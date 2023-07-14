-- Utilizing Microsoft Server SQL to examine and extract valuable findings from the Adventure Works 2019 dataset.

USE AdventureWorks2019;

SELECT * FROM HumanResources.Employee
ORDER BY JobTitle 

SELECT * FROM Person.Person
ORDER BY LastName;

-- let's look at the employee details arranged in ascending order using the last name
SELECT FirstName, LastName, businessentityid AS Employee_id
FROM Person.Person
ORDER BY LastName; 

-- let's look at the product's information and select sell start date with data and where product line is 'T'
SELECT ProductID,ProductNumber, Name
 FROM Production.Product
 WHERE SellStartDate IS NOT NULL 
 AND ProductLine = 'T'
 ORDER BY Name;

-- now, let's look at the percentage of tax to subtotal. The table return shows two orders had over 10 percent tax to subtotal 
SELECT SalesOrderID, CustomerID,OrderDate, SubTotal, 
(TaxAmt/SubTotal)*100 AS percentage_tax_column
FROM sales.salesorderheader
ORDER BY SubTotal desc;

-- let see the unique jobtitles available in the employee's table
SELECT DISTINCT (JobTitle) FROM HumanResources.Employee
ORDER BY JobTitle

-- We look at the total freight by the customers.
SELECT CustomerID, SUM(Freight) AS Total_frieight 
FROM sales.salesorderheader
GROUP BY CustomerID
ORDER BY CustomerID;

-- We now look at the average and sum of the subtotal grouped by customer and the saleperson
SELECT CustomerID,AVG(SubTotal) AS Avg_subtotal, SUM(SubTotal) AS Subtotal
FROM sales.salesorderheader
GROUP BY CustomerID, SalesPersonID
ORDER BY CustomerID DESC;

-- now let's look at retrieving the products with the total quantity of 500+ by product only for product that are in shelf A,C and H
SELECT  ProductID, SUM(Quantity) AS Total_Quantity
 FROM Production.ProductInventory
 WHERE Shelf IN ('A','C','H')
 GROUP BY ProductID
 HAVING SUM(Quantity) > 500
 ORDER BY ProductID


-- We look at the total quantity by location with id greater than 10
SELECT LocationID,SUM(Quantity) 
FROM Production.ProductInventory
GROUP BY LocationID
HAVING LocationID > 9

-- Let's look at employee's phone numbers arranged in alphabetical order with LastName starting with 'L'
SELECT person.BusinessEntityID AS employeeID, person.FirstName,person.LastName, PhoneNumber
FROM Person.Person
JOIN Person.PersonPhone ON Person.BusinessEntityID = PersonPhone.BusinessEntityID
WHERE LastName LIKE 'L%'
ORDER BY LastName, FirstName;

-- Herre, let's look at total subtotal by salespersons and customers. the ROLLUP function allows us to generate subtotals at different grouping levels, providing a comprehensive summary of the data.

SELECT SalesPersonID, CustomerID,  SUM(SubTotal) AS sum_Subtotal
 FROM Sales.SalesOrderHeader
 GROUP BY ROLLUP (SalesPersonID, CustomerID);

-- We look at the total quantity of the distinct combination of location and shelf. in this case we used CUBE which can be use to grop data along multiple axis.
SELECT LocationID, Shelf, SUM(Quantity) AS TotalQuantity
 FROM Production.ProductInventory
GROUP BY CUBE (LocationID, shelf)

-- We want to look at number of employee that resides in each city
SELECT a.City, COUNT(a.AddressID) AS no_of_employee
 FROM PERSON.Address a
    JOIN Person.BusinessEntityAddress b
    ON a.AddressID=b.AddressID
 GROUP BY City
 ORDER BY City

-- let's look at the total due amount by order year
SELECT YEAR(OrderDate) AS Order_year, SUM(TotalDue) FROM sales.SalesOrderHeader 
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate)

SELECT YEAR(OrderDate) AS Order_year, SUM(TotalDue) FROM sales.SalesOrderHeader 
WHERE YEAR(OrderDate) <= 2016
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate)

-- let's look at designation that are managers
SELECT ContactTypeID, Name 
FROM Person.ContactType
WHERE Name LIKE '%Manager%'
ORDER BY ContactTypeID DESC

