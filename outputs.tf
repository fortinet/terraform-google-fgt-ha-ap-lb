output "fgt_mgmt_eips" {
  value       = google_compute_address.pub
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

output "elb_bes" {
  value       = google_compute_region_backend_service.elb_bes.self_link
  description = "Self-link to ELB backend service. "
}

output "api_key" {
  value       = length(var.api_accprofile) > 0 ? random_string.api_key.result : ""
  description = "FortiGate API access token "
}


output "ilb_address" {
  value       = { for indx, ilb in google_compute_address.ilb : indx => ilb.address }
  description = "Address of ILB. Can be used for PBR creation"
}

output "frontends" {
  value       = local.eip_all
  description = "Map of all external IP addresses bound to FortiGate cluster"
}
