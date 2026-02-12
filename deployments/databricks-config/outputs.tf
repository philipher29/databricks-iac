# ---------------------------------------------------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "groups" {
  description = "Created Databricks groups"
  value       = module.databricks_config.groups
}

output "storage_credentials" {
  description = "Created storage credentials"
  value       = module.databricks_config.storage_credentials
}

output "external_locations" {
  description = "Created external locations"
  value       = module.databricks_config.external_locations
}

output "catalogs" {
  description = "Created catalogs"
  value       = module.databricks_config.catalogs
}

output "schemas" {
  description = "Created schemas"
  value       = module.databricks_config.schemas
}

output "volumes" {
  description = "Created volumes"
  value       = module.databricks_config.volumes
}

output "cluster_policies" {
  description = "Created cluster policies"
  value       = module.databricks_config.cluster_policies
}

output "clusters" {
  description = "Created clusters"
  value       = module.databricks_config.clusters
}

output "secret_scopes" {
  description = "Created secret scopes"
  value       = module.databricks_config.secret_scopes
}

output "crossplane_service_principal" {
  description = "Crossplane service principal details"
  value       = module.databricks_config.crossplane_service_principal
}

output "service_principals" {
  description = "Created service principals"
  value       = module.databricks_config.service_principals
}

output "permission_groups" {
  description = "Built-in stage-based permission groups"
  value       = module.databricks_config.permission_groups
}

output "default_catalog_schema" {
  description = "Effective existing default catalog/schema configuration"
  value       = module.databricks_config.default_catalog_schema
}
