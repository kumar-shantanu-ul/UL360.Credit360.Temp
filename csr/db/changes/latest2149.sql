-- Please update version.sql too -- this keeps clean builds in sync
define version=2149
@update_header

INSERT INTO CSR.STD_MEASURE_CONVERSION(STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28125, 32, 'kWh/km', 0.00027777777778, 1, 0, 1);

@update_tail