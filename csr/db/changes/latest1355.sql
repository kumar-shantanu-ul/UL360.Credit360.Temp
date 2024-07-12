-- Please update version.sql too -- this keeps clean builds in sync
define version=1355
@update_header 

BEGIN
	-- MWh/m^2
	Insert into CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C) values (26162,18,'MWh/m^2',.000000000277777778,1,0);
END;
/

@update_tail
