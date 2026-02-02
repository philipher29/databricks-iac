# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LISTS
# Network-level access control for the Databricks workspace
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_ip_access_list" "this" {
  for_each = var.ip_access_lists

  label        = each.key
  list_type    = each.value.list_type
  ip_addresses = each.value.ip_addresses
  enabled      = each.value.enabled
}
