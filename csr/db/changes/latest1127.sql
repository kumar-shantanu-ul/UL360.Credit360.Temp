-- Please update version.sql too -- this keeps clean builds in sync
define version=1127
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	 VALUES (25990,26,'kWh/Gallon (US)',0.00000000105150327,1,0);

@update_tail
