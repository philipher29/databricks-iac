# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS RESOURCE IMPORTS

# Example:
#   import_groups = {
#     "db_admins" = "12345678901234"
#   }
#   import_catalogs = {
#     "my_catalog" = "my_catalog"
#   }
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # IDENTITY & ACCESS
  # ---------------------------------------------------------------------------

  # Key = group key (as in var.groups), Value = Databricks group ID
  import_groups = {}

  # Key = composite key (as used in local.direct_memberships), Value = "group_id/member_id"
  import_group_members_direct = {}

  # Key = composite key (as used in local.child_group_memberships), Value = "group_id/member_id"
  import_group_members_child = {}

  # Key = composite key (as used in local.all_sp_group_memberships), Value = "group_id/member_id"
  import_group_members_service_principals = {}

  # Key = SP key (as in var.service_principals), Value = Databricks SP application ID
  import_service_principals = {}

  # ---------------------------------------------------------------------------
  # UNITY CATALOG
  # ---------------------------------------------------------------------------

  # Metastore assignment import ID: "workspace_id|metastore_id" (empty string to skip)
  import_metastore_assignment = ""

  # Key = credential key (as in var.storage_credentials), Value = credential name
  import_storage_credentials = {}

  # Key = location key (as in var.external_locations), Value = location name
  import_external_locations = {}

  # ---------------------------------------------------------------------------
  # CATALOGS & SCHEMAS
  # ---------------------------------------------------------------------------

  # Key = catalog key (as in var.catalogs), Value = catalog name
  import_catalogs = {}

  # Key = composite key "catalog_key/schema_key" (as used in local.catalog_schemas_map), Value = "catalog_name.schema_name"
  import_schemas = {}

  # ---------------------------------------------------------------------------
  # VOLUMES
  # ---------------------------------------------------------------------------

  # Key = volume key (as in var.volumes), Value = "catalog_name.schema_name.volume_name"
  import_volumes_managed = {}

  # Key = volume key (as used in local.external_location_volumes), Value = "catalog_name.schema_name.volume_name"
  import_volumes_external = {}

  # ---------------------------------------------------------------------------
  # COMPUTE
  # ---------------------------------------------------------------------------

  # Key = policy key (as in var.cluster_policies), Value = Databricks cluster policy ID
  import_cluster_policies = {}

  # Key = cluster key (as in var.clusters), Value = Databricks cluster ID
  import_clusters = {}

  # ---------------------------------------------------------------------------
  # SECURITY
  # ---------------------------------------------------------------------------

  # Key = scope key (as in var.secret_scopes), Value = secret scope name
  import_secret_scopes = {}

  # Key = composite key (as used in local.secret_scope_acls), Value = "scope_name|||principal"
  import_secret_acls = {}

  # Key = access list key (as in var.ip_access_lists), Value = Databricks IP access list ID
  import_ip_access_lists = {}

  # ---------------------------------------------------------------------------
  # GRANTS (Unity Catalog)
  # Each grant resource has a distinct name in the configuration module
  # ---------------------------------------------------------------------------

  # Key = catalog key, Value = "catalog/catalog_name"
  import_grants_catalogs = {}

  # Key = composite key, Value = "schema/catalog_name.schema_name"
  import_grants_schemas = {}

  # Key = credential key, Value = "storage_credential/credential_name"
  import_grants_storage_credentials = {}

  # Key = location key, Value = "external_location/location_name"
  import_grants_external_locations = {}

  # Key = volume key, Value = "volume/catalog.schema.volume"
  import_grants_managed_volumes = {}

  # Key = volume key, Value = "volume/catalog.schema.volume"
  import_grants_external_volumes = {}

  # ---------------------------------------------------------------------------
  # PERMISSIONS (Workspace-level)
  # Each permission resource has a distinct name in the configuration module
  # ---------------------------------------------------------------------------

  # Key = policy key, Value = "/cluster-policies/policy_id"
  import_permissions_cluster_policies = {}

  # Key = cluster key, Value = "/clusters/cluster_id"
  import_permissions_clusters = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - IDENTITY & ACCESS
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_groups
  id       = each.value
  to       = module.databricks_config.databricks_group.this[each.key]
}

