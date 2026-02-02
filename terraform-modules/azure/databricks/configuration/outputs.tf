# ---------------------------------------------------------------------------------------------------------------------
# GROUP OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "groups" {
  description = "Map of created Databricks groups"
  value = {
    for key, group in databricks_group.this : key => {
      id           = group.id
      display_name = group.display_name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE CREDENTIAL OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "storage_credentials" {
  description = "Map of created storage credentials"
  value = {
    for key, cred in databricks_storage_credential.this : key => {
      id   = cred.id
      name = cred.name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EXTERNAL LOCATION OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "external_locations" {
  description = "Map of created external locations"
  value = {
    for key, loc in databricks_external_location.this : key => {
      id   = loc.id
      name = loc.name
      url  = loc.url
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CATALOG OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "catalogs" {
  description = "Map of created catalogs"
  value = {
    for key, cat in databricks_catalog.this : key => {
      id   = cat.id
      name = cat.name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SCHEMA OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "schemas" {
  description = "Map of created schemas"
  value = {
    for key, schema in databricks_schema.this : key => {
      id           = schema.id
      name         = schema.name
      catalog_name = schema.catalog_name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VOLUME OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "volumes" {
  description = "Map of created volumes"
  value = {
    for key, vol in databricks_volume.this : key => {
      id               = vol.id
      name             = vol.name
      catalog_name     = vol.catalog_name
      schema_name      = vol.schema_name
      volume_type      = vol.volume_type
      storage_location = vol.storage_location
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER POLICY OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_policies" {
  description = "Map of created cluster policies"
  value = {
    for key, policy in databricks_cluster_policy.this : key => {
      id   = policy.id
      name = policy.name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECRET SCOPE OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "secret_scopes" {
  description = "Map of created secret scopes"
  value = {
    for key, scope in databricks_secret_scope.this : key => {
      id   = scope.id
      name = scope.name
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IP ACCESS LIST OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "ip_access_lists" {
  description = "Map of created IP access lists"
  value = {
    for key, list in databricks_ip_access_list.this : key => {
      id        = list.id
      label     = list.label
      list_type = list.list_type
    }
  }
}
