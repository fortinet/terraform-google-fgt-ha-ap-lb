run "setup_vpcs" {
  module {
    source = "./tests/5networks"
  }
}

run "api-token" {
    command = plan
    
    variables {
        subnets = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4]            
        ]
        region        = "us-central1"
        api_accprofile        = "prof_admin"
        api_acl               = ["10.0.0.0/24"]
        api_token_secret_name = "fgt-api-secret"
    }

    assert {
        condition = length(google_secret_manager_secret_version.api_key) == 1
        error_message = "Secret version data is null"
    }
}

run "arm-based-machine-type" {
    command = plan

    variables {
        image  = {
            arch = "arm"
            license = "payg"
        }
        machine_type  = "t2a-standard-4"
        nic_type      = "GVNIC"

        prefix        = "fgt-example-arm"
        region        = "us-central1"
        subnets       = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4] 
        ]
        frontends     = ["app1"]
    }

    assert {
        condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type == "GVNIC"
        error_message = "nic0 type is not set to GVNIC"
    }
}

run "byol-existing-subnets" {
    command = plan

    variables {
        prefix        = "fgt-example-byol"
        region        = "us-central1"
        license_files = ["dummy_lic1.lic", "dummy_lic2.lic"]
        image = {
            family  = "fortigate-72-byol"
        }
        labels        = {
            owner : "johndoe"
            env   : "test"
        }
        subnets       = [             
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4] 
        ]
        frontends     = ["app1"]
    }

    assert {
        condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type != "GVNIC"
        error_message = "nic0 type is set to GVNIC"
    }
}

run "custom_image" {
    module {
        source = "./tests/pre_custom_image"
    }
}

run "gvnic-custom-image" {
    command = plan

    variables {
        region        = "us-central1"
        subnets       = [             
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4]
        ]
        image = {
            name    = run.custom_image.image_name
            project = run.custom_image.image_project
        }
        nic_type      = "GVNIC"
    }

  assert {  
    condition     = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "fortigcp-project-001")
    error_message = "Image from marketplace instead of custom"
  }
  assert {
    condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type == "GVNIC"
    error_message = "nic0 type is not set to GVNIC"
  }
}

run "licensing-byol" {
    command = plan

    variables {
        region        = "us-central1"
        subnets       = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4] 
        ]

        license_files = ["dummy_lic1.lic", "dummy_lic2.lic"]
        image = {
            family = "fortigate-70-byol"
        }
    }

  assert {
    condition     = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "PAYG image selected despite BYOL family"
  }
  assert {
    condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type != "GVNIC"
    error_message = "nic0 type is set to GVNIC"
  }
}

run "licensing-flex" {
    command = plan
    variables {
        region        = "us-central1"
        subnets       = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4] 
        ]

        flex_tokens   = ["B1C38EDAEA0D4E568D2F", "9E8FF67B64924C3B82E1"]
        image = {
            family  = "fortigate-70-byol"
        }        
    }

  assert {
    condition     = !strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "PAYG image selected despite BYOL family"
  }
    assert {
        condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type != "GVNIC"
        error_message = "nic0 type is set to GVNIC"
    }
}

run "licensing-payg" {
    command = plan
    variables {
        region        = "us-central1"
        subnets       = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4] 
        ]

        image = {
            family = "fortigate-72-payg"
        }
    }

  assert {
    condition     = strcontains(google_compute_instance.fgt_vm[0].boot_disk[0].initialize_params[0].image, "ondemand")
    error_message = "BYOL image selected instead of PAYG"
  }
}

run "minimal" {
    command = plan
    variables {
        region        = "us-central1"
        subnets       = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[4] 
        ]        
    }
    assert {
        condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type != "GVNIC"
        error_message = "nic0 type is set to GVNIC"
    }
}

run "public-addresses-elb-frontend" {
    command = plan
    variables {
        region        = "us-central1"
        subnets       = [
            run.setup_vpcs.subnets[0],
            run.setup_vpcs.subnets[1],
            run.setup_vpcs.subnets[3],
            run.setup_vpcs.subnets[4] 
        ]    
        frontends = [
            "service1", # this will create a new address
            "service2", # this will create a new address
            "35.1.2.3"  # this will attach existing address (if found in your project and region, and if not used)
        ]
    }

    assert {
        condition = google_compute_instance.fgt_vm[0].network_interface[0].nic_type != "GVNIC"
        error_message = "nic0 type is set to GVNIC"
    }
    assert {
        condition = length(google_compute_forwarding_rule.frontends) == 2
        error_message = "There are ${length(google_compute_forwarding_rule.frontends)} external forwarding rules instead of 2"
    }
}