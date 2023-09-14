module "fgt_ha" {
  source        = "git::github.com/fortinet/fortigate-gcp-ha-ap-lb-terraform?ref=v1.0.1"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]

  api_accprofile        = "prof_admin"
  api_acl               = ["10.0.0.0/24"]
  api_token_secret_name = "fgt-api-secret"
}
