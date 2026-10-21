SET search_path = pizza_runner;

-- 1. What are the standard ingredients for each pizza?
SELECT
  pn.pizza_name,
  STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS standard_ingredients
FROM pizza_recipes_unnest AS pr
JOIN pizza_toppings AS pt
  ON pt.topping_id = pr.topping_id
JOIN pizza_names AS pn
  ON pn.pizza_id = pr.pizza_id
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 2. What was the most commonly added extra?
WITH added_extras AS ( --unests the extras column from customer_orders and filters out null or empty values
    SELECT TRIM(extra_id)::INTEGER AS topping_id
    FROM customer_orders AS co
    CROSS JOIN UNNEST(STRING_TO_ARRAY(co.extras, ',')) AS extra(extra_id)
    WHERE TRIM(extra_id) NOT IN ('', 'null')
),
extra_counts AS (--counts the occurrences of each topping_id in the added_extras CTE and ranks them by popularity
    SELECT
        pt.topping_name,
        COUNT(*) AS times_added,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
    FROM added_extras AS ae
    JOIN pizza_toppings AS pt
        ON pt.topping_id = ae.topping_id
    GROUP BY pt.topping_name
)
SELECT topping_name, times_added
FROM extra_counts
WHERE popularity_rank = 1
ORDER BY topping_name;

-- 3. What was the most common exclusion?
WITH excluded_toppings AS (
  SELECT TRIM(exclusion_id)::INTEGER AS topping_id
  FROM customer_orders AS co
  CROSS JOIN UNNEST(STRING_TO_ARRAY(co.exclusions, ',')) AS exclusion(exclusion_id)
  WHERE TRIM(exclusion_id) NOT IN ('', 'null')
),
exclusion_counts AS (
  SELECT
    pt.topping_name,
    COUNT(*) AS times_excluded,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
  FROM excluded_toppings AS et
  JOIN pizza_toppings AS pt
    ON pt.topping_id = et.topping_id
  GROUP BY pt.topping_name
)
SELECT topping_name, times_excluded
FROM exclusion_counts
WHERE popularity_rank = 1
ORDER BY topping_name;

-- 4. Generate a descriptive order item for every customer_orders row.
WITH ingredient_list AS (
    SELECT
        co.order_id,
        co.pizza_id,
        pn.pizza_name,

      (
          SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
          FROM UNNEST(STRING_TO_ARRAY(co.extras, ',')) AS extra(extra_id)
          JOIN pizza_toppings AS pt
              ON pt.topping_id = TRIM(extra.extra_id)::INTEGER
      ) AS extra_ingredients,

      (
          SELECT STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
          FROM UNNEST(STRING_TO_ARRAY(co.exclusions, ',')) AS exclusion(exclusion_id)
          JOIN pizza_toppings AS pt
              ON pt.topping_id = TRIM(exclusion.exclusion_id)::INTEGER
      ) AS excluded_ingredients

  FROM customer_orders_clean AS co
  JOIN pizza_names AS pn USING (pizza_id)
)
SELECT
    order_id,
    pizza_name,
    CONCAT_WS(
        ' - ',
        pizza_name,
        CASE WHEN extra_ingredients IS NOT NULL
             THEN 'Extra ' || extra_ingredients END,
        CASE WHEN excluded_ingredients IS NOT NULL
             THEN 'Exclude ' || excluded_ingredients END
    ) AS order_item
FROM ingredient_list
ORDER BY order_id;

