# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG METASTORE ASSIGNMENT
# Links the workspace to a Unity Catalog metastore
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_metastore_assignment" "this" {
  count = var.unity_catalog_metastore_id != null ? 1 : 0

  workspace_id = var.workspace_id
  metastore_id = var.unity_catalog_metastore_id

  lifecycle {
    precondition {
      condition     = var.unity_catalog_metastore_id != null
      error_message = "Metastore ID is required for Unity Catalog features."
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIALS
# Credentials for accessing external storage (uses Access Connector managed identity)
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_storage_credential" "this" {
  for_each = var.storage_credentials

  name    = each.key
  comment = each.value.comment
  owner   = each.value.owner

  azure_managed_identity {
    access_connector_id = coalesce(
      each.value.azure_managed_identity_id,
      var.access_connector_id
    )
  }

  depends_on = [databricks_metastore_assignment.this]

  lifecycle {
    precondition {
      condition     = var.access_connector_id != null || each.value.azure_managed_identity_id != null
      error_message = "Either access_connector_id or azure_managed_identity_id must be provided for storage credential '${each.key}'."
    }

    # Prevent credential deletion if external locations depend on it
    create_before_destroy = true
  }
}

resource "databricks_grants" "storage_credentials" {
  for_each = {
    for item in local.storage_credential_grants : "${item.credential_key}-${item.principal}" => item
  }

  storage_credential = databricks_storage_credential.this[each.value.credential_key].id

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }

  lifecycle {
    # Validate privilege values
    precondition {
      condition = alltrue([
        for priv in each.value.privileges : contains([
          "ALL_PRIVILEGES",
          "CREATE_EXTERNAL_LOCATION",
          "CREATE_EXTERNAL_TABLE",
          "READ_FILES",
          "WRITE_FILES"
        ], priv)
      ])
      error_message = "Invalid privilege for storage credential. Valid values: ALL_PRIVILEGES, CREATE_EXTERNAL_LOCATION, CREATE_EXTERNAL_TABLE, READ_FILES, WRITE_FILES."
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATIONS
# Pointers to external storage paths with access control
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_external_location" "this" {
  for_each = var.external_locations

  name            = each.key
  url             = each.value.url
  credential_name = each.value.credential_name != null ? each.value.credential_name : (
    length(var.storage_credentials) > 0 ? keys(var.storage_credentials)[0] : null
  )
  skip_validation = each.value.skip_validation
  read_only       = each.value.read_only
  comment         = each.value.comment
  owner           = each.value.owner

  depends_on = [
    databricks_metastore_assignment.this,
    databricks_storage_credential.this
  ]

  lifecycle {
    precondition {
      condition     = can(regex("^abfss://", each.value.url)) || can(regex("^wasbs://", each.value.url)) || can(regex("^s3://", each.value.url)) || can(regex("^gs://", each.value.url))
      error_message = "External location URL for '${each.key}' must start with abfss://, wasbs://, s3://, or gs://."
    }

    precondition {
      condition     = each.value.credential_name != null || length(var.storage_credentials) > 0
      error_message = "External location '${each.key}' requires a storage credential."
    }
  }
}

resource "databricks_grants" "external_locations" {
  for_each = {
    for item in local.external_location_grants : "${item.location_key}-${item.principal}" => item
  }

  external_location = databricks_external_location.this[each.value.location_key].id

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for priv in each.value.privileges : contains([
          "ALL_PRIVILEGES",
          "CREATE_EXTERNAL_TABLE",
          "CREATE_MANAGED_STORAGE",
          "READ_FILES",
          "WRITE_FILES"
        ], priv)
      ])
      error_message = "Invalid privilege for external location."
    }
  }
}
