with orders as (

    select *
    from {{ ref('stg_orders') }}

),

items as (

    select *
    from {{ ref('int_order_items_aggregated') }}

),

payments as (

    select *
    from {{ ref('int_payments_aggregated') }}

)

select
    o.order_id,
    o.customer_id,
    o.order_status,
    o.ordered_at,

    coalesce(i.item_quantity, 0) as item_quantity,

    coalesce(
        i.order_amount,
        cast(0 as decimal(12, 2))
    ) as order_amount,

    coalesce(
        p.paid_amount,
        cast(0 as decimal(12, 2))
    ) as paid_amount,

    o.is_deleted,

    greatest(
        o.updated_at,
        o._loaded_at,
        coalesce(i.items_updated_at, o._loaded_at),
        coalesce(p.payments_updated_at, o._loaded_at)
    ) as record_updated_at

from orders o

left join items i
    on o.order_id = i.order_id

left join payments p
    on o.order_id = p.order_id