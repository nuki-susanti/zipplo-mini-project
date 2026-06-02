CREATE OR ALTER PROCEDURE create_databases_procedure
AS
BEGIN

SET NOCOUNT ON;
-- all etl scripts combined in the try statement
BEGIN TRY
-- create operational database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ZipploDB')
BEGIN
    CREATE DATABASE ZipploDB;
    PRINT 'Database ZipploDB created successfully.';
END
ELSE
BEGIN
    PRINT 'Database ZipploDB already exists.';
END
-- create data warehouse database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ZipploDW')
BEGIN
    CREATE DATABASE ZipploDW;
    PRINT 'Database ZipploDW created successfully.';
END
ELSE
BEGIN
    PRINT 'Database ZipploDW already exists.';
END

-- create staging tables for ZipploDB
------------------------------------------------------
-- SETUP SCRIPT FOR STAGING TABLES
------------------------------------------------------

DROP TABLE IF EXISTS ZipploDB.dbo.stg_Employee;
DROP TABLE IF EXISTS ZipploDB.dbo.stg_Customer;
DROP TABLE IF EXISTS ZipploDB.dbo.stg_Equipment;
DROP TABLE IF EXISTS ZipploDB.dbo.stg_RentalPlace;
DROP TABLE IF EXISTS ZipploDB.dbo.stg_EquipmentUnit;
DROP TABLE IF EXISTS ZipploDB.dbo.stg_EquipmentUnit;
DROP TABLE IF EXISTS ZipploDB.dbo.stg_RentalTransaction;


CREATE TABLE ZipploDB.dbo.stg_Employee (
    employee_id INT,
    name NVARCHAR(100),
    position VARCHAR(50)
);

CREATE TABLE ZipploDB.dbo.stg_Customer (
    customer_id INT,
    name NVARCHAR(100),
    type VARCHAR(20),
    company NVARCHAR(100),
    business_id VARCHAR(50)
);

CREATE TABLE ZipploDB.dbo.stg_Equipment (
    equipment_id INT,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    model VARCHAR(50),
    price_per_minute DECIMAL(10,2)
);

CREATE TABLE ZipploDB.dbo.stg_RentalPlace (
    place_id INT,
    type VARCHAR(50),
    name NVARCHAR(100),
    address NVARCHAR(300),
    city NVARCHAR(100),
    country VARCHAR(50),
    employee_id INT
);

CREATE TABLE ZipploDB.dbo.stg_EquipmentUnit (
    equipment_unit_id INT,
    equipment_id INT,
    serial_number VARCHAR(50),
    purchase_date DATE,
    last_maintenance DATE,
    condition VARCHAR(50)
);

CREATE TABLE ZipploDB.dbo.stg_RentalTransaction (
    transaction_id INT,
    equipment_unit_id INT,
    customer_id INT,
    pickup_location_id INT,
    start_time DATETIME2(7),
    return_location_id INT,
    end_time DATETIME2(7),
    amount DECIMAL(10,2),
    km DECIMAL(10,2)
);

-- create tables for ZipploDB

DROP TABLE IF EXISTS ZipploDB.dbo.RentalTransaction;
DROP TABLE IF EXISTS ZipploDB.dbo.EquipmentUnit;
DROP TABLE IF EXISTS ZipploDB.dbo.Equipment;
DROP TABLE IF EXISTS ZipploDB.dbo.Customer;
DROP TABLE IF EXISTS ZipploDB.dbo.RentalPlace;
DROP TABLE IF EXISTS ZipploDB.dbo.Employee;

CREATE TABLE ZipploDB.dbo.Employee (
    employee_id INT NOT NULL IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL

    CONSTRAINT pk_employee PRIMARY KEY (employee_id)
)

CREATE TABLE ZipploDB.dbo.RentalPlace (
    place_id INT IDENTITY(1,1),
    type VARCHAR(50) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    address NVARCHAR(300) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    employee_id INT NULL
    
    CONSTRAINT pk_rentalplace PRIMARY KEY (place_id),
    CONSTRAINT chk_rentalplace CHECK(type IN ('store', 'station')),
);


