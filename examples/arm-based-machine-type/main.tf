module "fgt_ha" {
  source        = "git::github.com/fortinet/fortigate-gcp-ha-ap-lb-terraform?ref=v1.0.1"

  image_family  = "fortigate-arm64-72-payg"
  machine_type  = "t2a-standard-4"
  nic_type      = "GVNIC"

  prefix        = "fgt-example-arm"
  region        = "us-central1"
  subnets       = [ var.subnet_external, var.subnet_internal, var.subnet_hasync, var.subnet_mgmt]
  frontends     = ["app1"]
}

output outputs {
  value = module.fgt_ha
}
