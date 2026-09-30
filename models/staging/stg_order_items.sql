{{
    config(
        materialized='incremental',
        unique_key='order_item_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

select
    cast(order_item_id as bigint) as order_item_id,
    cast(order_id as bigint) as order_id,
    cast(product_id as bigint) as product_id,
    cast(quantity as int) as quantity,
    cast(unit_price as decimal(12, 2)) as unit_price,
    cast(updated_at as timestamp) as updated_at,
    cast(_loaded_at as timestamp) as _loaded_at
from {{ source('pharmacy_bronze', 'order_items') }}

{% if is_incremental() %}
where cast(_loaded_at as timestamp) > (
    select coalesce(
        max(_loaded_at),
        cast('1900-01-01 00:00:00' as timestamp)
    )
    from {{ this }}
)
{% endif %}
