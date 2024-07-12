-- Please update version.sql too -- this keeps clean builds in sync
define version=1471
@update_header

BEGIN
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C) VALUES (26178,9,'kg/MJ',1000000,1,0);
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

@update_tail
