--#1. Number of People in the DB with no Middle Name
SELECT COUNT(*)
FROM AdventureWorks2019.Person.Person
WHERE MiddleName IS NOT NULL;


--#2. Number of Email Addresses that don't end in adventure-works.com
SELECT COUNT(*)
FROM AdventureWorks2019.Person.EmailAddress
WHERE EmailAddress NOT LIKE '%adventure-works.com';

--#3. Details from states with most sales between 2010 and 2011
SELECT terr.Name AS country, state.Name AS province, COUNT(*) AS num_orders, SalesYTD --, COUNT(terr.Name) OVER (PARTITION BY state.Name) AS total_orders
FROM AdventureWorks2019.Sales.SalesOrderHeader AS ord
LEFT JOIN AdventureWorks2019.Sales.SalesTerritory AS terr
ON ord.TerritoryID = terr.TerritoryID
LEFT JOIN AdventureWorks2019.Person.StateProvince AS state
ON terr.TerritoryID = state.TerritoryID
WHERE DATEPART(YEAR, ord.OrderDate) BETWEEN 2010 AND 2011
GROUP BY terr.Name, state.Name, SalesYTD
ORDER BY SalesYTD DESC, num_orders DESC, country, province;

--#4. What customers got the email promotion?
SELECT *
FROM AdventureWorks2019.Sales.vIndividualCustomer
WHERE EmailPromotion != 0;

--#5. Different types of contacts and how many are in the database
SELECT biz_con.ContactTypeID, contyp.Name AS contact_type, COUNT(*) AS num_contacts
FROM AdventureWorks2019.Person.BusinessEntityContact AS biz_con
LEFT JOIN AdventureWorks2019.Person.ContactType AS contyp
ON biz_con.ContactTypeID = contyp.ContactTypeID
GROUP BY contyp.Name, biz_con.ContactTypeID
HAVING COUNT(*) > 100;

--#6. List of all Purchasing Managers including their names
SELECT person.FirstName, person.MiddleName, person.LastName, CONCAT(person.FirstName, ' ', person.MiddleName, ' ', person.LastName) AS FullName
FROM AdventureWorks2019.Person.Person AS person
LEFT JOIN AdventureWorks2019.Person.BusinessEntityContact AS ent_con
ON person.BusinessEntityID = ent_con.PersonID
LEFT JOIN AdventureWorks2019.Person.ContactType AS con_typ
ON con_typ.ContactTypeID = ent_con.ContactTypeID
WHERE con_typ.Name = 'Purchasing Manager';


--#7. OrdeQty, the Name and the ListPrice of the order by Customer ID 635
SELECT ord_det.OrderQty, prod.Name productName, prod.ListPrice
FROM AdventureWorks2019.Sales.SalesOrderDetail ord_det
LEFT JOIN AdventureWorks2019.Sales.SalesOrderHeader header
ON ord_det.SalesOrderID = header.SalesOrderID
LEFT JOIN AdventureWorks2019.Production.Product prod
ON ord_det.ProductID = prod.ProductID
WHERE header.CustomerID = 635;
--There is no order in the database by Customer ID 635
SELECT *
FROM AdventureWorks2019.Sales.SalesOrderHeader
WHERE CustomerID < 1000;
--Further check shows no ID 635 order in the database from the oder header

--#8. SalesOrderID and UnitPrice for every Single Item Order
SELECT SalesOrderID, UnitPrice
FROM AdventureWorks2019.Sales.SalesOrderDetail
WHERE OrderQty = 1;

--#9. ProductName and CompanyName for customers who ordered productModel 'Racing Socks'
SELECT 
	prod.Name AS ProductName, 
	ven.Name AS CompanyName
FROM AdventureWorks2019.Production.Product prod
LEFT JOIN AdventureWorks2019.Purchasing.ProductVendor pro_ven
ON prod.ProductID = pro_ven.ProductID
LEFT JOIN AdventureWorks2019.Purchasing.Vendor ven
ON pro_ven.BusinessEntityID = ven.BusinessEntityID
WHERE ProductModelID IN (
	SELECT ProductModelID
	FROM AdventureWorks2019.Production.ProductModel
	WHERE Name = 'Racing Socks'
	);

--#10. How many products in ProductCategory 'Cranksets' have been sold to an address in London?
--SalesOrderHeader = Find Shipping Address ID
--Person.Address = Find City, connect to SalesOrderHeader via Address ID
--ProductCategory = Find the Product Category. Connect to Product Subcategory via Category ID
--ProductSubcategory = Find Subcategory ID. Use to connect to Production.Product
--Production.Product = Find Product ID, connect to SalesOrderDetail
--SalesOrderDetail = Find SalesOrderID, connect to SalesOrder Header


WITH LondonOrders AS (
	SELECT SalesOrderID
	FROM AdventureWorks2019.Sales.SalesOrderHeader
	WHERE ShipToAddressID IN (
		SELECT AddressID
		FROM AdventureWorks2019.Person.Address
		WHERE City = 'London')
),--First CTE to select Sales Order ID for all orders shipped to London

CranksOrders AS (
	SELECT SalesOrderID
	--FROM AdventureWorks2019.Production.ProductCategory cat
	FROM AdventureWorks2019.Production.ProductSubcategory subcat
	--ON cat.ProductCategoryID = subcat.ProductCategoryID
	LEFT JOIN AdventureWorks2019.Production.Product prod
	ON subcat.ProductSubcategoryID = prod.ProductSubcategoryID
	LEFT JOIN AdventureWorks2019.Sales.SalesOrderDetail sales_det
	ON sales_det.ProductID = prod.ProductID
	WHERE subcat.Name = 'Cranksets') --Second CTE to select Sales Order ID for all Crankset orders

SELECT COUNT(*)
FROM LondonOrders lo
INNER JOIN CranksOrders co --INNER JOIN, so only those common to both are selected
ON lo.SalesOrderID = co.SalesOrderID;
--Cranksets is actually a subcategory of Bikes, it's not in ProductCategory

--#11. Best selling item by value
WITH cte2 AS (SELECT 
	prd.Name AS Item,
	orddet.ProductID, 
	orddet.OrderQty,
	prd.StandardCost AS CostPrice,
	prd.ListPrice,
	orddet.UnitPrice,
	orddet.UnitPriceDiscount,
	LineTotal AS PricewDiscount,	
	OrderQty*(prd.ListPrice - prd.StandardCost) AS ListProfit,
	LineTotal-(OrderQty * StandardCost) AS SaleProfit
FROM AdventureWorks2019.Sales.SalesOrderDetail orddet
LEFT JOIN AdventureWorks2019.Production.Product prd
ON prd.ProductID = orddet.ProductID)

SELECT TOP 1 
Item, CostPrice, ListPrice, UnitPrice, SUM(ListProfit) AS totalListProfit, SUM(SaleProfit) AS totalProfit
FROM cte2
GROUP BY Item, CostPrice, ListPrice, UnitPrice
ORDER BY totalProfit DESC, totalListProfit DESC;