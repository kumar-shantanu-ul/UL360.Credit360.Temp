-- Please update version.sql too -- this keeps clean builds in sync
define version=752
@update_header

INSERT INTO csr.STD_MEASURE_CONVERSION (std_measure_conversion_id, std_measure_id, description, a, b, c)
values (80, 1, 'metric ton / short ton', 0.90718474, 1, 0);

@update_tail
