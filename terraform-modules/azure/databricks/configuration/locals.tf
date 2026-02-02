# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP FLATTENING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  group_members = flatten([
    for group_key, group in var.groups : [
      for member in group.members : {
        group_key = group_key
        member    = member
      }
    ]
  ])

  group_service_principals = flatten([
    for group_key, group in var.groups : [
      for sp in group.service_principals : {
        group_key         = group_key
        service_principal = sp
      }
    ]
  ])

  group_child_groups = flatten([
    for group_key, group in var.groups : [
      for child in group.child_groups : {
        group_key   = group_key
        child_group = child
      }
    ]
  ])

  # EntraID group memberships - maps group display names to Azure AD object IDs
  group_entra_id_groups = flatten([
    for group_key, group in var.groups : [
      for entra_group_name in coalesce(group.entra_id_groups, []) : {
        group_key        = group_key
        entra_group_name = entra_group_name
        entra_group_id   = var.entra_id_groups[entra_group_name]
      }
    ]
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPAL MEMBERSHIP FLATTENING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Crossplane SP group memberships
  crossplane_sp_groups = var.crossplane_service_principal != null ? coalesce(var.crossplane_service_principal.groups, []) : []

  # Generic service principal group memberships
  service_principal_group_memberships = flatten([
    for sp_key, sp in var.service_principals : [
      for group_key in coalesce(sp.groups, []) : {
        sp_key    = sp_key
        group_key = group_key
      }
    ]
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG FLATTENING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Flatten catalog schemas for iteration
  catalog_schemas = flatten([
    for catalog_key, catalog in var.catalogs : [
      for schema_key, schema in catalog.schemas : {
        catalog_key  = catalog_key
        schema_key   = schema_key
        catalog_name = catalog_key
        schema_name  = schema_key
        comment      = schema.comment
        owner        = schema.owner
        storage_root = schema.storage_root
        grants       = schema.grants
      }
    ]
  ])

  # Storage credential grants
  storage_credential_grants = flatten([
    for cred_key, cred in var.storage_credentials : [
      for grant in cred.grants : {
        credential_key = cred_key
        principal      = grant.principal
        privileges     = grant.privileges
      }
    ]
  ])

  # External location grants
  external_location_grants = flatten([
    for loc_key, loc in var.external_locations : [
      for grant in loc.grants : {
        location_key = loc_key
        principal    = grant.principal
        privileges   = grant.privileges
      }
    ]
  ])

  # Catalog grants
  catalog_grants = flatten([
    for cat_key, cat in var.catalogs : [
      for grant in cat.grants : {
        catalog_key = cat_key
        principal   = grant.principal
        privileges  = grant.privileges
      }
    ]
  ])

  # Schema grants
  schema_grants = flatten([
    for schema in local.catalog_schemas : [
      for grant in schema.grants : {
        catalog_key = schema.catalog_key
        schema_key  = schema.schema_key
        principal   = grant.principal
        privileges  = grant.privileges
      }
    ]
  ])

  # Volume grants (MANAGED volumes)
  volume_grants = flatten([
    for vol_key, vol in var.volumes : [
      for grant in vol.grants : {
        volume_key = vol_key
        principal  = grant.principal
        privileges = grant.privileges
      }
    ]
  ])

  # External location volumes - EXTERNAL volumes embedded in external_locations
  external_location_volumes = {
    for loc_key, loc in var.external_locations : loc_key => {
      location_key     = loc_key
      name             = coalesce(loc.volume.name, loc_key)
      catalog_name     = loc.volume.catalog_name
      schema_name      = loc.volume.schema_name
      storage_location = loc.volume.subpath != null ? "${trimsuffix(loc.url, "/")}${loc.volume.subpath}" : loc.url
      comment          = loc.volume.comment
      owner            = coalesce(loc.volume.owner, loc.owner)
      grants           = coalesce(loc.volume.grants, [])
    }
    if loc.volume != null
  }

  # External location volume grants
  external_location_volume_grants = flatten([
    for loc_key, vol in local.external_location_volumes : [
      for grant in vol.grants : {
        volume_key = loc_key
        principal  = grant.principal
        privileges = grant.privileges
      }
    ]
  ])
}
