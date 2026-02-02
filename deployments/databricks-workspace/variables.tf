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
