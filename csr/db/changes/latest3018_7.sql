-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=7
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

	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
		 WHERE property_flow_sid IS NOT NULL
		   AND app_sid NOT IN (SELECT app_sid
		                         FROM csr.issue_type
		                        WHERE issue_type_id = 15)
	) LOOP
		INSERT INTO csr.issue_type(app_sid, issue_type_id, label)
			 VALUES (r.app_sid, 15, 'Property');
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
