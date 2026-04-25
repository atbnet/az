env = "dev"

# Replace with your tenant + subscription IDs, or pass via -var / env.
# tenant_id       = "00000000-0000-0000-0000-000000000000"
# subscription_id = "00000000-0000-0000-0000-000000000000"

primary_region_key = "swc"

regions = {
  swc = {
    location     = "swedencentral"
    vnet_cidr    = "10.10.0.0/16"
    node_vm_size = "Standard_D2ds_v5"
    node_min     = 2
    node_max     = 5
  }
  uks = {
    location     = "uksouth"
    vnet_cidr    = "10.20.0.0/16"
    node_vm_size = "Standard_D2ds_v5"
    node_min     = 2
    node_max     = 5
  }
}

log_retention_days = 30
waf_mode           = "Detection"

admin_group_object_ids = []
