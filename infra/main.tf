resource "azurerm_resource_group" "global" {
  name     = local.global_rg
  location = local.primary_location
  tags     = merge(local.common_tags, { region = "global" })
}

module "global_observability" {
  source = "./modules/observability"

  name                = local.global_log_name
  resource_group_name = azurerm_resource_group.global.name
  location            = local.primary_location
  retention_days      = var.log_retention_days
  tags                = merge(local.common_tags, { region = "global" })
}

module "acr" {
  source = "./modules/acr"

  env                      = var.env
  resource_group_name      = azurerm_resource_group.global.name
  location                 = local.primary_location
  georeplication_locations = [for r in var.regions : r.location]
  retention_days           = 7
  tags                     = merge(local.common_tags, { region = "global" })
}

module "region" {
  for_each = var.regions
  source   = "./modules/regional"

  env                    = var.env
  region_key             = each.key
  location               = each.value.location
  vnet_cidr              = each.value.vnet_cidr
  node_vm_size           = each.value.node_vm_size
  node_min               = each.value.node_min
  node_max               = each.value.node_max
  log_retention_days     = var.log_retention_days
  acr_id                 = module.acr.id
  admin_group_object_ids = var.admin_group_object_ids
  tags                   = local.common_tags
}

module "front_door" {
  source = "./modules/frontend-global"

  env                        = var.env
  resource_group_name        = azurerm_resource_group.global.name
  origins                    = { for k, r in module.region : k => { fqdn = r.agc_frontend_fqdn } }
  waf_mode                   = var.waf_mode
  log_analytics_workspace_id = module.global_observability.id
  tags                       = merge(local.common_tags, { region = "global" })
}
