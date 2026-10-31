-- 04_upsert_dimensions.sql
-- Idempotent load of the dimensions from stg to dw.
-- Each dimension has a UNIQUE business key, so re-running updates rows in place.
-- Staging columns are raw text, so values are cast here.

-- 1. Customers
INSERT INTO dw.dim_customers
    (customer_id, company_name, contact_name, contact_title, city, region, postal_code, country)
SELECT customerID, companyName, contactName, contactTitle, city, region, postalCode, country
FROM stg.customers
ON DUPLICATE KEY UPDATE
    company_name  = VALUES(company_name),
    contact_name  = VALUES(contact_name),
    contact_title = VALUES(contact_title),
    city          = VALUES(city),
    region        = VALUES(region),
    postal_code   = VALUES(postal_code),
    country       = VALUES(country);

-- 2. Products (flattened with the category name)
INSERT INTO dw.dim_products
    (product_id, product_name, category_id, category_name, supplier_id,
     quantity_per_unit, unit_price, units_in_stock, is_discontinued)
SELECT
    CAST(p.productID AS UNSIGNED),
    p.productName,
    CAST(p.categoryID AS UNSIGNED),
    c.categoryName,
    CAST(p.supplierID AS UNSIGNED),
    p.quantityPerUnit,
    CAST(p.unitPrice AS DECIMAL(10,2)),
    CAST(p.unitsInStock AS SIGNED),
    CAST(p.discontinued AS SIGNED)
FROM stg.products p
LEFT JOIN stg.categories c ON c.categoryID = p.categoryID
ON DUPLICATE KEY UPDATE
    product_name      = VALUES(product_name),
    category_id       = VALUES(category_id),
    category_name     = VALUES(category_name),
    supplier_id       = VALUES(supplier_id),
    quantity_per_unit = VALUES(quantity_per_unit),
    unit_price        = VALUES(unit_price),
    units_in_stock    = VALUES(units_in_stock),
    is_discontinued   = VALUES(is_discontinued);

-- 3. Employees
INSERT INTO dw.dim_employees
    (employee_id, full_name, title, hire_date, city, country, reports_to)
SELECT
    CAST(employeeID AS UNSIGNED),
    CONCAT(firstName, ' ', lastName),
    title,
    STR_TO_DATE(LEFT(hireDate, 10), '%Y-%m-%d'),
    city,
    country,
    CAST(reportsTo AS UNSIGNED)
FROM stg.employees
ON DUPLICATE KEY UPDATE
    full_name  = VALUES(full_name),
    title      = VALUES(title),
    hire_date  = VALUES(hire_date),
    city       = VALUES(city),
    country    = VALUES(country),
    reports_to = VALUES(reports_to);

-- 4. Suppliers
INSERT INTO dw.dim_suppliers
    (supplier_id, company_name, contact_name, city, country)
SELECT CAST(supplierID AS UNSIGNED), companyName, contactName, city, country
FROM stg.suppliers
ON DUPLICATE KEY UPDATE
    company_name = VALUES(company_name),
    contact_name = VALUES(contact_name),
    city         = VALUES(city),
    country      = VALUES(country);
