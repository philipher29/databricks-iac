# ---------------------------------------------------------------------------------------------------------------------
# DEFAULTS AND CONFIGURATION CONSTANTS
# Centralized configuration values - override via variables, not hardcoded strings
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURABLE DEFAULTS
# These can be overridden via input variables
# ---------------------------------------------------------------------------------------------------------------------

variable "defaults" {
  description = "Default values for optional configurations. Override specific values as needed."
  type = object({
    # Group defaults
    group_allow_cluster_create       = optional(bool, false)
    group_allow_instance_pool_create = optional(bool, false)
    group_databricks_sql_access      = optional(bool, false)
    group_workspace_access           = optional(bool, true)

    # Service principal defaults
    sp_allow_cluster_create       = optional(bool, false)
    sp_allow_instance_pool_create = optional(bool, false)
    sp_databricks_sql_access      = optional(bool, false)
    sp_workspace_access           = optional(bool, true)
    sp_active                     = optional(bool, true)

    # Catalog defaults
    catalog_isolation_mode = optional(string, "OPEN")

    # Volume defaults
    volume_type = optional(string, "MANAGED")

    # Secret scope defaults
    secret_scope_initial_manage_principal = optional(string, "users")

    # IP access list defaults
    ip_access_list_enabled = optional(bool, true)

    # External location defaults
    external_location_skip_validation = optional(bool, false)
    external_location_read_only       = optional(bool, false)
  })
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# PRIVILEGE DEFINITIONS
# Centralized valid privilege sets for validation
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Valid privilege sets for each resource type
  valid_privileges = {
    storage_credential = [
      "ALL_PRIVILEGES",
      "CREATE_EXTERNAL_LOCATION",
      "CREATE_EXTERNAL_TABLE",
      "READ_FILES",
      "WRITE_FILES"
    ]

    external_location = [
      "ALL_PRIVILEGES",
      "CREATE_EXTERNAL_TABLE",
      "CREATE_MANAGED_STORAGE",
      "READ_FILES",
      "WRITE_FILES"
    ]

    catalog = [
      "ALL_PRIVILEGES",
      "APPLY_TAG",
      "CREATE_CATALOG",
      "CREATE_SCHEMA",
      "USE_CATALOG"
    ]

    schema = [
      "ALL_PRIVILEGES",
      "APPLY_TAG",
      "CREATE_FUNCTION",
      "CREATE_MATERIALIZED_VIEW",
      "CREATE_MODEL",
      "CREATE_TABLE",
      "CREATE_VOLUME",
      "MODIFY",
      "SELECT",
      "USE_SCHEMA"
    ]

    volume = [
      "ALL_PRIVILEGES",
      "READ_VOLUME",
      "WRITE_VOLUME"
    ]

    cluster_policy = [
      "CAN_USE"
    ]

    secret_scope = [
      "READ",
      "WRITE",
      "MANAGE"
    ]
  }

  # Merged defaults with variable overrides
  defaults = merge({
    group_allow_cluster_create            = false
    group_allow_instance_pool_create      = false
    group_databricks_sql_access           = false
    group_workspace_access                = true
    sp_allow_cluster_create               = false
    sp_allow_instance_pool_create         = false
    sp_databricks_sql_access              = false
    sp_workspace_access                   = true
    sp_active                             = true
    catalog_isolation_mode                = "OPEN"
    volume_type                           = "MANAGED"
    secret_scope_initial_manage_principal = "users"
    ip_access_list_enabled                = true
    external_location_skip_validation     = false
    external_location_read_only           = false
  }, var.defaults)
}

# ---------------------------------------------------------------------------------------------------------------------
# RESOURCE NAMING PATTERNS
# Template-based naming for consistent resource naming across environments
# ---------------------------------------------------------------------------------------------------------------------

variable "naming" {
  description = "Naming patterns and prefixes for resources. Use {env} as placeholder for environment."
  type = object({
    environment = optional(string, "")
    prefix      = optional(string, "")
    suffix      = optional(string, "")
    separator   = optional(string, "_")
    patterns = optional(object({
      storage_credential = optional(string, "{env}_storage")
      external_location  = optional(string, "{env}_{zone}")
      catalog            = optional(string, "{env}_analytics")
      schema             = optional(string, "{name}")
      volume             = optional(string, "{env}_{name}")
      secret_scope       = optional(string, "{env}_secrets")
      cluster_policy     = optional(string, "{name}")
      group              = optional(string, "{name}")
    }), {})
  })
  default = {}
}

locals {
  # Naming patterns with defaults
  naming = {
    environment = coalesce(var.naming.environment, "")
    prefix      = coalesce(var.naming.prefix, "")
    suffix      = coalesce(var.naming.suffix, "")
    separator   = coalesce(var.naming.separator, "_")
    patterns = {
      storage_credential = coalesce(try(var.naming.patterns.storage_credential, null), "{env}_storage")
      external_location  = coalesce(try(var.naming.patterns.external_location, null), "{env}_{zone}")
      catalog            = coalesce(try(var.naming.patterns.catalog, null), "{env}_analytics")
      schema             = coalesce(try(var.naming.patterns.schema, null), "{name}")
      volume             = coalesce(try(var.naming.patterns.volume, null), "{env}_{name}")
      secret_scope       = coalesce(try(var.naming.patterns.secret_scope, null), "{env}_secrets")
      cluster_policy     = coalesce(try(var.naming.patterns.cluster_policy, null), "{name}")
      group              = coalesce(try(var.naming.patterns.group, null), "{name}")
    }
  }

  # Helper function to apply naming pattern
  env = local.naming.environment
}
