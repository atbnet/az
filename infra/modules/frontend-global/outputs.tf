output "profile_id" {
  value = azurerm_cdn_frontdoor_profile.this.id
}

output "profile_name" {
  value = azurerm_cdn_frontdoor_profile.this.name
}

output "profile_resource_guid" {
  description = "AFD profile GUID that appears in the auto-injected X-Azure-FDID header."
  value       = azurerm_cdn_frontdoor_profile.this.resource_guid
}

output "endpoint_id" {
  value = azurerm_cdn_frontdoor_endpoint.this.id
}

output "endpoint_hostname" {
  description = "The *.z01.azurefd.net hostname clients will hit."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "waf_policy_id" {
  value = azurerm_cdn_frontdoor_firewall_policy.this.id
}
