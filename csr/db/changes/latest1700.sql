-- Please update version.sql too -- this keeps clean builds in sync
define version=1700
@update_header

INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
     VALUES (26193, 28, 'hl/MJ', 10000000, 1, 0);

@update_tail
