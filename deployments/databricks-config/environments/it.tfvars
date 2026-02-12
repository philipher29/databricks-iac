# ---------------------------------------------------------------------------------------------------------------------
# IT (Integration Test) ENVIRONMENT - DATABRICKS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

environment           = "it"
resource_group_name   = "rg-databricks-it"
workspace_name        = "dbw-platform-it"
access_connector_name = "dbw-platform-it-access-connector"

# Unity Catalog
unity_catalog_metastore_id = null # Set to your metastore ID

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIALS
# ---------------------------------------------------------------------------------------------------------------------

storage_credentials = {
  it_storage = {
    comment = "Integration test storage credential"
    grants = [
      {
        principal  = "DB-Engineers-it"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATIONS
# ---------------------------------------------------------------------------------------------------------------------

external_locations = {
  it_landing = {
    url             = "abfss://landing@stitdatabricks.dfs.core.windows.net/"
    credential_name = "it_storage"
    comment         = "IT landing zone"
    grants = [
      {
        principal  = "DB-Engineers-it"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
  }
  it_processed = {
    url             = "abfss://processed@stitdatabricks.dfs.core.windows.net/"
    credential_name = "it_storage"
    comment         = "IT processed data"
    grants = [
      {
        principal  = "DB-Engineers-it"
        privileges = ["READ_FILES", "WRITE_FILES"]
      },
      {
        principal  = "DB-Engineers-it"
        privileges = ["READ_FILES"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOGS
# ---------------------------------------------------------------------------------------------------------------------

catalogs = {
  it_analytics = {
    comment = "Integration test analytics catalog"
    grants = [
      {
        principal  = "DB-Engineers-it"
        privileges = ["ALL_PRIVILEGES"]
      },
      {
        principal  = "DB-Engineers-it"
        privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
      }
    ]
    schemas = {
      bronze = { comment = "Raw ingested data" }
      silver = { comment = "Cleansed data" }
      gold   = { comment = "Business-ready data" }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTERS (optional Azure Databricks workspace compute)
# ---------------------------------------------------------------------------------------------------------------------

clusters = {}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES
# ---------------------------------------------------------------------------------------------------------------------

secret_scopes = {
  it_secrets = {
    initial_manage_principal = "users"
    acls = [
      { principal = "DB-Engineers-it", permission = "WRITE" },
      { principal = "DB-Engineers-it", permission = "READ" }
    ]
  }
}

# No IP restrictions in IT
ip_access_lists = {}
