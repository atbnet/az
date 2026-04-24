data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  tags = merge(var.tags, { env = var.env })

  state_rg  = "rg-web-tfstate-${var.env}"
  state_sa  = "stwebtfst${var.env}${random_string.suffix.result}"
  state_ctr = "tfstate"
}

resource "azurerm_resource_group" "state" {
  name     = local.state_rg
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                     = local.state_sa
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "state" {
  name                  = local.state_ctr
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

# Grant the bootstrap runner (the human executing this) access to read/write
# state while standing things up. GitHub Actions gets its own grant via the
# app reg below.
resource "azurerm_role_assignment" "state_current_user" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "state_extra_groups" {
  for_each             = toset(var.state_principals_group_object_ids)
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
  principal_type       = "Group"
}

# Generate the backend HCL file next to the env's tfvars so the CI
# workflow can `-backend-config=envs/backends/<env>.hcl` after bootstrap.
resource "local_file" "backend_hcl" {
  filename        = "${path.module}/../envs/backends/${var.env}.hcl"
  file_permission = "0644"
  content         = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.state.name}"
    key                  = "env.tfstate"
    use_azuread_auth     = true
    use_oidc             = true
  EOT
}
