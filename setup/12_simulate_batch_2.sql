-- ============================================================
-- BATCH 2
-- ============================================================
--
-- Existing state for order 1004:
--
-- seq=1  initial
-- seq=2  CANCELLED
-- seq=3  SHIPPED
--
-- Therefore batch 2 MUST continue with seq=4 and seq=5.
-- ============================================================


-- ============================================================
-- ORDER 1004
-- Multiple events for the SAME business key in one batch.
--
-- seq=4 arrives first
-- seq=5 is newer and must win
-- seq=5 is then replayed exactly
-- ============================================================

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
VALUES
(
    1004,
    3,
    'PAID',
    cast('2026-09-21 16:40:00' as timestamp),
    cast('2026-10-05 09:00:00' as timestamp),
    cast('2026-10-05 10:00:00' as timestamp),
    'U',
    4,
    2
);


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
VALUES
(
    1004,
    3,
    'SHIPPED',
    cast('2026-09-21 16:40:00' as timestamp),
    cast('2026-10-05 09:05:00' as timestamp),
    cast('2026-10-05 10:05:00' as timestamp),
    'U',
    5,
    2
);


-- Exact business-event replay.
--
-- _loaded_at differs intentionally because delivery metadata may differ.
-- Business payload remains identical to the previous seq=5 event.

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
VALUES
(
    1004,
    3,
    'SHIPPED',
    cast('2026-09-21 16:40:00' as timestamp),
    cast('2026-10-05 09:05:00' as timestamp),
    cast('2026-10-05 10:06:00' as timestamp),
    'U',
    5,
    2
);


-- ============================================================
-- ORDER 1008
-- Late arriving event.
--
-- _loaded_at is deliberately several days old.
-- Old timestamp-lookback processing could miss it.
-- Batch-based processing must still pick it up because batch_id=2.
-- ============================================================

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
    cast('2026-10-05 09:10:00' as timestamp),
    cast('2026-10-01 08:00:00' as timestamp),
    'U',
    cast(2 as bigint),
    cast(2 as bigint)
FROM bronze.orders_cdc
WHERE order_id = 1008
  AND _cdc_sequence = 1
LIMIT 1;


-- ============================================================
-- ORDER ITEM
-- Replay an existing event in a newer ingestion batch.
--
-- Business payload and CDC sequence remain unchanged.
-- Only delivery metadata changes.
-- ============================================================

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
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    updated_at,
    cast('2026-10-05 10:20:00' as timestamp),
    _cdc_operation,
    _cdc_sequence,
    cast(2 as bigint)
FROM bronze.order_items_cdc
WHERE order_item_id = 4010
  AND _cdc_sequence = 1
ORDER BY _loaded_at
LIMIT 1;


-- ============================================================
-- PAYMENT
-- Same replay test for payment CDC.
-- ============================================================

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
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    paid_at,
    updated_at,
    cast('2026-10-05 10:25:00' as timestamp),
    _cdc_operation,
    _cdc_sequence,
    cast(2 as bigint)
FROM bronze.payments_cdc
WHERE payment_id = 5008
  AND _cdc_sequence = 1
ORDER BY _loaded_at
LIMIT 1;