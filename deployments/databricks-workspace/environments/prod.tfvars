# ---------------------------------------------------------------------------------------------------------------------
# PROD (Production) ENVIRONMENT CONFIGURATION
# Production - maximum security and reliability
# ---------------------------------------------------------------------------------------------------------------------

environment = "prod"

# Azure settings
location            = "westeurope"
resource_group_name = "rg-databricks-prod"

# Workspace
workspace_name                    = "dbw-platform-prod"
managed_resource_group_name       = "rg-databricks-prod-managed"
public_network_access_enabled     = false
infrastructure_encryption_enabled = true

# Private endpoints - required for production
private_endpoints = {
  enabled                        = true
  subnet_id                      = "/subscriptions/xxx/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod/subnets/snet-privateendpoints"
  private_dns_zone_ids           = ["/subscriptions/xxx/resourceGroups/rg-dns/providers/Microsoft.Network/privateDnsZones/privatelink.azuredatabricks.net"]
  browser_authentication_enabled = true
}

# VNet injection - required for production
custom_vnet_config = {
  virtual_network_id                       = "/subscriptions/xxx/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod"
  private_subnet_name                      = "snet-databricks-private"
  private_subnet_network_security_group_id = "/subscriptions/xxx/resourceGroups/rg-network-prod/providers/Microsoft.Network/networkSecurityGroups/nsg-databricks"
  public_subnet_name                       = "snet-databricks-public"
  public_subnet_network_security_group_id  = "/subscriptions/xxx/resourceGroups/rg-network-prod/providers/Microsoft.Network/networkSecurityGroups/nsg-databricks"
  no_public_ip                             = true
}

# Environment-specific tags
tags = {
  Environment  = "prod"
  CostCenter   = "production"
  BusinessUnit = "data-platform"
  Criticality  = "high"
}
