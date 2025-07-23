terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}


# Pull information about subnets we will connect to FortiGate instances. Subnets must
# already exist (can be created in parent module).
# Index by port name
data "google_compute_subnetwork" "connected" {
  for_each = toset([for indx in range(length(var.subnets)) : "port${indx + 1}"])

  name   = var.subnets[tonumber(substr(each.key, 4, 1)) - 1]
  region = local.region
}

# Pull default zones and the service account. Both can be overridden in variables if needed.
data "google_compute_zones" "zones_in_region" {
  region = local.region
}

data "google_compute_default_service_account" "default" {
}

data "google_client_config" "default" {}

locals {
  # derive region from zones if provided, otherwise use the region from variable, as last resort use default region from provider
  region = coalesce(try(join("-", slice(split("-", var.zones[0]), 0, 2)), null), var.region, data.google_client_config.default.region)

  zones = [
    var.zones[0] != "" ? var.zones[0] : data.google_compute_zones.zones_in_region.names[0],
    var.zones[1] != "" ? var.zones[1] : data.google_compute_zones.zones_in_region.names[1]
  ]
}

# We'll use shortened region and zone names for some resource names. This is a standard shortening described in
# GCP security foundations.
locals {
  region_short = replace(replace(replace(replace(replace(replace(replace(replace(replace(local.region, "-south", "s"), "-east", "e"), "-central", "c"), "-north", "n"), "-west", "w"), "europe", "eu"), "australia", "au"), "northamerica", "na"), "southamerica", "sa")
  zones_short = [
    "${local.region_short}${substr(local.zones[0], length(local.region) + 1, 1)}",
    "${local.region_short}${substr(local.zones[1], length(local.region) + 1, 1)}"
  ]
}

locals {
  # If prefix is defined, add a "-" spacer after it
  prefix = length(var.prefix) > 0 && substr(var.prefix, -1, 1) != "-" ? "${var.prefix}-" : var.prefix

  # Auto-set NIC type to GVNIC if ARM image was selected
  nic_type = var.image.arch == "arm" ? "GVNIC" : var.nic_type

  # List of NICs with public IP attached
  public_nics = [local.mgmt_port]

  # FGCP HA sync port (last-1 or port3 if there are not more ports available than 3)
  ha_port = var.ha_port != null ? var.ha_port : "port${max(length(var.subnets) - 1, 3)}"

  # FGCP dedicated management port (last)
  mgmt_port = var.mgmt_port != null ? var.mgmt_port : "port${length(var.subnets)}"

  subnets_internal = { for indx, subnet in var.subnets : indx => subnet if(indx > 0 && local.ha_port != "port${indx + 1}" && local.mgmt_port != "port${indx + 1}") }
  ports_internal   = { for indx, subnet in var.subnets : "port${indx + 1}" => subnet if(!contains(var.ports_external, "port${indx + 1}") && local.ha_port != "port${indx + 1}" && local.mgmt_port != "port${indx + 1}") }
}

# Create new random API key to be provisioned in FortiGates.
resource "random_string" "api_key" {
  length  = 30
  special = false
  numeric = true
}

resource "random_string" "ha_password" {
  length  = 20
  special = false
  upper   = false
  numeric = true
}

# Create FortiGate instances with secondary logdisks and configuration. Everything 2 times (active + passive)
resource "google_compute_disk" "logdisk" {
  count = 2

  name   = "${local.prefix}disk-logdisk${count.index + 1}-${local.zones_short[count.index]}"
  size   = var.logdisk_size
  type   = "pd-ssd"
  zone   = local.zones[count.index]
  labels = var.labels
}


data "cloudinit_config" "fgt" {
  count = 2

  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = try(var.flex_tokens[count.index], "") == "" ? [] : [1]
    content {
      filename     = "license"
      content_type = "text/plain; charset=\"us-ascii\""
      content      = <<-EOF
        LICENSE-TOKEN: ${var.flex_tokens[count.index]}
        EOF
    }
  }

  part {
    filename     = "config"
    content_type = "text/plain; charset=\"us-ascii\""
    content = templatefile("${path.module}/fgt-base-config.tftpl", {
      hostname             = "${local.prefix}vm-fgt${count.index + 1}-${local.zones_short[count.index]}"
      healthcheck_port     = var.healthcheck_port
      api_acl              = var.api_acl
      api_accprofile       = var.api_accprofile
      api_key              = random_string.api_key.result
      hbdev_port           = local.ha_port
      mgmt_port            = local.mgmt_port
      mgmt_gw              = data.google_compute_subnetwork.connected[local.mgmt_port].gateway_address
      ha_prio              = (count.index + 1) % 2
      unicast_peer_ip      = google_compute_address.priv["${local.ha_port}-${(count.index + 1) % 2}"].address
      unicast_peer_netmask = cidrnetmask(data.google_compute_subnetwork.connected[local.ha_port].ip_cidr_range)
      priv_ips             = { for indx, addr in google_compute_address.priv : split("-", indx)[0] => addr.address if tonumber(split("-", indx)[1]) == count.index }
      ilb_ips              = google_compute_address.ilb
      # note: don't index subnets var by port name as we might include all subnets from connected VPCs in future
      subnets = { for port, subnet in data.google_compute_subnetwork.connected :
        subnet.ip_cidr_range => {
          "gw" : subnet.gateway_address,
          "dev" : port,
          "name" : subnet.name
        }
      }
      gateways          = { for port, subnet in data.google_compute_subnetwork.connected : port => subnet.gateway_address }
      frontend_eips     = local.eip_all
      fgt_config        = var.fgt_config
      probe_loopback_ip = var.probe_loopback_ip
      ha_password       = random_string.ha_password.result
    })
  }
}

