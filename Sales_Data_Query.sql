-- inspecting the sales data 
select * from dbo.sales

-- checking for unique values 
select distinct status from [dbo].[sales_data_sample] 
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample]
select distinct COUNTRY from [dbo].[sales_data_sample] 
select distinct DEALSIZE from [dbo].[sales_data_sample] 
select distinct TERRITORY from [dbo].[sales_data_sample] 

-- Sales by product line analysis 
select PRODUCTLINE, sum(sales) as Revenue
from dbo.sales
group by PRODUCTLINE
order by Revenue desc

--Classic cars makes the most revenue and then vintage cars. Trains makes the least revenue. 

--Which year did they make the most money? 

select YEAR_ID, sum(sales) as Revenue
from dbo.sales
group by YEAR_ID
order by Revenue desc

--2004, then 2003 and then 2005

select distinct MONTH_ID from dbo.sales
where year_id = 2005
--They didn't make that much money in 2005 because they only operated for 5 months 

--Which sizes make the most revenue? 
select  DEALSIZE,  sum(sales) as Revenue
from dbo.sales
group by  DEALSIZE
order by Revenue desc

--What was the best month for sales? 

select  MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from dbo.sales
where YEAR_ID = 2003 --change year 
group by  MONTH_ID
order by Revenue desc

--November seems to be the best month for sales 

--Which product do they sell the most in November? 
select  MONTH_ID, PRODUCTLINE, sum(sales) as Revenue, count(ORDERNUMBER)
from dbo.sales
where YEAR_ID = 2004 and MONTH_ID = 11 --change year 
group by  MONTH_ID, PRODUCTLINE
order by Revenue desc

--Classic cars 

--What city has the highest number of sales in a specific country:

select city, sum (sales) as Revenue
from dbo.sales
where country = 'UK' -- change country
group by city
order by Revenue desc


--what is the best prodcut in the United states? 

select country, YEAR_ID, PRODUCTLINE, sum(sales) as Revenue
from dbo.sales
where country = 'USA' 
group by  country, YEAR_ID, PRODUCTLINE
order by Revenue desc

--Who's their best customer (using RFM) 
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from dbo.sales) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from dbo.sales)) Recency
	from dbo.sales
	group by CUSTOMERNAME

	),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm