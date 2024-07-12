-- Please update version.sql too -- this keeps clean builds in sync
define version=1104
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	 VALUES (131, 17, 'kWh/metric ton', 0.000277777778, 1, 0);

@..\measure_pkg
@..\measure_body

@update_tail
