# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - CATALOGS
# Top-level containers for schemas (databases) in Unity Catalog
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_catalog" "this" {
  for_each = var.catalogs

  name           = each.key
  comment        = each.value.comment
  owner          = each.value.owner
  storage_root   = each.value.storage_root
  isolation_mode = coalesce(each.value.isolation_mode, local.defaults.catalog_isolation_mode)

  depends_on = [
    databricks_metastore_assignment.this,
    databricks_external_location.this
  ]
}

resource "databricks_grants" "catalogs" {
  for_each = local.catalog_grants

  catalog = databricks_catalog.this[each.value.resource_key].name

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for priv in each.value.privileges : contains(local.valid_privileges.catalog, priv)
      ])
      error_message = "Invalid privilege for catalog. Valid values: ${join(", ", local.valid_privileges.catalog)}"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG - SCHEMAS
# Second-level containers within catalogs (equivalent to databases)
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_schema" "this" {
  for_each = local.catalog_schemas_map

  name         = each.value.schema_name
  catalog_name = databricks_catalog.this[each.value.catalog_key].name
  comment      = each.value.comment
  owner        = each.value.owner
  storage_root = each.value.storage_root

  depends_on = [databricks_catalog.this]
}

resource "databricks_grants" "schemas" {
  for_each = local.schema_grants

  schema = "${databricks_catalog.this[each.value.catalog_key].name}.${databricks_schema.this[each.value.resource_key].name}"

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for priv in each.value.privileges : contains(local.valid_privileges.schema, priv)
      ])
      error_message = "Invalid privilege for schema. Valid values: ${join(", ", local.valid_privileges.schema)}"
    }
  }
}
