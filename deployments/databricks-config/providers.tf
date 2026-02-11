# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# Supports multiple authentication methods:
#   - User-Assigned Managed Identity (recommended for pipelines)
#   - System-Assigned Managed Identity
#   - Azure CLI (for local development)
#   - Service Principal (alternative)
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0" # Pinned for security and reproducibility
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.58.0" # Pinned for security and reproducibility
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AZURE PROVIDER (for data sources)
# Supports User-Assigned MSI, System-Assigned MSI, Azure CLI, or Service Principal
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id

  # User-Assigned Managed Identity authentication (recommended)
  # Requires: use_msi = true AND managed_identity_client_id set
  use_msi   = var.use_msi
  client_id = var.use_msi ? var.managed_identity_client_id : var.client_id

  # Service Principal authentication (when use_msi = false)
  tenant_id     = var.tenant_id
  client_secret = var.use_msi ? null : var.client_secret

  # Skip provider registration for faster init (assume already registered)
  skip_provider_registration = true
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS PROVIDER
# Authenticates using User-Assigned Managed Identity, Azure CLI, or Service Principal
# 
# IMPORTANT: For User-Assigned Managed Identity authentication to work:
# 1. The managed identity must have "Contributor" role on the Databricks workspace
# 2. The managed identity must be added to the Databricks workspace as an admin user
#    - Go to Databricks workspace > Admin Settings > Users
#    - Add the managed identity's Object ID (Principal ID) as a user with admin permissions
# 3. Set ARM_USE_MSI=true and ARM_CLIENT_ID=<user-assigned-identity-client-id> in environment
# ---------------------------------------------------------------------------------------------------------------------

provider "databricks" {
  host = "https://${data.azurerm_databricks_workspace.this.workspace_url}"

  # Azure authentication - supports User-Assigned MSI, System-Assigned MSI, CLI, and SP
  azure_workspace_resource_id = data.azurerm_databricks_workspace.this.id

  # User-Assigned Managed Identity authentication (recommended for pipelines)
  # When azure_use_msi=true and azure_client_id is set, uses User-Assigned Identity
  # When azure_use_msi=true and azure_client_id is null, uses System-Assigned Identity
  azure_use_msi   = var.use_msi
  azure_client_id = var.use_msi ? var.managed_identity_client_id : var.client_id

  # Tenant ID (required for all Azure auth methods)
  azure_tenant_id = var.tenant_id

  # Service Principal authentication (alternative to MSI)
  azure_client_secret = var.use_msi ? null : var.client_secret

  # Timeouts for better reliability
  http_timeout_seconds = 120
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCE: Existing Databricks Workspace
# ---------------------------------------------------------------------------------------------------------------------

data "azurerm_databricks_workspace" "this" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

data "azurerm_databricks_access_connector" "this" {
  count = var.access_connector_name != null ? 1 : 0

  name                = var.access_connector_name
  resource_group_name = var.resource_group_name
}
