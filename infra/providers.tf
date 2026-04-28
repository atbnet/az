provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }

  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  use_oidc                        = true
  storage_use_azuread             = true
  resource_provider_registrations = "core"
}

provider "azuread" {
  tenant_id = var.tenant_id
  use_oidc  = true
}
