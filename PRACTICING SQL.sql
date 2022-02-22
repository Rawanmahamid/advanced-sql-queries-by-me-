--OVER()

SELECT P.FirstName,P.LastName,H.JobTitle,HS.Rate, AVG(HS.RATE) OVER() AS AVGRATE,MAX(HS.RATE) OVER () AS MAXRATE, HS.RATE - AVG(HS.RATE) OVER() AS DIFFRATE,(HS.RATE/MAX(HS.RATE) OVER () )* 100 AS PERCRATE
FROM [Person].Person P JOIN HumanResources.Employee H ON P.BusinessEntityID=H.BusinessEntityID
JOIN HumanResources.EmployeePayHistory HS ON P.BusinessEntityID=HS.BusinessEntityID 


--PARTITION BY 

SELECT P.Name AS PRODUCTNAME,P.ListPrice,PS.Name AS PRODSUBC,PC.Name AS PRODCAT,AVG(P.LISTPRICE) OVER (PARTITION BY PC.NAME) AS AVGPRCAT,AVG(P.LISTPRICE) OVER (PARTITION BY PC.NAME, PS.NAME) AS AVGPRCATSUB,P.ListPrice- AVG(P.LISTPRICE) OVER (PARTITION BY PC.NAME) AS DELTA
FROM Production.Product P JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID=PS.ProductSubcategoryID 
JOIN Production.ProductCategory PC ON PS.ProductCategoryID=PC.ProductCategoryID


--ROW_NUMBER

SELECT P.Name AS PRODUCTNAME,P.ListPrice,PS.Name AS PRODSUBC,PC.Name AS PRODCAT,
ROW_NUMBER() OVER(ORDER BY P.LISTPRICE DESC) AS PRICERANK,
ROW_NUMBER() OVER (PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC)AS CATPRCRANK,
CASE WHEN ROW_NUMBER() OVER (PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC)<= 5 THEN 'YES' ELSE 'NO' END AS TOP5
FROM Production.Product P JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID=PS.ProductSubcategoryID 
JOIN Production.ProductCategory PC ON PS.ProductCategoryID=PC.ProductCategoryID


--RANK AND DENSE_RANK

SELECT P.Name AS PRODUCTNAME,P.ListPrice,PS.Name AS PRODSUBC,PC.Name AS PRODCAT,
ROW_NUMBER() OVER(ORDER BY P.LISTPRICE DESC) AS PRICERANK,
ROW_NUMBER() OVER (PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC)AS CATPRCRANK,
CASE WHEN ROW_NUMBER() OVER (PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC)<= 5 THEN 'YES' ELSE 'NO' END AS TOP5,
RANK() OVER(PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC) AS PRRANK,
DENSE_RANK() OVER (PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC) AS PRDNSRANK,
CASE WHEN DENSE_RANK() OVER (PARTITION BY PC.NAME ORDER BY P.LISTPRICE DESC)<= 5 THEN 'YES' ELSE 'NO' END AS TOP55
FROM Production.Product P JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID=PS.ProductSubcategoryID 
JOIN Production.ProductCategory PC ON PS.ProductCategoryID=PC.ProductCategoryID


--LEAD AND LAG

SELECT P.PurchaseOrderID,P.OrderDate,P.TotalDue,V.Name AS VENDORNAME,
LAG(P.TOTALDUE) OVER(PARTITION BY V.NAME ORDER BY P.ORDERDATE) AS PRVORDVEND,
LEAD(V.Name) OVER(PARTITION BY P.EMPLOYEEID ORDER BY P.ORDERDATE) AS NXTORDVEND,
LEAD(V.Name,2) OVER(PARTITION BY P.EMPLOYEEID ORDER BY P.ORDERDATE) AS NXT2ORDVEND
FROM Purchasing.PurchaseOrderHeader P JOIN Purchasing.Vendor V ON P.VendorID=V.BusinessEntityID
WHERE P.TotalDue >500 AND YEAR(P.ORDERDATE) >=2013 


--SUBQUERY

