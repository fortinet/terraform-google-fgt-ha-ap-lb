# Selecting base image for FortiGate instances (new)

*Important: Version 1.1 of this module introduces new way to define the base image for the FortiGate VMs using a single `image` object variable and replacing variables `image_name`, `image_family`, `image_project`.*

In virtual deployments administrators tend to deploy the exact desired version of FortiGates rather than go through multiple steps of upgrading/downgrading the firmware. Fortinet publishes all versions in its public project, so the customers can use them instead of downloading images from Fortinet support website.

Each base image used to create FortiGate virtual machines in Google Cloud can be identified using 3 attributes:
- firmware version
- architecture (arm or x64) - image architecture must match the processor architecture of the selected [machine type](https://cloud.google.com/compute/docs/machine-resource)
- license type - Fortinet offers separate images for PAYG and BYOL/FortiFlex deployments

By default, the FortiGates will be deployed with the 7.2.8 version and PAYG licensing on Intel-based platform. If you want to use a different firmware version, licensing or ARM-based VM instance - you must change the image by declaring the module `image` object variable with the desired properties.

## Selecting image by firmware version

In order to deploy a desired version of the firmware using one of the official images published by Fortinet in Google Cloud marketplace you can set the `image.version` property. You can use either the full (3-number) version of the firmware or a shortened (2-number) branch version letting the module select the newest firmware available in a given branch.

```
module "fgt_ha" {
  [...]

  # use version 7.4.4
  image = {
    version = "7.4.4"
  }
}
```

or 

```
module "fgt_ha" {
  [...]

  # use newest version from 7.4 branch
  image = {
    version = "7.4"
  }
}
```

Using branch number as version can result in terraform detecting a drift after Fortinet releases new version. See [Branch numbers and terraform drift detection](#branch-numbers-and-terraform-drift-detection) section below for more details.

*Note that using `version` with only branch number should be equivalent to defining image family, but is using different metadata to select the image. Only one of `version` or `family` can be used in module input.*

### Licensing and images

Due to the way how cloud marketplaces work **PAYG** vs. **BYOL/FortiFlex** licensing uses different base images. You cannot switch between these two licensing types without re-deploying the VM instance. This is why it's extremely important to select the correct image.

BYOL vs PAYG image can be selected using `image.license` variable:

```
module "fgt_ha" {
  [...]

  # use 7.4.4 version with BYOL or FortiFlex license
  image = {
    license = "byol"
    version = "7.4.4"
  }
}
```

### Architecture

If deploying on ARM-based machine types, you need to indicate ARM-based image using the `image.arch` variable:

```
module "fgt_ha" {
  [...]

  image = {
    license = "byol"
    version = "7.4.4"
    arch    = "arm"
  }
}
```

## Using image family
*Family name* is the easy shortcut to select the latest images published by Fortinet and supports both BYOL and PAYG deployments. *Image families* are a feature of Google Compute automatically selecting the latest image of a given family. As Fortinet customers often decide to not use the latest firmware branch, images are published with separate families for each main branch (6.4, 7.0, 7.2). You will also need to decide if the image license should be paid via Google Cloud Marketplace per time used (PAYG) or upfront (BYOL or FlexVM license). ARM-based images need to be declared using "**fortigate-arm64**" prefix instead of "**fortigate**".

At the time of writing the following family names are available:
- fortigate-70-byol
- fortigate-70-payg
- fortigate-72-byol
- fortigate-72-payg
- fortigate-arm64-72-byol
- fortigate-arm64-72-payg
- fortigate-74-byol
- fortigate-74-payg
- fortigate-arm64-74-byol
- fortigate-arm64-74-payg
- fortigate-76-byol
- fortigate-76-payg
- fortigate-arm64-76-byol
- fortigate-arm64-76-payg

To indicate family name pass it to the module as `family` property of `image` variable. Eg.:

```
module "fgt_ha" {
  [...]

  image = {
    family  = "fortigate-76-byol"
  }
}
```

> **Note**: family_name gets mapped to the newest image every time terraform template is run. Re-running the plan after deployment will detect a drift if a new firmware version was published in the meantime. See [Branch numbers and terraform drift detection](#branch-numbers-and-terraform-drift-detection) section below for more details.

## Using image name
Indicating explicit image name can be used instead of version/licensing/architecture for selecting precisely the firmware version and locking it down in case your terraform code is re-run often and drift problem described in previous section might be an issue.

To find the image name list images from Fortinet's public fortigcp-project-001 project:

```
gcloud compute images list --project fortigcp-project-001 --no-standard-images | grep fortinet-fgt
```

and provide desired image name as `image.name` module variable. Eg.:

```
module "fgt_ha" {
  [...]

  image = {
    name    = "fortinet-fgtondemand-6410-20220829-001-w-license"
  }
}
```

### Private custom images
If your deployment is using custom images, either derived from public ones or running an interim firmware build, you can add the project name to the image name. Eg.:

```
module "fgt_ha" {
  [...]

  image = {
    name    = "my-fgt-image"
    project = "my-project"
  }
}
```

***NOTE:*** if using a custom image with GVNIC support, you can use GVNIC driver by setting `nic_type`:

```
module "fgt_ha" {
  [...]

  image = {
    name    = "my-fgt-image"
    project = "my-project"
  }
  nic_type      = "GVNIC"
}
```

## Branch numbers and terraform drift detection

Using `family` or the `version` property with only branch number does not indicate uniquely the image in the terraform code but rather offloads finding the newest available image to Google Compute or to the terraform module respectively. This means that every time terraform refresh is performed (which happens at every `terraform plan` execution) the module will try to find the newest image matching the definition in the code. If Fortinet releases new image with the same branch number terraform will detect and report a drift. While this does not have to be a problem in every deployment, you should be aware of the consequences of not selecting precisely the image.