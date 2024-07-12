-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=37
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
	security.user_pkg.LogonAdmin;
	
	UPDATE chain.filter_field
	   SET name = REPLACE(name, 'PropertyCmsFilter', 'CmsFilter')
	 WHERE name LIKE 'PropertyCmsFilter%';
	
	UPDATE chain.filter_field
	   SET name = REPLACE(name, 'CompanyCmsFilter', 'CmsFilter')
	 WHERE name LIKE 'CompanyCmsFilter%';
	
	UPDATE chain.filter_field
	   SET name = REPLACE(name, 'ProductCmsFilter', 'CmsFilter')
	 WHERE name LIKE 'ProductCmsFilter%';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
