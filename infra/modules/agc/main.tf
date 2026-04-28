resource "azurerm_application_load_balancer" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_application_load_balancer_subnet_association" "this" {
  name                         = "${var.name}-sub"
  application_load_balancer_id = azurerm_application_load_balancer.this.id
  subnet_id                    = var.alb_subnet_id
  tags                         = var.tags
}

resource "azurerm_application_load_balancer_frontend" "this" {
  name                         = var.frontend_name
  application_load_balancer_id = azurerm_application_load_balancer.this.id
  tags                         = var.tags
}

# User-assigned identity used by the in-cluster ALB Controller (installed
# via Helm in a post-apply workflow step). The controller federates into
# Azure via AKS's OIDC issuer.
resource "azurerm_user_assigned_identity" "controller" {
  name                = var.controller_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "controller" {
  name                = "alb-controller"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.controller.id
  subject             = "system:serviceaccount:${var.aks_controller_namespace}:${var.aks_controller_service_account}"
}

# Role required by the ALB Controller to read/update the AGC config.
resource "azurerm_role_assignment" "controller_config_manager" {
  scope                = azurerm_application_load_balancer.this.id
  role_definition_name = "AppGw for Containers Configuration Manager"
  principal_id         = azurerm_user_assigned_identity.controller.principal_id
  principal_type       = "ServicePrincipal"
}

# Needed so the controller can look up the delegated subnet.
resource "azurerm_role_assignment" "controller_network_reader" {
  scope                = var.alb_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.controller.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_monitor_diagnostic_setting" "agc" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_application_load_balancer.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}
