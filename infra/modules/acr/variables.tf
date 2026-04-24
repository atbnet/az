variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "prd"], var.env)
    error_message = "env must be dev or prd."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  description = "Primary ACR location."
  type        = string
}

variable "georeplication_locations" {
  description = "Additional Azure regions to replicate the registry to."
  type        = list(string)
  default     = []
}

variable "retention_days" {
  description = "Untagged manifest retention in days."
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
