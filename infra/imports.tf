# One-shot imports for resources that pre-existed Terraform management.
# Each block is idempotent: once the resource is in state, Terraform ignores it.

import {
  to = module.region["swc"].module.agc.azurerm_application_load_balancer_subnet_association.this
  id = "/subscriptions/${var.subscription_id}/resourceGroups/rg-web-dev-swc/providers/Microsoft.ServiceNetworking/trafficControllers/alb-web-dev-swc/associations/alb-web-dev-swc-sub"
}
