variables {
  subnets = [
    "external",
    "internal",
    "hasync"
  ]
}

run "zone_from_region" {
  command = plan

  variables {
    region = "us-central1"
  }

  assert {
    condition     = local.region == "us-central1"
    error_message = "Region not set from variable"
  }
  assert {
    condition = contains( local.zones3, "us-central1-a")
    error_message = "Zone list does not include zone in region from variable"
  }
  assert {
    condition = contains( local.zones_short, "usc1a")
    error_message = "Missing short zone from the list"
  }
}

run "region_from_zones" {
  command = plan

  variables {
    zones = ["us-central1-b", "us-central1-c"]
  }

  assert {
    condition     = local.region == "us-central1"
    error_message = "Region not set from zones"
  }
  assert {
    condition = contains( local.zones3, "us-central1-a")
    error_message = "Missing 3rd zone from zones list"
  }
  assert {
    condition = contains( local.zones_short, "usc1a")
    error_message = "Missing short zone from the list"
  }
}