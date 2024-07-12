-- Please update version.sql too -- this keeps clean builds in sync
define version=3183
define minor_version=7
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
   SET util_script_name = 'Enable/Disable lazy load of region role membership on user and region edit',
	   description = 'Enable or disable automatic loading of region role membership for users on editing a user or a region'
 WHERE util_script_id = 37;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
