output "fgt_mgmt_eips" {
  value       = [for eip in google_compute_address.pub : eip.address ]
  description = "Public management IP addresses of FortiGate VMs"
}

output "fgt_password" {
  value       = google_compute_instance.fgt_vm[0].instance_id
  description = "Initial admin password"
}

output "fgt_self_links" {
  value       = google_compute_instance.fgt_vm[*].self_link
  description = "List of 2 self-links to FortiGate VMs"
}

output "fgt_umigs" {
  value       = google_compute_instance_group.fgt_umigs[*].self_link
  description = "List of 2 self-links to unmanaged instance groups with FortiGates"
}

output "elb_bes" {
  value       = google_compute_region_backend_service.elb_bes.self_link
  description = "Self-link to ELB backend service. "
}

output "api_key" {
  value       = length(var.api_accprofile) > 0 ? random_string.api_key.result : ""
  description = "FortiGate API access token "
}


output "ilb_addresses" {
  value       = { for indx, ilb in google_compute_address.ilb : indx => ilb.address }
  description = "Address of ILB. Can be used for PBR creation"
}

output "ilb_ids" {
  value       = { for indx, ilb in google_compute_forwarding_rule.ilb : indx => ilb.id }
  description = "Address of ILB. Can be used for route creation"  
}

output "frontends" {
  value       = local.eip_all
  description = "Map of all external IP addresses bound to FortiGate cluster"
}

output "fgts" {
  value = [for vm in google_compute_instance.fgt_vm: {
    name = vm.name
    self_link = vm.self_link
    id = vm.id
    instance_id = vm.instance_id
    zone = vm.zone
    boot_disk = { initialize_params = [vm.boot_disk[0].initialize_params]}
    network_interface = [ for nic_indx in range(length(var.subnets)) : vm.network_interface[ nic_indx ]]
    ports = { for nic_indx in range(length(var.subnets)) : "port${nic_indx+1}"=>vm.network_interface[ nic_indx ]}
    service_account = vm.service_account
  }]
  description = "FortiGate VM instance objects (partial)"
}