
--Create database and bulk import--
CREATE DATABASE EcommerceAnalytics;

 
DROP TABLE IF EXISTS ecommerce_data;
DROP TABLE IF EXISTS ecommerce_clean;
DROP TABLE IF EXISTS ecommerce_stage;

CREATE TABLE ecommerce_stage (
    InvoiceNo VARCHAR(50) NULL,
    StockCode VARCHAR(50) NULL,
    Description VARCHAR(255) NULL,
    Quantity VARCHAR(50) NULL,
    InvoiceDate VARCHAR(50) NULL,
    UnitPrice VARCHAR(50) NULL,
    CustomerID VARCHAR(50) NULL,
    Country VARCHAR(100) NULL
);

SELECT * FROM ecommerce_stage;

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

BULK INSERT ecommerce_stage
FROM 'C:\Users\tanis\OneDrive\Desktop\ecommerce_funnel_clean.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);


SELECT COUNT(*) FROM ecommerce_stage;
----------------------------------------------------------------
--Understand the dataset-EDA
SELECT TOP 20 *
FROM ecommerce_stage;
----------------------------------------------------------------
--Clean Analysis Table
DROP TABLE IF EXISTS ecommerce_clean;

CREATE TABLE ecommerce_clean (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME NULL,
    UnitPrice FLOAT,
    CustomerID FLOAT NULL,
    Country VARCHAR(100)
);

--Convert Data Safely
INSERT INTO ecommerce_clean
SELECT
    InvoiceNo,
    StockCode,
    Description,
    TRY_CAST(Quantity AS INT),
    TRY_CAST(InvoiceDate AS DATETIME),
    TRY_CAST(UnitPrice AS FLOAT),
    TRY_CAST(CustomerID AS FLOAT),
    Country
FROM ecommerce_stage;

--Verify Conversion
SELECT TOP 20 *
FROM ecommerce_clean;

SELECT COUNT(*)
FROM ecommerce_clean;
-----------------------------------------------------
--Remove Rows Without Customers
DELETE FROM ecommerce_clean
WHERE CustomerID IS NULL;
-----------------------------------------------------
--Data Health Check
SELECT
COUNT(*) total_rows,
COUNT(DISTINCT CustomerID) customers,
COUNT(DISTINCT InvoiceNo) orders
FROM ecommerce_clean;

====================================================
/*Data cleaning

Handling null values

Removing cancelled transactions

Revenue analysis

Customer analysis

Product performance

Time-series analysis*/
==================================================
--revenue calculation
SELECT
SUM(Quantity * UnitPrice) total_revenue
FROM ecommerce_clean;
====================================================
--cancelled orders (InvoiceNo starting with C)
SELECT COUNT(*)
FROM ecommerce_clean
WHERE InvoiceNo LIKE 'C%';

--remove cancelled orders
DELETE FROM ecommerce_clean
WHERE InvoiceNo LIKE 'C%';

--check no. of rows
SELECT COUNT(*) AS remaining_rows
FROM ecommerce_clean;
====================================================
--Total Revenue(most important KPI)
SELECT
ROUND(SUM(Quantity * UnitPrice),2) AS Total_Revenue
FROM ecommerce_clean;
====================================================
--Top Selling Products
SELECT TOP 10
Description,
SUM(Quantity) AS Total_Quantity_Sold
FROM ecommerce_clean
GROUP BY Description
ORDER BY Total_Quantity_Sold DESC;
=====================================================
--Top Revenue Generating Products
SELECT TOP 10
Description,
ROUND(SUM(Quantity * UnitPrice),2) AS Revenue
FROM ecommerce_clean
GROUP BY Description
ORDER BY Revenue DESC;
=====================================================
--Top Countries by Revenue
SELECT
Country,
ROUND(SUM(Quantity * UnitPrice),2) AS Revenue
FROM ecommerce_clean
GROUP BY Country
ORDER BY Revenue DESC;
=====================================================
--Monthly Sales Trend
SELECT
FORMAT(InvoiceDate, 'yyyy-MM') AS Month,
ROUND(SUM(Quantity * UnitPrice),2) AS Revenue
FROM ecommerce_clean
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY Month;
========================================================
--Top Customers
SELECT TOP 10
CustomerID,
ROUND(SUM(Quantity * UnitPrice),2) AS Customer_Spending
FROM ecommerce_clean
GROUP BY CustomerID
ORDER BY Customer_Spending DESC;
========================================================
--Average Order Value
SELECT
ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo),2) AS Avg_Order_Value
FROM ecommerce_clean;
===========================================================
/*R → Recency (How recently a customer purchased)
F → Frequency (How often they purchase)
M → Monetary (How much money they spend)*/
==========================================================
--Latest Date in Dataset
SELECT MAX(InvoiceDate) AS Last_Date
FROM ecommerce_clean;
===========================================================
--Customer Metrics (Base Table)
SELECT
CustomerID,
MAX(InvoiceDate) AS LastPurchaseDate,
DATEDIFF(day, MAX(InvoiceDate), (SELECT MAX(InvoiceDate) FROM ecommerce_clean)) AS Recency,
COUNT(DISTINCT InvoiceNo) AS Frequency,
ROUND(SUM(Quantity * UnitPrice),2) AS Monetary
INTO rfm_base
FROM ecommerce_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;

