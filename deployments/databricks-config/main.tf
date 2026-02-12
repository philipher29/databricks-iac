# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS CONFIGURATION DEPLOYMENT
# Deploys Databricks-internal configuration (groups, catalogs, volumes, etc.)
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# KEY VAULT DATA SOURCES
# Fetch service principal credentials from Key Vault
# ---------------------------------------------------------------------------------------------------------------------

data "azurerm_key_vault" "this" {
  count = var.keyvault_name != null ? 1 : 0

  name                = var.keyvault_name
  resource_group_name = coalesce(var.keyvault_resource_group_name, var.resource_group_name)
}

# Crossplane SP Application ID from Key Vault
data "azurerm_key_vault_secret" "crossplane_sp" {
  count = var.enable_crossplane_service_principal && var.keyvault_name != null ? 1 : 0

  name         = var.crossplane_sp_secret_name
  key_vault_id = data.azurerm_key_vault.this[0].id
}

# Generic service principal secrets from Key Vault
data "azurerm_key_vault_secret" "service_principals" {
  for_each = var.keyvault_name != null ? {
    for k, v in var.service_principals : k => v.keyvault_secret_name
    if try(v.keyvault_secret_name, null) != null
  } : {}

  name         = each.value
  key_vault_id = data.azurerm_key_vault.this[0].id
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES
# Consolidate configuration and apply defaults
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Crossplane SP configuration (only if enabled)
  crossplane_sp_config = var.enable_crossplane_service_principal ? {
    application_id             = var.keyvault_name != null ? data.azurerm_key_vault_secret.crossplane_sp[0].value : null
    display_name               = var.crossplane_sp_display_name
    allow_cluster_create       = null # Use module defaults
    allow_instance_pool_create = null
    databricks_sql_access      = null
    workspace_access           = null
    groups                     = var.crossplane_sp_groups
  } : null

  # Merge application IDs from Key Vault and direct configuration
  service_principals_resolved = {
    for k, v in var.service_principals : k => {
      application_id             = coalesce(try(v.application_id, null), try(data.azurerm_key_vault_secret.service_principals[k].value, null))
      display_name               = try(v.display_name, null)
      active                     = try(v.active, null)
      allow_cluster_create       = try(v.allow_cluster_create, null)
      allow_instance_pool_create = try(v.allow_instance_pool_create, null)
      databricks_sql_access      = try(v.databricks_sql_access, null)
      workspace_access           = try(v.workspace_access, null)
      groups                     = try(v.groups, [])
    }
  }
}

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

  # Defaults and naming configuration
  defaults               = var.defaults
  permission_model       = var.permission_model
  default_catalog_schema = var.default_catalog_schema
  naming = {
    environment = var.environment
  }

  # Azure context for dynamic resource ID construction
  subscription_id             = var.subscription_id
  default_resource_group_name = var.resource_group_name

  # EntraID group mapping
  entra_id_groups = var.entra_id_groups

  # Databricks Account Groups mapping (for workspace group membership)
  account_groups = var.account_groups

  # Groups
  groups = var.groups

  # Service Principals
  crossplane_service_principal = local.crossplane_sp_config
  service_principals           = local.service_principals_resolved

  # Storage credentials and external locations
  storage_credentials = var.storage_credentials
  external_locations  = var.external_locations

  # Catalogs, schemas, and volumes
  catalogs = var.catalogs
  volumes  = var.volumes

  # Governance
  cluster_policies = var.cluster_policies
  clusters         = var.clusters
  secret_scopes    = var.secret_scopes
  ip_access_lists  = var.ip_access_lists
}
