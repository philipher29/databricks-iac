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
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AZURE PROVIDER
# Supports User-Assigned MSI, System-Assigned MSI, Azure CLI, or Service Principal
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

  # User-Assigned Managed Identity authentication (recommended)
  # Requires: use_msi = true AND managed_identity_client_id set
  use_msi   = var.use_msi
  client_id = var.use_msi ? var.managed_identity_client_id : var.client_id

  # Tenant ID (recommended for all auth methods)
  tenant_id = var.tenant_id

  # Service Principal authentication (when use_msi = false)
  client_secret = var.use_msi ? null : var.client_secret

  # Skip provider registration for faster init (assume already registered)
  skip_provider_registration = true
}
