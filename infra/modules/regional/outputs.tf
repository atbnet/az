output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = var.location
}

output "vnet_id" {
  value = module.network.id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "aks_name" {
  value = module.aks.name
}

output "aks_id" {
  value = module.aks.id
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "aks_node_resource_group" {
  value = module.aks.node_resource_group
}

output "agc_id" {
  value = module.agc.id
}

output "agc_name" {
  value = module.agc.name
}

output "agc_frontend_fqdn" {
  description = "Public FQDN of the AGC frontend, used as the AFD origin host."
  value       = module.agc.frontend_fqdn
}

output "agc_frontend_name" {
  value = module.agc.frontend_name
}

output "alb_subnet_id" {
  value = module.network.subnet_ids["alb"]
}

output "controller_identity_client_id" {
  description = "Client ID of the ALB Controller user-assigned identity, passed to the Helm chart."
  value       = module.agc.controller_identity_client_id
}

output "log_analytics_workspace_id" {
  value = module.observability.id
}