SELECT *
FROM
(SELECT P.PurchaseOrderID,P.VendorID,P.OrderDate,P.TaxAmt,P.Freight,P.TotalDue,DENSE_RANK() OVER(PARTITION BY P.VENDORID ORDER BY P.TOTALDUE DESC) AS DNSRNK
FROM Purchasing.PurchaseOrderHeader P)TB
WHERE DNSRNK<=3

--SUBQUERY SINGLE VALUE

SELECT BusinessEntityID,JobTitle,VacationHours,(SELECT MAX(VACATIONHOURS) FROM HumanResources.Employee) AS MAXVCHORS,
(VacationHours*1.00 / (SELECT MAX(VACATIONHOURS) FROM HumanResources.Employee)) AS PERCVHOURS
FROM HumanResources.Employee
WHERE (VacationHours*1.00 / (SELECT MAX(VACATIONHOURS) FROM HumanResources.Employee))>=0.8


--FOR XML PATH

SELECT Name AS SUBNAME ,
STUFF ((SELECT ',' + Name
FROM  Production.Product PP
WHERE PP.ProductSubcategoryID=PS.ProductSubcategoryID AND PP.ListPrice>50
FOR XML PATH ('')),1,1,'') AS PRODUCT
FROM Production.ProductSubcategory PS


--PIVOT
SELECT [GENDER] AS [EMPLOYEE GENDER] ,[SALES REPRESENTATIVE],[BUYER],[JANITOR]
FROM
(SELECT JobTitle,VacationHours,Gender
FROM HumanResources.Employee) B
PIVOT(AVG(VACATIONHOURS) FOR JOBTITLE IN ([SALES REPRESENTATIVE],[BUYER],[JANITOR]))A


--CTE

WITH SALES AS
(
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Sales.SalesOrderHeader
		) 
,TOP10SALES AS
(SELECT ORDERMONTH,SUM(TOTALDUE) AS TOTALSALES
FROM SALES
WHERE ORDERRANK>10
GROUP BY ORDERMONTH)
, PURCHASES AS
(SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader

)
,TOP10PUR AS
(SELECT ORDERMONTH,SUM(TOTALDUE) AS TOTALPUR
FROM PURCHASES
WHERE OrderRank > 10
	GROUP BY OrderMonth)
SELECT A.OrderMonth,A.TOTALSALES,B.TOTALPUR
FROM TOP10SALES A JOIN TOP10PUR B ON A.OrderMonth=B.OrderMonth
ORDER BY 1

---CTE RECURSIVE

WITH CTE AS 
(SELECT 1 AS ODD

UNION ALL

SELECT ODD + 2
FROM CTE
WHERE ODD<99
)
SELECT ODD
FROM CTE

GO

WITH DATECTE AS 
(SELECT CAST('2020-01-01' AS DATE) AS MYDATE
UNION ALL
SELECT DATEADD(MONTH,1,MYDATE) AS MYDATE
FROM DATECTE
WHERE MYDATE<CAST('2029-12-01' AS DATE)
)
SELECT MYDATE
FROM DATECTE
OPTION(MAXRECURSION 10000)

--TEMP TABLES



		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #SALES		
		FROM AdventureWorks2019.Sales.SalesOrderHeader
		
		
SELECT ORDERMONTH,SUM(TOTALDUE) AS TOTALSALES
INTO #TOP10SALES
FROM #SALES
WHERE ORDERRANK>10
GROUP BY ORDERMONTH

SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
INTO #PURCHASES
		FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader


SELECT ORDERMONTH,SUM(TOTALDUE) AS TOTALPUR
INTO #TOP10PUR
FROM #PURCHASES
WHERE OrderRank > 10
	GROUP BY OrderMonth

SELECT A.OrderMonth,A.TOTALSALES,B.TOTALPUR
FROM #TOP10SALES A JOIN #TOP10PUR B ON A.OrderMonth=B.OrderMonth
ORDER BY 1

--CREATE AND INSERT
DROP TABLE #SALES
CREATE TABLE #SALES (OrderDate DATE
		  ,OrderMonth DATE
		  ,TotalDue MONEY
		  ,OrderRank INT)
