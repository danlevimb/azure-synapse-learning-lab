/*
===============================================================================
Lab 03 — Schema-on-Read and External Table Schemas
Repo: azure-synapse-learning-lab
Engine: Synapse Serverless SQL — Built-in
Database: synapse_serving_demo

Purpose:
  Practice schema-on-read using OPENROWSET, explicit schemas, and lab external
  tables without touching the portfolio project's main objects.

Important:
  This script creates/recreates only one safe lab object:

    lab.customers_schema_on_read

  It does not modify ext.*, rpt.*, or audit.* objects.
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
02. Create lab schema for safe practice objects
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'lab')
BEGIN
    EXEC('CREATE SCHEMA lab');
END;
GO

SELECT
    name AS schema_name,
    'READY' AS schema_status
FROM sys.schemas
WHERE name = 'lab';
GO

/*
===============================================================================
03. OPENROWSET with inferred schema

Goal:
  Read customer Parquet files directly and let Synapse infer the schema from
  Parquet metadata.
===============================================================================
*/

SELECT TOP (5)
    *
FROM OPENROWSET(
    BULK 'curated/retail/customers/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
) AS customers_file;
GO

SELECT
    COUNT(*) AS openrowset_inferred_customers_count
FROM OPENROWSET(
    BULK 'curated/retail/customers/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
) AS customers_file;
GO

/*
===============================================================================
04. OPENROWSET with explicit schema

Goal:
  Define the expected columns and SQL data types at query time.

Note:
  Character columns use UTF-8 collation to align with the portfolio project
  external table pattern.
===============================================================================
*/

SELECT TOP (5)
    customer_id,
    customer_name,
    email,
    city,
    state_code,
    customer_segment,
    created_at,
    updated_at
FROM OPENROWSET(
    BULK 'curated/retail/customers/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
)
WITH (
    customer_id       int,
    customer_name     varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
    email             varchar(200) COLLATE Latin1_General_100_BIN2_UTF8,
    city              varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
    state_code        varchar(10)  COLLATE Latin1_General_100_BIN2_UTF8,
    customer_segment  varchar(50)  COLLATE Latin1_General_100_BIN2_UTF8,
    created_at        datetime2(3),
    updated_at        datetime2(3)
) AS customers_explicit
ORDER BY customer_id;
GO

SELECT
    COUNT(*) AS openrowset_explicit_customers_count
FROM OPENROWSET(
    BULK 'curated/retail/customers/*.parquet',
    DATA_SOURCE = 'ds_adls_synapse_serving',
    FORMAT = 'PARQUET'
)
WITH (
    customer_id       int,
    customer_name     varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
    email             varchar(200) COLLATE Latin1_General_100_BIN2_UTF8,
    city              varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
    state_code        varchar(10)  COLLATE Latin1_General_100_BIN2_UTF8,
    customer_segment  varchar(50)  COLLATE Latin1_General_100_BIN2_UTF8,
    created_at        datetime2(3),
    updated_at        datetime2(3)
) AS customers_explicit;
GO

/*
===============================================================================
05. Inspect existing external table metadata

Important:
  Keep metadata queries separate from external data scans.
  Synapse Serverless can be picky when system catalog views and distributed
  external-data queries are mixed in the same query.
===============================================================================
*/

SELECT
    s.name AS schema_name,
    t.name AS external_table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS system_type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.collation_name
FROM sys.external_tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
INNER JOIN sys.columns AS c
    ON t.object_id = c.object_id
INNER JOIN sys.types AS ty
    ON c.user_type_id = ty.user_type_id
WHERE s.name = 'ext'
  AND t.name = 'customers'
ORDER BY c.column_id;
GO

/*
===============================================================================
06. Create a safe practice external table over the same customers folder

Lesson:
  Do not use NOT NULL in this Synapse Serverless external table definition.
  Logical required fields are validated later with SQL checks.
===============================================================================
*/

