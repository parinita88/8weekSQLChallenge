/*Data Cleaning - Customer Order*/
CREATE TEMPORARY TABLE tmp_customer_orders
SELECT order_id, customer_id, pizza_id, 
# nulls in exclusions
(CASE WHEN exclusions = 'null' THEN '' ELSE exclusions END) AS exclusions,
# nulls in extras
(CASE WHEN extras = 'null' THEN '' 
WHEN extras IS NULL THEN ''
ELSE extras END) AS extras,
# change data typr of order_time
CAST(order_time AS DATETIME) AS order_time
FROM customer_orders;

/*Data Cleaning - Runner Order*/
CREATE TEMPORARY TABLE tmp_runner_orders
SELECT order_id, runner_id,
# nulls in pickup_time
CAST(( CASE WHEN pickup_time = 'null' THEN NULL 
ELSE pickup_time END) AS DATETIME) AS pickup_time,
# nulls and cast in distance
CAST((CASE WHEN distance = 'null' THEN '0'
WHEN distance LIKE '%km' THEN TRIM(SUBSTRING_INDEX(distance, 'k', 1))
ELSE distance END) AS DECIMAL(4,2))AS distance,
# nulls and cast in duration
CAST((
CASE WHEN duration = 'null' THEN '0'
WHEN duration LIKE '%min%' THEN TRIM(SUBSTRING_INDEX(duration, 'm', 1))
ELSE duration END
) AS UNSIGNED) AS duration,
# nulls in cancellation
(
CASE WHEN cancellation IS NULL THEN ''
WHEN cancellation = 'null' THEN ''
ELSE cancellation END
)AS cancellation
FROM runner_orders;

/* PART A. Pizza Metrics */
SELECT 
    COUNT(*) AS 'No of Pizzas Ordered'
FROM
    tmp_customer_orders;

/* Question 2 - How many unique customer orders were made? */
SELECT 
    COUNT(DISTINCT order_id) AS 'Unique Customer Orders'
FROM
    tmp_customer_orders;

/* Question 3 - How many successful orders were delivered by each runner? */
SELECT 
    runner_id, COUNT(*) AS 'No of Order Delivered'
FROM
    tmp_runner_orders
WHERE
    cancellation = ''
GROUP BY runner_id;

/* Question 4 - How many of each type of pizza was delivered? */
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

/* Question 5 - How many Vegetarian and Meatlovers were ordered by each customer? */
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

/* Question 6 - What was the maximum number of pizzas delivered in a single order? */
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

/* Question 7 - For each customer, how many delivered pizzas had at least 1 change and how many had no changes? */
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

/* Question 8 - How many pizzas were delivered that had both exclusions and extras? */
SELECT 
    COUNT(*) AS 'Pizza with both exclusions and extras'
FROM
    tmp_customer_orders
        LEFT JOIN
    tmp_runner_orders ON tmp_customer_orders.order_id = tmp_runner_orders.order_id
WHERE
    exclusions != '' AND extras != ''
        AND cancellation = '';

/* Question 9 - What was the total volume of pizzas ordered for each hour of the day */
WITH RECURSIVE timeSlots (t) AS (
    SELECT 0
    UNION ALL
    SELECT t +3600 FROM timeSlots WHERE t < (23*3600)
    )
    
SELECT 
    TIME_FORMAT(SEC_TO_TIME(t), '%H'),
    COUNT(customer_orders.order_id)
FROM
    timeslots
        LEFT JOIN
    customer_orders ON timeslots.t = HOUR(customer_orders.order_time) * 3600
GROUP BY 1
ORDER BY 1;

/* Question 10 - What was the volume of orders for each day of the week? */
WITH RECURSIVE daysofweek (d) AS (
    SELECT 1
    UNION ALL
    SELECT d +1 FROM daysofweek WHERE d < 7
    )

SELECT 
    (CASE d
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END) AS 'Day of week',
    COUNT(customer_orders.order_id) AS 'No of Orders'
FROM
    daysofweek
        LEFT JOIN
    customer_orders ON daysofweek.d = DAYOFWEEK(customer_orders.order_time)
GROUP BY 1
ORDER BY 2 DESC;

/* END OF PART A */

