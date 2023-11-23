module "fgt_ha" {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]
}
