USE dw;

-- 1.Fill of Customers Dimension
INSERT INTO dw.dim_customers (customer_id, company_name, country)
SELECT CustomerID, CompanyName, Country
FROM stg.customers
ON DUPLICATE KEY UPDATE 
    company_name = VALUES(company_name),
    country = VALUES(country);

-- 2. Fill of Products Dimension
INSERT INTO dw.dim_products (product_id, product_name, unit_price)
SELECT ProductID, ProductName, UnitPrice
FROM stg.products
ON DUPLICATE KEY UPDATE 
    product_name = VALUES(product_name),
    unit_price = VALUES(unit_price);

-- 3.Fill of Employees Dimension
INSERT INTO dw.dim_employees (employee_id, full_name, title)
SELECT EmployeeID, CONCAT(FirstName, ' ', LastName), Title
FROM stg.employees
ON DUPLICATE KEY UPDATE 
    full_name = VALUES(full_name),
    title = VALUES(title);

-- 4.Fill of Suppliers Dimension
INSERT INTO dw.dim_suppliers (supplier_id, company_name, country)
SELECT SupplierID, CompanyName, Country
FROM stg.suppliers
ON DUPLICATE KEY UPDATE 
    company_name = VALUES(company_name),
    country = VALUES(country);