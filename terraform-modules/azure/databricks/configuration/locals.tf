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

  # Volume grants
  volume_grants = flatten([
    for vol_key, vol in var.volumes : [
      for grant in vol.grants : {
        volume_key = vol_key
        principal  = grant.principal
        privileges = grant.privileges
      }
    ]
  ])
}
