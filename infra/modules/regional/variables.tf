variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "prd"], var.env)
    error_message = "env must be dev or prd."
  }
}

variable "region_key" {
  description = "Short region key used in resource names (e.g. weu, neu)."
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,4}$", var.region_key))
    error_message = "region_key must be 2-4 lowercase letters."
  }
}

variable "location" {
  description = "Azure region (e.g. westeurope)."
  type        = string
}

variable "vnet_cidr" {
  type = string
}

variable "node_vm_size" {
  type = string
}

variable "node_min" {
  type = number
}

variable "node_max" {
  type = number
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "acr_id" {
  description = "ACR resource ID for AcrPull role assignment on kubelet identity."
  type        = string
}

variable "admin_group_object_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
