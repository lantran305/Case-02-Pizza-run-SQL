
-- ============================================
-- Week 2: Pizza Runner
-- Section A: Pizza Metrics
-- ============================================


-- Q1. How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered
FROM customer_orders_clean;


-- Q2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM customer_orders_clean;


-- Q3. How many successful orders were delivered by each runner?
SELECT
    runner_id,
    COUNT(DISTINCT order_id) AS successful_orders
FROM runner_orders_clean
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY runner_id;


-- Q4. How many of each type of pizza was delivered?
SELECT
    pizza_name,
    COUNT(*) AS pizzas_delivered
FROM customer_orders_clean AS co
JOIN runner_orders_clean AS ro
    ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY pizza_name
ORDER BY pizzas_delivered DESC;


-- Q5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    co.customer_id,
    SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END)
        AS meatlovers_count,
    SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END)
        AS vegetarian_count
FROM customer_orders_clean AS co
JOIN pizza_names AS pn
    ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id
ORDER BY co.customer_id;


-- Q6. What was the maximum number of pizzas delivered in a single order?
SELECT MAX(pizza_count) AS max_pizzas_in_single_order
FROM (
    SELECT
        co.order_id,
        COUNT(*) AS pizza_count
    FROM customer_orders_clean AS co
    JOIN runner_orders_clean AS ro
        ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL
    GROUP BY co.order_id
) AS order_summary;


-- Q7. For each customer, how many delivered pizzas had 
-- at least 1 change and how many had no changes?
SELECT
    co.customer_id,
    SUM(CASE WHEN co.exclusions IS NOT NULL
              OR co.extras IS NOT NULL
            THEN 1 ELSE 0 END) AS pizzas_with_changes,
    SUM(CASE WHEN co.exclusions IS NULL
             AND co.extras IS NULL
            THEN 1 ELSE 0 END) AS pizzas_without_changes
FROM customer_orders_clean AS co
JOIN runner_orders_clean AS ro
    ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;


-- Q8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS pizzas_with_exclusions_and_extras
FROM customer_orders_clean
JOIN runner_orders_clean
  USING (order_id)
WHERE cancellation IS NULL
  AND exclusions IS NOT NULL
  AND extras IS NOT NULL;


-- Q9. What was the total volume of pizzas ordered for each hour of the day?
-- Requires an order_time column in customer_orders_clean.
SELECT
    EXTRACT(HOUR FROM order_time)::INTEGER AS order_hour,
    COUNT(*) AS pizzas_ordered
FROM customer_orders_clean
GROUP BY order_hour
ORDER BY order_hour;


-- Q10. What was the volume of orders for each day of the week?
-- Requires an order_time column in customer_orders_clean.
SELECT
    TO_CHAR(order_time, 'FMDay') AS day_of_week,
    COUNT(DISTINCT order_id) AS total_orders
FROM customer_orders_clean
GROUP BY EXTRACT(ISODOW FROM order_time),
         TO_CHAR(order_time, 'FMDay')
ORDER BY EXTRACT(ISODOW FROM order_time);
