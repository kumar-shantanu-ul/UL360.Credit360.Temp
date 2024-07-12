-- Please update version.sql too -- this keeps clean builds in sync
define version=1094
@update_header 

-- Hectares
INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES(118, 12, 'Hectare', 0.0001, 1, 0);

-- Tonnes/Litre
INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES(119, 8, 'tonne/litre', 0.000001, 1, 0);

@update_tail
