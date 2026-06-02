USE ZipploDW;
GO

INSERT INTO dbo.dim_equipment (
	equipment_unit_id,
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
	eu.equipment_unit_id AS equipment_unit_id,
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
	ON eu.equipment_id = e.equipment_id;
GO