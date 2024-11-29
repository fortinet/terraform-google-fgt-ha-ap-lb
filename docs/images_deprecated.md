# Selecting base image for FortiGate instances (deprecated)

By default, the FortiGates will be deployed with the newest 7.2 version and PAYG licensing on Intel-based platform. If you want to use a different firmware version, licensing or ARM-based VM instance - you must change the image by declaring one or more of the module variables: `image_name`, `image_family`, `image_project`.

## Using family_name
*Family name* is the easiest way to select the latest images published by Fortinet and supports both BYOL and PAYG deployments. Image *families* are a feature of Google Compute automatically selecting the latest image of a given family. As Fortinet customers often decide to not use the latest firmware branch, images are published with separate families for each main branch (6.4, 7.0, 7.2). You will also need to decide if the image license should be paid via Google Cloud Marketplace per time used (PAYG) or upfront (BYOL or FlexVM license). ARM-based images need to be declared using "**fortigate-arm64**" prefix instead of "**fortigate**".

At the time of writing the following family names are available:
- fortinet-64-byol
- fortinet-64-payg
- fortinet-70-byol
- fortinet-70-payg
- fortinet-72-byol
- fortinet-72-payg
- fortinet-arm64-72-byol
- fortinet-arm64-72-payg

To indicate family name pass it to the module as `family_name` variable. Eg.:

```
module fgt_ha {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]
  image_family  = "fortinet-70-byol"
}
```

> **Note**: family_name gets mapped to the newest image every time terraform template is run. Re-running the plan after deployment will detect a drift if a new firmware version was published in the meantime.

## Using image_name
Indicating explicit image name is useful for selecting precisely the firmware version and locking it down in case your terraform code is re-run often and drift problem described in previous section might be an issue.

To find the image name list images from Fortinet's public fortigcp-project-001 project:

```
gcloud compute images list --project fortigcp-project-001 --no-standard-images | grep fortinet-fgt
```

and provide desired image name as `image_name` module variable. Eg.:

```
module fgt_ha {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]
  image_name    = "fortinet-fgtondemand-6410-20220829-001-w-license"
}
```

## Custom images
If your deployment is using custom images, either derived from public ones or running an interim firmware build, pass to the module both `image_name` and `image_project` variables. Eg.:

```
module fgt_ha {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]
  image_name    = "my-fgt-image"
  image_project = "my-project"
}
```

***NOTE:*** if using a custom image with GVNIC support, you can use GVNIC driver by setting `nic_type`:

```
module fgt_ha {
  source        = "git::github.com/fortinet/terraform-google-fgt-ha-ap-lb"

  region        = "us-central1"
  subnets       = [ "external", "internal", "hasync", "mgmt" ]
  image_name    = "my-fgt-image"
  image_project = "my-project"
  nic_type      = "GVNIC"
}
```
