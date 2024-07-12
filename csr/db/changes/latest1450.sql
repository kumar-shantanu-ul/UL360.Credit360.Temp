-- Please update version.sql too -- this keeps clean builds in sync
define version=1450
@update_header

DECLARE
	e_measure_missing	EXCEPTION;
BEGIN
	BEGIN
		UPDATE csr.std_measure_conversion
		SET a = 3600000000,
		std_measure_id = 9
		WHERE std_measure_conversion_id = 26170;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE e_measure_missing;
		END IF;
	EXCEPTION
		WHEN e_measure_missing THEN
			BEGIN
					-- Maybe it doesn't exist? SHOULD DO!
					INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c) VALUES (26170, 9, 'g/kWh', 3600000000, 1, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
	END;
END;
/

@update_tail
