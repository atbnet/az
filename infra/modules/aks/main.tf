resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"
  node_resource_group = "mc-${var.name}"

  oidc_issuer_enabled          = true
  workload_identity_enabled    = true
  local_account_disabled       = true
  azure_policy_enabled         = true
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  automatic_upgrade_channel = "stable"
  node_os_upgrade_channel   = "NodeImage"

  tags = var.tags

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.node_subnet_id
    zones                        = ["1", "2", "3"]
    auto_scaling_enabled         = true
    min_count                    = 2
    max_count                    = 5
    only_critical_addons_enabled = true
    os_disk_type                 = "Ephemeral"
    os_sku                       = "AzureLinux"
    max_pods                     = 110
    temporary_name_for_rotation  = "systemtmp"
    tags                         = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_dataplane   = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = null
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "5m"
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  monitor_metrics {}

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Saturday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  lifecycle {
    ignore_changes = [
      # The autoscaler owns node_count at runtime.
      default_node_pool[0].node_count,
      # Kubernetes minor upgrades happen via the upgrade channel.
      kubernetes_version,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = var.node_subnet_id
  zones                 = ["1", "2", "3"]
  auto_scaling_enabled  = true
  min_count             = var.user_node_min
  max_count             = var.user_node_max
  os_disk_type          = "Ephemeral"
  os_sku                = "AzureLinux"
  max_pods              = 110
  mode                  = "User"

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

resource "azurerm_role_assignment" "acrpull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }
  enabled_log {
    category = "kube-audit-admin"
  }
  enabled_log {
    category = "kube-controller-manager"
  }
  enabled_log {
    category = "cluster-autoscaler"
  }
  enabled_log {
    category = "guard"
  }
  metric {
    category = "AllMetrics"
  }
}
