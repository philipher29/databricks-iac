# ---------------------------------------------------------------------------------------------------------------------
# DEV ENVIRONMENT - DATABRICKS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

environment         = "dev"
resource_group_name = "rg-databricks-dev"
workspace_name      = "dbw-platform-dev"
access_connector_name = "dbw-platform-dev-access-connector"

# Unity Catalog (optional in dev)
unity_catalog_metastore_id = null

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIALS
# ---------------------------------------------------------------------------------------------------------------------

storage_credentials = {
  dev_storage = {
    comment = "Development storage credential"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATIONS
# ---------------------------------------------------------------------------------------------------------------------

external_locations = {
  dev_landing = {
    url             = "abfss://landing@stdevdatabricks.dfs.core.windows.net/"
    credential_name = "dev_storage"
    comment         = "Development landing zone"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOGS (simplified for dev)
# ---------------------------------------------------------------------------------------------------------------------

catalogs = {
  dev_analytics = {
    comment = "Development analytics catalog"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["ALL_PRIVILEGES"]
      },
      {
        principal  = "Data Analysts"
        privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
      }
    ]
    schemas = {
      raw = {
        comment = "Raw data"
      }
      curated = {
        comment = "Curated data"
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES
# ---------------------------------------------------------------------------------------------------------------------

secret_scopes = {
  dev_secrets = {
    initial_manage_principal = "users"
    acls = [
      { principal = "Data Engineers", permission = "WRITE" }
    ]
  }
}

# No IP restrictions in dev
ip_access_lists = {}
