USE db_schema;

-- Total revenue generated
SELECT SUM(`quantityOrdered` * `priceEach`) AS revenue
FROM orderdetails od
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
;


-- Revenue generated by each product line
SELECT `productLine`,
        SUM(`quantityOrdered` * `priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productLine`
ORDER BY revenue DESC
;

-- Top 5 & Bottom 5 products by revenue
(SELECT `productName`,
        SUM(`quantityOrdered` * `priceEach`) AS revenue,
        'Top' AS position
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productName`
ORDER BY revenue DESC
LIMIT 5)
UNION ALL
(SELECT `productName`,
        SUM(`quantityOrdered` * `priceEach`) AS revenue,
        'Bottom' AS position
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productName`
ORDER BY revenue ASC
LIMIT 5)
;

-- Top product in product line by revenue
WITH product_CTE AS (
    SELECT `productLine`,
            `productName`,
            SUM(`quantityOrdered` * `priceEach`) AS revenue,
            ROW_NUMBER() OVER(PARTITION BY `productLine` ORDER BY SUM(`quantityOrdered` * `priceEach`) DESC) AS row_num
    FROM products_new pn
    JOIN orderdetails od
        ON od.`productCode` = pn.`productCode`
    JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
    WHERE odn.`status` IN ('Shipped', 'Resolved')
    GROUP BY `productLine`, `productName`
)
SELECT `productLine`,
        `productName`,
        revenue
FROM `product_CTE`
WHERE row_num = 1
;

-- Total purchasing_cost, profit and revenue
SELECT SUM(od.`quantityOrdered` * pn.`buyPrice`) AS purchasing_cost,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
;

-- Purchasing cost, profit and revenue by product line
SELECT `productLine`,
        SUM(od.`quantityOrdered` * pn.`buyPrice`) AS purchasing_cost,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productLine`
ORDER BY profit DESC
;

-- Top & Bottom 5 products by Purchasing cost, profit and revenue
(SELECT `productName`,
        SUM(od.`quantityOrdered` * pn.`buyPrice`) AS purchasing_cost,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue,
        'Top' AS position
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productName`
ORDER BY profit DESC
LIMIT 5)
UNION ALL
(SELECT `productName`,
        SUM(od.`quantityOrdered` * pn.`buyPrice`) AS purchasing_cost,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue,
        'Bottom' AS position
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productName`
ORDER BY profit ASC
LIMIT 5)
;

-- Total revenue by country 
SELECT c.country,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn
    ON odn.`orderNumber` = od.`orderNumber`
JOIN customers_new c 
    ON c.`customerNumber` = odn.`customerNumber` 
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY c.country
;

-- Revenue by sales rep 
SELECT CONCAT(en.`firstName`, " ", en.`lastName`) AS fullName,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode` 
JOIN orders_new odn
    ON odn.`orderNumber` = od.`orderNumber`
JOIN customers_new c 
    ON c.`customerNumber` = odn.`customerNumber`
JOIN employees_new en  
    ON en.`employeeNumber` = c.`salesRepEmployeeNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY CONCAT(en.`firstName`, " ", en.`lastName`)
ORDER BY revenue DESC
;

-- Revenue by sales manager
SELECT CONCAT(e2.`firstName`, " ", e2.`lastName`) AS managerName,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode` 
JOIN orders_new odn
    ON odn.`orderNumber` = od.`orderNumber`
JOIN customers_new c 
    ON c.`customerNumber` = odn.`customerNumber`
JOIN employees_new e1  
    ON e1.`employeeNumber` = c.`salesRepEmployeeNumber`
JOIN employees_new e2
    ON e1.`reportsTo` = e2.`employeeNumber`
WHERE e2.`jobTitle` LIKE '%Manager%' AND 
        odn.`status` IN ('Shipped', 'Resolved')
GROUP BY CONCAT(e2.`firstName`, " ", e2.`lastName`)
ORDER BY revenue DESC
;

-- Revenue & profit by territory 
SELECT ofn.territory,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode` 
JOIN orders_new odn
    ON odn.`orderNumber` = od.`orderNumber`
JOIN customers_new c 
    ON c.`customerNumber` = odn.`customerNumber`
JOIN employees_new en  
    ON en.`employeeNumber` = c.`salesRepEmployeeNumber`
JOIN offices_new ofn
    ON ofn.`officeCode` = en.`officeCode`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY ofn.territory
ORDER BY revenue DESC
;

-- Profit and revenue by product vendor
SELECT `productVendor`,
        SUM((od.`priceEach` - pn.`buyPrice`) * od.`quantityOrdered`) AS profit,
        SUM(od.`quantityOrdered` * od.`priceEach`) AS revenue
FROM products_new pn
JOIN orderdetails od
    ON od.`productCode` = pn.`productCode`
JOIN orders_new odn 
    ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY `productVendor`
ORDER BY revenue DESC
;

-- Average revenue generated by month 
SELECT 
    MONTHNAME(odn.`shippedDate`) AS month,
    ROUND(AVG(CASE WHEN YEAR(odn.`shippedDate`) = 2003 THEN od.`quantityOrdered` * od.`priceEach` END), 2) AS avg_revenue_2003,
    ROUND(AVG(CASE WHEN YEAR(odn.`shippedDate`) = 2004 THEN od.`quantityOrdered` * od.`priceEach` END), 2) AS avg_revenue_2004,
    ROUND(AVG(CASE WHEN YEAR(odn.`shippedDate`) = 2005 THEN od.`quantityOrdered` * od.`priceEach` END), 2) AS avg_revenue_2005
FROM orderdetails od
JOIN orders_new odn 
    ON od.`orderNumber` = odn.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved') 
GROUP BY MONTHNAME(odn.`shippedDate`)
;

-- Monthly recurring revenue
SELECT 
    MONTHNAME(`shippedDate`) AS month,
    ROUND(SUM(CASE WHEN YEAR(odn.`shippedDate`) = 2003 THEN od.`quantityOrdered` * od.`priceEach` END), 2) AS recurringRevenue2003,
    ROUND(SUM(CASE WHEN YEAR(odn.`shippedDate`) = 2004 THEN od.`quantityOrdered` * od.`priceEach` END), 2) AS recurringRevenue2004,
    ROUND(SUM(CASE WHEN YEAR(odn.`shippedDate`) = 2005 THEN od.`quantityOrdered` * od.`priceEach` END), 2) AS recurringRevenue2005
FROM orderdetails od 
JOIN orders_new odn
        ON odn.`orderNumber` = od.`orderNumber`
WHERE odn.`status` IN ('Shipped', 'Resolved')
GROUP BY MONTHNAME(`shippedDate`) 
;

