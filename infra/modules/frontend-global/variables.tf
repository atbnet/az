variable "env" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "origins" {
  description = "Map of regional origins to register on the AFD origin group, keyed by region_key."
  type = map(object({
    fqdn     = string
    priority = optional(number, 1)
    weight   = optional(number, 1000)
    enabled  = optional(bool, true)
  }))
}

variable "health_probe_path" {
  type    = string
  default = "/healthz"
}

variable "waf_mode" {
  description = "WAF mode: Prevention or Detection."
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "waf_mode must be Prevention or Detection."
  }
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
