# Lab 02 — OPENROWSET vs External Tables

**Repo:** `azure-synapse-learning-lab`  
**Module:** `02_openrowset_vs_external_tables`  
**Status:** Practice module  
**Recommended engine:** Synapse Serverless SQL — `Built-in`  
**Recommended database:** `synapse_serving_demo`

---

## 1. Objective

Practice the two main ways to query files from Synapse Serverless SQL:

1. Direct file access with `OPENROWSET`.
2. Reusable SQL access through external tables.

By the end of this lab, you should be able to explain when you would use `OPENROWSET`, when you would use external tables, and why external tables are better for a stable serving layer.

---

## 2. Why This Matters

The portfolio project already created external tables over curated Parquet files.

This lab goes one level deeper.

Instead of only asking:

```text
Can Synapse count rows from external tables?
```

this module asks:

```text
Can I query the lake directly, compare that behavior with external tables, and explain the difference?
```

This matters because real projects often start with exploratory file access and then evolve into stable SQL objects for downstream consumers.

---

## 3. Starting Point

This lab assumes the portfolio project environment already exists.

Expected objects:

```text
Database:
  synapse_serving_demo

External data source:
  ds_adls_synapse_serving

External file format:
  ff_parquet

External tables:
  ext.customers
  ext.products
  ext.orders
  ext.order_items

Reporting view example:
  rpt.vw_sales_by_date
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

### `OPENROWSET`

`OPENROWSET` lets you query files directly from the lake.

It is useful for:

- Quick exploration.
- Testing file access.
- Inspecting new folders.
- Reading data without creating permanent SQL objects.

Tradeoff:

- Queries can become repetitive.
- Consumers need to know file paths.
- It is less clean for a reusable serving layer.

### External Tables

External tables expose files as SQL table objects.

They are useful for:

- Stable serving layers.
- Reusable SQL objects.
- Cleaner analytical views.
- Easier documentation.
- Hiding lake folder paths from consumers.

Tradeoff:

- They require upfront DDL.
- Schema must be defined correctly.
- Serverless external tables do not enforce constraints such as `NOT NULL`.

---

## 5. Exercise Structure

Use the companion script:

```text
attempts/02_openrowset_vs_external_tables_attempt.sql
```

The script is divided into these sections:

| Section | Goal |
|---|---|
| 01 | Confirm database context |
| 02 | Query customers directly with `OPENROWSET` |
| 03 | Query orders directly with `OPENROWSET` |
| 04 | Compare `OPENROWSET` row counts vs external table row counts |
| 05 | Compare revenue totals from direct lake reads vs external tables |
| 06 | Preview external tables |
| 07 | Explain when to use each pattern |
| 08 | Final validation |

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

### Task 2 — Read Customers with `OPENROWSET`

Use `OPENROWSET` to read the customer Parquet file directly from:

```text
curated/retail/customers/*.parquet
```

Use the existing external data source:

```text
ds_adls_synapse_serving
```

Expected row count:

```text
10
```

---

### Task 3 — Read Orders with `OPENROWSET`

Read the orders Parquet file directly from:

```text
curated/retail/orders/*.parquet
```

Expected row count:

```text
24
```

---

### Task 4 — Compare Direct Lake Reads vs External Tables

Compare row counts for:

```text
customers
products
orders
order_items
```

Expected result:

```text
OPENROWSET counts = External table counts
```

Expected row counts:

| Dataset | Expected Count |
|---|---:|
| customers | 10 |
| products | 10 |
| orders | 24 |
| order_items | 43 |

---

### Task 5 — Compare Revenue Totals

Compare total revenue calculated from direct file access against total revenue calculated from external tables.

Expected result:

```text
direct_total_revenue = external_table_total_revenue
```

This proves that both query patterns are reading the same curated files.

---

### Task 6 — Preview External Tables

Preview data from:

```text
ext.customers
ext.products
ext.orders
ext.order_items
```

Focus on recognizing the serving-layer pattern:

```text
files in ADLS → external tables → SQL consumers
```

---

## 7. Acceptance Criteria

This module is complete when:

1. You can query Parquet files directly with `OPENROWSET`.
2. You can query the same data through external tables.
3. Row counts match between both patterns.
4. Revenue totals match between both patterns.
5. You can explain the tradeoff between direct file reads and stable external SQL objects.
6. The final validation returns:

```text
status = PASS
```

---

## 8. Expected Final Result

The final validation should return:

```text
customers_match = 1
products_match = 1
orders_match = 1
order_items_match = 1
revenue_match = 1
status = PASS
```

---

## 9. Interview Defense Notes

### How would you explain `OPENROWSET`?

`OPENROWSET` is useful for querying files directly from storage without first creating a permanent table object. I would use it for exploration, validation, or ad hoc checks.

### How would you explain external tables?

External tables provide a reusable SQL object over files stored in the lake. They are better for a serving layer because downstream users can query tables and views without knowing the physical file paths.

### When would you use `OPENROWSET`?

For quick exploration, first-time validation, testing file paths, checking schemas, or inspecting new datasets.

### When would you use external tables?

For stable SQL consumption, reporting views, documentation, and reusable query surfaces.

### What is the key production lesson?

A serving layer should hide physical storage complexity behind stable SQL objects. `OPENROWSET` is excellent for exploration, but external tables and views are better for a documented consumption layer.

---

## 10. Common Mistakes

| Mistake | Why It Matters |
|---|---|
| Running queries against `master` | The project objects live in `synapse_serving_demo` |
| Hardcoding full storage URLs unnecessarily | The external data source already abstracts the ADLS location |
| Assuming external tables enforce constraints | Serverless external tables are schema-on-read and do not enforce `NOT NULL` |
| Using external tables for every quick test | `OPENROWSET` is often faster for exploration |
| Using only `OPENROWSET` in a serving layer | It exposes file paths and makes queries harder to maintain |

---

## 11. Completion Note

After completing this module, you should understand that Synapse Serverless SQL supports two complementary patterns:

```text
OPENROWSET      → flexible direct file access
External tables → stable serving-layer access
```

The portfolio repo uses external tables because the goal is a recruiter-facing serving layer. The learning lab practices both so you can defend the design decision.
