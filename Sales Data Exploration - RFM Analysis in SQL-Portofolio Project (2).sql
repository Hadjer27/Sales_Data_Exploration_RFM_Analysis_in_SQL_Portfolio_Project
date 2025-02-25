/* Inspecting Data */

select * from [dbo].[sales_data_sample]

/* Checking unique values */

select distinct status from [dbo].[sales_data_sample] 
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] 
select distinct COUNTRY from [dbo].[sales_data_sample] 
select distinct DEALSIZE from [dbo].[sales_data_sample] 
select distinct TERRITORY from [dbo].[sales_data_sample] 

select distinct MONTH_ID from [dbo].[sales_data_sample]
where year_id = 2005

/* ANALYSIS */
/* Let's start by grouping sales by productline*/


select PRODUCTLINE, SUM(convert(float,[SALES])) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc


select YEAR_ID, SUM(convert(float,[SALES])) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

select  DEALSIZE, SUM(convert(float,[SALES])) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc 

/* What was the best month for sales in a specific year ? How much was earned that month ? */

select [MONTH_ID], SUM(convert(float,[SALES])) Revenue, COUNT(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID= 2004
group by [MONTH_ID]
order by 2 desc

/* --November seems to be the month, what product do they sell in November, Classic I, believe */

select  MONTH_ID, PRODUCTLINE, SUM(convert(float,[SALES])) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 
group by  MONTH_ID, PRODUCTLINE
order by 3 desc

/* Who is our best customer (with RFM)  */

drop table if exists #rfm
;with rfm as 
(
    select CUSTOMERNAME, SUM(convert(float,[SALES])) MonetaryValue, AVG(convert(float,[SALES])) AvgMonetaryValue, count(ORDERNUMBER) Frequency, MAX(convert(date,[ORDERDATE])) LastOrderdate, (select MAX(convert(date,[ORDERDATE]))FROM[dbo].[sales_data_sample]) MaxOrderDate,
    DATEDIFF(DD, MAX(convert(date,[ORDERDATE])), (select MAX(convert(date,[ORDERDATE]))FROM[dbo].[sales_data_sample])) Recency
    from [dbo].[sales_data_sample] 
    group by CUSTOMERNAME 
   
),
rfm_calc as 
(
    select r.*,
        NTILE(4) OVER (order by Recency desc ) rfm_recency,
        NTILE(4) OVER (order by Frequency) rfm_frequency,
        NTILE(4) OVER (order by MonetaryValue) rfm_monetary
    FROM rfm r 
)
select 
    c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell, 
    cast(rfm_recency as varchar) + cast(rfm_frequency as varchar)+cast(rfm_monetary as varchar) as rfm_cell_string
into #rfm
from rfm_calc c

select * from #rfm

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311,221, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223,322, 233, 322,421,412,232) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432,423,234) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


select distinct(rfm_cell)
from #rfm

select CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary, rfm_cell,
    case 
        when rfm_cell BETWEEN 1 AND 4 THEN 'Lost customer'
        when rfm_cell BETWEEN 5 AND 8 THEN 'New customer'
        WHEN rfm_cell BETWEEN 9 AND 12 THEN 'Loyal'
    END rfm_segment2
from #rfm 


/* What products are most often sold together ? */


select distinct ordernumber, stuff
(
(select ',' + [PRODUCTCODE]
from [dbo].[sales_data_sample] p
where [ORDERNUMBER] in 
(
select [ORDERNUMBER]
from ( 
    select ORDERNUMBER, count(*) rn
				FROM [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
) m
where rn=2 
) and p.ORDERNUMBER =s.ORDERNUMBER
for xml path ('')), 1,1,'') ProductCodes
from [dbo].[sales_data_sample] s
order by 2 desc 
