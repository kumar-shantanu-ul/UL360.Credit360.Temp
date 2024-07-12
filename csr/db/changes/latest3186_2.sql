-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=2
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
-- description = 'GBTU (UK)'
UPDATE csr.std_measure_conversion
   SET A = 0.000000000000947817120
 WHERE std_measure_conversion_id = 28214;

-- description = 'GBTU (US)'    
UPDATE csr.std_measure_conversion
   SET A = 0.000000000000948043428
 WHERE std_measure_conversion_id = 28215;

-- description = 'GBTU (EC)'
UPDATE csr.std_measure_conversion
   SET A = 0.000000000000947813394
 WHERE std_measure_conversion_id = 28216;
    
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
