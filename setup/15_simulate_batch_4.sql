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
    cast('2026-10-06 11:00:00' as timestamp),
    cast('2026-10-06 11:01:00' as timestamp),
    'U',
    cast(2 as bigint),
    cast(4 as bigint)
FROM bronze.orders_cdc
WHERE order_id = 1009
  AND _cdc_sequence = 1
LIMIT 1;