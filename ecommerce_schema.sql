-- Creating, inserting, importing, and updating data into the database.
CREATE TABLE Orders (
    Order_Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Order_Date TEXT,
    Time TEXT,
    Aging INTEGER,
    Customer_Id INTEGER,
    Gender TEXT,
    Device_Type TEXT,
    Customer_Login_type TEXT,
    Product TEXT,
    Product_Category TEXT,
    Sales REAL,
    Quantity INTEGER,
    Discount REAL,
    Profit REAL,
    Shipping_Cost REAL,
    Order_Priority TEXT,
    Payment_Method TEXT
);

INSERT INTO Orders (
    Order_Date, Time, Aging, Customer_Id, Gender, Device_Type, Customer_Login_type,
    Product, Product_Category, Sales, Quantity, Discount, Profit, Shipping_Cost,
    Order_Priority, Payment_Method
)
SELECT 
    "Order_Date", "Time", "Aging", "Customer_Id", "Gender", "Device_Type", "Customer_Login_type",
    "Product", "Product_Category", "Sales", "Quantity", "Discount", "Profit", "Shipping_Cost",
    "Order_Priority", "Payment_method"
FROM "E-commerce Dataset";


SELECT * FROM Orders LIMIT 10;
DROP TABLE "E-commerce Dataset";

INSERT OR IGNORE INTO Customers (Customer_Id, Gender, Device_Type, Customer_Login_type)
SELECT DISTINCT Customer_Id, Gender, Device_Type, Customer_Login_type
FROM Orders;

SELECT * FROM Customers LIMIT 10;

INSERT INTO Products (Product_Name, Product_Category)
SELECT DISTINCT Product, Product_Category
FROM Orders;

SELECT * FROM Products LIMIT 10;

SELECT * FROM Orders LIMIT 10;

SELECT COUNT(*) FROM Orders;

UPDATE Orders
SET Product_Id = (SELECT Product_Id FROM Products 
                  WHERE Products.Product_Name = Orders.Product 
                  AND Products.Product_Category = Orders.Product_Category);

SELECT Product_Id, Product, Product_Category FROM Orders LIMIT 10;

-- Key Business Insights & Basic SQL Queries

-- 1. Total Sales and Profit Summary
-- 🛒 Get total sales, profit, and number of orders
SELECT 
    COUNT(Order_Id) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders;
-- ✅ Insight: Helps measure overall revenue and profitability.

--2. Monthly Sales Performance
--📅 Sales trend over time
SELECT 
    strftime('%Y-%m', Order_Date) AS Month,
    SUM(Sales) AS Monthly_Sales,
    SUM(Profit) AS Monthly_Profit
FROM Orders
GROUP BY Month
ORDER BY Month;
--✅ Insight: Identifies peak sales months and trends.

--3. Top Selling Products
--🔥 Find the most profitable products
SELECT 
    P.Product_Name,
    P.Product_Category,
    SUM(O.Sales) AS Total_Sales,
    SUM(O.Quantity) AS Total_Units_Sold
FROM Orders O
JOIN Products P ON O.Product_Id = P.Product_Id
GROUP BY P.Product_Name, P.Product_Category
ORDER BY Total_Sales DESC
LIMIT 10;
--✅ Insight: Identifies the best-selling and highest revenue-generating products.

--4. Customer Segmentation by Order Volume
--👥 Find most valuable customers
SELECT 
    C.Customer_Id,
    COUNT(O.Order_Id) AS Total_Orders,
    SUM(O.Sales) AS Total_Spent
FROM Orders O
JOIN Customers C ON O.Customer_Id = C.Customer_Id
GROUP BY C.Customer_Id
ORDER BY Total_Spent DESC
LIMIT 10;
--✅ Insight: Identifies high-value customers.

--5. Order Processing Performance
--⏳ Track average aging (processing time)
SELECT 
    AVG(Aging) AS Avg_Processing_Time
FROM Orders;
--✅ Insight: Helps monitor efficiency in order fulfillment.

--6. Shipping Cost Analysis
--🚚 Compare shipping costs across order priorities
SELECT 
    Order_Priority,
    COUNT(Order_Id) AS Total_Orders,
    AVG(Shipping_Cost) AS Avg_Shipping_Cost
FROM Orders
GROUP BY Order_Priority
ORDER BY Avg_Shipping_Cost DESC;
--✅ Insight: Helps optimize logistics and shipping costs.

