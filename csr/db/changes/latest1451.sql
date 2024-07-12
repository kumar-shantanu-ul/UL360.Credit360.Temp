-- Please update version.sql too -- this keeps clean builds in sync
define version=1451
@update_header

DECLARE
	e_measure_missing	EXCEPTION;
BEGIN
	BEGIN
		UPDATE csr.std_measure_conversion
		SET a = 3.6,
		std_measure_id = 1
		WHERE std_measure_conversion_id = 26165;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE e_measure_missing;
		END IF;
	EXCEPTION
		WHEN e_measure_missing THEN
			BEGIN
					-- Maybe it doesn't exist? SHOULD DO!
					INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
					VALUES (26165, 9, 'MJ/kWh', 3.6, 1, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
	END;
END;
/

@update_tail
