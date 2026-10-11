# Sales Analytics Dashboard (MySQL + Flask)

A beginner-friendly SQL mini-project: **Dimensional Model + Window Function Report + CTE Month-over-Month (MoM) Growth**.

## What you need

- MySQL Server (prefer MySQL 8.0.31 or later)
- VS Code
- Python 3.10 or later
- Internet connection for Chart.js (dashboard chart library is loaded from a CDN)

> Important: MySQL does not support native `CUBE` or `GROUPING SETS` syntax. The dashboard demonstrates equivalent summaries using `UNION ALL`. MySQL also does not have native materialized views, so this project uses a precomputed summary table that can be refreshed from the dashboard. `INTERSECT` and `EXCEPT` need MySQL 8.0.31+; alternative queries are included for older versions.

## Step-by-step setup on Windows

### Step 1 — Extract the ZIP

Extract `Sales_Analytics_Dashboard_MySQL.zip` into a folder you can find easily, such as:
`C:\Users\YourName\Documents\Sales_Analytics_Dashboard_MySQL`

In VS Code choose **File → Open Folder** and select that extracted folder.

### Step 2 — Confirm Python

In VS Code, choose **Terminal → New Terminal**, then run:

```powershell
python --version
```

If that does not work, try:

```powershell
py --version
```

You should see Python 3.10 or newer. If both commands fail, install Python from https://www.python.org/downloads/ and select **Add Python to PATH** during installation.

### Step 3 — Start MySQL and run the database script

1. Start your MySQL Server service.
2. Open MySQL Workbench (if installed) and connect to your local server. If you do not have Workbench, you can use the MySQL command-line client.
3. Open `sql/01_setup.sql`.
4. Run the whole script.
5. At the bottom, check that `sample_sales_rows` is `24`.

**Warning:** `01_setup.sql` drops and recreates the project tables in the `sales_analytics_db` database. Use it only for this project database; do not run it in a database containing important personal data.

### Step 4 — Create a Python virtual environment

In the VS Code terminal, ensure the terminal is in the project folder, then run:

```powershell
python -m venv .venv
```

Activate it:

```powershell
.venv\Scripts\Activate.ps1
```

If PowerShell blocks activation, use Command Prompt in VS Code and run:

```bat
.venv\Scripts\activate.bat
```

You may also install packages without activating the environment using `python -m pip`, but activating it is recommended.

### Step 5 — Install the Python packages

```powershell
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

### Step 6 — Set your MySQL password

1. In VS Code Explorer, make a copy of `.env.example`.
2. Rename the copy to `.env` (the filename must be exactly `.env`, not `.env.txt`).
3. Open `.env` and enter the password for your local MySQL user.

Example:

```text
DB_HOST=localhost
DB_PORT=3306
DB_NAME=sales_analytics_db
DB_USER=root
DB_PASSWORD=your_actual_mysql_password
```

Replace `your_actual_mysql_password` with your real password. Do not include quotation marks unless your password requires them. If your MySQL user has no password, leave `DB_PASSWORD=` empty. Do not upload `.env` to GitHub.

### Step 7 — Start the dashboard

In the VS Code terminal, run:

```powershell
python app.py
```

You should see a local address similar to `http://127.0.0.1:5000`.

Hold **Ctrl** and click the address, or copy it into your browser:
`http://127.0.0.1:5000`

Keep the terminal running while you use the dashboard. To stop the server, click the terminal and press `Ctrl+C`.

### Step 8 — Explore the SQL examples

Open `sql/02_advanced_queries.sql` in MySQL Workbench and run one query at a time. Read the comments above each query. This file demonstrates subqueries, `EXISTS`, `NOT EXISTS`, set operations, `ROLLUP`, `UNION ALL` summaries, recursive CTEs, window functions and window frames.

## Common problems

- **Access denied for user**: check `DB_USER` and `DB_PASSWORD` in `.env`.
- **Unknown database**: run `sql/01_setup.sql` first.
- **Can't connect to MySQL server**: start the MySQL service and confirm port `3306` (or change `DB_PORT`).
- **INTERSECT / EXCEPT syntax error**: your MySQL version may be older than 8.0.31. Use the commented compatibility alternatives in `sql/02_advanced_queries.sql`.
- **Dashboard chart is blank**: make sure you have internet access so the Chart.js CDN can load.
- **No module named flask/mysql.connector/dotenv**: activate `.venv` and rerun `python -m pip install -r requirements.txt`.

## SQL concepts and where to see them

| Concept | Where it appears |
|---|---|
| Dimensional model | `dim_date`, `dim_customer`, `dim_product`, `dim_store`, `fact_sales` |
| 1NF–3NF | Normalized dimension/fact design and comments in `02_advanced_queries.sql` |
| Scalar and correlated subqueries | `02_advanced_queries.sql` |
| `EXISTS` / `NOT EXISTS` | `02_advanced_queries.sql` and inactive customer dashboard |
| `RANK`, `DENSE_RANK`, `NTILE` | Dashboard product/customer reports |
| `LAG`, `LEAD`, window frames | Monthly revenue report |
| Recursive CTE | Generates all 12 months, including months without sales |
| `UNION`, `INTERSECT`, `EXCEPT` | `02_advanced_queries.sql` |
| `ROLLUP` | `02_advanced_queries.sql` |
| `CUBE` / `GROUPING SETS` | Emulated with `UNION ALL` because MySQL does not support the native syntax |
| Standard view | `v_monthly_sales` |
| Materialized view concept | `mv_monthly_category_sales` summary table + refresh button |

## Project explanation for presentation

“This project is a Sales Analytics Dashboard built using MySQL, Python Flask, HTML, CSS and JavaScript. The dimensional model separates sales transactions from customer, product, store and date details. SQL queries calculate monthly revenue and month-over-month growth. Window functions rank products and customers, and a recursive CTE generates each month in the reporting period. The dashboard also shows subtotals and grand totals. Because MySQL does not support native materialized views, the project stores a precomputed summary in a table and provides a refresh button.”
