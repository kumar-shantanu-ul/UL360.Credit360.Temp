-- Please update version.sql too -- this keeps clean builds in sync
define version=3162
define minor_version=8
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
	security.user_pkg.logonadmin;

	UPDATE security.menu
	   SET action = '/csr/site/flow/admin/pseudoRoles.acds'
	 WHERE LOWER(action) = '/csr/site/chain/admin/pseudoroles.acds';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
