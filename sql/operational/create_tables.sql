------------------------------------------------------
-- CREATE TABLE
------------------------------------------------------

DROP TABLE IF EXISTS Employee;
CREATE TABLE Employee (
    employee_id INT NOT NULL IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL

    CONSTRAINT pk_employee PRIMARY KEY (employee_id)
)

DROP TABLE IF EXISTS RentalPlace;
CREATE TABLE RentalPlace (
    place_id INT IDENTITY(1,1),
    type VARCHAR(50) NOT NULL,
    name NVARCHAR(100) NOT NULL,
    address NVARCHAR(300) NOT NULL,
    city NVARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    employee_id INT NULL
    
    CONSTRAINT pk_rentalplace PRIMARY KEY (place_id),
    CONSTRAINT chk_rentalplace CHECK(type IN ('store', 'station')),
    CONSTRAINT fk_rentalplace_employee FOREIGN KEY(employee_id) REFERENCES Employee(employee_id)
);

DROP TABLE IF EXISTS Customer;
CREATE TABLE Customer (
    customer_id INT NOT NULL IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    type   VARCHAR(20) NOT NULL DEFAULT 'private',
    company NVARCHAR(100) NULL,
    business_id VARCHAR(50) NULL
           
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT chk_type CHECK(type IN ('private', 'corporate'))
);


DROP TABLE IF EXISTS Equipment;
CREATE TABLE Equipment (
    equipment_id INT NOT NULL IDENTITY(1,1),
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    price_per_min DECIMAL(10,2) NOT NULL --what currency?

    CONSTRAINT pk_equipment PRIMARY KEY (equipment_id)
);

DROP TABLE IF EXISTS EquipmentUnit;
CREATE TABLE EquipmentUnit (
    equipment_unit_id INT NOT NULL IDENTITY(1,1),
    equipment_id INT NOT NULL,
    serial_number VARCHAR(50) NOT NULL,
    purchase_date DATE NOT NULL,
    last_maintenance DATE NULL,
    condition VARCHAR(50) NOT NULL DEFAULT 'good',
    current_place_id INT NULL

    CONSTRAINT pk_equipment_unit PRIMARY KEY (equipment_unit_id),
    CONSTRAINT uq_equipment_unit_serial_number UNIQUE(serial_number),
    CONSTRAINT chk_equipment_unit_condition CHECK(condition IN ('good', 'fair', 'poor')),
    CONSTRAINT fk_equipment_unit_equipment FOREIGN KEY (equipment_id) REFERENCES Equipment(equipment_id),
    CONSTRAINT fk_equipment_unit_rental_place FOREIGN KEY (current_place_id) REFERENCES RentalPlace(place_id)
);

DROP TABLE IF EXISTS RentalTransaction;
CREATE TABLE RentalTransaction (
    transaction_id INT NOT NULL IDENTITY(1,1),
    equipment_unit_id INT NOT NULL,
    customer_id INT NOT NULL,
    pickup_location_id INT NOT NULL,
    return_location_id INT NOT NULL,
    start_time DATETIME2(7) NOT NULL,
    end_time DATETIME2(7) NULL,
    amount DECIMAL(10,2) NULL,
    km DECIMAL(10,2) NULL

    CONSTRAINT pk_rental_transaction PRIMARY KEY (transaction_id),
    CONSTRAINT fk_rental_transaction_unit FOREIGN KEY (equipment_unit_id) REFERENCES EquipmentUnit(equipment_unit_id),
    CONSTRAINT fk_rental_transaction_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT fk_rental_transaction_pickup FOREIGN KEY (pickup_location_id) REFERENCES RentalPlace(place_id),
    CONSTRAINT fk_rental_transaction_return FOREIGN KEY (return_location_id) REFERENCES RentalPlace(place_id),
);
