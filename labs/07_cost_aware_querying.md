# Lab 07 — Cost-Aware Querying

**Repository:** `azure-synapse-learning-lab`  
**Module:** 07  
**Topic:** Cost-aware querying  
**Target engine:** Azure Synapse Serverless SQL  
**Database:** `synapse_serving_demo`  
**Recommended SQL pool:** Built-in / Serverless  

---

## 1. Objective

Practice cost-aware query habits in Azure Synapse Serverless SQL.

This lab focuses on how to think about cost when querying files from a Data Lake using serverless SQL.

By the end of this lab, you should be able to explain:

- Why Serverless SQL is cost-aware but not cost-free.
- Why query design matters when reading files from ADLS Gen2.
- Why Parquet is preferred over raw CSV for analytical querying.
- Why selecting only required columns is a better habit than `SELECT *`.
- Why folder structure and file format influence data scanned.
- Why Dedicated SQL Pools and Spark Pools are outside the MVP scope.
- Why Synapse Serverless metadata checks and external data checks should sometimes be separated.
- How to use Synapse Studio query details to observe processed data.
- How to explain cost controls in an interview.

---

## 2. Context

The portfolio project uses Azure Synapse Serverless SQL to expose curated Parquet datasets stored in ADLS Gen2.

The current environment has:

```text
ADLS Gen2 curated Parquet files
External data source
External file format
External tables
Reporting views
Data quality checks
CETAS output
```

The project intentionally avoids:

```text
Dedicated SQL Pool
Spark Pool
Always-on compute
Large datasets
Unnecessary scans
```

The goal is to keep the project aligned with the MVP:

```text
Query curated lake data through SQL while keeping cost and scope controlled.
```

---

## 3. Cost Principle

Serverless SQL does not require you to provision a dedicated SQL compute pool.

However, serverless queries still process data.

A good engineer should ask:

```text
How much data am I making the engine read to answer this question?
```

Good query habits include:

- Read only the columns needed.
- Prefer Parquet for analytical workloads.
- Avoid unnecessary `SELECT *`.
- Avoid scanning all datasets just to validate one question.
- Use small datasets for MVP learning.
- Keep CETAS outputs small and purposeful.
- Avoid creating Dedicated SQL Pools unless the project explicitly needs them.
- Avoid creating Spark Pools unless Spark processing is part of scope.

---

## 4. Important Synapse Serverless Behavior

Synapse Serverless can be picky when the same statement mixes:

```text
system catalog metadata objects, such as sys.external_tables or sys.sql_modules
```

with:

```text
external data processing over ext.* or rpt.* objects
```

For that reason, this lab intentionally separates:

```text
Metadata-only checks
External-data checks
Checklist-style controls
```

This is the same operational lesson learned during CETAS validation.

---

## 5. What This Lab Does

This lab is read-only.

It does not create or drop objects.

It runs:

| Check Type | Purpose |
|---|---|
| Metadata checks | Validate Parquet format, external tables, reporting views, and obvious `SELECT *` usage |
| External data checks | Validate small dataset size and targeted analytical query behavior |
| Cost checklist | Document design controls such as serverless-only and no Spark Pool required |

---

## 6. What You Should Observe Manually

After running selected queries in Synapse Studio, inspect the query execution details.

Look for information such as:

```text
Data processed
Duration
Query status
```

The important habit is:

```text
Do not only ask whether the query ran.
Ask how much data the query processed.
```

---

## 7. Execution Instructions

Open Synapse Studio and run:

```text
attempts/07_cost_controls_attempt.sql
```

Use:

```text
SQL pool: Built-in
Database: synapse_serving_demo
```

---

## 8. Expected Final Results

Because metadata and external-data checks are intentionally separated, the script returns two final PASS statuses:

```text
metadata_cost_awareness_status = PASS
external_data_cost_awareness_status = PASS
```

Expected supporting checks:

```text
parquet_format_status = PASS
external_table_status = PASS
reporting_view_status = PASS
select_star_status = PASS
dataset_size_status = PASS
targeted_query_status = PASS
```

---

## 9. Interview Defense Notes

### How would you explain cost-aware querying in Synapse Serverless?

A strong answer:

```text
In Synapse Serverless SQL, I do not manage a dedicated compute pool for this project, but queries still process data from storage. That means query design matters. I use Parquet, external tables, curated reporting views, explicit column selection, small controlled datasets, and focused analytical queries to reduce unnecessary scans. I also avoid Dedicated SQL Pools and Spark Pools because they are outside the MVP scope and could introduce unnecessary cost.
```

### Why separate metadata checks from external data checks?

A strong answer:

```text
Synapse Serverless uses distributed processing for external lake data. Some system catalog metadata objects are not supported inside the same distributed query shape. To keep scripts reliable, I separate metadata validation from external data validation.
```

### Why is Parquet helpful?

Parquet is columnar, so analytical queries can be more efficient when they only need a subset of columns.

### Why avoid `SELECT *`?

`SELECT *` is convenient for exploration, but it is a poor default for repeatable analytical queries because it may read unnecessary columns and makes the query contract less explicit.

### Why not create a Dedicated SQL Pool?

The objective of this project is serverless SQL over lake files. Dedicated SQL Pools are a different architecture and can introduce provisioned compute cost and extra operational scope.

---

## 10. Common Mistakes

Avoid:

- Thinking serverless means free.
- Creating Dedicated SQL Pools by accident.
- Creating Spark Pools when the lab only needs serverless SQL.
- Running `SELECT *` as the default pattern.
- Querying all tables when one table answers the question.
- Materializing CETAS outputs without a clear purpose.
- Re-running CETAS into the same existing output folder.
- Ignoring the query details panel in Synapse Studio.
- Mixing `sys.*` metadata checks and external data checks inside the same distributed statement.

---

## 11. Completion Criteria

This lab is complete when:

1. `attempts/07_cost_controls_attempt.sql` runs successfully.
2. `metadata_cost_awareness_status = PASS`.
3. `external_data_cost_awareness_status = PASS`.
4. You review at least one query's execution details in Synapse Studio.
5. You can explain why the project uses Serverless SQL, Parquet, external tables, views, and small datasets.
6. You can explain why Dedicated SQL Pools and Spark Pools are intentionally excluded from the MVP.
