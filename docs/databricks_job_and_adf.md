# Production-style orchestration: Git -> Databricks Job -> dbt -> ADF

## Three different DAGs

```text
ADF pipeline
  ingestion -> run Databricks Job -> downstream systems

Databricks Job
  dbt task

dbt DAG
  stg_* -> int_* -> dim_*/fct_* -> tests
```

Do not reproduce every dbt model as an ADF activity.

## Databricks Job configuration

Use a native Databricks `dbt` task.

Recommended settings:

- Job name: `pharmacy_analytics_dbt_prod`
- Task name: `dbt_build`
- Type: `dbt`
- Source: `Git provider`
- Repository: your GitHub repository
- Branch: `main`
- Project directory: repository root
- SQL warehouse: your serverless SQL warehouse
- Warehouse catalog: your Unity Catalog catalog, for example `workspace`
- Warehouse schema: `dbt_prod`
- dbt CLI compute: Serverless
- Environment / libraries: `dbt-default`
- Command:

```text
dbt build --vars '{"environment":"prod"}'
```

When a SQL warehouse is selected for a Databricks dbt task, Databricks generates the dbt
connection profile for the task. Therefore this tutorial does not depend on `--target prod`.

The custom `generate_schema_name` macro requires BOTH:
- `environment == prod`
- `target.schema == dbt_prod`

Only then are custom schemas mapped directly to:
- `silver`
- `gold`
- `silver_history`

Local development remains isolated:
- `dbt_pawel_silver`
- `dbt_pawel_gold`
- `dbt_pawel_silver_history`

## Production identity

For learning, `Run As` can be your own Databricks user.

For production, use a service principal with only the required permissions, including:
- CAN USE on the SQL warehouse
- USE CATALOG on the catalog
- appropriate USE SCHEMA / SELECT / MODIFY / CREATE privileges

## ADF responsibility

ADF performs or coordinates ingestion first. When Bronze is complete, it runs the saved
Databricks Job using a Databricks Job activity.

```text
ADF trigger
    |
    +--> Bronze ingestion
              |
              v
    Databricks Job activity
              |
              v
    pharmacy_analytics_dbt_prod
              |
              v
          dbt build
              |
          Silver + Gold
```

ADF should not contain activities such as `Run stg_orders`, `Run fct_orders`, etc.
`ref()` and the dbt DAG own those dependencies.
