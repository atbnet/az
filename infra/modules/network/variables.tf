variable "name" {
  description = "VNet name, e.g. vnet-web-prd-weu."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_cidr" {
  description = "Primary address space for the VNet."
  type        = string
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "vnet_cidr must be a valid CIDR block."
  }
}

variable "subnet_newbits" {
  description = "Newbits added to vnet_cidr when carving subnets. Default produces /24s from a /16."
  type        = number
  default     = 8
}

variable "tags" {
  type    = map(string)
  default = {}
}
