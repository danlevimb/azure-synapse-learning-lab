/*
Lab 07 — Cost-Aware Querying
Repository: azure-synapse-learning-lab
Target database: synapse_serving_demo
SQL pool: Built-in / Serverless

Purpose:
Practice cost-aware query habits in Synapse Serverless SQL.

This script is read-only.
It does not create, alter, or drop objects.

Important Synapse Serverless lesson:
Keep metadata checks over sys.* separate from external data checks over ext.* / rpt.*.
Mixing them in the same distributed query can trigger:
"The query references an object that is not supported in distributed processing mode."
*/

USE synapse_serving_demo;
GO

/* ------------------------------------------------------------
   1. Metadata check: Parquet external file format

   Metadata-only query.
------------------------------------------------------------ */
SELECT
    CASE
        WHEN COUNT(*) >= 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS parquet_format_status,
    COUNT(*) AS parquet_format_count
FROM sys.external_file_formats
WHERE name = 'ff_parquet'
  AND format_type = 'PARQUET';
GO

/* ------------------------------------------------------------
   2. Metadata check: required external tables

   Metadata-only query.
------------------------------------------------------------ */
SELECT
    CASE
        WHEN COUNT(*) = 4 THEN 'PASS'
        ELSE 'FAIL'
    END AS external_table_status,
    COUNT(*) AS required_external_table_count
FROM sys.external_tables et
INNER JOIN sys.schemas s
    ON et.schema_id = s.schema_id
WHERE s.name = 'ext'
  AND et.name IN ('customers', 'products', 'orders', 'order_items');
GO

/* ------------------------------------------------------------
   3. Metadata check: reporting views

   Metadata-only query.
------------------------------------------------------------ */
SELECT
    CASE
        WHEN COUNT(*) >= 5 THEN 'PASS'
        ELSE 'FAIL'
    END AS reporting_view_status,
    COUNT(*) AS reporting_view_count
FROM sys.views v
INNER JOIN sys.schemas s
    ON v.schema_id = s.schema_id
WHERE s.name = 'rpt'
  AND v.name IN
  (
      'vw_sales_by_date',
      'vw_sales_by_customer',
      'vw_sales_by_product',
      'vw_sales_by_city',
      'vw_order_status_summary'
  );
GO

/* ------------------------------------------------------------
   4. Metadata check: obvious SELECT * usage in reporting views

   Metadata-only query.
   This is a lightweight static check.
------------------------------------------------------------ */
SELECT
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'REVIEW'
    END AS select_star_status,
    COUNT(*) AS reporting_views_with_obvious_select_star
FROM sys.sql_modules m
INNER JOIN sys.views v
    ON m.object_id = v.object_id
INNER JOIN sys.schemas s
    ON v.schema_id = s.schema_id
WHERE s.name = 'rpt'
  AND UPPER(REPLACE(REPLACE(m.definition, CHAR(13), ' '), CHAR(10), ' ')) LIKE '%SELECT *%';
GO

/* ------------------------------------------------------------
   5. Metadata-only final status

   This final status uses only system catalog metadata.
   It does not read external data.
------------------------------------------------------------ */
WITH metadata_checks AS
(
    SELECT
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM sys.external_file_formats
                WHERE name = 'ff_parquet'
                  AND format_type = 'PARQUET'
            )
            THEN 1 ELSE 0
        END AS parquet_ok,

        CASE
            WHEN (
                SELECT COUNT(*)
                FROM sys.external_tables et
                INNER JOIN sys.schemas s
                    ON et.schema_id = s.schema_id
                WHERE s.name = 'ext'
                  AND et.name IN ('customers', 'products', 'orders', 'order_items')
            ) = 4
            THEN 1 ELSE 0
        END AS external_tables_ok,

        CASE
            WHEN (
                SELECT COUNT(*)
                FROM sys.views v
                INNER JOIN sys.schemas s
                    ON v.schema_id = s.schema_id
                WHERE s.name = 'rpt'
                  AND v.name IN
                  (
                      'vw_sales_by_date',
                      'vw_sales_by_customer',
                      'vw_sales_by_product',
                      'vw_sales_by_city',
                      'vw_order_status_summary'
                  )
            ) >= 5
            THEN 1 ELSE 0
        END AS reporting_views_ok,

        CASE
            WHEN (
                SELECT COUNT(*)
                FROM sys.sql_modules m
                INNER JOIN sys.views v
                    ON m.object_id = v.object_id
                INNER JOIN sys.schemas s
                    ON v.schema_id = s.schema_id
                WHERE s.name = 'rpt'
                  AND UPPER(REPLACE(REPLACE(m.definition, CHAR(13), ' '), CHAR(10), ' ')) LIKE '%SELECT *%'
            ) = 0
            THEN 1 ELSE 0
        END AS select_star_ok
)
SELECT
    CASE
        WHEN parquet_ok = 1
         AND external_tables_ok = 1
         AND reporting_views_ok = 1
         AND select_star_ok = 1
        THEN 'PASS'
        ELSE 'FAIL'
    END AS metadata_cost_awareness_status,
    parquet_ok,
    external_tables_ok,
    reporting_views_ok,
    select_star_ok
FROM metadata_checks;
GO

/* ------------------------------------------------------------
   6. Dataset size context

   External-data query.
   The MVP uses intentionally small datasets for cost-controlled learning.
------------------------------------------------------------ */
SELECT
    'customers' AS dataset_name,
    COUNT(*) AS row_count
FROM ext.customers

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM ext.products

UNION ALL

SELECT
    'orders',
    COUNT(*)
