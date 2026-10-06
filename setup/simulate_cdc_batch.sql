-- ---------------------------------------------------------
-- ORDER 1004
-- Newer business event arrives first.
-- ---------------------------------------------------------

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
    1004,
    3,
    'SHIPPED',
    cast('2026-09-21 16:40:00' as timestamp),
    cast('2026-10-02 09:30:00' as timestamp),
    cast('2026-10-02 10:00:00' as timestamp),
    'U',
    3,
    1
);


-- ---------------------------------------------------------
-- Older business event arrives later.
-- It must NOT overwrite sequence 3.
-- ---------------------------------------------------------

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
    1004,
    3,
    'CANCELLED',
    cast('2026-09-21 16:40:00' as timestamp),
    cast('2026-10-02 09:00:00' as timestamp),
    cast('2026-10-02 10:05:00' as timestamp),
    'U',
    2,
    1
);