INSERT INTO #SALES

		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Sales.SalesOrderHeader

	SELECT *
	FROM #SALES
DROP TABLE #TOP10SALES
CREATE TABLE #TOP10SALES
(ORDERMONTH DATE, TOTALSALES MONEY)
INSERT INTO #TOP10SALES

SELECT ORDERMONTH,SUM(TOTALDUE) AS TOTALSALES
FROM #SALES
WHERE ORDERRANK>10
GROUP BY ORDERMONTH
SELECT *
FROM #TOP10SALES


DROP TABLE #PURCHASES
CREATE TABLE #PURCHASES(OrderDate DATE
		  ,OrderMonth DATE
		  ,TotalDue MONEY
		  ,OrderRank INT )

INSERT INTO #PURCHASES
SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader
DROP TABLE #TOP10PUR
CREATE TABLE #TOP10PUR (ORDERMONTH DATE,TOTALPUR MONEY)
INSERT INTO #TOP10PUR
SELECT ORDERMONTH,SUM(TOTALDUE) AS TOTALPUR
FROM #PURCHASES
WHERE OrderRank > 10
	GROUP BY OrderMonth

SELECT A.OrderMonth,A.TOTALSALES,B.TOTALPUR
FROM #TOP10SALES A JOIN #TOP10PUR B ON A.OrderMonth=B.OrderMonth
ORDER BY 1

--TRUNCATE
DROP TABLE #ORDERS
CREATE TABLE #ORDERS (OrderDate DATE
		  ,OrderMonth DATE
		  ,TotalDue MONEY
		  ,OrderRank INT)
INSERT INTO #ORDERS

		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Sales.SalesOrderHeader

	SELECT *
	FROM #ORDERS

DROP TABLE #TOP10ORDERS
CREATE TABLE #TOP10ORDERS
(ORDERMONTH DATE,ORDERTYPE VARCHAR (30), TOTALSALES MONEY)
INSERT INTO #TOP10ORDERS

SELECT ORDERMONTH,'SALES' AS ORDERTYPE,SUM(TOTALDUE) AS TOTALSALES
FROM #ORDERS
WHERE ORDERRANK>10
GROUP BY ORDERMONTH
SELECT *
FROM #TOP10ORDERS


TRUNCATE TABLE #ORDERS

INSERT INTO #ORDERS
SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader



INSERT INTO #TOP10ORDERS
SELECT ORDERMONTH,'PURCHASE' AS DATATYPE,SUM(TOTALDUE) AS TOTALPUR
FROM #ORDERS
WHERE OrderRank > 10
	GROUP BY OrderMonth

SELECT A.OrderMonth,A.TOTALSALES,B.TOTALSALES 
FROM #TOP10ORDERS A JOIN #TOP10ORDERS B ON A.OrderMonth=B.OrderMonth AND A.ORDERTYPE='SALES'
WHERE  B.ORDERTYPE='PURCHASE'
ORDER BY 1


SELECT *
FROM #TOP10ORDERS
DROP TABLE #ORDERS
DROP TABLE #TOP10ORDERS


--UPDATE

CREATE TABLE #SalesOrders
(
 SalesOrderID INT,
 OrderDate DATE,
 TaxAmt MONEY,
 Freight MONEY,
 TotalDue MONEY,
 TaxFreightPercent FLOAT,
 TaxFreightBucket VARCHAR(32),
 OrderAmtBucket VARCHAR(32),
 OrderCategory VARCHAR(32),
 OrderSubcategory VARCHAR(32)
)

INSERT INTO #SalesOrders
(
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory
)

SELECT
 SalesOrderID,
 OrderDate,
 TaxAmt,
 Freight,
 TotalDue,
 OrderCategory = 'Non-holiday Order'

FROM [AdventureWorks2019].[Sales].[SalesOrderHeader]

WHERE YEAR(OrderDate) = 2013


