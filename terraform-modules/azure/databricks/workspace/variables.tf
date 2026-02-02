# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "Name of the Azure Databricks workspace"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,64}$", var.name))
    error_message = "Workspace name must be 3-64 characters, alphanumeric and hyphens only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Databricks workspace will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the Databricks workspace"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# WORKSPACE CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "sku" {
  description = "The SKU tier of the Databricks workspace (standard, premium, or trial)"
  type        = string
  default     = "premium"

  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "SKU must be one of: standard, premium, trial."
  }
}

variable "managed_resource_group_name" {
  description = "Name of the managed resource group for Databricks. If not provided, Azure will generate one."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the workspace"
  type        = bool
  default     = true
}

variable "network_security_group_rules_required" {
  description = "Security rules required for the workspace. Options: AllRules, NoAzureDatabricksRules, NoAzureServiceRules"
  type        = string
  default     = "AllRules"

  validation {
    condition     = contains(["AllRules", "NoAzureDatabricksRules", "NoAzureServiceRules"], var.network_security_group_rules_required)
    error_message = "Must be one of: AllRules, NoAzureDatabricksRules, NoAzureServiceRules."
  }
}

variable "customer_managed_key_enabled" {
  description = "Enable customer-managed key encryption for the workspace"
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption (double encryption)"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# VNET INJECTION (Optional)
# ---------------------------------------------------------------------------------------------------------------------

variable "custom_vnet_config" {
  description = "Configuration for VNet injection. Set to null to use Databricks-managed VNet."
  type = object({
    virtual_network_id                           = string
    private_subnet_name                          = string
    private_subnet_network_security_group_id     = string
    public_subnet_name                           = string
    public_subnet_network_security_group_id      = string
    storage_account_name                         = optional(string)
    storage_account_sku_name                     = optional(string, "Standard_LRS")
    no_public_ip                                 = optional(bool, true)
  })
  default = null
}

# ---------------------------------------------------------------------------------------------------------------------
# PRIVATE ENDPOINTS (Optional)
# ---------------------------------------------------------------------------------------------------------------------

variable "private_endpoints" {
  description = "Configuration for private endpoints"
  type = object({
    enabled                        = bool
    subnet_id                      = string
    private_dns_zone_ids           = optional(list(string), [])
    browser_authentication_enabled = optional(bool, false)
  })
  default = null
}

# ---------------------------------------------------------------------------------------------------------------------
# ACCESS CONNECTOR CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "access_connector" {
  description = "Configuration for the Access Connector (required for Unity Catalog external locations)"
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
