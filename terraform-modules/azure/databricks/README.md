# Azure Databricks Terraform Modules

Production-ready Terraform modules for deploying Azure Databricks with comprehensive testing, versioning, and CI/CD pipeline support.

## Architecture

This solution consists of two separate modules with independent lifecycles:

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
│   Module 1: WORKSPACE                 Module 2: CONFIGURATION                │
│   ├── Azure Databricks Workspace      ├── Groups & Permissions              │
│   ├── Access Connector                ├── Unity Catalog                      │
│   └── Private Endpoints               ├── Catalogs & Schemas                 │
│                                        ├── Volumes                            │
│   (Azure ARM Resources)               ├── Cluster Policies                   │
│                                        └── Secret Scopes                      │
│                                                                              │
│                                        (Databricks API Resources)            │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Modules

### 1. Workspace Module (`workspace/`)

Creates Azure infrastructure resources:

| Resource | Purpose |
|----------|---------|
| `azurerm_databricks_workspace` | Core Databricks workspace |
| `azurerm_databricks_access_connector` | Managed identity for Unity Catalog |
| `azurerm_private_endpoint` | Private Link connectivity |

### 2. Configuration Module (`configuration/`)

Creates Databricks-internal resources:

| Resource | Purpose |
|----------|---------|
| Groups & Members | Access control groups |
| Storage Credentials | Unity Catalog storage access |
| External Locations | External storage pointers |
| Catalogs & Schemas | Data organization |
| Volumes | File storage |
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
| Structure | Both | Validate required files exist |
| Validation | Both | Test variable validators |
| Plan | Both | Verify plan output |
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
| Storage Blob Data Contributor | State Storage | Terraform state |
| Storage Blob Data Contributor | Unity Catalog Storage | Data access |

## Usage

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

  groups = {
    data_engineers = {
      display_name         = "Data Engineers"
      allow_cluster_create = true
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
