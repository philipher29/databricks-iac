# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# Supports multiple authentication methods: MSI, Azure CLI, Service Principal
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
# Supports MSI (pipeline/VM), Azure CLI (local), or Service Principal
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id

  # MSI authentication (for Azure DevOps pipelines and Azure VMs)
  use_msi   = var.use_msi
  client_id = var.use_msi ? var.managed_identity_client_id : null

  # Service Principal authentication (alternative)
  tenant_id     = var.use_msi ? null : var.tenant_id
  client_secret = var.use_msi ? null : var.client_secret

  # Skip provider registration for faster init (assume already registered)
  skip_provider_registration = true
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS PROVIDER
# Authenticates using Azure managed identity, CLI, or Service Principal
# 
# IMPORTANT: For MSI authentication to work:
# 1. The managed identity must have "Contributor" role on the Databricks workspace
# 2. The managed identity must be added to the Databricks workspace as an admin user
#    - Go to Databricks workspace > Admin Settings > Users
#    - Add the managed identity's object ID as a user with admin permissions
# ---------------------------------------------------------------------------------------------------------------------

provider "databricks" {
  host = "https://${data.azurerm_databricks_workspace.this.workspace_url}"

  # Azure authentication - supports MSI, CLI, and SP
  azure_workspace_resource_id = data.azurerm_databricks_workspace.this.id

  # MSI authentication (recommended for pipelines)
  azure_use_msi   = var.use_msi
  azure_client_id = var.use_msi ? var.managed_identity_client_id : null

  # Service Principal authentication (alternative to MSI)
  azure_tenant_id     = var.use_msi ? null : var.tenant_id
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
