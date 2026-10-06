-- ============================================================
-- BATCH 3
-- End-to-end Databricks Job test
-- ============================================================


-- ------------------------------------------------------------
-- UPDATE existing order 1008
-- Previous latest sequence = 2
-- New sequence = 3
-- ------------------------------------------------------------

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
    order_id,
    customer_id,
    'SHIPPED',
    ordered_at,
    cast('2026-10-05 14:10:00' as timestamp),
    cast('2026-10-05 14:15:00' as timestamp),
    'U',
    cast(3 as bigint),
    cast(3 as bigint)
FROM bronze.orders_cdc
WHERE order_id = 1008
ORDER BY _cdc_sequence DESC, _loaded_at DESC
LIMIT 1;


-- ------------------------------------------------------------
-- NEW ORDER 1009
-- ------------------------------------------------------------

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
VALUES (
    1009,
    2,
    'PAID',
    cast('2026-10-05 14:20:00' as timestamp),
    cast('2026-10-05 14:20:00' as timestamp),
    cast('2026-10-05 14:21:00' as timestamp),
    'I',
    1,
    3
);


-- ------------------------------------------------------------
-- ITEM for order 1009
-- ------------------------------------------------------------

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
VALUES (
    4011,
    1009,
    2005,
    2,
    cast(16.00 as decimal(12, 2)),
    cast('2026-10-05 14:20:00' as timestamp),
    cast('2026-10-05 14:21:00' as timestamp),
    'I',
    1,
    3
);


-- ------------------------------------------------------------
-- PAYMENT for order 1009
-- order amount = 2 * 16 = 32
-- payment = 32
-- ------------------------------------------------------------

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
VALUES (
    5009,
    1009,
    'CARD',
    'PAID',
    cast(32.00 as decimal(12, 2)),
    cast('2026-10-05 14:22:00' as timestamp),
    cast('2026-10-05 14:22:00' as timestamp),
    cast('2026-10-05 14:23:00' as timestamp),
    'I',
    1,
    3
);