#
# Find marketplace image either based on version+arch+lic/family ...
#
module "fgtimage" {
  count = var.image.name == "" ? 1 : 0

  source = "./modules/fgt-get-image"
  ver    = var.image.version
  arch   = var.image.arch
  lic    = "${try(var.license_files[0], "")}${try(var.flex_tokens[0], "")}" != "" ? "byol" : var.image.license
  family = var.image.version == "" ? var.image.family : ""
}

#
# ... or get the custom one
#
data "google_compute_image" "custom" {
  count = var.image.name != "" ? 1 : 0

  project = var.image.project
  name    = var.image.name
}


# 
# Deploy VMs
#
resource "google_compute_instance" "fgt_vm" {
  count = 2

  zone           = local.zones[count.index]
  name           = "${local.prefix}vm-fgt${count.index + 1}-${local.zones_short[count.index]}"
  machine_type   = var.machine_type
  can_ip_forward = true
  tags           = ["fgt"]
  labels         = var.labels

  boot_disk {
    initialize_params {
      image  = var.image.name == "" ? module.fgtimage[0].self_link : data.google_compute_image.custom[0].self_link
      labels = var.labels
    }
  }
  attached_disk {
    source = google_compute_disk.logdisk[count.index].name
  }

  service_account {
    email  = (var.service_account != "" ? var.service_account : data.google_compute_default_service_account.default.email)
    scopes = ["cloud-platform"]
  }

  metadata = {
    user-data          = data.cloudinit_config.fgt[count.index].rendered #(count.index == 0 ? local.config_active : local.config_passive )
    license            = try(fileexists(var.license_files[count.index]), false) ? file(var.license_files[count.index]) : null
    serial-port-enable = var.serial_port_enable
    oslogin-enable     = var.oslogin_enable
  }

  dynamic "network_interface" {
    for_each = [for indx in range(length(var.subnets)) : "port${indx + 1}"]

    content {
      subnetwork = data.google_compute_subnetwork.connected[network_interface.value].name
      nic_type   = local.nic_type
      network_ip = google_compute_address.priv["${network_interface.value}-${count.index}"].address
      dynamic "access_config" {
        for_each = contains(local.public_nics, network_interface.value) ? [1] : []
        content {
          nat_ip = google_compute_address.pub["${network_interface.value}-${count.index}"].address
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !(("${try(var.license_files[0], "")}${try(var.flex_tokens[0], "")}" != "") && strcontains(try(module.fgtimage[0].image.name, ""), "ondemand"))
      error_message = "You provided a FortiGate BYOL (or Flex) license, but you're attempting to deploy a PAYG image. This would result in a double license fee. \nUpdate module's 'image' parameter to fix this error.\n\nCurrent var.image value: \n  {%{for k, v in var.image}%{if tostring(v) != ""}\n    ${k}=${v}%{endif}%{endfor}\n  }"
    }
  }
} //fgt-vm


# Common Load Balancer resources
resource "google_compute_region_health_check" "health_check" {
  name               = "${local.prefix}healthcheck-http${var.healthcheck_port}-${local.region_short}"
  region             = local.region
  timeout_sec        = 2
  check_interval_sec = 2

  http_health_check {
    port = var.healthcheck_port
  }
}

resource "google_compute_instance_group" "fgt_umigs" {
  count = 2

  name      = "${local.prefix}umig${count.index}-${local.zones_short[count.index]}"
  zone      = google_compute_instance.fgt_vm[count.index].zone
  instances = [google_compute_instance.fgt_vm[count.index].self_link]
  named_port {
    name = "http"
    port = 80
  }
  named_port {
    name = "https"
    port = 443
  }
}

# Firewall rules
#
## Open all traffic on data networks

resource "google_compute_firewall" "allow_all" {
  for_each = toset([for indx in range(length(var.subnets)) : "port${indx + 1}" if !contains([local.ha_port, local.mgmt_port], "port${indx + 1}")])

  name          = "${local.prefix}fw-${data.google_compute_subnetwork.connected[each.key].name}-allowall"
  network       = data.google_compute_subnetwork.connected[each.key].network
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_mgmt" {
  name          = "${local.prefix}fw-mgmt-allow-admin"
  network       = data.google_compute_subnetwork.connected[local.mgmt_port].network
  source_ranges = var.admin_acl
  target_tags   = ["fgt"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_hasync" {
  name        = "${local.prefix}fw-hasync-allow-fgt"
  network     = data.google_compute_subnetwork.connected[local.ha_port].network
  source_tags = ["fgt"]
  target_tags = ["fgt"]

  allow {
    protocol = "all"
  }
}


# Save api_key to Secret Manager if var.api_token_secret_name is set
resource "google_secret_manager_secret" "api_secret" {
  count     = var.api_token_secret_name != "" ? 1 : 0
  secret_id = var.api_token_secret_name

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "api_key" {
  count       = var.api_token_secret_name != "" ? 1 : 0
  secret      = google_secret_manager_secret.api_secret[0].id
  secret_data = random_string.api_key.id
}
