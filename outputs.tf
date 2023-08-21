output fgt_mgmt_eips {
  value       = google_compute_address.mgmt_pub[*].address
  description = "Public management IP addresses of FortiGate VMs"
}

output fgt_password {
  value       = google_compute_instance.fgt-vm[0].instance_id
  description = "Initial admin password"
}

output fgt_self_links {
  value       = google_compute_instance.fgt-vm[*].self_link
  description = "List of 2 self-links to FortiGate VMs"
}

output elb_bes {
  value       = google_compute_region_backend_service.elb_bes.self_link
  description = "Self-link to ELB backend service. "
}

output api_key {
  value       = length(var.api_accprofile)>0 ? random_string.api_key.result : ""
  description = "FortiGate API access token "
}


