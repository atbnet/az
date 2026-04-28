# Partial backend. Fill in at init:
#   terraform init -backend-config=envs/backends/<env>.hcl -reconfigure
terraform {
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
  }
}
