-- Please update version.sql too -- this keeps clean builds in sync
define version=530
@update_header

UPDATE std_measure_conversion
   SET description = 'kg/therm (UK)'
 WHERE description = 'kg/therm';

UPDATE std_measure_conversion
   SET description = 'million BTU (UK)'
 WHERE description = 'million BTU';
 
UPDATE std_measure_conversion
   SET description = 'BTU (UK)'
 WHERE description = 'BTU';

INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (41, 4, 'therm (US)', 9.48043428e-9, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (42, 4, 'therm (EC)', 9.47813394e-9, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (43, 9, 'kg/therm (US)', 105480400, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (44, 9, 'kg/therm (EC)', 105506000, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (45, 4, 'million BTU (US)', 9.48043428e-10, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (46, 4, 'million BTU (EC)', 9.47813394e-10, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (47, 4, 'BTU (US)', 9.48043428e-4, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (48, 4, 'BTU (EC)', 9.47813394e-4, 1, 0);

@update_tail
