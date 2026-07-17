# Synapse Learning Lab — Module Index

**Repository:** `azure-synapse-learning-lab`  
**Status:** Completed / Private Learning Lab Closed  
**Related portfolio project:** `azure-synapse-serverless-serving-layer`

---

## 1. Purpose

This document summarizes the completed module sequence for the `azure-synapse-learning-lab`.

The lab exists as a private dojo to reinforce practical fluency with Azure Synapse Serverless SQL after building the public portfolio project.

The goal is not only to run finished scripts.

The goal is to practice, validate, troubleshoot, and defend the concepts behind a SQL serving layer over curated Data Lake assets.

---

## 2. Module Sequence

| Module | Lab Document | Attempt Script | Status |
|---:|---|---|---|
| 00 | `labs/00_lab_scope.md` | N/A | Completed |
| 01 | `labs/01_serverless_sql_basics.md` | `attempts/01_serverless_sql_basics_attempt.sql` | Completed |
| 02 | `labs/02_openrowset_vs_external_tables.md` | `attempts/02_openrowset_vs_external_tables_attempt.sql` | Completed |
| 03 | `labs/03_schema_on_read_and_external_table_schemas.md` | `attempts/03_schema_on_read_attempt.sql` | Completed |
| 04 | `labs/04_reporting_views.md` | `attempts/04_reporting_views_attempt.sql` | Completed |
| 05 | `labs/05_data_quality_with_sql.md` | `attempts/05_data_quality_attempt.sql` | Completed |
| 06 | `labs/06_cetas_outputs.md` | `attempts/06_cetas_attempt.sql` | Completed |
| 07 | `labs/07_cost_aware_querying.md` | `attempts/07_cost_controls_attempt.sql` | Completed |
| 08 | `labs/08_troubleshooting_playbook.md` | N/A | Completed |

---

## 3. Lab Topics Covered

The lab covered:

- Serverless SQL basics.
- Database context validation.
- External data source validation.
- External file format validation.
- External table validation.
- `OPENROWSET` vs external tables.
- Schema-on-read behavior.
- External table schema design.
- Reporting views.
- Data quality validation with SQL.
- CETAS outputs.
- Cost-aware querying.
- Troubleshooting patterns.
- Interview defense notes.

---

## 4. Key Technical Lessons

### Serverless SQL Is a Query Layer Over Lake Files

Synapse Serverless SQL can expose curated Data Lake files through SQL objects without creating a Dedicated SQL Pool.

### External Tables Are Schema-on-Read

External tables define how files are read.

They do not behave like fully constrained OLTP tables.

Business rules should be validated explicitly.

### `NOT NULL` Is a Logical Contract, Not External Table DDL

The source data model can document non-null expectations.

The external table DDL should remain compatible with Synapse Serverless external table behavior.

### Metadata and External Data Checks Should Be Separated

Synapse Serverless can fail when a single distributed query mixes `sys.*` metadata objects with external data queries over `ext.*`, `rpt.*`, or `lab.*`.

The safer pattern is:

```text
metadata checks
external-data checks
business validation checks
preview queries
```

### CETAS Writes Physical Files

CETAS creates external table metadata and writes output files to ADLS Gen2.

Dropping the external table does not delete the files.

Output paths must be managed intentionally.

### Cost Awareness Matters

Serverless SQL avoids provisioned compute for this project, but queries still process data.

Good habits include:

- Use Parquet.
- Use small controlled datasets.
- Avoid unnecessary `SELECT *`.
- Select only required columns.
- Avoid creating Dedicated SQL Pools.
- Avoid creating Spark Pools unless Spark is in scope.

---

## 5. Completion Signal

The lab is considered complete when:

1. All module files are committed.
2. All attempt scripts from modules 01 through 07 have been executed successfully.
3. Lab 08 troubleshooting playbook has been reviewed.
4. The repository has a clean working tree.
5. The user can explain the main Synapse Serverless patterns without relying only on copied scripts.

---

## 6. Related Portfolio Repository

The public portfolio implementation lives in:

```text
azure-synapse-serverless-serving-layer
```

That repository contains the recruiter-facing project implementation, documentation, evidence, and final scripts.

This repository is the private practice dojo used to build confidence and muscle behind the public project.
