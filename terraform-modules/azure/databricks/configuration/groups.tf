# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS GROUPS
# Workspace groups with membership management
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group" "this" {
  for_each = var.groups

  display_name               = each.value.display_name
  allow_cluster_create       = coalesce(each.value.allow_cluster_create, local.defaults.group_allow_cluster_create)
  allow_instance_pool_create = coalesce(each.value.allow_instance_pool_create, local.defaults.group_allow_instance_pool_create)
  databricks_sql_access      = coalesce(each.value.databricks_sql_access, local.defaults.group_databricks_sql_access)
  workspace_access           = coalesce(each.value.workspace_access, local.defaults.group_workspace_access)
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP - Direct Members (Users, Service Principals, EntraID Groups)
# Unified resource for all non-child-group memberships
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "direct" {
  for_each = local.direct_memberships

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = each.value.member_id
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP - Child Groups
# Separate resource because member_id references created groups
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "child_groups" {
  for_each = local.child_group_memberships

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = databricks_group.this[each.value.member_id].id
}
