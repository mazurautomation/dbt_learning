select *
from {{ ref('fct_orders') }}
where order_status in ('paid', 'shipped')
  and abs(paid_amount - order_amount) > 0.01
