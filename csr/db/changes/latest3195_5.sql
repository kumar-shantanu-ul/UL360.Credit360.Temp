-- Please update version.sql too -- this keeps clean builds in sync
define version=3195
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
	
	FOR r IN (SELECT distinct host FROM csr.sheet_history sh JOIN csr.customer c ON sh.app_sid = c.app_sid)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		UPDATE csr.sheet_history sh
		   SET is_system_note = 1 
		 WHERE note like 'Created'
			OR note like 'Set status according to parent sheet.'
			OR note like 'Automatic submission of this sheet was blocked because there are errors'
			OR note like 'Rollback requested'
			OR note like 'Automatically approved'
			OR note like 'Automatic approval failed: intolerances found'
			OR note like 'Data Change Request automatically approved and form returned to user for editing';
			
		COMMIT;
	END LOOP;
	
	security.user_pkg.logonadmin();
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***


@update_tail
