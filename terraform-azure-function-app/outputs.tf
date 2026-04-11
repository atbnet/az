output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "function_app_name" {
  description = "Name of the function app."
  value       = azurerm_linux_function_app.this.name
}

output "function_app_hostname" {
  description = "Default hostname of the function app."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "function_app_id" {
  description = "Resource ID of the function app."
  value       = azurerm_linux_function_app.this.id
}

output "data_storage_account_name" {
  description = "Name of the data storage account."
  value       = azurerm_storage_account.data.name
}

output "data_blob_container_name" {
  description = "Name of the blob container used for data read/write operations."
  value       = azurerm_storage_container.data.name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.client_id
}
