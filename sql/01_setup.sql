
-- SALES ANALYTICS DASHBOARD
-- MySQL 8.0+
-- WARNING: Recreates the tables in this project database.

CREATE DATABASE IF NOT EXISTS sales_analytics_db;
USE sales_analytics_db;

-- Drop existing project objects in the correct order
DROP VIEW IF EXISTS v_monthly_sales;
DROP TABLE IF EXISTS mv_monthly_category_sales;
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_date;

-- 1. DATE DIMENSION
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year_num INT NOT NULL,
    month_num INT NOT NULL,
    month_label VARCHAR(20) NOT NULL
);

-- 2. CUSTOMER DIMENSION
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    city VARCHAR(80) NOT NULL,
    signup_date DATE NOT NULL
);

-- 3. PRODUCT DIMENSION
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(80) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL
);

-- 4. STORE DIMENSION
CREATE TABLE dim_store (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(80) NOT NULL
);

-- 5. SALES FACT TABLE
CREATE TABLE fact_sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    sale_date DATE NOT NULL,
    date_key INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
);

-- 6. DATE SAMPLE DATA
INSERT INTO dim_date
(date_key, full_date, year_num, month_num, month_label)
VALUES
(20250105,'2025-01-05',2025,1,'Jan'),
(20250118,'2025-01-18',2025,1,'Jan'),
(20250203,'2025-02-03',2025,2,'Feb'),
(20250221,'2025-02-21',2025,2,'Feb'),
(20250309,'2025-03-09',2025,3,'Mar'),
(20250325,'2025-03-25',2025,3,'Mar'),
(20250407,'2025-04-07',2025,4,'Apr'),
(20250422,'2025-04-22',2025,4,'Apr'),
(20250511,'2025-05-11',2025,5,'May'),
(20250527,'2025-05-27',2025,5,'May'),
(20250606,'2025-06-06',2025,6,'Jun'),
(20250619,'2025-06-19',2025,6,'Jun'),
(20250704,'2025-07-04',2025,7,'Jul'),
(20250723,'2025-07-23',2025,7,'Jul'),
(20250808,'2025-08-08',2025,8,'Aug'),
(20250824,'2025-08-24',2025,8,'Aug'),
(20250902,'2025-09-02',2025,9,'Sep'),
(20250920,'2025-09-20',2025,9,'Sep'),
(20251010,'2025-10-10',2025,10,'Oct'),
(20251026,'2025-10-26',2025,10,'Oct'),
(20251105,'2025-11-05',2025,11,'Nov'),
(20251122,'2025-11-22',2025,11,'Nov'),
(20251203,'2025-12-03',2025,12,'Dec'),
(20251218,'2025-12-18',2025,12,'Dec');

-- 7. CUSTOMER SAMPLE DATA
INSERT INTO dim_customer VALUES
(1,'Asha Rao','Bengaluru','2024-11-12'),
(2,'Rahul Kumar','Mysuru','2024-12-02'),
(3,'Meera Nair','Chennai','2025-01-15'),
(4,'Arjun Shetty','Mangaluru','2025-02-01'),
(5,'Divya Singh','Bengaluru','2025-02-18'),
(6,'Kiran Patel','Hyderabad','2025-03-10'),
(7,'Nisha Das','Mysuru','2025-04-04'),
(8,'Vikram Joshi','Pune','2025-05-20'),
(9,'Sneha Reddy','Hyderabad','2025-06-14'),
(10,'Rohan Bhat','Mangaluru','2025-07-08'),
(11,'Priya Menon','Chennai','2025-08-17'),
(12,'Aditya Rao','Bengaluru','2025-09-01');

-- 8. PRODUCT SAMPLE DATA
INSERT INTO dim_product VALUES
(1,'Laptop','Electronics',65000.00),
(2,'Headphones','Electronics',2500.00),
(3,'Office Chair','Furniture',8500.00),
(4,'Desk Lamp','Home',1200.00),
(5,'Water Bottle','Accessories',600.00),
(6,'Keyboard','Electronics',1800.00);

