variable "region" {
  type        = string
  description = "Region to deploy all resources in. Must match var.zones if defined."
  nullable    = true
  default = null
}

variable "prefix" {
  type        = string
  default     = "fgt"
  description = "This prefix will be added to all created resources"
}

variable "zones" {
  type        = list(string)
  default     = ["", ""]
  description = "Names of zones to deploy FortiGate instances to matching the region variable. Defaults to first 2 zones in given region."
}

variable "subnets" {
  type        = list(string)
  description = "Names of four existing subnets to be connected to FortiGate VMs"
  validation {
    condition     = length(var.subnets) >= 2
    error_message = "Minimum 2 NICs required \n(provide at least 2 subnet names; first one will be used as external, the last one for HA and dedicated management)."
  }
  validation {
    condition     = length(var.subnets) <= 8
    error_message = "Too many NICs \n(Google Compute does not support more than 8 NICs per VM. Use one of hub-and-spoke architectures to connect more VPCs)."
  }
}

variable "frontends" {
  type        = list(string)
  default     = []
  description = "List of names for external IP addresses to be created or existing IP addresses to be linked as ELB frontend."
  validation {
    condition     = length(var.frontends) < 33
    error_message = "You can define up to 32 External IP addresses in this module."
  }
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-4"
  description = "GCE machine type to use for VMs. Minimum 4 vCPUs are needed for 4 NICs"
}

variable "service_account" {
  type        = string
  default     = ""
  description = "E-mail of service account to be assigned to FortiGate VMs. Defaults to Default Compute Engine Account"
}

variable "admin_acl" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDRs allowed to connect to FortiGate management interfaces. Defaults to 0.0.0.0/0"
}

variable "license_files" {
  type        = list(string)
  default     = ["", ""]
  description = "List of license (.lic) files to be applied for BYOL instances."
}

variable "flex_tokens" {
  type        = list(string)
  default     = ["", ""]
  description = "List of FortiFlex tokens to be applied during bootstrapping"
}

variable "healthcheck_port" {
  type        = number
  default     = 8008
  description = "Port used for LB health checks"
}

variable "fgt_config" {
  type        = string
  description = "(optional) Additional configuration script to be added to bootstrap"
  default     = ""
}

variable "logdisk_size" {
  type        = number
  description = "Size of the attached logdisk in GB"
  default     = 30
  validation {
    condition     = var.logdisk_size > 10
    error_message = "Log disk size cannot be smaller than 10GB."
  }
}

variable "image_family" {
  type        = string
  description = "(deprecated) Image family. Overriden by providing explicit image name"
  default     = ""
  validation {
    condition     = var.image_family == ""
    error_message = "Variable image_family is deprecated in this module version. Please use var.image.family instead."
  }
}

variable "image_name" {
  type        = string
  description = "(deprecated) image_name and image_family is deprecated. Please use image.name instead"
  default     = ""
  validation {
    condition     = var.image_name == ""
    error_message = "Variable image_name is deprecated in this module version. Please use var.image.name instead."
  }
}

variable "image_project" {
  type        = string
  description = "(deprecated) Project hosting the image. Defaults to Fortinet public project"
  default     = ""
  validation {
    condition     = var.image_project == ""
    error_message = "Variable image_project is deprecated in this module version. Please use var.image.project instead."
  }
}

variable "api_accprofile" {
  type        = string
  default     = ""
  description = "Role (accprofile) to be assigned to the 'terraform' API account on FortiGates. If left empty, the API user will not be created."
}

variable "api_acl" {
  type        = list(string)
  default     = []
  description = "List of CIDRs allowed to connect to FortiGate API (must not be 0.0.0.0/0). Defaults to empty list."
}

variable "api_token_secret_name" {
  type        = string
  description = "Name of Secret Manager secret to be created and used for storing FortiGate API token. If left to empty string the secret will not be created and token will be available in outputs only."
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "Map of labels to be applied to the VMs, disks, and forwarding rules"
  default     = {}
}

variable "routes" {
  type        = map(string)
  description = "name=>cidr map of routes to be introduced in internal network"
  default = {
    "default" : "0.0.0.0/0"
  }
}

variable "nic_type" {
  type        = string
  description = "Type of NIC to use for FortiGates. Allowed values are GVNIC or VIRTIO_NET"
  default     = "VIRTIO_NET"
  validation {
    condition     = contains(["GVNIC", "VIRTIO_NET"], var.nic_type)
    error_message = "Unsupported value of nic_type variable. Allowed values are GVNIC or VIRTIO_NET."
  }
}

variable "probe_loopback_ip" {
  type        = string
  description = "IP address for an optional loopback health probe interface. Empty means no loopback interface will be created"
  default     = ""
  validation {
    condition     = anytrue([can(regex("$((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}^", var.probe_loopback_ip)), var.probe_loopback_ip == ""])
    error_message = "Must be a proper IPv4 IP address or empty."
  }
}

variable "image" {
  type = object({
    project = optional(string, "fortigcp-project-001")
    name    = optional(string, "")
    family  = optional(string, "")
    version = optional(string, "")
    arch    = optional(string, "x64")
    license = optional(string, "payg")
  })
  description = "Indicate FortiOS image you want to deploy by specifying one of the following: image family name (as image.family); firmware version, architecture and licensing (as image.version, image.arch and image.lic); image name (as image.name) optionally with image project name for custom images (as image.project)."
  default = {
    version = "7.2.10" # mature, see https://community.fortinet.com/t5/FortiGate/Technical-Tip-Recommended-Release-for-FortiOS/ta-p/227178
  }
  validation {
    condition     = contains(["arm", "x64"], var.image.arch)
    error_message = "Value of image.arch must be either 'arm' or 'x64' (default: 'x64')."
  }
  validation {
    condition     = contains(["payg", "byol"], var.image.license)
    error_message = "Value of image.license can be either 'payg' or 'byol' (default: 'payg'). For FortiFlex use 'byol'."
  }
  validation {
    condition     = anytrue([length(split(".", var.image.version)) == 3, length(split(".", var.image.version)) == 2, var.image.version == ""])
    error_message = "Value of image.version can be either null or contain FortiOS version in 3-digit format (eg. \"7.4.1\") or major version in 2-digit format (eg. \"7.4\")."
  }
}

variable "ha_port" {
  type        = string
  nullable    = true
  default     = null
  description = "Enforce a custom HA port instead of the last one. Provide value as FortiGate port name (eg. \"port3\")"
}

variable "mgmt_port" {
  type        = string
  nullable    = true
  default     = null
  description = "Enforce a custom management port instead of the last one. Provide value as FortiGate port name (eg. \"port3\")"
}

variable "oslogin_enable" {
  type        = bool
  default     = false
  description = "Set to true to enable the OSLogin for FortiGate VM instances."
}

variable "serial_port_enable" {
  type        = bool
  default     = false
  description = "Set to true to enable access through serial console"
}

variable "ports_external" {
  type = list(string)
  description = "List of ports treated as external. By default [port1]"
  default = ["port1"]
}