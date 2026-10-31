-- 05_upsert_fact_sales.sql
-- Idempotent load of the fact table (grain: one row per order line).
-- Primary key (order_id, product_sk) makes re-runs update rows instead of duplicating them.
-- INNER JOINs guarantee every fact row has valid surrogate keys (no orphans / NULL keys).

INSERT INTO dw.fact_orders
    (order_id, customer_sk, product_sk, employee_sk, supplier_sk, date_key,
     unit_price, quantity, discount, line_total)
SELECT
    CAST(o.orderID AS UNSIGNED)                                         AS order_id,
    c.customer_sk,
    p.product_sk,
    e.employee_sk,
    s.supplier_sk,
    d.date_key,
    CAST(od.unitPrice AS DECIMAL(10,2))                                 AS unit_price,
    CAST(od.quantity AS SIGNED)                                         AS quantity,
    CAST(od.discount AS DECIMAL(4,2))                                   AS discount,
    CAST(od.unitPrice AS DECIMAL(10,2)) * CAST(od.quantity AS SIGNED)
        * (1 - CAST(od.discount AS DECIMAL(4,2)))                       AS line_total
FROM stg.order_details od
JOIN stg.orders        o ON o.orderID = od.orderID
JOIN dw.dim_customers  c ON c.customer_id = o.customerID
JOIN dw.dim_products   p ON p.product_id = CAST(od.productID AS UNSIGNED)
JOIN dw.dim_employees  e ON e.employee_id = CAST(o.employeeID AS UNSIGNED)
JOIN dw.dim_suppliers  s ON s.supplier_id = p.supplier_id
JOIN dw.dim_date       d ON d.full_date = STR_TO_DATE(LEFT(o.orderDate, 10), '%Y-%m-%d')
ON DUPLICATE KEY UPDATE
    customer_sk = VALUES(customer_sk),
    employee_sk = VALUES(employee_sk),
    supplier_sk = VALUES(supplier_sk),
    date_key    = VALUES(date_key),
    unit_price  = VALUES(unit_price),
    quantity    = VALUES(quantity),
    discount    = VALUES(discount),
    line_total  = VALUES(line_total);
