-- Please update version.sql too -- this keeps clean builds in sync
define version=1610
@update_header

INSERT INTO csr.std_measure_conversion(std_measure_conversion_id, std_measure_id, description, a, b, c)
VALUES(26189, 3, 'ft', 3.281, 1, 0);

@update_tail