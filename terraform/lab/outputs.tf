output "current_user" {
  value = data.databricks_current_user.me.user_name
}

output "catalog_name" {
  value = data.databricks_catalog.workspace.name
}

output "terraform_schema" {
  value = databricks_schema.tf_lab.id
}

output "warehouse_id" {
  value = data.databricks_sql_warehouse.existing.id
}

output "warehouse_name" {
  value = data.databricks_sql_warehouse.existing.name
}