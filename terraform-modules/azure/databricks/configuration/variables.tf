# ---------------------------------------------------------------------------------------------------------------------
# WORKSPACE REFERENCE (from workspace module outputs)
# ---------------------------------------------------------------------------------------------------------------------

variable "workspace_id" {
  description = "The Databricks workspace ID (from workspace module output)"
  type        = string
}

variable "access_connector_id" {
  description = "The ID of the Access Connector for storage credentials"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "unity_catalog_metastore_id" {
  description = "ID of the Unity Catalog metastore to attach to the workspace"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# ENTRA ID GROUP MAPPING
# Provides Azure AD group object IDs without requiring azuread provider permissions
# ---------------------------------------------------------------------------------------------------------------------

variable "entra_id_groups" {
  description = "Map of EntraID group display names to their Azure AD object IDs for adding as Databricks group members"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUPS AND PERMISSIONS
# ---------------------------------------------------------------------------------------------------------------------

variable "groups" {
  description = "Map of Databricks groups to create with their configurations"
  type = map(object({
    display_name               = string
    allow_cluster_create       = optional(bool, false)
    allow_instance_pool_create = optional(bool, false)
    databricks_sql_access      = optional(bool, false)
    workspace_access           = optional(bool, true)
    members                    = optional(list(string), []) # User IDs or emails
    service_principals         = optional(list(string), []) # Service principal application IDs
    child_groups               = optional(list(string), []) # Keys of groups defined in this variable
    entra_id_groups            = optional(list(string), []) # Keys from entra_id_groups variable
    account_group_ids          = optional(list(string), []) # Databricks Account Group member IDs (direct)
    account_groups             = optional(list(string), []) # Keys from account_groups variable (name lookup)
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS ACCOUNT GROUPS MAPPING
# Maps account group display names to their Databricks member IDs
# Use this to add account-level groups as members of workspace groups
# ---------------------------------------------------------------------------------------------------------------------

variable "account_groups" {
  description = "Map of Databricks Account Group display names to their member IDs. Use data source 'databricks_group' with account-level provider to fetch these IDs."
  type        = map(string)
  default     = {}

  # Example:
  # account_groups = {
  #   "Account Admins"     = "1234567890123456"
  #   "Data Platform Team" = "9876543210987654"
  # }
}

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIALS
# ---------------------------------------------------------------------------------------------------------------------

variable "storage_credentials" {
  description = "Map of Unity Catalog storage credentials to create"
  type = map(object({
    comment                   = optional(string)
    owner                     = optional(string)
    azure_managed_identity_id = optional(string) # Uses access connector if not specified
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATIONS
# ---------------------------------------------------------------------------------------------------------------------

variable "external_locations" {
  description = "Map of Unity Catalog external locations to create, with optional EXTERNAL volume creation"
  type = map(object({
    url             = string
    credential_name = optional(string)
    skip_validation = optional(bool, false)
    read_only       = optional(bool, false)
    comment         = optional(string)
    owner           = optional(string)
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
    # Optional: Create an EXTERNAL volume at this location
    volume = optional(object({
      catalog_name = string
      schema_name  = string
      name         = optional(string) # Defaults to external location key
      subpath      = optional(string) # Subpath under the location URL (e.g., "/volumes/files")
      comment      = optional(string)
      owner        = optional(string)
      grants = optional(list(object({
        principal  = string
        privileges = list(string)
      })), [])
    }))
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOGS AND SCHEMAS
# ---------------------------------------------------------------------------------------------------------------------

variable "catalogs" {
  description = "Map of Unity Catalog catalogs to create"
  type = map(object({
    comment        = optional(string)
    owner          = optional(string)
    storage_root   = optional(string)
    isolation_mode = optional(string, "OPEN")
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
    schemas = optional(map(object({
      comment      = optional(string)
      owner        = optional(string)
      storage_root = optional(string)
      grants = optional(list(object({
        principal  = string
        privileges = list(string)
      })), [])
    })), {})
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# VOLUMES (MANAGED only - use external_locations.volume for EXTERNAL volumes)
# ---------------------------------------------------------------------------------------------------------------------

variable "volumes" {
  description = "Map of Unity Catalog MANAGED volumes to create. For EXTERNAL volumes, use the 'volume' block in external_locations instead."
  type = map(object({
    catalog_name = string
    schema_name  = string
    comment      = optional(string)
    owner        = optional(string)
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER POLICIES
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_policies" {
  description = "Map of cluster policies to create"
  type = map(object({
    definition            = string # JSON policy definition
    description           = optional(string)
    max_clusters_per_user = optional(number)
    grants = optional(list(object({
      principal  = string
      permission = string # CAN_USE
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES
# Supports both Databricks-backed and Azure Key Vault-backed scopes
# For Key Vault-backed scopes, use keyvault_name/keyvault_rg (recommended) OR legacy keyvault_metadata
# ---------------------------------------------------------------------------------------------------------------------

variable "secret_scopes" {
  description = "Map of secret scopes to create. For Key Vault-backed scopes, use keyvault_name (resource ID constructed dynamically)."
  type = map(object({
    initial_manage_principal = optional(string, "users")
    # New recommended pattern: use keyvault_name and let the module construct resource_id
    keyvault_name = optional(string)
    keyvault_rg   = optional(string) # Defaults to workspace resource group if not specified
    # Legacy pattern: provide full keyvault_metadata (deprecated, use keyvault_name instead)
    keyvault_metadata = optional(object({
      resource_id = string
      dns_name    = string
    }))
    acls = optional(list(object({
      principal  = string
      permission = string # READ, WRITE, MANAGE
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secret_scopes : !(v.keyvault_name != null && v.keyvault_metadata != null)
    ])
    error_message = "Cannot specify both keyvault_name and keyvault_metadata. Use keyvault_name (recommended) or keyvault_metadata (legacy), not both."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID (required for dynamic Key Vault resource ID construction)"
  type        = string
  default     = null
  sensitive   = true
}

variable "default_resource_group_name" {
  description = "Default resource group name for Key Vault lookups when keyvault_rg is not specified"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LISTS
# ---------------------------------------------------------------------------------------------------------------------

variable "ip_access_lists" {
  description = "Map of IP access lists for workspace access control"
  type = map(object({
    list_type    = string # ALLOW or BLOCK
    ip_addresses = list(string)
    enabled      = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.ip_access_lists : contains(["ALLOW", "BLOCK"], v.list_type)
    ])
    error_message = "List type must be either ALLOW or BLOCK."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTERS
# ---------------------------------------------------------------------------------------------------------------------

variable "clusters" {
  description = "Map of Databricks clusters to create"
  type = map(object({
    spark_version           = string
    node_type_id            = string
    driver_node_type_id     = optional(string) # Defaults to node_type_id if not specified
    num_workers             = optional(number, 2)
    min_workers             = optional(number)             # For autoscaling
    max_workers             = optional(number)             # For autoscaling
    cluster_mode            = optional(string, "STANDARD") # SINGLE_NODE or STANDARD
    autotermination_minutes = optional(number, 60)
    enable_elastic_disk     = optional(bool, true)
    instance_pool_id        = optional(string)
    policy_id               = optional(string) # Reference to cluster policy key or ID
    cluster_log_conf = optional(object({
      dbfs = optional(object({
        destination = string
      }))
    }))
    aws_attributes = optional(object({
      availability     = optional(string, "SPOT")
      zone_id          = optional(string)
      ebs_volume_count = optional(number)
      ebs_volume_size  = optional(number)
    }))
    azure_attributes = optional(object({
      availability       = optional(string, "SPOT_WITH_FALLBACK")
      first_on_demand    = optional(number, 1)
      spot_bid_max_price = optional(number, -1)
    }))
    gcp_attributes = optional(object({
      availability    = optional(string, "PREEMPTIBLE")
      local_ssd_count = optional(number)
    }))
    ssh_public_keys = optional(list(string))
    custom_tags     = optional(map(string), {})
    spark_conf      = optional(map(string), {})
    env_vars        = optional(map(string), {})
    init_scripts = optional(list(object({
      dbfs = optional(object({
        destination = string
      }))
      s3 = optional(object({
        destination = string
        region      = optional(string)
        endpoint    = optional(string)
      }))
    })))
    workload_type = optional(object({
      clients = optional(object({
        notebooks = optional(bool)
        jobs      = optional(bool)
      }))
    }))
    grants = optional(list(object({
      principal  = string
      permission = string # ATTACH_TO, MANAGE, RESTART, CAN_USE
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPALS
# ---------------------------------------------------------------------------------------------------------------------

variable "crossplane_service_principal" {
  description = "Configuration for Crossplane service principal to manage Databricks resources"
  type = object({
    application_id             = string
    display_name               = optional(string, "Crossplane")
    allow_cluster_create       = optional(bool, true)
    allow_instance_pool_create = optional(bool, true)
    databricks_sql_access      = optional(bool, true)
    workspace_access           = optional(bool, true)
    groups                     = optional(list(string), []) # Group keys to add SP to
  })
  default = null
}

variable "service_principals" {
  description = "Map of additional service principals to register in Databricks workspace"
  type = map(object({
    application_id             = string
    display_name               = optional(string)
    active                     = optional(bool, true)
    allow_cluster_create       = optional(bool, false)
    allow_instance_pool_create = optional(bool, false)
    databricks_sql_access      = optional(bool, false)
    workspace_access           = optional(bool, true)
    groups                     = optional(list(string), [])
  }))
  default = {}
}
