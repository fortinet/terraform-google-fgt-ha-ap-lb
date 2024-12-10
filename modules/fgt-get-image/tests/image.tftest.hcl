run "by_family_byol" {
  command = plan

  variables {
    family = "fortigate-72-byol"
  }

  assert {
    condition     = !strcontains(data.google_compute_image.all.self_link, "ondemand")
    error_message = "PAYG image selected despite BYOL family"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "72")
    error_message = "Image for family fortigate-72-byol should contain '72' substring"
  }
}

run "by_version_byol" {
  command = plan

  variables {
    ver = "7.2.4"
    lic = "byol"
  }

  assert {
    condition     = !strcontains(data.google_compute_image.all.self_link, "ondemand")
    error_message = "PAYG image selected despite BYOL licensing"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "724")
    error_message = "Image for version 7.2.4 should contain '724' substring"
  }
}

run "by_version_byol_arm" {
  command = plan

  variables {
    ver = "7.2.4"
    lic = "byol"
    arch = "arm"
  }

  assert {
    condition     = !strcontains(data.google_compute_image.all.self_link, "ondemand")
    error_message = "PAYG image selected despite BYOL licensing"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "724")
    error_message = "Image for version 7.2.4 should contain '724' substring"
  }

  assert {
    condition = strcontains(data.google_compute_image.all.self_link, "arm64")
    error_message = "Image for var.arch set to arm didn't select ARM64 image"
  }

  assert {
    condition = data.google_compute_image.all.status == "READY"
    error_message = "Selected image does not have status READY"
  }
}

run "by_version_payg" {
  command = plan

  variables {
    ver = "7.2.4"
    lic = "payg"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "ondemand")
    error_message = "BYOL image selected despite PAYG licensing"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "724")
    error_message = "Image for version 7.2.4 should contain '724' substring"
  }
}

run "by_version_defaultpayg" {
  command = plan

  variables {
    ver = "7.2.4"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "ondemand")
    error_message = "Image licensing should default to PAYG"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "724")
    error_message = "Image for version 7.2.4 should contain '724' substring"
  }
}

run "by_version_short" {
  command = plan

  variables {
    ver = "7.4"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "ondemand")
    error_message = "BYOL image selected despite PAYG licensing"
  }

  assert {
    condition     = strcontains(data.google_compute_image.all.self_link, "743")
    error_message = "Image for version 7.4 should contain '743' substring (newest)"
  }
}

run "default" {
    command = plan

    variables {}

    assert {
        condition = strcontains(data.google_compute_image.all.self_link, "ondemand")
        error_message = "Image licensing should default to PAYG"
    }
    assert {
        condition     = strcontains(data.google_compute_image.all.self_link, "743")
        error_message = "Image should default to 7.4.3"
    }
}

run "check_ver_xor_family" {
    command = plan

    variables {
        family = "fortigate-74-byol"
        ver = "7.4.1"
    }

    expect_failures = [
        check.ver_xor_family
    ]
}