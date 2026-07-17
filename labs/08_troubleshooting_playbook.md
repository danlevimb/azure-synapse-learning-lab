# Lab 08 — Troubleshooting Playbook

**Repository:** `azure-synapse-learning-lab`  
**Module:** 08  
**Topic:** Troubleshooting Playbook  
**Target engine:** Azure Synapse Serverless SQL  
**Database:** `synapse_serving_demo`  
**Recommended SQL pool:** Built-in / Serverless  

---

## 1. Objective

Create a practical troubleshooting playbook for Azure Synapse Serverless SQL.

This lab does not create a new attempt script.

Instead, it documents the real troubleshooting patterns discovered during the `azure-synapse-serverless-serving-layer` project and the `azure-synapse-learning-lab`.

By the end of this lab, you should be able to explain:

- How to diagnose Synapse workspace creation issues.
- How to validate Serverless SQL readiness.
- How to validate ADLS Gen2 permissions.
- How to troubleshoot external data sources.
- How to troubleshoot external file formats.
- How to troubleshoot external tables.
- Why `NOT NULL` is not appropriate in Synapse Serverless external table definitions.
- Why metadata queries over `sys.*` should be separated from distributed external-data queries.
- How to troubleshoot CETAS output conflicts.
- How to explain these issues in an interview without sounding lost.

---

## 2. Troubleshooting Mindset

Do not troubleshoot Synapse randomly.

Use a layer-by-layer approach:

```text
Azure resource exists
        ↓
Synapse Studio opens
        ↓
Built-in Serverless SQL responds
        ↓
Database context is correct
        ↓
ADLS Gen2 is visible
        ↓
Managed Identity has access
        ↓
External data source is correct
        ↓
External file format is correct
        ↓
External tables point to valid folders
        ↓
Views and queries return expected results
        ↓
CETAS writes to a clean output location
```

This order prevents jumping ahead and chasing fake errors.

---

## 3. Layer 1 — Synapse Workspace Creation

### Symptom

Workspace deployment fails with a message similar to:

```text
Location 'eastus' is not accepting creation of new Windows Azure SQL Database servers
for the subscription at this time.

SqlServerRegionDoesNotAllowProvisioning
```

### Likely Cause

The selected Azure region is not allowing SQL-related provisioning for the current subscription at that moment.

This is a regional capacity or provisioning limitation, not a mistake in the SQL scripts.

### Fix

Try a different region.

In this project, the successful region was:

```text
West US 2
```

### Lesson Learned

Do not assume every Azure region will accept every resource for every subscription.

For an MVP portfolio project, changing region is usually faster than opening a support ticket.

---

## 4. Layer 2 — Serverless SQL Readiness

### Symptom

You are not sure whether Synapse Serverless SQL is ready.

### Validation Query

Run this in Synapse Studio using the Built-in SQL pool:

```sql
SELECT
    'Synapse Serverless SQL is ready' AS validation_message,
    CURRENT_TIMESTAMP AS checked_at;
```

### Expected Result

```text
Synapse Serverless SQL is ready
```

### Lesson Learned

Before creating external objects, confirm that the Built-in Serverless SQL endpoint can run a simple query.

---

## 5. Layer 3 — Database Context

### Symptom

Scripts fail because objects cannot be found.

Examples:

```text
Invalid object name 'ext.customers'
External data source does not exist
External file format does not exist
Schema does not exist
```

### Likely Cause

The script is running against the wrong database, usually `master`.

### Fix

Select the correct database in Synapse Studio:

```text
synapse_serving_demo
```

Or include this at the top of scripts:

```sql
USE synapse_serving_demo;
GO
```

### Lesson Learned

Always validate the database context before running setup or lab scripts.

---

## 6. Layer 4 — ADLS Gen2 Visibility

### Symptom

Synapse Studio opens, but files or folders are not visible.

### Checks

In Synapse Studio:

```text
Data
→ Linked
→ synapse-serving
→ curated/
```

Expected folder:

```text
curated/retail/
```

Expected datasets:

```text
customers/
products/
orders/
order_items/
```

### Likely Cause

- Files were not uploaded.
- Files were uploaded to a different container.
- Folder structure does not match SQL script locations.
- Permission propagation is not complete.

### Fix

Confirm ADLS folder structure:

```text
synapse-serving/
└── curated/
    └── retail/
        ├── customers/
        ├── products/
        ├── orders/
        └── order_items/
```

---

## 7. Layer 5 — Managed Identity Permissions

### Symptom

External table queries fail with access errors.

### Likely Cause

The Synapse Workspace Managed Identity does not have sufficient permission on the Storage Account or container.

### Required Role for This Project

```text
Storage Blob Data Contributor
```

### Why Contributor?

Reader is enough for reading files.

However, the project also uses CETAS to write outputs back to ADLS Gen2.

CETAS requires write permission.

### Fix

In Azure Portal:

```text
Storage Account
→ Access Control (IAM)
→ Add role assignment
→ Storage Blob Data Contributor
→ Managed identity
→ Synapse workspace
→ syn-sqlserving-dev-mxc-001
```

