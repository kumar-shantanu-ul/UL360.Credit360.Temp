-- Please update version.sql too -- this keeps clean builds in sync
define version=1598
@update_header

-- This measure SHOULD exist - was added in latest1576.
UPDATE csr.std_measure_conversion
SET a = 3600000
WHERE std_measure_conversion_id = 26188;

@update_tail