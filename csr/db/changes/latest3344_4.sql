-- Please update version.sql too -- this keeps clean builds in sync
define version=3344
define minor_version=4
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
   SET std_measure_id = 8, A = 0.0283168466
 WHERE description LIKE 'kg/scf';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
