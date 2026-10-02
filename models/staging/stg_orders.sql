{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='cdc_soft_delete',
        on_schema_change='fail'
    )
}}

with source_changes as (

    select
        cast(order_id as bigint) as order_id,
        cast(customer_id as bigint) as customer_id,
        {{ normalize_status('order_status') }} as order_status,
        cast(ordered_at as timestamp) as ordered_at,
        cast(updated_at as timestamp) as updated_at,
        cast(_loaded_at as timestamp) as _loaded_at,
        upper(trim(_cdc_operation)) as _cdc_operation,
        cast(_cdc_sequence as bigint) as _cdc_sequence

    from {{ source('pharmacy_bronze', 'orders_cdc') }}

    {{ incremental_watermark_filter('_loaded_at') }}

),

ranked_changes as (

    select
        *,
        row_number() over (
            partition by order_id
            order by
                _cdc_sequence desc,
                _loaded_at desc
        ) as _cdc_rank

    from source_changes

),

latest_changes as (

    select
        order_id,
        customer_id,
        order_status,
        ordered_at,
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

)

select *
from latest_changes

{% if not is_incremental() %}
where _cdc_operation <> 'D'
{% endif %}