### Lesson Learned

For read-only external tables, reader access may work.

For CETAS output, the workspace identity needs write capability.

---

## 8. Layer 6 — External Data Source

### Symptom

External tables fail because the data source is invalid.

### Validation Query

```sql
SELECT
    name AS external_data_source_name,
    location,
    type_desc
FROM sys.external_data_sources
WHERE name = 'ds_adls_synapse_serving';
```

### Expected Location Pattern

```text
abfss://synapse-serving@synapselabdan.dfs.core.windows.net
```

### Common Mistakes

- Wrong container name.
- Wrong storage account name.
- Using `blob.core.windows.net` when the project expects ADLS Gen2 DFS endpoint.
- Missing trailing path considerations.
- Running the script in the wrong database.

---

## 9. Layer 7 — External File Format

### Symptom

External tables cannot read files correctly.

### Validation Query

```sql
SELECT
    name AS external_file_format_name,
    format_type
FROM sys.external_file_formats
WHERE name = 'ff_parquet';
```

### Expected Result

```text
ff_parquet | PARQUET
```

### Lesson Learned

The file format is the SQL object that tells Synapse how to interpret the files.

For this project, the curated serving datasets use Parquet.

---

## 10. Layer 8 — External Table DDL

### Symptom

External table creation fails with syntax near `NOT`.

### Example Problem

```sql
customer_id int NOT NULL
```

### Cause

Synapse Serverless external table definitions should not use `NOT NULL` constraints in this scenario.

The external table is schema-on-read over files.

### Fix

Use:

```sql
customer_id int
```

instead of:

```sql
customer_id int NOT NULL
```

### Important Distinction

The logical model can still document:

```text
customer_id is required
```

But the external table DDL should not enforce it with `NOT NULL`.

The rule should be validated with SQL data quality checks.

### Interview Defense

A strong answer:

```text
In this project, external tables are schema-on-read objects over Parquet files in ADLS Gen2. I do not rely on external table DDL to enforce all business constraints. Instead, I define the read schema and validate required fields, uniqueness, relationships, and business rules through explicit data quality queries.
```

---

## 11. Layer 9 — External Table Location

### Symptom

External table is created, but row count is zero or query fails.

### Likely Cause

The `LOCATION` does not match the folder where Parquet files exist.

### Expected Locations

```text
curated/retail/customers/
curated/retail/products/
curated/retail/orders/
curated/retail/order_items/
```

### Smoke Test

```sql
SELECT COUNT(*) FROM ext.customers;
SELECT COUNT(*) FROM ext.products;
SELECT COUNT(*) FROM ext.orders;
SELECT COUNT(*) FROM ext.order_items;
```

Expected counts:

```text
customers    = 10
products     = 10
orders       = 24
order_items  = 43
```

---

## 12. Layer 10 — Metadata Queries vs External Data Queries

### Symptom

A query fails with:

```text
The query references an object that is not supported in distributed processing mode.
```

### Context

This happened when a single query mixed:

```text
sys.external_tables
sys.schemas
sys.sql_modules
```

with:

```text
ext.*
rpt.*
lab.*
```

### Cause

Synapse Serverless uses distributed processing for external data. Some metadata objects from `sys.*` are not supported in the same distributed query shape.

### Fix

Separate the script into independent statements:

```text
1. Metadata-only validation
2. External-data validation
3. Business metric validation
4. Preview query
```

### Bad Pattern

```text
One final CTE that combines sys.* metadata and external data row counts.
```

### Good Pattern

```text
Result set 1: metadata status
Result set 2: external data status
Result set 3: business validation status
```

### Lesson Learned

This became one of the most important real-world lessons in the lab:

```text
Metadata checks and external-data checks should often be separated in Synapse Serverless.
```

---

## 13. Layer 11 — Reporting Views

### Symptom

A reporting view returns unexpected totals.

### Checks

Validate that the view:

- Joins the correct tables.
- Uses the correct status filter.
- Uses the correct revenue column.
- Does not accidentally double-count rows.
- Groups at the expected grain.

### Common Column Issue

During the project, a script referenced:

```text
gross_revenue
completed_revenue
```

but the actual view/table used:

```text
total_revenue
```

### Fix

Align validation scripts with the actual output schema.

For this project, the expected sales-by-date output uses:

```text
order_date
order_count
total_quantity
total_revenue
```

### Lesson Learned

Validation scripts must validate the schema that actually exists, not the schema you intended in your head.

---

## 14. Layer 12 — CETAS Output

### Symptom

CETAS fails on rerun.

### Likely Cause

The output folder already exists and contains files.

### Example Output Path

```text
serving/retail/sales_by_date_cetas/run_id=manual_001/
```

or lab output:

```text
lab/outputs/sales_by_city_cetas_attempt/run_id=lab_06_manual_001/
```

### Fix Options

Option 1 — Delete the output folder in ADLS.

Option 2 — Change the `run_id` in the CETAS `LOCATION`:

```text
run_id=manual_002/
```

or:

