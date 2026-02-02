# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS WORKSPACE DEPLOYMENT
# Deploys the Azure Databricks workspace infrastructure
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Merge environment-specific tags with common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "databricks-workspace"
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS WORKSPACE MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "databricks_workspace" {
  source = "../../terraform-modules/azure/databricks/workspace"

  name                = var.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.workspace_sku

  managed_resource_group_name       = var.managed_resource_group_name
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  custom_vnet_config = var.custom_vnet_config
  private_endpoints  = var.private_endpoints
  access_connector   = var.access_connector

  tags = local.common_tags
}
