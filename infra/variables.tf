variable "env" {
  description = "Environment name. Drives naming and sizing."
  type        = string
  validation {
    condition     = contains(["dev", "prd"], var.env)
    error_message = "env must be dev or prd."
  }
}

variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "regions" {
  description = "Map of regional deployments keyed by region_key (e.g. swc, usw)."
  type = map(object({
    location     = string
    vnet_cidr    = string
    node_vm_size = string
    node_min     = number
    node_max     = number
  }))
  validation {
    condition     = length(var.regions) >= 1
    error_message = "at least one region must be defined."
  }
}

variable "primary_region_key" {
  description = "Key within var.regions whose location anchors global resources (ACR, AFD, global RG)."
  type        = string
  default     = "swc"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "waf_mode" {
  description = "AFD WAF mode: Prevention or Detection."
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "waf_mode must be Prevention or Detection."
  }
}

variable "admin_group_object_ids" {
  description = "Entra group object IDs that get cluster-admin via AKS-managed AAD."
  type        = list(string)
  default     = []
}

variable "repo" {
  description = "GitHub owner/repo, applied as a common tag for traceability."
  type        = string
  default     = ""
}
