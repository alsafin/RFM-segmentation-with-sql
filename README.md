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

## 📂 Table Structure

```sql
CREATE TABLE sales (
    ORDERNUMBER INT,
    QUANTITYORDERED INT,
    PRICEEACH DECIMAL(10,2),
    ORDERLINENUMBER INT,
    SALES DECIMAL(10,2),
    ORDERDATE DATE,
    STATUS VARCHAR(20),
    QTR_ID INT,
    MONTH_ID INT,
    YEAR_ID INT,
    PRODUCTLINE VARCHAR(50),
    MSRP DECIMAL(10,2),
    PRODUCTCODE VARCHAR(50),
    CUSTOMERNAME VARCHAR(100),
    PHONE VARCHAR(20),
    ADDRESSLINE1 VARCHAR(100),
    ADDRESSLINE2 VARCHAR(100),
    CITY VARCHAR(50),
    STATE VARCHAR(50),
    POSTALCODE VARCHAR(20),
    COUNTRY VARCHAR(50),
    TERRITORY VARCHAR(50),
    CONTACTLASTNAME VARCHAR(50),
    CONTACTFIRSTNAME VARCHAR(50),
    DEALSIZE VARCHAR(20)
);

📊 Step 1: Customer Metrics (CLV, Frequency, Recency)

SELECT
    customername,
    ROUND(SUM(sales),0) AS CLV,
    COUNT(DISTINCT(ORDERNUMBER)) AS FREQUENCY,
    SUM(QUANTITYORDERED) AS TOTAL_QTY_ORDER,
    MAX(ORDERDATE) AS LAST_PURCHASE_DATE,
    DATEDIFF((SELECT MAX(ORDERDATE) FROM sales), MAX(ORDERDATE)) AS CUSTOMER_RECENCY
FROM sales
GROUP BY customername;

🏷️ Step 2: RFM Segmentation View

CREATE VIEW rfm AS

WITH CLV AS (
    SELECT
        customername,
        SUM(QUANTITYORDERED) AS TOTAL_QTY_ORDER,
        MAX(ORDERDATE) AS LAST_PURCHASE_DATE,
        DATEDIFF((SELECT MAX(ORDERDATE) FROM sales), MAX(ORDERDATE)) AS RECENCY,
        COUNT(DISTINCT(ORDERNUMBER)) AS FREQUENCY,
        ROUND(SUM(sales),0) AS MONETARY
    FROM sales
    GROUP BY customername
),

RFM_SCORE AS (
    SELECT
        C.*,
        NTILE(5) OVER (ORDER BY RECENCY DESC) AS R_score,
        NTILE(5) OVER (ORDER BY FREQUENCY ASC) AS F_score,
        NTILE(5) OVER (ORDER BY MONETARY ASC) AS M_score
    FROM CLV AS C
),

RFM_COMBINATION AS (
    SELECT
        R.*,
        R_score + F_score + M_score AS TOTAL_RFM_SCORE,
        CONCAT_WS('', R_score, F_score, M_score) AS RFM_COMBINATION
    FROM RFM_SCORE AS R
)

SELECT 
    RC.*,
    CASE  
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customers'
        WHEN r_score >= 4 AND m_score >= 3 AND f_score <= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN m_score >= 4 AND r_score <= 3 THEN 'Big Spenders'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
        ELSE 'Others'
    END AS customer_segment
FROM RFM_COMBINATION AS RC;
📈 Step 3: Aggregated Values by Segment

SELECT
    CUSTOMER_SEGMENT,
    SUM(MONETARY) AS TOTAL_SPENDING,
    ROUND(AVG(MONETARY),0) AS AVERAGE_SPENDING,
    SUM(FREQUENCY) AS TOTAL_ORDER,
    SUM(TOTAL_QTY_ORDER) AS TOTAL_QTY_ORDERED
FROM rfm
GROUP BY CUSTOMER_SEGMENT;
📉 Step 4: Segment Distribution

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2
    ) AS percentage
FROM rfm
GROUP BY customer_segment
ORDER BY customer_count DESC;
