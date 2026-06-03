-- VALIDATION QUERIES

PRINT '--- 1. Row Count Check (Source vs. Target) ---';
SELECT 
    'Customer' AS Entity, 
    (SELECT COUNT(*) FROM ZipploDB.dbo.Customer) AS Source_Count,
    (SELECT COUNT(*) FROM ZipploDW.dbo.dim_customer) AS DW_Count
UNION ALL
SELECT 
    'Transactions', 
    (SELECT COUNT(*) FROM ZipploDB.dbo.RentalTransaction),
    (SELECT COUNT(*) FROM ZipploDW.dbo.fact_rental)
UNION ALL
SELECT 
    'Location', 
    (SELECT COUNT(*) FROM ZipploDB.dbo.RentalPlace),
    (SELECT COUNT(*) FROM ZipploDW.dbo.dim_location)
UNION ALL
SELECT 
    'Equipment', 
    (SELECT COUNT(*) 
        FROM ZipploDB.dbo.EquipmentUnit AS eu
                JOIN ZipploDB.dbo.Equipment AS e
	            ON eu.equipment_id = e.equipment_id),
    (SELECT COUNT(*) FROM ZipploDW.dbo.dim_equipment);


PRINT '--- 2. Customer Totals Discrepancy Check ---';
WITH ZipploDB AS (
    SELECT 
        c.customer_id, 
        COUNT(*) AS transaction_count, 
        SUM(rt.amount) AS total_amount
    FROM ZipploDB.dbo.RentalTransaction rt
    JOIN ZipploDB.dbo.Customer c ON rt.customer_id = c.customer_id
    GROUP BY c.customer_id
),
ZipploDW AS (
    SELECT 
        dc.customer_alt_key, 
        COUNT(*) AS transaction_count, 
        SUM(fr.amount) AS total_amount
    FROM ZipploDW.dbo.fact_rental fr
    JOIN ZipploDW.dbo.dim_customer dc ON fr.customer_id = dc.customer_id
    GROUP BY dc.customer_alt_key
)
SELECT 
    COALESCE(db.customer_id, dw.customer_alt_key) AS customer_id,
    ISNULL(db.transaction_count, 0) AS Source_Tx_Count,
    ISNULL(dw.transaction_count, 0) AS DW_Tx_Count,
    ISNULL(db.total_amount, 0) AS Source_Amount,
    ISNULL(dw.total_amount, 0) AS DW_Amount
FROM ZipploDB db
FULL OUTER JOIN ZipploDW dw ON db.customer_id = dw.customer_alt_key
-- Filter for rows with errors
WHERE ISNULL(db.transaction_count, 0) <> ISNULL(dw.transaction_count, 0)
   OR ISNULL(db.total_amount, 0) <> ISNULL(dw.total_amount, 0);


PRINT '--- 3. Missing Dimensions (Orphan Check) ---';
SELECT 
	transaction_id, 
	start_date_id, 
	end_date_id
FROM ZipploDW.dbo.fact_rental
WHERE start_date_id NOT IN (SELECT date_id FROM ZipploDW.dbo.dim_date)
   OR end_date_id NOT IN (SELECT date_id FROM ZipploDW.dbo.dim_date);