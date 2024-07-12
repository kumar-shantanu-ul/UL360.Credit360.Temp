-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=36
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
BEGIN
	security.user_pkg.LogonAdmin(NULL);

	UPDATE csr.issue_type 
	   SET allow_critical = 1
	 WHERE issue_type_id = 22;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../enable_body
@../permit_body

@update_tail
