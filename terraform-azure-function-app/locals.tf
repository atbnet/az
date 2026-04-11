locals {
  name_suffix = "${var.name}-${var.environment}"

  # Storage account names must be globally unique, 3-24 lowercase alphanumeric chars.
  # Layout: "st" (2) + safe_name (≤14) + random suffix (6) + discriminator (1) = ≤23
  safe_name         = lower(replace("${var.name}${var.environment}", "-", ""))
  storage_func_name = "st${substr(local.safe_name, 0, 14)}${random_string.suffix.result}f"
  storage_data_name = "st${substr(local.safe_name, 0, 14)}${random_string.suffix.result}d"

  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
  })
}
