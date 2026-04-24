output "state_resource_group_name" {
  value = azurerm_resource_group.state.name
}

output "state_storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "state_container_name" {
  value = azurerm_storage_container.state.name
}

output "backend_hcl_path" {
  description = "Path of the generated backend config file."
  value       = local_file.backend_hcl.filename
}

output "github_oidc_client_id" {
  description = "Value for the AZURE_CLIENT_ID secret/variable in GitHub Actions."
  value       = azuread_application.gha.client_id
}

output "github_oidc_application_object_id" {
  value = azuread_application.gha.object_id
}

output "github_oidc_service_principal_object_id" {
  value = azuread_service_principal.gha.object_id
}

output "tenant_id" {
  value = var.tenant_id
}

output "subscription_id" {
  value = var.subscription_id
}
