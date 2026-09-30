# Production orchestration: ADF + Databricks + dbt

Conceptual production flow:

```text
Source systems
     |
     v
Azure Data Factory
     |
     | ingestion / Copy Activity
     v
Databricks Bronze
     |
     | Databricks Job Activity
     v
Databricks Job
     |
     | dbt task
     | dbt build --target prod
     v
Silver -> Gold
```

Responsibilities:

- ADF: orchestration and ingestion.
- Databricks: compute, Delta Lake and Unity Catalog.
- dbt: SQL transformation graph, tests, documentation and lineage.

Do not reproduce the dbt model DAG as individual ADF activities. ADF should normally invoke
a coarse-grained Databricks/dbt job; `ref()` controls dependencies inside dbt.

For production, use a Databricks Job dbt task backed by Git and a `Run As` principal with the
required Unity Catalog and SQL Warehouse permissions.
