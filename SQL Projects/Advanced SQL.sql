--------------------------------------------------------------------------------
/*
Advanced SQL Statement Use Cases
Data: Tableau Superstore Data 2022.2
https://data.world/missdataviz/20222-superstore
*/
--------------------------------------------------------------------------------

/* What were the total sales for each customer in their first order? */
WITH ranked AS (
  SELECT RANK() OVER (PARTITION BY Customer_Name ORDER BY Order_Date) AS Order_Rank,
		     Customer_Name,
         Sales
  FROM orders)

SELECT Order_Rank, Customer_Name, SUM(Sales) AS Total
FROM ranked
WHERE Order_Rank = 1
GROUP BY Customer_Name

/* For each customer, which order was returned (1st, 2nd, 3rd, etc.) and how
many items were in that return order? */
WITH ranked AS (
	SELECT RANK() OVER (PARTITION BY o.Customer_Name ORDER BY o.Order_Date) AS Order_Rank,
			   o.Customer_Name,
			   o.Order_Date,
			   o.Order_ID
	FROM orders o JOIN returns r
		ON o.Order_ID = r.Order_ID)

SELECT ranked.Order_Rank,
	   orders.Order_ID,
       COUNT(orders.Quantity) AS num_items
FROM orders, ranked
WHERE orders.Order_ID = ranked.Order_ID
GROUP BY ranked.Order_Rank, orders.Order_ID

/* Query a random sample of orders that consists of every other order per person
regardless of number of different items per order ID */
WITH row_table AS (
SELECT Order_ID, Customer_Name, ROW_NUMBER() OVER (PARTITION BY Customer_Name) AS row_num
FROM orders)

SELECT Order_ID, row_num
FROM row_table
WHERE row_num % 2 = 0

/* What are the running totals for sales per customer? */
SELECT Customer_Name,
	   Order_ID,
	   Order_Date,
       SUM(Sales) OVER(PARTITION BY Customer_Name
		ORDER BY Order_Date
    ROWS UNBOUNDED PRECEDING) AS Running_Total
FROM orders

/* Which customer had the largest gap between orders? Ensure query can return
correct answer even with table changes */
WITH days_difference AS (
	SELECT Customer_Name,
	   DATEDIFF(LEAD(Order_Date, 1) OVER(PARTITION BY Customer_Name
		ORDER BY Order_Date), Order_Date) AS Days
	FROM orders),
     max_difference AS (
	SELECT MAX(Days) AS max_day
	FROM days_difference)

SELECT Customer_Name
FROM days_difference d, max_difference m
WHERE d.Days = m.max_day

/* How many customers had total sales in returns exceeding that of sales
that were not returned? */
WITH return_sales AS (
	SELECT DISTINCT(o.Row_ID),
			o.Customer_Name,
			o.Order_ID,
			SUM(o.Sales) AS Return_Total
	FROM orders o JOIN returns r
		ON o.Order_ID = r.Order_ID
	GROUP BY Customer_Name),
Ordered_Sales AS (
	SELECT o.Customer_Name,
		   o.Order_ID,
        SUM(o.Sales) AS Sale_Total
	FROM orders o LEFT JOIN returns r
		ON o.Order_ID = r.Order_ID
	WHERE r.Order_ID IS NULL
    GROUP BY Customer_Name)

SELECT COUNT(o.Customer_Name)
FROM ordered_sales o JOIN return_sales r
	ON o.Customer_Name = r.Customer_Name
WHERE r.Return_Total > o.Sale_Total
