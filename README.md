# UK Online Retail Analysis | Power BI Dashboard

## Project Overview
This project analyzes a UK-based non-store online retail dataset to understand business performance, customer behavior, and product demand using Power BI & SQL.

## Tools & Skills Used
Power BI  
SQL  
Excel  
Data Modeling  
DAX  
Data Cleaning  
Business Analysis  
Dashboard Design

## Data Preparation Using SQL

Before building the dashboard, SQL was used for:

- Removing duplicate records
- Data filtering and validation
- Aggregating customer and order level data
- Preparing data for Power BI analysis

Example SQL concept used:
Window Functions (ROW_NUMBER) to remove duplicates.

---

The dashboard focuses on identifying:
- Revenue trends over time
- High-value customers
- Repeat customer behavior
- Top-performing products
- Country-wise revenue contribution

This project demonstrates data cleaning, data modeling, DAX calculations, and business storytelling.

---

## Business Questions Answered
1. How is revenue trending over time?
2. Which countries contribute the most revenue?
3. Who are the highest value customers?
4. What is the repeat customer rate?
5. Which products generate the highest revenue?
6. How does product demand change over time?

---

## Dashboard Pages

### Executive Overview
Provides a high-level view of business performance.

Key KPIs:
- Total Revenue
- Total Customers
- Total Orders
- Repeat Customer Rate
- Average Order Value

Visuals included:
- Monthly revenue trend
- Orders trend
- Revenue by country

---

### Customer Behavior Analysis
Focuses on identifying valuable customers and customer retention.

Insights:
- Top 10 high-value customers
- Revenue contribution by top customers
- Repeat customer analysis
- Customer order patterns

---

### Product Performance
Analyzes product demand and revenue contribution.

Insights:
- Product demand over time
- Top 10 products by revenue
- Revenue vs quantity analysis
- Revenue share by product

---

## Tools & Skills Used
Power BI  
Data Modeling  
DAX  
Data Cleaning  
Business Analysis  
Dashboard Design  

---

## Key DAX Measures Created

Total Revenue
=SUM(Revenue)


Repeat Customer Rate
=DISTINCTCOUNT(CustomerID)


Repeat Customer Rate
=DIVIDE([Repeat Customers], [Total Customers])


Average Order Value
=DIVIDE([Total Revenue], [Total Orders])


---

## Key Insights
- The majority of revenue comes from the United Kingdom.
- Revenue shows strong growth towards the end of the year.
- A small group of customers contributes significantly to total revenue.
- Certain products dominate overall sales performance.

---

## Project Purpose
This project was built to demonstrate practical data analytics skills including:
- Data exploration
- Dashboard development
- Business insights generation

It is part of my transition into a Data Analyst role.

---

## Author
Tanisha Debnath  
Data Analytics Enthusiast | Power BI | SQL | Excel
