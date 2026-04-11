resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.common_tags
}

# User-assigned managed identity is created before the function app so that
# RBAC assignments are in place before the app first starts, avoiding the
# race condition that exists with system-assigned identities.
resource "azurerm_user_assigned_identity" "this" {
  name                = "id-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.common_tags
}
