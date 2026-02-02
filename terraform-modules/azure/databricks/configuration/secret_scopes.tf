# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES
# Secure storage for credentials and sensitive configuration
# Supports both Databricks-backed and Azure Key Vault-backed scopes
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_secret_scope" "this" {
  for_each = var.secret_scopes

  name                     = each.key
  initial_manage_principal = each.value.keyvault_metadata == null ? each.value.initial_manage_principal : null

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
# Access control for secret scopes
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_secret_acl" "this" {
  for_each = {
    for item in flatten([
      for scope_key, scope in var.secret_scopes : [
        for acl in scope.acls : {
          scope_key  = scope_key
          principal  = acl.principal
          permission = acl.permission
        }
      ]
    ]) : "${item.scope_key}-${item.principal}" => item
  }

  scope      = databricks_secret_scope.this[each.value.scope_key].name
  principal  = each.value.principal
  permission = each.value.permission
}
