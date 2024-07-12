-- Please update version.sql too -- this keeps clean builds in sync
define version=1445
@update_header

BEGIN
	-- Missing on staging
	BEGIN
		INSERT INTO CSR.STD_MEASURE (STD_MEASURE_ID, NAME, DESCRIPTION, SCALE, FORMAT_MASK, REGIONAL_AGGREGATION, CUSTOM_FIELD, PCT_OWNERSHIP_APPLIES, M, KG, S, A, K, MOL, CD) VALUES (31,'kg^-1','kg^-1',0,'#,##0','sum',NULL,0,0,-1,0,0,0,0,0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26170, 9, 'g/kWh', 3600, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;			
	END;
	
	BEGIN
		INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26171, 8, 'g/l', 0.000001, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;			
	END;
	
	BEGIN
		INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
		VALUES (26172, 31, 'g/tonne', 0.000001, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;			
	END;
END;
/

@update_tail
