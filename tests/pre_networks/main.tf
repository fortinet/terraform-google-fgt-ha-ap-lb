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

locals {
  network_names = [
    "ext",
    "int",
    "hasync",
    "mgmt"
  ]

  cidrs = {
    ext = "172.20.0.0/24"
    int = "172.20.1.0/24"
    hasync = "172.20.2.0/24"
    mgmt = "172.20.3.0/24"
  }

  region = "us-central1"
}


resource "random_string" "id" {
    length = 4
    special = false
    upper = false
}

#prepare the networks
resource google_compute_network "demo" {
  for_each      = toset(local.network_names)

  name          = "test-${random_string.id.result}-vpc-${each.value}"
  auto_create_subnetworks = false
}

resource google_compute_subnetwork "demo" {
  for_each      = toset(local.network_names)

  name          = "test-${random_string.id.result}-sb-${each.value}"
  region        = local.region
  network       = google_compute_network.demo[ each.value ].self_link
  ip_cidr_range = local.cidrs[ each.value ]
}

output "subnets" {
    value = [ for subnet in google_compute_subnetwork.demo : subnet.name ]
}