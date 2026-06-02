INSERT INTO ZipploDW.dbo.dim_location (
    location_id,
    location_type,
    location_name,
    address,
    city,
    country,
    place_alt_key
)
SELECT
    rp.place_id,
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