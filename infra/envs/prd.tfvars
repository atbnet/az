env = "prd"

# tenant_id       = "00000000-0000-0000-0000-000000000000"
# subscription_id = "00000000-0000-0000-0000-000000000000"

primary_region_key = "swc"

regions = {
  swc = {
    location     = "swedencentral"
    vnet_cidr    = "10.30.0.0/16"
    node_vm_size = "Standard_D4ds_v5"
    node_min     = 3
    node_max     = 10
  }
  usw = {
    location     = "westus"
    vnet_cidr    = "10.40.0.0/16"
    node_vm_size = "Standard_D4ds_v5"
    node_min     = 3
    node_max     = 10
  }
}

log_retention_days = 90
waf_mode           = "Prevention"

admin_group_object_ids = []
