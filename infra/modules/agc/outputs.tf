output "id" {
  value = azurerm_application_load_balancer.this.id
}

output "name" {
  value = azurerm_application_load_balancer.this.name
}

output "primary_configuration_endpoint" {
  description = "Configuration FQDN of the AGC (control plane)."
  value       = azurerm_application_load_balancer.this.primary_configuration_endpoint
}

output "frontend_id" {
  value = azurerm_application_load_balancer_frontend.this.id
}

output "frontend_name" {
  value = azurerm_application_load_balancer_frontend.this.name
}

output "frontend_fqdn" {
  description = "Public *.fzxx.alb.azure.com FQDN used as the AFD origin."
  value       = azurerm_application_load_balancer_frontend.this.fully_qualified_domain_name
}

output "alb_subnet_id" {
  value = var.alb_subnet_id
}

output "controller_identity_id" {
  value = azurerm_user_assigned_identity.controller.id
}

output "controller_identity_client_id" {
  value = azurerm_user_assigned_identity.controller.client_id
}

output "controller_identity_principal_id" {
  value = azurerm_user_assigned_identity.controller.principal_id
}
