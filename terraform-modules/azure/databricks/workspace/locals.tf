# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES
# ---------------------------------------------------------------------------------------------------------------------

locals {
  access_connector_name = var.access_connector.create ? (
    var.access_connector.name != null ? var.access_connector.name : "${var.name}-access-connector"
  ) : null
}
