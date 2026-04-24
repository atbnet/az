variable "name" {
  description = "Log Analytics workspace name, e.g. log-web-prd-weu or log-web-prd-global."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "retention_days" {
  description = "Log retention. Prd defaults to 90, dev to 30 via caller."
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 730
    error_message = "retention_days must be between 30 and 730."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
