
-- ============================================
-- Week 2: Pizza Runner
-- Section B: Runner and Customer Experience
-- ============================================


-- Q1. How many runners signed up for each 1 week period?
-- Week 1 starts on 2021-01-01.
SELECT
    FLOOR((registration_date - DATE '2021-01-01') / 7) + 1
        AS week_number,
    COUNT(*) AS runners_signed_up
FROM runners
GROUP BY week_number
ORDER BY week_number;


-- Q2. What was the average time in minutes it took for each
-- runner to arrive at Pizza Runner HQ to pick up the order?
-- Requires order_time to calculate the waiting time.
SELECT
    runner_id,
    ROUND(
        AVG(
          EXTRACT(EPOCH FROM (pickup_time - order_time))/ 60
        )::NUMERIC,2) AS avg_pickup_time_minutes
FROM customer_orders_clean 
JOIN runner_orders_clean
    USING (order_id)
WHERE cancellation IS NULL
  AND pickup_time IS NOT NULL
GROUP BY runner_id
ORDER BY runner_id;


-- Q3. Is there any relationship between the number of pizzas
-- and how long the order takes to prepare?
-- Requires order_time to calculate preparation time.
SELECT
    co.order_id,
    COUNT(*) AS pizza_count,
    ROUND(
        (
            EXTRACT(EPOCH FROM (ro.pickup_time - MIN(co.order_time::TIMESTAMP)))
            / 60
        )::NUMERIC,
        2
    ) AS preparation_time_minutes
FROM customer_orders_clean AS co
JOIN runner_orders_clean AS ro
    ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  AND ro.pickup_time IS NOT NULL
GROUP BY co.order_id, ro.pickup_time
ORDER BY pizza_count, co.order_id;


-- Q4. What was the average distance travelled for each customer?
SELECT
    co.customer_id,
    ROUND(AVG(ro.distance), 2) AS avg_distance_km
FROM customer_orders_clean AS co
JOIN runner_orders_clean AS ro
    ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  AND ro.distance IS NOT NULL
GROUP BY co.customer_id
ORDER BY co.customer_id;


-- Q5. What was the difference between the longest and shortest
-- delivery times for all orders?
SELECT
    MAX(duration) - MIN(duration) AS delivery_time_difference_minutes
FROM runner_orders_clean
WHERE cancellation IS NULL
  AND duration IS NOT NULL;


-- Q6. What was the average speed for each runner for each delivery?
-- Do you notice any trend?
SELECT
    order_id,
    runner_id,
    distance AS distance_km,
    duration AS duration_minutes,
    ROUND(
        (distance / NULLIF(duration, 0) * 60)::NUMERIC,
        2
    ) AS speed_kmh
FROM runner_orders_clean
WHERE cancellation IS NULL
  AND distance IS NOT NULL
  AND duration IS NOT NULL
ORDER BY runner_id, order_id;


-- Q7. What is the successful delivery percentage for each runner?
SELECT
    runner_id,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE cancellation IS NULL) AS successful_orders,
    ROUND(
        (
            COUNT(*) FILTER (WHERE cancellation IS NULL) * 100.0
            / COUNT(*)
        )::NUMERIC,
        2
    ) AS successful_delivery_percentage
FROM runner_orders_clean
GROUP BY runner_id
ORDER BY runner_id;
