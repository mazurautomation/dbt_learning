select
    order_id,
    cast(
        sum(
            case
                when payment_status = 'paid' then amount
                else 0
            end
        ) as decimal(12, 2)
    ) as paid_amount,
    max(updated_at) as payments_updated_at
from {{ ref('stg_payments') }}
group by order_id
