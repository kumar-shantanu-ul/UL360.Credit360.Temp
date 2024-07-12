-- Please update version.sql too -- this keeps clean builds in sync
define version=1519
@update_header

UPDATE csr.std_measure_conversion
SET a = 1
WHERE std_measure_conversion_id = 26179;		
 
@update_tail
