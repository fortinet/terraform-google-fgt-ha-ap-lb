# Internal load balancer resources

# ILB is used for routing network flows from cloud workloads to any other networks.
# List of prefixes to route via ILB is defined by var.outbound_routes (defaults to 0.0.0.0/0)


resource "google_compute_region_backend_service" "ilb_bes" {
  provider = google-beta
  for_each = local.ports_internal

  name    = "${local.prefix}bes-${each.key}-ilb-${local.region_short}"
  region  = local.region
  network = data.google_compute_subnetwork.connected[each.key].network

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

resource "google_compute_forwarding_rule" "ilb" {
  for_each = local.ports_internal

  name                  = "${local.prefix}fwdrule-${each.key}-ilb-${local.region_short}"
  region                = local.region
  network               = data.google_compute_subnetwork.connected[each.key].network
  subnetwork            = data.google_compute_subnetwork.connected[each.key].id
  ip_address            = google_compute_address.ilb[each.key].address
  all_ports             = true
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.ilb_bes[each.key].self_link
  allow_global_access   = true
  labels                = var.labels
}

#
# Add routes to all internal networks
# 
# Use product of local.ports_internal (list of internal port names) and var.routes (all routes to add, defaults to [0.0.0.0/0])
# Index by portNumber|routeLabel (eg. port2|default)
resource "google_compute_route" "outbound_routes" {
  for_each = toset([for pair in setproduct(keys(local.ports_internal), keys(var.routes)) : join("|", pair)])

  name         = "${local.prefix}rt-${data.google_compute_subnetwork.connected[split("|", each.key)[0]].name}-${split("|", each.key)[1]}-via-fgt"
  dest_range   = var.routes[split("|", each.key)[1]]
  network      = data.google_compute_subnetwork.connected[split("|", each.key)[0]].network
  next_hop_ilb = google_compute_forwarding_rule.ilb[split("|", each.key)[0]].self_link
  priority     = 100
}