SELECT 
    EXTRACT(WEEK FROM `registration_date`) AS 'Week No',
    COUNT(`runner_id`) AS 'Runner count'
FROM
    runners
GROUP BY 1;

/* Question 2 - What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order? */
WITH pickup_time_cte AS (
SELECT 
    runner_id,
    tmp_runner_orders.order_id,
    order_time,
    pickup_time,
    TIMESTAMPDIFF(MINUTE,
        order_time,
        pickup_time) AS pickup_time_mins
FROM
    tmp_runner_orders
        JOIN
    tmp_customer_orders ON tmp_runner_orders.order_id = tmp_customer_orders.order_id
WHERE
    duration > 0
GROUP BY 1 , 2 , 3 , 4)

SELECT 
    pickup_time_cte.runner_id,
    AVG(pickup_time_cte.pickup_time_mins) AS 'Avg Pickup Time (Mins)'
FROM
    pickup_time_cte
GROUP BY 1;

/* Question 3 - Is there any relationship between the number of pizzas and how long the order takes to prepare? */
WITH relation_count_time_cte AS (
SELECT 
    tmp_runner_orders.order_id,
    COUNT(pizza_id) AS 'No of Pizza Ordered',
    TIMESTAMPDIFF(MINUTE,
        order_time,
        pickup_time) AS prep_time_min
FROM
    tmp_customer_orders
        JOIN
    tmp_runner_orders ON tmp_customer_orders.order_id = tmp_runner_orders.order_id
WHERE
    pickup_time IS NOT NULL
GROUP BY 1 , 3)

SELECT 
    relation_count_time_cte.`No of Pizza Ordered`,
    AVG(prep_time_min) AS `Avg Prep Time`
FROM
    relation_count_time_cte
GROUP BY 1;


/* Question 4 - What was the average distance travelled for each customer? */
WITH avg_order_cte AS (
SELECT 
    customer_id,
    tmp_customer_orders.order_id,
    AVG(tmp_runner_orders.distance) AS distance
FROM
    tmp_customer_orders
        JOIN
    tmp_runner_orders ON tmp_customer_orders.order_id = tmp_runner_orders.order_id
WHERE
    distance != 0
GROUP BY 1 , 2)

SELECT 
    customer_id, ROUND(AVG(distance), 2) AS avg_dist_per_cust
FROM
    avg_order_cte
GROUP BY 1;

/* Question 5 - What was the difference between the longest and shortest delivery times for all orders? */
SELECT 
    MAX(duration) - MIN(duration) AS Diff
FROM
    tmp_runner_orders
WHERE
    duration != 0;
 
/* Question 6 - What was the average speed for each runner for each delivery and do you notice any trend for these values? */
SELECT 
    runner_id,
    order_id,
    ROUND(AVG(distance * 60 / duration), 2) AS 'Avg Speed'
FROM
    tmp_runner_orders
WHERE
    duration != 0
GROUP BY 1 , 2;
 
/* Question 7 - What is the successful delivery percentage for each runner? */
SELECT 
    runner_id,
    (SUM(CASE
        WHEN cancellation = '' THEN 1
        ELSE 0
    END) / COUNT(order_id)) * 100 AS 'Successful Percentage'
FROM
    tmp_runner_orders
GROUP BY runner_id;
 
/* Part C. Ingredient Optimisation */

SELECT 
    *
FROM
    pizza_toppings;

/* Question 2 - What was the most commonly added extra? */
WITH extras_cte AS (
SELECT 
    extras
FROM
    customer_orders
WHERE
    extras != '' AND extras NOT LIKE '%,%'
        AND extras != 'null'
        AND extras IS NOT NULL 
UNION ALL SELECT 
    TRIM(SUBSTRING_INDEX(extras, ',', 1))
FROM
    customer_orders
WHERE
    extras LIKE '%,%' 
UNION ALL SELECT 
    TRIM(SUBSTRING_INDEX(extras, ',', - 1))
FROM
    customer_orders
WHERE
    extras LIKE '%,%'),

max_extras_cte AS (
	SELECT 
    MAX(extras_count.count)
FROM
    (SELECT 
        COUNT(*) AS count
    FROM
        extras_cte
    GROUP BY extras) extras_count
	)

