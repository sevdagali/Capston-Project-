-- The classicmodels database represents a hypothetical retail company that sells classic cars. It consists of several 
-- tables that store essential information related to customers, products, sales orders, payments, employees, and offices
 -- and consist 3664 rows

# Data Exploration and Understanding :

-- let's specify the database 
USE classicmodels; 

-- let's get the row count of all tables in a database
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'classicmodels'
ORDER by table_name;

-- First, we'll explore the database tables to understand their contents. This helps us get 
-- overview of the data and identify any issues.

#1 let's extract data from all tables in a database and limit the results to 10 rows for each table 
SELECT * FROM Customers LIMIT 10;
SELECT * FROM Products LIMIT 10;
SELECT * FROM ProductLines LIMIT 10;
SELECT * FROM Orders LIMIT 10;
SELECT * FROM OrderDetails LIMIT 10;
SELECT * FROM Payments LIMIT 10;
SELECT * FROM Employees LIMIT 10;
SELECT * FROM Offices LIMIT 10;

#2 let's sart with costumers table

DESC customers;
SELECT DISTINCT count(customerName)
FROM customers; -- unique customers #122
 
SELECT count(*)
FROM customers
WHERE addressLine2 IS NULL
AND state IS NULL
AND postalCode IS NULL
AND salesRepEmployeeNumber IS NULL
AND creditLimit IS NULL; -- costumers table does not contain any NULL values

-- let's counts the number of orders each customer has made

SELECT o.customerNumber, COUNT(o.orderNumber) AS total_orders, 
AVG(p.amount) AS avg_order_amount
FROM Orders o
JOIN Payments p ON o.customerNumber = p.customerNumber
GROUP BY o.customerNumber
ORDER BY total_orders DESC;

-- here, let's see the total bigest amount spent 
SELECT c.customerNumber, c.customerName, SUM(p.amount) AS total_spent
FROM Customers c
JOIN Payments p ON c.customerNumber = p.customerNumber
GROUP BY  c.customerNumber, c.customerName
ORDER BY total_spent DESC;
-- The 'Euro+ Shopping Channel' biggest customers in terms of spending across all orders. 

-- products purchased the most by each customer in the classicmodels
SELECT c.customerNumber,c.customerName,od.productCode,p.productName, SUM(od.quantityOrdered) AS total_quantity
FROM Customers c
JOIN Orders o ON c.customerNumber = o.customerNumber
JOIN OrderDetails od ON o.orderNumber = od.orderNumber
JOIN Products p ON od.productCode = p.productCode
GROUP BY c.customerNumber, c.customerName, od.productCode, p.productName
ORDER BY total_quantity DESC;
-- it seems like '1992 Ferrari 360 Spider red' model most purchased product.

 -- information about canceled orders for each customer along with their total extended prices from those orders
 SELECT c.customerNumber,  c.customerName, 
SUM(od.quantityOrdered * od.priceEach) AS total_extended_price
FROM cutomers c
JOIN Orders o ON c.customerNumber = o.customerNumber
JOIN OrderDetails od ON o.orderNumber = od.orderNumber
WHERE o.status = 'Cancelled'
GROUP BY c.customerNumber, c.customerName;

#3 Let's explore the payments and products table 
desc payments; 

select count(*)
from payments
where amount is null; -- payments table has no NULL values 

-- let's see the total payments made for each month from paymnets teble. 
SELECT YEAR(paymentDate) AS year, MONTH(paymentDate) AS month, SUM(amount) AS total_payments
FROM Payments
GROUP BY year, month
ORDER BY year, month;

-- now, let's see the first payment of each month from the payments table.
SELECT MIN(paymentdate) as firts_payment_of_eachMonth, 
MONTH (paymentdate) as month
FROM payments 
GROUP BY month
ORDER BY firts_payment_of_eachMonth ASC;

