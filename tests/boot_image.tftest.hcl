run "setup_net" {
  module {
    source = "./tests/pre_networks"
  }
}

run "custom_image" {
  module {
    source = "./tests/pre_custom_image"
  }
}

variables {
  region = "us-central1"
  frontends = []
}

run "img_select_by_family_byol" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    image = {
      family = "fortigate-72-byol"
    }
  }

  assert {
    condition     = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "PAYG image selected despite BYOL family"
  }

  assert {
    condition     = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "72")
    error_message = "Image for family fortigate-72-byol should contain '72' substring"
  }

  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "projects/fortigcp-project-001/")
    error_message = "Image should be from fortigcp-project-001"
  }
}

run "img_select_by_version_defaultpayg" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    image = {
      version = "7.2.6"
    }
  }

  assert {
    condition     = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "726")
    error_message = "Image selected by firmware version should contain string '726'"
  }
  assert {
    condition     = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "Image should default to PAYG"
  }
}

run "img_select_by_version_byol_arm" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    image = {
      version = "7.2.4"
      license = "byol"
      arch = "arm"
    }
  }

  assert {
    condition     = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "PAYG image selected despite BYOL licensing"
  }

  assert {
    condition     = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "724")
    error_message = "Image for version 7.2.4 should contain '724' substring"
  }

  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "arm64")
    error_message = "Image for var.arch set to arm didn't select ARM64 image"
  }
}

run "img_custom" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    image = {
      project = run.custom_image.image_project
      name = run.custom_image.image_name
    }
  }

  assert {
    condition = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortigcp-project-001")
    error_message = "Custom image should not refer to Fortinet public project"
  }
}

run "img_null" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
  }

  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortigcp-project-001")
    error_message = "Default image should refer to Fortinet public project"
  }
  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortinet-fgtondemand")
    error_message = "Default image should be PAYG and contain 'fortinet-fgtondemand'"
  }
}

run "img_null_with_tokens" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    flex_tokens = ["aaa","bbb"]
  }

  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortigcp-project-001")
    error_message = "Default image should refer to Fortinet public project"
  }
  assert {
    condition = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortinet-fgtondemand")
    error_message = "Adding flex tokens to default image config did not switch to BYOL"
  }
}

run "img_select_by_version_short_byol" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    image = {
      version = "7.2"
      license = "byol"
    }
  }

  assert {
    condition     = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "7210")
    error_message = "Image selected by firmware version should contain string '728' (assuming it's the newest one)"
  }
  assert {
    condition     = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "Image should be BYOL"
  }
}

run "img_select_by_name" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    image = {
      name = "fortinet-fgt-724-20230310-001-w-license"
    }
  }

  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortinet-fgt-724-20230310-001-w-license")
    error_message = "Boot image selected by name does not match the name in variable (fortinet-fgt-724-20230310-001-w-license)"
  }
  assert {
    condition = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortigcp-project-001")
    error_message = "Named image should default to Fortinet public project"
  }
}


run "img_error_license_mismatch" {
  command = plan

  variables {
    subnets = run.setup_net.subnets
    flex_tokens = ["DUMMY1", "DUMMY2"]
    image = {
      family = "fortigate-74-payg"
    }
  }

  expect_failures = [
    google_compute_instance.fgt_vm[0],
    google_compute_instance.fgt_vm[1]
  ]
}