SELECT 
    extras AS extra_id, pizza_toppings.topping_name
FROM
    extras_cte
        JOIN
    pizza_toppings ON extras_cte.extras = pizza_toppings.topping_id
GROUP BY 1 , 2
HAVING COUNT(*) = (SELECT 
        *
    FROM
        max_extras_cte);


/* Question 3 - What was the most common exclusion? */
WITH exclusions_cte AS (
SELECT 
    exclusions
FROM
    customer_orders
WHERE
    exclusions != ''
        AND exclusions NOT LIKE '%,%'
        AND exclusions IS NOT NULL
        AND exclusions != 'null'
UNION ALL
SELECT 
    TRIM(SUBSTRING_INDEX(exclusions, ',', 1))
FROM
    customer_orders
WHERE
    exclusions LIKE '%,%'
UNION ALL
SELECT 
    TRIM(SUBSTRING_INDEX(exclusions, ',', -1))
FROM
    customer_orders
WHERE
    exclusions LIKE '%,%'),
    
max_exclusions_cte AS (
	SELECT 
    MAX(count)
FROM
    (SELECT 
        COUNT(*) AS count
    FROM
        exclusions_cte
    GROUP BY exclusions) exclusions_count
	)

SELECT 
    exclusions AS exclusion_id, pizza_toppings.topping_name
FROM
    exclusions_cte
        JOIN
    pizza_toppings ON exclusions_cte.exclusions = pizza_toppings.topping_id
GROUP BY 1 , 2
HAVING COUNT(*) = (SELECT 
        *
    FROM
        max_exclusions_cte) ;


/* Question 4 - 
Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

WITH tmp_customer_order_formatting_step1 AS (
SELECT 
    pizza_id,
    (CASE
        WHEN extras LIKE '%,%' THEN SUBSTRING_INDEX(extras, ',', 1)
        ELSE extras
    END) extra_1_id,
    (CASE
        WHEN extras LIKE '%,%' THEN SUBSTRING_INDEX(extras, ',', - 1)
    END) extra_2_id,
    (CASE
        WHEN exclusions LIKE '%,%' THEN SUBSTRING_INDEX(exclusions, ',', 1)
        ELSE exclusions
    END) exclusion_1_id,
    (CASE
        WHEN exclusions LIKE '%,%' THEN SUBSTRING_INDEX(exclusions, ',', - 1)
    END) exclusion_2_id
FROM
    tmp_customer_orders ),
 
tmp_customer_order_formatting_step2 AS (
SELECT 
    pizza_names.pizza_name pizza_name,
    (CASE
        WHEN exclusion_1_id = '' THEN ''
        ELSE CONCAT(' - Exclude ', exclusion1.topping_name)
    END) exclusion1,
    (CASE
        WHEN exclusion_2_id IS NULL THEN ''
        ELSE CONCAT(', ', exclusion2.topping_name)
    END) exclusion2,
    (CASE
        WHEN extra_1_id = '' THEN ''
        ELSE CONCAT(' - Extra ', extra1.topping_name)
    END) extra1,
    (CASE
        WHEN extra_2_id IS NULL THEN ''
        ELSE CONCAT(', ', extra2.topping_name)
    END) extra2
FROM
    tmp_customer_order_formatting_step1
        LEFT JOIN
    pizza_names ON tmp_customer_order_formatting_step1.pizza_id = pizza_names.pizza_id
        LEFT JOIN
    pizza_toppings extra1 ON tmp_customer_order_formatting_step1.extra_1_id = extra1.topping_id
        LEFT JOIN
    pizza_toppings extra2 ON tmp_customer_order_formatting_step1.extra_2_id = extra2.topping_id
        LEFT JOIN
    pizza_toppings exclusion1 ON tmp_customer_order_formatting_step1.exclusion_1_id = exclusion1.topping_id
        LEFT JOIN
    pizza_toppings exclusion2 ON tmp_customer_order_formatting_step1.exclusion_2_id = exclusion2.topping_id)

SELECT 
    CONCAT(pizza_name,
            exclusion1,
            exclusion2,
            extra1,
            extra2)
FROM
    tmp_customer_order_formatting_step2;
 
 /* END OF PART C */