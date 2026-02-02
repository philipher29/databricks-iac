# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - CATALOGS
# Top-level containers in the Unity Catalog three-level namespace
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_catalog" "this" {
  for_each = var.catalogs

  name           = each.key
  comment        = each.value.comment
  owner          = each.value.owner
  storage_root   = each.value.storage_root
  isolation_mode = each.value.isolation_mode

  depends_on = [
    databricks_metastore_assignment.this,
    databricks_external_location.this
  ]
}

resource "databricks_grants" "catalogs" {
  for_each = {
    for item in local.catalog_grants : "${item.catalog_key}-${item.principal}" => item
  }

  catalog = databricks_catalog.this[each.value.catalog_key].name

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - SCHEMAS
# Second-level namespace within catalogs (databases)
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_schema" "this" {
  for_each = {
    for schema in local.catalog_schemas : "${schema.catalog_key}.${schema.schema_key}" => schema
  }

  name         = each.value.schema_name
  catalog_name = databricks_catalog.this[each.value.catalog_key].name
  comment      = each.value.comment
  owner        = each.value.owner
  storage_root = each.value.storage_root
}

resource "databricks_grants" "schemas" {
  for_each = {
    for item in local.schema_grants : "${item.catalog_key}.${item.schema_key}-${item.principal}" => item
  }

  schema = "${databricks_catalog.this[each.value.catalog_key].name}.${databricks_schema.this["${each.value.catalog_key}.${each.value.schema_key}"].name}"

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }
}
