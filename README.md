# Week 2: Pizza Runner 🍕

## 1. Business Context
Pizza Runner is a pizza delivery business that combines a pizza restaurant with an on-demand delivery service. This project uses SQL to analyze sales, delivery performance, ingredient usage, and profitability to support business decisions.

## 2. Objectives
- Analyze customer ordering patterns and pizza sales.
- Evaluate delivery performance and runner efficiency.
- Explore ingredient usage, exclusions, and extras.
- Estimate revenue, costs, and profitability.
- Apply SQL techniques to solve business problems.

## 3. Dataset
The dataset is provided by the [8 Week SQL Challenge – Case Study #2](https://8weeksqlchallenge.com/case-study-2/).

| Table | Description |
|---|---|
| `runners` | Runner registration information |
| `customer_orders` | Customer orders, pizza types, exclusions, and extras |
| `runner_orders` | Delivery details, distances, durations, and cancellations |
| `pizza_names` | Pizza IDs and names |
| `pizza_recipes` | Standard ingredients for each pizza |
| `pizza_toppings` | Topping IDs and ingredient names |

## 4. Tools
PostgreSQL, VS Code, and pgAdmin.

## 5. Data Exploration & Cleaning
- **Customer Orders:** Standardized `exclusions` and `extras`, handled missing values, and created `customer_orders_clean`.
- **Runner Orders:** Converted `pickup_time` to `TIMESTAMP`, removed units from `distance` and `duration`, converted them into numeric values, handled missing values, and created `runner_orders_clean` while preserving the original data.

## 6. Case Study Sections
- **A. Pizza Metrics:** Order volume, pizza preferences, customer ordering patterns, and ordering frequency.
- **B. Runner and Customer Experience:** Preparation time, delivery distance and speed, runner performance, and successful delivery rates.
- **C. Ingredient Optimisation:** Standard recipes, popular extras and exclusions, and ingredient requirements.
- **D. Pricing and Ratings:** Revenue, delivery costs, pricing scenarios, and customer ratings.
- **E. Bonus DML Challenges:** Data manipulation and schema changes.

## 7. SQL Techniques

**Data Exploration & Cleaning**
- Data profiling using `information_schema`
- Missing value handling using `CASE WHEN`, `NULLIF()`, and `COALESCE()`
- String cleaning using `TRIM()`, `LOWER()`, and `REGEXP_REPLACE()`
- Data type conversion using `CAST()` and `::`
- Table creation using `CREATE TABLE AS SELECT`

**Data Retrieval & Transformation**
- Filtering and sorting using `WHERE`, `ORDER BY`, and `DISTINCT`
- Grouping and filtering aggregated results using `GROUP BY` and `HAVING`
- Table joins using `INNER JOIN` and `LEFT JOIN`
- Subqueries and Common Table Expressions (CTEs)
- Date/time functions: `EXTRACT()`, `DATE_TRUNC()`, and timestamp subtraction
- String and array functions: `STRING_AGG()`, `SPLIT_PART()`, and `UNNEST()`

**Aggregation & Business Analysis**
- Aggregate functions: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, and `MAX()`
- Conditional aggregation using `FILTER (WHERE ...)` and `SUM(CASE WHEN ... THEN ... END)`
- Percentage and rate calculations using arithmetic operators and `ROUND()`
- Revenue, cost, delivery performance, and success rate analysis

**Advanced SQL**
- Window functions: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `SUM() OVER()`, and `AVG() OVER()`
- Conditional logic using `CASE WHEN`
- Ranking, cumulative calculations, and comparative analysis

**Data Manipulation**
- Data modification using `INSERT`, `UPDATE`, and `DELETE`
- Schema modification using `ALTER TABLE`

## 8. Repository Structure
```text
case-02-pizza-runner/
├── README.md
├── schema.sql
├── data_cleaning.sql
├── solution_A.sql
├── solution_B.sql
├── solution_C.sql
└── solution_D.sql
```

- `schema.sql`: Creates and populates the source tables.
- `data_cleaning.sql`: Profiles, cleans, and prepares data for analysis.
- `solution_A.sql`: Solves business questions in Pizza Metrics.
- `solution_B.sql`: Analyzes runner performance and customer experience.
- `solution_C.sql`: Explores ingredient optimization.
- `solution_D.sql`: Analyzes pricing and ratings.
- `README.md`: Documents the business context, dataset, SQL techniques, and analytical approach.
## 9. Source
Case Study #2 – Pizza Runner, created by Danny Ma as part of the [8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-2/).

This repository contains my SQL practice and analysis based on the original case study.