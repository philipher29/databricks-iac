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
  display_name   = coalesce(var.crossplane_service_principal.display_name, "Crossplane")
  active         = true

  allow_cluster_create       = coalesce(var.crossplane_service_principal.allow_cluster_create, local.defaults.sp_allow_cluster_create)
  allow_instance_pool_create = coalesce(var.crossplane_service_principal.allow_instance_pool_create, local.defaults.sp_allow_instance_pool_create)
  databricks_sql_access      = coalesce(var.crossplane_service_principal.databricks_sql_access, local.defaults.sp_databricks_sql_access)
  workspace_access           = coalesce(var.crossplane_service_principal.workspace_access, local.defaults.sp_workspace_access)
}

# ---------------------------------------------------------------------------------------------------------------------
# GENERIC SERVICE PRINCIPALS
# Additional service principals defined via variable for automation tools
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_service_principal" "this" {
  for_each = var.service_principals

  application_id = each.value.application_id
  display_name   = coalesce(each.value.display_name, each.key)
  active         = coalesce(each.value.active, local.defaults.sp_active)

  allow_cluster_create       = coalesce(each.value.allow_cluster_create, local.defaults.sp_allow_cluster_create)
  allow_instance_pool_create = coalesce(each.value.allow_instance_pool_create, local.defaults.sp_allow_instance_pool_create)
  databricks_sql_access      = coalesce(each.value.databricks_sql_access, local.defaults.sp_databricks_sql_access)
  workspace_access           = coalesce(each.value.workspace_access, local.defaults.sp_workspace_access)
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPAL GROUP MEMBERSHIPS
# Unified resource for all SP group memberships using consolidated locals
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_group_member" "service_principals" {
  for_each = { for m in local.all_sp_group_memberships : m.key => m }

  group_id = databricks_group.this[each.value.group_key].id
  member_id = each.value.type == "crossplane" ? (
    databricks_service_principal.crossplane[0].id
  ) : databricks_service_principal.this[each.value.sp_key].id

  depends_on = [
    databricks_group.this,
    databricks_service_principal.crossplane,
    databricks_service_principal.this
  ]
}
