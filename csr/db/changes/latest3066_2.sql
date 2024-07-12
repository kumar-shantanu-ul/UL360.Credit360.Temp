-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.std_measure_conversion
   SET A = 0.00000000027777777778
 WHERE std_measure_conversion_id = 29;

UPDATE csr.std_measure_conversion
   SET A = 0.00000000000027777777778
 WHERE std_measure_conversion_id = 15797;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
