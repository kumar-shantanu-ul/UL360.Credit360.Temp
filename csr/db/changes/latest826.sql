-- Please update version.sql too -- this keeps clean builds in sync
define version=826
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (104, 26, 'kWh/l', 2.77777778e-10, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (105, 18, 'kWh/m^2', 2.77777778e-7, 1, 0);

@update_tail