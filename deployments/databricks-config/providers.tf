# ---------------------------------------------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# Uses existing managed identity for authentication
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.30.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AZURE PROVIDER (for data sources)
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  features {}

  use_msi         = true
  subscription_id = var.subscription_id
  client_id       = var.managed_identity_client_id
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS PROVIDER
# Authenticates using Azure managed identity
# ---------------------------------------------------------------------------------------------------------------------

provider "databricks" {
  host = "https://${data.azurerm_databricks_workspace.this.workspace_url}"

  # Use Azure managed identity authentication
  azure_use_msi       = true
  azure_client_id     = var.managed_identity_client_id
  azure_workspace_resource_id = data.azurerm_databricks_workspace.this.id
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
