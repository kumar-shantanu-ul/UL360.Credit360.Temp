-- Please update version.sql too -- this keeps clean builds in sync
define version=714
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (79, 16, 'km/l', 0.000001, 1, 0);

@update_tail
