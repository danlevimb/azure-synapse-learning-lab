# Azure Synapse Learning Lab

**Repository:** `azure-synapse-learning-lab`  
**Purpose:** Private companion dojo for the public portfolio project `azure-synapse-serverless-serving-layer`  
**Status:** Phase 0 — Lab Foundation

## Overview

This repository is a private hands-on learning lab designed to build practical fluency with Azure Synapse Serverless SQL.

The companion public portfolio project demonstrates a clean implementation of a SQL serving layer over ADLS Gen2.

This lab is different.

The lab is used to practice, repeat, break, rebuild, troubleshoot, and defend the technical concepts behind the implementation.

## Companion Portfolio Project

```text
azure-synapse-serverless-serving-layer
```

The portfolio repository contains the polished implementation:

- Architecture documentation
- SQL scripts
- Sample data generation
- ADLS upload scripts
- External tables
- Reporting views
- Analytical queries
- Data quality queries
- CETAS output
- Evidence and closeout documentation

## Learning Lab Role

This repository contains the practice track:

- Guided lab notes
- Attempt scripts
- Troubleshooting exercises
- Interview-defense prompts
- Cost-awareness drills
- Rebuild-from-scratch practice

## Recommended Structure

```text
README.md
.gitignore

labs/
  00_lab_scope.md
  01_serverless_sql_basics.md
  02_openrowset_vs_external_tables.md
  03_schema_on_read_and_external_tables.md
  04_reporting_views.md
  05_data_quality_with_sql.md
  06_cetas_outputs.md
  07_cost_aware_querying.md
  08_troubleshooting_playbook.md

attempts/
  01_serverless_sql_basics_attempt.sql
  02_openrowset_vs_external_tables_attempt.sql
  03_schema_on_read_attempt.sql
  04_reporting_views_attempt.sql
  05_data_quality_attempt.sql
  06_cetas_attempt.sql
  07_cost_controls_attempt.sql

notes/
  README.md

evidence/
  README.md
```

## Lab Workflow

Recommended workflow:

```text
VS Code → GitHub private repo → Synapse Studio → Serverless SQL execution → Evidence / notes
```

The lab can reuse the existing Azure resources created for the portfolio project, while keeping all practice scripts isolated from the polished project artifacts.

## Core Rule

The lab may experiment.

The public portfolio repository should remain clean.