SELECT TOP 10 *
FROM rfm_base;
===========================================================
--Customer Distribution
SELECT
MIN(Recency) AS Min_Recency,
MAX(Recency) AS Max_Recency,
MIN(Frequency) AS Min_Frequency,
MAX(Frequency) AS Max_Frequency,
MIN(Monetary) AS Min_Monetary,
MAX(Monetary) AS Max_Monetary
FROM rfm_base;
==========================================================
--RFM Scores
SELECT *,
NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
INTO rfm_scores
FROM rfm_base;

SELECT TOP 10 *
FROM rfm_scores;
===========================================================
--Customer Segments
SELECT *,
CONCAT(R_Score, F_Score, M_Score) AS RFM_Segment
INTO rfm_final
FROM rfm_scores;

--Best Customers
SELECT TOP 20 *
FROM rfm_final
ORDER BY Monetary DESC;

--Segment Summary
SELECT
RFM_Segment,
COUNT(CustomerID) AS Customers,
ROUND(AVG(Monetary),2) AS Avg_Spending
FROM rfm_final
GROUP BY RFM_Segment
ORDER BY Customers DESC;
=============================================================================================================
============================================================================================================
--Funnel Stages Table
--Funnel conversion analysis


SELECT *
FROM ecommerce_clean
WHERE Quantity <= 0 OR Quantity IS NULL;

DROP TABLE funnel_table;

SELECT
CustomerID,
InvoiceNo,
InvoiceDate,
Quantity,
UnitPrice,
(Quantity * UnitPrice) AS Revenue,

CASE
    WHEN Quantity <= 0 THEN 'Returned'
    WHEN Quantity = 1 THEN 'Product_View'
    WHEN Quantity BETWEEN 2 AND 5 THEN 'Add_to_Cart'
    WHEN Quantity > 5 THEN 'Purchase'
    ELSE 'Unknown'
END AS FunnelStage

INTO funnel_table
FROM ecommerce_clean
WHERE CustomerID IS NOT NULL;

--check Funnel Distribution
SELECT
FunnelStage,
COUNT(DISTINCT CustomerID) AS Customers
FROM funnel_table
GROUP BY FunnelStage
ORDER BY Customers DESC;

--Conversion from Add-to-Cart → Purchase
SELECT
COUNT(DISTINCT CASE WHEN FunnelStage = 'Add_to_Cart' THEN CustomerID END) AS Cart_Customers,
COUNT(DISTINCT CASE WHEN FunnelStage = 'Purchase' THEN CustomerID END) AS Purchase_Customers
FROM funnel_table;

--Conversion Rate Between Stages

WITH stage_counts AS (
    SELECT
        FunnelStage,
        COUNT(DISTINCT CustomerID) AS Customers
    FROM funnel_table
    GROUP BY FunnelStage
)
SELECT
FunnelStage,
Customers,
Customers * 100.0 /
(SELECT MAX(Customers) FROM stage_counts) AS ConversionRate
FROM stage_counts;

