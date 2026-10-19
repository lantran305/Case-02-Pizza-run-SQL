# Week 2: Pizza Runner 🍕

## 1. Business Context

Pizza Runner is a pizza delivery business that combines a pizza restaurant with an on-demand delivery service. As the business grows, Danny needs to analyze operational data to understand customer demand, evaluate delivery performance, and optimize business operations.

This project uses SQL to explore Pizza Runner's data and answer business questions related to sales, delivery efficiency, ingredient usage, and profitability.

## 2. Objectives

- Analyze pizza orders and customer purchasing patterns.
- Evaluate runner performance and delivery efficiency.
- Explore ingredient usage, exclusions, and extras.
- Analyze revenue, costs, and profitability.
- Practice data cleaning and SQL-based business analysis.

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

The raw data contains inconsistencies and missing values that require cleaning before analysis.

## 4. Tools

- PostgreSQL
- VS Code
- pgAdmin

## 5. SQL Techniques

- Data exploration and cleaning
- Handling `NULL` values and inconsistent data
- Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`
- Joins: `INNER JOIN`, `LEFT JOIN`
- Common Table Expressions (CTEs)
- Conditional logic using `CASE WHEN`
- Date and time functions
- String manipulation and data transformation
- Business metric calculations

## 6. Case Study Sections

### A. Pizza Metrics
Analyze order volume, pizza preferences, customer ordering patterns, and order frequency by time.

### B. Runner and Customer Experience
Evaluate runner registrations, preparation and delivery times, delivery distances, average speed, and successful delivery rates.

### C. Ingredient Optimisation
Explore standard pizza recipes, popular extras and exclusions, and ingredient requirements.

### D. Pricing and Ratings
Estimate revenue and delivery costs, explore pricing scenarios, and incorporate customer ratings into the operational dataset.

### E. Bonus DML Challenges
Practice data manipulation and schema changes to support new business requirements.

## 7. Repository Structure

```text
case-02-pizza-runner/
├── README.md
├── schema.sql
└── solutions.sql
```

- `schema.sql`: Creates the database tables and inserts the sample data.
- `solutions.sql`: Contains SQL queries answering the case study questions.
- `README.md`: Documents the business context, dataset, and analytical approach.

## 8. How to Run

1. Create a PostgreSQL database for the project.
2. Execute `schema.sql` to create and populate the tables.
3. Execute `solutions.sql` to run the analysis.
4. Review the query results and validate the findings.

## 9. Source

Case Study #2 – Pizza Runner, created by Danny Ma as part of the [8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-2/).

This repository contains my SQL practice and analysis based on the original case study.

