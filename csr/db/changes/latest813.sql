-- Please update version.sql too -- this keeps clean builds in sync
define version=813
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (103, 13, '1/mile', 1609.344, 1, 0);

@update_tail