-- 5. Generate an alphabetically ordered ingredient list for each pizza order.
--    Toppings appearing more than once are prefixed with their quantity (e.g. 2xBacon).
WITH pizza_lines AS (
  SELECT
    ROW_NUMBER() OVER () AS pizza_line_id,
    order_id,
    customer_id,
    pizza_id,
    exclusions,
    extras
  FROM customer_orders
),
excluded_toppings AS (
  SELECT
    pl.pizza_line_id,
    BTRIM(exclusion_id)::INTEGER AS topping_id
  FROM pizza_lines AS pl
  CROSS JOIN LATERAL UNNEST(
    STRING_TO_ARRAY(
      NULLIF(NULLIF(LOWER(TRIM(pl.exclusions)), ''), 'null'),
      ','
    )
  ) AS exclusion(exclusion_id)
  WHERE BTRIM(exclusion_id) <> ''
),
extra_toppings AS (
  SELECT
    pl.pizza_line_id,
    BTRIM(extra_id)::INTEGER AS topping_id
  FROM pizza_lines AS pl
  CROSS JOIN LATERAL UNNEST(
    STRING_TO_ARRAY(
      NULLIF(NULLIF(LOWER(TRIM(pl.extras)), ''), 'null'),
      ','
    )
  ) AS extra(extra_id)
  WHERE BTRIM(extra_id) <> ''
),
standard_toppings AS (
  SELECT
    pl.pizza_line_id,
    pt.topping_id,
    pt.topping_name
  FROM pizza_lines AS pl
  JOIN pizza_recipes AS pr
    ON pl.pizza_id = pr.pizza_id
  CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(pr.toppings, ',')) AS recipe_topping(topping_id)
  JOIN pizza_toppings AS pt
    ON pt.topping_id = BTRIM(recipe_topping.topping_id)::INTEGER
  WHERE NOT EXISTS (
    SELECT 1
    FROM excluded_toppings AS et
    WHERE et.pizza_line_id = pl.pizza_line_id
      AND et.topping_id = pt.topping_id
  )
),
all_toppings AS (
  SELECT pizza_line_id, topping_id, topping_name
  FROM standard_toppings

  UNION ALL

  SELECT et.pizza_line_id, pt.topping_id, pt.topping_name
  FROM extra_toppings AS et
  JOIN pizza_toppings AS pt
    ON pt.topping_id = et.topping_id
),
topping_quantities AS (
  SELECT
    pizza_line_id,
    topping_id,
    topping_name,
    COUNT(*) AS quantity
  FROM all_toppings
  GROUP BY pizza_line_id, topping_id, topping_name
),
ingredient_lists AS (
  SELECT
    pizza_line_id,
    STRING_AGG(
      CASE WHEN quantity > 1 THEN quantity::TEXT || 'x' ELSE '' END || topping_name,
      ', '
      ORDER BY topping_name
    ) AS ingredient_list
  FROM topping_quantities
  GROUP BY pizza_line_id
)
SELECT
  pl.order_id,
  pl.customer_id,
  pn.pizza_name || ': ' || il.ingredient_list AS pizza_ingredients
FROM pizza_lines AS pl
JOIN pizza_names AS pn
  ON pl.pizza_id = pn.pizza_id
JOIN ingredient_lists AS il
  ON pl.pizza_line_id = il.pizza_line_id
ORDER BY pl.order_id, pl.pizza_line_id;

-- 6. Total quantity of each ingredient used in delivered pizzas,
--    sorted from most frequent to least frequent.
WITH delivered_pizza_lines AS (
  SELECT
    ROW_NUMBER() OVER () AS pizza_line_id,
    co.pizza_id,
    co.exclusions,
    co.extras
  FROM customer_orders AS co
  JOIN runner_orders AS ro
    ON co.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
     OR LOWER(TRIM(ro.cancellation)) IN ('', 'null')
),
excluded_toppings AS (
  SELECT
    pl.pizza_line_id,
    BTRIM(exclusion_id)::INTEGER AS topping_id
  FROM delivered_pizza_lines AS pl
  CROSS JOIN LATERAL UNNEST(
    STRING_TO_ARRAY(
      NULLIF(NULLIF(LOWER(TRIM(pl.exclusions)), ''), 'null'),
      ','
    )
  ) AS exclusion(exclusion_id)
  WHERE BTRIM(exclusion_id) <> ''
),
extra_toppings AS (
  SELECT
    pl.pizza_line_id,
    BTRIM(extra_id)::INTEGER AS topping_id
  FROM delivered_pizza_lines AS pl
  CROSS JOIN LATERAL UNNEST(
    STRING_TO_ARRAY(
      NULLIF(NULLIF(LOWER(TRIM(pl.extras)), ''), 'null'),
      ','
    )
  ) AS extra(extra_id)
  WHERE BTRIM(extra_id) <> ''
),
standard_toppings AS (
  SELECT
    pl.pizza_line_id,
    pt.topping_id,
    pt.topping_name
  FROM delivered_pizza_lines AS pl
  JOIN pizza_recipes AS pr
    ON pl.pizza_id = pr.pizza_id
  CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(pr.toppings, ',')) AS recipe_topping(topping_id)
  JOIN pizza_toppings AS pt
    ON pt.topping_id = BTRIM(recipe_topping.topping_id)::INTEGER
  WHERE NOT EXISTS (
    SELECT 1
    FROM excluded_toppings AS et
    WHERE et.pizza_line_id = pl.pizza_line_id
      AND et.topping_id = pt.topping_id
  )
),
all_toppings AS (
  SELECT pizza_line_id, topping_id, topping_name
  FROM standard_toppings

  UNION ALL

  SELECT et.pizza_line_id, pt.topping_id, pt.topping_name
  FROM extra_toppings AS et
  JOIN pizza_toppings AS pt
    ON pt.topping_id = et.topping_id
)
SELECT
  topping_name,
  COUNT(*) AS quantity_used
FROM all_toppings
GROUP BY topping_name
ORDER BY quantity_used DESC, topping_name;
