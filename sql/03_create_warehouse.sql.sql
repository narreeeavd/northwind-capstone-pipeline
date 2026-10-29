USE dw;

-- Dim Customers
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_sk INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(50),
    company_name VARCHAR(255),
    country VARCHAR(100)
);

-- Dim Products
CREATE TABLE IF NOT EXISTS dim_products (
    product_sk INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(255),
    unit_price DECIMAL(10,2)
);

-- Dim Employees
CREATE TABLE IF NOT EXISTS dim_employees (
    employee_sk INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    full_name VARCHAR(200),
    title VARCHAR(100)
);

-- Dim Suppliers
CREATE TABLE IF NOT EXISTS dim_suppliers (
    supplier_sk INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT,
    company_name VARCHAR(255),
    country VARCHAR(100)
);

-- Fact Orders
CREATE TABLE IF NOT EXISTS fact_orders (
    order_id INT,
    customer_sk INT,
    product_sk INT,
    employee_sk INT,
    supplier_sk INT,
    date_key INT,
    unit_price DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(4,2),
    line_total DECIMAL(12,2),
    PRIMARY KEY (order_id, product_sk)
);