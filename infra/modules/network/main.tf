locals {
  subnets = {
    nodes = { index = 0 }
    alb   = { index = 1 }
    pe    = { index = 2 }
  }
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                 = "snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, var.subnet_newbits, each.value.index)]

  private_endpoint_network_policies             = each.key == "pe" ? "Disabled" : "Enabled"
  private_link_service_network_policies_enabled = each.key != "pe"

  dynamic "delegation" {
    for_each = each.key == "alb" ? [1] : []
    content {
      name = "Microsoft.ServiceNetworking.trafficControllers"
      service_delegation {
        name    = "Microsoft.ServiceNetworking/trafficControllers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnets

  name                = "nsg-${each.key}-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# AGC subnet: only allow ingress from Azure Front Door's backend pool.
resource "azurerm_network_security_rule" "alb_allow_afd" {
  name                        = "allow-afd-backend"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this["alb"].name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "AzureFrontDoor.Backend"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "alb_allow_azure_lb" {
  name                        = "allow-azure-lb"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this["alb"].name
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "alb_deny_internet" {
  name                        = "deny-internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this["alb"].name
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
