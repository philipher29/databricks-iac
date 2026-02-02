# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - MANAGED VOLUMES
# Storage locations for non-tabular data managed by Unity Catalog
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_volume" "managed" {
  for_each = var.volumes

  name         = each.key
  catalog_name = each.value.catalog_name
  schema_name  = each.value.schema_name
  volume_type  = "MANAGED"
  comment      = each.value.comment
  owner        = each.value.owner

  depends_on = [
    databricks_schema.this
  ]
}

resource "databricks_grants" "managed_volumes" {
  for_each = {
    for item in local.volume_grants : "${item.volume_key}-${item.principal}" => item
  }

  volume = "${var.volumes[each.value.volume_key].catalog_name}.${var.volumes[each.value.volume_key].schema_name}.${databricks_volume.managed[each.value.volume_key].name}"

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - EXTERNAL VOLUMES (from external_locations)
# Storage locations for non-tabular data in external storage
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_volume" "external" {
  for_each = local.external_location_volumes

  name             = each.value.name
  catalog_name     = each.value.catalog_name
  schema_name      = each.value.schema_name
  volume_type      = "EXTERNAL"
  storage_location = each.value.storage_location
  comment          = each.value.comment
  owner            = each.value.owner

  depends_on = [
    databricks_schema.this,
    databricks_external_location.this
  ]
}

resource "databricks_grants" "external_volumes" {
  for_each = {
    for item in local.external_location_volume_grants : "${item.volume_key}-${item.principal}" => item
  }

  volume = "${local.external_location_volumes[each.value.volume_key].catalog_name}.${local.external_location_volumes[each.value.volume_key].schema_name}.${databricks_volume.external[each.value.volume_key].name}"

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }
}
