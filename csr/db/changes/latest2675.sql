--Please update version.sql too -- this keeps clean builds in sync
define version=2675
@update_header

INSERT INTO csr.std_measure_conversion (
	std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
) VALUES (
	28152, 17, 'kWh/short ton', 0.0002519957610684249, 1, 0, 1
);

@update_tail
