-- Please update version.sql too -- this keeps clean builds in sync
define version=681
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (75, 17, 'GJ/t', 1e-9, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (76, 10, 'g/km', 1000, 1, 0);

@update_tail


