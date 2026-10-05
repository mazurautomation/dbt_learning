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
        cast(_cdc_sequence as bigint) as _cdc_sequence,
        cast(_ingest_batch_id as bigint) as _ingest_batch_id

    from {{ source('pharmacy_bronze', 'orders_cdc') }}

    {{ cdc_batch_filter('_ingest_batch_id') }}

),

sequence_deduplicated as (

    select *
    from (

        select
            *,
            row_number() over (
                partition by
                    order_id,
                    _cdc_sequence
                order by
                    _ingest_batch_id desc,
                    _loaded_at desc
            ) as _sequence_duplicate_rank

        from source_changes

    )

    where _sequence_duplicate_rank = 1

),

ranked_changes as (

    select
        *,
        row_number() over (
            partition by order_id
            order by
                _cdc_sequence desc,
                _ingest_batch_id desc,
                _loaded_at desc
        ) as _cdc_rank

    from sequence_deduplicated

)

select
    order_id,
    customer_id,
    order_status,
    ordered_at,
    updated_at,
    _loaded_at,
    _cdc_operation,
    _cdc_sequence,
    _ingest_batch_id,

    case
        when _cdc_operation = 'D' then true
        else false
    end as is_deleted

from ranked_changes

where _cdc_rank = 1

{% if not is_incremental() %}
  and _cdc_operation <> 'D'
{% endif %}