-- Please update version.sql too -- this keeps clean builds in sync
define version=762
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (81, 3, 'Nautical mile', 0.000539956803, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (82, 12, 'l/Nautical mile', 1852000, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (83, 12, 'Gallon (US)/Nautical mile', 489246.641, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (84, 12, 'Gallon (UK)/Nautical mile', 407382.879, 1, 0);

@update_tail
