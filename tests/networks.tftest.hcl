
run "setup_vpcs" {
  module {
    source = "./tests/5networks"
  }
}

variables {
  region = "us-central1"
}

run "classic-4nic" {
  command = plan

  variables {
    subnets = [
        run.setup_vpcs.subnets[0],
        run.setup_vpcs.subnets[1],
        run.setup_vpcs.subnets[3],
        run.setup_vpcs.subnets[4]
    ]
    ha_port = "port3"
    mgmt_port = "port4"
  }

  assert {
    condition = length(google_compute_instance.fgt_vm[0].network_interface) == 4
    error_message = "Number of NICs does not match number of subnets"
  }
  assert {
    condition = length(keys(google_compute_forwarding_rule.ilb)) == 1
    error_message = "Number of forwarding rules should be 1"
  }
  assert {
    condition = length(google_compute_instance.fgt_vm[0].network_interface[3].access_config) == 1
    error_message = "Port4 of FGT1 is missing access_config"
  }
  assert {
    condition = length(google_compute_instance.fgt_vm[0].network_interface[2].access_config) == 0
    error_message = "Port3 should have no external IP"
  }
}

run "dual-internal" {
  command = plan

  variables {
    subnets = [
        run.setup_vpcs.subnets[0],
        run.setup_vpcs.subnets[1],
        run.setup_vpcs.subnets[2],
        run.setup_vpcs.subnets[4]
    ]
    ha_port = "port4"
    mgmt_port = "port4"
  }

  assert {
    condition = length(google_compute_instance.fgt_vm[0].network_interface) == 4
    error_message = "Number of NICs does not match number of subnets"
  }
  assert {
    condition = length(keys(google_compute_forwarding_rule.ilb)) == 2
    error_message = "Number of forwarding rules should be 2 (for 2 internal subnets)"
  }
  assert {
    condition = length(google_compute_instance.fgt_vm[0].network_interface[3].access_config) == 1
    error_message = "Port4 of FGT1 is missing access_config"
  }
  assert {
    condition = length(google_compute_instance.fgt_vm[0].network_interface[2].access_config) == 0
    error_message = "Port3 should have no external IP"
  }
  assert {
    condition = length(google_compute_instance.fgt_vm[1].network_interface[3].access_config) == 1
    error_message = "Port4 of FGT2 is missing access_config"
  }
}