-- now, let's retrieve the names of persons designated with purchasing manager
SELECT b.BusinessEntityID,p.LastName,p.FirstName,name
 FROM Person.BusinessEntityContact b
 JOIN Person.ContactType c
  ON b.ContactTypeID = c.ContactTypeID
 JOIN Person.Person p
 ON b.PersonID = p.BusinessEntityID
 WHERE Name = 'Purchasing Manager'
 ORDER BY LastName, FirstName
 
-- Now, let's retrieve the salesperson for each PostalCode who belongs to a territory and SalesYTD is not zero
WITH RankedSales AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY pa.PostalCode ORDER BY sp.SalesYTD DESC) AS "Row Number",
           pp.LastName,
           sp.SalesYTD,
           pa.PostalCode
    FROM Sales.SalesPerson AS sp
    INNER JOIN Person.Person AS pp ON sp.BusinessEntityID = pp.BusinessEntityID
    INNER JOIN Person.Address AS pa ON pa.AddressID = pp.BusinessEntityID
    WHERE TerritoryID IS NOT NULL AND SalesYTD <> 0
)
SELECT "Row Number", LastName, SalesYTD, PostalCode
FROM RankedSales
ORDER BY PostalCode;

-- return the total ListPrice and StandardCost of products for each color. Products that name starts with 'Mountain' and ListPrice is more than zero
SELECT Color,SUM(ListPrice) AS TotalListPrice, SUM(StandardCost) AS TotalStandardCost 
FROM Production.Product
WHERE Name LIKE 'Mountain%' AND Color IS NOT NULL
GROUP BY Color
HAVING SUM(ListPrice) > 0
ORDER BY Color;

-- Show the summary of the TotalSalesYTD amounts for all SalesQuota groups and return SalesQuota and TotalSalesYTD.
SELECT SalesQuota, SUM(SalesYTD) AS TotalSalesYTD,
GROUPING(SalesQuota) AS Grouping
FROM Sales.SalesPerson
GROUP BY ROLLUP (SalesQuota )

-- Now, We Want to Analyze Salary Percentiles by Department: Exploring Employee Salary Distribution and Ranking
SELECT eph.Department, eph.LastName, edh.Rate,  CUME_DIST() OVER (PARTITION BY Department ORDER BY Rate) AS CumulativeDistribution, PERCENT_RANK() OVER (PARTITION BY Department ORDER BY Rate) AS Percentage_Rank
 FROM HumanResources.vemployeedepartmenthistory AS eph
 JOIN HumanResources.EmployeePayHistory AS edh
 ON eph.BusinessEntityID = edh.BusinessEntityID
 ORDER BY Department, Rate DESC;

-- We Want to Identify the Least Expensive Product: Exploring the Lowest List Price
SELECT Name, ListPrice,
       FIRST_VALUE(Name) OVER (ORDER BY ListPrice ASC) AS LeastExpensive
FROM Production.Product
WHERE ProductSubcategoryID = 1;

-- Now, let's return the employee with the fewest number of vacation hours compared to other employees with the same job title,
SELECT e.JobTitle,p.LastName,e.VacationHours, FIRST_VALUE(LastName) OVER (PARTITION BY JobTitle ORDER BY VacationHours) AS FEWERVACATIONHRS
FROM HumanResources.Employee AS e
JOIN Person.Person AS p
ON e.BusinessEntityID = p.BusinessEntityID;

-- Let's Calculate Row Number for Salespeople Based on Year-to-Date Sales Ranking
SELECT ROW_NUMBER() OVER (ORDER BY SalesYTD DESC) AS Row_number, FirstName, LastName, ROUND(SalesYTD,2) AS 'Sales YTD'
FROM Sales.vSalesPerson
WHERE TerritoryName IS NOT NULL AND SalesYTD <> 0;

-- Lastly, let's retrieve the employee's Weekly salary by their full name
SELECT CAST(ep.RateChangeDate AS DATE) AS RateDate , CONCAT(p.LastName, ', ', p.MiddleName, ' ', p.FirstName) AS FullName, ep.Rate * 40 AS WeeklySalary
FROM HumanResources.EmployeePayHistory AS ep
JOIN Person.Person AS p ON ep.BusinessEntityID = p.BusinessEntityID
ORDER BY FullName;