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
    members                    = optional(list(string), [])
    service_principals         = optional(list(string), [])
    child_groups               = optional(list(string), [])
  }))
  default = {}
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
  description = "Map of Unity Catalog external locations to create"
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
# VOLUMES
# ---------------------------------------------------------------------------------------------------------------------

variable "volumes" {
  description = "Map of Unity Catalog volumes to create"
  type = map(object({
    catalog_name     = string
    schema_name      = string
    volume_type      = string # MANAGED or EXTERNAL
    storage_location = optional(string) # Required for EXTERNAL volumes
    comment          = optional(string)
    owner            = optional(string)
    grants = optional(list(object({
      principal  = string
      privileges = list(string)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.volumes : contains(["MANAGED", "EXTERNAL"], v.volume_type)
    ])
    error_message = "Volume type must be either MANAGED or EXTERNAL."
  }
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
# ---------------------------------------------------------------------------------------------------------------------

variable "secret_scopes" {
  description = "Map of secret scopes to create"
  type = map(object({
    initial_manage_principal = optional(string, "users")
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
