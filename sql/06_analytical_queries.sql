-- 06_analytical_queries.sql
-- Business queries that read only from the dw schema (star schema).
-- Not part of the pipeline run; execute manually or reuse in the notebook / Power BI.

-- 1. Revenue by product category
SELECT
    p.category_name,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    SUM(f.quantity)             AS total_items_sold,
    ROUND(SUM(f.line_total), 2) AS total_revenue
FROM dw.fact_orders f
JOIN dw.dim_products p ON p.product_sk = f.product_sk
GROUP BY p.category_name
ORDER BY total_revenue DESC;

-- 2. Monthly revenue trend
SELECT
    d.year_month_text,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    SUM(f.quantity)             AS total_items_sold,
    ROUND(SUM(f.line_total), 2) AS monthly_revenue
FROM dw.fact_orders f
JOIN dw.dim_date d ON d.date_key = f.date_key
GROUP BY d.year_month_text
ORDER BY d.year_month_text;

-- 3. Revenue by customer country
SELECT
    c.country,
    COUNT(DISTINCT f.customer_sk) AS active_customers,
    COUNT(DISTINCT f.order_id)    AS total_orders,
    ROUND(SUM(f.line_total), 2)   AS total_revenue
FROM dw.fact_orders f
JOIN dw.dim_customers c ON c.customer_sk = f.customer_sk
GROUP BY c.country
ORDER BY total_revenue DESC;

-- 4. Revenue by discount tier
SELECT
    CASE
        WHEN f.discount = 0    THEN '0% (No Discount)'
        WHEN f.discount <= 0.10 THEN '1% - 10% Discount'
        WHEN f.discount <= 0.20 THEN '11% - 20% Discount'
        ELSE 'Above 20% Discount'
    END                               AS discount_tier,
    COUNT(*)                          AS order_lines,
    ROUND(SUM(f.line_total), 2)       AS total_revenue,
    ROUND(AVG(f.discount) * 100, 2)   AS avg_discount_pct
FROM dw.fact_orders f
GROUP BY discount_tier
ORDER BY total_revenue DESC;

-- 5. Revenue by supplier
SELECT
    s.company_name                    AS supplier_name,
    s.country                         AS supplier_country,
    COUNT(DISTINCT f.product_sk)      AS unique_products_sold,
    SUM(f.quantity)                   AS total_units_sold,
    ROUND(SUM(f.line_total), 2)       AS total_revenue
FROM dw.fact_orders f
JOIN dw.dim_suppliers s ON s.supplier_sk = f.supplier_sk
GROUP BY s.supplier_sk, s.company_name, s.country
ORDER BY total_revenue DESC;

-- 6. Sales performance by employee
SELECT
    e.full_name,
    e.title,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    ROUND(SUM(f.line_total), 2) AS total_revenue
FROM dw.fact_orders f
JOIN dw.dim_employees e ON e.employee_sk = f.employee_sk
GROUP BY e.employee_sk, e.full_name, e.title
ORDER BY total_revenue DESC;

-- 7. Revenue by year and quarter
SELECT
    d.year,
    d.quarter,
    ROUND(SUM(f.line_total), 2) AS revenue
FROM dw.fact_orders f
JOIN dw.dim_date d ON d.date_key = f.date_key
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;
