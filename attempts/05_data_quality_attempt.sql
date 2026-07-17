/*
Lab 05 — Data Quality with SQL
Repository: azure-synapse-learning-lab
Target database: synapse_serving_demo
SQL pool: Built-in / Serverless

Purpose:
Validate curated retail external tables using explicit SQL data quality checks.

This script is safe to re-run.
It creates only:
  lab.vw_data_quality_checks_attempt
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
   2. Recreate data quality view
------------------------------------------------------------ */
CREATE OR ALTER VIEW lab.vw_data_quality_checks_attempt
AS

/* Duplicate key checks */
SELECT
    CAST('duplicate_customer_ids' AS varchar(100)) AS check_name,
    CAST('uniqueness' AS varchar(50)) AS check_category,
    CAST(COUNT(*) AS bigint) AS failed_record_count,
    CAST('HIGH' AS varchar(20)) AS severity,
    CAST(CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS varchar(10)) AS status,
    CAST('Customer IDs should be unique.' AS varchar(300)) AS validation_message
FROM (
    SELECT customer_id
    FROM ext.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'duplicate_product_ids',
    'uniqueness',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Product IDs should be unique.'
FROM (
    SELECT product_id
    FROM ext.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'duplicate_order_ids',
    'uniqueness',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Order IDs should be unique.'
FROM (
    SELECT order_id
    FROM ext.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'duplicate_order_item_ids',
    'uniqueness',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Order item IDs should be unique.'
FROM (
    SELECT order_item_id
    FROM ext.order_items
    GROUP BY order_item_id
    HAVING COUNT(*) > 1
) d

UNION ALL

/* Relationship checks */
SELECT
    'orders_without_customer',
    'referential_integrity',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Every order should reference an existing customer.'
FROM ext.orders o
LEFT JOIN ext.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'order_items_without_order',
    'referential_integrity',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Every order item should reference an existing order.'
FROM ext.order_items oi
LEFT JOIN ext.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_items_without_product',
    'referential_integrity',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Every order item should reference an existing product.'
FROM ext.order_items oi
LEFT JOIN ext.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

/* Monetary checks */
SELECT
    'negative_order_totals',
    'business_rule',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Order totals should not be negative.'
FROM ext.orders
WHERE order_total < 0

UNION ALL

SELECT
    'negative_line_totals',
    'business_rule',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Order item line totals should not be negative.'
FROM ext.order_items
WHERE line_total < 0

UNION ALL

/* Domain checks */
SELECT
    'invalid_order_status',
    'domain_validation',
    CAST(COUNT(*) AS bigint),
    'MEDIUM',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Order status should belong to the approved domain.'
FROM ext.orders
WHERE order_status NOT IN ('COMPLETED', 'PAID', 'PENDING', 'CANCELLED', 'REFUNDED')

UNION ALL

SELECT
    'invalid_payment_status',
    'domain_validation',
    CAST(COUNT(*) AS bigint),
    'MEDIUM',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Payment status should belong to the approved domain.'
FROM ext.orders
WHERE payment_status NOT IN ('APPROVED', 'PENDING', 'DECLINED', 'REFUNDED')

UNION ALL

/* Calculation checks */
SELECT
    'line_total_mismatch',
    'calculation_validation',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Line total should equal quantity multiplied by unit price.'
FROM ext.order_items
WHERE ABS(CAST(line_total AS decimal(18,2)) - CAST(quantity * unit_price AS decimal(18,2))) > 0.01

UNION ALL

SELECT
    'order_total_mismatch',
    'calculation_validation',
    CAST(COUNT(*) AS bigint),
    'HIGH',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Order header total should equal the sum of its order item line totals.'
FROM (
    SELECT
        o.order_id,
        CAST(o.order_total AS decimal(18,2)) AS order_total,
        CAST(SUM(oi.line_total) AS decimal(18,2)) AS calculated_order_total
    FROM ext.orders o
    INNER JOIN ext.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.order_total
) x
WHERE ABS(order_total - calculated_order_total) > 0.01;
GO

/* ------------------------------------------------------------
   3. Inspect all data quality checks
------------------------------------------------------------ */
SELECT
    check_name,
    check_category,
    failed_record_count,
    severity,
    status,
    validation_message
FROM lab.vw_data_quality_checks_attempt
ORDER BY
    CASE severity
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        WHEN 'LOW' THEN 3
        ELSE 4
    END,
    check_category,
    check_name;
GO

/* ------------------------------------------------------------
   4. Final summary
------------------------------------------------------------ */
SELECT
    COUNT(*) AS total_check_count,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS pass_check_count,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS fail_check_count,
    SUM(failed_record_count) AS total_failed_record_count,
    CASE
        WHEN SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) = 0
         AND SUM(failed_record_count) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS data_quality_status
FROM lab.vw_data_quality_checks_attempt;
GO

/* ------------------------------------------------------------
   5. Optional row count context
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
