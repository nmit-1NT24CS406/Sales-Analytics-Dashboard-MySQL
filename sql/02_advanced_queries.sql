USE sales_analytics_db;

-- 1. Scalar subquery: products priced above the average product price.
SELECT product_name, unit_price
FROM dim_product
WHERE unit_price > (SELECT AVG(unit_price) FROM dim_product);

-- 2. Correlated subquery: customers whose spend is above the average spend
-- among customers who have made at least one purchase.
SELECT c.customer_name
FROM dim_customer c
WHERE (
    SELECT COALESCE(SUM(f.total_amount), 0)
    FROM fact_sales f
    WHERE f.customer_id = c.customer_id
) > (
    SELECT AVG(customer_spend)
    FROM (
        SELECT SUM(total_amount) AS customer_spend
        FROM fact_sales
        GROUP BY customer_id
    ) spends
);

-- 3. EXISTS: customers who have at least one order.
SELECT c.customer_name
FROM dim_customer c
WHERE EXISTS (
    SELECT 1 FROM fact_sales f WHERE f.customer_id = c.customer_id
);

-- 4. NOT EXISTS: customers who have never ordered.
SELECT c.customer_name
FROM dim_customer c
WHERE NOT EXISTS (
    SELECT 1 FROM fact_sales f WHERE f.customer_id = c.customer_id
);

-- 5. UNION: combines cities from customers and stores, removing duplicates.
SELECT city FROM dim_customer
UNION
SELECT city FROM dim_store;

-- 6. INTERSECT/EXCEPT are supported by MySQL 8.0.31+.
-- For earlier MySQL versions, use the compatibility examples below.
-- Cities represented in both customer and store tables:
SELECT city FROM dim_customer
INTERSECT
SELECT city FROM dim_store;

-- Cities in customers but not in stores:
SELECT city FROM dim_customer
EXCEPT
SELECT city FROM dim_store;

-- Compatibility alternatives for versions before 8.0.31:
-- INTERSECT equivalent:
-- SELECT DISTINCT c.city FROM dim_customer c
-- WHERE EXISTS (SELECT 1 FROM dim_store s WHERE s.city = c.city);
-- EXCEPT equivalent:
-- SELECT DISTINCT c.city FROM dim_customer c
-- WHERE NOT EXISTS (SELECT 1 FROM dim_store s WHERE s.city = c.city);

-- 7. ROLLUP: subtotals and grand total by store/category.
SELECT
    s.store_name,
    p.category,
    SUM(f.total_amount) AS revenue
FROM fact_sales f
JOIN dim_store s ON s.store_id = f.store_id
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY s.store_name, p.category WITH ROLLUP;

-- 8. GROUPING SETS / CUBE teaching demo.
-- MySQL does not support GROUPING SETS or CUBE keywords.
-- Equivalent summaries are created with UNION ALL.
SELECT s.store_name, p.category, SUM(f.total_amount) AS revenue,
       'Store + Category' AS summary_level
FROM fact_sales f
JOIN dim_store s ON s.store_id = f.store_id
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY s.store_name, p.category

UNION ALL

SELECT s.store_name, 'ALL CATEGORIES', SUM(f.total_amount), 'Store subtotal'
FROM fact_sales f
JOIN dim_store s ON s.store_id = f.store_id
GROUP BY s.store_id, s.store_name

UNION ALL

SELECT 'ALL STORES', p.category, SUM(f.total_amount), 'Category subtotal'
FROM fact_sales f
JOIN dim_product p ON p.product_id = f.product_id
GROUP BY p.category

UNION ALL

SELECT 'ALL STORES', 'ALL CATEGORIES', SUM(f.total_amount), 'Grand total'
FROM fact_sales f;

-- 9. Recursive CTE: generate month starts for 2025.
WITH RECURSIVE months AS (
    SELECT CAST('2025-01-01' AS DATE) AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM months
    WHERE month_start < '2025-12-01'
)
SELECT month_start FROM months;

-- 10. Window functions: RANK, DENSE_RANK, NTILE.
SELECT customer_name, total_spend,
       RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
       DENSE_RANK() OVER (ORDER BY total_spend DESC) AS dense_spend_rank,
       NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile
FROM (
    SELECT c.customer_name, SUM(f.total_amount) AS total_spend
    FROM dim_customer c
    JOIN fact_sales f ON f.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
) customer_spend;

-- 11. LAG, LEAD, running total and a 3-row rolling average.
WITH monthly AS (
    SELECT DATE_SUB(sale_date, INTERVAL DAYOFMONTH(sale_date) - 1 DAY) AS month_start,
           SUM(total_amount) AS revenue
    FROM fact_sales
    GROUP BY month_start
)
SELECT month_start, revenue,
       LAG(revenue) OVER (ORDER BY month_start) AS previous_month,
       LEAD(revenue) OVER (ORDER BY month_start) AS next_month,
       SUM(revenue) OVER (
           ORDER BY month_start ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total,
       AVG(revenue) OVER (
           ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS rolling_3_month_average
FROM monthly;

-- 12. Normalization examples:
-- 1NF: one value per cell; no comma-separated product lists in one field.
-- 2NF: every non-key attribute depends on the whole key.
-- 3NF: non-key attributes depend on the key, not another non-key attribute.
-- The dimension tables hold customer/product/store details separately,
-- while fact_sales stores transaction facts and foreign keys.
