# ---------------------------------------------------------------------------------------------------------------------
# QAS (Quality Assurance) ENVIRONMENT - DATABRICKS CONFIGURATION
# Pre-production - mirrors production settings
# ---------------------------------------------------------------------------------------------------------------------

environment           = "qas"
resource_group_name   = "rg-databricks-qas"
workspace_name        = "dbw-platform-qas"
access_connector_name = "dbw-platform-qas-access-connector"

# Unity Catalog
unity_catalog_metastore_id = null # Set to your metastore ID

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIALS
# ---------------------------------------------------------------------------------------------------------------------

storage_credentials = {
  qas_storage = {
    comment = "QAS storage credential"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      },
      {
        principal  = "Data Scientists"
        privileges = ["READ_FILES"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATIONS
# ---------------------------------------------------------------------------------------------------------------------

external_locations = {
  qas_landing = {
    url             = "abfss://landing@stqasdatabricks.dfs.core.windows.net/"
    credential_name = "qas_storage"
    comment         = "QAS landing zone"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
    # EXTERNAL volume embedded in this location
    volume = {
      catalog_name = "qas_analytics"
      schema_name  = "bronze"
      name         = "qas_landing_files"
      subpath      = "/volumes/files"
      comment      = "Landing zone for file uploads"
      grants = [
        { principal = "Data Engineers", privileges = ["READ_VOLUME", "WRITE_VOLUME"] }
      ]
    }
  }
  qas_processed = {
    url             = "abfss://processed@stqasdatabricks.dfs.core.windows.net/"
    credential_name = "qas_storage"
    comment         = "QAS processed data"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES"]
      },
      {
        principal  = "Data Scientists"
        privileges = ["READ_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
  }
  qas_curated = {
    url             = "abfss://curated@stqasdatabricks.dfs.core.windows.net/"
    credential_name = "qas_storage"
    comment         = "QAS curated data"
    read_only       = false
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES"]
      },
      {
        principal  = "Data Analysts"
        privileges = ["READ_FILES"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOGS
# ---------------------------------------------------------------------------------------------------------------------

catalogs = {
  qas_analytics = {
    comment = "QAS analytics catalog"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["ALL_PRIVILEGES"]
      },
      {
        principal  = "Data Scientists"
        privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT", "MODIFY"]
      },
      {
        principal  = "Data Analysts"
        privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
      }
    ]
    schemas = {
      bronze = {
        comment = "Raw ingested data"
        grants = [
          { principal = "Data Engineers", privileges = ["ALL_PRIVILEGES"] }
        ]
      }
      silver = {
        comment = "Cleansed and transformed data"
        grants = [
          { principal = "Data Engineers", privileges = ["ALL_PRIVILEGES"] },
          { principal = "Data Scientists", privileges = ["USE_SCHEMA", "SELECT", "MODIFY"] }
        ]
      }
      gold = {
        comment = "Business-ready aggregated data"
        grants = [
          { principal = "Data Engineers", privileges = ["ALL_PRIVILEGES"] },
          { principal = "Data Analysts", privileges = ["USE_SCHEMA", "SELECT"] }
        ]
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VOLUMES (MANAGED only - EXTERNAL volumes are now in external_locations)
# ---------------------------------------------------------------------------------------------------------------------

# No managed volumes in QAS - EXTERNAL volumes moved to external_locations above
volumes = {}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES (Key Vault backed in QAS)
# ---------------------------------------------------------------------------------------------------------------------

# NOTE: Key Vault resource IDs are constructed dynamically using subscription_id variable
# The format is: /subscriptions/${subscription_id}/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<name>
# Update the keyvault_name variable instead of hardcoding subscription IDs

secret_scopes = {
  qas_secrets = {
    # Key Vault-backed secret scope - subscription ID injected via keyvault_resource_id variable
    keyvault_name = "kv-databricks-qas"
    keyvault_rg   = "rg-databricks-qas" # Optional, defaults to resource_group_name
    acls = [
      { principal = "Data Engineers", permission = "READ" },
      { principal = "Platform Admins", permission = "MANAGE" }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LISTS
# ---------------------------------------------------------------------------------------------------------------------

ip_access_lists = {
  corporate_network = {
    list_type    = "ALLOW"
    ip_addresses = ["10.0.0.0/8", "172.16.0.0/12"]
    enabled      = true
  }
}
