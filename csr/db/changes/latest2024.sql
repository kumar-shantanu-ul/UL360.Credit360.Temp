-- Please update version.sql too -- this keeps clean builds in sync
define version=2024
@update_header

-- standardise the precision for kWh/m^3 to match kWh, kWh/m^2, etc.
UPDATE csr.std_measure_conversion
SET a = 2.77778E-07
WHERE std_measure_conversion_id = 26188;

@update_tail
