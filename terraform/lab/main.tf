data "databricks_current_user" "me" {}

data "databricks_catalog" "workspace" {
  name = var.catalog_name
}

data "databricks_sql_warehouse" "existing" {
  id = var.warehouse_id
}

resource "databricks_schema" "tf_lab" {
  catalog_name = data.databricks_catalog.workspace.name
  name         = "tf_lab"

  comment = "Terraform-managed schema for dbt infrastructure lab."
}