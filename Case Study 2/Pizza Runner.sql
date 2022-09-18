/*Data Cleaning - Customer Order*/
create temporary table tmp_customer_orders
select order_id, customer_id, pizza_id, 
(case when exclusions = 'null' then '' else exclusions end) as exclusions,
(case when extras = 'null' then '' 
when extras is null then ''
else extras end) as extras,
order_time
from customer_orders;

/*Data Cleaning - Runner Order*/
create temporary table tmp_runner_orders
select order_id, runner_id,
( case when pickup_time = 'null' then null 
else pickup_time end) as pickup_time,
(case when distance = 'null' then '0'
when distance like '%km' then trim(substring_index(distance, 'k', 1))
else distance end) as distance,
(
case when duration = 'null' then '0'
when duration like '%min%' then trim(substring_index(duration, 'm', 1))
else duration end
) as duration,
(
case when cancellation is null then ''
when cancellation = 'null' then ''
else cancellation end
)as cancellation
from runner_orders;

/* Change Data Type */
alter table tmp_customer_orders
modify order_time datetime;

alter table tmp_runner_orders
modify pickup_time datetime,
modify distance decimal(4,2),
modify duration int;

/* How many pizzas were ordered? */
SELECT 
    COUNT(*) AS 'No of Pizzas Ordered'
FROM
    tmp_customer_orders;

/* How many unique customer orders were made? */
SELECT 
    COUNT(DISTINCT order_id) AS 'Unique Customer Orders'
FROM
    tmp_customer_orders;

/* How many successful orders were delivered by each runner? */
SELECT 
    runner_id, COUNT(*) AS 'No of Order Delivered'
FROM
    tmp_runner_orders
WHERE
    cancellation = ''
GROUP BY runner_id;

/* How many of each type of pizza was delivered? */
SELECT 
    pizza_name, COUNT(*) AS 'No of Pizza Delivered'
FROM
    tmp_runner_orders
        LEFT JOIN
    tmp_customer_orders ON tmp_runner_orders.order_id = tmp_customer_orders.order_id
        LEFT JOIN
    pizza_names ON tmp_customer_orders.pizza_id = pizza_names.pizza_id
WHERE
    cancellation = ''
GROUP BY pizza_name;

/* How many Vegetarian and Meatlovers were ordered by each customer? */
SELECT 
    customer_id,
    SUM(CASE
        WHEN pizza_names.pizza_name = 'Meatlovers' THEN 1
        ELSE 0
    END) AS 'Meatlover count',
    SUM(CASE
        WHEN pizza_names.pizza_name = 'Vegetarian' THEN 1
        ELSE 0
    END) AS 'Vegetarian count'
FROM
    tmp_customer_orders
        LEFT JOIN
    pizza_names ON tmp_customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_id;

/* What was the maximum number of pizzas delivered in a single order? */
SELECT 
    COUNT(pizza_id) AS 'Max No of Pizza in a Order'
FROM
    tmp_customer_orders
        LEFT JOIN
    tmp_runner_orders ON tmp_customer_orders.order_id = tmp_runner_orders.order_id
WHERE
    cancellation = ''
GROUP BY tmp_customer_orders.order_id
ORDER BY COUNT(pizza_id) DESC
LIMIT 1;

/* For each customer, how many delivered pizzas had at least 1 change and how many had no changes? */
SELECT 
    customer_id,
    SUM(CASE
        WHEN exclusions = '' AND extras = '' THEN 1
        ELSE 0
    END) AS 'No change',
    SUM(CASE
        WHEN exclusions != '' OR extras != '' THEN 1
        ELSE 0
    END) AS 'One change'
FROM
    tmp_customer_orders
        LEFT JOIN
    tmp_runner_orders ON tmp_customer_orders.order_id = tmp_runner_orders.order_id
WHERE
    cancellation = ''
GROUP BY customer_id;

/* How many pizzas were delivered that had both exclusions and extras? */
SELECT 
    COUNT(*) AS 'Pizza with both exclusions and extras'
FROM
    tmp_customer_orders
        LEFT JOIN
    tmp_runner_orders ON tmp_customer_orders.order_id = tmp_runner_orders.order_id
WHERE
    exclusions != '' AND extras != ''
        AND cancellation = '';




