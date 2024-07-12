-- Please update version.sql too -- this keeps clean builds in sync
define version=1313
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES (26160,26,'GJ/m^3',0.000000001,1,0);

@update_tail
