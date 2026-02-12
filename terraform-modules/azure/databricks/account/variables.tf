# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS ACCOUNT-LEVEL CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

variable "metastores" {
  description = "Map of Unity Catalog metastores to create (supports multiple regions)."
  type = map(object({
    name                = optional(string)
    storage_root        = string
    region              = string
    owner               = optional(string)
    delta_sharing_scope = optional(string)
    force_destroy       = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, metastore in var.metastores : can(regex("^(abfss|wasbs|s3|gs)://", metastore.storage_root))
    ])
    error_message = "Metastore storage_root must start with abfss://, wasbs://, s3://, or gs://."
  }

  validation {
    condition = alltrue([
      for _, metastore in var.metastores : length(trimspace(metastore.region)) > 0
    ])
    error_message = "Metastore region must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for _, metastore in var.metastores : metastore.delta_sharing_scope == null || contains(["INTERNAL", "OPEN"], metastore.delta_sharing_scope)
    ])
    error_message = "delta_sharing_scope must be one of: INTERNAL, OPEN."
  }
}
