-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=9
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
	   SET action = '/csr/site/users/list/list.acds'
	 WHERE LOWER(action) = '/csr/site/users/userlist.acds';
	
	UPDATE security.securable_object so
	   SET name = 'csr_users_list'
	 WHERE LOWER(name) = 'csr_users'
	   AND EXISTS (
			SELECT NULL
			  FROM security.menu
			 WHERE sid_id = so.sid_id
			   AND LOWER(action) = '/csr/site/users/list/list.acds'
	   );  
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
