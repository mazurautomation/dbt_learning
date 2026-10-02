-- ---------------------------------------------------------
-- ORDER 1004
-- valid newer update
-- ---------------------------------------------------------

INSERT INTO bronze.orders_cdc
SELECT
    1004,
    3,
    'SHIPPED',
    cast('2026-09-21 16:40:00' as timestamp),
    current_timestamp(),
    current_timestamp(),
    'U',
    cast(2 as bigint);


-- ---------------------------------------------------------
-- ORDER 1004
-- stale event arriving AFTER sequence 2
-- it must NOT overwrite sequence 2
-- ---------------------------------------------------------

INSERT INTO bronze.orders_cdc
SELECT
    1004,
    3,
    'CANCELLED',
    cast('2026-09-21 16:40:00' as timestamp),
    current_timestamp(),
    current_timestamp(),
    'U',
    cast(1 as bigint);


-- ---------------------------------------------------------
-- ORDER 1002 DELETE
-- ---------------------------------------------------------

INSERT INTO bronze.orders_cdc
SELECT
    1002,
    cast(null as bigint),
    cast(null as string),
    cast(null as timestamp),
    cast(null as timestamp),
    current_timestamp(),
    'D',
    cast(2 as bigint);


-- Delete its item

INSERT INTO bronze.order_items_cdc
SELECT
    4003,
    cast(null as bigint),
    cast(null as bigint),
    cast(null as int),
    cast(null as decimal(12, 2)),
    cast(null as timestamp),
    current_timestamp(),
    'D',
    cast(2 as bigint);


-- Delete its payment

INSERT INTO bronze.payments_cdc
SELECT
    5002,
    cast(null as bigint),
    cast(null as string),
    cast(null as string),
    cast(null as decimal(12, 2)),
    cast(null as timestamp),
    cast(null as timestamp),
    current_timestamp(),
    'D',
    cast(2 as bigint);


-- ---------------------------------------------------------
-- NEW ORDER 1008
-- ---------------------------------------------------------

INSERT INTO bronze.orders_cdc
SELECT
    1008,
    5,
    'PAID',
    current_timestamp(),
    current_timestamp(),
    current_timestamp(),
    'I',
    cast(1 as bigint);


INSERT INTO bronze.order_items_cdc
SELECT
    4010,
    1008,
    2005,
    1,
    cast(32.00 as decimal(12, 2)),
    current_timestamp(),
    current_timestamp(),
    'I',
    cast(1 as bigint);


INSERT INTO bronze.payments_cdc
SELECT
    5008,
    1008,
    'CARD',
    'PAID',
    cast(32.00 as decimal(12, 2)),
    current_timestamp(),
    current_timestamp(),
    current_timestamp(),
    'I',
    cast(1 as bigint);