-- Please update version.sql too -- this keeps clean builds in sync
define version=796
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES (100, 9, 'lb/MMBTU (US)', 2.32544476e9, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES (101, 9, 'lb/MMBTU (EC)', 2.32600914e9, 1, 0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES (102, 9, 'lb/MMBTU (UK)', 2.32600e9, 1, 0);

@update_tail