FROM ext.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM ext.order_items;
GO

/* ------------------------------------------------------------
   7. Dataset size validation

   External-data query only.
------------------------------------------------------------ */
WITH row_counts AS
(
    SELECT 'customers' AS dataset_name, COUNT(*) AS row_count FROM ext.customers
    UNION ALL
    SELECT 'products', COUNT(*) FROM ext.products
    UNION ALL
    SELECT 'orders', COUNT(*) FROM ext.orders
    UNION ALL
    SELECT 'order_items', COUNT(*) FROM ext.order_items
)
SELECT
    CASE
        WHEN SUM(CASE WHEN dataset_name = 'customers' AND row_count = 10 THEN 1 ELSE 0 END) = 1
         AND SUM(CASE WHEN dataset_name = 'products' AND row_count = 10 THEN 1 ELSE 0 END) = 1
         AND SUM(CASE WHEN dataset_name = 'orders' AND row_count = 24 THEN 1 ELSE 0 END) = 1
         AND SUM(CASE WHEN dataset_name = 'order_items' AND row_count = 43 THEN 1 ELSE 0 END) = 1
        THEN 'PASS'
        ELSE 'FAIL'
    END AS dataset_size_status,
    SUM(row_count) AS total_demo_rows
FROM row_counts;
GO

/* ------------------------------------------------------------
   8. Wider exploration query

   External-data query.
   This is acceptable for quick inspection, but avoid making this
   the default pattern for reusable reporting queries.
------------------------------------------------------------ */
SELECT TOP 10
    o.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    o.payment_status,
    o.order_total,
    oi.order_item_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM ext.orders o
INNER JOIN ext.order_items oi
    ON o.order_id = oi.order_id
ORDER BY
    o.order_date,
    o.order_id;
GO

/* ------------------------------------------------------------
   9. Targeted analytical query

   External-data query.
   This selects only the columns needed to answer:
   sales by date.
------------------------------------------------------------ */
SELECT TOP 20
    order_date,
    order_count,
    total_quantity,
    total_revenue
FROM rpt.vw_sales_by_date
ORDER BY
    order_date;
GO

/* ------------------------------------------------------------
   10. Targeted query validation

   External-data query only.
------------------------------------------------------------ */
SELECT
    CASE
        WHEN COUNT(*) > 0
         AND SUM(total_quantity) > 0
         AND SUM(total_revenue) > 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS targeted_query_status,
    COUNT(*) AS sales_by_date_row_count,
    CAST(SUM(total_quantity) AS int) AS total_quantity,
    CAST(SUM(total_revenue) AS decimal(12,2)) AS total_revenue
FROM rpt.vw_sales_by_date;
GO

/* ------------------------------------------------------------
   11. External-data final status

   External-data query only.
   It does not reference sys.* metadata.
------------------------------------------------------------ */
WITH dataset_validation AS
(
    SELECT
        CASE
            WHEN SUM(CASE WHEN dataset_name = 'customers' AND row_count = 10 THEN 1 ELSE 0 END) = 1
             AND SUM(CASE WHEN dataset_name = 'products' AND row_count = 10 THEN 1 ELSE 0 END) = 1
             AND SUM(CASE WHEN dataset_name = 'orders' AND row_count = 24 THEN 1 ELSE 0 END) = 1
             AND SUM(CASE WHEN dataset_name = 'order_items' AND row_count = 43 THEN 1 ELSE 0 END) = 1
            THEN 1 ELSE 0
        END AS dataset_size_ok
    FROM
    (
        SELECT 'customers' AS dataset_name, COUNT(*) AS row_count FROM ext.customers
        UNION ALL
        SELECT 'products', COUNT(*) FROM ext.products
        UNION ALL
        SELECT 'orders', COUNT(*) FROM ext.orders
        UNION ALL
        SELECT 'order_items', COUNT(*) FROM ext.order_items
    ) rc
),
targeted_query_validation AS
(
    SELECT
        CASE
            WHEN COUNT(*) > 0
             AND SUM(total_quantity) > 0
             AND SUM(total_revenue) > 0
            THEN 1 ELSE 0
        END AS targeted_query_ok
    FROM rpt.vw_sales_by_date
)
SELECT
    CASE
        WHEN d.dataset_size_ok = 1
         AND t.targeted_query_ok = 1
        THEN 'PASS'
        ELSE 'FAIL'
    END AS external_data_cost_awareness_status,
    d.dataset_size_ok,
    t.targeted_query_ok
FROM dataset_validation d
CROSS JOIN targeted_query_validation t;
GO

/* ------------------------------------------------------------
   12. Cost-control checklist

   Static review checklist.
------------------------------------------------------------ */
SELECT
    'serverless_sql_only' AS control_name,
    'PASS' AS status,
    'The lab uses the Built-in Serverless SQL pool. Do not create Dedicated SQL Pools for this MVP.' AS control_note

UNION ALL

SELECT
    'parquet_format',
    'PASS',
    'The project uses Parquet files for curated analytical datasets.'

UNION ALL

SELECT
    'small_controlled_dataset',
    'PASS',
    'The MVP uses a small synthetic dataset to avoid unnecessary data processing.'

UNION ALL

SELECT
    'explicit_reporting_columns',
    'PASS',
    'Reporting queries should select required columns instead of defaulting to SELECT *.'

UNION ALL

SELECT
    'cetas_with_purpose',
    'PASS',
    'CETAS outputs should be small, intentional, and validated.'

UNION ALL

SELECT
    'no_spark_pool_required',
    'PASS',
    'Spark Pools are not required for this SQL serving lab.';
GO
