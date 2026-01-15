module "fgt_ha" {
  #  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"
  source = "./../.."

  image = {
    arch    = "arm"
    license = "payg"
  }
  machine_type = "t2a-standard-4"
  nic_type     = "GVNIC"

  prefix    = "fgt-example-arm"
  region    = "us-central1"
  subnets   = [var.subnet_external, var.subnet_internal, var.subnet_hasync, var.subnet_mgmt]
  frontends = ["app1"]
  ha_port   = "port3"
}

output "outputs" {
  value = module.fgt_ha
}
