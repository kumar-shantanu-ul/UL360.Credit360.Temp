-- Please update version.sql too -- this keeps clean builds in sync
define version=529
@update_header

UPDATE std_measure_conversion
   SET description = 'ton'
 WHERE description = 't';

INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (39, 2, 'long ton', 0.000984206526, 1, 0);
INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (40, 2, 'short ton', 0.00110231131, 1, 0);

@update_tail
