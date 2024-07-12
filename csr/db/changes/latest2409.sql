-- Please update version.sql too -- this keeps clean builds in sync
define version=2409
@update_header

INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28138, 9, 't/MWh', 3600000, 1,0,0);

@update_tail
