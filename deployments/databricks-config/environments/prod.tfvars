# ---------------------------------------------------------------------------------------------------------------------
# PROD (Production) ENVIRONMENT - DATABRICKS CONFIGURATION
# Maximum governance and security
# ---------------------------------------------------------------------------------------------------------------------

environment           = "prod"
resource_group_name   = "rg-databricks-prod"
workspace_name        = "dbw-platform-prod"
access_connector_name = "dbw-platform-prod-access-connector"

# Unity Catalog
unity_catalog_metastore_id = null # Set to your production metastore ID

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIALS
# ---------------------------------------------------------------------------------------------------------------------

storage_credentials = {
  prod_storage = {
    comment = "Production storage credential"
    owner   = "Platform Admins"
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
  prod_landing = {
    url             = "abfss://landing@stproddatabricks.dfs.core.windows.net/"
    credential_name = "prod_storage"
    comment         = "Production landing zone - ingestion only"
    owner           = "Platform Admins"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
      }
    ]
  }
  prod_processed = {
    url             = "abfss://processed@stproddatabricks.dfs.core.windows.net/"
    credential_name = "prod_storage"
    comment         = "Production processed data"
    owner           = "Platform Admins"
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
  prod_curated = {
    url             = "abfss://curated@stproddatabricks.dfs.core.windows.net/"
    credential_name = "prod_storage"
    comment         = "Production curated data - business consumption"
    owner           = "Platform Admins"
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
  prod_archive = {
    url             = "abfss://archive@stproddatabricks.dfs.core.windows.net/"
    credential_name = "prod_storage"
    comment         = "Production archive - long-term storage"
    read_only       = true
    owner           = "Platform Admins"
    grants = [
      {
        principal  = "Data Engineers"
        privileges = ["READ_FILES"]
      }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOGS
# ---------------------------------------------------------------------------------------------------------------------

catalogs = {
  prod_analytics = {
    comment        = "Production analytics catalog"
    owner          = "Platform Admins"
    isolation_mode = "OPEN"
    grants = [
      {
        principal  = "Platform Admins"
        privileges = ["ALL_PRIVILEGES"]
      },
      {
        principal  = "Data Engineers"
        privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
      },
      {
        principal  = "Data Scientists"
        privileges = ["USE_CATALOG"]
      },
      {
        principal  = "Data Analysts"
        privileges = ["USE_CATALOG"]
      }
    ]
    schemas = {
      bronze = {
        comment = "Raw ingested data - immutable"
        owner   = "Data Engineers"
        grants = [
          { principal = "Data Engineers", privileges = ["ALL_PRIVILEGES"] }
        ]
      }
      silver = {
        comment = "Cleansed and transformed data"
        owner   = "Data Engineers"
        grants = [
          { principal = "Data Engineers", privileges = ["ALL_PRIVILEGES"] },
          { principal = "Data Scientists", privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"] }
        ]
      }
      gold = {
        comment = "Business-ready aggregated data"
        owner   = "Data Engineers"
        grants = [
          { principal = "Data Engineers", privileges = ["ALL_PRIVILEGES"] },
          { principal = "Data Scientists", privileges = ["USE_SCHEMA", "SELECT"] },
          { principal = "Data Analysts", privileges = ["USE_SCHEMA", "SELECT"] }
        ]
      }
      ml_features = {
        comment = "ML feature store"
        owner   = "Data Scientists"
        grants = [
          { principal = "Data Scientists", privileges = ["ALL_PRIVILEGES"] },
          { principal = "Data Engineers", privileges = ["USE_SCHEMA", "SELECT"] }
        ]
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VOLUMES
# ---------------------------------------------------------------------------------------------------------------------

volumes = {
  prod_landing_files = {
    catalog_name     = "prod_analytics"
    schema_name      = "bronze"
    volume_type      = "EXTERNAL"
    storage_location = "abfss://landing@stproddatabricks.dfs.core.windows.net/volumes/files"
    comment          = "Production file landing zone"
    owner            = "Data Engineers"
    grants = [
      { principal = "Data Engineers", privileges = ["READ_VOLUME", "WRITE_VOLUME"] }
    ]
  }
  prod_ml_models = {
    catalog_name = "prod_analytics"
    schema_name  = "ml_features"
    volume_type  = "MANAGED"
    comment      = "Production ML model artifacts"
    owner        = "Data Scientists"
    grants = [
      { principal = "Data Scientists", privileges = ["READ_VOLUME", "WRITE_VOLUME"] },
      { principal = "Data Engineers", privileges = ["READ_VOLUME"] }
    ]
  }
  prod_reports = {
    catalog_name     = "prod_analytics"
    schema_name      = "gold"
    volume_type      = "EXTERNAL"
    storage_location = "abfss://curated@stproddatabricks.dfs.core.windows.net/volumes/reports"
    comment          = "Production report exports"
    owner            = "Data Engineers"
    grants = [
      { principal = "Data Engineers", privileges = ["READ_VOLUME", "WRITE_VOLUME"] },
      { principal = "Data Analysts", privileges = ["READ_VOLUME"] }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES (Key Vault backed in production)
# ---------------------------------------------------------------------------------------------------------------------

secret_scopes = {
  prod_secrets = {
    keyvault_metadata = {
      resource_id = "/subscriptions/xxx/resourceGroups/rg-databricks-prod/providers/Microsoft.KeyVault/vaults/kv-databricks-prod"
      dns_name    = "https://kv-databricks-prod.vault.azure.net/"
    }
    acls = [
      { principal = "Data Engineers", permission = "READ" },
      { principal = "Data Scientists", permission = "READ" },
      { principal = "Platform Admins", permission = "MANAGE" }
    ]
  }
  prod_service_connections = {
    keyvault_metadata = {
      resource_id = "/subscriptions/xxx/resourceGroups/rg-databricks-prod/providers/Microsoft.KeyVault/vaults/kv-databricks-svc-prod"
      dns_name    = "https://kv-databricks-svc-prod.vault.azure.net/"
    }
    acls = [
      { principal = "Platform Admins", permission = "MANAGE" }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LISTS (strict in production)
# ---------------------------------------------------------------------------------------------------------------------

ip_access_lists = {
  corporate_network = {
    list_type    = "ALLOW"
    ip_addresses = ["10.0.0.0/8"]
    enabled      = true
  }
  vpn_gateway = {
    list_type    = "ALLOW"
    ip_addresses = ["203.0.113.0/24"] # Replace with actual VPN IPs
    enabled      = true
  }
}
