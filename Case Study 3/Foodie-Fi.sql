-- Section A. Customer Journey
-- Question 1 - Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

SELECT 
    customer_id, plan_name, start_date
FROM
    foodie_fi.subscriptions
        JOIN
    foodie_fi.plans USING (plan_id)
ORDER BY 1 , 3;


-- Section B. Data Analysis
-- Question 1 - How many customers has Foodie-Fi ever had?

SELECT 
    COUNT(DISTINCT customer_id)
FROM
    foodie_fi.subscriptions;

-- Question 2 - What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT 
    TO_CHAR(start_date, 'Month') AS Month,
    COUNT(*) AS new_trial_count
FROM
    foodie_fi.subscriptions
WHERE
    plan_id = 0
GROUP BY 1 , EXTRACT(MONTH FROM start_date)
ORDER BY EXTRACT(MONTH FROM start_date);

-- Question 3 - What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

-- event: joining a new plan
WITH new_plan_cte AS (
SELECT 
    plan_id, COUNT(*) AS No, 'Started New Plan' AS status
FROM
    foodie_fi.subscriptions
WHERE
    EXTRACT(YEAR FROM start_date) > 2020
GROUP BY 1),

-- event: upgraded a plan
cancel_cte AS (
SELECT 
    s1.plan_id, COUNT(*) AS No, 'Changed Plan' AS status
FROM
    foodie_fi.subscriptions s1
        LEFT JOIN
    foodie_fi.subscriptions s2 USING (customer_id)
WHERE
    s1.plan_id != s2.plan_id
        AND s2.start_date >= s1.start_date
        AND EXTRACT(YEAR FROM s2.start_date) > 2020
GROUP BY 1 )

-- Union results
SELECT 
    plan_id, status, No
FROM
    cancel_cte 
UNION SELECT 
    plan_id, status, No
FROM
    new_plan_cte
ORDER BY 1 , 2;

-- Question 4 - What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
    (SUM(CASE
        WHEN plan_name = 'churn' THEN 1
        ELSE 0
    END) * 100.0 / (COUNT(DISTINCT customer_id))) AS Count_Churned,
    ROUND((SUM(CASE
                WHEN plan_name = 'churn' THEN 1
                ELSE 0
            END) * 100.0 / (COUNT(DISTINCT customer_id))),
            1) AS Percent_Churned
FROM
    foodie_fi.subscriptions
        LEFT JOIN
    foodie_fi.plans ON subscriptions.plan_id = plans.plan_id;

-- Question 5 - How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

SELECT 
    ROUND(SUM(CASE
                WHEN s1.plan_id = 0 AND s2.plan_id = 4 THEN 1
                ELSE 0
            END) * 100 / COUNT(DISTINCT customer_id),
            0) AS churned_after_trial
FROM
    foodie_fi.subscriptions s1
        LEFT JOIN
    foodie_fi.subscriptions s2 USING (customer_id)
WHERE
    s2.plan_id != s1.plan_id;

-- Question 6 - What is the number and percentage of customer plans after their initial free trial?

-- cte for next plan start date
WITH next_subscription_cte AS (
SELECT 
    customer_id, MIN(start_date) AS start_date
FROM
    foodie_fi.subscriptions
WHERE
    plan_id != 0
GROUP BY 1)

SELECT 
    SUM(CASE
        WHEN cr_sub.plan_id = 1 THEN 1
        ELSE 0
    END) AS count_plan_1,
    SUM(CASE
        WHEN cr_sub.plan_id = 2 THEN 1
        ELSE 0
    END) AS count_plan_2,
    SUM(CASE
        WHEN cr_sub.plan_id = 3 THEN 1
        ELSE 0
    END) AS count_plan_3,
    SUM(CASE
        WHEN cr_sub.plan_id = 4 THEN 1
        ELSE 0
    END) AS count_plan_4,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 1 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_1,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 2 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_2,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 3 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_3,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 4 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_4
