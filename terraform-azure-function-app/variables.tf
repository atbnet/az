variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "name" {
  description = "Base name used as a prefix for all resources."
  type        = string
  default     = "blobfunc"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,16}$", var.name))
    error_message = "name must be 1-16 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Environment label (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.environment))
    error_message = "environment must be 1-8 lowercase alphanumeric characters."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "python_version" {
  description = "Python runtime version for the function app."
  type        = string
  default     = "3.11"

  validation {
    condition     = contains(["3.10", "3.11"], var.python_version)
    error_message = "python_version must be one of: 3.10, 3.11."
  }
}

variable "blob_container_name" {
  description = "Name of the blob container used for data read/write operations."
  type        = string
  default     = "data"

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])$", var.blob_container_name))
    error_message = "blob_container_name must be 3-63 characters, contain only lowercase letters, numbers, or hyphens, and start and end with a letter or number."
  }
}

variable "tags" {
  description = "Additional tags applied to every resource."
  type        = map(string)
  default     = {}
}
