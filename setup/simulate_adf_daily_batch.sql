-- Simulates one daily ingestion batch orchestrated by ADF.
--
-- In a real solution ADF would obtain these rows from source systems and land/upsert
-- them into Bronze. This script only simulates the result of that ingestion.
--
-- Changes:
--   orders:
--     * order 1004: pending -> paid
--     * order 1007: new order
--   order_items:
--     * order_item 4005: quantity 1 -> 2 (correction)
--     * order_item 4009: new line for order 1007
--   payments:
--     * payment 5006: new payment for order 1004
--     * payment 5007: new payment for order 1007
--
-- Every ingested row receives a fresh _loaded_at watermark.

USE SCHEMA bronze;

-- --------------------------------------------------------------------------
-- ORDERS BATCH
-- --------------------------------------------------------------------------
CREATE OR REPLACE TEMP VIEW batch_orders AS
SELECT
    1004 AS order_id,
    3 AS customer_id,
    'PAID' AS order_status,
    cast('2026-09-21 16:40:00' as timestamp) AS ordered_at,
    current_timestamp() AS updated_at,
    current_timestamp() AS _loaded_at
UNION ALL
SELECT
    1007,
    2,
    'PAID',
    current_timestamp(),
    current_timestamp(),
    current_timestamp();

MERGE INTO bronze.orders AS target
USING batch_orders AS source
ON target.order_id = source.order_id
WHEN MATCHED THEN UPDATE SET
    target.customer_id = source.customer_id,
    target.order_status = source.order_status,
    target.ordered_at = source.ordered_at,
    target.updated_at = source.updated_at,
    target._loaded_at = source._loaded_at
WHEN NOT MATCHED THEN INSERT (
    order_id,
    customer_id,
    order_status,
    ordered_at,
    updated_at,
    _loaded_at
) VALUES (
    source.order_id,
    source.customer_id,
    source.order_status,
    source.ordered_at,
    source.updated_at,
    source._loaded_at
);

-- --------------------------------------------------------------------------
-- ORDER ITEMS BATCH
-- --------------------------------------------------------------------------
CREATE OR REPLACE TEMP VIEW batch_order_items AS
SELECT
    4005 AS order_item_id,
    1004 AS order_id,
    2001 AS product_id,
    2 AS quantity,
    cast(10.00 as decimal(12, 2)) AS unit_price,
    current_timestamp() AS updated_at,
    current_timestamp() AS _loaded_at
UNION ALL
SELECT
    4009,
    1007,
    2002,
    1,
    cast(25.50 as decimal(12, 2)),
    current_timestamp(),
    current_timestamp();

MERGE INTO bronze.order_items AS target
USING batch_order_items AS source
ON target.order_item_id = source.order_item_id
WHEN MATCHED THEN UPDATE SET
    target.order_id = source.order_id,
    target.product_id = source.product_id,
    target.quantity = source.quantity,
    target.unit_price = source.unit_price,
    target.updated_at = source.updated_at,
    target._loaded_at = source._loaded_at
WHEN NOT MATCHED THEN INSERT (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    updated_at,
    _loaded_at
) VALUES (
    source.order_item_id,
    source.order_id,
    source.product_id,
    source.quantity,
    source.unit_price,
    source.updated_at,
    source._loaded_at
);

-- --------------------------------------------------------------------------
-- PAYMENTS BATCH
-- --------------------------------------------------------------------------
CREATE OR REPLACE TEMP VIEW batch_payments AS
SELECT
    5006 AS payment_id,
    1004 AS order_id,
    'CARD' AS payment_method,
    'PAID' AS payment_status,
    cast(20.00 as decimal(12, 2)) AS amount,
    current_timestamp() AS paid_at,
    current_timestamp() AS updated_at,
    current_timestamp() AS _loaded_at
UNION ALL
SELECT
    5007,
    1007,
    'PAYPAL',
    'PAID',
    cast(25.50 as decimal(12, 2)),
    current_timestamp(),
    current_timestamp(),
    current_timestamp();

MERGE INTO bronze.payments AS target
USING batch_payments AS source
ON target.payment_id = source.payment_id
WHEN MATCHED THEN UPDATE SET
    target.order_id = source.order_id,
    target.payment_method = source.payment_method,
    target.payment_status = source.payment_status,
    target.amount = source.amount,
    target.paid_at = source.paid_at,
    target.updated_at = source.updated_at,
    target._loaded_at = source._loaded_at
WHEN NOT MATCHED THEN INSERT (
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    paid_at,
    updated_at,
    _loaded_at
) VALUES (
    source.payment_id,
    source.order_id,
    source.payment_method,
    source.payment_status,
    source.amount,
    source.paid_at,
    source.updated_at,
    source._loaded_at
);

-- Verify Bronze after ingestion.
SELECT order_id, customer_id, order_status, ordered_at, updated_at, _loaded_at
FROM bronze.orders
WHERE order_id IN (1004, 1007)
ORDER BY order_id;

SELECT order_item_id, order_id, product_id, quantity, unit_price, updated_at, _loaded_at
FROM bronze.order_items
WHERE order_item_id IN (4005, 4009)
ORDER BY order_item_id;

SELECT payment_id, order_id, payment_method, payment_status, amount, paid_at, updated_at, _loaded_at
FROM bronze.payments
WHERE payment_id IN (5006, 5007)
ORDER BY payment_id;
