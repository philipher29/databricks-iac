# ---------------------------------------------------------------------------------------------------------------------
# DEV ENVIRONMENT CONFIGURATION
# Development environment - less restrictive, lower cost
# ---------------------------------------------------------------------------------------------------------------------

environment = "dev"

# Azure settings
location            = "westeurope"
resource_group_name = "rg-databricks-dev"

# Workspace
workspace_name                = "dbw-platform-dev"
managed_resource_group_name   = "rg-databricks-dev-managed"
public_network_access_enabled = true

# No private endpoints in dev (cost saving)
private_endpoints = null

# No VNet injection in dev (simpler setup)
custom_vnet_config = null

# Environment-specific tags
tags = {
  Environment = "dev"
  CostCenter  = "development"
}
