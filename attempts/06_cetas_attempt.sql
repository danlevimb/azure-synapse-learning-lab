/*
Lab 06 — CETAS Outputs
Repository: azure-synapse-learning-lab
Target database: synapse_serving_demo
SQL pool: Built-in / Serverless

Purpose:
Practice CREATE EXTERNAL TABLE AS SELECT (CETAS) in Synapse Serverless SQL.

This script creates only:
  lab.sales_by_city_cetas_attempt

It writes output files to:
  lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/

Important:
If you re-run this script and the ADLS output folder already exists with files,
CETAS may fail. Either delete the ADLS folder or change the run_id below.
*/

USE synapse_serving_demo;
GO

/* ------------------------------------------------------------
   1. Ensure lab schema exists
------------------------------------------------------------ */
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'lab'
)
BEGIN
    EXEC('CREATE SCHEMA lab');
END;
GO

/* ------------------------------------------------------------
   2. Drop previous external table metadata if it exists

   Note:
   This does NOT delete files already written in ADLS.
------------------------------------------------------------ */
IF EXISTS (
    SELECT 1
    FROM sys.external_tables
    WHERE name = 'sales_by_city_cetas_attempt'
      AND schema_id = SCHEMA_ID('lab')
)
BEGIN
    DROP EXTERNAL TABLE lab.sales_by_city_cetas_attempt;
END;
GO

/* ------------------------------------------------------------
   3. Create CETAS output

   If this step fails with an output-location conflict:
   - delete the ADLS folder:
     lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/
   - or change the run_id in LOCATION.
------------------------------------------------------------ */
CREATE EXTERNAL TABLE lab.sales_by_city_cetas_attempt
WITH
(
    LOCATION = 'lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/',
    DATA_SOURCE = ds_adls_synapse_serving,
    FILE_FORMAT = ff_parquet
)
AS
SELECT
    CAST(c.city AS varchar(100)) AS city,
    CAST(c.state_code AS varchar(10)) AS state_code,
    CAST(COUNT(DISTINCT o.order_id) AS bigint) AS order_count,
    CAST(SUM(oi.quantity) AS int) AS total_quantity,
    CAST(SUM(oi.line_total) AS decimal(12,2)) AS total_revenue
FROM ext.customers c
INNER JOIN ext.orders o
    ON c.customer_id = o.customer_id
INNER JOIN ext.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status IN ('COMPLETED', 'PAID')
GROUP BY
    c.city,
    c.state_code;
GO

/* ------------------------------------------------------------
   4. Metadata validation

   Keep metadata checks separate from external data checks.
------------------------------------------------------------ */
SELECT
    CASE
        WHEN COUNT(*) = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS cetas_metadata_status,
    COUNT(*) AS cetas_external_table_count
FROM sys.external_tables et
INNER JOIN sys.schemas s
    ON et.schema_id = s.schema_id
WHERE s.name = 'lab'
  AND et.name = 'sales_by_city_cetas_attempt';
GO

/* ------------------------------------------------------------
   5. Preview CETAS output
------------------------------------------------------------ */
SELECT TOP 20
    city,
    state_code,
    order_count,
    total_quantity,
    total_revenue
FROM lab.sales_by_city_cetas_attempt
ORDER BY
    total_revenue DESC,
    city;
GO

/* ------------------------------------------------------------
   6. Source business summary

   This is computed directly from external source tables.
------------------------------------------------------------ */
SELECT
    COUNT(*) AS source_city_row_count,
    CAST(SUM(order_count) AS bigint) AS source_order_count,
    CAST(SUM(total_quantity) AS int) AS source_total_quantity,
    CAST(SUM(total_revenue) AS decimal(12,2)) AS source_total_revenue
FROM (
    SELECT
        c.city,
        c.state_code,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.line_total) AS total_revenue
    FROM ext.customers c
    INNER JOIN ext.orders o
        ON c.customer_id = o.customer_id
    INNER JOIN ext.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status IN ('COMPLETED', 'PAID')
    GROUP BY
        c.city,
        c.state_code
) src;
GO

/* ------------------------------------------------------------
   7. CETAS business summary

   This is computed from the CETAS output external table.
------------------------------------------------------------ */
SELECT
    COUNT(*) AS cetas_city_row_count,
    CAST(SUM(order_count) AS bigint) AS cetas_order_count,
    CAST(SUM(total_quantity) AS int) AS cetas_total_quantity,
    CAST(SUM(total_revenue) AS decimal(12,2)) AS cetas_total_revenue
FROM lab.sales_by_city_cetas_attempt;
GO

/* ------------------------------------------------------------
   8. Final business validation

   This compares the source calculation with the CETAS output.
------------------------------------------------------------ */
WITH source_summary AS
(
    SELECT
        COUNT(*) AS source_city_row_count,
        CAST(SUM(order_count) AS bigint) AS source_order_count,
        CAST(SUM(total_quantity) AS int) AS source_total_quantity,
        CAST(SUM(total_revenue) AS decimal(12,2)) AS source_total_revenue
    FROM (
        SELECT
            c.city,
            c.state_code,
            COUNT(DISTINCT o.order_id) AS order_count,
            SUM(oi.quantity) AS total_quantity,
            SUM(oi.line_total) AS total_revenue
        FROM ext.customers c
        INNER JOIN ext.orders o
            ON c.customer_id = o.customer_id
        INNER JOIN ext.order_items oi
            ON o.order_id = oi.order_id
        WHERE o.order_status IN ('COMPLETED', 'PAID')
        GROUP BY
            c.city,
            c.state_code
    ) src
),
cetas_summary AS
(
    SELECT
        COUNT(*) AS cetas_city_row_count,
        CAST(SUM(order_count) AS bigint) AS cetas_order_count,
        CAST(SUM(total_quantity) AS int) AS cetas_total_quantity,
        CAST(SUM(total_revenue) AS decimal(12,2)) AS cetas_total_revenue
    FROM lab.sales_by_city_cetas_attempt
)
SELECT
    s.source_city_row_count,
    c.cetas_city_row_count,
    s.source_order_count,
    c.cetas_order_count,
    s.source_total_quantity,
    c.cetas_total_quantity,
    s.source_total_revenue,
    c.cetas_total_revenue,
    CASE
        WHEN s.source_city_row_count = c.cetas_city_row_count
         AND s.source_order_count = c.cetas_order_count
         AND s.source_total_quantity = c.cetas_total_quantity
         AND ABS(s.source_total_revenue - c.cetas_total_revenue) <= 0.01
        THEN 'PASS'
        ELSE 'FAIL'
    END AS cetas_business_validation_status
FROM source_summary s
CROSS JOIN cetas_summary c;
GO
