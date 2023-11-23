module "fgt_ha" {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]

  # Note: this family is set by default, so you don't need to declare it.
  # It's not a bad idea to set it explicitly and keep your code easier to read
  image_family = "fortigate-72-payg"
}
