-- Please update version.sql too -- this keeps clean builds in sync
define version=1095
@update_header 

UPDATE csr.std_measure_conversion
SET description = 'metric ton'
WHERE std_measure_conversion_id = 4;

UPDATE csr.std_measure_conversion
SET description = 'metric ton/litre'
WHERE std_measure_conversion_id = 119;

@update_tail
