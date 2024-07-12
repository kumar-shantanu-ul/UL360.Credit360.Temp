-- Please update version.sql too -- this keeps clean builds in sync
define version=613
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, A, B, C)
	VALUES (61, 5, 'Mcf', 0.0353146667, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, A, B, C)
	VALUES (62, 5, 'Mmcf', 0.0000353146667, 1, 0);

@update_tail