CREATE TABLE ZipploDB.dbo.Customer (
    customer_id INT NOT NULL IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    type   VARCHAR(20) NOT NULL DEFAULT 'private',
    company NVARCHAR(100) NULL,
    business_id VARCHAR(50) NULL
           
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT chk_type CHECK(type IN ('private', 'corporate'))
);



CREATE TABLE ZipploDB.dbo.Equipment (
    equipment_id INT NOT NULL IDENTITY(1,1),
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    price_per_min DECIMAL(10,2) NOT NULL --what currency?

    CONSTRAINT pk_equipment PRIMARY KEY (equipment_id)
);


CREATE TABLE ZipploDB.dbo.EquipmentUnit (
    equipment_unit_id INT NOT NULL IDENTITY(1,1),
    equipment_id INT NOT NULL,
    serial_number VARCHAR(50) NOT NULL,
    purchase_date DATE NOT NULL,
    last_maintenance DATE NULL,
    condition VARCHAR(50) NOT NULL DEFAULT 'good'

    CONSTRAINT pk_equipment_unit PRIMARY KEY (equipment_unit_id),
    CONSTRAINT uq_equipment_unit_serial_number UNIQUE(serial_number),
    CONSTRAINT chk_equipment_unit_condition CHECK(condition IN ('good', 'fair', 'poor'))
);


CREATE TABLE ZipploDB.dbo.RentalTransaction (
    transaction_id INT NOT NULL IDENTITY(1,1),
    equipment_unit_id INT NOT NULL,
    customer_id INT NOT NULL,
    pickup_location_id INT NOT NULL,
    start_time DATETIME2(7) NOT NULL,
    return_location_id INT NOT NULL,
    end_time DATETIME2(7) NULL,
    amount DECIMAL(10,2) NULL,
    km DECIMAL(10,3) NULL

    CONSTRAINT pk_rental_transaction PRIMARY KEY (transaction_id)
)

------------------------------------------------------
-- ADD FOREIGN KEY CONSTRAINTS
------------------------------------------------------

ALTER TABLE ZipploDB.dbo.RentalPlace 
    ADD CONSTRAINT fk_rentalplace_employee FOREIGN KEY(employee_id) REFERENCES ZipploDB.dbo.Employee(employee_id)

ALTER TABLE ZipploDB.dbo.EquipmentUnit
    ADD CONSTRAINT fk_equipment_unit_equipment FOREIGN KEY (equipment_id) REFERENCES ZipploDB.dbo.Equipment(equipment_id)

ALTER TABLE ZipploDB.dbo.RentalTransaction
    ADD CONSTRAINT fk_rental_transaction_unit FOREIGN KEY (equipment_unit_id) REFERENCES ZipploDB.dbo.EquipmentUnit(equipment_unit_id)
ALTER TABLE ZipploDB.dbo.RentalTransaction
    ADD CONSTRAINT fk_rental_transaction_customer FOREIGN KEY (customer_id) REFERENCES ZipploDB.dbo.Customer(customer_id)
ALTER TABLE ZipploDB.dbo.RentalTransaction
    ADD CONSTRAINT fk_rental_transaction_pickup FOREIGN KEY (pickup_location_id) REFERENCES ZipploDB.dbo.RentalPlace(place_id)
ALTER TABLE ZipploDB.dbo.RentalTransaction
    ADD CONSTRAINT fk_rental_transaction_return FOREIGN KEY (return_location_id) REFERENCES ZipploDB.dbo.RentalPlace(place_id)

-- create tables for ZipploDW
-- ===================================================================
-- 1. Dimensions table
-- ===================================================================
-- ===================================================================

DROP TABLE IF EXISTS ZipploDW.dbo.fact_rental;
DROP TABLE IF EXISTS ZipploDW.dbo.dim_customer;
DROP TABLE IF EXISTS ZipploDW.dbo.dim_location;
DROP TABLE IF EXISTS ZipploDW.dbo.dim_equipment;
DROP TABLE IF EXISTS ZipploDW.dbo.dim_date;

CREATE TABLE ZipploDW.dbo.dim_date (
    date_id INT PRIMARY KEY,
    [date] DATE,
    [day] INT,
    [month] INT,
    [quarter] INT,
    [year] INT
);

