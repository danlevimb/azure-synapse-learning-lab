/*
Lab 04 — Reporting Views
Repository: azure-synapse-learning-lab
Target: Azure Synapse Serverless SQL
Database: synapse_serving_demo

Purpose:
Create practice reporting views in the lab schema without modifying ext.*, rpt.*, or audit.* objects.

Run context:
- SQL pool: Built-in
- Database: synapse_serving_demo
*/

USE synapse_serving_demo;
GO

/*
Step 1 — Create the lab schema if it does not exist.
*/
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'lab'
)
BEGIN
    EXEC('CREATE SCHEMA lab');
END;
GO

/*
Step 2 — Drop previous lab views so the exercise can be rerun safely.
*/
DROP VIEW IF EXISTS lab.vw_order_status_summary_attempt;
DROP VIEW IF EXISTS lab.vw_sales_by_product_attempt;
DROP VIEW IF EXISTS lab.vw_sales_by_customer_attempt;
DROP VIEW IF EXISTS lab.vw_sales_by_date_attempt;
DROP VIEW IF EXISTS lab.vw_order_line_enriched;
GO

/*
Step 3 — Create the enriched order-line view.

This view is the reusable base view for the reporting layer.
It keeps one row per order item and enriches it with customer, product, and order attributes.
*/
CREATE VIEW lab.vw_order_line_enriched
AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_name,
    c.city,
    c.state_code,
    c.customer_segment,
    o.order_date,
    o.order_status,
    o.payment_status,
    oi.order_item_id,
    oi.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    CAST(oi.unit_price AS decimal(12, 2)) AS unit_price,
    CAST(oi.line_total AS decimal(12, 2)) AS line_revenue
FROM ext.orders AS o
INNER JOIN ext.order_items AS oi
    ON o.order_id = oi.order_id
INNER JOIN ext.products AS p
    ON oi.product_id = p.product_id
INNER JOIN ext.customers AS c
    ON o.customer_id = c.customer_id;
GO

/*
Step 4 — Create sales by date view.
*/
CREATE VIEW lab.vw_sales_by_date_attempt
AS
SELECT
    order_date,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(quantity) AS total_quantity,
    CAST(SUM(line_revenue) AS decimal(12, 2)) AS total_revenue
FROM lab.vw_order_line_enriched
WHERE order_status IN ('COMPLETED', 'PAID')
  AND payment_status = 'APPROVED'
GROUP BY
    order_date;
GO

/*
Step 5 — Create sales by customer view.
*/
CREATE VIEW lab.vw_sales_by_customer_attempt
AS
SELECT
    customer_id,
    customer_name,
    city,
    state_code,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(quantity) AS total_quantity,
    CAST(SUM(line_revenue) AS decimal(12, 2)) AS total_revenue
FROM lab.vw_order_line_enriched
WHERE order_status IN ('COMPLETED', 'PAID')
  AND payment_status = 'APPROVED'
GROUP BY
    customer_id,
    customer_name,
    city,
    state_code;
GO

/*
Step 6 — Create sales by product view.
*/
CREATE VIEW lab.vw_sales_by_product_attempt
AS
SELECT
    product_id,
    product_name,
    category,
    COUNT(DISTINCT order_id) AS order_count,
    SUM(quantity) AS total_quantity,
    CAST(SUM(line_revenue) AS decimal(12, 2)) AS total_revenue
FROM lab.vw_order_line_enriched
WHERE order_status IN ('COMPLETED', 'PAID')
  AND payment_status = 'APPROVED'
GROUP BY
    product_id,
    product_name,
    category;
GO

/*
Step 7 — Create order status summary view.
*/
CREATE VIEW lab.vw_order_status_summary_attempt
AS
SELECT
    order_status,
    payment_status,
    COUNT(*) AS order_count,
    CAST(SUM(order_total) AS decimal(12, 2)) AS total_order_amount
FROM ext.orders
GROUP BY
    order_status,
    payment_status;
GO

/*
Step 8 — Preview enriched view.
*/
SELECT TOP 10
    order_id,
    customer_name,
    product_name,
    category,
    order_date,
    order_status,
    payment_status,
    quantity,
    unit_price,
    line_revenue
FROM lab.vw_order_line_enriched
ORDER BY
    order_id,
    order_item_id;
GO

/*
Step 9 — Preview reporting views.
*/
SELECT
    order_date,
    order_count,
    total_quantity,
    total_revenue
FROM lab.vw_sales_by_date_attempt
ORDER BY
    order_date;
GO

