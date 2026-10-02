{{
    config(
        materialized='incremental',
        unique_key='payment_id',
        incremental_strategy='cdc_soft_delete',
        on_schema_change='fail'
    )
}}

with source_changes as (

    select
        cast(payment_id as bigint) as payment_id,
        cast(order_id as bigint) as order_id,
        {{ normalize_status('payment_method') }} as payment_method,
        {{ normalize_status('payment_status') }} as payment_status,
        cast(amount as decimal(12, 2)) as amount,
        cast(paid_at as timestamp) as paid_at,
        cast(updated_at as timestamp) as updated_at,
        cast(_loaded_at as timestamp) as _loaded_at,
        upper(trim(_cdc_operation)) as _cdc_operation,
        cast(_cdc_sequence as bigint) as _cdc_sequence

    from {{ source('pharmacy_bronze', 'payments_cdc') }}

    {{ incremental_watermark_filter('_loaded_at') }}

),

ranked_changes as (

    select
        *,
        row_number() over (
            partition by payment_id
            order by
                _cdc_sequence desc,
                _loaded_at desc
        ) as _cdc_rank

    from source_changes

)

select
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    paid_at,
    updated_at,
    _loaded_at,
    _cdc_operation,
    _cdc_sequence,
    case
        when _cdc_operation = 'D' then true
        else false
    end as is_deleted

from ranked_changes

where _cdc_rank = 1

{% if not is_incremental() %}
  and _cdc_operation <> 'D'
{% endif %}