locals {
  profile_name  = "afd-web-${var.env}"
  endpoint_name = "afde-web-${var.env}"
  waf_name      = "wafweb${var.env}"
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = local.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags

  response_timeout_seconds = 60
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = local.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled                  = true
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "og-web-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = var.health_probe_path
    protocol            = "Https"
    interval_in_seconds = 30
    request_type        = "GET"
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.origins

  name                          = "origin-${each.key}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  enabled                       = each.value.enabled

  host_name          = each.value.fqdn
  origin_host_header = each.value.fqdn
  http_port          = 80
  https_port         = 443
  priority           = each.value.priority
  weight             = each.value.weight

  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "route-web-${var.env}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [for o in azurerm_cdn_frontdoor_origin.this : o.id]
  enabled                       = true
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]
  link_to_default_domain        = true
  cdn_frontdoor_rule_set_ids    = []
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = local.waf_name
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.this.sku_name
  enabled             = true
  mode                = var.waf_mode
  tags                = var.tags

  custom_block_response_status_code = 403

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.1"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "secpol-web-${var.env}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        patterns_to_match = ["/*"]
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "afd" {
  name                       = "diag-${local.profile_name}"
  target_resource_id         = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FrontDoorAccessLog"
  }
  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }
  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }
}