SELECT TOP 10
    customer_id,
    customer_name,
    city,
    state_code,
    order_count,
    total_quantity,
    total_revenue
FROM lab.vw_sales_by_customer_attempt
ORDER BY
    total_revenue DESC;
GO

SELECT TOP 10
    product_id,
    product_name,
    category,
    order_count,
    total_quantity,
    total_revenue
FROM lab.vw_sales_by_product_attempt
ORDER BY
    total_revenue DESC;
GO

SELECT
    order_status,
    payment_status,
    order_count,
    total_order_amount
FROM lab.vw_order_status_summary_attempt
ORDER BY
    order_status,
    payment_status;
GO

/*
Step 10 — Final validation.

This validation uses only external-table backed data and lab views.
It avoids mixing sys catalog views with external data in the same distributed query.
*/
WITH filtered_revenue AS (
    SELECT
        COUNT(DISTINCT order_id) AS filtered_order_count,
        SUM(quantity) AS filtered_total_quantity,
        CAST(SUM(line_revenue) AS decimal(18, 2)) AS filtered_total_revenue
    FROM lab.vw_order_line_enriched
    WHERE order_status IN ('COMPLETED', 'PAID')
      AND payment_status = 'APPROVED'
),
sales_by_date_validation AS (
    SELECT
        COUNT(*) AS sales_by_date_rows,
        SUM(order_count) AS sales_by_date_order_count,
        SUM(total_quantity) AS sales_by_date_total_quantity,
        CAST(SUM(total_revenue) AS decimal(18, 2)) AS sales_by_date_total_revenue
    FROM lab.vw_sales_by_date_attempt
),
sales_by_customer_validation AS (
    SELECT
        COUNT(*) AS sales_by_customer_rows,
        SUM(order_count) AS sales_by_customer_order_count,
        SUM(total_quantity) AS sales_by_customer_total_quantity,
        CAST(SUM(total_revenue) AS decimal(18, 2)) AS sales_by_customer_total_revenue
    FROM lab.vw_sales_by_customer_attempt
),
sales_by_product_validation AS (
    SELECT
        COUNT(*) AS sales_by_product_rows,
        SUM(total_quantity) AS sales_by_product_total_quantity,
        CAST(SUM(total_revenue) AS decimal(18, 2)) AS sales_by_product_total_revenue
    FROM lab.vw_sales_by_product_attempt
),
row_count_validation AS (
    SELECT
        (SELECT COUNT(*) FROM ext.order_items) AS order_items_count,
        (SELECT COUNT(*) FROM lab.vw_order_line_enriched) AS enriched_order_line_count,
        (SELECT COUNT(*) FROM ext.orders) AS orders_count,
        (SELECT SUM(order_count) FROM lab.vw_order_status_summary_attempt) AS status_summary_order_count
)
SELECT
    rc.order_items_count,
    rc.enriched_order_line_count,
    rc.orders_count,
    rc.status_summary_order_count,
    fr.filtered_order_count,
    fr.filtered_total_quantity,
    fr.filtered_total_revenue,
    sd.sales_by_date_rows,
    sd.sales_by_date_order_count,
    sd.sales_by_date_total_quantity,
    sd.sales_by_date_total_revenue,
    sc.sales_by_customer_rows,
    sc.sales_by_customer_total_quantity,
    sc.sales_by_customer_total_revenue,
    sp.sales_by_product_rows,
    sp.sales_by_product_total_quantity,
    sp.sales_by_product_total_revenue,
    CASE
        WHEN rc.order_items_count = rc.enriched_order_line_count
         AND rc.orders_count = rc.status_summary_order_count
         AND sd.sales_by_date_rows > 0
         AND sc.sales_by_customer_rows > 0
         AND sp.sales_by_product_rows > 0
         AND fr.filtered_total_quantity = sd.sales_by_date_total_quantity
         AND fr.filtered_total_quantity = sc.sales_by_customer_total_quantity
         AND fr.filtered_total_quantity = sp.sales_by_product_total_quantity
         AND fr.filtered_total_revenue = sd.sales_by_date_total_revenue
         AND fr.filtered_total_revenue = sc.sales_by_customer_total_revenue
         AND fr.filtered_total_revenue = sp.sales_by_product_total_revenue
        THEN 'PASS'
        ELSE 'FAIL'
    END AS reporting_views_status
FROM row_count_validation AS rc
CROSS JOIN filtered_revenue AS fr
CROSS JOIN sales_by_date_validation AS sd
CROSS JOIN sales_by_customer_validation AS sc
CROSS JOIN sales_by_product_validation AS sp;
GO