UPDATE #SalesOrders
SET 
TaxFreightPercent = (TaxAmt + Freight)/TotalDue,
OrderAmtBucket = 
	CASE
		WHEN TotalDue < 100 THEN 'Small'
		WHEN TotalDue < 1000 THEN 'Medium'
		ELSE 'Large'
	END


UPDATE #SalesOrders
SET TaxFreightBucket = 
	CASE
		WHEN TaxFreightPercent < 0.1 THEN 'Small'
		WHEN TaxFreightPercent < 0.2 THEN 'Medium'
		ELSE 'Large'
	END


UPDATE #SalesOrders
SET  OrderCategory = 'Holiday'
FROM #SalesOrders
WHERE DATEPART(quarter,OrderDate) = 4


UPDATE #SalesOrders
SET OrderSubcategory = CONCAT(OrderCategory,' ','-',' ',OrderAmtBucket)

SELECT *
FROM #SalesOrders


--OPTIMIZING WITH UPDATE

SELECT 
	   A.BusinessEntityID
      ,A.Title
      ,A.FirstName
      ,A.MiddleName
      ,A.LastName
	  ,B.PhoneNumber
	  ,PhoneNumberType = C.Name
	  ,D.EmailAddress

FROM AdventureWorks2019.Person.Person A
	LEFT JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID
	LEFT JOIN AdventureWorks2019.Person.PhoneNumberType C
		ON B.PhoneNumberTypeID = C.PhoneNumberTypeID
	LEFT JOIN AdventureWorks2019.Person.EmailAddress D
		ON A.BusinessEntityID = D.BusinessEntityID


		DROP TABLE #DETAILS
CREATE TABLE #DETAILS
		(BusinessEntityID INT
		,Title CHAR(5)
		,FirstName VARCHAR (30)
		  ,MiddleName VARCHAR (30)
		  ,LastName VARCHAR (30)
		  ,PhoneNumber VARCHAR(30)
		  ,PhoneNumberType VARCHAR (30)
		  ,EmailAddress VARCHAR (70)
)
INSERT INTO #DETAILS
(BusinessEntityID 
		,Title 
		,FirstName 
		  ,MiddleName
		  ,LastName )

SELECT BusinessEntityID,Title,FirstName,MiddleName,LastName FROM PERSON.Person

SELECT *
FROM #DETAILS
ORDER BY 1

UPDATE D
SET D.PhoneNumber=P.PhoneNumber,D.PhoneNumberType=AA.Name
FROM #DETAILS D JOIN PERSON.PersonPhone P ON D.BusinessEntityID=P.BusinessEntityID 
 JOIN Person.PhoneNumberType AA ON P.PhoneNumberTypeID=AA.PhoneNumberTypeID

UPDATE D
SET D.EmailAddress=E.EmailAddress
FROM #DETAILS D JOIN PERSON.EmailAddress E ON D.BusinessEntityID=E.BusinessEntityID


--OPTIMIZED WITH UPDATE AND EXISTS 

SELECT
       A.PurchaseOrderID,
	   A.OrderDate,
	   A.TotalDue

FROM AdventureWorks2019.Purchasing.PurchaseOrderHeader A

WHERE EXISTS (
	SELECT
	1
	FROM AdventureWorks2019.Purchasing.PurchaseOrderDetail B
	WHERE A.PurchaseOrderID = B.PurchaseOrderID
		AND B.RejectedQty > 5
)

ORDER BY 1


CREATE TABLE #IMP (PurchaseOrderID INT,
	   OrderDate DATETIME,
	   TotalDue MONEY
	   ,REJQTY INT)
INSERT INTO #IMP(PurchaseOrderID ,
	   OrderDate ,
	   TotalDue)
SELECT PurchaseOrderID,OrderDate,TotalDue FROM Purchasing.PurchaseOrderHeader

SELECT *
FROM #IMP
WHERE REJQTY IS NOT NULL

UPDATE #IMP
SET REJQTY=B.RejectedQty
FROM #IMP A JOIN Purchasing.PurchaseOrderDetail B
ON A.PurchaseOrderID=B.PurchaseOrderID
WHERE B.RejectedQty>5

--OPTIMIZING WITH INDEXES

