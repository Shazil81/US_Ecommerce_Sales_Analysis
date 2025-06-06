/* Data analysis */

/* 1.  List all unique cities where customers are located */
select distinct(customer_city) 
from customers;

/* 2.  count the number of ordered placed in 2017 */
select count(order_id) as Total_Orders 
from orders 
where year(order_purchase_timestamp) = '2017' ;

/* 3.  find total sales per category */

select upper(products.product_category) Category, 
sum(payments.payment_value) Total_sales 
from products join order_items
on products.product_id = order_items.product_id
join payments
on payments.order_id = order_items.order_id
group by Category;

/* 4.   calculate the percentage of orders that were paid in installments */

select (sum(case 
when payment_installments >= 1 then 1 else 0 end))/count(*) *100
from payments;

/* 5. count no of customers from each state  */

select customer_state, 
count(customer_id) as No_Of_Customers
from customers 
group by customer_state ;

/* 6.  calculate the number of orders per month in 2018 */

select monthname(order_purchase_timestamp) as months, count(order_id) as No_Of_Orders
from orders where year(order_purchase_timestamp) = '2018'
group by months ;

/* 7.  find the average number of products per order, grouped by customer city */

with count_per_order as 
(select orders.order_id, orders.customer_id, count(order_items.order_id) as oc
from orders join order_items
on orders.order_id = order_items.order_id
group by orders.order_id, orders.customer_id)

select customers.customer_city, round(avg(count_per_order.oc),2) average_orders
from customers join count_per_order
on customers.customer_id = count_per_order.customer_id
group by customers.customer_city order by average_orders desc;


/* 8.  calculate the percentage of total revenue contributed by each product category */

select upper(products.product_category) Category, 
round((sum(payments.payment_value)/(select sum(payment_value) from payments))*100,2) Sales_Percentage
from products join order_items 
on products.product_id = order_items.product_id
join payments 
on payments.order_id = order_items.order_id
group by Category order by Sales_Percentage desc;


/* 9.  identify the correlation between product price and the number of times a product has been purchased */

select products.product_category, count(order_items.product_id) as No_Of_Items,
round(avg(order_items.price),2) as Item_Price
from products join order_items
on products.product_id = order_items.product_id
group by products.product_category ;


/* 10.  Calculate the total revenue generated by each seller, and rank them by revenue */

select *, dense_rank() over(order by Revenue desc) as rn from
(select order_items.seller_id as Seller_Id, sum(payments.payment_value)
Revenue from order_items join payments
on order_items.order_id = payments.order_id
group by order_items.seller_id) as a;


/* 11.  calculate the moving average of order values for each customer over their order history */

select customer_id, order_purchase_timestamp, Payment,
avg(payment) over(partition by customer_id order by order_purchase_timestamp
rows between 2 preceding and current row) as Mov_Avg
from
(select orders.customer_id, orders.order_purchase_timestamp, 
payments.payment_value as Payment
from payments join orders
on payments.order_id = orders.order_id) as a;


/* 12. calculate the cumulative sales per month for each year  */

select Years, Months , Payment, sum(payment)
over(order by years, months) Cumulative_Sales from 
(select year(orders.order_purchase_timestamp) as Years,
month(orders.order_purchase_timestamp) as Months,
round(sum(payments.payment_value),2) as Payment from orders join payments
on orders.order_id = payments.order_id
group by Years, Months order by Years, Months) as a ;


/* 13. calculate the year-over-year growth rate of total sales */

with a as(select year(orders.order_purchase_timestamp) as Years,
round(sum(payments.payment_value),2) as payment from orders join payments
on orders.order_id = payments.order_id
group by Years order by Years)

select Years, ((payment - lag(payment, 1) over(order by years))/
lag(payment, 1) over(order by years)) * 100 as YOY_Growth from a ;

/* 14. identify the top 3 customers who spent the most money in each year */

select Years, Customer_Id, Payment, D_Rank
from
(select year(orders.order_purchase_timestamp) Years,
orders.customer_id as Customer_Id,
sum(payments.payment_value) Payment,
dense_rank() over(partition by year(orders.order_purchase_timestamp)
order by sum(payments.payment_value) desc) D_Rank
from orders join payments 
on payments.order_id = orders.order_id
group by year(orders.order_purchase_timestamp),
orders.customer_id) as a
where d_rank <= 3 ;