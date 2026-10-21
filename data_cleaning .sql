
SET search_path = pizza_runner;

-- check customer_orders data types
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'customer_orders'
ORDER BY ordinal_position;

-- customer_orders table overview
SELECT *
FROM customer_orders
ORDER BY order_id
LIMIT 20;

-- clean table 2: customer_orders
DROP TABLE IF EXISTS customer_orders_clean;

CREATE TABLE customer_orders_clean AS
SELECT
    order_id,
    customer_id,
    pizza_id,
    pizza_name,
    CASE
        WHEN exclusions IS NULL
          OR LOWER(TRIM(exclusions)) IN ('', 'null', 'nan')
        THEN NULL
        ELSE TRIM(exclusions)
    END AS exclusions,
    CASE
        WHEN extras IS NULL
          OR LOWER(TRIM(extras)) IN ('', 'null', 'nan')
        THEN NULL
        ELSE TRIM(extras)
    END AS extras,
    order_time
FROM customer_orders
JOIN pizza_names 
USING (pizza_id);

--------------------------
--------------------------

-- check runner_orders data types
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'runner_orders'
ORDER BY ordinal_position;

-- runner_orders table overview
SELECT *
FROM runner_orders
ORDER BY order_id
LIMIT 20;

--clean Table 3: runner_orders

DROP TABLE IF EXISTS runner_orders_clean;

CREATE TABLE runner_orders_clean AS
SELECT
    order_id,
    runner_id,

    -- Convert pickup_time to TIMESTAMP
    CASE
        WHEN LOWER(TRIM(pickup_time)) IN ('', 'null', 'nan')
            THEN NULL
        ELSE TRIM(pickup_time)::TIMESTAMP
    END AS pickup_time,

    -- Remove km and convert distance to NUMERIC
    CASE
        WHEN LOWER(TRIM(distance)) IN ('', 'null', 'nan')
            THEN NULL
        ELSE NULLIF(
            REGEXP_REPLACE(LOWER(distance), '[^0-9.]', '', 'g'), --chuyển distance thành chữ thường, sau đó xóa toàn bộ ký tự không phải số hoặc dấu chấm (như km, khoảng trắng) trên toàn bộ chuỗi để chuẩn bị chuyển thành kiểu số.
            ''
        )::NUMERIC
    END AS distance,

    -- Remove minutes, mins, minute and convert duration to INTEGER
    CASE
        WHEN LOWER(TRIM(duration)) IN ('', 'null', 'nan')
            THEN NULL
        ELSE NULLIF(
            REGEXP_REPLACE(LOWER(duration), '[^0-9.]', '', 'g'),
            ''
        )::NUMERIC::INTEGER
    END AS duration,

    -- Standardize cancellation
    CASE
        WHEN LOWER(TRIM(cancellation)) IN ('', 'null', 'nan')
            THEN NULL
        ELSE TRIM(cancellation)
    END AS cancellation

FROM runner_orders;

---------------------------
DROP TABLE IF EXISTS pizza_recipes_unnest;

CREATE TABLE pizza_recipes_unnest AS
SELECT
    pr.pizza_id,
    TRIM(t.topping_id)::INTEGER AS topping_id
FROM pizza_recipes AS pr
CROSS JOIN LATERAL
    UNNEST(STRING_TO_ARRAY(pr.toppings, ',')) AS t(topping_id);