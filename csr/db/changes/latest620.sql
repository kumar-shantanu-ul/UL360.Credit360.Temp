-- Please update version.sql too -- this keeps clean builds in sync
define version=620
@update_header

INSERT INTO csr.std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
	VALUES (17, 'J/kg', 'J/kg', 2, 0, -2, 0, 0, 0, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (65, 17, 'kWh/lb', 1.25997881e-7, 1, 0);

@update_tail
