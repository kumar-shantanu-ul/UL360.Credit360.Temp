-- Please update version.sql too -- this keeps clean builds in sync
define version=848
@update_header

--17 and 25 are duplicates
UPDATE csr.std_measure_conversion
   SET std_measure_id = 17
 WHERE std_measure_id = 25;

--add new std_measure
UPDATE csr.std_measure
   SET description = 'm^2.s^-1', m = 2, s = -1
 WHERE std_measure_id = 25;

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (109, 21, 'hour^-1', 3600, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (110, 25, 'mmBTU/ton.hour', 0.00341295634, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (111, 17, 'mmBTU/short ton', 8.60050531e-7, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (112, 8, 'lb/gallon (US)', 0.00834540446, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (113, 10, 'lb/mile', 3547.99619, 1, 0);

@update_tail
