-- Please update version.sql too -- this keeps clean builds in sync
define version=3258
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.std_measure_conversion
SET a = 1.8, c = -459.67
WHERE std_measure_conversion_id = 12493;

UPDATE csr.std_measure_conversion
SET c = -273.15
WHERE std_measure_conversion_id = 12437;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../measure_body

@update_tail
