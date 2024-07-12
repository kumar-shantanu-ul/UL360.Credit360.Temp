-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=0
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
UPDATE csr.module
   SET description = 'Update the Emission Factor start date to match the customer reporting period start date; existing standard factor dates will be matched to this date, custom factor dates will be unaffected.'
 WHERE module_id = 50
   AND enable_sp = 'EnableFactorStartMonth';


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body
@../factor_body

@update_tail
