resource "google_compute_image" "fgt_724_gvnic" {
  name         = "fgt-724-byol-gvnic"
  source_image = "projects/fortigcp-project-001/global/images/fortinet-fgt-724-20230310-001-w-license"

  guest_os_features {
    type = "GVNIC"
  }
}

module "fgt_ha" {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]

  image = {
    name    = google_compute_image.fgt_724_gvnic.name
    project = google_compute_image.fgt_724_gvnic.project
  }
  nic_type      = "GVNIC"
}
