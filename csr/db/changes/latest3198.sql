define version=3198
define minor_version=0

@update_header

BEGIN
	security.user_pkg.logonadmin();
	
	FOR r IN (SELECT distinct host FROM csr.sheet_history sh JOIN csr.customer c ON sh.app_sid = c.app_sid where host in (select website_name from security.website))
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

@update_tail
