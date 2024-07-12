-- Please update version.sql too -- this keeps clean builds in sync
define version=1509
@update_header
			
BEGIN
	--tCO2e/km
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26184, 10, 'tCO2e/km', 1, 1, 0); --std_measure_id refers to kg/m
EXCEPTION
	WHEN
		DUP_VAL_ON_INDEX THEN
			NULL;
END;
/
			
BEGIN
	--tCO2e/m3
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26185, 8, 'tCO2e/m3', 0.001, 1, 0);--std_measure_id refers to kg/m^3
EXCEPTION
	WHEN
		DUP_VAL_ON_INDEX THEN
			NULL;
END;
/
			
BEGIN
	--tCO2e/vkm
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26186, 10, 'tCO2e/vkm', 1, 1, 0); --std_measure_id refers to kg/m
EXCEPTION
	WHEN
		DUP_VAL_ON_INDEX THEN
			NULL;
END;
/

@update_tail