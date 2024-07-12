-- Please update version.sql too -- this keeps clean builds in sync
define version=1608
@update_header

-- Update, measure should exist!
UPDATE csr.std_measure_conversion
SET a = 0.0000002778
WHERE std_measure_conversion_id = 26188;

@update_tail