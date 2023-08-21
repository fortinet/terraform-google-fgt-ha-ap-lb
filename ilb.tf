# Internal load balancer resources

# ILB is used for routing network flows from cloud workloads to any other networks.
# List of prefixes to route via ILB is defined by var.outbound_routes (defaults to 0.0.0.0/0)

resource "google_compute_region_backend_service" "ilb_bes" {
  provider               = google-beta
  name                   = "${local.prefix}bes-ilb-${local.region_short}"
  region                 = var.region
  network                = data.google_compute_subnetwork.subnets[1].network

  backend {
    group                = google_compute_instance_group.fgt-umigs[0].self_link
  }
  backend {
    group                = google_compute_instance_group.fgt-umigs[1].self_link
  }

  health_checks          = [google_compute_region_health_check.health_check.self_link]
  connection_tracking_policy {
    connection_persistence_on_unhealthy_backends = "NEVER_PERSIST"
  }
}

resource "google_compute_forwarding_rule" "ilb_fwd_rule" {
  name                   = "${local.prefix}fwdrule-ilb-${local.region_short}"
  region                 = var.region
  network                = data.google_compute_subnetwork.subnets[1].network
  subnetwork             = data.google_compute_subnetwork.subnets[1].id
  ip_address             = google_compute_address.ilb.address
  all_ports              = true
  load_balancing_scheme  = "INTERNAL"
  backend_service        = google_compute_region_backend_service.ilb_bes.self_link
  allow_global_access    = true
  labels                 = var.labels
}

resource "google_compute_route" "outbound_routes" {
  for_each = var.routes

  name                   = "${local.prefix}rt-${each.key}-via-fgt"
  dest_range             = each.value
  network                = data.google_compute_subnetwork.subnets[1].network
  next_hop_ilb           = google_compute_forwarding_rule.ilb_fwd_rule.self_link
  priority               = 100
}
