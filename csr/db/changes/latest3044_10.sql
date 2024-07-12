-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=10
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

-- Change the menu for Metering\Meter Actions to point to the new metering issue list page
BEGIN
	security.user_pkg.LogonAdmin();

	UPDATE security.menu
		SET action = '/csr/site/meter/meterIssuesList.acds'
		WHERE lower(action) = lower('/csr/site/meter/meterActionsList.acds')
		   OR lower(action) = lower('/csr/site/issues/issueList.acds?issueTypes=6,7,8');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
