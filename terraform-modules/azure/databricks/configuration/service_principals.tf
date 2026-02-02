# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPALS
# Registers and configures service principals in Databricks workspace
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# CROSSPLANE SERVICE PRINCIPAL
# Service principal for Crossplane to manage Databricks resources
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_service_principal" "crossplane" {
  count = var.crossplane_service_principal != null ? 1 : 0

  application_id = var.crossplane_service_principal.application_id
  display_name   = var.crossplane_service_principal.display_name
  active         = true

  allow_cluster_create       = var.crossplane_service_principal.allow_cluster_create
  allow_instance_pool_create = var.crossplane_service_principal.allow_instance_pool_create
  databricks_sql_access      = var.crossplane_service_principal.databricks_sql_access
  workspace_access           = var.crossplane_service_principal.workspace_access
}

# Add Crossplane SP to specified groups
resource "databricks_group_member" "crossplane_groups" {
  for_each = toset(local.crossplane_sp_groups)

  group_id  = databricks_group.this[each.value].id
  member_id = databricks_service_principal.crossplane[0].id

  depends_on = [databricks_group.this]
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERIC SERVICE PRINCIPALS
# Additional service principals defined via variable for automation tools
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_service_principal" "this" {
  for_each = var.service_principals

  application_id = each.value.application_id
  display_name   = coalesce(each.value.display_name, each.key)
  active         = each.value.active

  allow_cluster_create       = each.value.allow_cluster_create
  allow_instance_pool_create = each.value.allow_instance_pool_create
  databricks_sql_access      = each.value.databricks_sql_access
  workspace_access           = each.value.workspace_access
}

# Add generic SPs to their specified groups
resource "databricks_group_member" "service_principal_groups" {
  for_each = {
    for item in local.service_principal_group_memberships : "${item.sp_key}-${item.group_key}" => item
  }

  group_id  = databricks_group.this[each.value.group_key].id
  member_id = databricks_service_principal.this[each.value.sp_key].id

  depends_on = [databricks_group.this, databricks_service_principal.this]
}
