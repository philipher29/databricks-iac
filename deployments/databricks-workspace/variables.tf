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

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKSPACE VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "workspace_name" {
  description = "Name of the Databricks workspace"
  type        = string
}

variable "workspace_sku" {
  description = "SKU tier (standard, premium, trial)"
  type        = string
  default     = "premium"
}

variable "managed_resource_group_name" {
  description = "Name of the managed resource group"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Allow public network access"
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Enable double encryption"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# VNET INJECTION
# ---------------------------------------------------------------------------------------------------------------------

variable "custom_vnet_config" {
  description = "VNet injection configuration"
  type = object({
    virtual_network_id                       = string
    private_subnet_name                      = string
    private_subnet_network_security_group_id = string
    public_subnet_name                       = string
    public_subnet_network_security_group_id  = string
    storage_account_name                     = optional(string)
    storage_account_sku_name                 = optional(string, "Standard_LRS")
    no_public_ip                             = optional(bool, true)
  })
  default = null
}

# ---------------------------------------------------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# ---------------------------------------------------------------------------------------------------------------------

variable "private_endpoints" {
  description = "Private endpoint configuration"
  type = object({
    enabled                        = bool
    subnet_id                      = string
    private_dns_zone_ids           = optional(list(string), [])
    browser_authentication_enabled = optional(bool, false)
  })
  default = null
}

# ---------------------------------------------------------------------------------------------------------------------
# ACCESS CONNECTOR
# ---------------------------------------------------------------------------------------------------------------------

variable "access_connector" {
  description = "Access Connector configuration"
  type = object({
    create                     = bool
    name                       = optional(string)
    identity_type              = optional(string, "SystemAssigned")
    user_assigned_identity_ids = optional(list(string), [])
  })
  default = {
    create = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# TAGS
# ---------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
