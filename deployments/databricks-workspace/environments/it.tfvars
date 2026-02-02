# ---------------------------------------------------------------------------------------------------------------------
# IT (Integration Test) ENVIRONMENT CONFIGURATION
# Integration testing - mirrors production architecture
# ---------------------------------------------------------------------------------------------------------------------

environment = "it"

# Azure settings
location            = "westeurope"
resource_group_name = "rg-databricks-it"

# Workspace
workspace_name                = "dbw-platform-it"
managed_resource_group_name   = "rg-databricks-it-managed"
public_network_access_enabled = true

# Private endpoints (optional for IT)
private_endpoints = null

# VNet injection (uncomment to enable)
# custom_vnet_config = {
#   virtual_network_id                       = "/subscriptions/xxx/resourceGroups/rg-network-it/providers/Microsoft.Network/virtualNetworks/vnet-it"
#   private_subnet_name                      = "snet-databricks-private"
#   private_subnet_network_security_group_id = "/subscriptions/xxx/resourceGroups/rg-network-it/providers/Microsoft.Network/networkSecurityGroups/nsg-databricks"
#   public_subnet_name                       = "snet-databricks-public"
#   public_subnet_network_security_group_id  = "/subscriptions/xxx/resourceGroups/rg-network-it/providers/Microsoft.Network/networkSecurityGroups/nsg-databricks"
#   no_public_ip                             = true
# }

# Environment-specific tags
tags = {
  Environment = "it"
  CostCenter  = "testing"
}
