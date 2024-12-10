module "fgt_ha" {
#  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"
  source        = "./../.."

  zones         = [ "us-central1-b", "us-central1-c" ]
  subnets       = [ "external", "internal", "mgmt" ]
}