output "env" {
  value = var.env
}

output "global_resource_group" {
  value = azurerm_resource_group.global.name
}

output "acr_name" {
  value = module.acr.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "afd_endpoint_hostname" {
  description = "Public hostname clients hit (e.g. afde-web-prd-xxxx.z01.azurefd.net)."
  value       = module.front_door.endpoint_hostname
}

output "afd_profile_id" {
  value = module.front_door.profile_id
}

output "afd_profile_resource_guid" {
  description = "AFD profile GUID used by downstream origin FDID verification."
  value       = module.front_door.profile_resource_guid
}

# Map of per-region outputs consumed by the deploy workflow to target
# each cluster and wire the Helm chart into the correct AGC frontend.
output "clusters" {
  description = "Per-region cluster + AGC info, keyed by region_key."
  value = {
    for k, r in module.region : k => {
      region_key                    = k
      location                      = r.location
      resource_group                = r.resource_group_name
      aks_name                      = r.aks_name
      aks_node_resource_group       = r.aks_node_resource_group
      aks_oidc_issuer_url           = r.aks_oidc_issuer_url
      alb_subnet_id                 = r.alb_subnet_id
      agc_name                      = r.agc_name
      agc_frontend_name             = r.agc_frontend_name
      agc_frontend_fqdn             = r.agc_frontend_fqdn
      controller_identity_client_id = r.controller_identity_client_id
      log_analytics_workspace_id    = r.log_analytics_workspace_id
    }
  }
}
