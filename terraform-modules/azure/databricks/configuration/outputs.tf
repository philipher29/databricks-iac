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
  description = "Map of all created volumes (both managed and external)"
  value = merge(
    {
      for key, vol in databricks_volume.managed : key => {
        id               = vol.id
        name             = vol.name
        catalog_name     = vol.catalog_name
        schema_name      = vol.schema_name
        volume_type      = vol.volume_type
        storage_location = vol.storage_location
      }
    },
    {
      for key, vol in databricks_volume.external : key => {
        id               = vol.id
        name             = vol.name
        catalog_name     = vol.catalog_name
        schema_name      = vol.schema_name
        volume_type      = vol.volume_type
        storage_location = vol.storage_location
      }
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "clusters" {
  description = "Map of created clusters"
  value = {
    for key, cluster in databricks_cluster.this : key => {
      id            = try(cluster.cluster_id, cluster.id)
      cluster_name  = cluster.cluster_name
      spark_version = cluster.spark_version
      node_type_id  = cluster.node_type_id
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

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE PRINCIPAL OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "crossplane_service_principal" {
  description = "Crossplane service principal details"
  value = var.crossplane_service_principal != null ? {
    id             = databricks_service_principal.crossplane[0].id
    application_id = databricks_service_principal.crossplane[0].application_id
    display_name   = databricks_service_principal.crossplane[0].display_name
  } : null
}

output "service_principals" {
  description = "Map of created service principals"
  value = {
    for key, sp in databricks_service_principal.this : key => {
      id             = sp.id
      application_id = sp.application_id
      display_name   = sp.display_name
    }
  }
}

output "permission_groups" {
  description = "Default stage-based permission groups created by the built-in permission model."
  value = local.permission_model.enabled ? {
    admin_group_name    = local.admin_group_display_name
    engineer_group_name = local.engineer_group_display_name
  } : null
}
