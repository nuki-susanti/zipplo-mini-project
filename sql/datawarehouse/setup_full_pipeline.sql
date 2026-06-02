-- create_databases -- 1
CREATE OR ALTER PROCEDURE create_databases
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
GO

-- ingest_csv_data  -- 2
CREATE OR ALTER PROCEDURE ingest_csv_data
AS
BEGIN

SET NOCOUNT ON;

BEGIN TRY

-- ingestion script
------------------------------------------------------
-- SCRIPT FOR DATA INSERTION FROM CSV TO OPERATIONAL DATABASE USING STAGING TABLES
-- STAGING TABLES NEED TO BE CREATED FIRST
------------------------------------------------------
-- EMPLOYEE
TRUNCATE TABLE ZipploDB.dbo.stg_Employee;

BULK INSERT ZipploDB.dbo.stg_Employee
FROM 'C:\backup\ZIPPLO TEST DATA\Employee.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT ZipploDB.dbo.Employee ON;
INSERT INTO ZipploDB.dbo.Employee (
    employee_id, 
    name, 
    position)
SELECT 
    employee_id, 
    name, 
    position
FROM ZipploDB.dbo.stg_Employee;
SET IDENTITY_INSERT ZipploDB.dbo.Employee OFF;


-- CUSTOMER
TRUNCATE TABLE ZipploDB.dbo.stg_Customer;

BULK INSERT ZipploDB.dbo.stg_Customer
FROM 'C:\backup\ZIPPLO TEST DATA\Customer.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT ZipploDB.dbo.Customer ON;
INSERT INTO ZipploDB.dbo.Customer (
    customer_id,
    name,
    type,
    company,
    business_id
)
SELECT
    customer_id,
    name,
    type,
    company,
    business_id
FROM ZipploDB.dbo.stg_Customer;
SET IDENTITY_INSERT ZipploDB.dbo.Customer OFF;


-- EQUIPMENT
TRUNCATE TABLE ZipploDB.dbo.stg_Equipment;

BULK INSERT ZipploDB.dbo.stg_Equipment
FROM 'C:\backup\ZIPPLO TEST DATA\Equipment.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT ZipploDB.dbo.Equipment ON;

INSERT INTO ZipploDB.dbo.Equipment (
    equipment_id,
    category,
    subcategory,
    model,
    price_per_min
)
SELECT
    equipment_id,
    category,
    subcategory,
    model,
    price_per_minute
FROM ZipploDB.dbo.stg_Equipment;
SET IDENTITY_INSERT ZipploDB.dbo.Equipment OFF;

-- RENTALPLACE
TRUNCATE TABLE ZipploDB.dbo.stg_RentalPlace;

BULK INSERT ZipploDB.dbo.stg_RentalPlace
FROM 'C:\backup\ZIPPLO TEST DATA\Rental_Place.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT ZipploDB.dbo.RentalPlace ON;
INSERT INTO ZipploDB.dbo.RentalPlace (
    place_id,
    type,
    name,
    address,
    city,
    country,
    employee_id
)
SELECT
    place_id,
    type,
    name,
    address,
    city,
    country,
    employee_id
FROM ZipploDB.dbo.stg_RentalPlace;
SET IDENTITY_INSERT ZipploDB.dbo.RentalPlace OFF;

-- EQUIPMENTUNIT
TRUNCATE TABLE ZipploDB.dbo.stg_EquipmentUnit;

BULK INSERT ZipploDB.dbo.stg_EquipmentUnit
FROM 'C:\backup\ZIPPLO TEST DATA\Equipment_Unit.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT ZipploDB.dbo.EquipmentUnit ON;
INSERT INTO ZipploDB.dbo.EquipmentUnit (
    equipment_unit_id,
    equipment_id,
    serial_number,
    purchase_date,
    last_maintenance,
    condition
)
SELECT
    equipment_unit_id,
    equipment_id,
    serial_number,
    purchase_date,
    last_maintenance,
    condition
FROM ZipploDB.dbo.stg_EquipmentUnit;
SET IDENTITY_INSERT ZipploDB.dbo.EquipmentUnit OFF;

-- RENTALTRANSACTION
TRUNCATE TABLE ZipploDB.dbo.stg_RentalTransaction;

BULK INSERT ZipploDB.dbo.stg_RentalTransaction
FROM 'C:\backup\ZIPPLO TEST DATA\Rental_Transaction.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT ZipploDB.dbo.RentalTransaction ON;

INSERT INTO ZipploDB.dbo.RentalTransaction (
    transaction_id,
    equipment_unit_id,
    customer_id,
    pickup_location_id,
    return_location_id,
    start_time,
    end_time,
    amount,
    km
)
SELECT
    transaction_id,
    equipment_unit_id,
    customer_id,
    pickup_location_id,
    return_location_id,
    start_time,
    end_time,
    amount,
    km
