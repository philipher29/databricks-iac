# ---------------------------------------------------------------------------------------------------------------------
# COMMON DATABRICKS CONFIGURATION
# Shared settings across all environments
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# ENTRA ID GROUPS MAPPING
# Maps Azure AD group display names to object IDs (avoids azuread provider)
# Replace UUIDs with actual Azure AD group object IDs from your tenant
# ---------------------------------------------------------------------------------------------------------------------

entra_id_groups = {
  # Example mappings - replace with actual Azure AD group object IDs:
  # "Data Engineering Team" = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  # "Data Science Team"     = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
  # "Data Analyst Team"     = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUPS (common structure, may have different permissions per env)
# Use entra_id_groups field to map Azure AD groups without azuread provider
# ---------------------------------------------------------------------------------------------------------------------

groups = {
  data_engineers = {
    display_name          = "Data Engineers"
    allow_cluster_create  = true
    databricks_sql_access = true
    workspace_access      = true
  }

  data_scientists = {
    display_name          = "Data Scientists"
    allow_cluster_create  = false
    databricks_sql_access = true
    workspace_access      = true
  }

  data_analysts = {
    display_name          = "Data Analysts"
    allow_cluster_create  = false
    databricks_sql_access = true
    workspace_access      = true
  }

  platform_admins = {
    display_name               = "Platform Admins"
    allow_cluster_create       = true
    allow_instance_pool_create = true
    databricks_sql_access      = true
    workspace_access           = true
    child_groups               = ["data_engineers"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER POLICIES (governance)
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
        },
        "custom_tags.Environment": {
          "type": "fixed",
          "value": "shared"
        }
      }
    EOT
    grants = [
      { principal = "Data Engineers", permission = "CAN_USE" }
    ]
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
    grants = [
      { principal = "Data Scientists", permission = "CAN_USE" }
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CROSSPLANE SERVICE PRINCIPAL
# Enables Crossplane to manage Databricks resources via Kubernetes
# ---------------------------------------------------------------------------------------------------------------------

# Enable in environment-specific tfvars when ready:
# enable_crossplane_service_principal = true
# keyvault_name                       = "kv-databricks-<env>"
# crossplane_sp_secret_name           = "crossplane-sp-client-id"
# crossplane_sp_groups                = ["platform_admins"]
