module "fgt_ha" {
  #  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"
  source = "./../.."

  machine_type = "e2-standard-4"
  zones = [
    "us-central1-b",
    "us-central1-c"
  ]
  subnets = [
    "external",
    "mgmt",
    "internal1",
    "internal2",
    "internal3",
    "internal4",
    "internal5",
    "internal6"
  ]
  ha_port   = "port2"
  mgmt_port = "port2"
}