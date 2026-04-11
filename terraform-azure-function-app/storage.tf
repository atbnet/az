# ---------------------------------------------------------------------------
# Function runtime storage (AzureWebJobsStorage)
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "func" {
  name                     = local.storage_func_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Data storage – the function reads and writes blobs here
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "data" {
  name                     = local.storage_data_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags
}

# Private container for data blobs
resource "azurerm_storage_container" "data" {
  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}
