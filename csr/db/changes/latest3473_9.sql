-- Please update version.sql too -- this keeps clean builds in sync
define version=3473
define minor_version=9
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
-- ADO https://dev.azure.com/ULSE/UL360%20Development/_workitems/edit/216766
-- Disables all Super Admin accounts with usernames that do not meet the
-- requirements for Super Admin SSO (must be an @global.ul.com username).
-- Passwords are also nulled out.
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM security.web_resource
	 WHERE path = '/csr/sasso/login';

	IF v_count = 0 THEN
		-- Superadmin SSO is not configured on this database. Skip
		-- so that we don't disable accounts that may be used for tests
		-- (e.g. on .auto or .sprint) where SA SSO is not available.
		RETURN;
	END IF;

	FOR r IN (
		SELECT csr_user_sid
		  FROM csr.superadmin
		 WHERE LOWER(user_name) NOT LIKE ('%@global.ul.com')
	)
	LOOP
		security.user_pkg.UNSEC_DisableAccount(r.csr_user_sid);
		
		-- Null out password.
		UPDATE security.user_table
		   SET login_password = null,
		       login_password_salt = null,
		       java_login_password = null
		 WHERE sid_id = r.csr_user_sid;
		
		COMMIT;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
