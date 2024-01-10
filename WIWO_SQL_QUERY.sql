-- EXPLORE THE DATABASE

-- Select all columns from factSale table
SELECT *
FROM factSale;


-- EXPLORE CUSTOMER DIMENSION

-- Select all columns from dimCustomer table
SELECT *
FROM dimCustomer;

-- Count the number of customers where Stock Item is not 'unknown'
SELECT COUNT([Customer ID])
FROM dimCustomer
WHERE [Stock Item] != 'unknown';


-- EXPLORING NUMBER OF PRODUCTS

-- Select all columns from dimStockItem table
SELECT *
FROM dimStockItem;

-- Count the number of distinct colors in dimStockItem
SELECT COUNT(DISTINCT Color) AS colorcount
FROM dimStockItem
WHERE Color <> 'N/A';


-- EXPLORE CHEAPEST PRODUCT

-- Find the minimum unit price from dimStockItem where Stock Item Key is not 0
SELECT MIN([Unit Price]) FROM dimStockItem WHERE [Stock Item Key] != 0;

-- Return the names and prices of all products in dimStockItem
SELECT
[Stock Item] AS ProductName,
[Unit Price]
FROM dimStockItem;

-- Return the name and price of the lowest priced product in dimStockItem
SELECT
[Stock Item] AS ProductName,
[Unit Price]
FROM dimStockItem
WHERE [Unit Price] = (SELECT MIN([Unit Price]) FROM dimStockItem WHERE [Stock Item Key] != 0);

-- Return cheapest products excluding those with 'box', 'bag', or 'carton' in their names
SELECT
[Stock Item] AS ProductName,
[Unit Price]
FROM dimStockItem
WHERE [Stock Item Key] != 0
AND [Stock Item] NOT LIKE '%bag%'
AND [Stock Item] NOT LIKE '%box%'
AND [Stock Item] NOT LIKE '%carton%';


-- BLACK PRODUCTS CONTAINING MUG OR SHIRT

-- Return black products containing 'mug' or 'shirt'
SELECT
[Stock Item] AS ProductName,
[Unit Price]
FROM dimStockItem
WHERE ([Stock Item] LIKE '%mug%' OR [Stock Item] LIKE '%shirt%') AND Color = 'Black';

-- Return list of black products containing 'mug' or 'shirt' ordered by unit price
SELECT
[WWI Stock Item ID],
[Stock Item] AS ProductName,
[Unit Price]
FROM dimStockItem
WHERE ([Stock Item] LIKE '%mug%' OR [Stock Item] LIKE '%shirt%') AND Color = 'Black'
ORDER BY [Unit Price] ASC;


-- DELIVERY EFFICIENCY

-- CUSTOMERS BY BUYING GROUP

-- Count customers in each buying group and order by customer count
SELECT
[Buying Group],
COUNT([Customer Key]) AS CustomerCount
FROM dimCustomer
GROUP BY [Buying Group]
ORDER BY CustomerCount ASC;

-- Return postcodes with more than 3 Wingtip Toys shops for the buying group 'Wingtip Toys'
SELECT
[Postal Code]
FROM dimCustomer
WHERE [Buying Group] = 'Wingtip Toys'
GROUP BY [Postal Code]
HAVING COUNT([Customer Key]) > 3;


-- LIST CUSTOMERS IN SAME POSTAL CODE

-- Return list of customers in post codes with more than three Wingtip Customer shops
SELECT
[Postal Code],
Customer
FROM dimCustomer
WHERE [Postal Code] IN (
    SELECT
    [Postal Code]
    FROM dimCustomer
    WHERE [Buying Group] = 'Wingtip Toys'
    GROUP BY [Postal Code]
    HAVING COUNT([Customer Key]) > 3
);

-- Return list of customers in post codes with more than three Wingtip Customer shops, filtering for 'Wingtip Toys'
SELECT
[Postal Code],
Customer
FROM dimCustomer
WHERE [Buying Group] = 'Wingtip Toys'
AND [Postal Code] IN (
    SELECT
    [Postal Code]
    FROM dimCustomer
    WHERE [Buying Group] = 'Wingtip Toys'
    GROUP BY [Postal Code]
    HAVING COUNT([Customer Key]) > 3
);


-- ADVANCED QUERIES

-- GRANULARITY - FACT SALES

-- Return all sales with multiple rows per invoice to illustrate the granularity of the fact table
SELECT *
FROM factSale
WHERE [WWI Invoice ID] IN (
    SELECT [WWI Invoice ID]
    FROM factSale
    GROUP BY [WWI Invoice ID]
    HAVING COUNT([WWI Invoice ID]) > 1
)
ORDER BY [WWI Invoice ID];