CREATE TABLE ZipploDW.dbo.dim_equipment (
    equipment_unit_id INT IDENTITY(1, 1) PRIMARY KEY,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    model VARCHAR(50),
    serial_number VARCHAR(50),
    price_per_minute DECIMAL(10, 2),
    purchase_date DATE,
    last_maintenance DATE,
    condition VARCHAR(50),
    equipment_unit_alt_key INT,
    equipment_alt_key INT
);

CREATE TABLE ZipploDW.dbo.dim_location (
    location_id INT IDENTITY(1, 1) PRIMARY KEY,
    location_type VARCHAR(50),
    location_name NVARCHAR(100),
    address NVARCHAR(100),
    city NVARCHAR(100),
    country VARCHAR(50),
    place_alt_key INT
);

CREATE TABLE ZipploDW.dbo.dim_customer (
    customer_id INT IDENTITY(1, 1) PRIMARY KEY,
    customer_name NVARCHAR(100),
    [type] NVARCHAR(100), 
    company NVARCHAR(100),
    customer_alt_key INT
);

-- ===================================================================
-- 2. Fact table
-- ===================================================================
CREATE TABLE ZipploDW.dbo.fact_rental (
    transaction_id INT PRIMARY KEY,
    amount DECIMAL(10, 2),
    start_date_id INT, 
    end_date_id INT, 
    customer_id INT, 
    equipment_unit_id INT, 
    pick_up_location INT, 
    return_location INT, 
    duration INT,
    [count] INT DEFAULT 1,
    km DECIMAL(10, 3),
    start_time time,
    end_time time,

    -- Definition of Constraints
    CONSTRAINT fk_fact_rental_start_date FOREIGN KEY (start_date_id) 
        REFERENCES ZipploDW.dbo.dim_date(date_id),
    CONSTRAINT fk_fact_rental_end_date FOREIGN KEY (end_date_id) 
        REFERENCES ZipploDW.dbo.dim_date(date_id),
    CONSTRAINT fk_fact_rental_customer FOREIGN KEY (customer_id) 
        REFERENCES ZipploDW.dbo.dim_customer(customer_id),
    CONSTRAINT fk_fact_rental_equipment FOREIGN KEY (equipment_unit_id) 
        REFERENCES ZipploDW.dbo.dim_equipment(equipment_unit_id),
    CONSTRAINT fk_fact_rental_pick_up_location FOREIGN KEY (pick_up_location) 
        REFERENCES ZipploDW.dbo.dim_location(location_id),
    CONSTRAINT fk_fact_rental_return_location FOREIGN KEY (return_location) 
        REFERENCES ZipploDW.dbo.dim_location(location_id)
);

-- populate dim_date with date data from 2020-01-01 to 2040-12-31

-- Optional: Clear the table before repopulating
-- TRUNCATE TABLE dim_date;

-- Set the date range for the dimension
DECLARE @StartDate DATE = '2020-01-01'; -- Start date
DECLARE @EndDate DATE = '2040-12-31';   -- End date (covers 20 years)

-- Use a recursive CTE to generate all days between @StartDate and @EndDate
WITH DateDimension_CTE AS (
    SELECT @StartDate AS CurrentDate
    UNION ALL
    SELECT DATEADD(DAY, 1, CurrentDate)
    FROM DateDimension_CTE
    WHERE CurrentDate < @EndDate
)
INSERT INTO ZipploDW.dbo.dim_date (date_id, [date], [day], [month], [quarter], [year])
SELECT 
    -- Generates a numeric ID in YYYYMMDD format (e.g., 20260601 for today)
    -- This format is highly efficient for joins and remains human-readable.
    CONVERT(INT, CONVERT(VARCHAR(8), CurrentDate, 112)) AS date_id,
    CurrentDate AS [date],
    DAY(CurrentDate) AS [day],
    MONTH(CurrentDate) AS [month],
    DATEPART(QUARTER, CurrentDate) AS [quarter],
    YEAR(CurrentDate) AS [year]
FROM DateDimension_CTE
-- OPTION (MAXRECURSION 0) is mandatory to allow more than 100 recursive steps
OPTION (MAXRECURSION 0); 

--------------------------
END TRY 
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'error in creation: ' + @ErrorMessage;
END CATCH

END