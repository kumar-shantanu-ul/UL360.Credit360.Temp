-- Please update version.sql too -- this keeps clean builds in sync
define version=1449
@update_header

DECLARE
	e_measure_missing	EXCEPTION;
	e_in_use			EXCEPTION;
BEGIN
	BEGIN
		UPDATE csr.std_measure_conversion
		SET a = 907184.74,
		std_measure_id = 1,
		description = 'g/short ton'
		WHERE std_measure_conversion_id = 26175;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE e_measure_missing;
		END IF;
		
		BEGIN
			-- Delete a dupe measure.
			-- If this fails, you've probably used it in a measure.
			DELETE FROM csr.std_measure_conversion
			 WHERE std_measure_conversion_id = 26172;
		EXCEPTION
			WHEN OTHERS THEN
				RAISE e_in_use;
		END;
	EXCEPTION
		WHEN e_in_use THEN
			raise_application_error(-20001, sqlerrm||' Couldn''t delete the UOM with ID: 26172. You might''ve used it in a measure?');
		WHEN e_measure_missing THEN
			BEGIN
					-- Maybe it doesn't exist? SHOULD DO!
					INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
					VALUES(26165, 9, 'g/short ton', 907184.74, 1, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
	END;
END;
/

@update_tail
