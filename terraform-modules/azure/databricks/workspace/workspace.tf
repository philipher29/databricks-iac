# ---------------------------------------------------------------------------------------------------------------------
# AZURE DATABRICKS WORKSPACE
# The core workspace resource with VNet injection support
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_databricks_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  managed_resource_group_name           = var.managed_resource_group_name
  public_network_access_enabled         = var.public_network_access_enabled
  network_security_group_rules_required = var.network_security_group_rules_required
  customer_managed_key_enabled          = var.customer_managed_key_enabled
  infrastructure_encryption_enabled     = var.infrastructure_encryption_enabled

  # VNet injection configuration
  dynamic "custom_parameters" {
    for_each = var.custom_vnet_config != null ? [var.custom_vnet_config] : []
    content {
      virtual_network_id                                   = custom_parameters.value.virtual_network_id
      private_subnet_name                                  = custom_parameters.value.private_subnet_name
      private_subnet_network_security_group_association_id = custom_parameters.value.private_subnet_network_security_group_id
      public_subnet_name                                   = custom_parameters.value.public_subnet_name
      public_subnet_network_security_group_association_id  = custom_parameters.value.public_subnet_network_security_group_id
      storage_account_name                                 = custom_parameters.value.storage_account_name
      storage_account_sku_name                             = custom_parameters.value.storage_account_sku_name
      no_public_ip                                         = custom_parameters.value.no_public_ip
    }
  }

  tags = var.tags

  # Lifecycle rules for safe operations
  lifecycle {
    # Prevent accidental deletion of workspace
    prevent_destroy = false  # Set to true in production

    # These attributes cannot be changed without recreation
    ignore_changes = [
      # Ignore tag changes made outside Terraform
      # tags["CreatedDate"],
    ]

    # Validate configuration before apply
    precondition {
      condition     = var.sku == "premium" || !var.customer_managed_key_enabled
      error_message = "Customer-managed keys require Premium SKU."
    }

    precondition {
      condition     = var.sku == "premium" || !var.infrastructure_encryption_enabled
      error_message = "Infrastructure encryption requires Premium SKU."
    }

    precondition {
      condition     = var.custom_vnet_config == null || var.sku == "premium"
      error_message = "VNet injection requires Premium SKU."
    }

    postcondition {
      condition     = self.workspace_url != null && self.workspace_url != ""
      error_message = "Workspace URL should be set after creation."
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VALIDATIONS
# Additional validation checks for workspace configuration
# ---------------------------------------------------------------------------------------------------------------------

# Validate VNet injection configuration completeness
check "vnet_injection_complete" {
  assert {
    condition = var.custom_vnet_config == null || (
      var.custom_vnet_config.virtual_network_id != null &&
      var.custom_vnet_config.private_subnet_name != null &&
      var.custom_vnet_config.public_subnet_name != null
    )
    error_message = "VNet injection requires virtual_network_id, private_subnet_name, and public_subnet_name."
  }
}

# Validate private endpoint configuration
check "private_endpoints_require_vnet_or_premium" {
  assert {
    condition = var.private_endpoints == null || var.sku == "premium"
    error_message = "Private endpoints require Premium SKU."
  }
}
