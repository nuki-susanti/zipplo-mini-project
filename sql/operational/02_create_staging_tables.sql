------------------------------------------------------
-- SETUP SCRIPT FOR STAGING TABLES
------------------------------------------------------

DROP TABLE IF EXISTS stg_Employee;
DROP TABLE IF EXISTS stg_Customer;
DROP TABLE IF EXISTS stg_Equipment;
DROP TABLE IF EXISTS stg_RentalPlace;
DROP TABLE IF EXISTS stg_EquipmentUnit;
DROP TABLE IF EXISTS stg_EquipmentUnit;
DROP TABLE IF EXISTS stg_RentalTransaction;


CREATE TABLE stg_Employee (
    employee_id INT,
    name NVARCHAR(100),
    position VARCHAR(50)
);

CREATE TABLE stg_Customer (
    customer_id INT,
    name NVARCHAR(100),
    type VARCHAR(20),
    company NVARCHAR(100),
    business_id VARCHAR(50)
);

CREATE TABLE stg_Equipment (
    equipment_id INT,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    model VARCHAR(50),
    price_per_minute DECIMAL(10,2)
);

CREATE TABLE stg_RentalPlace (
    place_id INT,
    type VARCHAR(50),
    name NVARCHAR(100),
    address NVARCHAR(300),
    city NVARCHAR(100),
    country VARCHAR(50),
    employee_id INT
);

CREATE TABLE stg_EquipmentUnit (
    equipment_unit_id INT,
    equipment_id INT,
    serial_number VARCHAR(50),
    purchase_date DATE,
    last_maintenance DATE,
    condition VARCHAR(50)
);

CREATE TABLE stg_RentalTransaction (
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