```text
run_id=lab_06_manual_002/
```

### Important Behavior

Dropping the external table removes SQL metadata.

It does not delete the Parquet files in ADLS.

### Interview Defense

A strong answer:

```text
CETAS materializes query results as physical files in ADLS and registers external table metadata over those files. Dropping the external table does not delete the underlying lake files, so output paths must be managed intentionally. For reruns, I either clean the target folder or use a new run_id path.
```

---

## 15. Layer 13 — Cost Troubleshooting

### Symptom

Concern about unexpected cost.

### Key Reminder

Serverless SQL charges based on data processed by queries.

This does not mean there is a fixed monthly pool charge like a Dedicated SQL Pool.

### MVP Cost Controls

This project controls cost by using:

```text
Built-in Serverless SQL only
Small synthetic datasets
Parquet files
Focused queries
No Dedicated SQL Pool
No Spark Pool
No always-on compute
Small CETAS outputs
```

### What Not to Create

```text
Dedicated SQL Pool
Apache Spark Pool
Data Explorer Pool
```

### Good Habit

After running queries, inspect query details in Synapse Studio to understand processed data and duration.

---

## 16. Layer 14 — Evidence and Public Safety

### Symptom

Screenshots are useful but expose sensitive data.

### Do Not Publish Screenshots Showing

```text
Subscription ID
Tenant ID
Object ID
Personal email
Full endpoints if unnecessary
Storage keys
SAS tokens
Connection strings
Passwords
```

### Fix

Crop or censor images before committing them to a public repository.

### Evidence Worth Keeping

```text
Serverless SQL ready query
Database created
External data source created
External file format created
External tables created
Smoke test PASS
Reporting views PASS
Data quality PASS
CETAS validation PASS
Cost controls / no dedicated pools
```

---

## 17. Fast Diagnostic Checklist

Use this checklist when something breaks.

| Question | Why It Matters |
|---|---|
| Am I connected to Built-in Serverless SQL? | Avoids using the wrong compute mode |
| Am I using `synapse_serving_demo`? | Avoids wrong database context |
| Can I run a simple `SELECT CURRENT_TIMESTAMP`? | Confirms SQL endpoint readiness |
| Can I see `curated/retail/` in Synapse Studio? | Confirms lake visibility |
| Does the workspace identity have Storage Blob Data Contributor? | Confirms read/write access |
| Does `ds_adls_synapse_serving` exist? | Confirms external source |
| Does `ff_parquet` exist? | Confirms file format |
| Do `ext.*` tables exist? | Confirms table metadata |
| Do counts match expected values? | Confirms file/table alignment |
| Am I mixing `sys.*` and `ext.*` in one query? | Common distributed processing error |
| Does CETAS output path already exist? | Common rerun failure |
| Did I accidentally reference a non-existent column? | Common validation bug |
| Did I create expensive pools? | Cost risk |

---

## 18. Troubleshooting Patterns Learned in This Project

Real issues discovered and resolved:

| Issue | Resolution |
|---|---|
| East US provisioning blocked | Created Synapse Workspace in West US 2 |
| Needed Synapse access to ADLS | Assigned Storage Blob Data Contributor to workspace Managed Identity |
| External tables failed with `NOT NULL` | Removed `NOT NULL` from external table DDL |
| Smoke test needed expected counts | Validated `10 / 10 / 24 / 43` dataset counts |
| CETAS validation mixed metadata and data | Split validation into separate statements |
| Wrong revenue column names | Standardized on `total_revenue` |
| Cost-control script mixed `sys.*` and `rpt.*` | Split metadata and external-data final statuses |
| CETAS rerun risk | Use clean folder or new `run_id` |
| Public screenshots exposed details | Crop/censor before publishing |

---

## 19. Interview Defense Summary

A strong project defense:

```text
I built a Synapse Serverless SQL serving layer over curated Parquet files in ADLS Gen2. During implementation and lab practice, I validated the full path from workspace provisioning to external tables, views, data quality checks, CETAS outputs, and cost-aware querying. I also documented troubleshooting lessons such as region provisioning limitations, managed identity permissions, external table schema-on-read behavior, CETAS output path management, and the need to separate catalog metadata checks from external-data distributed queries.
```

A strong troubleshooting defense:

```text
When a Synapse issue appears, I diagnose it layer by layer: workspace, SQL endpoint, database context, storage visibility, managed identity permissions, external data source, file format, external table location, query shape, and output path. This prevents random troubleshooting and helps isolate whether the issue is Azure provisioning, permissions, metadata, schema, query logic, or CETAS behavior.
```

---

## 20. Completion Criteria

This lab is complete when:

1. You have read the troubleshooting playbook.
2. You can identify at least five real issues solved during the Synapse project.
3. You can explain the `NOT NULL` external table issue.
4. You can explain the `sys.*` plus external data distributed processing issue.
5. You can explain CETAS output folder behavior.
6. You can explain the cost-control boundary of the MVP.
7. You can use the fast diagnostic checklist when something breaks.
8. You can defend the troubleshooting approach in an interview.
