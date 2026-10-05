select
    order_id,

    sum(
        case
            when not is_deleted then quantity
            else 0
        end
    ) as item_quantity,

    cast(
        sum(
            case
                when not is_deleted
                    then quantity * unit_price
                else 0
            end
        )
        as decimal(12, 2)
    ) as order_amount,

    max(_loaded_at) as items_updated_at,

    max(_ingest_batch_id) as items_batch_id

from {{ ref('stg_order_items') }}

group by order_id