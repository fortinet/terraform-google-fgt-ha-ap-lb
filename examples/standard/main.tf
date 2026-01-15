provider "google" {
  project = var.project_id
}

module "fgt_ha" {
  // indicate the source of the module (Fortinet's GitHub repository)
  source = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  // All created resources will have a customizable prefix added to their names
  // for uniqueness and easier identification
  prefix = var.prefix

  // Obligatory module parameters (location and subnet names)
  zones   = var.zones
  subnets = ["external", "internal", "hasync", "mgmt"]

  // The module can create multiple public-facing frontends, simply list their names here
  frontends = ["app1", "app2"]

  // 4-NIC deployment requires a machine type with at least 3 vCPUs
  machine_type = "n2-standard-4"

  // Use licensing type (byol or payg) and firmware version to indicate which image you want 
  // to deploy. See docs/images.md for more details on this section
  image = {
    version = "7.6.1"
    license = "byol"
  }

  // If using standard BYOL licenses indicate the license files here. Skip this argument for
  // PAYG deployments and use flex_tokens for FortiFlex
  license_files = ["dummy_lic1.lic", "dummy_lic2.lic"]

  // Service account to be bound to the FortiGate VMs. If omitted defaults to Default Compute Service Account
  service_account = "fortigatesdn-ro@${var.project_id}.iam.gserviceaccount.com"

  // Add any custom labels to indicate the resources deployed by this module
  labels = {
    project = "demo"
  }

  // The line below is needed only if you create networks in the same terraform template
  // see networks.tf file for more details
  depends_on = [module.networks]
}
