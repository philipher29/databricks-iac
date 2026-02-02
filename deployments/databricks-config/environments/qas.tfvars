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
# VOLUMES
# ---------------------------------------------------------------------------------------------------------------------

volumes = {
  qas_landing_files = {
    catalog_name     = "qas_analytics"
    schema_name      = "bronze"
    volume_type      = "EXTERNAL"
    storage_location = "abfss://landing@stqasdatabricks.dfs.core.windows.net/volumes/files"
    comment          = "Landing zone for file uploads"
    grants = [
      { principal = "Data Engineers", privileges = ["READ_VOLUME", "WRITE_VOLUME"] }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES (Key Vault backed in QAS)
# ---------------------------------------------------------------------------------------------------------------------

secret_scopes = {
  qas_secrets = {
    keyvault_metadata = {
      resource_id = "/subscriptions/xxx/resourceGroups/rg-databricks-qas/providers/Microsoft.KeyVault/vaults/kv-databricks-qas"
      dns_name    = "https://kv-databricks-qas.vault.azure.net/"
    }
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
