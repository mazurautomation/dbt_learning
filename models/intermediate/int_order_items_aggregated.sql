select
    order_id,
    sum(quantity) as item_quantity,
    cast(sum(quantity * unit_price) as decimal(12, 2)) as order_amount,
    max(updated_at) as items_updated_at
from {{ ref('stg_order_items') }}
group by order_id
