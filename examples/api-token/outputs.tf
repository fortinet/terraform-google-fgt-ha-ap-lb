output "api_token" {
    value = module.fgt_ha.api_key
}

output "primary_fgt_address" {
  value = module.fgt_ha.fgt_mgmt_eips[0]
}

output "your_first_api_request" {
    value = "curl --insecure -H 'Accept: application/json' -H 'Authorization: Bearer ${module.fgt_ha.api_key}' https://${module.fgt_ha.fgt_mgmt_eips[0]}/api/v2/cmdb/firewall/address"
}