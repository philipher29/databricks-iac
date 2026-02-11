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
# DATABRICKS ACCOUNT GROUPS MAPPING
# Maps Databricks Account Group display names to their member IDs
# Use databricks_group data source with account-level provider to fetch these IDs:
#
#   data "databricks_group" "account_admins" {
#     provider     = databricks.account
#     display_name = "Account Admins"
#   }
#   # Then use: data.databricks_group.account_admins.id
#
# Or fetch via Databricks CLI:
#   databricks account groups list --output json | jq '.[] | {name: .displayName, id: .id}'
# ---------------------------------------------------------------------------------------------------------------------

account_groups = {
  # Example mappings - replace with actual Databricks Account Group member IDs:
  # "Account Admins"     = "1234567890123456"
  # "Data Platform Team" = "9876543210987654"
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
    # Add account groups by name (requires account_groups mapping above)
    # account_groups = ["Data Platform Team"]
    # Or add account groups directly by member ID:
    # account_group_ids = ["1234567890123456"]
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
    # Example: add account-level admin group as member
    # account_groups = ["Account Admins"]
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

# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS CLUSTERS
# Compute resources for running workloads (notebooks, jobs, SQL)
# Note: Can reference cluster policies by key (from cluster_policies above) or by policy ID
# ---------------------------------------------------------------------------------------------------------------------

# Uncomment and customize for your environment:
# clusters = {
#   data_eng_standard = {
#     spark_version      = "13.3.x-scala2.12"
#     node_type_id       = "Standard_DS4_v2"  # Azure node type
#     driver_node_type_id = "Standard_DS4_v2"
#     num_workers        = 2
#     autotermination_minutes = 30
#     enable_elastic_disk = true
#     policy_id          = "data_engineering"  # Reference by key
#     custom_tags = {
#       Environment = "shared"
#       Team        = "data_engineering"
#     }
#     spark_conf = {
#       "spark.databricks.cluster.profile" = "singleNode"
#     }
#     grants = [
#       { principal = "Data Engineers", permission = "ATTACH_TO" }
#     ]
#   }
#
#   data_science_gpu = {
#     spark_version      = "13.3.x-gpu-scala2.12"
#     node_type_id       = "Standard_NC24s_v3"  # GPU node type
#     num_workers        = 1
#     min_workers        = 1
#     max_workers        = 4
#     autotermination_minutes = 60
#     policy_id          = "data_science"
#     custom_tags = {
#       Environment = "shared"
#       Team        = "data_science"
#     }
#     grants = [
#       { principal = "Data Scientists", permission = "ATTACH_TO" }
#     ]
#   }
#
#   sql_warehouse = {
#     spark_version      = "11.3.x-scala2.12"
#     node_type_id       = "Standard_D4s_v5"
#     num_workers        = 1
#     autotermination_minutes = 20
#     custom_tags = {
#       Environment = "shared"
#       Purpose     = "SQL_Analytics"
#     }
#     grants = [
#       { principal = "Data Analysts", permission = "ATTACH_TO" }
#     ]
#   }
# }
