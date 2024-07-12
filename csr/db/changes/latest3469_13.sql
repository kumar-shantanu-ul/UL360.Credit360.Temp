-- Please update version.sql too -- this keeps clean builds in sync
define version=3469
define minor_version=13
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
	security.user_pkg.logonadmin('sso-sharky.credit360.com');

	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

BEGIN
	security.user_pkg.logonadmin('sso.cr360-refresh.com');

	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

BEGIN
	security.user_pkg.logonadmin('sso.cat-cr360.com');

	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
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
