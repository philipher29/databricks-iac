# ---------------------------------------------------------------------------------------------------------------------
# AUTHENTICATION VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID for deployment"
  type        = string
}

variable "managed_identity_client_id" {
  description = "Client ID of the managed identity used for authentication"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, it, qas, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "it", "qas", "prod"], var.environment)
    error_message = "Environment must be one of: dev, it, qas, prod."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group containing the workspace"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKSPACE REFERENCE
# ---------------------------------------------------------------------------------------------------------------------

variable "workspace_name" {
  description = "Name of the existing Databricks workspace"
  type        = string
}

variable "access_connector_name" {
  description = "Name of the existing Access Connector"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG
# ---------------------------------------------------------------------------------------------------------------------

variable "unity_catalog_metastore_id" {
  description = "ID of the Unity Catalog metastore to attach"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUPS
# ---------------------------------------------------------------------------------------------------------------------

variable "groups" {
  description = "Map of Databricks groups to create"
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
  description = "Map of storage credentials to create"
  type = map(object({
    comment                   = optional(string)
    owner                     = optional(string)
    azure_managed_identity_id = optional(string)
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
  description = "Map of external locations to create"
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
  description = "Map of catalogs to create"
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
  description = "Map of volumes to create"
  type = map(object({
    catalog_name     = string
    schema_name      = string
    volume_type      = string
    storage_location = optional(string)
    comment          = optional(string)
    owner            = optional(string)
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
    definition            = string
    description           = optional(string)
    max_clusters_per_user = optional(number)
    grants = optional(list(object({
      principal  = string
      permission = string
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
      permission = string
    })), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LISTS
# ---------------------------------------------------------------------------------------------------------------------

variable "ip_access_lists" {
  description = "Map of IP access lists"
  type = map(object({
    list_type    = string
    ip_addresses = list(string)
    enabled      = optional(bool, true)
  }))
  default = {}
}
