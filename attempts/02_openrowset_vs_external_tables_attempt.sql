/*
===============================================================================
Lab 02 — OPENROWSET vs External Tables
Repo: azure-synapse-learning-lab
Engine: Synapse Serverless SQL — Built-in
Database: synapse_serving_demo

Purpose:
  Compare direct Parquet reads through OPENROWSET with reusable external tables.

Important:
  This script is read-only. It does not create, alter, or drop objects.
===============================================================================
*/

USE synapse_serving_demo;
GO

/*
===============================================================================
01. Confirm execution context
===============================================================================
*/

SELECT
    DB_NAME() AS current_database,
    'Built-in Serverless SQL expected' AS expected_sql_pool,
    CURRENT_TIMESTAMP AS checked_at;
GO

/*
===============================================================================
02. Direct lake read — customers through OPENROWSET

Goal:
  Read the customers Parquet files directly from ADLS using the existing external
  data source.

Practice:
  Notice that this query does not reference ext.customers.
  It reads files directly from curated/retail/customers/.
===============================================================================
*/

SELECT TOP (5)
    customer_id,
    customer_name,
    city,
    state_code,
    customer_segment
FROM OPENROWSET(
    BULK 'curated/retail/customers/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
) AS customers_file;
GO

SELECT
    COUNT(*) AS openrowset_customers_count
FROM OPENROWSET(
    BULK 'curated/retail/customers/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
) AS customers_file;
GO

/*
===============================================================================
03. Direct lake read — orders through OPENROWSET
===============================================================================
*/

SELECT TOP (5)
    order_id,
    customer_id,
    order_date,
    order_status,
    payment_status,
    order_total
FROM OPENROWSET(
    BULK 'curated/retail/orders/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
) AS orders_file
ORDER BY order_id;
GO

SELECT
    COUNT(*) AS openrowset_orders_count
FROM OPENROWSET(
    BULK 'curated/retail/orders/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
) AS orders_file;
GO

/*
===============================================================================
04. Compare OPENROWSET counts vs external table counts

Expected:
  customers   = 10
  products    = 10
  orders      = 24
  order_items = 43
===============================================================================
*/

WITH openrowset_counts AS (
    SELECT 'customers' AS dataset_name, COUNT(*) AS row_count
    FROM OPENROWSET(
        BULK 'curated/retail/customers/*.parquet',
        DATA_SOURCE = 'ds_adls_synapse_serving',
        FORMAT = 'PARQUET'
    ) AS f

    UNION ALL

    SELECT 'products' AS dataset_name, COUNT(*) AS row_count
    FROM OPENROWSET(
        BULK 'curated/retail/products/*.parquet',
        DATA_SOURCE = 'ds_adls_synapse_serving',
        FORMAT = 'PARQUET'
    ) AS f

    UNION ALL

    SELECT 'orders' AS dataset_name, COUNT(*) AS row_count
    FROM OPENROWSET(
        BULK 'curated/retail/orders/*.parquet',
        DATA_SOURCE = 'ds_adls_synapse_serving',
        FORMAT = 'PARQUET'
    ) AS f

    UNION ALL

    SELECT 'order_items' AS dataset_name, COUNT(*) AS row_count
    FROM OPENROWSET(
        BULK 'curated/retail/order_items/*.parquet',
        DATA_SOURCE = 'ds_adls_synapse_serving',
        FORMAT = 'PARQUET'
    ) AS f
),
external_table_counts AS (
    SELECT 'customers' AS dataset_name, COUNT(*) AS row_count FROM ext.customers
    UNION ALL
    SELECT 'products' AS dataset_name, COUNT(*) AS row_count FROM ext.products
    UNION ALL
    SELECT 'orders' AS dataset_name, COUNT(*) AS row_count FROM ext.orders
    UNION ALL
    SELECT 'order_items' AS dataset_name, COUNT(*) AS row_count FROM ext.order_items
)
SELECT
    o.dataset_name,
    o.row_count AS openrowset_row_count,
    e.row_count AS external_table_row_count,
    CASE
        WHEN o.row_count = e.row_count THEN 'PASS'
        ELSE 'FAIL'
    END AS comparison_status
FROM openrowset_counts AS o
INNER JOIN external_table_counts AS e
    ON o.dataset_name = e.dataset_name
ORDER BY o.dataset_name;
GO

/*
===============================================================================
05. Compare revenue totals from direct lake reads vs external tables

This validates that the two query patterns are reading the same business data.
===============================================================================
*/

WITH openrowset_revenue AS (
    SELECT
        CAST(SUM(line_total) AS decimal(12,2)) AS total_revenue
    FROM OPENROWSET(
        BULK 'curated/retail/order_items/*.parquet',
        DATA_SOURCE = 'ds_adls_synapse_serving',
        FORMAT = 'PARQUET'
    ) AS f
),
external_table_revenue AS (
    SELECT
        CAST(SUM(line_total) AS decimal(12,2)) AS total_revenue
    FROM ext.order_items
)
SELECT
    o.total_revenue AS openrowset_total_revenue,
    e.total_revenue AS external_table_total_revenue,
    CASE
        WHEN o.total_revenue = e.total_revenue THEN 'PASS'
        ELSE 'FAIL'
    END AS revenue_comparison_status
