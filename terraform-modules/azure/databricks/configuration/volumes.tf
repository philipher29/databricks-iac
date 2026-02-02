# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - VOLUMES
# Storage locations for non-tabular data (files, models, artifacts)
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_volume" "this" {
  for_each = var.volumes

  name             = each.key
  catalog_name     = each.value.catalog_name
  schema_name      = each.value.schema_name
  volume_type      = each.value.volume_type
  storage_location = each.value.storage_location
  comment          = each.value.comment
  owner            = each.value.owner

  depends_on = [
    databricks_schema.this,
    databricks_external_location.this
  ]
}

resource "databricks_grants" "volumes" {
  for_each = {
    for item in local.volume_grants : "${item.volume_key}-${item.principal}" => item
  }

  volume = "${var.volumes[each.value.volume_key].catalog_name}.${var.volumes[each.value.volume_key].schema_name}.${databricks_volume.this[each.value.volume_key].name}"

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }
}
