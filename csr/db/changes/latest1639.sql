-- Please update version.sql too -- this keeps clean builds in sync
define version=1639
@update_header

UPDATE csr.std_measure_conversion
   SET A = 0.1
 WHERE std_measure_conversion_id = 26190;

UPDATE csr.std_measure_conversion
   SET A = 1000
 WHERE std_measure_conversion_id = 26192;

@update_tail
