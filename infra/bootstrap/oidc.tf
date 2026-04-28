# Per-env Entra app registration + federated credentials for GitHub OIDC.
# GitHub Environments (`dev` / `prd`) are the trust boundary: only a
# workflow running in that environment can assume the identity.

data "azuread_client_config" "current" {}

resource "azuread_application" "gha" {
  display_name = "github-web-${var.env}"
  owners       = [data.azuread_client_config.current.object_id]
  description  = "OIDC identity used by GitHub Actions to deploy the web workload (env=${var.env})."

  required_resource_access {
    # Microsoft Graph — no API perms strictly required for Terraform here,
    # but declared for clarity if AAD group lookups are added later.
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read (delegated)
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "gha" {
  client_id                    = azuread_application.gha.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Federated credential tied to the GitHub Environment matching this env.
resource "azuread_application_federated_identity_credential" "env" {
  application_id = azuread_application.gha.id
  display_name   = "gh-${var.env}"
  description    = "GitHub Actions jobs running under environment=${var.env}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_owner}/${var.github_repo}:environment:${var.env}"
}

# Optional: allow PR workflows (plan-only jobs) that don't bind to an
# Environment. For prd this subject is deliberately narrow.
resource "azuread_application_federated_identity_credential" "pull_request" {
  count          = var.env == "dev" ? 1 : 0
  application_id = azuread_application.gha.id
  display_name   = "gh-${var.env}-pr"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_owner}/${var.github_repo}:pull_request"
}

# Subscription-level Contributor so Terraform can provision everything.
# Tighten to a more scoped role assignment later if wanted.
resource "azurerm_role_assignment" "gha_subscription_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.gha.object_id
  principal_type       = "ServicePrincipal"
}

# User Access Administrator is needed so Terraform can create role
# assignments (e.g. AcrPull for the AKS kubelet identity).
resource "azurerm_role_assignment" "gha_uaa" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.gha.object_id
  principal_type       = "ServicePrincipal"
  condition_version    = "2.0"
  condition            = <<-COND
    (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
      OR
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId]
        ForAnyOfAnyValues:GuidEquals {
          7f951dda-4ed3-4680-a7ca-43fe172d538d,
          acdd72a7-3385-48ef-bd42-f606fba81ae7,
          4633458b-17de-408a-b874-0445c86b69e6,
          b24988ac-6180-42a0-ab88-20f7382dd24c,
          4d97b98b-1d4f-4787-a291-c67834d212e7,
          fbdf93bf-df7d-467e-a4d2-9458aa1360c8
        }
    )
  COND
}

# State storage: give the GHA principal Blob Data Contributor so it can
# read/write the tfstate blob.
resource "azurerm_role_assignment" "gha_state" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.gha.object_id
  principal_type       = "ServicePrincipal"
}
