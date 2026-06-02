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