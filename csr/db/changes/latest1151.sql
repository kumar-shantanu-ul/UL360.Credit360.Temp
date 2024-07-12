-- Please update version.sql too -- this keeps clean builds in sync
define version=1151
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id,std_measure_id,description,a,b,c) VALUES (25991,26,'kWh/hl',0.000000027777777778,1,0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id,std_measure_id,description,a,b,c) VALUES (25992,26,'MWh/hl',0.000000000027777778,1,0);

@update_tail