FROM ZipploDB.dbo.stg_RentalTransaction;
SET IDENTITY_INSERT ZipploDB.dbo.RentalTransaction OFF;

END TRY 
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'error in csv ingestion: ' + @ErrorMessage;
END CATCH

END
GO

-- etl_procedure    -- 3
CREATE OR ALTER PROCEDURE etl_procedure
AS
BEGIN

SET NOCOUNT ON;
-- all etl scripts combined in the try statement
BEGIN TRY
-- firstly all dim tables
-- customer
INSERT INTO ZipploDW.dbo.dim_customer (
    customer_name,
    [type],
    company,
    customer_alt_key
)
SELECT 
    c.name AS customer_name,
    c.type AS [type],
    c.company AS company,
    c.customer_id AS customer_alt_key
FROM ZipploDB.dbo.Customer AS c
-- alt
WHERE NOT EXISTS (
    SELECT 1
    FROM ZipploDW.dbo.dim_customer AS dc
    WHERE dc.customer_alt_key = c.customer_id
);

-- equipment
INSERT INTO ZipploDW.dbo.dim_equipment (
	category,
	subcategory,
	model,
	serial_number,
	price_per_minute,
	purchase_date,
	last_maintenance,
	condition,
	equipment_unit_alt_key,
	equipment_alt_key
)
SELECT
	e.category AS category,
	e.subcategory AS subcategory,
	e.model AS model,
	eu.serial_number AS serial_number,
	e.price_per_min AS price_per_min,
	eu.purchase_date AS purchase_date,
	eu.last_maintenance AS last_maintenance,
	eu.condition AS condition,
	eu.equipment_unit_id AS equipment_unit_id,
	e.equipment_id AS equipment_id
FROM ZipploDB.dbo.EquipmentUnit AS eu
JOIN ZipploDB.dbo.Equipment AS e
	ON eu.equipment_id = e.equipment_id
WHERE NOT EXISTS (
    SELECT 1
    FROM ZipploDW.dbo.dim_equipment AS de
    WHERE de.equipment_unit_alt_key = eu.equipment_unit_id 
		AND de.equipment_alt_key = e.equipment_id
);

-- location
INSERT INTO ZipploDW.dbo.dim_location (
    location_type,
    location_name,
    address,
    city,
    country,
    place_alt_key
)
SELECT
    rp.type,
    rp.name,
    rp.address,
    rp.city,
    rp.country,
    rp.place_id
FROM ZipploDB.dbo.RentalPlace AS rp
WHERE NOT EXISTS (
    SELECT 1
    FROM ZipploDW.dbo.dim_location AS dl
    WHERE dl.place_alt_key = rp.place_id
);

-- finally the fact table
INSERT INTO ZipploDW.dbo.fact_rental (
    transaction_id,
    amount,
    start_date_id,
    end_date_id,
    customer_id,
    equipment_unit_id,
    pick_up_location,
    return_location,
    duration,
    [count],
    km,
    start_time,
    end_time
)
SELECT 
    rt.transaction_id,
    rt.amount,
    -- start and end_date gets converted to YYYYMMDD (INT) in order to fit the primary key of dim_date
    CONVERT(INT, CONVERT(VARCHAR(8), rt.start_time, 112)) AS start_date_id,
    CONVERT(INT, CONVERT(VARCHAR(8), rt.end_time, 112)) AS end_date_id,
    
    dc.customer_id,       -- Surrogat Key from dim_customer
    de.equipment_unit_id, -- Surrogat Key from dim_equipment
    dl_pick.location_id,  -- Surrogat Key from dim_location
    dl_ret.location_id,   -- Surrogat Key from dim_location
    
    -- duration calculation
    DATEDIFF(MINUTE, rt.start_time, rt.end_time) AS duration,
    1 AS [count],
    rt.km,
    CAST(rt.start_time AS TIME) AS start_time,
    CAST(rt.end_time AS TIME) AS end_time
FROM ZipploDB.dbo.RentalTransaction AS rt
-- Joining of Dimensionen on their Alt-Keys (Original-IDs from ZipploDB)
LEFT JOIN ZipploDW.dbo.dim_customer dc 
    ON rt.customer_id = dc.customer_alt_key
LEFT JOIN ZipploDW.dbo.dim_equipment de 
    ON rt.equipment_unit_id = de.equipment_unit_alt_key
LEFT JOIN ZipploDW.dbo.dim_location dl_pick 
    ON rt.pickup_location_id = dl_pick.place_alt_key
