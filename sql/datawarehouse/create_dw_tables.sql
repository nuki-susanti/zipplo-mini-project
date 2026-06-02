-- ===================================================================
-- 1. Dimensions table
-- ===================================================================
-- ===================================================================
IF DB_ID('ZipploDW') IS NULL
     CREATE DATABASE ZipploDW;
GO

USE ZipploDW
GO

DROP TABLE IF EXISTS fact_rental;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_location;
DROP TABLE IF EXISTS dim_equipment;
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    [date] DATE,
    [day] INT,
    [month] INT,
    [quarter] INT,
    [year] INT
);

CREATE TABLE dim_equipment (
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

CREATE TABLE dim_location (
    location_id INT IDENTITY(1, 1) PRIMARY KEY,
    location_type VARCHAR(50),
    location_name NVARCHAR(100),
    address NVARCHAR(100),
    city NVARCHAR(100),
    country VARCHAR(50),
    place_alt_key INT
);

CREATE TABLE dim_customer (
    customer_id INT IDENTITY(1, 1) PRIMARY KEY,
    customer_name NVARCHAR(100),
    [type] NVARCHAR(100), 
    company NVARCHAR(100),
    customer_alt_key INT
);

-- ===================================================================
-- 2. Fact table
-- ===================================================================
CREATE TABLE fact_rental (
    transaction_id INT PRIMARY KEY,
    amount DECIMAL(10, 2),
    start_date_id INT, 
    end_date_id INT, 
    customer_id INT, 
    equipment_unit_id INT, 
    pick_up_location INT, 
    return_location INT, 
    duration DATETIME2(7),
    [count] INT DEFAULT 1,
    km DECIMAL(10, 3),
    start_time time,
    end_time time,

    -- Definition of Constraints
    CONSTRAINT fk_fact_rental_start_date FOREIGN KEY (start_date_id) 
        REFERENCES dim_date(date_id),
    CONSTRAINT fk_fact_rental_end_date FOREIGN KEY (end_date_id) 
        REFERENCES dim_date(date_id),
    CONSTRAINT fk_fact_rental_customer FOREIGN KEY (customer_id) 
        REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_fact_rental_equipment FOREIGN KEY (equipment_unit_id) 
        REFERENCES dim_equipment(equipment_unit_id),
    CONSTRAINT fk_fact_rental_pick_up_location FOREIGN KEY (pick_up_location) 
        REFERENCES dim_location(location_id),
    CONSTRAINT fk_fact_rental_return_location FOREIGN KEY (return_location) 
        REFERENCES dim_location(location_id)
);
