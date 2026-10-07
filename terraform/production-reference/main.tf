# ============================================================
# PRODUCTION REFERENCE ONLY
# Do not apply in Databricks Free Edition.
# ============================================================

resource "databricks_catalog" "pharmacy" {
  name    = "pharmacy"
  comment = "Production pharmacy analytics catalog."
}


resource "databricks_schema" "bronze" {
  catalog_name = databricks_catalog.pharmacy.name
  name         = "bronze"
}

resource "databricks_schema" "silver" {
  catalog_name = databricks_catalog.pharmacy.name
  name         = "silver"
}

resource "databricks_schema" "gold" {
  catalog_name = databricks_catalog.pharmacy.name
  name         = "gold"
}

resource "databricks_schema" "silver_history" {
  catalog_name = databricks_catalog.pharmacy.name
  name         = "silver_history"
}

resource "databricks_schema" "ops" {
  catalog_name = databricks_catalog.pharmacy.name
  name         = "ops"
}


resource "databricks_service_principal" "dbt_deployer" {
  display_name = "pharmacy-dbt-deployer"
}


resource "databricks_sql_endpoint" "transformations" {
  name             = "pharmacy-transformations"
  cluster_size     = "Small"
  max_num_clusters = 1
  auto_stop_mins   = 10
}


resource "databricks_permissions" "warehouse_usage" {
  sql_endpoint_id = databricks_sql_endpoint.transformations.id

  access_control {
    service_principal_name = databricks_service_principal.dbt_deployer.application_id
    permission_level       = "CAN_USE"
  }
}


resource "databricks_grant" "catalog_usage" {
  catalog = databricks_catalog.pharmacy.name

  principal = databricks_service_principal.dbt_deployer.application_id

  privileges = [
    "USE_CATALOG"
  ]
}


resource "databricks_grant" "silver_write" {
  schema = databricks_schema.silver.id

  principal = databricks_service_principal.dbt_deployer.application_id

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "MODIFY",
    "SELECT"
  ]
}


resource "databricks_grant" "gold_write" {
  schema = databricks_schema.gold.id

  principal = databricks_service_principal.dbt_deployer.application_id

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "MODIFY",
    "SELECT"
  ]
}


resource "databricks_grant" "history_write" {
  schema = databricks_schema.silver_history.id

  principal = databricks_service_principal.dbt_deployer.application_id

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "MODIFY",
    "SELECT"
  ]
}


resource "databricks_grant" "ops_write" {
  schema = databricks_schema.ops.id

  principal = databricks_service_principal.dbt_deployer.application_id

  privileges = [
    "USE_SCHEMA",
    "CREATE_TABLE",
    "MODIFY",
    "SELECT"
  ]
}


resource "databricks_grant" "bronze_read" {
  schema = databricks_schema.bronze.id

  principal = databricks_service_principal.dbt_deployer.application_id

  privileges = [
    "USE_SCHEMA",
    "SELECT"
  ]
}