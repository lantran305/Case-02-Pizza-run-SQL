SET search_path = pizza_runner;

-- 1. What are the standard ingredients for each pizza?
SELECT
  pn.pizza_name,
  STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS standard_ingredients
FROM pizza_recipes AS pr
JOIN pizza_names AS pn
  ON pr.pizza_id = pn.pizza_id
CROSS JOIN UNNEST(STRING_TO_ARRAY(pr.toppings, ',')) AS recipe_topping(topping_id)
JOIN pizza_toppings AS pt
  ON pt.topping_id = BTRIM(recipe_topping.topping_id)::INTEGER
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 2. What was the most commonly added extra?
WITH added_extras AS (
  SELECT BTRIM(extra_id) AS topping_id
  FROM customer_orders AS co
  CROSS JOIN UNNEST(
    STRING_TO_ARRAY(
      NULLIF(NULLIF(LOWER(TRIM(co.extras)), ''), 'null'),
      ','
    )
  ) AS extra(extra_id)
  WHERE BTRIM(extra_id) <> ''
),
extra_counts AS (
  SELECT
    pt.topping_name,
    COUNT(*) AS times_added,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
  FROM added_extras AS ae
  JOIN pizza_toppings AS pt
    ON pt.topping_id = ae.topping_id::INTEGER
  GROUP BY pt.topping_name
)
SELECT topping_name, times_added
FROM extra_counts
WHERE popularity_rank = 1
ORDER BY topping_name;

-- 3. What was the most common exclusion?
WITH excluded_toppings AS (
  SELECT BTRIM(exclusion_id) AS topping_id
  FROM customer_orders AS co
  CROSS JOIN UNNEST(
    STRING_TO_ARRAY(
      NULLIF(NULLIF(LOWER(TRIM(co.exclusions)), ''), 'null'),
      ','
    )
  ) AS exclusion(exclusion_id)
  WHERE BTRIM(exclusion_id) <> ''
),
exclusion_counts AS (
  SELECT
    pt.topping_name,
    COUNT(*) AS times_excluded,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
  FROM excluded_toppings AS et
  JOIN pizza_toppings AS pt
    ON pt.topping_id = et.topping_id::INTEGER
  GROUP BY pt.topping_name
)
SELECT topping_name, times_excluded
FROM exclusion_counts
WHERE popularity_rank = 1
ORDER BY topping_name;

-- 4. Generate a descriptive order item for every customer_orders row.
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
line_modifications AS (
  SELECT
    pl.pizza_line_id,
    STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
      FILTER (WHERE modification.kind = 'Exclude') AS exclusions,
    STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name)
      FILTER (WHERE modification.kind = 'Extra') AS extras
  FROM pizza_lines AS pl
  CROSS JOIN LATERAL (
    SELECT 'Exclude' AS kind, BTRIM(exclusion_id) AS topping_id
    FROM UNNEST(
      STRING_TO_ARRAY(
        NULLIF(NULLIF(LOWER(TRIM(pl.exclusions)), ''), 'null'),
        ','
      )
    ) AS exclusion(exclusion_id)
    WHERE BTRIM(exclusion_id) <> ''

    UNION ALL

    SELECT 'Extra' AS kind, BTRIM(extra_id) AS topping_id
    FROM UNNEST(
      STRING_TO_ARRAY(
        NULLIF(NULLIF(LOWER(TRIM(pl.extras)), ''), 'null'),
        ','
      )
    ) AS extra(extra_id)
    WHERE BTRIM(extra_id) <> ''
  ) AS modification
  JOIN pizza_toppings AS pt
    ON pt.topping_id = modification.topping_id::INTEGER
  GROUP BY pl.pizza_line_id
)
SELECT
  pl.order_id,
  pl.customer_id,
  CONCAT_WS(
    ' - ',
    pn.pizza_name,
    CASE WHEN lm.exclusions IS NOT NULL THEN 'Exclude ' || lm.exclusions END,
    CASE WHEN lm.extras IS NOT NULL THEN 'Extra ' || lm.extras END
  ) AS order_item
FROM pizza_lines AS pl
JOIN pizza_names AS pn
  ON pl.pizza_id = pn.pizza_id
LEFT JOIN line_modifications AS lm
  ON pl.pizza_line_id = lm.pizza_line_id
ORDER BY pl.order_id, pl.pizza_line_id;

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
