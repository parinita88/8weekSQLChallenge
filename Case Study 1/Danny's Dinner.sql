
/* Question 1 - What is the total amount each customer spent at the restaurant? */
SELECT 
    sales.customer_id, SUM(menu.price) as 'Total Amount'
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY 2 DESC;

/* Question 2 - How many days has each customer visited the restaurant? */
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS 'No od Days Visited'
FROM
    sales
GROUP BY customer_id
ORDER BY 2 DESC;

/* Question 3 - What was the first item from the menu purchased by each customer? */
WITH date_cte AS (SELECT DISTINCT
    customer_id, product_name, order_date, RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as date_rank
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id)
    
SELECT 
    customer_id, product_name AS 'Product Name'
FROM
    cte
WHERE
    date_rank = 1;

/* Question 4 - What is the most purchased item on the menu and how many times was it purchased by all customers? */
SELECT 
    product_name AS 'Most Purchased Product',
    COUNT(*) AS 'No of purchases'
FROM
    sales
        JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY 2 DESC
LIMIT 1;

/* Question 5 - Which item was the most popular for each customer? */
WITH fav_item_cte AS (
SELECT 
    customer_id, product_name, COUNT(*) AS order_count, RANK() OVER(PARTITION BY customer_id ORDER BY count(*) desc ) as item_rank
FROM
    sales
        JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY 1 , 2)

SELECT 
    customer_id, product_name, order_count
FROM
    fav_item_cte 
WHERE
    item_rank = 1;


/* Question 6 - Which item was purchased first by the customer after they became a member? */
WITH min_date_cte AS (
SELECT 
    members.customer_id, product_id, sales.order_date, RANK() OVER(PARTITION BY customer_id ORDER BY order_date asc) date_rank
FROM
    members
        LEFT JOIN
    sales ON members.customer_id = sales.customer_id
        AND sales.order_date >= members.join_date)
SELECT 
    customer_id,
    menu.product_name AS 'First Purchase after Membership'
FROM
    min_date_cte
        LEFT JOIN
    menu ON min_date_cte.product_id = menu.product_id
WHERE
    date_rank = 1;
    

/* Question 7 - Which item was purchased just before the customer became a member? */
WITH max_date_cte AS (
SELECT 
    members.customer_id, order_date, product_name, RANK() OVER(PARTITION BY customer_id ORDER BY order_date desc) as date_rank
FROM
    members
        LEFT JOIN
    sales ON members.customer_id = sales.customer_id
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
WHERE
    order_date <= join_date)
SELECT 
    customer_id, product_name AS 'First Item Before Membership'
FROM
    max_date_cte
WHERE
    date_rank = 1;
    

/* Question 8 - What is the total items and amount spent for each member before they became a member? */
SELECT 
    members.customer_id,
    COUNT(menu.product_id) AS 'Total Items',
    SUM(price) AS 'Total Amount'
FROM
    members
        LEFT JOIN
    sales ON members.customer_id = sales.customer_id
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
WHERE
    sales.order_date < members.join_date
GROUP BY customer_id;

/* Question 9 - each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? */
SELECT 
    customer_id,
    SUM(price * (CASE
                WHEN product_name = 'sushi' THEN 20
                ELSE 10
            END)) AS 'Total Points'
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY customer_id;

/* Question 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */
SELECT 
    sales.customer_id,
    SUM(price * (CASE
                        WHEN
                            order_date < DATE_ADD(join_date, INTERVAL 6 DAY)
                                AND order_date >= join_date
                        THEN
                            20
                        WHEN product_name = 'sushi' THEN 20
                        ELSE 10
                    END)) AS 'Total Points'
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
        LEFT JOIN
    members ON sales.customer_id = members.customer_id
WHERE
    sales.order_date <= '2021–01–31'
GROUP BY customer_id;

/* Bonus Question 1 */
SELECT 
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    (CASE
        WHEN members.join_date > sales.order_date THEN 'N'
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END) AS member
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
        LEFT JOIN
    members ON members.customer_id = sales.customer_id
    
/* Bonus Question 2 */
WITH summary_rank_cte AS 
(SELECT 
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    (CASE
        WHEN members.join_date > sales.order_date THEN 'N'
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END) AS member
FROM
    sales
        LEFT JOIN
    menu ON sales.product_id = menu.product_id
        LEFT JOIN
    members ON members.customer_id = sales.customer_id)
    
SELECT 
    customer_id,
    order_date,
    product_name,
    price,
    member,
    (CASE
        WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
    END) AS ranking
FROM
    summary_rank_cte
