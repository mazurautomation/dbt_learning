{{
    config(
        materialized='incremental',
        unique_key='order_item_id',
        incremental_strategy='cdc_soft_delete',
        on_schema_change='fail'
    )
}}

with source_changes as (

    select
        cast(order_item_id as bigint) as order_item_id,
        cast(order_id as bigint) as order_id,
        cast(product_id as bigint) as product_id,
        cast(quantity as int) as quantity,
        cast(unit_price as decimal(12, 2)) as unit_price,
        cast(updated_at as timestamp) as updated_at,
        cast(_loaded_at as timestamp) as _loaded_at,
        upper(trim(_cdc_operation)) as _cdc_operation,
        cast(_cdc_sequence as bigint) as _cdc_sequence

    from {{ source('pharmacy_bronze', 'order_items_cdc') }}

    {{ incremental_watermark_filter('_loaded_at') }}

),

ranked_changes as (

    select
        *,
        row_number() over (
            partition by order_item_id
            order by
                _cdc_sequence desc,
                _loaded_at desc
        ) as _cdc_rank

    from source_changes

)

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
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