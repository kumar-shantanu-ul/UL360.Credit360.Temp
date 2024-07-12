-- Please update version.sql too -- this keeps clean builds in sync
define version=850
@update_header

-- fix bug
UPDATE csr.std_measure_conversion
   SET a = 1e-6
 WHERE std_measure_conversion_id = 75;

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (114, 18, 'kJ/m^3', 0.001, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (115, 18, 'kJ/t', 1, 1, 0);

INSERT INTO csr.std_measure (std_measure_id, name, description, m, kg, s, a, k, mol, cd)
	VALUES (28, 'm.kg^-1.s^2', 'm.kg^-1.s^2', 1, -1, 2, 0, 0, 0, 0);

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (116, 28, 'Gallon (US)/BTU', 278649.737, 1, 0);

@update_tail
