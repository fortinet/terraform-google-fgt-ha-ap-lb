# Find the public image to be used for deployment. You can indicate image by either
# image family or image name. By default, the Fortinet's public project and newest
# 72 PAYG image is used.
data "google_compute_image" "fgt_image" {
  project         = var.image_project
  family          = var.image_name == "" ? var.image_family : null
  name            = var.image_name != "" ? var.image_name : null
}


# Pull information about subnets we will connect to FortiGate instances. Subnets must
# already exist (can be created in parent module).
data "google_compute_subnetwork" "subnets" {
  count           = length(var.subnets)
  name            = var.subnets[count.index]
  region          = var.region
}

# Pull default zones and the service account. Both can be overridden in variables if needed.
data "google_compute_zones" "zones_in_region" {
  region          = var.region
}

data "google_compute_default_service_account" "default" {
}

locals {
  zones = [
    var.zones[0]  != "" ? var.zones[0] : data.google_compute_zones.zones_in_region.names[0],
    var.zones[1]  != "" ? var.zones[1] : data.google_compute_zones.zones_in_region.names[1]
  ]
}

# We'll use shortened region and zone names for some resource names. This is a standard shortening described in
# GCP security foundations.
locals {
  region_short    = replace( replace( replace( replace(var.region, "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  zones_short     = [
    replace( replace( replace( replace(local.zones[0], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa"),
    replace( replace( replace( replace(local.zones[1], "europe-", "eu"), "australia", "au" ), "northamerica", "na"), "southamerica", "sa")
  ]
}

locals {
  # If prefix is defined, add a "-" spacer after it
  prefix = length(var.prefix)>0 && substr(var.prefix, -1, 1)!="-" ? "${var.prefix}-" : var.prefix
}

# Create new random API key to be provisioned in FortiGates.
resource "random_string" "api_key" {
  length                 = 30
  special                = false
  numeric                = true
}

# Create FortiGate instances with secondary logdisks and configuration. Everything 2 times (active + passive)
resource "google_compute_disk" "logdisk" {
  count                  = 2

  name                   = "${local.prefix}disk-logdisk${count.index+1}-${local.zones_short[count.index]}"
  size                   = var.logdisk_size
  type                   = "pd-ssd"
  zone                   = local.zones[count.index]
  labels                 = var.labels
}



locals {
  config_active_noflex   = templatefile("${path.module}/fgt-base-config.tftpl", {
    hostname               = "${local.prefix}vm-${local.zones_short[0]}"
    unicast_peer_ip        = google_compute_address.hasync_priv[1].address
    unicast_peer_netmask   = cidrnetmask(data.google_compute_subnetwork.subnets[2].ip_cidr_range)
    ha_prio                = 1
    healthcheck_port       = var.healthcheck_port
    api_key                = random_string.api_key.result
    ext_ip                 = google_compute_address.ext_priv[0].address
    ext_gw                 = data.google_compute_subnetwork.subnets[0].gateway_address
    int_ip                 = google_compute_address.int_priv[0].address
    int_gw                 = data.google_compute_subnetwork.subnets[1].gateway_address
    int_cidr               = data.google_compute_subnetwork.subnets[1].ip_cidr_range
    hasync_ip              = google_compute_address.hasync_priv[0].address
    mgmt_ip                = google_compute_address.mgmt_priv[0].address
    mgmt_gw                = data.google_compute_subnetwork.subnets[3].gateway_address
    ilb_ip                 = google_compute_address.ilb.address
    api_acl                = var.api_acl
    api_accprofile         = var.api_accprofile
    frontend_eips          = local.eip_all
    fgt_config             = var.fgt_config
    probe_loopback_ip      = var.probe_loopback_ip
  })

  config_passive_noflex  = templatefile("${path.module}/fgt-base-config.tftpl", {
    hostname               = "${local.prefix}vm-${local.zones_short[1]}"
    unicast_peer_ip        = google_compute_address.hasync_priv[0].address
    unicast_peer_netmask   = cidrnetmask(data.google_compute_subnetwork.subnets[2].ip_cidr_range)
    ha_prio                = 0
    healthcheck_port       = var.healthcheck_port
    api_key                = random_string.api_key.result
    ext_ip                 = google_compute_address.ext_priv[1].address
    ext_gw                 = data.google_compute_subnetwork.subnets[0].gateway_address
    int_ip                 = google_compute_address.int_priv[1].address
    int_gw                 = data.google_compute_subnetwork.subnets[1].gateway_address
    int_cidr               = data.google_compute_subnetwork.subnets[1].ip_cidr_range
    hasync_ip              = google_compute_address.hasync_priv[1].address
    mgmt_ip                = google_compute_address.mgmt_priv[1].address
    mgmt_gw                = data.google_compute_subnetwork.subnets[3].gateway_address
    ilb_ip                 = google_compute_address.ilb.address
    api_acl                = var.api_acl
    api_accprofile         = var.api_accprofile
    frontend_eips          = local.eip_all
    fgt_config             = var.fgt_config
    probe_loopback_ip      = var.probe_loopback_ip
  })

  config_active_flex     = templatefile("${path.module}/fgt-base-flex-wrapper.tftpl", {
    fgt_config   = local.config_active_noflex
    flexvm_token = var.flexvm_tokens[0]
    })
  config_passive_flex    = templatefile("${path.module}/fgt-base-flex-wrapper.tftpl", {
    fgt_config   = local.config_passive_noflex
    flexvm_token = var.flexvm_tokens[1]
    })

  config_active  = length(var.flexvm_tokens[0])>1 ? local.config_active_flex : local.config_active_noflex
  config_passive = length(var.flexvm_tokens[1])>1 ? local.config_passive_flex : local.config_passive_noflex
}

resource "google_compute_instance" "fgt-vm" {
  count                  = 2

  zone                   = local.zones[count.index]
  name                   = "${local.prefix}vm${count.index+1}-${local.zones_short[count.index]}"
  machine_type           = var.machine_type
  can_ip_forward         = true
  tags                   = ["fgt"]
  labels                 = var.labels

  boot_disk {
    initialize_params {
      image              = data.google_compute_image.fgt_image.self_link
      labels             = var.labels
    }
  }
  attached_disk {
    source               = google_compute_disk.logdisk[count.index].name
  }

  service_account {
    email                = (var.service_account != "" ? var.service_account : data.google_compute_default_service_account.default.email)
    scopes               = ["cloud-platform"]
  }

  metadata = {
    user-data            = (count.index == 0 ? local.config_active : local.config_passive )
    license              = fileexists(var.license_files[count.index]) ? file(var.license_files[count.index]) : null
    serial-port-enable   = true
  }

  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[0].id
    network_ip           = google_compute_address.ext_priv[count.index].address
    nic_type             = var.nic_type
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[1].id
    network_ip           = google_compute_address.int_priv[count.index].address
    nic_type             = var.nic_type
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[2].id
    network_ip           = google_compute_address.hasync_priv[count.index].address
    nic_type             = var.nic_type
  }
  network_interface {
    subnetwork           = data.google_compute_subnetwork.subnets[3].id
    network_ip           = google_compute_address.mgmt_priv[count.index].address
    nic_type             = var.nic_type
    access_config {
      nat_ip             = google_compute_address.mgmt_pub[count.index].address
    }
  }
} //fgt-vm


# Common Load Balancer resources
resource "google_compute_region_health_check" "health_check" {
  name                   = "${local.prefix}healthcheck-http${var.healthcheck_port}-${local.region_short}"
  region                 = var.region
  timeout_sec            = 2
  check_interval_sec     = 2

  http_health_check {
    port                 = var.healthcheck_port
  }
}

resource "google_compute_instance_group" "fgt-umigs" {
  count                  = 2

  name                   = "${local.prefix}umig${count.index}-${local.zones_short[count.index]}"
  zone                   = google_compute_instance.fgt-vm[count.index].zone
  instances              = [google_compute_instance.fgt-vm[count.index].self_link]
}

# Firewall rules
resource "google_compute_firewall" "allow-mgmt" {
  name                   = "${local.prefix}fw-mgmt-allow-admin"
  network                = data.google_compute_subnetwork.subnets[3].network
  source_ranges          = var.admin_acl
  target_tags            = ["fgt"]

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow-hasync" {
  name                   = "${local.prefix}fw-hasync-allow-fgt"
  network                = data.google_compute_subnetwork.subnets[2].network
  source_tags            = ["fgt"]
  target_tags            = ["fgt"]

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow-port1" {
  name                   = "${local.prefix}fw-ext-allowall"
  network                = data.google_compute_subnetwork.subnets[0].network
  source_ranges          = ["0.0.0.0/0"]

  allow {
    protocol             = "all"
  }
}

resource "google_compute_firewall" "allow-port2" {
  name                   = "${local.prefix}fw-int-allowall"
  network                = data.google_compute_subnetwork.subnets[1].network
  source_ranges          = ["0.0.0.0/0"]

  allow {
    protocol             = "all"
  }
}

# Save api_key to Secret Manager if var.api_token_secret_name is set
resource "google_secret_manager_secret" "api-secret" {
  count                  = var.api_token_secret_name!="" ? 1 : 0
  secret_id              = var.api_token_secret_name

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "api_key" {
  count                  = var.api_token_secret_name!="" ? 1 : 0
  secret                 = google_secret_manager_secret.api-secret[0].id
  secret_data            = random_string.api_key.id
}
