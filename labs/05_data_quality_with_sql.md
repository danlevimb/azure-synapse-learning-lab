# Lab 05 — Data Quality with SQL

**Repository:** `azure-synapse-learning-lab`  
**Module:** 05  
**Topic:** Data Quality with SQL  
**Target engine:** Azure Synapse Serverless SQL  
**Database:** `synapse_serving_demo`  
**Recommended SQL pool:** Built-in / Serverless  

---

## 1. Objective

Practice how to validate curated lake data using SQL in Azure Synapse Serverless.

This lab reinforces the idea that a SQL serving layer is not only for reporting. It can also expose validation checks that help confirm whether the data is safe enough for analytical consumption.

By the end of this lab, you should be able to explain:

- How to validate row counts from external tables.
- How to detect duplicate business keys.
- How to detect orphan records across external tables.
- How to validate allowed status values.
- How to detect negative monetary values.
- How to validate `line_total = quantity * unit_price`.
- How to compare order header totals against line-level totals.
- Why data quality rules should be explicit when using schema-on-read.

---

## 2. Context

The portfolio project `azure-synapse-serverless-serving-layer` already created external tables over curated Parquet files:

```text
ext.customers
ext.products
ext.orders
ext.order_items
```

Those tables are schema-on-read objects over files in ADLS Gen2.

That means the external table definition describes how Synapse should read the files, but many business rules are not enforced by the external table itself.

For example:

```text
customer_id should not be null
order_id should be unique
order_status should belong to an allowed list
line_total should equal quantity * unit_price
```

Those are data quality rules, not physical constraints enforced by the external table DDL.

---

## 3. What This Lab Builds

This lab creates one practice view in the `lab` schema:

```text
lab.vw_data_quality_checks_attempt
```

The view returns one row per validation rule.

Each row includes:

| Column | Description |
|---|---|
| `check_name` | Name of the validation |
| `check_category` | Logical group of the validation |
| `failed_record_count` | Number of records that failed the rule |
| `severity` | Severity level |
| `status` | `PASS` or `FAIL` |
| `validation_message` | Human-readable explanation |

The lab also runs a final summary query that returns:

```text
data_quality_status = PASS
```

when all validation checks pass.

---

## 4. Lab Safety

This lab is safe to run multiple times.

It only creates or replaces objects in the `lab` schema.

It does not modify:

```text
ext.*
rpt.*
audit.*
```

It does not write to ADLS.

It does not create CETAS output.

It does not create Dedicated SQL Pools or Spark Pools.

---

## 5. Checks Included

The lab validates:

| Check | Expected Failed Count |
|---|---:|
| Duplicate customer IDs | 0 |
| Duplicate product IDs | 0 |
| Duplicate order IDs | 0 |
| Duplicate order item IDs | 0 |
| Orders without matching customer | 0 |
| Order items without matching order | 0 |
| Order items without matching product | 0 |
| Negative order totals | 0 |
| Negative line totals | 0 |
| Invalid order statuses | 0 |
| Invalid payment statuses | 0 |
| Line total mismatches | 0 |
| Order total mismatches | 0 |

---

## 6. Execution Instructions

Open Synapse Studio and run:

```text
attempts/05_data_quality_attempt.sql
```

Use:

```text
SQL pool: Built-in
Database: synapse_serving_demo
```

---

## 7. Expected Final Result

The last result set should show:

```text
data_quality_status = PASS
```

The view should show all checks with:

```text
failed_record_count = 0
status = PASS
```

---

## 8. Interview Defense Notes

### How would you explain this lab?

A strong answer:

```text
This lab validates curated lake data from a SQL serving layer using Synapse Serverless SQL. Because external tables are schema-on-read and do not enforce relational constraints like a traditional OLTP database, I created explicit SQL checks for duplicates, orphan records, invalid statuses, negative values, and total mismatches. The output behaves like a lightweight data quality report that can be used during validation, troubleshooting, or operational review.
```

### Why are these checks important?

Because analytical users depend on the serving layer to produce trustworthy results.

If there are orphan records, invalid statuses, or mismatched totals, the reporting views may still run, but the business output may be wrong.

### Why not enforce everything with `NOT NULL` or primary keys?

In this project, the tables are external tables over Parquet files in ADLS Gen2. Synapse Serverless reads those files using schema-on-read. Business rules should be documented and validated explicitly through SQL checks.

### What is the professional signal?

This lab shows that the engineer thinks beyond making queries run. It shows concern for correctness, trust, auditability, and defensible analytical consumption.

---

## 9. Common Mistakes

Avoid:

- Assuming external tables enforce all business rules.
- Confusing schema definition with data quality validation.
- Only checking row counts and ignoring relationships.
- Forgetting orphan checks.
- Ignoring status domain validation.
- Comparing financial values without rounding.
- Hardcoding assumptions that are not documented.
- Running validation in the wrong database context.

---

## 10. Completion Criteria

This lab is complete when:

1. `attempts/05_data_quality_attempt.sql` runs successfully.
2. `lab.vw_data_quality_checks_attempt` is created.
3. All validation checks return `PASS`.
4. The final summary returns `data_quality_status = PASS`.
5. You can explain why data quality is explicit in a schema-on-read serving layer.
