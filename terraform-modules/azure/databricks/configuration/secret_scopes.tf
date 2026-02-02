# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES
# Secure storage for credentials and sensitive configuration
# Supports both Databricks-backed and Azure Key Vault-backed scopes
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_secret_scope" "this" {
  for_each = var.secret_scopes

  name = each.key
  initial_manage_principal = each.value.keyvault_metadata == null ? coalesce(
    each.value.initial_manage_principal,
    local.defaults.secret_scope_initial_manage_principal
  ) : null

  dynamic "keyvault_metadata" {
    for_each = each.value.keyvault_metadata != null ? [each.value.keyvault_metadata] : []
    content {
      resource_id = keyvault_metadata.value.resource_id
      dns_name    = keyvault_metadata.value.dns_name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPE ACLs
# Access control for secret scopes using consolidated locals
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_secret_acl" "this" {
  for_each = local.secret_scope_acls

  scope      = databricks_secret_scope.this[each.value.resource_key].name
  principal  = each.value.principal
  permission = each.value.permission

  lifecycle {
    precondition {
      condition     = contains(local.valid_privileges.secret_scope, each.value.permission)
      error_message = "Invalid permission for secret scope ACL. Valid values: ${join(", ", local.valid_privileges.secret_scope)}"
    }
  }
}
