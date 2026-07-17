# Lab 06 — CETAS Outputs

**Repository:** `azure-synapse-learning-lab`  
**Module:** 06  
**Topic:** CETAS outputs  
**Target engine:** Azure Synapse Serverless SQL  
**Database:** `synapse_serving_demo`  
**Recommended SQL pool:** Built-in / Serverless  

---

## 1. Objective

Practice how to use CETAS in Azure Synapse Serverless SQL.

CETAS means:

```text
CREATE EXTERNAL TABLE AS SELECT
```

It allows Synapse Serverless SQL to write the result of a SQL query back to Azure Data Lake Storage Gen2 as files.

By the end of this lab, you should be able to explain:

- What CETAS does.
- Why CETAS is useful in a SQL serving layer.
- How CETAS differs from a normal view.
- Why CETAS creates physical files in ADLS Gen2.
- Why CETAS output paths must be managed carefully.
- How to validate a CETAS output without mixing metadata queries and external data queries in the same distributed statement.

---

## 2. Context

The portfolio project already created a CETAS output for the public serving layer.

This lab repeats the pattern in a controlled practice area.

The goal is not only to run CETAS once.

The goal is to understand the operational behavior:

```text
SQL query result → External table metadata → Parquet output files in ADLS Gen2
```

---

## 3. What This Lab Builds

This lab creates one practice CETAS external table:

```text
lab.sales_by_city_cetas_attempt
```

The external table writes Parquet output into ADLS Gen2 using this folder pattern:

```text
lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/
```

The output summarizes revenue by city and state.

---

## 4. Lab Safety

This lab does not modify:

```text
ext.*
rpt.*
audit.*
```

It creates or drops only:

```text
lab.sales_by_city_cetas_attempt
```

It writes files only under:

```text
lab/outputs/
```

This lab does not create Dedicated SQL Pools.

This lab does not create Spark Pools.

---

## 5. Important CETAS Behavior

### CETAS Does Not Overwrite Existing Folders

If the output location already contains files, CETAS may fail.

For example, this location must be empty before the table is created:

```text
lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/
```

If you need to re-run the lab, use one of these options:

1. Delete the output folder in ADLS Gen2 before running again.
2. Change the `run_id` in the script, for example:

```text
run_id=lab_06_manual_002/
```

### Dropping the External Table Does Not Delete ADLS Files

This command removes table metadata:

```sql
DROP EXTERNAL TABLE lab.sales_by_city_cetas_attempt;
```

But it does not delete the physical Parquet files from ADLS.

This is important for cleanup and cost hygiene.

### Metadata Validation Should Be Separate

Synapse Serverless can be picky when system catalog metadata and external file processing are mixed in the same distributed query.

For this reason, the validation script separates:

```text
metadata checks
row count checks
business metric checks
preview queries
```

---

## 6. Execution Instructions

Open Synapse Studio and run:

```text
attempts/06_cetas_attempt.sql
```

Use:

```text
SQL pool: Built-in
Database: synapse_serving_demo
```

---

## 7. Expected Output

The script should create:

```text
lab.sales_by_city_cetas_attempt
```

The output location should contain Parquet files under:

```text
lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/
```

The final validation should show:

```text
cetas_business_validation_status = PASS
```

---

## 8. Expected Result Columns

The CETAS table should include:

| Column | Description |
|---|---|
| `city` | Customer city |
| `state_code` | State or region code |
| `order_count` | Number of distinct orders |
| `total_quantity` | Total quantity sold |
| `total_revenue` | Total completed or paid revenue |

---

## 9. Interview Defense Notes

### How would you explain CETAS?

A strong answer:

```text
CETAS lets Synapse Serverless SQL materialize the result of a query as files in ADLS Gen2 while registering an external table over that output. In this project, it demonstrates how a SQL serving layer can not only query curated lake files but also publish curated analytical outputs back to the lake.
```

### How is CETAS different from a view?

A view stores only query logic.

CETAS writes physical files.

That means CETAS can be useful for creating reusable outputs, snapshots, extracts, or downstream serving datasets.

### What is the operational caution?

CETAS does not behave like overwrite by default.

The output location must be managed carefully. Dropping the external table removes metadata, not the physical files.

### Why is this relevant professionally?

Because real data engineering work often involves publishing curated outputs, not just querying source data. CETAS shows how SQL can participate in a lake-based serving architecture.

---

## 10. Common Mistakes

Avoid:

- Reusing a CETAS output folder that already contains files.
- Assuming `DROP EXTERNAL TABLE` deletes lake files.
- Mixing system catalog metadata checks and external data checks in one complex distributed query.
- Creating CETAS outputs in the same folders used by the public portfolio project.
- Forgetting to validate row counts and business totals.
- Creating Dedicated SQL Pools for a serverless SQL lab.

---

## 11. Completion Criteria

This lab is complete when:

1. `attempts/06_cetas_attempt.sql` runs successfully.
2. `lab.sales_by_city_cetas_attempt` is created.
3. The output Parquet files exist under the `lab/outputs/` path.
4. Row count validation passes.
5. Business metric validation passes.
6. The final status returns `PASS`.
7. You can explain CETAS behavior, limitations, and cleanup implications.
