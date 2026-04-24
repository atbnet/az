variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "prd"], var.env)
    error_message = "env must be dev or prd."
  }
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "location" {
  description = "Region for the state storage account."
  type        = string
  default     = "westeurope"
}

variable "github_owner" {
  description = "GitHub org or user that owns the repo."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name (without the owner)."
  type        = string
}

variable "state_principals_group_object_ids" {
  description = "Additional Entra group object IDs granted Storage Blob Data Contributor on the state SA (e.g. platform team)."
  type        = list(string)
  default     = []
}

variable "tags" {
  type = map(string)
  default = {
    workload   = "web"
    managed_by = "terraform"
    purpose    = "bootstrap"
  }
}
