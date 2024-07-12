-- Please update version.sql too -- this keeps clean builds in sync
define version=1624
@update_header

INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES (26190, 24, '1/hl', 10, 1, 0);

INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES(26191, 1, 'hl/hl', 1, 1, 0);

INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES (26192, 1, 'kg/tonne', 1000000000, 1, 0);
							 
@update_tail
