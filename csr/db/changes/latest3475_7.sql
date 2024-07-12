-- Please update version.sql too -- this keeps clean builds in sync
define version=3475
define minor_version=7
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
	security.user_pkg.logonadmin('sso.credit360.demo');

	UPDATE csr.customer
	   SET require_sa_login_reason = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

BEGIN
	security.user_pkg.logonadmin('sso-local.credit360.com');

	UPDATE csr.customer
	   SET require_sa_login_reason = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