SELECT 
	   A.BusinessEntityID
      ,A.Title
      ,A.FirstName
      ,A.MiddleName
      ,A.LastName
	  ,B.PhoneNumber
	  ,PhoneNumberType = C.Name
	  ,D.EmailAddress

FROM AdventureWorks2019.Person.Person A
	LEFT JOIN AdventureWorks2019.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID
	LEFT JOIN AdventureWorks2019.Person.PhoneNumberType C
		ON B.PhoneNumberTypeID = C.PhoneNumberTypeID
	LEFT JOIN AdventureWorks2019.Person.EmailAddress D
		ON A.BusinessEntityID = D.BusinessEntityID


		DROP TABLE #DETAILS
CREATE TABLE #DETAILS
		(BusinessEntityID INT
		,Title CHAR(5)
		,FirstName VARCHAR (30)
		  ,MiddleName VARCHAR (30)
		  ,LastName VARCHAR (30)
		  ,PhoneNumber VARCHAR(30)
		  ,PhoneNumberType VARCHAR (30)
		  ,EmailAddress VARCHAR (70)
)
INSERT INTO #DETAILS
(BusinessEntityID 
		,Title 
		,FirstName 
		  ,MiddleName
		  ,LastName )

SELECT BusinessEntityID,Title,FirstName,MiddleName,LastName FROM PERSON.Person

SELECT *
FROM #DETAILS
ORDER BY 1

UPDATE D
SET D.PhoneNumber=P.PhoneNumber,D.PhoneNumberType=AA.Name
FROM #DETAILS D JOIN PERSON.PersonPhone P ON D.BusinessEntityID=P.BusinessEntityID 
 JOIN Person.PhoneNumberType AA ON P.PhoneNumberTypeID=AA.PhoneNumberTypeID

CREATE CLUSTERED INDEX DET_IDX ON #DETAILS(BusinessEntityID)
CREATE NONCLUSTERED INDEX DET_IDX1 ON #DETAILS(PHONENUMBERTYPE)


UPDATE D
SET D.EmailAddress=E.EmailAddress
FROM #DETAILS D JOIN PERSON.EmailAddress E ON D.BusinessEntityID=E.BusinessEntityID
CREATE NONCLUSTERED INDEX DET_IDX2 ON #DETAILS(EMAILADDRESS)

--lookup table
DROP TABLE CALENDAR
create table calendar 
(datee date ,daynumber int ,daynameE varchar(11),DAYmonthnumber int,monthnUMBER INT,yearnumber int,weekendflag tinyint,holidayflag tinyint)

with cte as (
select cast('1993-11-18' as date) as mydate

union all

select dateadd(day,1,mydate)
from cte 
where mydate <= cast('2022-02-19' as date))


insert into calendar
(datee)
select mydate
from cte
option(maxrecursion 12000)

select *
from calendar


update calendar
set
	daynumber=datepart(WEEKDAY,datee),
	daynameE=format(datee,'dddd'),
	DAYmonthnumber=day(datee),
	monthnUMBER=MONTH(DATEE),
	YEARNUMBER=YEAR(DATEE)
	
UPDATE calendar
SET 
	weekendflag =
	CASE 
	    WHEN daynameE IN('FRIDAY','SATURDAY') THEN 1 ELSE 0
		END


UPDATE calendar
SET holidayflag=
CASE WHEN monthnUMBER IN (4,5,6,8) THEN 1
ELSE 0
END

SELECT A.* ,B.daynameE,B.monthnUMBER
FROM Purchasing.PurchaseOrderHeader A JOIN calendar B
ON A.OrderDate=B.datee
WHERE B.holidayflag=1 AND B.weekendflag=1



--VARIABLES

DECLARE @MAXVCHR INT

SELECT @MAXVCHR=(SELECT MAX(VacationHours) FROM AdventureWorks2019.HumanResources.Employee)
SELECT @MAXVCHR

SELECT
	   BusinessEntityID
      ,JobTitle
      ,VacationHours
	  ,MaxVacationHours = @MAXVCHR
	  ,PercentOfMaxVacationHours = (VacationHours * 1.0) / @MAXVCHR

