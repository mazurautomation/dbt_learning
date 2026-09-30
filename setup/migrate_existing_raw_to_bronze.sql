-- Use this if you already completed v1 of the tutorial and have raw_pharmacy.*.
-- It copies the existing raw tables into the new Bronze schema.

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE OR REPLACE TABLE bronze.customers USING DELTA AS
SELECT * FROM raw_pharmacy.customers;

CREATE OR REPLACE TABLE bronze.products USING DELTA AS
SELECT * FROM raw_pharmacy.products;

CREATE OR REPLACE TABLE bronze.orders USING DELTA AS
SELECT * FROM raw_pharmacy.orders;

CREATE OR REPLACE TABLE bronze.order_items USING DELTA AS
SELECT * FROM raw_pharmacy.order_items;

CREATE OR REPLACE TABLE bronze.payments USING DELTA AS
SELECT * FROM raw_pharmacy.payments;

SELECT 'customers' AS table_name, count(*) AS row_count FROM bronze.customers
UNION ALL
SELECT 'products', count(*) FROM bronze.products
UNION ALL
SELECT 'orders', count(*) FROM bronze.orders
UNION ALL
SELECT 'order_items', count(*) FROM bronze.order_items
UNION ALL
SELECT 'payments', count(*) FROM bronze.payments;