--Revenue Analysis by Country
SELECT
Country,
SUM(Quantity * UnitPrice) AS TotalRevenue,
COUNT(DISTINCT CustomerID) AS Customers
FROM ecommerce_clean
GROUP BY Country
ORDER BY TotalRevenue DESC;

--Customer Lifetime Value (CLV)
SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS TotalOrders,
SUM(Quantity * UnitPrice) AS TotalSpent,
AVG(Quantity * UnitPrice) AS AvgOrderValue
FROM ecommerce_clean
GROUP BY CustomerID
ORDER BY TotalSpent DESC;

--Monthly Revenue Trend
SELECT
FORMAT(InvoiceDate, 'yyyy-MM') AS Month,
SUM(Quantity * UnitPrice) AS Revenue
FROM ecommerce_clean
GROUP BY FORMAT(InvoiceDate, 'yyyy-MM')
ORDER BY Month;

--Customer Funnel Journey
SELECT
CustomerID,
COUNT(DISTINCT FunnelStage) AS Stages_Reached
FROM funnel_table
GROUP BY CustomerID
ORDER BY Stages_Reached DESC;
=========================================================================================
--STORED PROCEDURE
CREATE PROCEDURE TopCustomers
AS
SELECT TOP 20
CustomerID,
SUM(Quantity * UnitPrice) AS Revenue
FROM ecommerce_clean
GROUP BY CustomerID
ORDER BY Revenue DESC;
===========================================================================================
--Customer Retention Analysis (Cohort Analysis)
===========================================================================================
--Customer First Purchase Month
SELECT
CustomerID,
MIN(InvoiceDate) AS FirstPurchaseDate
INTO customer_cohort
FROM ecommerce_clean
GROUP BY CustomerID;

--Add Cohort Month
SELECT
CustomerID,
FORMAT(FirstPurchaseDate,'yyyy-MM') AS CohortMonth
INTO cohort_table
FROM customer_cohort;

--Customer Activity by Month
SELECT
e.CustomerID,
c.CohortMonth,
FORMAT(e.InvoiceDate,'yyyy-MM') AS ActivityMonth
INTO cohort_activity
FROM ecommerce_clean e
JOIN cohort_table c
ON e.CustomerID = c.CustomerID;

--Calculate Retention
SELECT
CohortMonth,
ActivityMonth,
COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM cohort_activity
GROUP BY CohortMonth, ActivityMonth
ORDER BY CohortMonth, ActivityMonth;

--Calculate Retention Percentage
WITH cohort_size AS
(
SELECT
CohortMonth,
COUNT(DISTINCT CustomerID) AS TotalCustomers
FROM cohort_table
GROUP BY CohortMonth
)

SELECT
a.CohortMonth,
a.ActivityMonth,
a.ActiveCustomers,
ROUND(a.ActiveCustomers * 100.0 / c.TotalCustomers,2) AS RetentionRate
FROM
(
SELECT
CohortMonth,
ActivityMonth,
COUNT(DISTINCT CustomerID) AS ActiveCustomers
FROM cohort_activity
GROUP BY CohortMonth, ActivityMonth
) a
JOIN cohort_size c
ON a.CohortMonth = c.CohortMonth
ORDER BY a.CohortMonth, a.ActivityMonth;

==================================================================================================================
=====================================================================================================================
--All Tables
SELECT COUNT(*) FROM ecommerce_clean;
SELECT COUNT(*) FROM rfm_final;
SELECT COUNT(*) FROM funnel_table;
SELECT COUNT(*) FROM cohort_activity;

--Revenue Summary Table
SELECT
FORMAT(InvoiceDate,'yyyy-MM') AS Month,
SUM(Quantity * UnitPrice) AS Revenue
INTO revenue_trend
FROM ecommerce_clean
GROUP BY FORMAT(InvoiceDate,'yyyy-MM');

--Top Customers Table
SELECT
CustomerID,
SUM(Quantity * UnitPrice) AS TotalRevenue
INTO top_customers
FROM ecommerce_clean
GROUP BY CustomerID;

--Funnel Summary Table
SELECT
CustomerID,
SUM(Quantity * UnitPrice) AS TotalRevenue
INTO top_customers
FROM ecommerce_clean
GROUP BY CustomerID;



























