# ---------------------------------------------------------------------------------------------------------------------
# DATABRICKS GROUPS
# Workspace groups with membership management
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group" "this" {
  for_each = var.groups

  display_name               = each.value.display_name
  allow_cluster_create       = each.value.allow_cluster_create
  allow_instance_pool_create = each.value.allow_instance_pool_create
  databricks_sql_access      = each.value.databricks_sql_access
  workspace_access           = each.value.workspace_access
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP - Users
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "users" {
  for_each = {
    for item in local.group_members : "${item.group_key}-${item.member}" => item
  }

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = each.value.member
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP - Service Principals
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "service_principals" {
  for_each = {
    for item in local.group_service_principals : "${item.group_key}-${item.service_principal}" => item
  }

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = each.value.service_principal
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP - Nested Groups
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "child_groups" {
  for_each = {
    for item in local.group_child_groups : "${item.group_key}-${item.child_group}" => item
  }

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = databricks_group.this[each.value.child_group].id
}

# ---------------------------------------------------------------------------------------------------------------------
# GROUP MEMBERSHIP - EntraID Groups
# Maps Azure AD groups to Databricks groups without requiring azuread provider
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "entra_id_groups" {
  for_each = {
    for item in local.group_entra_id_groups : "${item.group_key}-${item.entra_group_name}" => item
  }

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = each.value.entra_group_id
}
