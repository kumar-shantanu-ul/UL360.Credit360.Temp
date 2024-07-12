-- Please update version.sql too -- this keeps clean builds in sync
define version=2451
@update_header

INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c, divisible)
VALUES (28139, 22, 'days', 0.00001157, 1, 0, 0);

@update_tail
