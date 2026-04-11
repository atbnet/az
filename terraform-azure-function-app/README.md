# Azure Function App – Blob Read/Write

Terraform configuration (≥ 1.11) + azurerm provider (≥ 4.60) that deploys a Python Azure Function App capable of reading and writing Azure Blob Storage.

## Architecture

```
Resource Group
├── User-Assigned Managed Identity          id-<name>-<env>
├── Storage Account (function runtime)      st<name><env><rand>f
├── Storage Account (data blobs)            st<name><env><rand>d
│   └── Blob Container                      data
├── Log Analytics Workspace                 law-<name>-<env>
├── Application Insights                    appi-<name>-<env>
├── App Service Plan (Consumption Y1)       asp-<name>-<env>
└── Linux Function App (Python)             func-<name>-<env>
```

## Security posture

| Concern | Approach |
|---------|----------|
| Storage authentication | User-assigned managed identity – no connection strings in app settings |
| RBAC for runtime storage | `Storage Blob Data Owner` + `Storage Queue Data Contributor` + `Storage Table Data Contributor` |
| RBAC for data storage | `Storage Blob Data Contributor` |
| TLS | Minimum TLS 1.2 on all storage accounts |
| Public blob access | Disabled on all storage accounts |
| RBAC race condition | User-assigned identity created and RBAC assigned *before* function app; `depends_on` enforces ordering |

## Function API

Both endpoints require a function-level key (`?code=<key>` or `x-functions-key` header).

### Read a blob
```
GET https://<hostname>/api/blobs/{name}?code=<function-key>
```
Returns the blob content as `application/octet-stream` (HTTP 200), or HTTP 404 if the blob does not exist.

### Write a blob
```
POST https://<hostname>/api/blobs/{name}?code=<function-key>
Content-Type: application/octet-stream

<body is stored as the blob content>
```
Creates or overwrites the blob (HTTP 201).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.11
- Azure CLI authenticated: `az login`
- Azure subscription with the following resource providers registered:
  - `Microsoft.Web`
  - `Microsoft.Storage`
  - `Microsoft.Insights`
  - `Microsoft.OperationalInsights`
  - `Microsoft.ManagedIdentity`

## Quickstart

```bash
cd terraform-azure-function-app

# 1. Copy and edit the example variables file
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars          # set subscription_id at minimum

# 2. Initialise providers
terraform init

# 3. Review the plan
terraform plan

# 4. Deploy
terraform apply
```

After a successful apply, retrieve the function URL:

```bash
terraform output function_app_hostname
```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `subscription_id` | string | – | **Required.** Azure subscription ID. |
| `name` | string | `blobfunc` | Base name prefix for all resources (1-16 lowercase alphanumeric / hyphens). |
| `environment` | string | `dev` | Environment label (1-8 lowercase alphanumeric). |
| `location` | string | `eastus` | Azure region. |
| `python_version` | string | `3.11` | Python runtime (`3.10` or `3.11`). |
| `blob_container_name` | string | `data` | Blob container name for data operations. |
| `tags` | map(string) | `{}` | Additional tags applied to all resources. |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Resource group name. |
| `function_app_name` | Function app name. |
| `function_app_hostname` | Default hostname. |
| `function_app_id` | Resource ID. |
| `data_storage_account_name` | Data storage account name. |
| `data_blob_container_name` | Blob container name. |
| `application_insights_connection_string` | App Insights connection string (sensitive). |
| `managed_identity_client_id` | Client ID of the managed identity. |

## Remote state (recommended for teams)

Add a `backend` block to `providers.tf` to store state in Azure Blob Storage:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate<unique>"
    container_name       = "tfstate"
    key                  = "blobfunc.tfstate"
  }
}
```
