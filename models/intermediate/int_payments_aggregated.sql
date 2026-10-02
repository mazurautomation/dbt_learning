select
    order_id,

    cast(
        sum(
            case
                when not is_deleted
                 and payment_status = 'paid'
                    then amount
                else 0
            end
        )
        as decimal(12, 2)
    ) as paid_amount,

    max(_loaded_at) as payments_updated_at

from {{ ref('stg_payments') }}

group by order_id