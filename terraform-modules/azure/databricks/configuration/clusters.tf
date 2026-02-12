# ---------------------------------------------------------------------------------------------------------------------
# CLUSTERS
# Azure Databricks compute clusters for workspace workloads
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_cluster" "this" {
  for_each = var.clusters

  cluster_name                = coalesce(each.value.cluster_name, each.key)
  spark_version               = each.value.spark_version
  node_type_id                = each.value.node_type_id
  driver_node_type_id         = coalesce(each.value.driver_node_type_id, each.value.node_type_id)
  autotermination_minutes     = coalesce(each.value.autotermination_minutes, local.defaults.cluster_autotermination_minutes)
  num_workers                 = each.value.autoscale == null ? coalesce(each.value.num_workers, local.defaults.cluster_num_workers) : null
  data_security_mode          = each.value.data_security_mode
  single_user_name            = each.value.single_user_name
  apply_policy_default_values = each.value.apply_policy_default_values
  instance_pool_id            = each.value.instance_pool_id
  spark_conf                  = coalesce(each.value.spark_conf, {})
  spark_env_vars              = coalesce(each.value.spark_env_vars, {})
  custom_tags                 = coalesce(each.value.custom_tags, {})

  policy_id = try(
    each.value.policy_id != null ? coalesce(
      try(databricks_cluster_policy.this[each.value.policy_id].id, null),
      each.value.policy_id
    ) : null,
    null
  )

  dynamic "autoscale" {
    for_each = each.value.autoscale != null ? [each.value.autoscale] : []
    content {
      min_workers = autoscale.value.min_workers
      max_workers = autoscale.value.max_workers
    }
  }

  dynamic "azure_attributes" {
    for_each = each.value.azure_attributes != null ? [each.value.azure_attributes] : []
    content {
      availability       = azure_attributes.value.availability
      first_on_demand    = azure_attributes.value.first_on_demand
      spot_bid_max_price = azure_attributes.value.spot_bid_max_price
      zone_id            = azure_attributes.value.zone_id
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.autoscale != null || each.value.num_workers != null
      error_message = "Cluster '${each.key}' must set either autoscale or num_workers."
    }
    precondition {
      condition     = !(each.value.autoscale != null && each.value.num_workers != null)
      error_message = "Cluster '${each.key}' cannot set both autoscale and num_workers."
    }
  }
}

resource "databricks_permissions" "clusters" {
  for_each = local.cluster_permissions

  cluster_id = databricks_cluster.this[each.key].id

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
}
