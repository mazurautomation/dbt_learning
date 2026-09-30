{{
    config(
        materialized='incremental',
        unique_key='payment_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

select
    cast(payment_id as bigint) as payment_id,
    cast(order_id as bigint) as order_id,
    {{ normalize_status('payment_method') }} as payment_method,
    {{ normalize_status('payment_status') }} as payment_status,
    cast(amount as decimal(12, 2)) as amount,
    cast(paid_at as timestamp) as paid_at,
    cast(updated_at as timestamp) as updated_at,
    cast(_loaded_at as timestamp) as _loaded_at
from {{ source('pharmacy_bronze', 'payments') }}

{% if is_incremental() %}
where cast(_loaded_at as timestamp) > (
    select coalesce(
        max(_loaded_at),
        cast('1900-01-01 00:00:00' as timestamp)
    )
    from {{ this }}
)
{% endif %}
