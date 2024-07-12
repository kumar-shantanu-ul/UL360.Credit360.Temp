-- Please update version.sql too -- this keeps clean builds in sync
define version=3392
define minor_version=4
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
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT m.sid_id, so.application_sid_id, w.website_name
		  FROM security.menu m
		  JOIN security.securable_object so ON so.sid_id = m.sid_id
		  JOIN security.website w ON w.application_sid_id = so.application_sid_id
		 WHERE m.action = '/csr/site/delegation/manage/editPlan.acds'
	) LOOP
		security.user_pkg.logonadmin(r.website_name);
		security.securableobject_pkg.DeleteSO(sys_context('security', 'act'), r.sid_id);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
