-- Please update version.sql too -- this keeps clean builds in sync
define version=847
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (107, 26, 'MJ/m^3', 0.000001, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (108, 1, 'kWh/MJ', 0.27777777778, 1, 0);

@update_tail
