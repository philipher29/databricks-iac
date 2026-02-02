# ---------------------------------------------------------------------------------------------------------------------
# WORKSPACE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "workspace_id" {
  description = "The Azure resource ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_url" {
  description = "The workspace URL (without https://)"
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "workspace_resource_id" {
  description = "The unique identifier of the Databricks workspace in Databricks"
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "managed_resource_group_id" {
  description = "The ID of the managed resource group"
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "managed_resource_group_name" {
  description = "The name of the managed resource group"
  value       = azurerm_databricks_workspace.this.managed_resource_group_name
}

output "storage_account_identity" {
  description = "The identity of the managed storage account"
  value       = azurerm_databricks_workspace.this.storage_account_identity
}

# ---------------------------------------------------------------------------------------------------------------------
# ACCESS CONNECTOR OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "access_connector_id" {
  description = "The ID of the Databricks Access Connector"
  value       = var.access_connector.create ? azurerm_databricks_access_connector.this[0].id : null
}

output "access_connector_identity" {
  description = "The identity of the Access Connector"
  value       = var.access_connector.create ? azurerm_databricks_access_connector.this[0].identity : null
}

output "access_connector_principal_id" {
  description = "The principal ID of the Access Connector's managed identity"
  value       = var.access_connector.create ? azurerm_databricks_access_connector.this[0].identity[0].principal_id : null
}

# ---------------------------------------------------------------------------------------------------------------------
# PRIVATE ENDPOINT OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "private_endpoint_ui_api_id" {
  description = "The ID of the UI/API private endpoint"
  value       = var.private_endpoints != null && var.private_endpoints.enabled ? azurerm_private_endpoint.databricks_ui_api[0].id : null
}

output "private_endpoint_browser_auth_id" {
  description = "The ID of the browser authentication private endpoint"
  value       = var.private_endpoints != null && var.private_endpoints.enabled && var.private_endpoints.browser_authentication_enabled ? azurerm_private_endpoint.databricks_browser_auth[0].id : null
}
