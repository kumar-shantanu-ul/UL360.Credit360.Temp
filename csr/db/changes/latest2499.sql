-- Please update version.sql too -- this keeps clean builds in sync
define version=2499
@update_header

INSERT INTO CSR.STD_MEASURE_CONVERSION 
	(STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE)
VALUES
	(28148, 16, 'km/hl', 0.0001, 1, 0, 0);

@update_tail
