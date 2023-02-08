select * from gdb023.dim_customer;
select * from gdb023.dim_product;
select * from gdb023.fact_gross_price;
select * from gdb023.fact_manufacturing_cost;
select * from gdb023.fact_pre_invoice_deductions;
select * from gdb023.fact_sales_monthly;



/*Q1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates 
its  business in the  APAC  region.*/
select
	distinct market as Atliq_Exclusive_markets_in_APAC
from
	gdb023.dim_customer
where
	customer = 'Atliq Exclusive'
    and region = 'APAC'
order by
	1;
    
    
/* Q2. What is the percentage of unique product increase in 2021 vs. 2020? 
The  final output contains these fields,  
unique_products_2020  
unique_products_2021  
percentage_chg */
with yearly_unique_products_count as
(select
	(select 
		count(distinct product_code) 
	from 
		gdb023.fact_sales_monthly 
	where 
		fiscal_year = 2020) as unique_products_2020,
	(select 
		count(distinct product_code) 
	from 
		gdb023.fact_sales_monthly 
	where 
		fiscal_year = 2021) as unique_products_2021)

select
	*,
    round(100.0*(unique_products_2021 - unique_products_2020)/unique_products_2020, 2) as percentage_chg
from
	yearly_unique_products_count;
    
-- using cross join
with unique_products as 
(select 
	fiscal_year, 
    count(distinct product_code) as unique_products_count
from 
	gdb023.fact_sales_monthly
group by 
	fiscal_year)
select
	up1.unique_products_count as unique_products_2020,
    up2.unique_products_count as unique_products_2021,
    round(100.0*(up2.unique_products_count - up1.unique_products_count)/up1.unique_products_count, 2)
    as percentage_chg
from
	unique_products up1
cross join
	unique_products up2
where
	up1.fiscal_year = 2020
    and up2.fiscal_year = 2021;
    
    
/* Q3. Provide a report with all the unique product counts for each  segment  
and  sort them in descending order of product counts. The final output contains  
2 fields,  
segment  
product_count */
select
	segment,
    count(distinct product_code) as product_count
from
	gdb023.dim_product
group by
	segment
order by
	2 desc;
    
    
/* Q4. Follow-up: Which segment had the most increase in unique products in  
2021 vs 2020? The final output contains these fields,  
segment  
product_count_2020  
product_count_2021  
difference*/
with count_per_segment_per_year as 
(select
	prod.segment,
    sales.fiscal_year as year,
    count(distinct sales.product_code) as product_count
from
	gdb023.dim_product prod
inner join
	gdb023.fact_sales_monthly sales
on 
	prod.product_code = sales.product_code
group by
	prod.segment,
    sales.fiscal_year),
count_per_segment_per_year_pivot as
(select
	segment,
    sum(case when year = 2020 then product_count else 0 end) as product_count_2020,
    sum(case when year = 2021 then product_count else 0 end) as product_count_2021
from
	count_per_segment_per_year
group by
	segment)
    
select
	*,
    round(100.0*(product_count_2021 - product_count_2020)/product_count_2020, 2) as difference_prcnt
from
	count_per_segment_per_year_pivot
order by
	4 desc;
    
    
/* Q5.  Get the products that have the highest and lowest manufacturing costs.  
The final output should contain these fields,  
product_code  
product  
manufacturing_cost */
(select
	p.product_code,
    p.product,
    m.manufacturing_cost
from
	gdb023.dim_product p
inner join
	gdb023.fact_manufacturing_cost m
on
	p.product_code = m.product_code
order by
	manufacturing_cost desc
limit
	1)
union
(select
	p.product_code,
    p.product,
    m.manufacturing_cost
from
	gdb023.dim_product p
inner join
	gdb023.fact_manufacturing_cost m
on
	p.product_code = m.product_code
order by
	manufacturing_cost asc
limit
	1);
    
-- using min, max
(select
	p.product_code,
    p.product,
    max(m.manufacturing_cost) as manufacturing_cost
from
	gdb023.dim_product p
inner join
	gdb023.fact_manufacturing_cost m
on
	p.product_code = m.product_code
group by
	1,2)
union
(select
	p.product_code,
    p.product,
    min(m.manufacturing_cost) as manufacturing_cost
from
	gdb023.dim_product p
inner join
	gdb023.fact_manufacturing_cost m
on
	p.product_code = m.product_code
group by
	1,2); 


/* Q6.   Generate a report which contains the top 5 customers who received an  
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the  
Indian  market. The final output contains these fields,  
customer_code  
customer  
average_discount_percentage */
select
	i.customer_code,
    c.customer,
    i.pre_invoice_discount_pct as average_discount_percentage
from
	gdb023.dim_customer c
inner join
	gdb023.fact_pre_invoice_deductions i
on
	i.customer_code = c.customer_code
where
	i.fiscal_year = 2021
    and c.market = 'India'
order by
	3 desc
limit
	5;
    
    

/* Q7.    Get the complete report of the Gross sales amount for the customer  
“Atliq  Exclusive”  for each month  .  This analysis helps to  get an idea 
of low and  high-performing months and take strategic decisions.  
The final report contains these columns:  
Month  
Year  
Gross sales Amount */
select
	month(sales.date) as Month,
    year(sales.date) as Year,
    sum(sales.sold_quantity * price.gross_price) as "Gross sales Amount"
from
	gdb023.fact_sales_monthly sales 
inner join
	gdb023.fact_gross_price price
on
	sales.product_code = price.product_code
inner join
	gdb023.dim_customer customer
on
	sales.customer_code = customer.customer_code
where
	customer.customer = 'Atliq Exclusive'
group by
	1,2
order by
	sales.date;



/* Q8. In which quarter of 2020, got the maximum total_sold_quantity? 
The final  output contains these fields sorted by the total_sold_quantity,  
Quarter  
total_sold_quantity */
select
	quarter(date) as Quarter,
    sum(sold_quantity) as total_sold_quantity
from
	gdb023.fact_sales_monthly
where
	year(date) = 2020
group by
	quarter(date)
order by
	sum(sold_quantity) desc;

	

/* Q9.  Which channel helped to bring more gross sales in the fiscal year 
2021  and the percentage of contribution?  
The final output  contains these fields,  
channel  
gross_sales_mln  
percentage */
with sales_by_channel as 
(select
	customer.channel as channel,
    sum(sales.sold_quantity * price.gross_price)  as gross_sales
from
	dim_customer customer
inner join
	fact_sales_monthly sales
on
	sales.customer_code = customer.customer_code
inner join
	fact_gross_price price
on
	sales.product_code = price.product_code
where
	sales.fiscal_year = 2021
group by
	customer.channel)

select
	channel,
    round(1.0*gross_sales/1000000, 2) as gross_sales_mln,
    round(100.0*gross_sales/(select sum(gross_sales) from sales_by_channel), 2) as percentage
from
	sales_by_channel
order by
	3 desc;
    
    
    
/*  Q10. Get the Top 3 products in each division that have a high  
total_sold_quantity in the fiscal_year 2021? 
The final output contains these  fields,  
division  
product_code 
product  
total_sold_quantity 
rank_ord */
select
*
from
(select
	product.division,
    product.product_code,
    product.product,
    sum(sales.sold_quantity) as total_sold_quantity,
    dense_rank() over(
		partition by
			product.division
		order by
			sum(sales.sold_quantity) desc)
	as rank_ord
from
	gdb023.dim_product product
inner join
	gdb023.fact_sales_monthly sales
on
	product.product_code = sales.product_code
where
	sales.fiscal_year = 2021
group by
	1,2,3) sub
where
	rank_ord <=3;


    
	















