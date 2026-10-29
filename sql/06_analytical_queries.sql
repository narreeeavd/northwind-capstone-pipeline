SELECT 
    cat.CategoryName,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_items_sold,
    ROUND(SUM(f.line_total), 2) AS total_revenue
FROM dw.fact_orders f
JOIN dw.dim_products p ON f.product_sk = p.product_sk
JOIN stg.products stg_p ON p.product_id = stg_p.ProductID
JOIN stg.categories cat ON stg_p.CategoryID = cat.CategoryID
GROUP BY cat.CategoryName
ORDER BY total_revenue DESC;

SELECT 
    LEFT(o.OrderDate, 7) AS year_months,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.quantity) AS total_items_sold,
    ROUND(SUM(f.line_total), 2) AS monthly_revenue
FROM dw.fact_orders f
JOIN stg.orders o ON f.order_id = o.OrderID
GROUP BY LEFT(o.OrderDate, 7)
ORDER BY year_months ASC;


SELECT 
    c.country,
    COUNT(DISTINCT f.customer_sk) AS active_customers_count,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.line_total), 2) AS total_revenue
FROM dw.fact_orders f
JOIN dw.dim_customers c ON f.customer_sk = c.customer_sk
GROUP BY c.country
ORDER BY total_revenue DESC;


SELECT 
    CASE 
        WHEN f.discount = 0 THEN '0% (No Discount)'
        WHEN f.discount <= 0.10 THEN '1% - 10% Discount'
        WHEN f.discount <= 0.20 THEN '11% - 20% Discount'
        ELSE 'Above 20% Discount'
    END AS discount_tier,
    COUNT(*) AS order_items_count,
    ROUND(SUM(f.line_total), 2) AS total_revenue,
    ROUND(AVG(f.discount) * 100, 2) AS avg_discount_percentage
FROM dw.fact_orders f
GROUP BY discount_tier
ORDER BY total_revenue DESC;

SELECT 
    s.company_name AS supplier_name,
    s.country AS supplier_country,
    COUNT(DISTINCT f.product_sk) AS unique_products_sold,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.line_total), 2) AS total_revenue_generated
FROM dw.fact_orders f
JOIN dw.dim_suppliers s ON f.supplier_sk = s.supplier_sk
GROUP BY s.supplier_sk, s.company_name, s.country
ORDER BY total_revenue_generated DESC;