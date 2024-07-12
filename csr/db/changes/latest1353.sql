-- Please update version.sql too -- this keeps clean builds in sync
define version=1353
@update_header 

BEGIN
	-- mg/m^3
	Insert into CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C) values (26161,8,'mg/m^3',1000000,1,0);
END;
/

@update_tail
