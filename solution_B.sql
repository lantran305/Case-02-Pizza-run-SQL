SET search_path = pizza_runner;

-- 1. How many runners signed up for each 1 week period?
--    The first period starts on 2021-01-01.
SELECT
  DATE '2021-01-01'
    + (((registration_date - DATE '2021-01-01') / 7) * 7) AS week_start,
  COUNT(*) AS runners_signed_up
FROM runners
GROUP BY week_start
ORDER BY week_start;

-- 2. What was the average time in minutes it took for each runner
--    to arrive at the Pizza Runner HQ to pickup the order?
WITH successful_deliveries AS (
  SELECT
    runner_id,
    order_id,
    NULLIF(NULLIF(TRIM(pickup_time), ''), 'null')::TIMESTAMP AS pickup_timestamp
  FROM runner_orders
  WHERE cancellation IS NULL
     OR LOWER(TRIM(cancellation)) IN ('', 'null')
),
orders AS (
  SELECT DISTINCT order_id, order_time
  FROM customer_orders
)
SELECT
  sd.runner_id,
  ROUND(AVG(EXTRACT(EPOCH FROM (sd.pickup_timestamp - o.order_time)) / 60)::NUMERIC, 2)
    AS average_pickup_minutes
FROM successful_deliveries AS sd
JOIN orders AS o
  ON sd.order_id = o.order_id
GROUP BY sd.runner_id
ORDER BY sd.runner_id;

-- 3. Is there any relationship between the number of pizzas and
--    how long the order takes to prepare?
WITH order_pizza_counts AS (
  SELECT order_id, COUNT(*) AS pizza_count
  FROM customer_orders
  GROUP BY order_id
),
successful_deliveries AS (
  SELECT
    order_id,
    NULLIF(NULLIF(TRIM(pickup_time), ''), 'null')::TIMESTAMP AS pickup_timestamp
  FROM runner_orders
  WHERE cancellation IS NULL
     OR LOWER(TRIM(cancellation)) IN ('', 'null')
),
order_preparation AS (
  SELECT
    opc.order_id,
    opc.pizza_count,
    EXTRACT(EPOCH FROM (sd.pickup_timestamp - co.order_time)) / 60
      AS preparation_minutes
  FROM order_pizza_counts AS opc
  JOIN successful_deliveries AS sd
    ON opc.order_id = sd.order_id
  JOIN (
    SELECT DISTINCT order_id, order_time
    FROM customer_orders
  ) AS co
    ON opc.order_id = co.order_id
)
SELECT
  pizza_count,
  ROUND(AVG(preparation_minutes)::NUMERIC, 2) AS average_preparation_minutes
FROM order_preparation
GROUP BY pizza_count
ORDER BY pizza_count;

-- 4. What was the average distance travelled for each customer?
WITH successful_order_distances AS (
  SELECT DISTINCT
    co.customer_id,
    co.order_id,
    NULLIF(REGEXP_REPLACE(ro.distance, '[^0-9.]', '', 'g'), '')::NUMERIC
      AS distance_km
  FROM customer_orders AS co
  JOIN runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
     OR LOWER(TRIM(ro.cancellation)) IN ('', 'null')
)
SELECT
  customer_id,
  ROUND(AVG(distance_km), 2) AS average_distance_km
FROM successful_order_distances
GROUP BY customer_id
ORDER BY customer_id;

-- 5. What was the difference between the longest and shortest
--    delivery times for all successful orders?
WITH successful_delivery_times AS (
  SELECT
    NULLIF(REGEXP_REPLACE(duration, '[^0-9.]', '', 'g'), '')::NUMERIC
      AS duration_minutes
  FROM runner_orders
  WHERE cancellation IS NULL
     OR LOWER(TRIM(cancellation)) IN ('', 'null')
)
SELECT
  MAX(duration_minutes) - MIN(duration_minutes) AS delivery_time_difference_minutes
FROM successful_delivery_times;

-- 6. What was the average speed for each runner for each delivery?
--    Speeds are in km/h; the window average helps compare deliveries
--    and spot variation for each runner.
WITH successful_delivery_metrics AS (
  SELECT
    runner_id,
    order_id,
    NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g'), '')::NUMERIC
      AS distance_km,
    NULLIF(REGEXP_REPLACE(duration, '[^0-9.]', '', 'g'), '')::NUMERIC
      AS duration_minutes
  FROM runner_orders
  WHERE cancellation IS NULL
     OR LOWER(TRIM(cancellation)) IN ('', 'null')
),
delivery_speeds AS (
  SELECT
    runner_id,
    order_id,
    distance_km / NULLIF(duration_minutes / 60, 0) AS speed_kmh
  FROM successful_delivery_metrics
)
SELECT
  runner_id,
  order_id,
  ROUND(speed_kmh, 2) AS speed_kmh,
  ROUND(AVG(speed_kmh) OVER (PARTITION BY runner_id), 2) AS runner_average_speed_kmh
FROM delivery_speeds
ORDER BY runner_id, order_id;

-- 7. What is the successful delivery percentage for each runner?
SELECT
  runner_id,
  ROUND(
    100.0 * COUNT(DISTINCT order_id) FILTER (
      WHERE cancellation IS NULL
         OR LOWER(TRIM(cancellation)) IN ('', 'null')
    ) / NULLIF(COUNT(DISTINCT order_id), 0),
    2
  ) AS successful_delivery_percentage
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;
