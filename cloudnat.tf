# Cloud NAT is used for outbound connectivity from FortiGate instances.
# it will be used for all connections initiated by FortiGates (eg. license
# entitlement checks, signature updates, etc.), as well as for forwarded
# connections if SNAT is set to port1 interface IP (default).

# Cloud NAT will use ephemeral external IP

resource "google_compute_router" "nat_router" {
  name    = "${local.prefix}cr-cloudnat-${local.region_short}"
  region  = local.region
  network = data.google_compute_subnetwork.connected["port1"].network
}

resource "google_compute_router_nat" "cloud_nat" {
  name                               = "${local.prefix}nat-cloudnat-${local.region_short}"
  router                             = google_compute_router.nat_router.name
  region                             = local.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = data.google_compute_subnetwork.connected["port1"].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
