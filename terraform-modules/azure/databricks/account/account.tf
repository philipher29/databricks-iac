# ---------------------------------------------------------------------------------------------------------------------
# UNITY CATALOG METASTORES
# ---------------------------------------------------------------------------------------------------------------------

resource "databricks_metastore" "this" {
  for_each = var.metastores

  name                = coalesce(each.value.name, each.key)
  storage_root        = each.value.storage_root
  region              = each.value.region
  owner               = each.value.owner
  delta_sharing_scope = each.value.delta_sharing_scope
  force_destroy       = each.value.force_destroy
}
