-- Please update version.sql too -- this keeps clean builds in sync
define version=2059
@update_header

BEGIN
	INSERT INTO CSR.STD_MEASURE_CONVERSION(STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28117, 5, 'Mm^3', 0.000001, 1, 0, 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

@update_tail
