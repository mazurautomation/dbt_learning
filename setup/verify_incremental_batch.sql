-- Run after:
--   dbt build --select stg_orders stg_order_items stg_payments
--   dbt build --select fct_orders+
--
-- Expected:
--   * 1004 is updated, not duplicated
--   * 1007 is inserted
--   * order_item 4005 quantity = 2
--   * order_item 4009 exists
--   * payments 5006 and 5007 exist
--   * Gold fct_orders reflects the corrected amounts

SELECT
    order_id,
    customer_id,
    order_status,
    ordered_at,
    updated_at,
    _loaded_at
FROM dbt_pawel_silver.stg_orders
WHERE order_id IN (1004, 1007)
ORDER BY order_id;

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    updated_at,
    _loaded_at
FROM dbt_pawel_silver.stg_order_items
WHERE order_item_id IN (4005, 4009)
ORDER BY order_item_id;

SELECT
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    paid_at,
    updated_at,
    _loaded_at
FROM dbt_pawel_silver.stg_payments
WHERE payment_id IN (5006, 5007)
ORDER BY payment_id;

SELECT
    order_id,
    customer_id,
    order_status,
    item_quantity,
    order_amount,
    paid_amount,
    record_updated_at
FROM dbt_pawel_gold.fct_orders
WHERE order_id IN (1004, 1007)
ORDER BY order_id;

-- These should both return exactly one row per ID, proving MERGE did not append duplicates.
SELECT order_id, count(*) AS row_count
FROM dbt_pawel_silver.stg_orders
WHERE order_id IN (1004, 1007)
GROUP BY order_id
ORDER BY order_id;

SELECT order_item_id, count(*) AS row_count
FROM dbt_pawel_silver.stg_order_items
WHERE order_item_id IN (4005, 4009)
GROUP BY order_item_id
ORDER BY order_item_id;
