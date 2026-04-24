# Values come from `infra/bootstrap` outputs for env=dev.
# Populate storage_account_name with the generated name from bootstrap.
resource_group_name  = "rg-web-tfstate-dev"
storage_account_name = "REPLACE_AFTER_BOOTSTRAP"
container_name       = "tfstate"
key                  = "env.tfstate"
use_azuread_auth     = true
use_oidc             = true
