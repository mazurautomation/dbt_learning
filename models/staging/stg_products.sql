select
    cast(product_id as bigint) as product_id,
    trim(product_name) as product_name,
    trim(category) as category,
    cast(unit_price as decimal(12, 2)) as unit_price,
    cast(is_active as boolean) as is_active,
    cast(updated_at as timestamp) as updated_at,
    cast(_loaded_at as timestamp) as _loaded_at
from {{ source('pharmacy_bronze', 'products') }}
