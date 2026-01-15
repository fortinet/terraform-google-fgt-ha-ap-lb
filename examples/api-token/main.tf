module "fgt_ha" {
#  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"
  source        = "./../.."

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]

  api_accprofile        = "prof_admin"

  # Make sure you replace these addresses with your own
  api_acl               = [ "${data.http.ipinfo.response_body}/32", "10.0.0.0/24"]

  # This line is optional and saves the generated token to Secret Manager under the key indicated in the variable
  api_token_secret_name = "fgt-api-secret"
}

# This data section is here only to make the example API call in the outputs work
data "http" "ipinfo" {
  url = "http://api.ipify.org"
}