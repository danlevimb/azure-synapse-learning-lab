# Lab 03 — Schema-on-Read and External Table Schemas

**Repo:** `azure-synapse-learning-lab`  
**Module:** `03_schema_on_read_and_external_table_schemas`  
**Status:** Practice module  
**Recommended engine:** Synapse Serverless SQL — `Built-in`  
**Recommended database:** `synapse_serving_demo`

---

## 1. Objective

Practice how Synapse Serverless SQL applies schema to files stored in Azure Data Lake Storage Gen2.

By the end of this lab, you should be able to explain:

1. What schema-on-read means.
2. Why Parquet files can be queried without loading them into SQL storage.
3. How `OPENROWSET` can infer or explicitly define a schema.
4. How external tables provide a reusable schema over lake files.
5. Why external table definitions do not enforce constraints such as `NOT NULL`.
6. Why data quality checks still matter even when a logical schema exists.

---

## 2. Why This Matters

In traditional SQL Server work, table schemas usually define and enforce storage structure.

In Synapse Serverless SQL, the data remains in the lake.

The SQL layer reads files and applies schema at query time.

That pattern is called:

```text
schema-on-read
```

This is powerful because users can query data lake files through SQL without loading them into a dedicated SQL database.

But it also means the SQL serving layer must be designed carefully:

```text
Physical files in ADLS → SQL schema definition → query-time interpretation
```

The schema helps consumers query data consistently, but it does not automatically enforce all business rules.

---

## 3. Starting Point

This lab assumes the portfolio project environment already exists.

Expected database:

```text
synapse_serving_demo
```

Expected external objects:

```text
External data source:
  ds_adls_synapse_serving

External file format:
  ff_parquet

External tables:
  ext.customers
  ext.products
  ext.orders
  ext.order_items
```

Expected ADLS layout:

```text
curated/
  retail/
    customers/
    products/
    orders/
    order_items/
```

---

## 4. Key Concepts

### Schema-on-Read

Schema-on-read means the data is not physically loaded into a SQL table before being queried.

Instead, the query engine reads files from storage and applies a schema during query execution.

### `OPENROWSET` with Inferred Schema

When reading Parquet, Synapse Serverless SQL can infer columns from the Parquet metadata.

This is useful for exploration.

### `OPENROWSET` with Explicit Schema

You can also provide a `WITH` clause to define the expected columns and data types.

This is useful when you want more control over the query surface.

### External Table Schema

An external table stores a reusable SQL schema definition over files in the lake.

The external table does not store the data.

It points to the data.

### Logical Rules vs Engine Enforcement

The project documentation may describe certain columns as logically required.

However, Synapse Serverless external tables do not use `NOT NULL` constraints in the same way as regular SQL Server tables.

Business requirements such as required keys, valid statuses, and non-negative amounts should be validated with queries.

---

## 5. Exercise Structure

Use the companion script:

```text
attempts/03_schema_on_read_attempt.sql
```

The script is divided into these sections:

| Section | Goal |
|---|---|
| 01 | Confirm database context |
| 02 | Create a `lab` schema for safe practice objects |
| 03 | Query customers with inferred schema |
| 04 | Query customers with explicit schema |
| 05 | Inspect existing external table metadata |
| 06 | Create a lab external table without `NOT NULL` |
| 07 | Query the lab external table |
| 08 | Compare lab external table with production external table |
| 09 | Validate logical constraints with SQL queries |
| 10 | Review optional commented failure examples |
| 11 | Final validation |

---

## 6. Tasks

### Task 1 — Confirm Context

Confirm you are connected to:

```text
SQL pool: Built-in
Database: synapse_serving_demo
```

The script should return the current database and timestamp.

---

### Task 2 — Query with Inferred Schema

Use `OPENROWSET` over:

```text
curated/retail/customers/*.parquet
```

Do not provide a `WITH` clause in the first read.

This lets Synapse infer the schema from Parquet metadata.

Expected row count:

```text
10
```

---

### Task 3 — Query with Explicit Schema