--7. Payment Method Trends
--💳 Identify most used payment methods
SELECT 
    Payment_Method,
    COUNT(Order_Id) AS Total_Orders,
    SUM(Sales) AS Total_Revenue
FROM Orders
GROUP BY Payment_Method
ORDER BY Total_Revenue DESC;
--✅ Insight: Helps Amazon optimize preferred payment methods.

--Queries Using Window Functions

--🏆 Rank Customers by Total Spending
SELECT 
    P.Product_Name,
    P.Product_Category,
    SUM(O.Sales) AS Total_Sales,
    RANK() OVER (ORDER BY SUM(O.Sales) DESC) AS Sales_Rank
FROM Orders O
JOIN Products P ON O.Product_Id = P.Product_Id
GROUP BY P.Product_Name, P.Product_Category
ORDER BY Total_Sales DESC;
--✅ Insight: Identifies top customers dynamically.

--🛒 Find the Running Total of Sales Over Time
WITH MonthlySales AS (
    SELECT 
        strftime('%Y-%m', Order_Date) AS Order_Month,
        SUM(Sales) AS Monthly_Sales
    FROM Orders
    GROUP BY Order_Month
    ORDER BY Order_Month
)
SELECT
    Order_Month,
    Monthly_Sales,
    SUM(Monthly_Sales) OVER (ORDER BY Order_Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Total
FROM MonthlySales;
--✅ Insight: Helps track cumulative revenue growth.

--Queries Using Common Table Expressions (CTEs)
--🏆 CTE for Highest-Spending Customers
WITH CustomerSpending AS (
    SELECT 
        O.Customer_Id,
        SUM(O.Sales) AS Total_Sales,
        SUM(O.Profit) AS Total_Profit
    FROM Orders O
    GROUP BY O.Customer_Id
)
SELECT 
    C.Customer_Id,
    C.Gender,
    CustomerSpending.Total_Sales,
    CustomerSpending.Total_Profit
FROM CustomerSpending
JOIN Customers C ON C.Customer_Id = CustomerSpending.Customer_Id
ORDER BY CustomerSpending.Total_Sales DESC
LIMIT 10;

--Recursive CTE
CREATE TABLE IF NOT EXISTS Categories (
    Category_Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Category_Name TEXT UNIQUE,
    Parent_Category_Id INTEGER NULL,
    FOREIGN KEY (Parent_Category_Id) REFERENCES Categories(Category_Id)
);
INSERT INTO Categories (Category_Name, Parent_Category_Id) VALUES
('Electronics', NULL),
('Auto & Accessories', NULL),
('Mobile Accessories', 1),
('Car Accessories', 2),
('Bike Accessories', 2);

WITH RECURSIVE CategoryHierarchy AS (
    SELECT 
        Category_Id,
        Parent_Category_Id,
        Category_Name,
        0 AS Level
    FROM Categories
    WHERE Parent_Category_Id IS NULL

    UNION ALL

    SELECT 
        c.Category_Id,
        c.Parent_Category_Id,
        c.Category_Name,
        ch.Level + 1
    FROM Categories c
    JOIN CategoryHierarchy ch 
        ON c.Parent_Category_Id = ch.Category_Id
)
SELECT * 
FROM CategoryHierarchy;
--✅ Insight: Uses a CTE to improve readability and efficiency.

--Indexing for Query Optimization
CREATE INDEX idx_orders_date ON Orders(Order_Date);
-- composite INDEX
CREATE INDEX idx_orders_customer_product 
ON Orders(Customer_Id, Product_Id);
--query PLAN
EXPLAIN QUERY PLAN
SELECT *
FROM Orders
WHERE Order_Date BETWEEN '2019-01-01' AND '2019-12-31';
--✅ Benefit: Indexes speed up data retrieval by allowing the database to find data without scanning every row.

--Partitioning for Efficient Querying - Partitioning Sales Data by Month
CREATE TABLE Orders_Partitioned (
    Order_Id INTEGER PRIMARY KEY,
    Order_Date TEXT,
    Sales REAL,
    Partition_Key TEXT GENERATED ALWAYS AS (strftime('%Y-%m', Order_Date)) VIRTUAL
);

CREATE INDEX idx_partition ON Orders_Partitioned(Partition_Key);
--✅ Benefit: Queries on Orders by month will be significantly faster.