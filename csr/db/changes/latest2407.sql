-- Please update version.sql too -- this keeps clean builds in sync
define version=2407
@update_header

INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28137, 9, 'TJ/Kg', 0.000000000001, 1, 0, 0);

@update_tail
