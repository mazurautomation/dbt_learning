{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

-- CI schema lifecycle test

select
    cast(order_id as bigint) as order_id,
    cast(customer_id as bigint) as customer_id,
    {{ normalize_status('order_status') }} as order_status,
    cast(ordered_at as timestamp) as ordered_at,
    cast(updated_at as timestamp) as updated_at,
    cast(_loaded_at as timestamp) as _loaded_at
from {{ source('pharmacy_bronze', 'orders') }}

{{ incremental_watermark_filter('_loaded_at') }}
