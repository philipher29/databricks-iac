# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPES
# Secure storage for credentials and sensitive configuration
# Supports both Databricks-backed and Azure Key Vault-backed scopes
#
# Key Vault-backed scopes can be defined using:
#   - keyvault_name/keyvault_rg: Resource ID constructed dynamically (recommended)
#   - keyvault_metadata: Legacy pattern with explicit resource_id and dns_name
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Construct Key Vault metadata for scopes using keyvault_name pattern
  secret_scope_keyvault_metadata = {
    for k, v in var.secret_scopes : k => (
      v.keyvault_name != null ? {
        resource_id = "/subscriptions/${var.subscription_id}/resourceGroups/${coalesce(v.keyvault_rg, var.default_resource_group_name)}/providers/Microsoft.KeyVault/vaults/${v.keyvault_name}"
        dns_name    = "https://${v.keyvault_name}.vault.azure.net/"
      } : v.keyvault_metadata
    )
  }

  # Determine if scope is Key Vault-backed
  is_keyvault_scope = {
    for k, v in var.secret_scopes : k => (v.keyvault_name != null || v.keyvault_metadata != null)
  }
}

resource "databricks_secret_scope" "this" {
  for_each = var.secret_scopes

  name = each.key
  # initial_manage_principal only applies to Databricks-backed scopes
  initial_manage_principal = local.is_keyvault_scope[each.key] ? null : coalesce(
    each.value.initial_manage_principal,
    local.defaults.secret_scope_initial_manage_principal
  )

  dynamic "keyvault_metadata" {
    for_each = local.secret_scope_keyvault_metadata[each.key] != null ? [local.secret_scope_keyvault_metadata[each.key]] : []
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
