-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=8
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
BEGIN
	UPDATE csr.util_script
	   SET util_script_name = 'API: Create API Client'
	 WHERE util_script_id = 38;
	
	UPDATE csr.util_script
	   SET util_script_name = 'API: Update API Client secret'
	 WHERE util_script_id = 39;
	
	
	UPDATE csr.module
	   SET description = 'Enables API integrations . See utility script page for API user creation.'
	 WHERE module_id = 97;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_body

@update_tail
