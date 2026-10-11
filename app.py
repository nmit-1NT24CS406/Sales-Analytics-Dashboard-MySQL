import os
from decimal import Decimal
from flask import Flask, jsonify, render_template
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

load_dotenv()
app = Flask(__name__)

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "database": os.getenv("DB_NAME", "sales_analytics_db"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "12345"),
}

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def rows_as_dicts(cursor):
    return cursor.fetchall()

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/api/dashboard")
def dashboard_data():
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                COALESCE(SUM(total_amount), 0) AS revenue,
                COUNT(*) AS orders_count,
                COUNT(DISTINCT customer_id) AS customers_count,
                COALESCE(AVG(total_amount), 0) AS average_order
            FROM fact_sales
        """)
        kpis = cursor.fetchone()

        cursor.execute("""
            WITH RECURSIVE months AS (
                SELECT CAST('2025-01-01' AS DATE) AS month_start
                UNION ALL
                SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
                FROM months
                WHERE month_start < '2025-12-01'
            ),
            monthly AS (
                SELECT
                    m.month_start,
                    COALESCE(SUM(f.total_amount), 0) AS revenue
                FROM months m
                LEFT JOIN fact_sales f
                    ON f.sale_date >= m.month_start
                   AND f.sale_date < DATE_ADD(m.month_start, INTERVAL 1 MONTH)
                GROUP BY m.month_start
            ),
            with_previous AS (
                SELECT
                    month_start,
                    revenue,
                    LAG(revenue) OVER (ORDER BY month_start) AS previous_revenue,
                    LEAD(revenue) OVER (ORDER BY month_start) AS next_revenue,
                    SUM(revenue) OVER (
                        ORDER BY month_start
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    ) AS running_revenue,
                    AVG(revenue) OVER (
                        ORDER BY month_start
                        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
                    ) AS rolling_3_month_avg
                FROM monthly
            )
            SELECT
                DATE_FORMAT(month_start, '%b') AS month_label,
                ROUND(revenue, 2) AS revenue,
                ROUND(
                    CASE
                        WHEN previous_revenue IS NULL OR previous_revenue = 0 THEN NULL
                        ELSE ((revenue - previous_revenue) / previous_revenue) * 100
                    END, 2
                ) AS mom_growth,
                ROUND(running_revenue, 2) AS running_revenue,
                ROUND(rolling_3_month_avg, 2) AS rolling_3_month_avg,
                ROUND(next_revenue, 2) AS next_month_revenue
            FROM with_previous
            ORDER BY month_start
        """)
        monthly = rows_as_dicts(cursor)

        cursor.execute("""
            SELECT product_name, category, revenue,
                   RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
                   DENSE_RANK() OVER (ORDER BY revenue DESC) AS dense_revenue_rank
            FROM (
                SELECT p.product_name, p.category, SUM(f.total_amount) AS revenue
                FROM fact_sales f
                JOIN dim_product p ON p.product_id = f.product_id
                GROUP BY p.product_id, p.product_name, p.category
            ) product_totals
            ORDER BY revenue DESC
            LIMIT 8
        """)
        products = rows_as_dicts(cursor)

        cursor.execute("""
            SELECT customer_name, total_spend, customer_quartile
            FROM (
                SELECT
                    c.customer_name,
                    SUM(f.total_amount) AS total_spend,
                    NTILE(4) OVER (ORDER BY SUM(f.total_amount) DESC) AS customer_quartile
                FROM dim_customer c
                JOIN fact_sales f ON f.customer_id = c.customer_id
                GROUP BY c.customer_id, c.customer_name
            ) ranked_customers
            ORDER BY total_spend DESC
            LIMIT 10
        """)
        customers = rows_as_dicts(cursor)

        # MySQL does not support GROUPING SETS or CUBE syntax.
        # This UNION ALL query emulates category/store grouping sets and a grand total.
        cursor.execute("""
            SELECT store_name, category, SUM(revenue) AS revenue, summary_level
            FROM (
                SELECT s.store_name, p.category, SUM(f.total_amount) AS revenue,
                       'Store + Category' AS summary_level
                FROM fact_sales f
                JOIN dim_store s ON s.store_id = f.store_id
                JOIN dim_product p ON p.product_id = f.product_id
                GROUP BY s.store_id, s.store_name, p.category

                UNION ALL

                SELECT s.store_name, 'ALL CATEGORIES' AS category,
                       SUM(f.total_amount) AS revenue,
                       'Store subtotal' AS summary_level
                FROM fact_sales f
                JOIN dim_store s ON s.store_id = f.store_id
                GROUP BY s.store_id, s.store_name

                UNION ALL

                SELECT 'ALL STORES' AS store_name, p.category,
                       SUM(f.total_amount) AS revenue,
                       'Category subtotal' AS summary_level
                FROM fact_sales f
                JOIN dim_product p ON p.product_id = f.product_id
                GROUP BY p.category

                UNION ALL

                SELECT 'ALL STORES' AS store_name, 'ALL CATEGORIES' AS category,
                       SUM(f.total_amount) AS revenue,
                       'Grand total' AS summary_level
                FROM fact_sales f
            ) grouped_sales
            GROUP BY store_name, category, summary_level
            ORDER BY
                CASE summary_level
                    WHEN 'Store + Category' THEN 1
                    WHEN 'Store subtotal' THEN 2
                    WHEN 'Category subtotal' THEN 3
                    ELSE 4
                END,
                store_name, category
        """)
        grouping_rows = rows_as_dicts(cursor)

        cursor.execute("""
            SELECT c.customer_name,
                   COUNT(f.sale_id) AS order_count,
                   MAX(f.sale_date) AS latest_order
            FROM dim_customer c
            LEFT JOIN fact_sales f ON f.customer_id = c.customer_id
            GROUP BY c.customer_id, c.customer_name
            HAVING COUNT(f.sale_id) = 0
            ORDER BY c.customer_name
            LIMIT 10
        """)
        inactive_customers = rows_as_dicts(cursor)

        cursor.execute("""
            SELECT month_label, category, revenue
            FROM mv_monthly_category_sales
            ORDER BY month_start, category
        """)
        materialized_summary = rows_as_dicts(cursor)

        return jsonify({
            "kpis": kpis,
            "monthly": monthly,
            "products": products,
            "customers": customers,
            "grouping_rows": grouping_rows,
            "inactive_customers": inactive_customers,
            "materialized_summary": materialized_summary
        })
    except Error as exc:
        return jsonify({
            "error": str(exc),
            "help": "Check that MySQL is running, sql/01_setup.sql has been executed, and .env has the correct password/database."
        }), 500
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

@app.route("/api/refresh-summary", methods=["POST"])
def refresh_summary():
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("TRUNCATE TABLE mv_monthly_category_sales")
        cursor.execute("""
            INSERT INTO mv_monthly_category_sales (month_start, month_label, category, revenue)
            SELECT
                DATE_SUB(f.sale_date, INTERVAL DAYOFMONTH(f.sale_date) - 1 DAY) AS month_start,
                DATE_FORMAT(f.sale_date, '%b %Y') AS month_label,
                p.category,
                SUM(f.total_amount) AS revenue
            FROM fact_sales f
            JOIN dim_product p ON p.product_id = f.product_id
            GROUP BY month_start, month_label, p.category
        """)
        conn.commit()
        return jsonify({"message": "Summary table refreshed successfully."})
    except Error as exc:
        if conn:
            conn.rollback()
        return jsonify({"error": str(exc)}), 500
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()

if __name__ == "__main__":
    app.run(debug=True)
