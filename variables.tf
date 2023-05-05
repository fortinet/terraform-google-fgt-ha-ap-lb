variable region {
  type        = string
  description = "Region to deploy all resources in. Must match var.zones if defined."
}

variable prefix {
  type        = string
  default     = "fgt"
  description = "This prefix will be added to all created resources"
}

variable zones {
  type        = list(string)
  default     = ["",""]
  description = "Names of zones to deploy FortiGate instances to matching the region variable. Defaults to first 2 zones in given region."
}

variable subnets {
  type        = list(string)
  description = "Names of four existing subnets to be connected to FortiGate VMs (external, internal, heartbeat, management)"
  validation {
    condition     = length(var.subnets) == 4
    error_message = "Please provide exactly 4 subnet names (external, internal, heartbeat, management)."
  }
}

variable frontends {
  type        = list(string)
  default     = []
  description = "List of public IP names to be linked or created as ELB frontend."
  validation {
    condition = length(var.frontends)<33
    error_message = "You can define up to 32 External IP addresses in this module."
  }
}

variable machine_type {
  type        = string
  default     = "e2-standard-4"
  description = "GCE machine type to use for VMs. Minimum 4 vCPUs are needed for 4 NICs"
}

variable service_account {
  type        = string
  default     = ""
  description = "E-mail of service account to be assigned to FortiGate VMs. Defaults to Default Compute Engine Account"
}

variable admin_acl {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "List of CIDRs allowed to connect to FortiGate management interfaces. Defaults to 0.0.0.0/0"
}

variable license_files {
  type        = list(string)
  default     = ["null","null"]
  description = "List of license (.lic) files to be applied for BYOL instances."
}

variable flexvm_tokens {
  type        = list(string)
  default     = ["",""]
  description = "List of FlexVM tokens to be applied during bootstrapping"
}

variable healthcheck_port {
  type        = number
  default     = 8008
  description = "Port used for LB health checks"
}

variable fgt_config {
  type        = string
  description = "(optional) Additional configuration script to be added to bootstrap"
  default     = ""
}

variable logdisk_size {
  type        = number
  description = "Size of the attached logdisk in GB"
  default     = 30
  validation {
    condition     = var.logdisk_size > 10
    error_message = "Log disk size cannot be smaller than 10GB."
  }
}

variable image_family {
  type        = string
  description = "Image family. Overriden by providing explicit image name"
  default     = "fortigate-72-payg"
  validation {
    condition     = can(regex("^fortigate-(arm64-)?[67][0-9]-(byol|payg)$", var.image_family))
    error_message = "The image_family is always in form 'fortigate-[major version]-[payg or byol]' (eg. 'fortigate-72-byol')."
  }
}

variable image_name {
  type        = string
  description = "Image name. If not empty overrides var.firmware_family"
  default     = ""
}

variable image_project {
  type        = string
  description = "Project hosting the image. Defaults to Fortinet public project"
  default     = "fortigcp-project-001"
}

variable api_accprofile {
  type        = string
  default     = ""
  description = "Role (accprofile) to be assigned to the 'terraform' API account on FortiGates. If left empty, the API user will not be created."
}

variable api_acl {
  type        = list(string)
  default     = []
  description = "List of CIDRs allowed to connect to FortiGate API (must not be 0.0.0.0/0). Defaults to empty list."
}

variable api_token_secret_name {
  type        = string
  description = "Name of Secret Manager secret to be created and used for storing FortiGate API token. If left to empty string the secret will not be created and token will be available in outputs only."
  default     = ""
}

variable labels {
  type        = map(string)
  description = "Map of labels to be applied to the VMs, disks, and forwarding rules"
  default     = {}
}

variable routes {
  type        = map(string)
  description = "name=>cidr map of routes to be introduced in internal network"
  default     = {
    "default" : "0.0.0.0/0"
    }
}

variable nic_type {
  type        = string
  description = "Type of NIC to use for FortiGates. Allowed values are GVNIC or VIRTIO_NET"
  default     = "VIRTIO_NET"
  validation {
    condition     = contains(["GVNIC", "VIRTIO_NET"], var.nic_type)
    error_message = "Unsupported value of nic_type variable. Allowed values are GVNIC or VIRTIO_NET."
  }
}

variable probe_loopback_ip {
  type        = string
  description = "IP address for an optional loopback health probe interface. Empty means no loopback interface will be created"
  default     = ""
  validation {
    condition     = anytrue([can(regex("$((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}^", var.probe_loopback_ip)), var.probe_loopback_ip==""])
    error_message = "Must be a proper IPv4 IP address or empty"
  }
}