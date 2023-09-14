module "fgt_ha" {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb?ref=v1.0.1"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]
}
