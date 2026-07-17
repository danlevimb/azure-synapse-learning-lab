# Lab 04 — Reporting Views

**Repository:** `azure-synapse-learning-lab`  
**Lab:** `04_reporting_views`  
**Mode:** Hands-on SQL practice  
**Target environment:** Azure Synapse Serverless SQL  
**Database:** `synapse_serving_demo`

---

## 1. Objective

Practice how to build a reusable analytical query surface on top of external tables.

The goal of this lab is to move from this:

```text
External tables over Parquet files
```

To this:

```text
Reusable reporting views for analytical consumers
```

This lab reinforces the difference between:

| Layer | Purpose |
|---|---|
| `ext` | Exposes curated lake files as SQL external tables |
| `lab` | Practice schema for learning exercises |
| `rpt` | Portfolio-ready reporting views from the main project |

In this lab, you will create your own `lab.*` reporting views without modifying the existing `rpt.*` views from the portfolio project.

---

## 2. Why This Matters

External tables are useful, but business users should not always query raw external tables directly.

A serving layer usually provides reusable SQL objects such as views that:

- Hide joins.
- Apply business logic.
- Standardize metrics.
- Reduce repeated query logic.
- Make analytical consumption easier.
- Protect users from needing to know lake folder details.

This is the core idea of a SQL serving layer.

---

## 3. What You Will Build

The attempt script creates the following lab views:

```text
lab.vw_order_line_enriched
lab.vw_sales_by_date_attempt
lab.vw_sales_by_customer_attempt
lab.vw_sales_by_product_attempt
lab.vw_order_status_summary_attempt
```

These views are created only in the `lab` schema.

They do not modify:

```text
ext.*
rpt.*
audit.*
```

---

## 4. View Design

### 4.1 `lab.vw_order_line_enriched`

This is the base analytical view.

It joins:

```text
ext.orders
ext.order_items
ext.products
ext.customers
```

It exposes one row per order item enriched with:

- Order attributes
- Customer attributes
- Product attributes
- Quantity
- Unit price
- Line revenue

### 4.2 `lab.vw_sales_by_date_attempt`

Aggregates revenue by `order_date`.

Expected columns:

```text
order_date
order_count
total_quantity
total_revenue
```

### 4.3 `lab.vw_sales_by_customer_attempt`

Aggregates revenue by customer.

Expected columns:

```text
customer_id
customer_name
city
state_code
order_count
total_quantity
total_revenue
```

### 4.4 `lab.vw_sales_by_product_attempt`

Aggregates revenue by product.

Expected columns:

```text
product_id
product_name
category
order_count
total_quantity
total_revenue
```

### 4.5 `lab.vw_order_status_summary_attempt`

Summarizes order and payment statuses.

Expected columns:

```text
order_status
payment_status
order_count
total_order_amount
```

---

## 5. Business Logic

For analytical revenue views, count only completed/paid business transactions:

```text
order_status IN ('COMPLETED', 'PAID')
payment_status = 'APPROVED'
```

This excludes:

- Pending orders
- Cancelled orders
- Refunded orders
- Declined payments

This keeps the reporting layer aligned with revenue recognition logic.

---

## 6. Practice Instructions

Open Synapse Studio and connect to:

```text
SQL pool: Built-in
Database: synapse_serving_demo
```

Run:

```text
attempts/04_reporting_views_attempt.sql
```

Read the output in sections.

Do not just run the whole script blindly.

Understand what each result set proves.

---

## 7. Expected Validation

The final result should return:

```text
reporting_views_status = PASS
```

The script validates that:

- The enriched order-line view returns the same number of rows as `ext.order_items`.
- Sales-by-date revenue matches the filtered enriched view revenue.
- Sales-by-customer revenue matches the filtered enriched view revenue.
- Sales-by-product revenue matches the filtered enriched view revenue.
- Order status summary row counts match `ext.orders`.
- Reporting views produce rows.

---

## 8. Reflection Questions

Answer these in your own words:

1. Why should analytical users query reporting views instead of raw external tables?
2. What logic belongs in a reporting view?
3. What logic should not be hidden inside a reporting view?
4. Why does this lab create views in the `lab` schema instead of modifying `rpt`?
5. How would you explain the difference between `ext` and `rpt` schemas in an interview?
6. Why is revenue filtered to completed or paid orders with approved payments?
7. What could go wrong if every analyst writes their own joins directly against external tables?

---

## 9. Interview Defense

A strong explanation:

```text
In this lab, I created a small reporting layer on top of Synapse Serverless external tables. The external tables expose curated Parquet files from ADLS Gen2, while the reporting views provide reusable analytical logic such as enriched order lines, sales by date, sales by customer, sales by product, and order status summaries. This separates physical lake access from consumption logic and makes the serving layer easier to query and maintain.
```

---

## 10. Completion Criteria

This lab is complete when:

- The SQL attempt script runs successfully.
- The `lab` schema exists.
- All five `lab.*` views are created.
- Preview queries return readable results.
- Final validation returns `PASS`.
- Reflection questions are answered.
