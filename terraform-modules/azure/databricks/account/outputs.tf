# ---------------------------------------------------------------------------------------------------------------------
# METASTORE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "metastores" {
  description = "Map of created Unity Catalog metastores"
  value = {
    for key, metastore in databricks_metastore.this : key => {
      id           = metastore.id
      name         = metastore.name
      region       = metastore.region
      storage_root = metastore.storage_root
    }
  }
}
