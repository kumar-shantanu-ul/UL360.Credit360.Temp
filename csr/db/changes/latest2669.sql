--Please update version.sql too -- this keeps clean builds in sync
define version=2669
@update_header

INSERT INTO csr.std_measure_conversion (
	std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
) VALUES (
	28151, 29, 'm^3/kg', 1, 1, 0, 1
);

@update_tail
