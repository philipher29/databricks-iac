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
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# AZURE PROVIDER
# Authenticates using managed identity (set via ARM_USE_MSI=true or use_msi=true)
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  features {}

  # Use managed identity for authentication
  use_msi = true

  # Subscription is set via ARM_SUBSCRIPTION_ID environment variable or var
  subscription_id = var.subscription_id

  # Optional: specific managed identity client ID (if multiple identities exist)
  client_id = var.managed_identity_client_id
}
