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
# DEFAULTS CONFIGURATION
# Override module defaults - see module's defaults.tf for available options
# ---------------------------------------------------------------------------------------------------------------------

variable "defaults" {
  description = "Override module defaults (group permissions, catalog isolation mode, etc.)"
  type        = any
  default     = {}
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
# MODULE PASSTHROUGH VARIABLES
# These use 'any' type to avoid duplicating complex type definitions from the module.
# Validation is handled at the module level.
# ---------------------------------------------------------------------------------------------------------------------

variable "groups" {
  description = "Map of Databricks groups to create. See module for schema."
  type        = any
  default     = {}
}

variable "storage_credentials" {
  description = "Map of storage credentials to create. See module for schema."
  type        = any
  default     = {}
}

variable "external_locations" {
  description = "Map of external locations to create, with optional EXTERNAL volume creation. See module for schema."
  type        = any
  default     = {}
}

variable "catalogs" {
  description = "Map of catalogs to create with nested schemas. See module for schema."
  type        = any
  default     = {}
}

variable "volumes" {
  description = "Map of MANAGED volumes to create. For EXTERNAL volumes, use the 'volume' block in external_locations."
  type        = any
  default     = {}
}

variable "cluster_policies" {
  description = "Map of cluster policies to create. See module for schema."
  type        = any
  default     = {}
}

variable "secret_scopes" {
  description = "Map of secret scopes to create (Databricks-backed or Key Vault-backed). See module for schema."
  type        = any
  default     = {}
}

variable "ip_access_lists" {
  description = "Map of IP access lists for workspace access control. See module for schema."
  type        = any
  default     = {}
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
  description = "Map of additional service principals to register. See module for schema."
  type        = any
  default     = {}
}
