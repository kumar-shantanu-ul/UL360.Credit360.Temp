-- Please update version.sql too -- this keeps clean builds in sync
define version=3101
define minor_version=0
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
	UPDATE security.menu
	   SET action = '/csr/site/chain/admin/pseudoRoles.acds',
		   description = 'Workflow pseudo-roles'
	 WHERE action = '/csr/site/flow/admin/involvementtypes.acds';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
