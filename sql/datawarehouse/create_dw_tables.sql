-- ===================================================================
-- 1. Dimension tables (Dim)
-- ===================================================================

CREATE TABLE DimDate (
    Date_ID INT PRIMARY KEY,
    [Date]  datetime2(7),
    [Day] INT,
    [Month] INT,
    [Quarter] INT,
    [Year] INT
);

CREATE TABLE DimEquipment (
    EquipmentUnit_ID INT PRIMARY KEY,
    Category VARCHAR(50),
    Subcategory VARCHAR(50),
    Model VARCHAR(50),
    SerialNumber VARCHAR(50),
    PricePerMinute DECIMAL(10, 2),
    PurchaseDate DATE,
    LastMaintenance DATE,
    Condition VARCHAR(50),
    EquipmentUnitAltKey int,
    EquipmentAltKey int
);

CREATE TABLE DimLocation (
    Location_ID INT PRIMARY KEY,
    LocationType VARCHAR(50),
    LocationName NVARCHAR(100),
    Address NVARCHAR(100),
    City NVARCHAR(100),
    Country VARCHAR(50),
    PlaceAltKey int
);

CREATE TABLE DimCustomer (
    Customer_ID INT PRIMARY KEY,
    CustomerName NVARCHAR(100),
    [Type] NVARCHAR(100), 
    Company NVARCHAR(100)
);

-- ===================================================================
-- 2. Fact Tables with Foreign Keys
-- ===================================================================

CREATE TABLE FactRental (
    Rental_ID INT PRIMARY KEY,
    Amount DECIMAL(10, 2),
    StartTime int, 
    EndTime int, 
    Customer_ID INT, 
    EquipmentUnit_ID INT, 
    PickUpLocation INT, 
    ReturnLocation INT, 
    Duration datetime2(7),
    [Count] int default 1

    -- Definition of constraints
    CONSTRAINT FK_FactRental_StartTime FOREIGN KEY (StartTime) REFERENCES DimDate(Date_ID),
    CONSTRAINT FK_FactRental_EndTime FOREIGN KEY (EndTime) REFERENCES DimDate(Date_ID),
    CONSTRAINT FK_FactRental_Customer FOREIGN KEY (Customer_ID) REFERENCES DimCustomer(Customer_ID),
    CONSTRAINT FK_FactRental_Equipment FOREIGN KEY (EquipmentUnit_ID) REFERENCES DimEquipment(EquipmentUnit_ID),
    CONSTRAINT FK_FactRental_PickUpLocation FOREIGN KEY (PickUpLocation) REFERENCES DimLocation(Location_ID),
    CONSTRAINT FK_FactRental_ReturnLocation FOREIGN KEY (ReturnLocation) REFERENCES DimLocation(Location_ID)
);