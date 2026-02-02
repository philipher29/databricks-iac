# ---------------------------------------------------------------------------------------------------------------------
# UNIFIED GROUP MEMBERSHIP FLATTENING
# Single consolidated local for all membership types
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Unified group memberships - all types in one structure
  all_group_memberships = flatten([
    # User members
    [for group_key, group in var.groups : [
      for member in coalesce(group.members, []) : {
        key       = "${group_key}-user-${member}"
        group_key = group_key
        member_id = member
        type      = "user"
      }
    ]],
    # Service principals (from groups variable)
    [for group_key, group in var.groups : [
      for sp in coalesce(group.service_principals, []) : {
        key       = "${group_key}-sp-${sp}"
        group_key = group_key
        member_id = sp
        type      = "service_principal"
      }
    ]],
    # Child groups
    [for group_key, group in var.groups : [
      for child in coalesce(group.child_groups, []) : {
        key       = "${group_key}-child-${child}"
        group_key = group_key
        member_id = child
        type      = "child_group"
      }
    ]],
    # EntraID groups
    [for group_key, group in var.groups : [
      for entra_name in coalesce(group.entra_id_groups, []) : {
        key       = "${group_key}-entra-${entra_name}"
        group_key = group_key
        member_id = var.entra_id_groups[entra_name]
        type      = "entra_id"
      }
    ]]
  ])

  # Convert to map for for_each
  group_memberships_map = { for m in local.all_group_memberships : m.key => m }

  # Child groups need special handling (reference created groups)
  child_group_memberships = { for k, v in local.group_memberships_map : k => v if v.type == "child_group" }
  direct_memberships      = { for k, v in local.group_memberships_map : k => v if v.type != "child_group" }
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPAL MEMBERSHIP FLATTENING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Crossplane SP group memberships
  crossplane_sp_groups = var.crossplane_service_principal != null ? coalesce(var.crossplane_service_principal.groups, []) : []

  # All service principal group memberships (from service_principals variable)
  all_sp_group_memberships = flatten([
    # Crossplane SP
    [for group_key in local.crossplane_sp_groups : {
      key       = "crossplane-${group_key}"
      sp_key    = "crossplane"
      group_key = group_key
      type      = "crossplane"
    }],
    # Generic service principals
    [for sp_key, sp in var.service_principals : [
      for group_key in coalesce(sp.groups, []) : {
        key       = "${sp_key}-${group_key}"
        sp_key    = sp_key
        group_key = group_key
        type      = "generic"
      }
    ]]
  ])

  sp_group_memberships_map = { for m in local.all_sp_group_memberships : m.key => m }
}

