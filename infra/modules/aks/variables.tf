variable "name" {
  description = "AKS cluster name, e.g. aks-web-prd-weu."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "env" {
  type = string
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS API server hostname."
}

variable "node_subnet_id" {
  type = string
}

variable "pod_cidr" {
  description = "Pod CIDR for Azure CNI Overlay. Must not overlap with vnet_cidr."
  type        = string
  default     = "100.64.0.0/16"
}

variable "service_cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "172.20.0.10"
}

variable "kubernetes_version" {
  description = "AKS minor version. Null keeps the current default."
  type        = string
  default     = null
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D4ds_v5"
}

variable "user_node_vm_size" {
  type = string
}

variable "user_node_min" {
  type = number
}

variable "user_node_max" {
  type = number
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "acr_id" {
  description = "ACR resource ID for AcrPull role assignment on kubelet identity."
  type        = string
}

variable "admin_group_object_ids" {
  description = "Entra group object IDs that get cluster-admin via AKS-managed AAD."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
