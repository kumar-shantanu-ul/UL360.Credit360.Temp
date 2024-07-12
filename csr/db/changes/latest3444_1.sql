-- Please update version.sql too -- this keeps clean builds in sync
define version=3444
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
BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Refresh of Finding List Plugin', 1, 'Added a function to enable users to refresh the findings on the finding list when multiple audit details are opened in different browser tabs. This ensures that the finding list displays up to date records.');
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
