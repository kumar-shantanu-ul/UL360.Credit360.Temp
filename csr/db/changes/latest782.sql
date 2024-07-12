define version=782
@update_header

UPDATE csr.std_measure_conversion
   SET description = '1/Gallon (US)'
 WHERE std_measure_conversion_id = 86;

@update_tail