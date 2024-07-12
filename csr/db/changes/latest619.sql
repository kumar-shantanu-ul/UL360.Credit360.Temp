-- Please update version.sql too -- this keeps clean builds in sync
define version=619
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (63, 1, 'metric ton/lb', 0.00045359237, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (64, 9, 'lb/kWh', 7936641.432, 1, 0);

@update_tail
