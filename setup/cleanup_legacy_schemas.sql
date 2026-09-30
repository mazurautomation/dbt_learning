-- DESTRUCTIVE CLEANUP FOR THE OLD TUTORIAL VERSION.
--
-- Run this only after you have:
--   1. migrated raw_pharmacy.* -> bronze.*
--   2. successfully run `dbt build`
--   3. verified dbt_pawel_silver and dbt_pawel_gold
--
-- We intentionally DO NOT drop `dbt_pawel`.
-- It remains the DEV target.schema used as the prefix for developer schemas.

SELECT current_catalog();

-- Pre-flight checks.
SELECT 'bronze.customers' AS object_name, count(*) AS row_count FROM bronze.customers
UNION ALL
SELECT 'bronze.products', count(*) FROM bronze.products
UNION ALL
SELECT 'bronze.orders', count(*) FROM bronze.orders
UNION ALL
SELECT 'bronze.order_items', count(*) FROM bronze.order_items
UNION ALL
SELECT 'bronze.payments', count(*) FROM bronze.payments;

SHOW TABLES IN dbt_pawel_silver;
SHOW TABLES IN dbt_pawel_gold;

-- Old project schemas.
DROP SCHEMA IF EXISTS raw_pharmacy CASCADE;
DROP SCHEMA IF EXISTS dbt_pawel_staging CASCADE;
DROP SCHEMA IF EXISTS dbt_pawel_marts CASCADE;
DROP SCHEMA IF EXISTS dbt_pawel_snapshots CASCADE;