-- let's return a list of the customer names and the first payment date each month.
CREATE temporary table first_montly_payment 
SELECT MIN(paymentdate) as firts_payment_of_eachMonth, 
MONTH (paymentdate) as month
FROM payments 
GROUP BY month
ORDER BY firts_payment_of_eachMonth ASC;

SELECT c.customerName, fpm.month, fpm.firts_payment_of_eachMonth
FROM first_montly_payment as fpm
INNER JOIN payments as p ON fpm.firts_payment_of_eachMonth = p.paymentDate
INNER JOIN customers as c ON p.customerNumber = c.customerNumber
ORDER BY 2 ASC;

-- les't retriev the employee name and the average payment amount collected from sales by each of them. 
SELECT e.employeeNumber,e.lastName,e.firstName,e.jobTitle,
AVG(p.amount) AS avg_payment_amount
FROM Employees e
JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN Payments p ON c.customerNumber = p.customerNumber
GROUP BY e.employeeNumber, e.lastName, e.firstName, e.jobTitle
ORDER BY avg_payment_amount DESC;
-- Leslie Jennings generates us the most profit on average, where Thompson Leslie the least. We should consider that.  

SELECT  count(*)
FROM  productlines
WHERE image IS NULL;

-- it is better to drop those imega column as there are no values.
ALTER TABLE productlines
    DROP COLUMN image;
    
-- let's find total quantity sold for each product.
SELECT od.productCode, p.productName, 
SUM(od.quantityOrdered) AS total_sold
FROM OrderDetails od
JOIN Products p ON od.productCode = p.productCode
GROUP BY p.productCode, p.productName
ORDER BY total_sold DESC;

-- let's find most popular product line SELECT productLine, SUM(quantityOrdered) as total_ordered
SELECT productLine, SUM(quantityOrdered) as total_ordered
FROM products p
JOIN orderdetails o ON p.productCode = o.productCode
GROUP BY productLine
ORDER BY total_ordered DESC
LIMIT 1; -- The classic Cars are most popular sold products.alter.

#4 Regional Sales Analysis
-- let's find total sales per city for each custome
SELECT c.city, SUM(od.quantityOrdered) 
AS total_sales,o.customerNumber
FROM Customers c
JOIN Orders o ON c.customerNumber = o.customerNumber
JOIN OrderDetails od ON o.orderNumber = od.orderNumber
GROUP BY c.city, o.customerNumber;

-- let's find top contries by costumers
SELECT country, count(*) as num_of_customer
FROM  customers
GROUP BY country
ORDER BY  num_of_customer desc
LIMIT 5;

#5 The years with highest sales. 
WITH cte as (select year(paymentDate) as year, amount
FROM payments)
SELECT  year, sum(amount) as total_sales
FROM cte
GROUP BY  year
ORDER BY total_sales desc; -- 2004,2003 and 2005 were the years with highest sales rate. 

-- Highest number of orders by months 
WITH cte AS (
SELECT YEAR(orderDate) AS year,
MONTH(orderDate) AS month,
SUM(quantityOrdered) AS total_orders,
RANK() OVER (PARTITION BY YEAR(orderDate) ORDER BY SUM(quantityOrdered) DESC) AS rank_
FROM orders o
JOIN orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY year, month)
SELECT year, month, total_orders
FROM cte
WHERE rank_ = 1; -- November and May had the highest number of orders

#6 creating views 
-- let’s create a view to show the total sales by year
CREATE VIEW total_sales_byyear as
SELECT year(paymentDate) as year, sum(amount)
FROM payments
GROUP BY year;

SELECT * FROM total_sales_byyear;

-- let's crate a view for customers who have made total payment which more than 60K
CREATE VIEW  top_customers as
SELECT customerName, sum(amount) as total_payment
FROM customers c
JOIN payments p on c.customerNumber = p.customerNumber
GROUP BY c.customerNumber
HAVING total_payment > 60000;

SELECT * FROM top_customers;




