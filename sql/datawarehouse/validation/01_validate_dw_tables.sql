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