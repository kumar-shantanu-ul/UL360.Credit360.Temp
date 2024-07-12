-- Please update version.sql too -- this keeps clean builds in sync
define version=1813
@update_header

INSERT INTO CSR.STD_MEASURE_CONVERSION(STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (26203,32,'MWh/km',0.000000277778,1,0,0);
 
@update_tail