
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
    PRODUCTLINE VARCHAR(50),  -- ← Changed from INT to VARCHAR
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
select MAX(ORDERDATE) from sales;

select
	customername,
    round(sum(sales),0) AS CLV,
    COUNT(DISTINCT(ORDERNUMBER)) AS FREQUENCY,
    SUM(QUANTITYORDERED) AS TOTAL_QTY_ORDER,
    MAX(ORDERDATE) AS LAST_PURCHES_DATE,
    datediff((select MAX(ORDERDATE) from sales),MAX(ORDERDATE)) AS CUSTOMER_RECENCY
from
	sales
GROUP BY CUSTOMERNAME;

#rfm SEGMENTATION
CREATE VIEW   rfm AS

WITH CLV AS 
(select
	customername,
	SUM(QUANTITYORDERED) AS TOTAL_QTY_ORDER,
	MAX(ORDERDATE) AS LAST_PURCHES_DATE,
    datediff((select MAX(ORDERDATE) from sales),MAX(ORDERDATE)) AS RECENCY,
    COUNT(DISTINCT(ORDERNUMBER)) AS FREQUENCY,
    round(sum(sales),0) AS MONETARY	
from
	sales
GROUP BY CUSTOMERNAME),
#RFM SCORE
 RFM_SCORE AS 
(SELECT
C.*,
NTILE(5) OVER (ORDER BY RECENCY DESC) AS R_score,
NTILE(5) OVER (ORDER BY FREQUENCY ASC) AS F_score,
NTILE(5) OVER (ORDER BY MONETARY ASC) AS M_score
FROM
CLV AS C),

# RFM COMBINITION
RFM_COMBINATION AS 
(SELECT
R.*,
R_score + F_score + M_score AS TOTAL_RFM_SCORE,
CONCAT_WS("" ,R_score,F_SCORE,M_SCORE  ) AS RFM_COMBINATION


FROM RFM_SCORE AS R)



SELECT 
RC.*,
        
      CASE  WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customers'
            WHEN r_score >= 4 AND m_score >= 3 AND f_score <= 2 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
            WHEN m_score >= 4 AND r_score <= 3 THEN 'Big Spenders'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
            ELSE 'Others'
    END AS customer_segment
FROM RFM_COMBINATION AS RC;


select * from rfm;
#AGGREGATE VALU
SELECT
	CUSTOMER_SEGMENT,
    SUM(MONETARY) AS TOTAL_SPENDING,
    ROUND(AVG(MONETARY),0) AS AVERAGE_SPENDING,
    SUM(FREQUENCY) AS TOTAL_ORDER,
    SUM(TOTAL_QTY_ORDER) AS TOTAL_QTY_ORDERED
FROM rfm
GROUP BY CUSTOMER_SEGMENT;

-- Final: Count and Percentage
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2
    ) AS percentage
FROM rfm
GROUP BY customer_segment
ORDER BY customer_count DESC;