LEFT JOIN ZipploDW.dbo.dim_location dl_ret 
    ON rt.return_location_id = dl_ret.place_alt_key
-- Filter: only insert rows which are not already in the fact table
WHERE NOT EXISTS (
    SELECT 1 FROM ZipploDW.dbo.fact_rental fr 
    WHERE fr.transaction_id = rt.transaction_id
);

END TRY 
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'error in etl process: ' + @ErrorMessage;
END CATCH

END
GO

-- dw_validation	-- 4
CREATE OR ALTER PROCEDURE dw_validation
AS
BEGIN

SET NOCOUNT ON;
BEGIN TRY
-- VALIDATION QUERIES

/*
1. Overall Totals Comparison

Description:
Compares the total number of rental transactions, total rental amount, and total kilometers between the operational database ZipploDB and the data warehouse ZipploDW.

Purpose:
This validation ensures that all rental transactions have been loaded into the data warehouse and that the most important numeric totals match between the
source system and the warehouse.
*/

WITH ZipploDB AS (
    SELECT
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount,
        SUM(KM) AS total_km
    FROM ZipploDB.dbo.RentalTransaction
),
ZipploDW AS (
    SELECT
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount,
        SUM(km) AS total_km
    FROM ZipploDW.dbo.fact_rental
)
SELECT
    ZipploDB.transaction_count AS ZipploDB_transaction_count,
    ZipploDW.transaction_count AS ZipploDW_transaction_count,
    ZipploDW.transaction_count - ZipploDB.transaction_count AS transaction_count_difference,

    ZipploDB.total_amount AS ZipploDB_total_amount,
    ZipploDW.total_amount AS ZipploDW_total_amount,
    ZipploDW.total_amount - ZipploDB.total_amount AS amount_difference,

    ZipploDB.total_km AS ZipploDB_total_km,
    ZipploDW.total_km AS ZipploDW_total_km,
    ZipploDW.total_km - ZipploDB.total_km AS km_difference
FROM ZipploDB
CROSS JOIN ZipploDW;




/*
2. Monthly Totals Comparison

Description:
Compares rental transaction counts, total rental amount, and total kilometers by year and month between ZipploDB and ZipploDW.

Purpose:
This validation checks that rental transactions have been assigned to the correct dates in the data warehouse, especially through the dim_date dimension.
*/

WITH ZipploDB AS (
    SELECT
        YEAR(start_time) AS year,
        MONTH(start_time) AS month,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_amount,
        SUM(KM) AS total_km
    FROM ZipploDB.dbo.RentalTransaction
    GROUP BY
        YEAR(start_time),
        MONTH(start_time)
),
ZipploDW AS (
    SELECT
        dim_date.year,
        dim_date.month,
        COUNT(*) AS transaction_count,
        SUM(fact_rental.amount) AS total_amount,
        SUM(fact_rental.km) AS total_km
    FROM ZipploDW.dbo.fact_rental
    JOIN ZipploDW.dbo.dim_date
        ON fact_rental.start_date_id = dim_date.date_id
    GROUP BY
        dim_date.year,
        dim_date.month
)
SELECT
    COALESCE(ZipploDB.year, ZipploDW.year) AS year,
    COALESCE(ZipploDB.month, ZipploDW.month) AS month,

    ZipploDB.transaction_count AS ZipploDB_transaction_count,
    ZipploDW.transaction_count AS ZipploDW_transaction_count,
    ISNULL(ZipploDW.transaction_count, 0) - ISNULL(ZipploDB.transaction_count, 0) AS transaction_count_difference,

    ZipploDB.total_amount AS ZipploDB_total_amount,
    ZipploDW.total_amount AS ZipploDW_total_amount,
    ISNULL(ZipploDW.total_amount, 0) - ISNULL(ZipploDB.total_amount, 0) AS amount_difference,

    ZipploDB.total_km AS ZipploDB_total_km,
    ZipploDW.total_km AS ZipploDW_total_km,
    ISNULL(ZipploDW.total_km, 0) - ISNULL(ZipploDB.total_km, 0) AS km_difference
FROM ZipploDB
FULL OUTER JOIN ZipploDW
    ON ZipploDB.year = ZipploDW.year
    AND ZipploDB.month = ZipploDW.month
ORDER BY
    year,
    month;


/*
3. Customer Totals Comparison

Description:
Compares total rental amount and transaction count per customer between ZipploDB and ZipploDW.

Purpose:
Validates that all customers have been correctly loaded into dim_customer and that
customer-level totals match between source and warehouse.
*/