FROM
    next_subscription_cte next_sub
        LEFT JOIN
    foodie_fi.subscriptions cr_sub ON next_sub.customer_id = cr_sub.customer_id
        AND next_sub.start_date = cr_sub.start_date;


-- Question 7 - What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH latest_subscription_cte AS (
SELECT 
    customer_id, MAX(start_date) AS start_date
FROM
    foodie_fi.subscriptions
WHERE
    start_date <= '2020-12-31'
GROUP BY 1)

SELECT 
    SUM(CASE
        WHEN cr_sub.plan_id = 0 THEN 1
        ELSE 0
    END) AS count_plan_0,
    SUM(CASE
        WHEN cr_sub.plan_id = 1 THEN 1
        ELSE 0
    END) AS count_plan_1,
    SUM(CASE
        WHEN cr_sub.plan_id = 2 THEN 1
        ELSE 0
    END) AS count_plan_2,
    SUM(CASE
        WHEN cr_sub.plan_id = 3 THEN 1
        ELSE 0
    END) AS count_plan_3,
    SUM(CASE
        WHEN cr_sub.plan_id = 4 THEN 1
        ELSE 0
    END) AS count_plan_4,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 0 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_0,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 1 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_1,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 2 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_2,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 3 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_3,
    ROUND(SUM(CASE
                WHEN cr_sub.plan_id = 4 THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
            2) AS percent_plan_4
FROM
    latest_subscription_cte next_sub
        LEFT JOIN
    foodie_fi.subscriptions cr_sub ON next_sub.customer_id = cr_sub.customer_id
        AND next_sub.start_date = cr_sub.start_date;

-- Question 8 - How many customers have upgraded to an annual plan in 2020?

SELECT 
    COUNT(*) AS Number
FROM
    foodie_fi.subscriptions
WHERE
    plan_id = 3
        AND EXTRACT(YEAR FROM start_date) = 2020;

-- Question 9 - How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- start for plan 4

WITH plan_3_cte AS (
SELECT 
    customer_id, start_date AS plan_3_start_date
FROM
    foodie_fi.subscriptions
WHERE
    plan_id = 3),

-- joined Foodie-Fi
joined_cte AS (SELECT 
    customer_id, MIN(start_date) AS join_date
FROM
    foodie_fi.subscriptions
GROUP BY 1)

SELECT 
    ROUND(AVG(plan_3_start_date - join_date), 2) AS upgrade_days
FROM
    plan_3_cte
        LEFT JOIN
    joined_cte USING (customer_id);

-- Question 10 - Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- start for plan 4

WITH plan_3_cte AS (
SELECT 
    customer_id, start_date AS plan_3_start_date
FROM
    foodie_fi.subscriptions
WHERE
    plan_id = 3),

-- joined Foodie-Fi
joined_cte AS (SELECT 
    customer_id, MIN(start_date) AS join_date
FROM
    foodie_fi.subscriptions
GROUP BY 1),

bins AS(
SELECT 
    WIDTH_BUCKET(plan_3_start_date - join_date,
            0,
            360,
            12) AS avg_days_to_upgrade
FROM
    joined_cte
        JOIN
    plan_3_cte ON joined_cte.customer_id = plan_3_cte.customer_id
)

SELECT 
    ((avg_days_to_upgrade - 1) * 30 || '-'
        || (avg_days_to_upgrade) * 30) AS day_range,
    COUNT(*)
FROM
    bins
GROUP BY avg_days_to_upgrade;

-- Question 11 - How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

SELECT 
    COUNT(*)
FROM
    foodie_fi.subscriptions sub1
        LEFT JOIN
    foodie_fi.subscriptions sub2 ON sub1.customer_id = sub2.customer_id
WHERE
    sub1.plan_id = 2 AND sub2.plan_id = 1
        AND sub1.start_date < sub2.start_date
        AND EXTRACT(YEAR FROM sub2.start_date) = 2020;