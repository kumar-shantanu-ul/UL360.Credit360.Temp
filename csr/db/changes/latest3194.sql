-- Please update version.sql too -- this keeps clean builds in sync
define version=3194
define minor_version=0
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
	FOR r IN (
		SELECT distinct host
		  FROM csr.sheet_history sh
		  JOIN csr.customer c ON sh.app_sid = c.app_sid
		  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		UPDATE csr.sheet_history sh
		   SET is_system_note = 1 
		 WHERE note like 'Set to edit';
			
		COMMIT;
	END LOOP;
	
	security.user_pkg.logonadmin();
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../sheet_body

@update_tail
