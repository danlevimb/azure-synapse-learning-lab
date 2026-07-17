# Lab 01 — Serverless SQL Basics

**Repository:** `azure-synapse-learning-lab`  
**Track:** Synapse Serverless SQL Learning Lab  
**Status:** Practice module  
**Related portfolio repo:** `azure-synapse-serverless-serving-layer`

## 1. Objective

Practice the basic operating model of Azure Synapse Serverless SQL.

This module reinforces the difference between "having files in the Data Lake" and "querying those files through a SQL serving layer."

The goal is to become comfortable with:

- Opening Synapse Studio.
- Using the Built-in Serverless SQL pool.
- Selecting the correct database context.
- Running simple validation queries.
- Inspecting external data sources, external file formats, external tables, and schemas.
- Running row-count checks against external tables.
- Understanding why Serverless SQL is query-based and cost-aware.

## 2. Environment Assumptions

This lab reuses the environment created for the portfolio project.

Expected environment:

| Component | Expected value |
|---|---|
| Synapse workspace | Existing project workspace |
| SQL pool | `Built-in` |
| Database | `synapse_serving_demo` |
| Storage account | Existing project ADLS Gen2 account |
| Container / filesystem | `synapse-serving` |
| Data zone | `curated/retail/` |

The lab should not create a new Synapse workspace, new ADLS account, Dedicated SQL Pool, or Spark Pool.

## 3. Safety Rules

This module is read-only.

Do not run:

```text
DROP DATABASE
DROP EXTERNAL TABLE
DROP EXTERNAL DATA SOURCE
CREATE EXTERNAL TABLE AS SELECT
DELETE
ALTER DATABASE
```

The goal is to observe, query, and validate.

## 4. Concepts Practiced

### Serverless SQL Pool

Synapse Serverless SQL allows you to query data in the lake without provisioning a Dedicated SQL Pool.

For this lab, the SQL pool should be:

```text
Built-in
```

### Database Context

The portfolio project database should be:

```text
synapse_serving_demo
```

A common mistake is running scripts while still connected to `master`.

### External Objects

The project uses:

| Object type | Purpose |
|---|---|
| External data source | Points Synapse SQL to ADLS Gen2 |
| External file format | Defines Parquet as the readable format |
| External tables | Expose lake files as SQL tables |
| Reporting views | Provide analytical SQL query surfaces |

## 5. Exercise Instructions

Create or open:

```text
attempts/01_serverless_sql_basics_attempt.sql
```

Complete the script in Synapse Studio using the `Built-in` SQL pool.

Run each section independently and observe the result.

## 6. Tasks

### Task 1 — Confirm Serverless SQL Is Running

Run a basic query that returns a message and current timestamp.

Expected outcome:

```text
The query returns one row with a timestamp.
```

### Task 2 — Select the Project Database

Switch to:

```text
synapse_serving_demo
```

Then confirm the current database context.

Expected outcome:

```text
current_database = synapse_serving_demo
```

### Task 3 — Inspect Schemas

List the schemas available in the database.

Expected schemas should include:

```text
ext
rpt
audit
```

Depending on the current project implementation, `dbo` may also appear.

### Task 4 — Inspect External Data Sources

List external data sources.

Expected result:

```text
ds_adls_synapse_serving
```

### Task 5 — Inspect External File Formats

List external file formats.

Expected result:

```text
ff_parquet
```

### Task 6 — Inspect External Tables

List external tables.

Expected external tables:

```text
ext.customers
ext.products
ext.orders
ext.order_items
```

### Task 7 — Validate External Table Row Counts

Query each external table and validate row counts.

Expected counts:

| Table | Expected count |
|---|---:|
| `ext.customers` | 10 |
| `ext.products` | 10 |
| `ext.orders` | 24 |
| `ext.order_items` | 43 |

### Task 8 — Preview a Reporting View

Query one reporting view.

Recommended view:

```text
rpt.vw_sales_by_date
```

Expected outcome:

```text
The query returns daily sales metrics.
```

### Task 9 — Final Validation

Create a final validation query that returns:

| Field | Expected value |
|---|---|
| `customers_count` | 10 |
| `products_count` | 10 |
| `orders_count` | 24 |
| `order_items_count` | 43 |
| `status` | `PASS` |

## 7. Acceptance Criteria

This lab is complete when:

1. You can open Synapse Studio and use the `Built-in` SQL pool.
2. You can switch to the project database.
3. You can identify the external data source.
4. You can identify the external file format.
5. You can identify the external tables.
6. You can query row counts from the external tables.
7. You can preview at least one reporting view.
8. Your final validation query returns `PASS`.

## 8. Reflection Questions

Answer these in your own words after completing the attempt:

1. What is the role of the `Built-in` SQL pool?
2. Why should this lab avoid Dedicated SQL Pools?
3. What does an external data source represent?
4. What does an external file format represent?
5. Why are external tables useful for a SQL serving layer?
6. What is the difference between querying `ext.customers` and querying a regular SQL Server table?
7. Why does this project use Parquet instead of CSV as the main curated format?
8. How does Serverless SQL pricing influence query design?
9. Why is it important to confirm the current database context before running scripts?
10. What evidence would prove this module worked?

## 9. Interview Defense Notes

A strong explanation:

> In this lab, I used Synapse Serverless SQL through the Built-in pool to query curated Parquet files stored in ADLS Gen2. I validated the database context, inspected external objects, confirmed the external data source and Parquet file format, queried external tables, and validated expected row counts. This proves that the serving layer can expose Data Lake files through SQL without provisioning a Dedicated SQL Pool.

## 10. Common Mistakes

| Mistake | Why it matters |
|---|---|
| Running against `master` | Project objects live in `synapse_serving_demo` |
| Creating a Dedicated SQL Pool | Adds unnecessary cost and is out of scope |
| Using `SELECT *` everywhere | Can process unnecessary data in Serverless SQL |
| Confusing external tables with stored tables | External tables read files from ADLS instead of storing rows inside SQL engine |
| Assuming `NOT NULL` works like SQL Server tables | External tables are schema-on-read and have DDL limitations |

## 11. Completion Status

Mark this module complete when:

```text
attempts/01_serverless_sql_basics_attempt.sql returns PASS
reflection questions answered
key screenshot captured if useful
```
