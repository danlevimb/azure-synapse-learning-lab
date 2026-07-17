# Lab Scope

**Repository:** `azure-synapse-learning-lab`  
**Companion portfolio project:** `azure-synapse-serverless-serving-layer`  
**Status:** Phase 0 — Lab Foundation  
**Purpose:** Private Synapse Serverless SQL dojo

## 1. Purpose

This lab exists to build practical fluency with Azure Synapse Serverless SQL.

The companion portfolio project proves that a polished SQL serving layer can be implemented over curated Parquet files in Azure Data Lake Storage Gen2.

This learning lab reinforces the concepts behind that project through repeated practice, guided exercises, attempt scripts, troubleshooting, and interview-defense questions.

The goal is not only to say:

```text
I built a Synapse Serverless SQL serving layer.
```

The goal is to be able to say:

```text
I understand how Synapse Serverless SQL reads files from ADLS Gen2, how external tables differ from OPENROWSET, how schema-on-read behaves, how CETAS works, how to validate data quality from SQL, and how to control cost by reducing scanned data.
```

## 2. Companion Project Boundary

The companion public project is:

```text
azure-synapse-serverless-serving-layer
```

That repository should remain polished, recruiter-facing, and evidence-backed.

It contains:

- Final SQL scripts
- Professional documentation
- Clean evidence
- Project closeout notes
- Public-safe implementation artifacts

This lab repository is private and may contain:

- Practice exercises
- Attempt scripts
- Scratch work
- Controlled failures
- Troubleshooting notes
- Interview-defense answers
- Repetition drills

## 3. Strategic Roadmap Rule

Starting with this project, every public portfolio project should have a companion learning lab / dojo.

The working pattern is:

| Repository Type | Purpose |
|---|---|
| Public portfolio project | Clean implementation, documentation, evidence, recruiter-facing narrative |
| Private learning lab | Practice, repetition, failed attempts, troubleshooting, interview-defense fluency |

This pattern helps separate polished portfolio artifacts from the private work required to build real technical muscle.

## 4. Current Environment Reuse

The lab can reuse the Azure resources created during the portfolio project to avoid unnecessary cost and duplication.

Current project environment:

```text
Synapse Workspace: syn-sqlserving-dev-mxc-001
Storage Account: synapselabdan
Container / File system: synapse-serving
Database: synapse_serving_demo
```

No new Synapse workspace, Dedicated SQL Pool, Spark Pool, or extra storage account is required for the first version of this lab.

## 5. Safety Boundary

The lab should avoid modifying the final polished project objects unless explicitly required.

Read-only practice can use existing objects:

```text
ext.customers
ext.products
ext.orders
ext.order_items
rpt.vw_sales_by_date
rpt.vw_sales_by_customer
rpt.vw_sales_by_product
rpt.vw_sales_by_city
rpt.vw_order_status_summary
rpt.sales_by_date_cetas
audit views or data quality queries
```

Experimental objects should use lab-oriented naming such as:

```text
lab
scratch
sandbox
```

Recommended schemas for lab practice:

```sql
CREATE SCHEMA lab;
CREATE SCHEMA scratch;
```

## 6. Lab Module Sequence

The lab is organized into eight practical modules.

| Module | Topic | Main Skill |
|---:|---|---|
| 01 | Serverless SQL Basics | Understand the Built-in serverless SQL pool and simple validation queries |
| 02 | OPENROWSET vs External Tables | Compare ad hoc file querying with reusable SQL objects |
| 03 | Schema-on-Read and External Tables | Rebuild external table logic and understand schema behavior |
| 04 | Reporting Views | Build analytical views over external tables |
| 05 | Data Quality with SQL | Validate row counts, duplicates, orphan records, invalid values, and totals |
| 06 | CETAS Outputs | Materialize a query result back to ADLS Gen2 |
| 07 | Cost-Aware Querying | Practice query design that reduces scanned data |
| 08 | Troubleshooting Playbook | Diagnose common Synapse Serverless SQL issues |

## 7. Attempt Script Sequence

Each practical module from 01 through 07 should include an attempt script.

```text
attempts/01_serverless_sql_basics_attempt.sql
attempts/02_openrowset_vs_external_tables_attempt.sql
attempts/03_schema_on_read_attempt.sql
attempts/04_reporting_views_attempt.sql
attempts/05_data_quality_attempt.sql
attempts/06_cetas_attempt.sql
attempts/07_cost_controls_attempt.sql
```

Module 08 is a troubleshooting playbook and may use multiple small snippets instead of one formal attempt script.

## 8. Exercise Standard

Each module should include:

- Objective
- Why it matters
- Prerequisites
- Exercise instructions
- Attempt script path
- Expected result
- Acceptance criteria
- Common mistakes
- Interview-defense questions
- Completion checklist

Each attempt should end with an explicit validation output whenever possible:

```text
status = PASS
```

## 9. Cost Strategy

The lab should remain cost-aware.

Rules:

- Use the existing Serverless SQL pool only.
- Do not create a Dedicated SQL Pool.
- Do not create a Spark Pool.
- Keep datasets small.
- Prefer Parquet for repeated analytical queries.
- Avoid unnecessary `SELECT *` scans.
- Use `TOP` for preview queries.
- Use focused columns in analytical queries.
- Reuse existing ADLS files when possible.
- Clean up experimental CETAS output folders when rerunning exercises.

## 10. What This Lab Should Build

By the end of this lab, the user should be able to explain and practice:

- What Synapse Serverless SQL is
- Why it is useful as a serving layer
- How it reads ADLS files
- How `OPENROWSET` differs from external tables
- What schema-on-read means
- How external data sources and file formats work
- How to expose Parquet files as SQL tables
- How to create reporting views over external tables
- How to validate data quality from SQL
- How CETAS writes query results back to ADLS
- Why CETAS paths must be managed carefully
- How serverless SQL cost is related to data processed
- Why metadata queries and external data queries may need to be separated
- How to defend MVP limitations honestly in interviews

## 11. Success Criteria

The lab is successful when:

1. The repo is created as a private learning lab.
2. The scope and module sequence are documented.
3. Each module has a guided lab note.
4. Each practical module has an attempt script.
5. Exercises can be run against the existing Synapse/ADLS environment.
6. Attempt scripts produce clear validation outputs.
7. Troubleshooting notes capture real issues discovered during execution.
8. The user can explain the difference between a polished portfolio project and the private practice required to master it.

## 12. Immediate Next Action

Create the private GitHub repository:

```text
azure-synapse-learning-lab
```

Then add this file:

```text
labs/00_lab_scope.md
```

After the lab foundation is committed, start Module 01:

```text
labs/01_serverless_sql_basics.md
attempts/01_serverless_sql_basics_attempt.sql
```
