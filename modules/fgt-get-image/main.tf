terraform {
	required_providers {
	  google = {
		source = "hashicorp/google"
	  }
	}
}

locals {
	default_family = var.arch=="x86" ? "fortigate-74-${var.lic}" : "fortigate-arm64-74-${var.lic}"
	arch_post = substr(var.ver, 0, 2)=="7.2" && try(split(".", var.ver)[2] > 5, true) ? (var.arch=="arm" ? "arm64-" : "x64-" ) : ""
	arch_pre  = substr(var.ver, 0, 2)=="7.2" && try(split(".", var.ver)[2] > 5, true) ? "" : (var.arch=="arm" ? "arm64-" : "" )
	lic       = lower(var.lic)=="payg" ? "ondemand" : ""
	ver       = length(split(".", var.ver)) == 3 ? replace(var.ver, ".", "") : "${replace(var.ver, ".", "")}\\d{1,2}"
}


data "google_compute_image" "all" {
	project     = "fortigcp-project-001"
	# if version is set search by version else null filter
	filter      = var.ver != "" ? "name eq fortinet-fgt${local.lic}-${local.arch_pre}${local.ver}-\\d{8}-\\d{3}-${local.arch_post}.*" : null
	# if version is not defined, search by family or by default family as last resort
	family      = var.ver == "" ? (var.family == "" ? local.default_family : var.family ) : null
	most_recent = "true"
}


output "image" {
	value = data.google_compute_image.all
}

output "self_link" {
	value = data.google_compute_image.all.self_link
}
