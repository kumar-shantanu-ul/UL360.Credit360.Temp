-- Please update version.sql too -- this keeps clean builds in sync
define version=3266
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

UPDATE csr.util_script
   SET description = '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the number of years to bound calculation "end of time". Updates Calc End Dtm.'
 WHERE util_script_id = 40;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../util_script_body

@update_tail
