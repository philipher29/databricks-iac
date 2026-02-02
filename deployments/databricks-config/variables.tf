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
# KEY VAULT CONFIGURATION
# For fetching service principal credentials
# ---------------------------------------------------------------------------------------------------------------------

variable "keyvault_name" {
  description = "Name of the Azure Key Vault containing service principal secrets"
  type        = string
  default     = null
}

variable "keyvault_resource_group_name" {
  description = "Resource group name for the Key Vault (defaults to workspace resource group)"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------------------------------------------------
# ENTRA ID GROUPS
# Maps Azure AD group display names to object IDs (avoids azuread provider)
# ---------------------------------------------------------------------------------------------------------------------

variable "entra_id_groups" {
  description = "Map of EntraID group display names to their Azure AD object IDs"
  type        = map(string)
  default     = {}
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
    entra_id_groups            = optional(list(string), [])
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

# ---------------------------------------------------------------------------------------------------------------------
# CROSSPLANE SERVICE PRINCIPAL
# ---------------------------------------------------------------------------------------------------------------------

variable "enable_crossplane_service_principal" {
  description = "Whether to create and configure Crossplane service principal"
  type        = bool
  default     = false
}

variable "crossplane_sp_secret_name" {
  description = "Name of the Key Vault secret containing Crossplane SP application ID"
  type        = string
  default     = "crossplane-sp-client-id"
}

variable "crossplane_sp_display_name" {
  description = "Display name for Crossplane service principal in Databricks"
  type        = string
  default     = "Crossplane"
}

variable "crossplane_sp_groups" {
  description = "Databricks group keys to add Crossplane SP to"
  type        = list(string)
  default     = ["platform_admins"]
}

# ---------------------------------------------------------------------------------------------------------------------
# ADDITIONAL SERVICE PRINCIPALS
# ---------------------------------------------------------------------------------------------------------------------

variable "service_principals" {
  description = "Map of additional service principals to register"
  type = map(object({
    application_id             = optional(string)       # Direct ID or null to fetch from Key Vault
    keyvault_secret_name       = optional(string)       # Key Vault secret name for application ID
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
