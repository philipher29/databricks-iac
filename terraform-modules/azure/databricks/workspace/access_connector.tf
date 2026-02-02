# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS ACCESS CONNECTOR
# Managed identity for Unity Catalog to access Azure storage
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_databricks_access_connector" "this" {
  count = var.access_connector.create ? 1 : 0

  name                = local.access_connector_name
  resource_group_name = var.resource_group_name
  location            = var.location

  identity {
    type         = var.access_connector.identity_type
    identity_ids = var.access_connector.identity_type == "UserAssigned" ? var.access_connector.user_assigned_identity_ids : null
  }

  tags = var.tags
}