-- TOP SELLING PRODUCTS

-- Return top 10 products in YTD 2016 based on total sales excluding tax
SELECT TOP 10
p.[Stock Item] AS Product,
SUM(s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax
FROM factSale AS s
INNER JOIN dimStockItem p
ON s.[Stock Item Key] = p.[Stock Item Key]
INNER JOIN dimDate AS d
ON s.[Invoice Date Key] = d.[Date]
WHERE d.[Fiscal Year] = 2016
GROUP BY p.[Stock Item]
ORDER BY YTDTotalSalesExcludingTax DESC;

-- SALES BY SALESPERSON AND PRODUCT

-- Return top 10 sales by employee and product in 2016 based on total sales excluding tax
SELECT TOP 10
e.Employee AS SalesPerson,
p.[Stock Item] AS Product,
SUM(s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax
FROM factSale AS s
INNER JOIN dimStockItem p
ON s.[Stock Item Key] = p.[Stock Item Key]
INNER JOIN dimDate AS d
ON s.[Invoice Date Key] = d.[Date]
INNER JOIN dimEmployee as e
ON s.[Salesperson Key] = e.[Employee Key]
WHERE d.[Fiscal Year] = 2016
GROUP BY p.[Stock Item], e.Employee
ORDER BY YTDTotalSalesExcludingTax DESC;

-- SALES BY SALESPERSON AND PRODUCT - PERCENT OF TOTAL BY SALES PERSON

-- Return top 10 sales by employee and product in 2016 with percent of total sales
SELECT TOP 10
e.Employee AS SalesPerson,
p.[Stock Item] AS Product,
SUM(s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax,
FORMAT(CAST(SUM(s.[Total Excluding Tax]) / (SELECT SUM(s.[Total Excluding Tax]) 
FROM factSale AS s 
INNER JOIN dimDate AS d
ON s.[Invoice Date Key] = d.[Date]
WHERE d.[Fiscal Year] = 2016) AS decimal (8,6)), 'P4') AS PercentOfSalesYTD
FROM factSale AS s
INNER JOIN dimStockItem p
ON s.[Stock Item Key] = p.[Stock Item Key]
INNER JOIN dimDate AS d
ON s.[Invoice Date Key] = d.[Date]
INNER JOIN dimEmployee as e
ON s.[Salesperson Key] = e.[Employee Key]
GROUP BY p.[Stock Item], e.Employee
ORDER BY YTDTotalSalesExcludingTax DESC;


-- SALES BY SALESPERSON AND PRODUCT - PERCENT OF TOTAL (USING SUBQUERY)

-- Return top 10 sales by employee and product in the most recent fiscal year with percent of total sales
SELECT TOP 10
e.Employee AS SalesPerson,
p.[Stock Item] AS Product,
SUM(s.[Total Excluding Tax]) AS YTDTotalSalesExcludingTax,
FORMAT(CAST(SUM(s.[Total Excluding Tax]) / (SELECT SUM(s.[Total Excluding Tax]) 
FROM factSale AS s 
INNER JOIN dimDate AS d
ON s.[Invoice Date Key] = d.[Date]
WHERE d.[Fiscal Year] = (SELECT MAX([Fiscal Year]) FROM factSale AS s INNER JOIN dimDate AS d ON s.[Invoice Date Key] = d.[Date])) AS decimal (8,6)), 'P4') 
AS PercentOfSalesYTD
FROM factSale AS s
INNER JOIN dimStockItem p
ON s.[Stock Item Key] = p.[Stock Item Key]
INNER JOIN dimDate AS d
ON s.[Invoice Date Key] = d.[Date]
INNER JOIN dimEmployee as e
ON s.[Salesperson Key] = e.[Employee Key]
WHERE d.[Fiscal Year] = (SELECT MAX([Fiscal Year]) FROM factSale AS s INNER JOIN dimDate AS d ON s.[Invoice Date Key] = d.[Date])
GROUP BY p.[Stock Item], e.Employee
ORDER BY YTDTotalSalesExcludingTax DESC;


-- TOP SELLING CHILLER PRODUCTS

-- Show quantity sold by stock item for chiller stock items
SELECT
p.[Stock Item],
SUM(Quantity) AS QuantitySold
FROM factSale AS s
RIGHT JOIN dimStockItem p
ON s.[Stock Item Key] = p.[Stock Item Key]
WHERE p.[Is Chiller Stock] = 1
GROUP BY ROLLUP(p.[Stock Item])
ORDER BY QuantitySold DESC;
