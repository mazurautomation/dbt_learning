{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='cdc_hard_delete',
        on_schema_change='fail'
    )
}}

select
    order_id,
    customer_id,
    order_status,
    ordered_at,
    item_quantity,
    order_amount,
    paid_amount,
    is_deleted,
    record_updated_at,
    _ingest_batch_id

from {{ ref('int_orders_enriched') }}

{% if is_incremental() %}

    {{ cdc_batch_filter('_ingest_batch_id') }}

{% else %}

    where not is_deleted

{% endif %}