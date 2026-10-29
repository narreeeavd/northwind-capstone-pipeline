USE dw;

INSERT INTO dw.fact_orders (
    order_id, 
    customer_sk, 
    product_sk, 
    employee_sk, 
    supplier_sk, 
    date_key, 
    unit_price, 
    quantity, 
    discount, 
    line_total
) 
SELECT 
    o.OrderID, 
    c.customer_sk, 
    p.product_sk, 
    e.employee_sk, 
    s.supplier_sk, 
    
    -- (YYYY-MM-DD) -> INT (YYYYMMDD)
    CAST(DATE_FORMAT(STR_TO_DATE(LEFT(o.OrderDate, 10), '%Y-%m-%d'), '%Y%m%d') AS SIGNED) AS date_key, 
    CAST(od.UnitPrice AS DECIMAL(10,2)) AS unit_price, 
    CAST(od.Quantity AS SIGNED) AS quantity, 
    CAST(od.Discount AS DECIMAL(4,2)) AS discount, 
    (CAST(od.UnitPrice AS DECIMAL(10,2)) * CAST(od.Quantity AS SIGNED)) * (1 - CAST(od.Discount AS DECIMAL(4,2))) AS line_total 
FROM stg.order_details od 
JOIN stg.orders o ON od.OrderID = o.OrderID 
LEFT JOIN dw.dim_customers c ON o.CustomerID = c.customer_id 
LEFT JOIN dw.dim_products p ON od.ProductID = p.product_id 
LEFT JOIN dw.dim_employees e ON o.EmployeeID = e.employee_id 
LEFT JOIN stg.products stg_p ON od.ProductID = stg_p.ProductID 
LEFT JOIN dw.dim_suppliers s ON stg_p.SupplierID = s.supplier_id 
ON DUPLICATE KEY UPDATE 
    customer_sk = VALUES(customer_sk), 
    employee_sk = VALUES(employee_sk), 
    supplier_sk = VALUES(supplier_sk), 
    date_key = VALUES(date_key), 
    unit_price = VALUES(unit_price), 
    quantity = VALUES(quantity), 
    discount = VALUES(discount), 
    line_total = VALUES(line_total);