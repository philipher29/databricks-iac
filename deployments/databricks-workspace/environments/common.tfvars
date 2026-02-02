# ---------------------------------------------------------------------------------------------------------------------
# COMMON CONFIGURATION
# Shared settings across all environments - loaded first, then overlaid with environment-specific values
# ---------------------------------------------------------------------------------------------------------------------

# Workspace settings (can be overridden per environment)
workspace_sku = "premium"

# Access Connector (for Unity Catalog)
access_connector = {
  create        = true
  identity_type = "SystemAssigned"
}

# Common tags applied to all resources
tags = {
  Project   = "databricks-platform"
  ManagedBy = "terraform"
  Team      = "data-platform"
}
