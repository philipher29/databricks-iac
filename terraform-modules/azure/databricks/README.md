# Azure Databricks Terraform Modules

Production-ready Terraform modules for deploying Azure Databricks with comprehensive testing, versioning, and CI/CD pipeline support.

## Architecture

This solution consists of three separate modules with independent lifecycles:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DEPLOYMENT FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐ │
│   │     DEV      │───▶│      IT      │───▶│     QAS      │───▶│   PROD   │ │
│   │  (auto)      │    │  (auto)      │    │  (approval)  │    │(approval)│ │
│   └──────────────┘    └──────────────┘    └──────────────┘    └──────────┘ │
│                                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Module 1: ACCOUNT                   Module 2: WORKSPACE                    │
│   ├── Unity Catalog Metastores        ├── Azure Databricks Workspace         │
│                                       ├── Access Connector                   │
│                                       └── Private Endpoints                  │
│                                                                              │
│   Module 3: CONFIGURATION             (Azure ARM Resources)                  │
│   ├── Groups & Permissions            ├── Unity Catalog                       │
│   ├── Catalogs & Schemas              ├── Volumes                             │
│   ├── Clusters                        ├── Cluster Policies                    │
│   └── Secret Scopes                   └── IP Access Lists                     │
│                                                                              │
│   (Databricks API Resources)                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Modules

### 1. Account Module (`account/`)

Creates account-level resources:

| Resource | Purpose |
|----------|---------|
| `databricks_metastore` | Unity Catalog metastore per region |

### 2. Workspace Module (`workspace/`)

Creates Azure infrastructure resources:

| Resource | Purpose |
|----------|---------|
| `azurerm_databricks_workspace` | Core Databricks workspace |
| `azurerm_databricks_access_connector` | Managed identity for Unity Catalog |
| `azurerm_private_endpoint` | Private Link connectivity |

### 3. Configuration Module (`configuration/`)

Creates Databricks-internal resources:

| Resource | Purpose |
|----------|---------|
| Groups & Members | Access control groups |
| Storage Credentials | Unity Catalog storage access |
| External Locations | External storage pointers |
| Catalogs & Schemas | Data organization |
| Volumes | File storage |
| Clusters | Compute resources |
| Cluster Policies | Compute governance |
| Secret Scopes | Credential management |
| IP Access Lists | Network restrictions |

## Versioning

Each module has a `version.json` file tracking:
- Semantic version (MAJOR.MINOR.PATCH)
- Changelog with dates
- Provider compatibility

```json
{
  "module": "databricks-workspace",
  "version": "1.0.0",
  "changelog": {
    "1.0.0": {
      "date": "2025-01-30",
      "changes": ["Initial release"]
    }
  }
}
```

### Version Management

```bash
# Bump module version
./scripts/bump-version.sh workspace minor "Added private endpoint support"

# Check deployment status
./scripts/get-deployment-status.sh
```

## Testing

### Unit Tests

Fast tests validating module structure and Terraform configuration:

```bash
cd terraform-modules/azure/databricks/account/tests
go test -v -run "^Test[^Integration]" ./...

cd terraform-modules/azure/databricks/workspace/tests
go test -v -run "^Test[^Integration]" ./...
```

### Integration Tests

Deploy real resources to validate functionality:

```bash
export INTEGRATION_TEST=true
export ARM_SUBSCRIPTION_ID=xxx
go test -v -run "TestIntegration" ./...
```

### Test Coverage

| Test Type | Module | Purpose |
|-----------|--------|---------|
| Structure | All | Validate required files exist |
| Validation | All | Test variable validators |
| Plan | Workspace/Config | Verify plan output |
| Integration | Workspace | Deploy/destroy real workspace |
| Integration | Config | Create real groups/policies |

## CI/CD Pipelines

### Pipeline Structure

```
pipelines/
├── ci/                          # PR validation
│   ├── workspace-ci.yml         # Workspace CI
│   └── config-ci.yml            # Config CI
├── stages/                      # Environment deployments
│   ├── workspace-dev.yml        # Auto-deploy to DEV
│   ├── workspace-it.yml         # Auto-deploy to IT
│   ├── workspace-qas.yml        # Manual + Approval
│   ├── workspace-prod.yml       # Manual + 2x Approval
│   ├── config-dev.yml
│   └── config-qas.yml
└── templates/                   # Reusable components
    ├── terraform-init.yml
    ├── terraform-plan.yml
    ├── terraform-apply.yml
    ├── run-tests.yml
    ├── security-scan.yml
    └── version-management.yml
```

