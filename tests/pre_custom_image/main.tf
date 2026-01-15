terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
        }
        random = {
            source = "hashicorp/random"
        }
    }
}

resource "random_string" "id" {
    length = 4
    special = false
    upper = false
}

resource "google_compute_image" "test" {
  name         = "test${random_string.id.result}-custom-image"
  source_image = "projects/fortigcp-project-001/global/images/fortinet-fgt-724-20230310-001-w-license"

  guest_os_features {
    type = "GVNIC"
  }
}

data "google_project" "this" {}

output "image_name" {
  value = google_compute_image.test.name
}

output "image_project" {
    value = data.google_project.this.project_id
}