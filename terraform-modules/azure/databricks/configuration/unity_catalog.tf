# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG METASTORE ASSIGNMENT
# Links the workspace to a Unity Catalog metastore
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_metastore_assignment" "this" {
  count = var.unity_catalog_metastore_id != null ? 1 : 0

  workspace_id = var.workspace_id
  metastore_id = var.unity_catalog_metastore_id
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
    create_before_destroy = true
  }
}

resource "databricks_grants" "storage_credentials" {
  for_each = local.storage_credential_grants

  storage_credential = databricks_storage_credential.this[each.value.resource_key].id

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for priv in each.value.privileges : contains(local.valid_privileges.storage_credential, priv)
      ])
      error_message = "Invalid privilege for storage credential. Valid values: ${join(", ", local.valid_privileges.storage_credential)}"
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
  skip_validation = coalesce(each.value.skip_validation, local.defaults.external_location_skip_validation)
  read_only       = coalesce(each.value.read_only, local.defaults.external_location_read_only)
  comment         = each.value.comment
  owner           = each.value.owner

  depends_on = [
    databricks_metastore_assignment.this,
    databricks_storage_credential.this
  ]

  lifecycle {
    precondition {
      condition     = can(regex("^(abfss|wasbs|s3|gs)://", each.value.url))
      error_message = "External location URL for '${each.key}' must start with abfss://, wasbs://, s3://, or gs://."
    }

    precondition {
      condition     = each.value.credential_name != null || length(var.storage_credentials) > 0
      error_message = "External location '${each.key}' requires a storage credential."
    }
  }
}

resource "databricks_grants" "external_locations" {
  for_each = local.external_location_grants

  external_location = databricks_external_location.this[each.value.resource_key].id

  grant {
    principal  = each.value.principal
    privileges = each.value.privileges
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for priv in each.value.privileges : contains(local.valid_privileges.external_location, priv)
      ])
      error_message = "Invalid privilege for external location. Valid values: ${join(", ", local.valid_privileges.external_location)}"
    }
  }
}
