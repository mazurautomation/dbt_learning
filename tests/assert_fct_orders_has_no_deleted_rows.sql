select *
from {{ ref('fct_orders') }}
where is_deleted = true