-- Please update version.sql too -- this keeps clean builds in sync
define version=3026
define minor_version=0
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
	-- Menu text change, but only where the menu is still called one of 
	-- the old names it's had (probably not changed by the user)
	UPDATE security.menu
	   SET description = 'Meter errors'
	 WHERE LOWER(action) = '/csr/site/meter/monitor/orphanmeterregions.acds'
	   AND LOWER(description) IN ('orphan data', 'orphan meters');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
