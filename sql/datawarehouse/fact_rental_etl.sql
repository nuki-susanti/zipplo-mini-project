USE ZipploDW;
GO

INSERT INTO fact_rental (
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
    dl_pick.location_id,  -- Surrogat Key from dim_location (Abholung)
    dl_ret.location_id,   -- Surrogat Key from dim_location (Rückgabe)
    
    -- duration calculation
    CAST(rt.end_time - rt.start_time AS DATETIME2(7)) AS duration,
    1 AS [count],
    rt.km,
    CAST(rt.start_time AS TIME) AS start_time,
    CAST(rt.end_time AS TIME) AS end_time
FROM ZipploDB.dbo.RentalTransaction AS rt
-- Joining of Dimensionen on their Alt-Keys (Original-IDs from ZipploDB)
LEFT JOIN dim_customer dc 
    ON rt.customer_id = dc.customer_alt_key
LEFT JOIN dim_equipment de 
    ON rt.equipment_unit_id = de.equipment_unit_alt_key
LEFT JOIN dim_location dl_pick 
    ON rt.pickup_location_id = dl_pick.place_alt_key
LEFT JOIN dim_location dl_ret 
    ON rt.return_location_id = dl_ret.place_alt_key
-- Filter: only insert rows which are not already in the fact table
WHERE NOT EXISTS (
    SELECT 1 FROM fact_rental fr 
    WHERE fr.transaction_id = rt.transaction_id
);
GO