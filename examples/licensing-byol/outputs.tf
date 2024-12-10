output "primary_fgt_address" {
  value = module.fgt_ha.fgt_mgmt_eips[0]
}

output "default_admin_password" {
  value = module.fgt_ha.fgt_password
}