### Approval Gates

| Environment | Approval Required | Approvers |
|-------------|-------------------|-----------|
| DEV | ❌ None | Auto |
| IT | ❌ None | Auto (after DEV) |
| QAS | ✅ Required | platform-admins |
| PROD | ✅ Required (2x) | platform-admins + security-team |

### Deployment Tracking

The `deployment-manifest.json` tracks:
- Version deployed to each environment
- Deployment timestamp
- Deploying user
- Git commit SHA
- Pipeline run ID

## tfvars Structure

Environment-specific configuration using layered tfvars:

```
deployments/databricks-workspace/environments/
├── common.tfvars      # Shared settings (loaded first)
├── dev.tfvars         # DEV overrides
├── it.tfvars          # IT overrides
├── qas.tfvars         # QAS overrides (stricter)
└── prod.tfvars        # PROD overrides (strictest)
```

### Best Practices

1. **common.tfvars**: Shared defaults, tags, policies
2. **Environment tfvars**: Only environment-specific values
3. **No secrets in tfvars**: Use Azure Key Vault + variable groups
4. **Progressive strictness**: dev → prod increases security

## Prerequisites

### Azure DevOps Setup

1. **Variable Groups**:
   - `terraform-backend`: backendResourceGroup, backendStorageAccount
   - `databricks-dev/it/qas/prod`: subscription-id, managed-identity-client-id

2. **Environments** (with approval policies):
   - `databricks-dev`, `databricks-it`
   - `databricks-qas` (platform-admins approval)
   - `databricks-prod` (platform-admins + security-team)

3. **Service Connections**:
   - Managed identity with Contributor on resource groups

### Managed Identity Permissions

| Permission | Scope | Purpose |
|------------|-------|---------|
| Contributor | Resource Group | Create workspace |
| Contributor | Databricks Workspace | Required for Databricks provider auth |
| Storage Blob Data Contributor | State Storage | Terraform state |
| Storage Blob Data Contributor | Unity Catalog Storage | Data access |

### Databricks Workspace Access (Required for MSI)

For the managed identity to authenticate to the Databricks workspace API, you must add it as a user in Databricks:

1. Navigate to your Databricks workspace in Azure Portal
2. Click **Launch Workspace** to open Databricks UI
3. Go to **Settings** → **Admin Settings** → **Users**
4. Click **Add User** and enter the managed identity's **Object ID** (not Client ID)
5. Grant **Admin** permissions for full access, or configure specific permissions

Alternatively, use Azure CLI to add the managed identity:

```bash
# Get the managed identity object ID
MI_OBJECT_ID=$(az identity show --name <managed-identity-name> --resource-group <rg> --query principalId -o tsv)

# Add to Databricks workspace (requires workspace URL)
curl -X POST "https://<workspace-url>/api/2.0/preview/scim/v2/Users" \
  -H "Authorization: Bearer $(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --query accessToken -o tsv)" \
  -H "Content-Type: application/json" \
  -d "{\"schemas\":[\"urn:ietf:params:scim:schemas:core:2.0:User\"],\"userName\":\"${MI_OBJECT_ID}\",\"displayName\":\"My Managed Identity\",\"active\":true,\"entitlements\":[{\"value\":\"allow-cluster-create\"}]}"
```

## Authentication Troubleshooting

### 401 Unauthorized Errors

If you receive `401 Unauthorized` when the Databricks provider tries to authenticate:

1. **Verify managed identity has Contributor role on the workspace:**
   ```bash
   az role assignment list --assignee <managed-identity-client-id> --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Databricks/workspaces/<workspace>
   ```

2. **Verify managed identity is added as a Databricks user:**
   - Open Databricks workspace → Admin Settings → Users
   - Check if the managed identity's Object ID is listed

3. **For local development, use Azure CLI auth instead:**
   ```bash
   az login
   terraform plan -var="use_msi=false"
   ```

4. **Check token acquisition:**
   ```bash
   # Test if MSI can get a Databricks token
   az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d
   ```

### 403 Forbidden Errors

1. **Check workspace network settings** - ensure your IP is allowed if IP access lists are enabled
2. **Verify private endpoint configuration** if using private connectivity
3. **Check NSG rules** on the Databricks subnets

### Authentication Methods

| Method | Use Case | Configuration |
|--------|----------|---------------|
| User-Assigned MSI | Azure DevOps pipelines (recommended) | `use_msi = true` + `managed_identity_client_id` |
| System-Assigned MSI | Azure VMs with system identity | `use_msi = true` (no client_id) |
| Azure CLI | Local development | `use_msi = false` + `az login` |
| Service Principal | CI/CD without MSI | `use_msi = false` + `client_id` + `client_secret` |

