/*
Lab 01 — Serverless SQL Basics Attempt
Repository: azure-synapse-learning-lab

Goal:
Practice basic Synapse Serverless SQL operations using the existing portfolio environment.

Instructions:
1. Open Synapse Studio.
2. Create a SQL script.
3. Connect to the Built-in SQL pool.
4. Complete each TODO.
5. Run each section independently.
6. The final validation should return PASS.

Safety:
This script should be read-only. Do not drop or alter project objects.
*/

/* ============================================================
   Task 1 — Confirm Serverless SQL is ready
   ============================================================ */

-- TODO:
-- Return a message and current timestamp.
-- Hint: use SELECT and CURRENT_TIMESTAMP.

SELECT
    'TODO: replace this with your validation message' AS validation_message,
    CURRENT_TIMESTAMP AS checked_at;


/* ============================================================
   Task 2 — Select and confirm database context
   ============================================================ */

-- TODO:
-- Switch to the project database.
-- Expected database: synapse_serving_demo

-- USE [synapse_serving_demo];

-- TODO:
-- Confirm the current database.
-- Hint: DB_NAME()

SELECT
    DB_NAME() AS current_database;


/* ============================================================
   Task 3 — Inspect database schemas
   ============================================================ */

-- TODO:
-- List schemas in the current database.
-- Expected important schemas: ext, rpt, audit.

SELECT
    name AS schema_name
FROM sys.schemas
ORDER BY name;


/* ============================================================
   Task 4 — Inspect external data sources
   ============================================================ */

-- TODO:
-- List external data sources.
-- Expected: ds_adls_synapse_serving

SELECT
    name AS external_data_source_name,
    location
FROM sys.external_data_sources
ORDER BY name;


/* ============================================================
   Task 5 — Inspect external file formats
   ============================================================ */

-- TODO:
-- List external file formats.
-- Expected: ff_parquet

SELECT
    name AS external_file_format_name,
    format_type
FROM sys.external_file_formats
ORDER BY name;


/* ============================================================
   Task 6 — Inspect external tables
   ============================================================ */

-- TODO:
-- List external tables and their schemas.
-- Expected: ext.customers, ext.products, ext.orders, ext.order_items.

SELECT
    s.name AS schema_name,
    et.name AS external_table_name,
    ds.name AS external_data_source_name,
    ff.name AS external_file_format_name,
    et.location
FROM sys.external_tables AS et
INNER JOIN sys.schemas AS s
    ON et.schema_id = s.schema_id
INNER JOIN sys.external_data_sources AS ds
    ON et.data_source_id = ds.data_source_id
INNER JOIN sys.external_file_formats AS ff
    ON et.file_format_id = ff.file_format_id
ORDER BY
    s.name,
    et.name;


/* ============================================================
   Task 7 — Validate external table row counts
   ============================================================ */

-- TODO:
-- Validate row counts for external tables.
-- Expected:
-- customers    = 10
-- products     = 10
-- orders       = 24
-- order_items  = 43

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM ext.customers
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM ext.products
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM ext.orders
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM ext.order_items;


/* ============================================================
   Task 8 — Preview a reporting view
   ============================================================ */

-- TODO:
-- Preview the sales-by-date reporting view.
-- Keep the query small and cost-aware.

SELECT TOP (10)
    order_date,
    order_count,
    total_quantity,
    total_revenue
FROM rpt.vw_sales_by_date
ORDER BY order_date;


/* ============================================================
   Task 9 — Final validation
   ============================================================ */

-- TODO:
-- Complete the final validation.
-- Expected status: PASS

WITH counts AS (
    SELECT
        (SELECT COUNT(*) FROM ext.customers) AS customers_count,
        (SELECT COUNT(*) FROM ext.products) AS products_count,
        (SELECT COUNT(*) FROM ext.orders) AS orders_count,
        (SELECT COUNT(*) FROM ext.order_items) AS order_items_count
)
SELECT
    customers_count,
    products_count,
    orders_count,
    order_items_count,
    CASE
        WHEN customers_count = 10
         AND products_count = 10
         AND orders_count = 24
         AND order_items_count = 43
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status,
    CURRENT_TIMESTAMP AS checked_at
FROM counts;


/* ============================================================
   Reflection Prompts
   ============================================================

Answer in your notes:

1. What is the role of the Built-in SQL pool?
2. Why does this lab avoid Dedicated SQL Pools?
3. What is the difference between an external table and a regular SQL table?
4. Why is Parquet a good format for Serverless SQL queries?
5. Why should you confirm the current database before running scripts?
*/
