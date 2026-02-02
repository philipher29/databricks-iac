# ---------------------------------------------------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# Secure connectivity for Databricks workspace UI/API and browser authentication
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_private_endpoint" "databricks_ui_api" {
  count = var.private_endpoints != null && var.private_endpoints.enabled ? 1 : 0

  name                = "${var.name}-pe-ui-api"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints.subnet_id

  private_service_connection {
    name                           = "${var.name}-psc-ui-api"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_endpoints.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "databricks-dns-zone-group"
      private_dns_zone_ids = var.private_endpoints.private_dns_zone_ids
    }
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "databricks_browser_auth" {
  count = var.private_endpoints != null && var.private_endpoints.enabled && var.private_endpoints.browser_authentication_enabled ? 1 : 0

  name                = "${var.name}-pe-browser-auth"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints.subnet_id

  private_service_connection {
    name                           = "${var.name}-psc-browser-auth"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["browser_authentication"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_endpoints.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "databricks-browser-auth-dns-zone-group"
      private_dns_zone_ids = var.private_endpoints.private_dns_zone_ids
    }
  }

  tags = var.tags
}
