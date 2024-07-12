-- Please update version.sql too -- this keeps clean builds in sync
define version=1507
@update_header

BEGIN
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (26183, 1, 'tonne/kg', 0.001, 1, 0);
EXCEPTION
	WHEN
		DUP_VAL_ON_INDEX THEN
			NULL;
END;
/
			
@update_tail
