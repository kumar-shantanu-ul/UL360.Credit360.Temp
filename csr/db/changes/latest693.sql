-- Please update version.sql too -- this keeps clean builds in sync
define version=693
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (77, 2, 'oz (avoirdupois)', 35.2739619, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (78, 2, 'oz (troy)', 32.1507466, 1, 0);

@update_tail