IF EXISTS (
    SELECT 1
    FROM sys.external_tables AS t
    INNER JOIN sys.schemas AS s
        ON t.schema_id = s.schema_id
    WHERE s.name = 'lab'
      AND t.name = 'customers_schema_on_read'
)
BEGIN
    DROP EXTERNAL TABLE [lab].[customers_schema_on_read];
END;
GO

CREATE EXTERNAL TABLE [lab].[customers_schema_on_read]
(
    [customer_id]       int,
    [customer_name]     varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
    [email]             varchar(200) COLLATE Latin1_General_100_BIN2_UTF8,
    [city]              varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
    [state_code]        varchar(10)  COLLATE Latin1_General_100_BIN2_UTF8,
    [customer_segment]  varchar(50)  COLLATE Latin1_General_100_BIN2_UTF8,
    [created_at]        datetime2(3),
    [updated_at]        datetime2(3)
)
WITH
(
    LOCATION = 'curated/retail/customers/',
    DATA_SOURCE = [ds_adls_synapse_serving],
    FILE_FORMAT = [ff_parquet]
);
GO

SELECT
    s.name AS schema_name,
    t.name AS external_table_name,
    ds.name AS external_data_source_name,
    ff.name AS external_file_format_name,
    t.location AS table_location,
    'READY' AS table_status
FROM sys.external_tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
INNER JOIN sys.external_data_sources AS ds
    ON t.data_source_id = ds.data_source_id
INNER JOIN sys.external_file_formats AS ff
    ON t.file_format_id = ff.file_format_id
WHERE s.name = 'lab'
  AND t.name = 'customers_schema_on_read';
GO

/*
===============================================================================
07. Query the lab external table
===============================================================================
*/

SELECT TOP (5)
    customer_id,
    customer_name,
    city,
    state_code,
    customer_segment
FROM lab.customers_schema_on_read
ORDER BY customer_id;
GO

SELECT
    COUNT(*) AS lab_customers_count
FROM lab.customers_schema_on_read;
GO

/*
===============================================================================
08. Compare lab external table with portfolio external table
===============================================================================
*/

SELECT
    (SELECT COUNT(*) FROM ext.customers) AS ext_customers_count,
    (SELECT COUNT(*) FROM lab.customers_schema_on_read) AS lab_customers_count,
    CASE
        WHEN (SELECT COUNT(*) FROM ext.customers)
           = (SELECT COUNT(*) FROM lab.customers_schema_on_read)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS row_count_comparison_status;
GO

SELECT
    COALESCE(e.city, l.city) AS city,
    e.ext_customer_count,
    l.lab_customer_count,
    CASE
        WHEN ISNULL(e.ext_customer_count, -1) = ISNULL(l.lab_customer_count, -2)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS city_distribution_status
FROM (
    SELECT
        city,
        COUNT(*) AS ext_customer_count
    FROM ext.customers
    GROUP BY city
) AS e
FULL OUTER JOIN (
    SELECT
        city,
        COUNT(*) AS lab_customer_count
    FROM lab.customers_schema_on_read
    GROUP BY city
) AS l
    ON e.city = l.city
ORDER BY city;
GO

/*
===============================================================================
09. Validate logical constraints with SQL

External tables define how to read files. They do not replace data quality rules.
===============================================================================
*/

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id_count,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_customer_name_count,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city_count,
    SUM(CASE WHEN customer_segment IS NULL THEN 1 ELSE 0 END) AS null_customer_segment_count
FROM lab.customers_schema_on_read;
GO

SELECT
    COUNT(*) AS duplicate_customer_id_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS duplicate_count
    FROM lab.customers_schema_on_read
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS duplicates;
GO

