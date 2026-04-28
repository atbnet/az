resource "random_string" "suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  name = "acrweb${var.env}global${random_string.suffix.result}"
}

resource "azurerm_container_registry" "this" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = true
  zone_redundancy_enabled       = true
  anonymous_pull_enabled        = false
  data_endpoint_enabled         = true
  export_policy_enabled         = true
  tags                          = var.tags

  retention_policy_in_days = var.retention_days
  trust_policy_enabled     = true

  dynamic "georeplications" {
    for_each = toset([for r in var.georeplication_locations : r if r != var.location])
    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }
}
