locals {
  suffix   = "${var.env}-${var.region_key}"
  rg_name  = "rg-web-${local.suffix}"
  vnet     = "vnet-web-${local.suffix}"
  aks      = "aks-web-${local.suffix}"
  agc      = "alb-web-${local.suffix}"
  log_name = "log-web-${local.suffix}"
  id_alb   = "id-alb-${local.suffix}"

  tags = merge(var.tags, {
    env    = var.env
    region = var.region_key
  })
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../network"
  name                = local.vnet
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_cidr           = var.vnet_cidr
  tags                = local.tags
}

module "observability" {
  source              = "../observability"
  name                = local.log_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  retention_days      = var.log_retention_days
  tags                = local.tags
}

module "aks" {
  source                     = "../aks"
  name                       = local.aks
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  env                        = var.env
  dns_prefix                 = "web-${local.suffix}"
  node_subnet_id             = module.network.subnet_ids["nodes"]
  user_node_vm_size          = var.node_vm_size
  user_node_min              = var.node_min
  user_node_max              = var.node_max
  log_analytics_workspace_id = module.observability.id
  acr_id                     = var.acr_id
  admin_group_object_ids     = var.admin_group_object_ids
  tags                       = local.tags
}

module "agc" {
  source                     = "../agc"
  name                       = local.agc
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  alb_subnet_id              = module.network.subnet_ids["alb"]
  controller_identity_name   = local.id_alb
  aks_oidc_issuer_url        = module.aks.oidc_issuer_url
  log_analytics_workspace_id = module.observability.id
  tags                       = local.tags
}

# The AKS cluster's system-assigned identity needs Network Contributor
# on the VNet so it can configure internal LBs / route tables on pod
# networking and future internal-LB services.
resource "azurerm_role_assignment" "aks_vnet" {
  scope                = module.network.id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.cluster_identity_principal_id
  principal_type       = "ServicePrincipal"
}
