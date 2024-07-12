-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=1
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

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT sid_id
		  FROM security.menu
		 WHERE action = '/csr/site/chain/import/import.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, r.sid_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../structure_import_pkg
@../structure_import_body

@update_tail
