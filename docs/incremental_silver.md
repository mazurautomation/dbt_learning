# Incremental Silver with dbt + Databricks

`stg_orders`, `stg_order_items`, and `stg_payments` are incremental models.

Each model has:

```sql
config(
    materialized='incremental',
    unique_key='...',
    incremental_strategy='merge',
    on_schema_change='fail'
)
```

On the initial run, dbt creates the entire target relation.

On later runs, this filter is active:

```sql
{% if is_incremental() %}
where _loaded_at > (
    select coalesce(max(_loaded_at), timestamp('1900-01-01'))
    from {{ this }}
)
{% endif %}
```

`_loaded_at` is the ingestion watermark owned by the data platform. It is intentionally used
instead of source-system `updated_at`.

The rows selected from Bronze become the MERGE source. `unique_key` defines the match key:

- orders -> `order_id`
- order_items -> `order_item_id`
- payments -> `payment_id`

Databricks/dbt then performs the equivalent of:

```sql
MERGE INTO silver_target t
USING changed_bronze_rows s
ON t.id = s.id
WHEN MATCHED THEN UPDATE ...
WHEN NOT MATCHED THEN INSERT ...
```

Important production note:

A timestamp watermark is sufficient for this exercise but is not always the best production
watermark. If ingestion can deliver late/out-of-order rows, use a deliberate lookback window,
batch identifier, CDC sequence/version, or another ingestion control that guarantees that
changed rows cannot be skipped.
