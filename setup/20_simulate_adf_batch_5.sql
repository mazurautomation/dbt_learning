INSERT INTO bronze.orders_cdc (
    order_id,
    customer_id,
    order_status,
    ordered_at,
    updated_at,
    _loaded_at,
    _cdc_operation,
    _cdc_sequence,
    _ingest_batch_id
)

SELECT
    1010,
    c.customer_id,
    'PAID',
    current_timestamp(),
    current_timestamp(),
    current_timestamp(),
    'I',
    CAST(1 AS BIGINT),
    CAST(5 AS BIGINT)

FROM (
    SELECT MIN(customer_id) AS customer_id
    FROM bronze.customers
) c

WHERE NOT EXISTS (
    SELECT 1
    FROM bronze.orders_cdc
    WHERE order_id = 1010
      AND _cdc_sequence = 1
);

INSERT INTO bronze.order_items_cdc (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    updated_at,
    _loaded_at,
    _cdc_operation,
    _cdc_sequence,
    _ingest_batch_id
)

SELECT
    4012,
    1010,
    p.product_id,
    2,
    p.unit_price,
    current_timestamp(),
    current_timestamp(),
    'I',
    CAST(1 AS BIGINT),
    CAST(5 AS BIGINT)

FROM (
    SELECT
        product_id,
        unit_price
    FROM bronze.products
    ORDER BY product_id
    LIMIT 1
) p

WHERE NOT EXISTS (
    SELECT 1
    FROM bronze.order_items_cdc
    WHERE order_item_id = 4012
      AND _cdc_sequence = 1
);

INSERT INTO bronze.payments_cdc (
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    paid_at,
    updated_at,
    _loaded_at,
    _cdc_operation,
    _cdc_sequence,
    _ingest_batch_id
)

SELECT
    5010,
    1010,
    'CARD',
    'PAID',
    CAST(p.unit_price * 2 AS DECIMAL(12,2)),
    current_timestamp(),
    current_timestamp(),
    current_timestamp(),
    'I',
    CAST(1 AS BIGINT),
    CAST(5 AS BIGINT)

FROM (
    SELECT
        product_id,
        unit_price
    FROM bronze.products
    ORDER BY product_id
    LIMIT 1
) p

WHERE NOT EXISTS (
    SELECT 1
    FROM bronze.payments_cdc
    WHERE payment_id = 5010
      AND _cdc_sequence = 1
);

