# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER POLICIES
# Governance rules for compute resources
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_cluster_policy" "this" {
  for_each = var.cluster_policies

  name                  = each.key
  definition            = each.value.definition
  description           = each.value.description
  max_clusters_per_user = each.value.max_clusters_per_user
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER POLICY PERMISSIONS
# Using consolidated permissions from locals
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_permissions" "cluster_policies" {
  for_each = {
    for policy_key in distinct([for p in values(local.cluster_policy_permissions) : p.resource_key]) : policy_key => [
      for perm in values(local.cluster_policy_permissions) : perm if perm.resource_key == policy_key
    ]
  }

  cluster_policy_id = databricks_cluster_policy.this[each.key].id

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
        for perm in each.value : contains(local.valid_privileges.cluster_policy, perm.permission)
      ])
      error_message = "Invalid permission for cluster policy. Valid values: ${join(", ", local.valid_privileges.cluster_policy)}"
    }
  }
}
