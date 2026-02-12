# ---------------------------------------------------------------------------------------------------------------------
# COMMON DATABRICKS CONFIGURATION
# Shared settings across all environments
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# PERMISSION MODEL
# Creates two stage-based groups in each workspace:
#   - DB-Admin-{stage}
#   - DB-Engineers-{stage}
# Stage comes from environment variable (dev/it/qas/prod).
# ---------------------------------------------------------------------------------------------------------------------

permission_model = {
  enabled = true
}

# ---------------------------------------------------------------------------------------------------------------------
# ENTRA ID GROUPS MAPPING
# Maps Azure AD group display names to object IDs (avoids azuread provider)
# ---------------------------------------------------------------------------------------------------------------------

entra_id_groups = {
  # Example:
  # "Engineering Oncall" = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS ACCOUNT GROUPS MAPPING
# Maps Databricks Account Group display names to their member IDs
# ---------------------------------------------------------------------------------------------------------------------

account_groups = {
  # Example:
  # "Account Admins" = "1234567890123456"
}

# ---------------------------------------------------------------------------------------------------------------------
# ADDITIONAL CUSTOM GROUPS (optional)
# The two stage-based groups above are created automatically.
# ---------------------------------------------------------------------------------------------------------------------

groups = {}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER POLICIES (governance baseline)
# Keep grants empty here; assign stage-specific principals in environment tfvars if needed.
# ---------------------------------------------------------------------------------------------------------------------

cluster_policies = {
  data_engineering = {
    description = "Standard policy for data engineering workloads"
    definition  = <<-EOT
      {
        "spark_version": {
          "type": "regex",
          "pattern": "1[3-9]\\.[0-9]+\\.x-scala.*"
        },
        "autotermination_minutes": {
          "type": "range",
          "minValue": 10,
          "maxValue": 120,
          "defaultValue": 30
        }
      }
    EOT
    grants      = []
  }

  data_science = {
    description = "Policy for data science and ML workloads"
    definition  = <<-EOT
      {
        "spark_version": {
          "type": "regex",
          "pattern": "1[3-9]\\.[0-9]+\\.x-.*ml.*"
        },
        "autotermination_minutes": {
          "type": "fixed",
          "value": 60
        }
      }
    EOT
    grants      = []
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL AZURE DATABRICKS CLUSTERS
# Add concrete clusters in environment-specific tfvars.
# ---------------------------------------------------------------------------------------------------------------------

# clusters = {
#   engineering_shared = {
#     spark_version           = "13.3.x-scala2.12"
#     node_type_id            = "Standard_DS4_v2"
#     autotermination_minutes = 30
#     num_workers             = 2
#     policy_id               = "data_engineering"
#     azure_attributes = {
#       availability = "ON_DEMAND_AZURE"
#     }
#     grants = [
#       { principal = "DB-Engineers-dev", permission = "CAN_ATTACH_TO" },
#       { principal = "DB-Admin-dev", permission = "CAN_MANAGE" }
#     ]
#   }
# }
