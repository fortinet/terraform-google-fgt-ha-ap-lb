# All addresses are static but automatically assigned from the subnets.
# This module does not support manual selection of addresses. Modify this file if you want to decide
# which address will be assigned to what

resource "google_compute_address" "mgmt_pub" {
  count                  = 2

  region                 = var.region
  name                   = "${local.prefix}eip${count.index+1}-mgmt-${local.region_short}"
}

resource "google_compute_address" "ext_priv" {
  count                  = 2

  name                   = "${local.prefix}ip${count.index+1}-ext-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[0].id
}

resource "google_compute_address" "int_priv" {
  count                  = 2

  name                   = "${local.prefix}ip${count.index+1}-int-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[1].id
}

resource "google_compute_address" "ilb" {
  name                   = "${local.prefix}ip-ilb-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[1].id

  # move ILB addresses after FGT addresses for more consistent address assignment
  depends_on = [
    google_compute_address.int_priv
  ]
}

resource "google_compute_address" "hasync_priv" {
  count                  = 2

  name                   = "${local.prefix}ip${count.index+1}-hasync-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[2].id
}

resource "google_compute_address" "mgmt_priv" {
  count                  = 2

  name                   = "${local.prefix}ip${count.index+1}-mgmt-${local.region_short}"
  region                 = var.region
  address_type           = "INTERNAL"
  subnetwork             = data.google_compute_subnetwork.subnets[3].id
}
