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