-- Please update version.sql too -- this keeps clean builds in sync
define version=1447
@update_header

BEGIN
	BEGIN
			INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
			VALUES(26165, 9, 'MJ/kWh', 0.278, 1, 0);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

@update_tail