Use `OPENROWSET` again, but this time define the schema with a `WITH` clause.

The customer schema should include:

```text
customer_id
customer_name
email
city
state_code
customer_segment
created_at
updated_at
```

Expected row count:

```text
10
```

---

### Task 4 — Inspect External Table Metadata

Inspect the external table metadata for:

```text
ext.customers
```

Focus on:

- Column names
- Data types
- Character column collation
- Nullability metadata

Important lesson:

```text
Metadata inspection is separate from distributed file querying.
```

Do not mix `sys.*` metadata views and external-data scans inside the same validation query.

---

### Task 5 — Create a Practice External Table

Create this lab table:

```text
lab.customers_schema_on_read
```

It should point to the same folder as `ext.customers`:

```text
curated/retail/customers/
```

Use:

```text
DATA_SOURCE = ds_adls_synapse_serving
FILE_FORMAT = ff_parquet
```

Do not use `NOT NULL` in the external table DDL.

---

### Task 6 — Compare External Tables

Compare:

```text
ext.customers
lab.customers_schema_on_read
```

Expected result:

```text
Both tables return 10 rows.
```

---

### Task 7 — Validate Logical Rules with SQL

Since external tables do not enforce all constraints, validate the logical contract with SQL queries.

For customers, validate:

| Check | Expected Result |
|---|---:|
| Null `customer_id` | 0 |
| Duplicate `customer_id` | 0 |
| Null `customer_name` | 0 |
| Null `city` | 0 |
| Null `customer_segment` | 0 |

---

## 7. Acceptance Criteria

This module is complete when:

1. You can explain schema-on-read.
2. You can query Parquet with inferred schema.
3. You can query Parquet with explicit schema.
4. You can inspect external table metadata.
5. You can create a safe lab external table.
6. You understand why external table DDL should not use `NOT NULL` in this project.
7. You validate logical constraints using SQL queries.
8. The final validation returns:

```text
status = PASS
```

---

## 8. Expected Final Result

The final validation should return:

```text
openrowset_explicit_count = 10
external_customers_count = 10
lab_customers_count = 10
null_customer_id_count = 0
duplicate_customer_id_count = 0
schema_on_read_status = PASS
```

---

## 9. Interview Defense Notes

### How would you explain schema-on-read?

Schema-on-read means the data remains in files, and the SQL engine applies a schema when the query runs. In Synapse Serverless, external tables and `OPENROWSET` define how lake files should be interpreted at query time.

### Why is Parquet useful here?

Parquet is columnar and carries schema metadata. That makes it efficient and convenient for analytical queries over files.

### Why use an explicit schema if Parquet can infer one?

Explicit schemas make the query contract clearer and more stable. They also help document what the serving layer expects consumers to query.

### Why do external tables not replace data quality checks?

External tables describe how to read files, but they do not enforce the full business contract. Required keys, allowed statuses, non-negative values, and referential integrity still need to be checked with SQL validations or upstream data quality processes.

### What was the key project lesson from the `NOT NULL` issue?

The logical data contract can say a column is required, but the external table DDL may not enforce that rule. In this project, the correct pattern is to keep the external table schema compatible with Synapse Serverless and validate required values with quality queries.

---

## 10. Common Mistakes

| Mistake | Why It Matters |
|---|---|
| Running the lab against `master` | The project objects live in `synapse_serving_demo` |
| Adding `NOT NULL` to external table columns | Synapse Serverless external table DDL can reject this syntax |
| Assuming schema equals data quality | Schema-on-read does not enforce the full business contract |
| Mixing `sys.*` metadata and external table scans in one distributed query | Serverless SQL can reject unsupported distributed query combinations |
| Treating external tables as physically stored SQL tables | External tables point to files; they do not store the data |

---

## 11. Completion Note

After completing this module, you should be able to explain the core mental model of Synapse Serverless SQL:

```text
ADLS files remain in the lake.
Synapse applies schema at query time.
External tables make that schema reusable.
Data quality still needs explicit validation.
```
