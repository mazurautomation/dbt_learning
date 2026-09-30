-- This script simulates what ADF ingestion would normally do.
-- In production, dbt should NOT own the Bronze ingestion layer.

SELECT current_catalog();

CREATE SCHEMA IF NOT EXISTS bronze;
USE SCHEMA bronze;

CREATE OR REPLACE TABLE customers USING DELTA AS
SELECT 1 AS customer_id, ' Anna.Nowak@example.com ' AS email, 'pl' AS country_code,
       cast('2026-09-01 10:00:00' as timestamp) AS signup_at,
       cast('2026-09-20 09:00:00' as timestamp) AS updated_at,
       current_timestamp() AS _loaded_at
UNION ALL
SELECT 2, 'jan.kowalski@example.com', 'DE',
       cast('2026-09-02 12:00:00' as timestamp),
       cast('2026-09-21 08:00:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 3, 'eva.novak@example.com', 'CZ',
       cast('2026-09-03 14:30:00' as timestamp),
       cast('2026-09-21 09:30:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 4, 'peter.jansen@example.com', 'NL',
       cast('2026-09-05 07:45:00' as timestamp),
       cast('2026-09-22 10:00:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 5, 'maria.schmidt@example.com', 'DE',
       cast('2026-09-07 16:10:00' as timestamp),
       cast('2026-09-22 11:00:00' as timestamp),
       current_timestamp();

CREATE OR REPLACE TABLE products USING DELTA AS
SELECT 2001 AS product_id, 'Pain Relief 500mg' AS product_name, 'OTC' AS category,
       cast(10.00 as decimal(12,2)) AS unit_price, true AS is_active,
       cast('2026-09-20 08:00:00' as timestamp) AS updated_at,
       current_timestamp() AS _loaded_at
UNION ALL
SELECT 2002, 'Vitamin D 2000 IU', 'Supplements', cast(25.50 as decimal(12,2)), true,
       cast('2026-09-20 08:00:00' as timestamp), current_timestamp()
UNION ALL
SELECT 2003, 'Digital Thermometer', 'Devices', cast(49.90 as decimal(12,2)), true,
       cast('2026-09-20 08:00:00' as timestamp), current_timestamp()
UNION ALL
SELECT 2004, 'Nasal Spray', 'OTC', cast(18.00 as decimal(12,2)), true,
       cast('2026-09-20 08:00:00' as timestamp), current_timestamp()
UNION ALL
SELECT 2005, 'Magnesium', 'Supplements', cast(32.00 as decimal(12,2)), true,
       cast('2026-09-20 08:00:00' as timestamp), current_timestamp();

CREATE OR REPLACE TABLE orders USING DELTA AS
SELECT 1001 AS order_id, 1 AS customer_id, 'SHIPPED' AS order_status,
       cast('2026-09-18 10:15:00' as timestamp) AS ordered_at,
       cast('2026-09-19 08:00:00' as timestamp) AS updated_at,
       current_timestamp() AS _loaded_at
UNION ALL
SELECT 1002, 1, 'Cancelled',
       cast('2026-09-19 12:20:00' as timestamp),
       cast('2026-09-19 13:00:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 1003, 2, 'PAID',
       cast('2026-09-20 09:10:00' as timestamp),
       cast('2026-09-20 09:30:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 1004, 3, 'Pending',
       cast('2026-09-21 16:40:00' as timestamp),
       cast('2026-09-21 16:40:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 1005, 4, 'shipped',
       cast('2026-09-22 11:05:00' as timestamp),
       cast('2026-09-23 07:00:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 1006, 5, 'Paid',
       cast('2026-09-23 18:30:00' as timestamp),
       cast('2026-09-23 18:35:00' as timestamp),
       current_timestamp();

CREATE OR REPLACE TABLE order_items USING DELTA AS
SELECT 4001 AS order_item_id, 1001 AS order_id, 2002 AS product_id, 2 AS quantity,
       cast(25.50 as decimal(12,2)) AS unit_price,
       cast('2026-09-18 10:15:00' as timestamp) AS updated_at,
       current_timestamp() AS _loaded_at
UNION ALL
SELECT 4002, 1001, 2004, 1, cast(18.00 as decimal(12,2)),
       cast('2026-09-18 10:15:00' as timestamp), current_timestamp()
UNION ALL
SELECT 4003, 1002, 2003, 1, cast(49.90 as decimal(12,2)),
       cast('2026-09-19 12:20:00' as timestamp), current_timestamp()
UNION ALL
SELECT 4004, 1003, 2005, 2, cast(32.00 as decimal(12,2)),
       cast('2026-09-20 09:10:00' as timestamp), current_timestamp()
UNION ALL
SELECT 4005, 1004, 2001, 1, cast(10.00 as decimal(12,2)),
       cast('2026-09-21 16:40:00' as timestamp), current_timestamp()
UNION ALL
SELECT 4006, 1005, 2003, 1, cast(49.90 as decimal(12,2)),
       cast('2026-09-22 11:05:00' as timestamp), current_timestamp()
UNION ALL
SELECT 4007, 1005, 2002, 1, cast(25.50 as decimal(12,2)),
       cast('2026-09-22 11:05:00' as timestamp), current_timestamp()
UNION ALL
SELECT 4008, 1006, 2004, 2, cast(18.00 as decimal(12,2)),
       cast('2026-09-23 18:30:00' as timestamp), current_timestamp();

CREATE OR REPLACE TABLE payments USING DELTA AS
SELECT 5001 AS payment_id, 1001 AS order_id, 'CARD' AS payment_method, 'PAID' AS payment_status,
       cast(69.00 as decimal(12,2)) AS amount,
       cast('2026-09-18 10:16:00' as timestamp) AS paid_at,
       cast('2026-09-18 10:16:00' as timestamp) AS updated_at,
       current_timestamp() AS _loaded_at
UNION ALL
SELECT 5002, 1002, 'CARD', 'FAILED', cast(49.90 as decimal(12,2)),
       cast(null as timestamp),
       cast('2026-09-19 12:22:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 5003, 1003, 'PAYPAL', 'PAID', cast(64.00 as decimal(12,2)),
       cast('2026-09-20 09:12:00' as timestamp),
       cast('2026-09-20 09:12:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 5004, 1005, 'CARD', 'PAID', cast(75.40 as decimal(12,2)),
       cast('2026-09-22 11:07:00' as timestamp),
       cast('2026-09-22 11:07:00' as timestamp),
       current_timestamp()
UNION ALL
SELECT 5005, 1006, 'CARD', 'PAID', cast(36.00 as decimal(12,2)),
       cast('2026-09-23 18:32:00' as timestamp),
       cast('2026-09-23 18:32:00' as timestamp),
       current_timestamp();

SELECT 'customers' AS table_name, count(*) AS row_count FROM customers
UNION ALL
SELECT 'products', count(*) FROM products
UNION ALL
SELECT 'orders', count(*) FROM orders
UNION ALL
SELECT 'order_items', count(*) FROM order_items
UNION ALL
SELECT 'payments', count(*) FROM payments;
