-- Please update version.sql too -- this keeps clean builds in sync
define version=1446
@update_header

BEGIN
	BEGIN
		INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26173, 26, 'TJ/m^3', 0.000001, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c) 
		VALUES (26174, 2, 'Mt', 1000, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;			
	END;
	
	BEGIN
		INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c) 
		VALUES(26175, 31, 'g/ton', 0.000001102, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;			
	END;
	
	BEGIN
		INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c) 
		VALUES (26176, 17, 'mWh/ton', 3968000, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;			
	END;
END;
/

@update_tail
