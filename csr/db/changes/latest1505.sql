-- Please update version.sql too -- this keeps clean builds in sync
define version=1505
@update_header

BEGIN
	INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES(26180, 3, '1/km', 1000, 1, 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		null;
END;
/

BEGIN
	INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES(26181, 6, '1/tkm', 1016000, 1, 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		null;
END;
/

BEGIN
	INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES(26182, 3, '1/vkm', 1000, 1, 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		null;
END;
/
 
@update_tail
