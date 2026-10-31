-- 02_create_staging.sql
-- 1:1 staging tables: same table and column names as the source CSV files,
-- every column loaded as raw text (no type changes, no keys, no transformation).
-- Casting to proper data types happens later, in the dw load (04_ / 05_).

CREATE TABLE IF NOT EXISTS stg.categories (
    categoryID   VARCHAR(255),
    categoryName VARCHAR(255),
    description  TEXT,
    picture      LONGTEXT
);

CREATE TABLE IF NOT EXISTS stg.customers (
    customerID   VARCHAR(255),
    companyName  VARCHAR(255),
    contactName  VARCHAR(255),
    contactTitle VARCHAR(255),
    address      VARCHAR(255),
    city         VARCHAR(255),
    region       VARCHAR(255),
    postalCode   VARCHAR(255),
    country      VARCHAR(255),
    phone        VARCHAR(255),
    fax          VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.customer_customer_demo (
    customerID     VARCHAR(255),
    customerTypeID VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.customer_demographics (
    customerTypeID VARCHAR(255),
    customerDesc   TEXT
);

CREATE TABLE IF NOT EXISTS stg.employees (
    employeeID       VARCHAR(255),
    lastName         VARCHAR(255),
    firstName        VARCHAR(255),
    title            VARCHAR(255),
    titleOfCourtesy  VARCHAR(255),
    birthDate        VARCHAR(255),
    hireDate         VARCHAR(255),
    address          VARCHAR(255),
    city             VARCHAR(255),
    region           VARCHAR(255),
    postalCode       VARCHAR(255),
    country          VARCHAR(255),
    homePhone        VARCHAR(255),
    extension        VARCHAR(255),
    photo            LONGTEXT,
    notes            TEXT,
    reportsTo        VARCHAR(255),
    photoPath        VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.employee_territories (
    employeeID  VARCHAR(255),
    territoryID VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.order_details (
    orderID   VARCHAR(255),
    productID VARCHAR(255),
    unitPrice VARCHAR(255),
    quantity  VARCHAR(255),
    discount  VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.orders (
    orderID        VARCHAR(255),
    customerID     VARCHAR(255),
    employeeID     VARCHAR(255),
    orderDate      VARCHAR(255),
    requiredDate   VARCHAR(255),
    shippedDate    VARCHAR(255),
    shipVia        VARCHAR(255),
    freight        VARCHAR(255),
    shipName       VARCHAR(255),
    shipAddress    VARCHAR(255),
    shipCity       VARCHAR(255),
    shipRegion     VARCHAR(255),
    shipPostalCode VARCHAR(255),
    shipCountry    VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.products (
    productID       VARCHAR(255),
    productName     VARCHAR(255),
    supplierID      VARCHAR(255),
    categoryID      VARCHAR(255),
    quantityPerUnit VARCHAR(255),
    unitPrice       VARCHAR(255),
    unitsInStock    VARCHAR(255),
    unitsOnOrder    VARCHAR(255),
    reorderLevel    VARCHAR(255),
    discontinued    VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.regions (
    regionID          VARCHAR(255),
    regionDescription VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.shippers (
    shipperID   VARCHAR(255),
    companyName VARCHAR(255),
    phone       VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS stg.suppliers (
    supplierID  VARCHAR(255),
    companyName VARCHAR(255),
    contactName VARCHAR(255),
    contactTitle VARCHAR(255),
    address     VARCHAR(255),
    city        VARCHAR(255),
    region      VARCHAR(255),
    postalCode  VARCHAR(255),
    country     VARCHAR(255),
    phone       VARCHAR(255),
    fax         VARCHAR(255),
    homePage    TEXT
);

CREATE TABLE IF NOT EXISTS stg.territories (
    territoryID          VARCHAR(255),
    territoryDescription VARCHAR(255),
    regionID             VARCHAR(255)
);
