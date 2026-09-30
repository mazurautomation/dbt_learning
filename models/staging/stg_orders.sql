{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

select
    cast(order_id as bigint) as order_id,
    cast(customer_id as bigint) as customer_id,
    {{ normalize_status('order_status') }} as order_status,
    cast(ordered_at as timestamp) as ordered_at,
    cast(updated_at as timestamp) as updated_at,
    cast(_loaded_at as timestamp) as _loaded_at
from {{ source('pharmacy_bronze', 'orders') }}

{% if is_incremental() %}
where cast(_loaded_at as timestamp) > (
    select coalesce(
        max(_loaded_at),
        cast('1900-01-01 00:00:00' as timestamp)
    )
    from {{ this }}
)
{% endif %}
