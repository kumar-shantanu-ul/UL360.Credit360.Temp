-- Please update version.sql too -- this keeps clean builds in sync
define version=1512
@update_header
	

--tCO2e/km
UPDATE csr.std_measure_conversion 
   SET description = 't/km'
 WHERE std_measure_conversion_id = 26184;
 
 --tCO2e/m3
UPDATE csr.std_measure_conversion 
   SET description = 't/m^3'
 WHERE std_measure_conversion_id = 26185;

 --tCO2e/vkm
UPDATE csr.std_measure_conversion 
   SET description = 't/vkm'
 WHERE std_measure_conversion_id = 26186;
			
@update_tail