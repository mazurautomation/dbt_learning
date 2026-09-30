select
    customer_id,
    email,
    country_code,
    signup_at,
    updated_at
from {{ ref('stg_customers') }}
