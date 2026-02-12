# ---------------------------------------------------------------------------------------------------------------------
# PERMISSION MODEL + GROUP MEMBERSHIP
# ---------------------------------------------------------------------------------------------------------------------

locals {
  permission_model = merge({
    enabled               = true
    stage                 = null
    admin_group_prefix    = "DB-Admin"
    engineer_group_prefix = "DB-Engineers"
  }, var.permission_model)

  permission_stage = coalesce(local.permission_model.stage, try(var.naming.environment, null))

  default_groups = local.permission_model.enabled ? {
    db_admins = {
      display_name               = "${local.permission_model.admin_group_prefix}-${local.permission_stage}"
      allow_cluster_create       = true
      allow_instance_pool_create = true
      databricks_sql_access      = true
      workspace_access           = true
      members                    = []
      service_principals         = []
      child_groups               = []
      entra_id_groups            = []
      account_group_ids          = []
      account_groups             = []
    }
    db_engineers = {
      display_name               = "${local.permission_model.engineer_group_prefix}-${local.permission_stage}"
      allow_cluster_create       = true
      allow_instance_pool_create = false
      databricks_sql_access      = true
      workspace_access           = true
      members                    = []
      service_principals         = []
      child_groups               = []
      entra_id_groups            = []
      account_group_ids          = []
      account_groups             = []
    }
  } : {}

  effective_groups = merge(local.default_groups, var.groups)

  all_group_memberships = flatten([
    [for group_key, group in local.effective_groups : [
      for member in coalesce(group.members, []) : {
        key       = "${group_key}-user-${member}"
        group_key = group_key
        member_id = member
        type      = "user"
      }
    ]],
    [for group_key, group in local.effective_groups : [
      for sp in coalesce(group.service_principals, []) : {
        key       = "${group_key}-sp-${sp}"
        group_key = group_key
        member_id = sp
        type      = "service_principal"
      }
    ]],
    [for group_key, group in local.effective_groups : [
      for child in coalesce(group.child_groups, []) : {
        key       = "${group_key}-child-${child}"
        group_key = group_key
        member_id = child
        type      = "child_group"
      }
    ]],
    [for group_key, group in local.effective_groups : [
      for entra_name in coalesce(group.entra_id_groups, []) : {
        key       = "${group_key}-entra-${entra_name}"
        group_key = group_key
        member_id = var.entra_id_groups[entra_name]
        type      = "entra_id"
      }
    ]],
    [for group_key, group in local.effective_groups : [
      for account_group_id in coalesce(group.account_group_ids, []) : {
        key       = "${group_key}-account-${account_group_id}"
        group_key = group_key
        member_id = account_group_id
        type      = "account_group"
      }
    ]],
    [for group_key, group in local.effective_groups : [
      for account_group_name in coalesce(group.account_groups, []) : {
        key       = "${group_key}-account-${account_group_name}"
        group_key = group_key
        member_id = var.account_groups[account_group_name]
        type      = "account_group"
      }
      if try(group.account_groups, null) != null
    ]]
  ])

  group_memberships_map       = { for m in local.all_group_memberships : m.key => m }
  child_group_memberships     = { for k, v in local.group_memberships_map : k => v if v.type == "child_group" }
  direct_memberships          = { for k, v in local.group_memberships_map : k => v if v.type != "child_group" }
  admin_group_display_name    = local.permission_model.enabled ? local.default_groups.db_admins.display_name : null
  engineer_group_display_name = local.permission_model.enabled ? local.default_groups.db_engineers.display_name : null
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPAL MEMBERSHIPS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  crossplane_sp_groups = var.crossplane_service_principal != null ? coalesce(var.crossplane_service_principal.groups, []) : []

  all_sp_group_memberships = flatten([
    [for group_key in local.crossplane_sp_groups : {
      key       = "crossplane-${group_key}"
      sp_key    = "crossplane"
      group_key = group_key
      type      = "crossplane"
    }],
    [for sp_key, sp in var.service_principals : [
      for group_key in coalesce(sp.groups, []) : {
        key       = "${sp_key}-${group_key}"
        sp_key    = sp_key
        group_key = group_key
        type      = "generic"
      }
    ]]
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOG/SCHEMA AND EXTERNAL VOLUME FLATTENING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  default_catalog_schema = merge({
    enabled        = false
    catalog_name   = "hive_metastore"
    schema_name    = "default"
    catalog_grants = []
    schema_grants  = []
  }, var.default_catalog_schema)

  catalog_schemas = flatten([
    for catalog_key, catalog in var.catalogs : [
      for schema_key, schema in coalesce(catalog.schemas, {}) : {
        key          = "${catalog_key}.${schema_key}"
        catalog_key  = catalog_key
        schema_key   = schema_key
        catalog_name = catalog_key
        schema_name  = schema_key
        comment      = schema.comment
        owner        = schema.owner
        storage_root = schema.storage_root
        grants       = coalesce(schema.grants, [])
      }
    ]
  ])

  catalog_schemas_map = { for s in local.catalog_schemas : s.key => s }

  external_location_volumes = {
    for loc_key, loc in var.external_locations : loc_key => {
      location_key     = loc_key
      name             = coalesce(try(loc.volume.name, null), loc_key)
      catalog_name     = coalesce(try(loc.volume.catalog_name, null), local.default_catalog_schema.enabled ? local.default_catalog_schema.catalog_name : null)
      schema_name      = coalesce(try(loc.volume.schema_name, null), local.default_catalog_schema.enabled ? local.default_catalog_schema.schema_name : null)
      storage_location = try(loc.volume.subpath, null) != null ? "${trimsuffix(loc.url, "/")}${loc.volume.subpath}" : loc.url
      comment          = try(loc.volume.comment, null)
      owner            = coalesce(try(loc.volume.owner, null), loc.owner)
      grants           = coalesce(try(loc.volume.grants, null), [])
    }
    if try(loc.volume, null) != null
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GRANT/PERMISSION MAPS (PER RESOURCE) FOR DYNAMIC BLOCKS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  storage_credential_grants = {
    for key, credential in var.storage_credentials : key => coalesce(credential.grants, [])
    if length(coalesce(credential.grants, [])) > 0
  }

  external_location_grants = {
    for key, location in var.external_locations : key => coalesce(location.grants, [])
    if length(coalesce(location.grants, [])) > 0
  }

  catalog_grants = {
    for key, catalog in var.catalogs : key => coalesce(catalog.grants, [])
    if length(coalesce(catalog.grants, [])) > 0
  }

  schema_grants = {
    for schema in local.catalog_schemas : schema.key => schema.grants
    if length(schema.grants) > 0
  }

  managed_volume_grants = {
    for key, volume in var.volumes : key => coalesce(volume.grants, [])
    if length(coalesce(volume.grants, [])) > 0
  }

  external_volume_grants = {
    for key, volume in local.external_location_volumes : key => coalesce(volume.grants, [])
    if length(coalesce(volume.grants, [])) > 0
  }

  cluster_policy_permissions = {
    for key, policy in var.cluster_policies : key => coalesce(policy.grants, [])
    if length(coalesce(policy.grants, [])) > 0
  }

  cluster_permissions = {
    for key, cluster in var.clusters : key => coalesce(cluster.grants, [])
    if length(coalesce(cluster.grants, [])) > 0
  }

  secret_scope_acls = {
    for acl in flatten([
      for scope_key, scope in var.secret_scopes : [
        for permission in coalesce(scope.acls, []) : {
          key        = "${scope_key}-${permission.principal}"
          scope_key  = scope_key
          principal  = permission.principal
          permission = permission.permission
        }
      ]
    ]) : acl.key => acl
  }

  default_catalog_grants = local.default_catalog_schema.enabled && length(local.default_catalog_schema.catalog_grants) > 0 ? {
    default = local.default_catalog_schema.catalog_grants
  } : {}

  default_schema_grants = local.default_catalog_schema.enabled && length(local.default_catalog_schema.schema_grants) > 0 ? {
    default = local.default_catalog_schema.schema_grants
  } : {}
}
