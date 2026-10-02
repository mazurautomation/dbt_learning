CREATE OR REPLACE TABLE bronze.orders_cdc
USING DELTA
AS
SELECT
    order_id,
    customer_id,
    order_status,
    ordered_at,
    updated_at,
    _loaded_at,
    'I' AS _cdc_operation,
    cast(1 as bigint) AS _cdc_sequence
FROM bronze.orders;


CREATE OR REPLACE TABLE bronze.order_items_cdc
USING DELTA
AS
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    updated_at,
    _loaded_at,
    'I' AS _cdc_operation,
    cast(1 as bigint) AS _cdc_sequence
FROM bronze.order_items;


CREATE OR REPLACE TABLE bronze.payments_cdc
USING DELTA
AS
SELECT
    payment_id,
    order_id,
    payment_method,
    payment_status,
    amount,
    paid_at,
    updated_at,
    _loaded_at,
    'I' AS _cdc_operation,
    cast(1 as bigint) AS _cdc_sequence
FROM bronze.payments;