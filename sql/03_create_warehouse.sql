-- 03_create_warehouse.sql
-- Star schema in the dw schema: 5 dimensions (incl. a generated date dimension)
-- and one fact table. Every dimension has a UNIQUE business key so the upserts
-- in 04_ / 05_ are idempotent.

-- ---------------------------------------------------------------- dimensions

CREATE TABLE IF NOT EXISTS dw.dim_customers (
    customer_sk   INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   VARCHAR(50)  NOT NULL,
    company_name  VARCHAR(255),
    contact_name  VARCHAR(255),
    contact_title VARCHAR(255),
    city          VARCHAR(100),
    region        VARCHAR(100),
    postal_code   VARCHAR(50),
    country       VARCHAR(100),
    UNIQUE KEY uq_dim_customers_id (customer_id)
);

CREATE TABLE IF NOT EXISTS dw.dim_products (
    product_sk        INT AUTO_INCREMENT PRIMARY KEY,
    product_id        INT NOT NULL,
    product_name      VARCHAR(255),
    category_id       INT,
    category_name     VARCHAR(255),
    supplier_id       INT,
    quantity_per_unit VARCHAR(100),
    unit_price        DECIMAL(10,2),
    units_in_stock    INT,
    is_discontinued   TINYINT(1),
    UNIQUE KEY uq_dim_products_id (product_id)
);

CREATE TABLE IF NOT EXISTS dw.dim_employees (
    employee_sk INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    full_name   VARCHAR(200),
    title       VARCHAR(100),
    hire_date   DATE,
    city        VARCHAR(100),
    country     VARCHAR(100),
    reports_to  INT,
    UNIQUE KEY uq_dim_employees_id (employee_id)
);

CREATE TABLE IF NOT EXISTS dw.dim_suppliers (
    supplier_sk  INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id  INT NOT NULL,
    company_name VARCHAR(255),
    contact_name VARCHAR(255),
    city         VARCHAR(100),
    country      VARCHAR(100),
    UNIQUE KEY uq_dim_suppliers_id (supplier_id)
);

-- Date dimension: one row per calendar day, 1990-01-01 .. 9999-12-31.
-- Fiscal year assumption: starts on 1 July (change the "+ 5" / ">= 7" below to move it).
CREATE TABLE IF NOT EXISTS dw.dim_date (
    date_key        INT PRIMARY KEY,          -- YYYYMMDD
    full_date       DATE NOT NULL,
    year            SMALLINT,
    quarter         TINYINT,
    month_number    TINYINT,
    month_name      VARCHAR(10),
    month_short     CHAR(3),
    year_month_text      CHAR(7),                  -- YYYY-MM
    day_of_month    TINYINT,
    day_of_year     SMALLINT,
    week_of_year    TINYINT,                  -- ISO week (Monday start)
    day_of_week     TINYINT,                  -- 1 = Monday .. 7 = Sunday
    day_name        VARCHAR(10),
    is_weekend      TINYINT(1),
    is_month_end    TINYINT(1),
    fiscal_year     SMALLINT,
    fiscal_quarter  TINYINT,
    fiscal_month    TINYINT,
    UNIQUE KEY uq_dim_date_full_date (full_date)
);

-- Populate dim_date only if it is empty (keeps re-runs fast and idempotent).
INSERT INTO dw.dim_date (
    date_key, full_date, year, quarter, month_number, month_name, month_short,
    year_month_text, day_of_month, day_of_year, week_of_year, day_of_week, day_name,
    is_weekend, is_month_end, fiscal_year, fiscal_quarter, fiscal_month
)
SELECT
    CAST(DATE_FORMAT(x.d, '%Y%m%d') AS UNSIGNED),
    x.d,
    YEAR(x.d),
    QUARTER(x.d),
    MONTH(x.d),
    MONTHNAME(x.d),
    LEFT(MONTHNAME(x.d), 3),
    DATE_FORMAT(x.d, '%Y-%m'),
    DAYOFMONTH(x.d),
    DAYOFYEAR(x.d),
    WEEK(x.d, 3),
    WEEKDAY(x.d) + 1,
    DAYNAME(x.d),
    CASE WHEN WEEKDAY(x.d) >= 5 THEN 1 ELSE 0 END,
    CASE WHEN x.d = LAST_DAY(x.d) THEN 1 ELSE 0 END,
    YEAR(x.d) + CASE WHEN MONTH(x.d) >= 7 THEN 1 ELSE 0 END,
    CEIL((MOD(MONTH(x.d) + 5, 12) + 1) / 3),
    MOD(MONTH(x.d) + 5, 12) + 1
FROM (
    SELECT DATE_ADD('1990-01-01', INTERVAL n.n DAY) AS d
    FROM (
        SELECT t0.n + t1.n * 10 + t2.n * 100 + t3.n * 1000
             + t4.n * 10000 + t5.n * 100000 + t6.n * 1000000 AS n
        FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t0
        CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1
        CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2
        CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t3
        CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t4
        CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t5
        CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) t6
    ) n
    WHERE n.n <= DATEDIFF('9999-12-31', '1990-01-01')
) x
WHERE NOT EXISTS (SELECT 1 FROM dw.dim_date);

-- ---------------------------------------------------------------- fact table
-- Grain: one row per order line (order x product).

CREATE TABLE IF NOT EXISTS dw.fact_orders (
    order_id    INT NOT NULL,
    customer_sk INT NOT NULL,
    product_sk  INT NOT NULL,
    employee_sk INT NOT NULL,
    supplier_sk INT NOT NULL,
    date_key    INT NOT NULL,
    unit_price  DECIMAL(10,2),
    quantity    INT,
    discount    DECIMAL(4,2),
    line_total  DECIMAL(12,2),
    PRIMARY KEY (order_id, product_sk),
    CONSTRAINT fk_fact_customer FOREIGN KEY (customer_sk) REFERENCES dw.dim_customers (customer_sk),
    CONSTRAINT fk_fact_product  FOREIGN KEY (product_sk)  REFERENCES dw.dim_products (product_sk),
    CONSTRAINT fk_fact_employee FOREIGN KEY (employee_sk) REFERENCES dw.dim_employees (employee_sk),
    CONSTRAINT fk_fact_supplier FOREIGN KEY (supplier_sk) REFERENCES dw.dim_suppliers (supplier_sk),
    CONSTRAINT fk_fact_date     FOREIGN KEY (date_key)    REFERENCES dw.dim_date (date_key)
);

-- The capstone brief calls the fact table dw.fact_sales. The physical table keeps
-- its original name (fact_orders) so the existing Power BI report keeps working;
-- fact_sales is a view over it.
CREATE OR REPLACE VIEW dw.fact_sales AS
SELECT * FROM dw.fact_orders;
