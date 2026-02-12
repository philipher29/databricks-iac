# ---------------------------------------------------------------------------------------------------------------------
# AUTHENTICATION VARIABLES
# Supports multiple authentication methods:
#   - User-Assigned Managed Identity (recommended for pipelines) - use_msi=true + managed_identity_client_id
#   - System-Assigned Managed Identity - use_msi=true (without managed_identity_client_id)
#   - Azure CLI (for local development) - use_msi=false
#   - Service Principal - use_msi=false + client_id + client_secret
# ---------------------------------------------------------------------------------------------------------------------

variable "subscription_id" {
  description = "Azure subscription ID for deployment"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid UUID format."
  }
}

variable "tenant_id" {
  description = "Azure tenant ID (recommended for all auth methods, required for Service Principal)"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.tenant_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid UUID format when provided."
  }
}

variable "use_msi" {
  description = "Use Managed Service Identity for authentication. Set to false to use Azure CLI or Service Principal."
  type        = bool
  default     = true
}

variable "managed_identity_client_id" {
  description = "Client ID of the User-Assigned Managed Identity. Required when use_msi=true for User-Assigned Identity. Leave null for System-Assigned Identity."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.managed_identity_client_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.managed_identity_client_id))
    error_message = "Managed identity client ID must be a valid UUID format when provided."
  }
}

variable "client_id" {
  description = "Client ID for Service Principal authentication (required when use_msi=false and not using Azure CLI)"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.client_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.client_id))
    error_message = "Client ID must be a valid UUID format when provided."
  }
}

variable "client_secret" {
  description = "Client secret for Service Principal authentication (required when use_msi=false and not using Azure CLI)"
  type        = string
  default     = null
  sensitive   = true
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

variable "permission_model" {
  description = "Built-in stage-based permission concept for Databricks groups (DB-Admin-{stage}, DB-Engineers-{stage})."
  type        = any
  default     = {}
}

variable "default_catalog_schema" {
  description = "Use existing default Databricks catalog/schema (for example hive_metastore.default) instead of creating custom catalog/schema."
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
# DATABRICKS ACCOUNT GROUPS
# Maps Databricks Account Group display names to their member IDs
# ---------------------------------------------------------------------------------------------------------------------

variable "account_groups" {
  description = "Map of Databricks Account Group display names to their member IDs for workspace group membership"
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

variable "clusters" {
  description = "Map of Azure Databricks clusters to create. See module for schema."
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
  default     = ["db_admins"]
}

# ---------------------------------------------------------------------------------------------------------------------
# ADDITIONAL SERVICE PRINCIPALS
# ---------------------------------------------------------------------------------------------------------------------

variable "service_principals" {
  description = "Map of additional service principals to register. See module for schema."
  type        = any
  default     = {}
}
