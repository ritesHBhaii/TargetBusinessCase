

#A. INITIAL EXPLORATION - (I) Getting familiar with the metadata

SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'customers'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'sellers'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'products'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'payment'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'order_reviews'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'orders'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'order_items'
ORDER BY ordinal_position;


SELECT column_name, data_type
FROM `dsml-sql-382115.Target_business_case.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'geolocation'
ORDER BY ordinal_position;





#A. INITIAL EXPLORATION - (II) Checking the time range between which the orders were placed to understand the dataset coverage duration

SELECT MIN(order_purchase_timestamp) as first_order_date, MAX(order_purchase_timestamp) as last_order_date
FROM `dsml-sql-382115.Target_business_case.orders`;




#A. INITIAL EXPLORATION - (III) Checking the number of cities and states where customers have placed orders

SELECT count(DISTINCT c.customer_city) as total_customer_cities, count(DISTINCT c.customer_state) as total_customer_states
FROM `dsml-sql-382115.Target_business_case.orders` o
JOIN `dsml-sql-382115.Target_business_case.customers` c
ON o.customer_id = c.customer_id;



#A. INITIAL EXPLORATION - (IV) Checking the number of rows in different tables to check data completeness and relationships among the tables

SELECT count(*) from `dsml-sql-382115.Target_business_case.customers`;
SELECT count(*) from `dsml-sql-382115.Target_business_case.orders`;
SELECT count(*) from `dsml-sql-382115.Target_business_case.payments`;
SELECT count(*) from `dsml-sql-382115.Target_business_case.order_items`;


#A. INITIAL EXPLORATION - (V) Checking cancelled / undelivered orders - null delivery date

SELECT count(*) as total_rows, COUNTIF(order_delivered_customer_date IS NULL) as missing_delivery_date
FROM `dsml-sql-382115.Target_business_case.orders`;


#A. INITIAL EXPLORATION - (VI) Checking if all the order IDs are unique or not


SELECT count(*) as total_rows, count(distinct order_id) as unique_order_ids 
from `dsml-sql-382115.Target_business_case.orders`;




#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#





#B. IN-DEPTH EXPLORATION - (I) Checking the e-commerce demand trend in the past few years 

SELECT extract(YEAR from order_purchase_timestamp) as order_year, count(distinct order_id) as total_orders
from `Target_business_case.orders`
group by order_year
order by order_year;



#B. IN-DEPTH EXPLORATION - (II) Checking monthly seasonality in orders

SELECT FORMAT_TIMESTAMP('%B', order_purchase_timestamp) AS order_month, count(DISTINCT order_id) AS total_orders
FROM `dsml-sql-382115.Target_business_case.orders`
group by order_month, extract(MONTH from order_purchase_timestamp)
order by extract(MONTH from order_purchase_timestamp);




#B. IN-DEPTH EXPLORATION - (III) Checking daily order purchase trend based on the time of purchase

SELECT CASE 
 WHEN extract(hour FROM order_purchase_timestamp) between 0 and 6 then 'Dawn'
 WHEN extract(hour FROM order_purchase_timestamp) between 7 and 12 then 'Morning'
 WHEN extract(hour FROM order_purchase_timestamp) between 12 and 18 then 'Evening'
 ELSE 'Night'
end as time_of_day, count(distinct order_id) as total_orders
from `dsml-sql-382115.Target_business_case.orders`
group by time_of_day
order by total_orders desc;







#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#





#C. E-commerce analysis - (I) Checking month on month number of orders placed in each state 

SELECT c.customer_state, FORMAT_TIMESTAMP('%Y-%m', o.order_purchase_timestamp) as year_month, COUNT(DISTINCT o.order_id) as total_orders
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
group by c.customer_state, year_month
order by c.customer_state, year_month;



#C. E-commerce analysis - (II) Checking customer distribution across all states

SELECT customer_state, count(distinct customer_unique_id) as total_customers
from `dsml-sql-382115.Target_business_case.customers`
group by customer_state
order by total_customers desc;









#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#





#D. Impact on economy - (I) % Increase in cost of orders from 2017 to 2018 (Jan to Aug only)

with yearly_sales as (
  select extract(YEAR from o.order_purchase_timestamp) as order_year,
  sum(p.payment_value) as total_sales
  from `Target_business_case.orders` o JOIN `Target_business_case.payments` p
  on o.order_id = p.order_id
  where extract(MONTH from o.order_purchase_timestamp) between 1 and 8 
  and extract(YEAR from o.order_purchase_timestamp) in (2017,2018)
  group by order_year
)
SELECT max(case when order_year=2017 then total_sales end) as sales_2017,
       max(case when order_year=2018 then total_sales end) as sales_2018,
       round((max(case when order_year=2018 then total_sales end) - max(case when order_year=2017 then total_sales end))/max(case when order_year=2017 then total_sales end) * 100,2) as percentage_increase
from yearly_sales;




#D. Impact on economy - (II) - Calculating total and average order value for every state 

select c.customer_state,round(sum(p.payment_value), 2) as total_order_value, round(avg(p.payment_value), 2) as avg_order_value
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
join `dsml-sql-382115.Target_business_case.payments` p
on o.order_id = p.order_id
group by c.customer_state
order by total_order_value desc;



#D. Impact on economy - (III) - Calculating total and average freight value for each state 

select c.customer_state, round(sum(oi.freight_value), 2) as total_freight_value,
round(avg(oi.freight_value), 2) as avg_freight_value
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
join `dsml-sql-382115.Target_business_case.order_items` oi
on o.order_id = oi.order_id
group by c.customer_state
order by total_freight_value desc;





#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#





#E. Analysis on sales, freight and delivery times - 
#(I) - Checking actual delivery time vs difference in estimated and actual delivery time


select order_id, order_purchase_timestamp, order_delivered_customer_date, order_estimated_delivery_date,
date_diff(date(order_delivered_customer_date),date(order_purchase_timestamp),day) as time_to_deliver_days,
date_diff(date(order_delivered_customer_date),date(order_estimated_delivery_date),day) as diff_estimated_delivery_days
from `dsml-sql-382115.Target_business_case.orders`
where order_delivered_customer_date is not null;


#E. Analysis on sales, freight and delivery times - (II) - Checking top 5 states with highest average freight value


select c.customer_state, round(avg(oi.freight_value), 2) as avg_freight
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
join `dsml-sql-382115.Target_business_case.order_items` oi
on o.order_id = oi.order_id
group by c.customer_state
order by avg_freight desc
limit 5;



#E. Analysis on sales, freight and delivery times - (III) - Checking top 5 states with lowest average freight value

select c.customer_state, round(avg(oi.freight_value), 2) as avg_freight
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
join `dsml-sql-382115.Target_business_case.order_items` oi
on o.order_id = oi.order_id
group by c.customer_state
order by avg_freight asc
limit 5;


#E. Analysis on sales, freight and delivery times - (IV) - Checking top 5 states with highest average delivery time

select c.customer_state,
round(avg(date_diff(date(o.order_delivered_customer_date),date(o.order_purchase_timestamp),day)), 2) as avg_delivery_days
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by avg_delivery_days desc
limit 5;


#E. Analysis on sales, freight and delivery times - (V) - Checking top 5 states with lowest average delivery time

select c.customer_state,
round(avg(date_diff(date(o.order_delivered_customer_date),date(o.order_purchase_timestamp),day)), 2) as avg_delivery_days
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by avg_delivery_days asc
limit 5;



#E. Analysis on sales, freight and delivery times - (VI) - Checking top 5 states where delivery was made faster than expected

select c.customer_state,
round(avg(date_diff(date(o.order_delivered_customer_date),date(o.order_estimated_delivery_date),day)),2) as avg_delivery_vs_estimate
from `dsml-sql-382115.Target_business_case.orders` o
join `dsml-sql-382115.Target_business_case.customers` c
on o.customer_id = c.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by avg_delivery_vs_estimate asc
limit 5;






#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------------------------------------------------------------------------#





#F. Payments analysis - (I) - Checking month on month no. of orders using different payment types

select * from (
  select format_timestamp('%Y-%m', o.order_purchase_timestamp) as year_month,
         p.payment_type,
         o.order_id
  from `dsml-sql-382115.Target_business_case.orders` o
  join `dsml-sql-382115.Target_business_case.payments` p
  on o.order_id = p.order_id)
pivot ( count(distinct order_id)
  for payment_type in ('credit_card', 'UPI', 'voucher', 'debit_card'))
order by year_month;



#F. Payments analysis - (II) - Checking number of orders based on payment installments

select payment_installments, count(distinct order_id) as total_orders,
round(count(distinct order_id) * 100.0 /(sum(count(distinct order_id)) over ()),2) as order_share_percentage
from `dsml-sql-382115.Target_business_case.payments`
group by payment_installments
order by payment_installments;





#######################################################################################################################################