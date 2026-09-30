-- Run this only AFTER the first successful dbt build / dbt snapshot.
-- It simulates a new source-system batch:
--   * customer 1 changes e-mail -> snapshot should create history
--   * order 1004 moves from pending to paid
--   * new order 1007 arrives
-- The MERGEs make the inserts idempotent if you accidentally rerun this script.

USE SCHEMA bronze;

UPDATE customers
SET
    email = 'anna.nowak+new@example.com',
    updated_at = current_timestamp(),
    _loaded_at = current_timestamp()
WHERE customer_id = 1;

UPDATE orders
SET
    order_status = 'PAID',
    updated_at = current_timestamp(),
    _loaded_at = current_timestamp()
WHERE order_id = 1004;

MERGE INTO payments AS target
USING (
    SELECT
        5006 AS payment_id,
        1004 AS order_id,
        'CARD' AS payment_method,
        'PAID' AS payment_status,
        cast(10.00 as decimal(12,2)) AS amount,
        current_timestamp() AS paid_at,
        current_timestamp() AS updated_at,
        current_timestamp() AS _loaded_at
) AS source
ON target.payment_id = source.payment_id
WHEN NOT MATCHED THEN INSERT *;

MERGE INTO orders AS target
USING (
    SELECT
        1007 AS order_id,
        2 AS customer_id,
        'PAID' AS order_status,
        current_timestamp() AS ordered_at,
        current_timestamp() AS updated_at,
        current_timestamp() AS _loaded_at
) AS source
ON target.order_id = source.order_id
WHEN NOT MATCHED THEN INSERT *;

MERGE INTO order_items AS target
USING (
    SELECT
        4009 AS order_item_id,
        1007 AS order_id,
        2002 AS product_id,
        1 AS quantity,
        cast(25.50 as decimal(12,2)) AS unit_price,
        current_timestamp() AS updated_at,
        current_timestamp() AS _loaded_at
) AS source
ON target.order_item_id = source.order_item_id
WHEN NOT MATCHED THEN INSERT *;

MERGE INTO payments AS target
USING (
    SELECT
        5007 AS payment_id,
        1007 AS order_id,
        'PAYPAL' AS payment_method,
        'PAID' AS payment_status,
        cast(25.50 as decimal(12,2)) AS amount,
        current_timestamp() AS paid_at,
        current_timestamp() AS updated_at,
        current_timestamp() AS _loaded_at
) AS source
ON target.payment_id = source.payment_id
WHEN NOT MATCHED THEN INSERT *;
