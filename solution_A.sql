SET search_path = pizza_runner;

-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT
  runner_id,
  COUNT(DISTINCT order_id) AS successful_orders_delivered
FROM runner_orders
WHERE cancellation IS NULL
   OR LOWER(TRIM(cancellation)) IN ('', 'null')
GROUP BY runner_id
ORDER BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT
  pn.pizza_name,
  COUNT(*) AS pizzas_delivered
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
JOIN pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
   OR LOWER(TRIM(ro.cancellation)) IN ('', 'null')
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  co.customer_id,
  COUNT(*) FILTER (WHERE pn.pizza_name = 'Meatlovers') AS meat_lovers,
  COUNT(*) FILTER (WHERE pn.pizza_name = 'Vegetarian') AS vegetarian
FROM customer_orders AS co
JOIN pizza_names AS pn
  ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT MAX(pizza_count) AS max_pizzas_in_single_order
FROM (
  SELECT co.order_id, COUNT(*) AS pizza_count
  FROM customer_orders AS co
  JOIN runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
     OR LOWER(TRIM(ro.cancellation)) IN ('', 'null')
  GROUP BY co.order_id
) AS delivered_order_counts;

-- 7. For each customer, how many delivered pizzas had at least 1 change
--    and how many had no changes?
SELECT
  co.customer_id,
  COUNT(*) FILTER (
    WHERE LOWER(TRIM(COALESCE(co.exclusions, ''))) NOT IN ('', 'null')
       OR LOWER(TRIM(COALESCE(co.extras, ''))) NOT IN ('', 'null')
  ) AS pizzas_with_changes,
  COUNT(*) FILTER (
    WHERE LOWER(TRIM(COALESCE(co.exclusions, ''))) IN ('', 'null')
      AND LOWER(TRIM(COALESCE(co.extras, ''))) IN ('', 'null')
  ) AS pizzas_without_changes
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
   OR LOWER(TRIM(ro.cancellation)) IN ('', 'null')
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS pizzas_with_exclusions_and_extras
FROM customer_orders AS co
JOIN runner_orders AS ro
  ON co.order_id = ro.order_id
WHERE (ro.cancellation IS NULL OR LOWER(TRIM(ro.cancellation)) IN ('', 'null'))
  AND LOWER(TRIM(COALESCE(co.exclusions, ''))) NOT IN ('', 'null')
  AND LOWER(TRIM(COALESCE(co.extras, ''))) NOT IN ('', 'null');

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
  EXTRACT(HOUR FROM order_time)::INTEGER AS order_hour,
  COUNT(*) AS pizzas_ordered
FROM customer_orders
GROUP BY order_hour
ORDER BY order_hour;

-- 10. What was the volume of orders for each day of the week?
SELECT
  TO_CHAR(order_time, 'Day') AS day_of_week,
  COUNT(DISTINCT order_id) AS orders
FROM customer_orders
GROUP BY EXTRACT(DOW FROM order_time), TO_CHAR(order_time, 'Day')
ORDER BY EXTRACT(DOW FROM order_time);