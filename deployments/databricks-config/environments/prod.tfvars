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
    # EXTERNAL volume embedded in this location
    volume = {
      catalog_name = "prod_analytics"
      schema_name  = "bronze"
      name         = "prod_landing_files"
      subpath      = "/volumes/files"
      comment      = "Production file landing zone"
      owner        = "Data Engineers"
      grants = [
        { principal = "Data Engineers", privileges = ["READ_VOLUME", "WRITE_VOLUME"] }
      ]
    }
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
    # EXTERNAL volume embedded in this location
    volume = {
      catalog_name = "prod_analytics"
      schema_name  = "gold"
      name         = "prod_reports"
      subpath      = "/volumes/reports"
      comment      = "Production report exports"
      owner        = "Data Engineers"
      grants = [
        { principal = "Data Engineers", privileges = ["READ_VOLUME", "WRITE_VOLUME"] },
        { principal = "Data Analysts", privileges = ["READ_VOLUME"] }
      ]
    }
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
# VOLUMES (MANAGED only - EXTERNAL volumes are now in external_locations)
# ---------------------------------------------------------------------------------------------------------------------

volumes = {
  # MANAGED volume - stored within Unity Catalog managed storage
  prod_ml_models = {
    catalog_name = "prod_analytics"
    schema_name  = "ml_features"
    comment      = "Production ML model artifacts"
    owner        = "Data Scientists"
    grants = [
      { principal = "Data Scientists", privileges = ["READ_VOLUME", "WRITE_VOLUME"] },
      { principal = "Data Engineers", privileges = ["READ_VOLUME"] }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES (Key Vault backed in production)
# NOTE: Key Vault resource IDs are constructed dynamically using subscription_id variable
# ---------------------------------------------------------------------------------------------------------------------

secret_scopes = {
  prod_secrets = {
    # Key Vault-backed secret scope - subscription ID injected via keyvault_resource_id variable
    keyvault_name = "kv-databricks-prod"
    keyvault_rg   = "rg-databricks-prod" # Optional, defaults to resource_group_name
    acls = [
      { principal = "Data Engineers", permission = "READ" },
      { principal = "Data Scientists", permission = "READ" },
      { principal = "Platform Admins", permission = "MANAGE" }
    ]
  }
  prod_service_connections = {
    # Separate Key Vault for service connection secrets
    keyvault_name = "kv-databricks-svc-prod"
    keyvault_rg   = "rg-databricks-prod" # Optional, defaults to resource_group_name
    acls = [
      { principal = "Platform Admins", permission = "MANAGE" }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LISTS (strict in production)
# IMPORTANT: Replace placeholder IP ranges with your actual corporate network and VPN IP addresses
# ---------------------------------------------------------------------------------------------------------------------

ip_access_lists = {
  corporate_network = {
    list_type    = "ALLOW"
    ip_addresses = ["10.0.0.0/8"] # RFC 1918 private network - update with your actual ranges
    enabled      = true
  }
  # TODO: Replace with your actual VPN gateway public IP addresses
  # vpn_gateway = {
  #   list_type    = "ALLOW"
  #   ip_addresses = ["YOUR.VPN.IP.RANGE/CIDR"]  # Example: ["198.51.100.0/24"]
  #   enabled      = true
  # }
}
