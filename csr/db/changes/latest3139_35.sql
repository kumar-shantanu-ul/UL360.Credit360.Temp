-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=35
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

-- Fix Defra factor Road Vehicle Distance - Car (Average) - Unknown Fuel (Direct)
UPDATE csr.std_factor
   SET std_measure_conversion_id = 19
 WHERE std_factor_set_id = 1454
   AND factor_type_id = 13995
   AND std_measure_conversion_id = 38;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
