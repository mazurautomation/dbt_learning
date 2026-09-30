{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
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
    record_updated_at
from {{ ref('int_orders_enriched') }}

{% if is_incremental() %}
where record_updated_at >= (
    select coalesce(
        max(record_updated_at),
        cast('1900-01-01 00:00:00' as timestamp)
    )
    from {{ this }}
)
{% endif %}
