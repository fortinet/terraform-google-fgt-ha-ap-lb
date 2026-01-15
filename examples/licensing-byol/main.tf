module "fgt_ha" {
  #  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"
  source = "./../.."

  region  = "us-central1"
  subnets = ["external", "internal", "hasync", "mgmt"]

  license_files = ["dummy_lic1.lic", "dummy_lic2.lic"]
  image = {
    license = "byol"
  }
}
