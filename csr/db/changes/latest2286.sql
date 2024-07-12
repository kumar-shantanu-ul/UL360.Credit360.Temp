-- Please update version.sql too -- this keeps clean builds in sync
define version=2286
@update_header

  INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28130, 5, 'mililitre', 1000000, 1, 0, 1);

@update_tail