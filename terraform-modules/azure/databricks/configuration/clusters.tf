# ---------------------------------------------------------------------------------------------------------------------
# CLUSTERS
# Databricks compute clusters for running workloads
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_cluster" "this" {
  for_each = var.clusters

  # Basic cluster configuration
  cluster_name            = each.key
  spark_version           = each.value.spark_version
  node_type_id            = each.value.node_type_id
  driver_node_type_id     = coalesce(each.value.driver_node_type_id, each.value.node_type_id)
  autotermination_minutes = each.value.autotermination_minutes
  enable_elastic_disk     = each.value.enable_elastic_disk

  # Scaling configuration - choose autoscale or fixed workers
  dynamic "autoscale" {
    for_each = each.value.min_workers != null && each.value.max_workers != null ? [1] : []
    content {
      min_workers = each.value.min_workers
      max_workers = each.value.max_workers
    }
  }

  num_workers = each.value.min_workers == null && each.value.max_workers == null ? each.value.num_workers : null

  # Policy enforcement
  policy_id = try(
    each.value.policy_id != null ? (
      can(regex("^[0-9]+$", each.value.policy_id)) ? each.value.policy_id : databricks_cluster_policy.this[each.value.policy_id].id
    ) : null,
    null
  )

  # Instance pool
  instance_pool_id = each.value.instance_pool_id

  # Logging
  dynamic "cluster_log_conf" {
    for_each = each.value.cluster_log_conf != null ? [each.value.cluster_log_conf] : []
    content {
      dynamic "dbfs" {
        for_each = cluster_log_conf.value.dbfs != null ? [cluster_log_conf.value.dbfs] : []
        content {
          destination = dbfs.value.destination
        }
      }
    }
  }

  # Cloud-specific attributes
  dynamic "aws_attributes" {
    for_each = each.value.aws_attributes != null ? [each.value.aws_attributes] : []
    content {
      availability     = aws_attributes.value.availability
      zone_id          = aws_attributes.value.zone_id
      ebs_volume_count = aws_attributes.value.ebs_volume_count
      ebs_volume_size  = aws_attributes.value.ebs_volume_size
    }
  }

  dynamic "azure_attributes" {
    for_each = each.value.azure_attributes != null ? [each.value.azure_attributes] : []
    content {
      availability       = azure_attributes.value.availability
      first_on_demand    = azure_attributes.value.first_on_demand
      spot_bid_max_price = azure_attributes.value.spot_bid_max_price
    }
  }

  dynamic "gcp_attributes" {
    for_each = each.value.gcp_attributes != null ? [each.value.gcp_attributes] : []
    content {
      availability    = gcp_attributes.value.availability
      local_ssd_count = gcp_attributes.value.local_ssd_count
    }
  }

  # SSH access
  ssh_public_keys = each.value.ssh_public_keys

  # Spark configuration
  custom_tags    = each.value.custom_tags
  spark_conf     = each.value.spark_conf
  spark_env_vars = each.value.env_vars

  # Init scripts
  dynamic "init_scripts" {
    for_each = each.value.init_scripts != null ? each.value.init_scripts : []
    content {
      dynamic "dbfs" {
        for_each = init_scripts.value.dbfs != null ? [init_scripts.value.dbfs] : []
        content {
          destination = dbfs.value.destination
        }
      }
      dynamic "s3" {
        for_each = init_scripts.value.s3 != null ? [init_scripts.value.s3] : []
        content {
          destination = s3.value.destination
          region      = s3.value.region
          endpoint    = s3.value.endpoint
        }
      }
    }
  }

  # Workload type (for SQL/jobs specific behavior)
  dynamic "workload_type" {
    for_each = each.value.workload_type != null ? [each.value.workload_type] : []
    content {
      dynamic "clients" {
        for_each = workload_type.value.clients != null ? [workload_type.value.clients] : []
        content {
          notebooks = clients.value.notebooks
          jobs      = clients.value.jobs
        }
      }
    }
  }
}

# Cluster policies are managed separately in cluster_policies.tf
# The policy_id field in the cluster resource references either an existing policy ID or a policy key that maps to the created policy

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER PERMISSIONS
# Using consolidated permissions from locals
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_permissions" "clusters" {
  for_each = {
    for cluster_key in distinct([for p in values(local.cluster_permissions) : p.resource_key]) : cluster_key => [
      for perm in values(local.cluster_permissions) : perm if perm.resource_key == cluster_key
    ]
  }

  cluster_id = databricks_cluster.this[each.key].cluster_id

  dynamic "access_control" {
    for_each = each.value
    content {
      group_name       = access_control.value.principal
      permission_level = access_control.value.permission
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for perm in each.value : contains(local.valid_privileges.cluster, perm.permission)
      ])
      error_message = "Invalid permission for cluster. Valid values: ${join(", ", local.valid_privileges.cluster)}"
    }
  }

  depends_on = [databricks_cluster.this]
}