/*
===============================================================================
10. Optional failure examples — keep commented by default

These examples are intentionally NOT executed.
They document common mistakes without breaking the lab run.
===============================================================================

-- Example A: External table definitions with NOT NULL can fail in Synapse
-- Serverless SQL. Keep logical required fields in documentation and validate
-- them through data quality queries instead.

-- CREATE EXTERNAL TABLE [lab].[bad_not_null_demo]
-- (
--     [customer_id] int NOT NULL
-- )
-- WITH
-- (
--     LOCATION = 'curated/retail/customers/',
--     DATA_SOURCE = [ds_adls_synapse_serving],
--     FILE_FORMAT = [ff_parquet]
-- );

-- Example B: A wrong column type can produce conversion or query-time errors.
-- Schema-on-read means mistakes surface when the files are read.

-- SELECT TOP (5)
--     customer_id
-- FROM OPENROWSET(
--     BULK 'curated/retail/customers/*.parquet',
--     DATA_SOURCE = 'ds_adls_synapse_serving',
--     FORMAT = 'PARQUET'
-- )
-- WITH (
--     customer_id varchar(5)
-- ) AS bad_type_demo;
===============================================================================
*/

/*
===============================================================================
11. Final validation

Expected:
  openrowset_explicit_count    = 10
  external_customers_count     = 10
  lab_customers_count          = 10
  null_customer_id_count       = 0
  duplicate_customer_id_count  = 0
  schema_on_read_status        = PASS
===============================================================================
*/

WITH openrowset_explicit AS (
    SELECT COUNT(*) AS openrowset_explicit_count
    FROM OPENROWSET(
        BULK 'curated/retail/customers/*.parquet',
        DATA_SOURCE = 'ds_adls_synapse_serving',
        FORMAT = 'PARQUET'
    )
    WITH (
        customer_id       int,
        customer_name     varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
        email             varchar(200) COLLATE Latin1_General_100_BIN2_UTF8,
        city              varchar(100) COLLATE Latin1_General_100_BIN2_UTF8,
        state_code        varchar(10)  COLLATE Latin1_General_100_BIN2_UTF8,
        customer_segment  varchar(50)  COLLATE Latin1_General_100_BIN2_UTF8,
        created_at        datetime2(3),
        updated_at        datetime2(3)
    ) AS customers_explicit
),
external_counts AS (
    SELECT
        (SELECT COUNT(*) FROM ext.customers) AS external_customers_count,
        (SELECT COUNT(*) FROM lab.customers_schema_on_read) AS lab_customers_count
),
logical_quality AS (
    SELECT
        SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id_count,
        SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_customer_name_count,
        SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city_count,
        SUM(CASE WHEN customer_segment IS NULL THEN 1 ELSE 0 END) AS null_customer_segment_count
    FROM lab.customers_schema_on_read
),
duplicate_check AS (
    SELECT
        COUNT(*) AS duplicate_customer_id_count
    FROM (
        SELECT
            customer_id,
            COUNT(*) AS duplicate_count
        FROM lab.customers_schema_on_read
        GROUP BY customer_id
        HAVING COUNT(*) > 1
    ) AS duplicates
)
SELECT
    o.openrowset_explicit_count,
    e.external_customers_count,
    e.lab_customers_count,
    q.null_customer_id_count,
    q.null_customer_name_count,
    q.null_city_count,
    q.null_customer_segment_count,
    d.duplicate_customer_id_count,
    CASE
        WHEN o.openrowset_explicit_count = 10
         AND e.external_customers_count = 10
         AND e.lab_customers_count = 10
         AND e.external_customers_count = e.lab_customers_count
         AND q.null_customer_id_count = 0
         AND q.null_customer_name_count = 0
         AND q.null_city_count = 0
         AND q.null_customer_segment_count = 0
         AND d.duplicate_customer_id_count = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS schema_on_read_status
FROM openrowset_explicit AS o
CROSS JOIN external_counts AS e
CROSS JOIN logical_quality AS q
CROSS JOIN duplicate_check AS d;
GO

/*
===============================================================================
Reflection prompts

Answer these in your own notes:

1. What does schema-on-read mean in Synapse Serverless SQL?
2. What is the difference between inferred schema and explicit schema?
3. Why are external tables useful for a serving layer?
4. Why did NOT NULL belong in the logical data contract but not in the
   Synapse external table DDL?
5. How do data quality queries complement schema-on-read?
===============================================================================
*/
