-- Please update version.sql too -- this keeps clean builds in sync
define version=2026
@update_header

-- standardise the precision for kWh/m^3 to match kWh
UPDATE csr.std_measure_conversion
SET a = 0.00000027777777778
WHERE std_measure_conversion_id = 26188;

@update_tail
