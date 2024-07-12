-- Please update version.sql too -- this keeps clean builds in sync
define version=2381
@update_header

ALTER TABLE csr.std_measure_conversion
MODIFY (a NUMBER);

UPDATE csr.std_measure_conversion
   SET a = 0.0000000000002777777777
 WHERE description = 'GWh';

@update_tail
