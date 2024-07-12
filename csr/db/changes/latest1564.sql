-- Please update version.sql too -- this keeps clean builds in sync
define version=1564
@update_header

BEGIN
	INSERT INTO csr.std_measure_conversion (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C)
	VALUES (26187, 8, 'kg/hl', 0.1, 1, 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail