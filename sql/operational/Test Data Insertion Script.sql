------------------------------------------------------
-- SCRIPT FOR DATA INSERTION FROM CSV TO OPERATIONAL DATABASE USING STAGING TABLES
-- STAGING TABLES NEED TO BE CREATED FIRST
------------------------------------------------------

USE ZipploDB;

-- EMPLOYEE
TRUNCATE TABLE stg_Employee;

BULK INSERT stg_Employee
FROM 'C:\backup\ZIPPLO TEST DATA\Employee.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT Employee ON;
INSERT INTO Employee (
    employee_id, 
    name, 
    position)
SELECT 
    employee_id, 
    name, 
    position
FROM stg_Employee;
SET IDENTITY_INSERT Employee OFF;


-- CUSTOMER
TRUNCATE TABLE stg_Customer;

BULK INSERT stg_Customer
FROM 'C:\backup\ZIPPLO TEST DATA\Customer.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT Customer ON;
INSERT INTO Customer (
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
FROM stg_Customer;
SET IDENTITY_INSERT Customer OFF;


-- EQUIPMENT
TRUNCATE TABLE stg_Equipment;

BULK INSERT stg_Equipment
FROM 'C:\backup\ZIPPLO TEST DATA\Equipment.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT Equipment ON;

INSERT INTO Equipment (
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
FROM stg_Equipment;
SET IDENTITY_INSERT Equipment OFF;

-- RENTALPLACE
TRUNCATE TABLE stg_RentalPlace;

BULK INSERT stg_RentalPlace
FROM 'C:\backup\ZIPPLO TEST DATA\Rental_Place.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT RentalPlace ON;
INSERT INTO RentalPlace (
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
FROM stg_RentalPlace;
SET IDENTITY_INSERT RentalPlace OFF;

-- EQUIPMENTUNIT
TRUNCATE TABLE stg_EquipmentUnit;

BULK INSERT stg_EquipmentUnit
FROM 'C:\backup\ZIPPLO TEST DATA\Equipment_Unit.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT EquipmentUnit ON;
INSERT INTO EquipmentUnit (
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
FROM stg_EquipmentUnit;
SET IDENTITY_INSERT EquipmentUnit OFF;

-- RENTALTRANSACTION
TRUNCATE TABLE stg_RentalTransaction;

BULK INSERT stg_RentalTransaction
FROM 'C:\backup\ZIPPLO TEST DATA\Rental_Transaction.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');

SET IDENTITY_INSERT RentalTransaction ON;

INSERT INTO RentalTransaction (
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
FROM stg_RentalTransaction;
SET IDENTITY_INSERT RentalTransaction OFF;