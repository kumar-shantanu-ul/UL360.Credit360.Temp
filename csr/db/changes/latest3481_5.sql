-- Please update version.sql too -- this keeps clean builds in sync
define version=3481
define minor_version=5
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
		SELECT DISTINCT application_sid_id, website_name
		  FROM security.website sec
		  JOIN csr.customer c
		    ON sec.application_sid_id = c.app_sid
		 WHERE LOWER(c.site_type) = 'staff'
	)
	LOOP
		security.user_pkg.LogonAdmin(r.website_name);

		UPDATE aspen2.application
		   SET ga4_enabled = 0
		 WHERE app_sid = r.application_sid_id;

		security.user_pkg.LogonAdmin();
	END lOOP;
END;
/	
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail
