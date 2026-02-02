# ---------------------------------------------------------------------------------------------------------------------
# QAS (Quality Assurance) ENVIRONMENT CONFIGURATION
# Pre-production - should closely mirror production
# ---------------------------------------------------------------------------------------------------------------------

environment = "qas"

# Azure settings
location            = "westeurope"
resource_group_name = "rg-databricks-qas"

# Workspace
workspace_name                    = "dbw-platform-qas"
managed_resource_group_name       = "rg-databricks-qas-managed"
public_network_access_enabled     = false
infrastructure_encryption_enabled = true

# Private endpoints
private_endpoints = {
  enabled                        = true
  subnet_id                      = "/subscriptions/xxx/resourceGroups/rg-network-qas/providers/Microsoft.Network/virtualNetworks/vnet-qas/subnets/snet-privateendpoints"
  private_dns_zone_ids           = ["/subscriptions/xxx/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.azuredatabricks.net"]
  browser_authentication_enabled = true
}

# VNet injection
custom_vnet_config = {
  virtual_network_id                       = "/subscriptions/xxx/resourceGroups/rg-network-qas/providers/Microsoft.Network/virtualNetworks/vnet-qas"
  private_subnet_name                      = "snet-databricks-private"
  private_subnet_network_security_group_id = "/subscriptions/xxx/resourceGroups/rg-network-qas/providers/Microsoft.Network/networkSecurityGroups/nsg-databricks"
  public_subnet_name                       = "snet-databricks-public"
  public_subnet_network_security_group_id  = "/subscriptions/xxx/resourceGroups/rg-network-qas/providers/Microsoft.Network/networkSecurityGroups/nsg-databricks"
  no_public_ip                             = true
}

# Environment-specific tags
tags = {
  Environment = "qas"
  CostCenter  = "quality-assurance"
}
