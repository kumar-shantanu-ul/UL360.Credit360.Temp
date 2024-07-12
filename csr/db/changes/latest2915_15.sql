-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=15
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
-- Remove old region metric list page, its now deprecated
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu 
		 WHERE LOWER(action) ='/csr/site/property/admin/regionmetriclist.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_metric_pkg
@../property_pkg

@../region_metric_body
@../indicator_body
@../property_body
@../dataset_legacy_body

@update_tail
