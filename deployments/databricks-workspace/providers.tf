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
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AZURE PROVIDER
# Supports MSI (pipeline/VM), Azure CLI (local), or Service Principal
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
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