FROM AdventureWorks2019.HumanResources.Employee

WHERE (VacationHours * 1.0) / @MAXVCHR >= 0.8

-----
DECLARE @TODAY DATE
SET @TODAY=CAST(GETDATE() AS DATE)

DECLARE @14DAY  DATE SET @14DAY=DATEFROMPARTS(YEAR(@TODAY),MONTH(@TODAY),14)
DECLARE @ENDPPP DATE SET @ENDPPP = CASE WHEN DAY(@TODAY)<15 THEN DATEADD(MONTH,-1,@14DAY) ELSE @14DAY END
DECLARE @STRT DATE SET @STRT=DATEADD(DAY,1,DATEADD(MONTH,-1,@ENDPPP))
SELECT @TODAY,@14DAY,@STRT,@ENDPPP

--FUNCTIONS
GO
USE AdventureWorks2019
GO
ALTER FUNCTION DBO.PERD(@FIRST FLOAT,@SECOND FLOAT)
RETURNS VARCHAR(10) AS
BEGIN

DECLARE @CON VARCHAR(90)= CONCAT(CONVERT(DECIMAL(5,2),(@FIRST/@SECOND))*100,'%')
RETURN @CON
END

SELECT DBO.PERD(8,10)



--
DECLARE @MAXVAC FLOAT
SET
@MAXVAC =(SELECT MAX(VACATIONHOURS) FROM HumanResources.Employee)

SELECT BusinessEntityID,JobTitle,VacationHours,
DBO.PERD(VacationHours,@MAXVAC) AS PERCVAC
FROM HumanResources.Employee


---PROCEDURES
GO
ALTER PROC ODS(@ORDERTYPE INT,@ABC INT,@STRTYR INT,@ENDYR INT)
AS BEGIN
	IF @ORDERTYPE=1
		BEGIN
		SELECT *,'SALES'AS ORDERTYPE
		FROM Sales.SalesOrderHeader
		WHERE TotalDue>@ABC AND YEAR(OrderDate) BETWEEN @STRTYR AND @ENDYR
		END
	IF @ORDERTYPE=2
		BEGIN
		SELECT *,'PURCHASE' AS ORDERTYPE
		FROM Purchasing.PurchaseOrderHeader
		WHERE TotalDue>@ABC AND YEAR(OrderDate) BETWEEN @STRTYR AND @ENDYR
		END
	ELSE
	BEGIN
	CREATE TABLE #ALLORDERS(ORDERID INT,TotalDue MONEY,OrderDate DATETIME,ORDERTYPE VARCHAR(10))
	INSERT INTO #ALLORDERS
	SELECT SalesOrderID ,TotalDue,OrderDate,'SALES'AS ORDERTYPE
		FROM Sales.SalesOrderHeader
		WHERE TotalDue>@ABC AND YEAR(OrderDate) BETWEEN @STRTYR AND @ENDYR
		UNION ALL
		SELECT PurchaseOrderID,TotalDue,OrderDate,'PURCHASE' AS ORDERTYPE
		FROM Purchasing.PurchaseOrderHeader
		WHERE TotalDue>@ABC AND YEAR(OrderDate) BETWEEN @STRTYR AND @ENDYR
		SELECT*
		FROM #ALLORDERS
	END	
	
END

EXEC ODS 3,70,2012,2013

--DYNAMIC SQL

create PROC dbo.pr (@NAME VARCHAR(32) ,@SEARCH VARCHAR(32)) AS
BEGIN
DECLARE @DSQL VARCHAR(MAX)
SET @DSQL='SELECT '
SET @DSQL=@DSQL+@NAME
SET @DSQL=@DSQL+'NAME FROM PERSON.PERSON WHERE '
SET @DSQL=@DSQL+@NAME
SET @DSQL=@DSQL+'NAME LIKE %'
SET @DSQL=@DSQL+@SEARCH
SET @DSQL=@DSQL+'%'
EXEC(@DSQL)
END
select @DSQL
EXEC dbo.pr 'first','a'