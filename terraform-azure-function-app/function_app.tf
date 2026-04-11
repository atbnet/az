# ---------------------------------------------------------------------------
# Package the Python function code into a zip for deployment
# ---------------------------------------------------------------------------
data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/.terraform/function.zip"
}

# ---------------------------------------------------------------------------
# Consumption (serverless) App Service Plan
# ---------------------------------------------------------------------------
resource "azurerm_service_plan" "this" {
  name                = "asp-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# RBAC: managed identity → function runtime storage (AzureWebJobsStorage)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "func_webjobs_blob_owner" {
  scope                = azurerm_storage_account.func.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "func_webjobs_queue_contributor" {
  scope                = azurerm_storage_account.func.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_role_assignment" "func_webjobs_table_contributor" {
  scope                = azurerm_storage_account.func.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

# ---------------------------------------------------------------------------
# RBAC: managed identity → data storage (blob read/write)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "func_data_blob_contributor" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

# ---------------------------------------------------------------------------
# Linux Function App – Python runtime
# ---------------------------------------------------------------------------
resource "azurerm_linux_function_app" "this" {
  name                        = "func-${local.name_suffix}"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  service_plan_id             = azurerm_service_plan.this.id
  functions_extension_version = "~4"

  # Use managed identity for AzureWebJobsStorage – no connection strings stored.
  storage_account_name          = azurerm_storage_account.func.name
  storage_uses_managed_identity = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  site_config {
    application_stack {
      python_version = var.python_version
    }
  }

  app_settings = {
    # Monitoring
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.this.connection_string

    # Runtime
    "FUNCTIONS_WORKER_RUNTIME" = "python"

    # Managed-identity credentials for AzureWebJobsStorage (per-service URIs required
    # when a user-assigned identity is used instead of the default system identity).
    "AzureWebJobsStorage__accountName" = azurerm_storage_account.func.name
    "AzureWebJobsStorage__clientId"    = azurerm_user_assigned_identity.this.client_id
    "AzureWebJobsStorage__credential"  = "managedidentity"

    # Data storage settings consumed by the Python function
    "DATA_STORAGE_ACCOUNT_URL" = azurerm_storage_account.data.primary_blob_endpoint
    "DATA_BLOB_CONTAINER_NAME" = azurerm_storage_container.data.name
    "DATA_STORAGE_CLIENT_ID"   = azurerm_user_assigned_identity.this.client_id

    # Run from deployment zip package
    "WEBSITE_RUN_FROM_PACKAGE" = "1"

    # Forces a re-deploy when function source code changes
    "FUNCTION_APP_CODE_HASH" = data.archive_file.function.output_sha256
  }

  zip_deploy_file = data.archive_file.function.output_path

  tags = local.common_tags

  # Ensure all RBAC assignments exist before the app starts so the managed
  # identity can authenticate to storage on the very first boot.
  depends_on = [
    azurerm_role_assignment.func_webjobs_blob_owner,
    azurerm_role_assignment.func_webjobs_queue_contributor,
    azurerm_role_assignment.func_webjobs_table_contributor,
    azurerm_role_assignment.func_data_blob_contributor,
  ]
}
