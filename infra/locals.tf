locals {
  global_rg       = "rg-web-${var.env}-global"
  global_log_name = "log-web-${var.env}-global"

  primary_location = var.regions[var.primary_region_key].location

  common_tags = merge(
    {
      workload   = "web"
      env        = var.env
      managed_by = "terraform"
    },
    var.repo == "" ? {} : { repo = var.repo },
  )
}
