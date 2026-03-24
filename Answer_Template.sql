--SQL Advance Case Study
select * from DIM_MANUFACTURER
select * from DIM_MODEL
select * from DIM_CUSTOMER
select * from DIM_LOCATION
select * from DIM_DATE
select * from FACT_TRANSACTIONS

--Q1--BEGIN 
select * 
from DIM_LOCATION as c inner join 
FACT_TRANSACTIONS as t on c.IDLocation = t.IDLocation
where Date >= '2005'

--Q1--ENDr

--Q2--BEGIN
select l.State , m.Manufacturer_Name , mo.Model_Name,count(*) as tot_model
from DIM_MANUFACTURER as m inner join 
DIM_MODEL as mo on m.IDManufacturer = M.IDManufacturer inner join 
FACT_TRANSACTIONS  as f on mo.IDModel = f.IDModel inner join 
DIM_LOCATION as l on l.IDLocation = f.IDLocation
where m.Manufacturer_Name = 'Samsung' and l.State = 'US'
group by l.State,m.Manufacturer_Name,mo.Model_Name
--Q2--END

--Q3--BEGIN  
select ZipCode , State,IDModel , count(*) as tot_transaction
from DIM_LOCATION as l inner join 
FACT_TRANSACTIONS as f on f.IDLocation = l.IDLocation
group by ZipCode,IDModel,State

--Q3--END

--Q4--BEGIN
SELECT mo.Model_Name, MIN(f.TotalPrice) AS MinPrice
FROM DIM_MODEL mo
JOIN FACT_TRANSACTIONS f 
    ON mo.IDModel = f.IDModel
GROUP BY mo.Model_Name
HAVING MIN(f.TotalPrice) = (
    SELECT MIN(TotalPrice) 
    FROM FACT_TRANSACTIONS
);

--Q4--END

--Q5--BEGIN
select mo.Model_Name,Manufacturer_Name,sum(quantity) as tot_sales,avg(TotalPrice) as avg_price
from DIM_MANUFACTURER as m inner join 
DIM_MODEL as mo on m.IDManufacturer = M.IDManufacturer inner join 
FACT_TRANSACTIONS  as f on mo.IDModel = f.IDModel inner join 
DIM_LOCATION as l on l.IDLocation = f.IDLocation
where mo.IDManufacturer in (select top 5 mo.IDManufacturer 
from FACT_TRANSACTIONS as f join DIM_MODEL as mo on f.IDModel = mo.IDModel
group by mo.IDManufacturer 
order by sum(f.quantity) desc
)
group by mo.Model_Name,Manufacturer_Name
order by avg_price

--Q5--END

--Q6--BEGIN
select c.Customer_Name , avg(totalprice) as avg_price
from DIM_CUSTOMER as c join FACT_TRANSACTIONS as f on f.IDCustomer = c.IDCustomer
where YEAR(Date) = '2009' 
group by c.Customer_Name
having avg(totalprice) >= 500
order by avg_price desc;

--Q6--END
	
--Q7--BEGIN  
with Yearly_rank as (
select year(date) as sales_year,m.IDModel,Model_Name ,SUM(quantity) as tot_qty,
DENSE_RANK() over(partition by Year(Date) order by sum(quantity) desc ) as ranks
from DIM_MODEL as m join FACT_TRANSACTIONS as f on m.IDModel = f.IDModel
where year(Date) in (2008,2009,2010)
group by m.IDModel,Model_Name,f.Date ),
topModels as (
select * from Yearly_rank where ranks<=5)
select Idmodel , model_name from topModels group by idModel,Model_Name
having count(Distinct sales_year) = 3;

--Q7--END	
--Q8--BEGIN
with yearly_sales as (
select m.Manufacturer_Name,year(f.Date) as sales_year ,sum(Quantity) as tot_sales
from DIM_MANUFACTURER as m join DIM_MODEL as mo on m.IDManufacturer = mo.IDManufacturer
join FACT_TRANSACTIONS as f on f.IDModel = mo.IDModel
where year(DAte) in (2009,2010)
group by m.Manufacturer_Name,f.Date),
ranked_sales as (select * , DENSE_RANK() over(partition by sales_year order by tot_sales desc) as ranks
from yearly_sales)
select sales_year,Manufacturer_Name,tot_sales
from ranked_sales
where ranks = 2

--Q8--END
--Q9--BEGIN
SELECT DISTINCT m.Manufacturer_Name
FROM FACT_TRANSACTIONS f
JOIN DIM_MODEL mo 
    ON f.IDModel = mo.IDModel
JOIN DIM_MANUFACTURER m 
    ON mo.IDManufacturer = m.IDManufacturer
WHERE YEAR(f.Date) = 2010
AND m.IDManufacturer NOT IN (
        SELECT DISTINCT m.IDManufacturer
        FROM FACT_TRANSACTIONS f
        JOIN DIM_MODEL mo 
            ON f.IDModel = mo.IDModel
        JOIN DIM_MANUFACTURER m 
            ON mo.IDManufacturer = m.IDManufacturer
        WHERE YEAR(f.Date) = 2009
);


--Q9--END

--Q10--BEGIN
WITH TopCustomers AS (
    SELECT TOP 100 
        f.IDCustomer
    FROM FACT_TRANSACTIONS f
    GROUP BY f.IDCustomer
    ORDER BY SUM(f.TotalPrice) DESC
),

YearlyData AS (
    SELECT 
        f.IDCustomer,
        YEAR(f.Date) AS SalesYear,
        AVG(f.TotalPrice) AS Avg_Spend,
        AVG(f.Quantity) AS Avg_Quantity
    FROM FACT_TRANSACTIONS f
    WHERE f.IDCustomer IN (SELECT IDCustomer FROM TopCustomers)
    GROUP BY f.IDCustomer, YEAR(f.Date)
),

FinalData AS (
    SELECT 
        IDCustomer,
        SalesYear,
        Avg_Spend,
        Avg_Quantity,
        LAG(Avg_Spend) OVER (
            PARTITION BY IDCustomer 
            ORDER BY SalesYear
        ) AS Prev_Year_Spend
    FROM YearlyData
)

SELECT 
    IDCustomer,
    SalesYear,
    Avg_Spend,
    Avg_Quantity,
    CASE 
        WHEN Prev_Year_Spend IS NULL THEN NULL
        ELSE ((Avg_Spend - Prev_Year_Spend) * 100.0 / Prev_Year_Spend)
    END AS Percent_Change_Spend
FROM FinalData
ORDER BY IDCustomer, SalesYear;

--Q10--END
	