# ---------------------------------------------------------------------------------------------------------------------
# DEV ENVIRONMENT - DATABRICKS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

environment           = "dev"
resource_group_name   = "rg-databricks-dev"
workspace_name        = "dbw-platform-dev"
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

# ---------------------------------------------------------------------------------------------------------------------
# KEY VAULT CONFIGURATION
# Uncomment to enable service principal retrieval from Key Vault
# ---------------------------------------------------------------------------------------------------------------------

# keyvault_name                = "kv-databricks-dev"
# keyvault_resource_group_name = "rg-shared-dev"  # Optional, defaults to resource_group_name

# ---------------------------------------------------------------------------------------------------------------------
# CROSSPLANE SERVICE PRINCIPAL
# Uncomment to enable Crossplane for managing Databricks resources
# ---------------------------------------------------------------------------------------------------------------------

# enable_crossplane_service_principal = true
# crossplane_sp_secret_name           = "crossplane-sp-client-id"
# crossplane_sp_display_name          = "Crossplane"
# crossplane_sp_groups                = ["platform_admins"]

# ---------------------------------------------------------------------------------------------------------------------
# ADDITIONAL SERVICE PRINCIPALS
# Add other automation service principals here
# ---------------------------------------------------------------------------------------------------------------------

# service_principals = {
#   ci_cd_pipeline = {
#     keyvault_secret_name       = "cicd-sp-client-id"
#     display_name               = "CI/CD Pipeline"
#     allow_cluster_create       = true
#     databricks_sql_access      = true
#     groups                     = ["platform_admins"]
#   }
# }
