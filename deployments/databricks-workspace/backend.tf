# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM BACKEND CONFIGURATION
# State is stored in Azure Blob Storage with environment-specific containers
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  backend "azurerm" {
    # These values are provided via -backend-config in the pipeline:
    # - resource_group_name
    # - storage_account_name
    # - container_name
    # - key (state file name)
    # - use_msi = true
  }
}
