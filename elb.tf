# External Load Balancer is used to drive traffic from Internet to FGT cluster
# but can be also used for outbound traffic
#
# var.frontends can contain both names for new addresses and values for existing addresses
# manipulations in locals below make the module distinguish between the two


locals {
  # split input frontends list into existing and to-be-created EIPs
  in_eip_new      = [for addr in var.frontends : addr if !can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", addr))]
  in_eip_existing = [for addr in var.frontends : addr if can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", addr))]

  # format existing EIP list into mapping by name, skip non-existing addresses, skip IN_USE addresses
  eip_existing_existing = { for addr, info in data.google_compute_addresses.existing : addr => info if length(info.addresses) > 0 }
  eip_existing          = { for addr, info in local.eip_existing_existing : trimprefix(info.addresses[0].name, local.prefix) => addr if info.addresses[0].status != "IN_USE" }

  # format new EIP list into mapping by name
  eip_new = { for name, info in google_compute_address.new_eip : name => info.address }

  eip_all = merge(local.eip_new, local.eip_existing)
}

# pull data about existing EIPs to be assigned to the cluster for:
# - sanity check if EIP is available to use
# - getting EIP name for resource naming
data "google_compute_addresses" "existing" {
  for_each = toset(local.in_eip_existing)

  region = local.region
  filter = "address=\"${each.value}\""

  # NOTE: in contrary to documentation lifecycle is not supported for data.
  #       unavailable addresses will be silently ignored
  #  lifecycle {
  #    postcondition {
  #      condition = length( self.addresses )>0
  #      error_message = "Address ${each.value} was not found in region ${local.region}."
  #    }
  #  }
}

resource "google_compute_address" "new_eip" {
  for_each = toset(local.in_eip_new)

  name         = "${local.prefix}eip-${each.value}"
  region       = local.region
  address_type = "EXTERNAL"
}

resource "google_compute_forwarding_rule" "frontends" {
  for_each = local.eip_all

  name                  = "${local.prefix}fr-${each.key}"
  region                = local.region
  ip_address            = each.value
  ip_protocol           = "L3_DEFAULT"
  all_ports             = true
  load_balancing_scheme = "EXTERNAL"
  backend_service       = google_compute_region_backend_service.elb_bes.self_link
  labels                = var.labels
}

resource "google_compute_region_backend_service" "elb_bes" {
  provider              = google-beta
  name                  = "${local.prefix}bes-elb-${local.region_short}"
  region                = local.region
  load_balancing_scheme = "EXTERNAL"
  protocol              = "UNSPECIFIED"

  backend {
    group = google_compute_instance_group.fgt_umigs[0].self_link
    balancing_mode = "CONNECTION"
  }
  backend {
    group = google_compute_instance_group.fgt_umigs[1].self_link
    balancing_mode = "CONNECTION"
  }

  health_checks = [google_compute_region_health_check.health_check.self_link]
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}
