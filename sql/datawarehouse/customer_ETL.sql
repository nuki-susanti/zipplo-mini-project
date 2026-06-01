DELETE FROM dim_customer;

INSERT INTO dim_customer ( 
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
FROM Customer AS c;

-- alt
WHERE NOT EXISTS (
	SELECT 1 
	FROM dim_customer AS dc 
	WHERE dc.customer_alt_key = c.customer_id 
);