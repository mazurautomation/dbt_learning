# Pharmacy Analytics — dbt + Databricks Medallion Project

Practical dbt project designed around Databricks Medallion Architecture and an ADF-style
production flow.

## Architecture

```text
Source systems
      |
      | ADF ingestion in production
      v
+------------------+
| BRONZE           |
| bronze.*         |
| raw Delta tables |
+------------------+
      |
      | dbt source()
      v
+------------------------+
| SILVER                 |
| dbt_pawel_silver.* DEV |
| silver.* PROD          |
| cleaned / typed / DQ   |
+------------------------+
      |
      | dbt ref()
      v
+----------------------+
| GOLD                 |
| dbt_pawel_gold.* DEV |
| gold.* PROD          |
| facts / dims / KPIs  |
+----------------------+
```

The folders remain `staging`, `intermediate`, and `marts` because those describe the role of
dbt code. Bronze/Silver/Gold describe the physical data architecture.

## Physical objects

Bronze, outside dbt ownership:
- `bronze.customers`
- `bronze.products`
- `bronze.orders`
- `bronze.order_items`
- `bronze.payments`

Silver, built by dbt:
- `stg_customers`
- `stg_products`
- `stg_orders`
- `stg_order_items`
- `stg_payments`

Intermediate models are ephemeral and therefore have no physical relation.

Gold, built by dbt:
- `dim_customers`
- `dim_products`
- `fct_orders`
- `fct_daily_sales`

History:
- `customers_snapshot` in Silver history.

## DEV vs PROD schemas

`macros/generate_schema_name.sql` keeps developer isolation:

DEV:
- `dbt_pawel_silver`
- `dbt_pawel_gold`
- `dbt_pawel_silver_history`

PROD:
- `silver`
- `gold`
- `silver_history`

This prevents a developer from overwriting shared production relations.

## Migrate from project v1

If you already have `raw_pharmacy.*`, run in Databricks SQL:

```text
setup/migrate_existing_raw_to_bronze.sql
```

If starting from scratch, run:

```text
setup/create_bronze_data.sql
```

Then from the project directory:

```powershell
dbt debug
dbt clean
dbt parse
dbt build
```

Do not run a project-wide `dbt test` before the first build: tests on Gold models require those
relations to exist. `dbt build` handles model/test ordering through the DAG.

## Inspect the layers

After `dbt build`, verify in Databricks:

```sql
SHOW TABLES IN dbt_pawel_silver;
SHOW TABLES IN dbt_pawel_gold;
```

Expected Silver:
- `stg_customers`
- `stg_products`
- `stg_orders`
- `stg_order_items`
- `stg_payments`

Expected Gold:
- `dim_customers`
- `dim_products`
- `fct_orders`
- `fct_daily_sales`

`fct_orders` overrides the Gold default and remains an incremental model using Databricks MERGE.

## Useful commands

Build Silver only:

```powershell
dbt build --selector silver
```

Build Gold only:

```powershell
dbt build --selector gold
```

Build a model plus downstream nodes:

```powershell
dbt build --select fct_orders+
```

Inspect generated SQL:

```powershell
dbt compile --select fct_orders
```

Snapshot customer history:

```powershell
dbt snapshot
```

Generate docs:

```powershell
dbt docs generate
dbt docs serve
```

## Production concept

ADF does not need one activity per dbt model.

Preferred conceptual flow:

```text
ADF Copy/ingestion
       |
       v
Bronze complete
       |
       v
ADF Databricks Job Activity
       |
       v
Databricks Job / dbt task
       |
       v
dbt build --target prod
       |
       v
Silver + Gold + tests
```

See `docs/production_orchestration.md`.


## Incremental Silver exercise

Three high-volume-style Silver models are now incremental:

- `stg_orders` -> key `order_id`
- `stg_order_items` -> key `order_item_id`
- `stg_payments` -> key `payment_id`

Run the exercise in this order:

```powershell
dbt build
```

Then execute in Databricks SQL:

```text
setup/simulate_adf_daily_batch.sql
```

Then execute only the affected Silver models:

```powershell
dbt build --select stg_orders stg_order_items stg_payments
```

Then propagate the changes to Gold:

```powershell
dbt build --select fct_orders+
```

Finally execute:

```text
setup/verify_incremental_batch.sql
```

To inspect what dbt generated:

```powershell
dbt compile --select stg_orders
```

and inspect `logs/dbt.log` / Databricks SQL query history for the generated `MERGE`.


## Production-style Databricks Job

Configure a native Databricks dbt task with:

```text
Warehouse schema = dbt_prod
```

and run:

```text
dbt build --vars '{"environment":"prod"}'
```

This creates production schemas:

```text
silver
gold
silver_history
```

See:
- `docs/databricks_job_and_adf.md`
- `adf/README.md`
- `adf/databricks_job_activity.template.json`
