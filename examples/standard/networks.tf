// NOTE: this is an additional file when compared to the deployment guide in
// Google Cloud Solutions Center. You can remove this file and comment out 
// depends_on meta-argument in module.ha_fgt (main.tf:44) if you are deploying 
// into existing subnets.
//
// This file creates 4 VPC networks and subnets. In most cases you will be using
// already existing networks and this file will not be necessary. It's included here
// for the completeness of the whole example deployment.
//
// Note that FortiGate module reads information about the networks during the terraform plan
// phase, which means you need to delay it using depends_on meta-argument in the module block
// if the networks do not exist before starting module deployment


locals {
  net_names = ["external", "internal", "hasync", "mgmt"]
}

module "networks" {
  for_each   = toset(local.net_names)
  source     = "terraform-google-modules/network/google"
  project_id = var.project_id

  network_name = "${var.prefix}-${each.key}"
  subnets = [{
    subnet_name   = each.key
    subnet_ip     = "10.0.${index(local.net_names, each.key)}.0/24"
    subnet_region = join("-", slice(split("-", var.zones[0]), 0, 2))
  }]
}