WITH ZipploDB AS (
    SELECT
        c.customer_id,
        c.name AS customer_name,
        COUNT(*) AS transaction_count,
        SUM(rt.amount) AS total_amount
    FROM ZipploDB.dbo.RentalTransaction rt
    JOIN ZipploDB.dbo.Customer c
        ON rt.customer_id = c.customer_id
    GROUP BY
        c.customer_id,
        c.name
),
ZipploDW AS (
    SELECT
        dc.customer_alt_key,
        dc.customer_name,
        COUNT(*) AS transaction_count,
        SUM(fr.amount) AS total_amount
    FROM ZipploDW.dbo.fact_rental fr
    JOIN ZipploDW.dbo.dim_customer dc
        ON fr.customer_id = dc.customer_id
    GROUP BY
        dc.customer_alt_key,
        dc.customer_name
)
SELECT
    COALESCE(ZipploDB.customer_name, ZipploDW.customer_name) AS customer_name,

    ISNULL(ZipploDB.transaction_count, 0) AS ZipploDB_transaction_count,
    ISNULL(ZipploDW.transaction_count, 0) AS ZipploDW_transaction_count,
    ISNULL(ZipploDW.transaction_count, 0) - ISNULL(ZipploDB.transaction_count, 0) AS transaction_count_difference,

    ISNULL(ZipploDB.total_amount, 0) AS ZipploDB_total_amount,
    ISNULL(ZipploDW.total_amount, 0) AS ZipploDW_total_amount,
    ISNULL(ZipploDW.total_amount, 0) - ISNULL(ZipploDB.total_amount, 0) AS amount_difference
FROM ZipploDB
FULL OUTER JOIN ZipploDW
    ON ZipploDB.customer_id = ZipploDW.customer_alt_key
ORDER BY
    customer_name;


/*
4. Location Totals Comparison

Description:
Compares transaction count and total rental amount per pickup location between ZipploDB and ZipploDW.

Purpose:
Validates that pickup locations have been correctly mapped through dim_location
and that location-level totals match between source and warehouse.
*/

WITH ZipploDB AS (
    SELECT
        rp.place_id,
        rp.name AS location_name,
        rp.type AS location_type,
        COUNT(*) AS transaction_count,
        SUM(rt.amount) AS total_amount
    FROM ZipploDB.dbo.RentalTransaction rt
    JOIN ZipploDB.dbo.RentalPlace rp
        ON rt.pickup_location_id = rp.place_id
    GROUP BY
        rp.place_id,
        rp.name,
        rp.type
),
ZipploDW AS (
    SELECT
        dl.place_alt_key,
        dl.location_name,
        dl.location_type,
        COUNT(*) AS transaction_count,
        SUM(fr.amount) AS total_amount
    FROM ZipploDW.dbo.fact_rental fr
    JOIN ZipploDW.dbo.dim_location dl
        ON fr.pick_up_location = dl.location_id
    GROUP BY
        dl.place_alt_key,
        dl.location_name,
        dl.location_type
)
SELECT
    COALESCE(ZipploDB.location_name, ZipploDW.location_name) AS location_name,
    COALESCE(ZipploDB.location_type, ZipploDW.location_type) AS location_type,

    ISNULL(ZipploDB.transaction_count, 0) AS ZipploDB_transaction_count,
    ISNULL(ZipploDW.transaction_count, 0) AS ZipploDW_transaction_count,
    ISNULL(ZipploDW.transaction_count, 0) - ISNULL(ZipploDB.transaction_count, 0) AS transaction_count_difference,

    ISNULL(ZipploDB.total_amount, 0) AS ZipploDB_total_amount,
    ISNULL(ZipploDW.total_amount, 0) AS ZipploDW_total_amount,
    ISNULL(ZipploDW.total_amount, 0) - ISNULL(ZipploDB.total_amount, 0) AS amount_difference
FROM ZipploDB
FULL OUTER JOIN ZipploDW
    ON ZipploDB.place_id = ZipploDW.place_alt_key
ORDER BY
    location_name;

END TRY 
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    PRINT 'error in validation process: ' + @ErrorMessage;
END CATCH
END
GO

PRINT '### Starting Full Pipeline Execution ###';

EXEC create_databases;   -- 1. Datenbanken & Tabellen
PRINT 'Done: Databases created.';
GO

EXEC ingest_csv_data;    -- 2. Staging & Source Data
PRINT 'Done: CSV Data ingested.';
GO

EXEC etl_procedure;      -- 3. DW Loading (Dims & Facts)
PRINT 'Done: ETL Process finished.';
GO

EXEC dw_validation;      -- 4. Testing & Quality Check
PRINT 'Done: Data validation complete.';
GO

PRINT '### Full Pipeline Finished Successfully ###';