# Values come from `infra/bootstrap` outputs for env=prd.
resource_group_name  = "rg-web-tfstate-prd"
storage_account_name = "REPLACE_AFTER_BOOTSTRAP"
container_name       = "tfstate"
key                  = "env.tfstate"
use_azuread_auth     = true
use_oidc             = true