FROM openrowset_revenue AS o
CROSS JOIN external_table_revenue AS e;
GO

/*
===============================================================================
06. Preview external tables

Goal:
  Notice how much cleaner the serving-layer query becomes once external tables
  exist.
===============================================================================
*/

SELECT TOP (5)
    customer_id,
    customer_name,
    city,
    customer_segment
FROM ext.customers
ORDER BY customer_id;
GO

SELECT TOP (5)
    order_id,
    customer_id,
    order_date,
    order_status,
    order_total
FROM ext.orders
ORDER BY order_id;
GO

SELECT TOP (5)
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total
FROM ext.order_items
ORDER BY order_item_id;
GO

/*
===============================================================================
07. Preview a reporting view that depends on external tables
===============================================================================
*/

SELECT TOP (10)
    order_date,
    order_count,
    total_quantity,
    total_revenue
FROM rpt.vw_sales_by_date
ORDER BY order_date;
GO

/*
===============================================================================
08. Final validation

Expected:
  customers_match   = 1
  products_match    = 1
  orders_match      = 1
  order_items_match = 1
  revenue_match     = 1
  status            = PASS
===============================================================================
*/

WITH validation_counts AS (
    SELECT
        (SELECT COUNT(*) FROM OPENROWSET(
            BULK 'curated/retail/customers/*.parquet',
            DATA_SOURCE = 'ds_adls_synapse_serving',
            FORMAT = 'PARQUET'
        ) AS f) AS openrowset_customers_count,
        (SELECT COUNT(*) FROM ext.customers) AS external_customers_count,

        (SELECT COUNT(*) FROM OPENROWSET(
            BULK 'curated/retail/products/*.parquet',
            DATA_SOURCE = 'ds_adls_synapse_serving',
            FORMAT = 'PARQUET'
        ) AS f) AS openrowset_products_count,
        (SELECT COUNT(*) FROM ext.products) AS external_products_count,

        (SELECT COUNT(*) FROM OPENROWSET(
            BULK 'curated/retail/orders/*.parquet',
            DATA_SOURCE = 'ds_adls_synapse_serving',
            FORMAT = 'PARQUET'
        ) AS f) AS openrowset_orders_count,
        (SELECT COUNT(*) FROM ext.orders) AS external_orders_count,

        (SELECT COUNT(*) FROM OPENROWSET(
            BULK 'curated/retail/order_items/*.parquet',
            DATA_SOURCE = 'ds_adls_synapse_serving',
            FORMAT = 'PARQUET'
        ) AS f) AS openrowset_order_items_count,
        (SELECT COUNT(*) FROM ext.order_items) AS external_order_items_count,

        (SELECT CAST(SUM(line_total) AS decimal(12,2)) FROM OPENROWSET(
            BULK 'curated/retail/order_items/*.parquet',
            DATA_SOURCE = 'ds_adls_synapse_serving',
            FORMAT = 'PARQUET'
        ) AS f) AS openrowset_total_revenue,
        (SELECT CAST(SUM(line_total) AS decimal(12,2)) FROM ext.order_items) AS external_total_revenue
)
SELECT
    openrowset_customers_count,
    external_customers_count,
    CASE WHEN openrowset_customers_count = external_customers_count THEN 1 ELSE 0 END AS customers_match,

    openrowset_products_count,
    external_products_count,
    CASE WHEN openrowset_products_count = external_products_count THEN 1 ELSE 0 END AS products_match,

    openrowset_orders_count,
    external_orders_count,
    CASE WHEN openrowset_orders_count = external_orders_count THEN 1 ELSE 0 END AS orders_match,

    openrowset_order_items_count,
    external_order_items_count,
    CASE WHEN openrowset_order_items_count = external_order_items_count THEN 1 ELSE 0 END AS order_items_match,

    openrowset_total_revenue,
    external_total_revenue,
    CASE WHEN openrowset_total_revenue = external_total_revenue THEN 1 ELSE 0 END AS revenue_match,

    CASE
        WHEN openrowset_customers_count = external_customers_count
         AND openrowset_products_count = external_products_count
         AND openrowset_orders_count = external_orders_count
         AND openrowset_order_items_count = external_order_items_count
         AND openrowset_total_revenue = external_total_revenue
        THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM validation_counts;
GO

/*
===============================================================================
Reflection prompts

Answer these in your own notes:

1. What does OPENROWSET give you that external tables do not?
2. What do external tables give you that OPENROWSET does not?
3. Why did the portfolio project use external tables for the serving layer?
4. When would you choose OPENROWSET during troubleshooting?
5. Why is hiding physical ADLS paths useful for consumers?
===============================================================================
*/
