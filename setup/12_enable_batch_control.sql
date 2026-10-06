-- Run once when migrating the existing CDC lab to batch-controlled CDC.

ALTER TABLE bronze.orders_cdc
ADD COLUMNS (_ingest_batch_id BIGINT);

ALTER TABLE bronze.order_items_cdc
ADD COLUMNS (_ingest_batch_id BIGINT);

ALTER TABLE bronze.payments_cdc
ADD COLUMNS (_ingest_batch_id BIGINT);


-- Everything processed during points 10/11 becomes bootstrap batch #1.

UPDATE bronze.orders_cdc
SET _ingest_batch_id = 1
WHERE _ingest_batch_id IS NULL;

UPDATE bronze.order_items_cdc
SET _ingest_batch_id = 1
WHERE _ingest_batch_id IS NULL;

UPDATE bronze.payments_cdc
SET _ingest_batch_id = 1
WHERE _ingest_batch_id IS NULL;


CREATE SCHEMA IF NOT EXISTS ops;


CREATE TABLE IF NOT EXISTS ops.cdc_batch_control
(
    pipeline_name STRING,
    last_successful_batch_id BIGINT,
    updated_at TIMESTAMP,
    run_id STRING
)
USING DELTA;


MERGE INTO ops.cdc_batch_control AS target

USING (
    SELECT
        'pharmacy_cdc' AS pipeline_name,
        cast(1 as bigint) AS last_successful_batch_id,
        current_timestamp() AS updated_at,
        'bootstrap' AS run_id
) AS source

ON target.pipeline_name = source.pipeline_name

WHEN NOT MATCHED THEN INSERT *;


SELECT *
FROM ops.cdc_batch_control;