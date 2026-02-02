# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS CONFIGURATION DEPLOYMENT
# Deploys Databricks-internal configuration (groups, catalogs, volumes, etc.)
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS CONFIGURATION MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "databricks_config" {
  source = "../../terraform-modules/azure/databricks/configuration"

  # Workspace reference
  workspace_id        = data.azurerm_databricks_workspace.this.workspace_id
  access_connector_id = var.access_connector_name != null ? data.azurerm_databricks_access_connector.this[0].id : null

  # Unity Catalog
  unity_catalog_metastore_id = var.unity_catalog_metastore_id

  # Groups
  groups = var.groups

  # Storage credentials and external locations
  storage_credentials = var.storage_credentials
  external_locations  = var.external_locations

  # Catalogs, schemas, and volumes
  catalogs = var.catalogs
  volumes  = var.volumes

  # Governance
  cluster_policies = var.cluster_policies
  secret_scopes    = var.secret_scopes
  ip_access_lists  = var.ip_access_lists
}
