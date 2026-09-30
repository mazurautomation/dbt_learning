select
    cast(customer_id as bigint) as customer_id,
    lower(trim(email)) as email,
    upper(trim(country_code)) as country_code,
    cast(signup_at as timestamp) as signup_at,
    cast(updated_at as timestamp) as updated_at,
    cast(_loaded_at as timestamp) as _loaded_at
from {{ source('pharmacy_bronze', 'customers') }}