-- 9. STORE SAMPLE DATA
INSERT INTO dim_store VALUES
(1,'Central Store','Bengaluru'),
(2,'City Store','Mysuru'),
(3,'Coastal Store','Mangaluru');

-- 10. SALES SAMPLE DATA
INSERT INTO fact_sales
(sale_date,date_key,customer_id,product_id,store_id,
 quantity,unit_price,total_amount)
VALUES
('2025-01-05',20250105,1,1,1,1,65000,65000),
('2025-01-18',20250118,2,2,2,2,2500,5000),
('2025-02-03',20250203,3,3,3,1,8500,8500),
('2025-02-21',20250221,1,4,1,3,1200,3600),
('2025-03-09',20250309,4,1,3,1,65000,65000),
('2025-03-25',20250325,5,5,1,4,600,2400),
('2025-04-07',20250407,6,2,2,3,2500,7500),
('2025-04-22',20250422,2,6,2,2,1800,3600),
('2025-05-11',20250511,7,3,2,2,8500,17000),
('2025-05-27',20250527,8,4,3,4,1200,4800),
('2025-06-06',20250606,9,1,1,1,65000,65000),
('2025-06-19',20250619,3,2,3,2,2500,5000),
('2025-07-04',20250704,10,6,3,3,1800,5400),
('2025-07-23',20250723,5,3,1,1,8500,8500),
('2025-08-08',20250808,11,1,2,1,65000,65000),
('2025-08-24',20250824,6,5,1,5,600,3000),
('2025-09-02',20250902,12,2,1,4,2500,10000),
('2025-09-20',20250920,7,4,2,3,1200,3600),
('2025-10-10',20251010,8,1,3,1,65000,65000),
('2025-10-26',20251026,9,6,1,2,1800,3600),
('2025-11-05',20251105,4,3,3,1,8500,8500),
('2025-11-22',20251122,10,2,2,3,2500,7500),
('2025-12-03',20251203,1,1,1,1,65000,65000),
('2025-12-18',20251218,11,4,2,5,1200,6000);

-- 11. STANDARD VIEW
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT
    DATE_FORMAT(sale_date, '%Y-%m') AS sales_month,
    SUM(total_amount) AS revenue,
    COUNT(*) AS order_count
FROM fact_sales
GROUP BY DATE_FORMAT(sale_date, '%Y-%m');

-- 12. SUMMARY TABLE
-- MySQL has no native materialized views.
CREATE TABLE mv_monthly_category_sales (
    month_start DATE NOT NULL,
    month_label VARCHAR(20) NOT NULL,
    category VARCHAR(80) NOT NULL,
    revenue DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (month_start, category)
);

-- FIXED QUERY: GROUP BY uses full expressions, not SELECT aliases.
INSERT INTO mv_monthly_category_sales
    (month_start, month_label, category, revenue)
SELECT
    DATE_SUB(
        f.sale_date,
        INTERVAL (DAYOFMONTH(f.sale_date) - 1) DAY
    ) AS month_start,
    DATE_FORMAT(f.sale_date, '%b %Y') AS month_label,
    p.category,
    SUM(f.total_amount) AS revenue
FROM fact_sales AS f
JOIN dim_product AS p
    ON p.product_id = f.product_id
GROUP BY
    DATE_SUB(
        f.sale_date,
        INTERVAL (DAYOFMONTH(f.sale_date) - 1) DAY
    ),
    DATE_FORMAT(f.sale_date, '%b %Y'),
    p.category;

-- 13. VALIDATION
SELECT COUNT(*) AS sample_sales_rows FROM fact_sales;
SELECT * FROM v_monthly_sales ORDER BY sales_month;
SELECT * FROM mv_monthly_category_sales
ORDER BY month_start, category;