### User-Assigned Managed Identity Setup

1. **Create the User-Assigned Managed Identity:**
   ```bash
   az identity create \
     --name mi-databricks-deploy \
     --resource-group rg-shared \
     --location westeurope
   ```

2. **Get the identity's Client ID and Principal ID:**
   ```bash
   # Client ID (used for authentication)
   az identity show --name mi-databricks-deploy --resource-group rg-shared --query clientId -o tsv
   
   # Principal ID / Object ID (used for RBAC and Databricks user)
   az identity show --name mi-databricks-deploy --resource-group rg-shared --query principalId -o tsv
   ```

3. **Assign RBAC roles to the managed identity:**
   ```bash
   PRINCIPAL_ID=$(az identity show --name mi-databricks-deploy --resource-group rg-shared --query principalId -o tsv)
   
   # Contributor on the Databricks workspace
   az role assignment create \
     --assignee $PRINCIPAL_ID \
     --role "Contributor" \
     --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Databricks/workspaces/<workspace>
   
   # Storage Blob Data Contributor for Terraform state
   az role assignment create \
     --assignee $PRINCIPAL_ID \
     --role "Storage Blob Data Contributor" \
     --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>
   ```

4. **Add the identity to Databricks workspace as admin:**
   - Open Databricks workspace → Admin Settings → Users
   - Add the **Principal ID** (Object ID) as a user with Admin permissions

5. **Configure Terraform to use the identity:**
   ```hcl
   # terraform.tfvars or via -var flags
   use_msi                    = true
   managed_identity_client_id = "<client-id-from-step-2>"
   tenant_id                  = "<your-tenant-id>"
   subscription_id            = "<your-subscription-id>"
   ```

6. **Set environment variables (for Azure DevOps or local):**
   ```bash
   export ARM_USE_MSI=true
   export ARM_CLIENT_ID=<client-id>
   export ARM_TENANT_ID=<tenant-id>
   export ARM_SUBSCRIPTION_ID=<subscription-id>
   ```

## Usage

### Deploy Account (Metastores)

```hcl
module "databricks_account" {
  source = "./terraform-modules/azure/databricks/account"

  metastores = {
    westeurope = {
      storage_root = "abfss://metastore@storage.dfs.core.windows.net/"
      region       = "westeurope"
      owner        = "account-admins"
    }
    northeurope = {
      storage_root = "abfss://metastore@storage-ne.dfs.core.windows.net/"
      region       = "northeurope"
    }
  }
}
```

### Deploy Workspace

```hcl
module "databricks_workspace" {
  source = "./terraform-modules/azure/databricks/workspace"

  name                = "dbw-platform-prod"
  resource_group_name = "rg-databricks-prod"
  location            = "westeurope"
  sku                 = "premium"

  access_connector = {
    create = true
  }

  private_endpoints = {
    enabled   = true
    subnet_id = "/subscriptions/.../subnets/pe"
  }
}
```

### Deploy Configuration

```hcl
module "databricks_config" {
  source = "./terraform-modules/azure/databricks/configuration"

  workspace_id        = module.databricks_workspace.workspace_resource_id
  access_connector_id = module.databricks_workspace.access_connector_id
  unity_catalog_metastore_id = module.databricks_account.metastores["westeurope"].id

  groups = {
    data_engineers = {
      display_name         = "Data Engineers"
      allow_cluster_create = true
    }
  }

  clusters = {
    shared_etl = {
      spark_version = "14.3.x-scala2.12"
      node_type_id  = "Standard_DS3_v2"
      autoscale = {
        min_workers = 1
        max_workers = 4
      }
      data_security_mode = "USER_ISOLATION"
      grants = [
        {
          principal  = "data_engineers"
          permission = "CAN_ATTACH_TO"
        }
      ]
    }
  }

  catalogs = {
    analytics = {
      schemas = {
        bronze = {}
        silver = {}
        gold   = {}
      }
    }
  }
}
```

## Security

### Built-in Checks

- **tfsec**: Static security analysis
- **checkov**: Compliance scanning
- **Preconditions**: Runtime validation
- **Privilege validation**: Grant permission checks

### Security Features

- VNet injection support
- Private endpoints
- Customer-managed keys
- Infrastructure encryption
- IP access lists
- Azure Key Vault integration

## License

MIT License