import {
  for_each = local.import_group_members_direct
  id       = each.value
  to       = module.databricks_config.databricks_group_member.direct[each.key]
}

import {
  for_each = local.import_group_members_child
  id       = each.value
  to       = module.databricks_config.databricks_group_member.child_groups[each.key]
}

import {
  for_each = local.import_group_members_service_principals
  id       = each.value
  to       = module.databricks_config.databricks_group_member.service_principals[each.key]
}

import {
  for_each = local.import_service_principals
  id       = each.value
  to       = module.databricks_config.databricks_service_principal.this[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - UNITY CATALOG
# Note: metastore_assignment uses count (not for_each), so it targets index [0]
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_metastore_assignment != "" ? { "this" = local.import_metastore_assignment } : {}
  id       = each.value
  to       = module.databricks_config.databricks_metastore_assignment.this[0]
}

import {
  for_each = local.import_storage_credentials
  id       = each.value
  to       = module.databricks_config.databricks_storage_credential.this[each.key]
}

import {
  for_each = local.import_external_locations
  id       = each.value
  to       = module.databricks_config.databricks_external_location.this[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - CATALOGS & SCHEMAS
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_catalogs
  id       = each.value
  to       = module.databricks_config.databricks_catalog.this[each.key]
}

import {
  for_each = local.import_schemas
  id       = each.value
  to       = module.databricks_config.databricks_schema.this[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - VOLUMES
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_volumes_managed
  id       = each.value
  to       = module.databricks_config.databricks_volume.managed[each.key]
}

import {
  for_each = local.import_volumes_external
  id       = each.value
  to       = module.databricks_config.databricks_volume.external[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - COMPUTE
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_cluster_policies
  id       = each.value
  to       = module.databricks_config.databricks_cluster_policy.this[each.key]
}

import {
  for_each = local.import_clusters
  id       = each.value
  to       = module.databricks_config.databricks_cluster.this[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - SECURITY
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_secret_scopes
  id       = each.value
  to       = module.databricks_config.databricks_secret_scope.this[each.key]
}

import {
  for_each = local.import_secret_acls
  id       = each.value
  to       = module.databricks_config.databricks_secret_acl.this[each.key]
}

import {
  for_each = local.import_ip_access_lists
  id       = each.value
  to       = module.databricks_config.databricks_ip_access_list.this[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - GRANTS (Unity Catalog)
# Each grant resource has a distinct name in the configuration module
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_grants_catalogs
  id       = each.value
  to       = module.databricks_config.databricks_grants.catalogs[each.key]
}

import {
  for_each = local.import_grants_schemas
  id       = each.value
  to       = module.databricks_config.databricks_grants.schemas[each.key]
}

import {
  for_each = local.import_grants_storage_credentials
  id       = each.value
  to       = module.databricks_config.databricks_grants.storage_credentials[each.key]
}

import {
  for_each = local.import_grants_external_locations
  id       = each.value
  to       = module.databricks_config.databricks_grants.external_locations[each.key]
}

import {
  for_each = local.import_grants_managed_volumes
  id       = each.value
  to       = module.databricks_config.databricks_grants.managed_volumes[each.key]
}

import {
  for_each = local.import_grants_external_volumes
  id       = each.value
  to       = module.databricks_config.databricks_grants.external_volumes[each.key]
}

# ---------------------------------------------------------------------------------------------------------------------
# IMPORT BLOCKS - PERMISSIONS (Workspace-level)
# Each permission resource has a distinct name in the configuration module
# ---------------------------------------------------------------------------------------------------------------------

import {
  for_each = local.import_permissions_cluster_policies
  id       = each.value
  to       = module.databricks_config.databricks_permissions.cluster_policies[each.key]
}

import {
  for_each = local.import_permissions_clusters
  id       = each.value
  to       = module.databricks_config.databricks_permissions.clusters[each.key]
}
