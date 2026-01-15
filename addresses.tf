# All addresses are static but automatically assigned from the subnets.
# This module does not support manual selection of addresses. Modify this file if you want to decide
# which address will be assigned to what


#
# Reserve a private address for each subnet * for each instance
#
# index by {port name}-{instance index0} (eg. port1-0)
# use "-" as separator show whole key can be used as part of resource name
#
resource "google_compute_address" "priv" {
  # index by "portX_Y"
  for_each = toset([for pair in setproduct(
    [for netindx in range(length(var.subnets)) : "port${netindx + 1}"],
    [0, 1]
  ) : join("-", pair)])

  name         = "${local.prefix}addrprv-${each.value}"
  region       = local.region
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.connected[split("-", each.key)[0]].id
}

#
# Reserve a public IP for each public management NIC
#
resource "google_compute_address" "pub" {
  for_each = toset([for pair in setproduct(
    local.public_nics,
    [0, 1]
  ) : join("-", pair)])

  name   = split("-", each.value)[0] == local.mgmt_port ? "${local.prefix}addr-mgmt-fgt${split("-", each.value)[1] + 1}" : "${local.prefix}addrpub-${each.value}"
  region = local.region
}

#
# Reserve address for each ILB - in each subnet except for the first (external) and the last one (hamgmt)
# 
resource "google_compute_address" "ilb" {
  for_each = local.ports_internal

  name         = "${local.prefix}addr-${each.value}-ilb"
  region       = local.region
  address_type = "INTERNAL"
  subnetwork   = data.google_compute_subnetwork.connected[each.key].id
}