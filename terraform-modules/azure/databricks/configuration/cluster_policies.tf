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
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_permissions" "cluster_policies" {
  for_each = {
    for policy_key, policy in var.cluster_policies : policy_key => policy
    if length(policy.grants) > 0
  }

  cluster_policy_id = databricks_cluster_policy.this[each.key].id

  dynamic "access_control" {
    for_each = each.value.grants
    content {
      group_name       = access_control.value.principal
      permission_level = access_control.value.permission
    }
  }
}
