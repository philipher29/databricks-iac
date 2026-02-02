# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# These values are used by the databricks-config deployment
# ---------------------------------------------------------------------------------------------------------------------

output "workspace_id" {
  description = "Azure resource ID of the Databricks workspace"
  value       = module.databricks_workspace.workspace_id
}

output "workspace_url" {
  description = "Databricks workspace URL"
  value       = module.databricks_workspace.workspace_url
}

output "workspace_resource_id" {
  description = "Databricks workspace ID (used for provider configuration)"
  value       = module.databricks_workspace.workspace_resource_id
}

output "access_connector_id" {
  description = "Access Connector ID for storage credentials"
  value       = module.databricks_workspace.access_connector_id
}

output "access_connector_principal_id" {
  description = "Access Connector principal ID for role assignments"
  value       = module.databricks_workspace.access_connector_principal_id
}

output "managed_resource_group_name" {
  description = "Managed resource group name"
  value       = module.databricks_workspace.managed_resource_group_name
}
