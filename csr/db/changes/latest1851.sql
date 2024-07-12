-- Please update version.sql too -- this keeps clean builds in sync
define version=1851
@update_header

INSERT INTO CSR.STD_MEASURE_CONVERSION(STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (26204,3,'l/m^2',1000,1,0,0);

@update_tail
