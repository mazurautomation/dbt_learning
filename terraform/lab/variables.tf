variable "databricks_profile" {
  description = "Databricks CLI authentication profile."
  type        = string
  default     = "dbt-learning"
}

variable "catalog_name" {
  description = "Unity Catalog catalog used by the lab."
  type        = string
  default     = "workspace"
}

variable "warehouse_id" {
  description = "Existing Databricks SQL Warehouse ID."
  type        = string
  default     = "09106b1d8e588c8e"
}