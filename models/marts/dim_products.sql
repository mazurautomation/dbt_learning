select
    product_id,
    product_name,
    category,
    unit_price,
    is_active,
    updated_at
from {{ ref('stg_products') }}
