USE stg;

-- Categories
CREATE TABLE IF NOT EXISTS categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(255),
    Description TEXT
);

-- Customers
CREATE TABLE IF NOT EXISTS customers (
    CustomerID VARCHAR(50) PRIMARY KEY,
    CompanyName VARCHAR(255),
    ContactName VARCHAR(255),
    ContactTitle VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(100),
    Region VARCHAR(100),
    PostalCode VARCHAR(50),
    Country VARCHAR(100),
    Phone VARCHAR(50),
    Fax VARCHAR(50)
);

-- Employees
CREATE TABLE IF NOT EXISTS employees (
    EmployeeID INT PRIMARY KEY,
    LastName VARCHAR(100),
    FirstName VARCHAR(100),
    Title VARCHAR(100),
    BirthDate VARCHAR(50),
    HireDate VARCHAR(50),
    Address VARCHAR(255),
    City VARCHAR(100),
    Country VARCHAR(100),
    HomePhone VARCHAR(50)
);

-- Products
CREATE TABLE IF NOT EXISTS products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(255),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit VARCHAR(100),
    UnitPrice DECIMAL(10,2),
    UnitsInStock INT,
    Discontinued INT
);

-- Suppliers
CREATE TABLE IF NOT EXISTS suppliers (
    SupplierID INT PRIMARY KEY,
    CompanyName VARCHAR(255),
    ContactName VARCHAR(255),
    City VARCHAR(100),
    Country VARCHAR(100)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
    OrderID INT PRIMARY KEY,
    CustomerID VARCHAR(50),
    EmployeeID INT,
    OrderDate VARCHAR(50),
    ShipCountry VARCHAR(100)
);

-- Order Details
CREATE TABLE IF NOT EXISTS order_details (
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(4,2),
    PRIMARY KEY (OrderID, ProductID)
);