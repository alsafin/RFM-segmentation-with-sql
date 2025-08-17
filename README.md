# 🧠 RFM Segmentation with MySQL

This project demonstrates how to perform **RFM segmentation** using SQL on a sales dataset. RFM stands for **Recency**, **Frequency**, and **Monetary** — three key metrics used to evaluate customer behavior and value.

## 📦 Dataset Structure

The `sales` table contains transactional data with the following key fields:

- `ORDERNUMBER`, `ORDERDATE`, `QUANTITYORDERED`, `PRICEEACH`, `SALES`
- `CUSTOMERNAME`, `PRODUCTLINE`, `DEALSIZE`, `COUNTRY`, etc.

Each row represents a line item from a customer order.

## 🔍 Analysis Overview

### 1. **Customer-Level Metrics**
We calculate:
- `CLV` (Customer Lifetime Value) — total sales per customer
- `FREQUENCY` — number of unique orders
- `TOTAL_QTY_ORDER` — total quantity ordered
- `CUSTOMER_RECENCY` — days since last purchase

### 2. **RFM Segmentation Logic**
Using a CTE-based view called `rfm`, we:
- Assign scores from 1 to 5 for each RFM metric using `NTILE(5)`
- Combine scores into a `RFM_COMBINATION` string (e.g., "543")
- Classify customers into segments like:
  - 🏆 Champions
  - 💎 Loyal Customers
  - 🕒 Recent Customers
  - 🌱 Potential Loyalists
  - ⚠️ At Risk
  - 💰 Big Spenders
  - ❌ Lost Customers

### 3. **Aggregate Insights**
We summarize:
- Total and average spending per segment
- Total orders and quantity
- Segment distribution by count and percentage

## 📊 Sample Queries

```sql
-- View top customer segments
SELECT * FROM rfm;

-- Segment-wise spending and order volume
SELECT
  CUSTOMER_SEGMENT,
  SUM(MONETARY) AS TOTAL_SPENDING,
  ROUND(AVG(MONETARY),0) AS AVERAGE_SPENDING,
  SUM(FREQUENCY) AS TOTAL_ORDER,
  SUM(TOTAL_QTY_ORDER) AS TOTAL_QTY_ORDERED
FROM rfm
GROUP BY CUSTOMER_SEGMENT;

-- Segment distribution
SELECT
  customer_segment,
  COUNT(*) AS customer_count,
  ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM rfm
GROUP BY customer_segment
ORDER BY customer_count DESC;