# ---------------------------------------------------------------------------------------------------------------------
# UNIFIED GRANTS FLATTENING
# Single pattern for all grant types
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Generic grant flattening function (applied to each resource type)
  all_grants = flatten([
    # Storage credential grants
    [for cred_key, cred in var.storage_credentials : [
      for grant in coalesce(cred.grants, []) : {
        key           = "storage_credential-${cred_key}-${grant.principal}"
        resource_type = "storage_credential"
        resource_key  = cred_key
        principal     = grant.principal
        privileges    = grant.privileges
      }
    ]],
    # External location grants
    [for loc_key, loc in var.external_locations : [
      for grant in coalesce(loc.grants, []) : {
        key           = "external_location-${loc_key}-${grant.principal}"
        resource_type = "external_location"
        resource_key  = loc_key
        principal     = grant.principal
        privileges    = grant.privileges
      }
    ]],
    # Catalog grants
    [for cat_key, cat in var.catalogs : [
      for grant in coalesce(cat.grants, []) : {
        key           = "catalog-${cat_key}-${grant.principal}"
        resource_type = "catalog"
        resource_key  = cat_key
        principal     = grant.principal
        privileges    = grant.privileges
      }
    ]],
    # Schema grants
    [for schema in local.catalog_schemas : [
      for grant in coalesce(schema.grants, []) : {
        key           = "schema-${schema.catalog_key}-${schema.schema_key}-${grant.principal}"
        resource_type = "schema"
        resource_key  = "${schema.catalog_key}.${schema.schema_key}"
        catalog_key   = schema.catalog_key
        schema_key    = schema.schema_key
        principal     = grant.principal
        privileges    = grant.privileges
      }
    ]],
    # Managed volume grants
    [for vol_key, vol in var.volumes : [
      for grant in coalesce(vol.grants, []) : {
        key           = "volume_managed-${vol_key}-${grant.principal}"
        resource_type = "volume_managed"
        resource_key  = vol_key
        catalog_name  = vol.catalog_name
        schema_name   = vol.schema_name
        principal     = grant.principal
        privileges    = grant.privileges
      }
    ]],
    # External volume grants (from external_locations)
    [for loc_key, vol in local.external_location_volumes : [
      for grant in coalesce(vol.grants, []) : {
        key           = "volume_external-${loc_key}-${grant.principal}"
        resource_type = "volume_external"
        resource_key  = loc_key
        catalog_name  = vol.catalog_name
        schema_name   = vol.schema_name
        principal     = grant.principal
        privileges    = grant.privileges
      }
    ]],
    # Cluster policy grants
    [for policy_key, policy in var.cluster_policies : [
      for grant in coalesce(policy.grants, []) : {
        key           = "cluster_policy-${policy_key}-${grant.principal}"
        resource_type = "cluster_policy"
        resource_key  = policy_key
        principal     = grant.principal
        permission    = grant.permission
      }
    ]],
    # Secret scope ACLs
    [for scope_key, scope in var.secret_scopes : [
      for acl in coalesce(scope.acls, []) : {
        key           = "secret_scope-${scope_key}-${acl.principal}"
        resource_type = "secret_scope"
        resource_key  = scope_key
        principal     = acl.principal
        permission    = acl.permission
      }
    ]]
  ])

  # Split grants by resource type for resource-specific handling
  grants_by_type = {
    for grant in local.all_grants : grant.resource_type => grant...
  }

  # Convert to maps for each resource type
  storage_credential_grants  = { for g in lookup(local.grants_by_type, "storage_credential", []) : g.key => g }
  external_location_grants   = { for g in lookup(local.grants_by_type, "external_location", []) : g.key => g }
  catalog_grants             = { for g in lookup(local.grants_by_type, "catalog", []) : g.key => g }
  schema_grants              = { for g in lookup(local.grants_by_type, "schema", []) : g.key => g }
  managed_volume_grants      = { for g in lookup(local.grants_by_type, "volume_managed", []) : g.key => g }
  external_volume_grants     = { for g in lookup(local.grants_by_type, "volume_external", []) : g.key => g }
  cluster_policy_permissions = { for g in lookup(local.grants_by_type, "cluster_policy", []) : g.key => g }
  secret_scope_acls          = { for g in lookup(local.grants_by_type, "secret_scope", []) : g.key => g }
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOG AND SCHEMA FLATTENING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Flatten catalog schemas for iteration
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
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATION VOLUMES
# EXTERNAL volumes embedded in external_locations
# ---------------------------------------------------------------------------------------------------------------------

locals {
  external_location_volumes = {
    for loc_key, loc in var.external_locations : loc_key => {
      location_key     = loc_key
      name             = coalesce(try(loc.volume.name, null), loc_key)
      catalog_name     = loc.volume.catalog_name
      schema_name      = loc.volume.schema_name
      storage_location = try(loc.volume.subpath, null) != null ? "${trimsuffix(loc.url, "/")}${loc.volume.subpath}" : loc.url
      comment          = try(loc.volume.comment, null)
      owner            = coalesce(try(loc.volume.owner, null), loc.owner)
      grants           = coalesce(try(loc.volume.grants, null), [])
    }
    if try(loc.volume, null) != null
  }
}
