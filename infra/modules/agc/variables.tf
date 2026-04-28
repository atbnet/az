variable "name" {
  description = "AGC resource name, e.g. alb-web-prd-weu."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "alb_subnet_id" {
  description = "Delegated subnet ID for the AGC data plane (Microsoft.ServiceNetworking/trafficControllers)."
  type        = string
}

variable "frontend_name" {
  description = "Name of the AGC frontend resource. The Gateway references this via addresses."
  type        = string
  default     = "web-frontend"
}

variable "controller_identity_name" {
  description = "User-assigned managed identity name for the ALB Controller."
  type        = string
}

variable "aks_oidc_issuer_url" {
  type = string
}

variable "aks_controller_namespace" {
  description = "Kubernetes namespace where the ALB Controller runs."
  type        = string
  default     = "azure-alb-system"
}

variable "aks_controller_service_account" {
  description = "Service account name used by the ALB Controller deployment."
  type        = string
  default     = "alb-controller-sa"
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
