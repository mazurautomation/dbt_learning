select
    cast(ordered_at as date) as sales_date,
    sum(
        case
            when order_status in ('paid', 'shipped') then 1
            else 0
        end
    ) as successful_orders,
    cast(
        sum(
            case
                when order_status in ('paid', 'shipped') then order_amount
                else 0
            end
        ) as decimal(14, 2)
    ) as gross_revenue,
    cast(
        sum(
            case
                when order_status in ('paid', 'shipped') then paid_amount
                else 0
            end
        ) as decimal(14, 2)
    ) as paid_revenue
from {{ ref('fct_orders') }}
group by cast(ordered_at as date)
