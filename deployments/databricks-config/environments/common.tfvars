# ---------------------------------------------------------------------------------------------------------------------
# COMMON DATABRICKS CONFIGURATION
# Shared settings across all environments
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# GROUPS (common structure, may have different permissions per env)
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
