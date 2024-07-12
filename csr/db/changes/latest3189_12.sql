-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
	DECLARE
		table_doesnt_exist exception;
		pragma exception_init( table_doesnt_exist, -942 );
	BEGIN
		--Some blacklist won't let me explicitly drop UPD tables so do it implicitly...
		EXECUTE IMMEDIATE 'DROP TABLE US15446_PROCESSED_DELEGS';
	EXCEPTION
		WHEN table_doesnt_exist THEN
			NULL;
	END;
	/
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
	UPDATE csr.delegation_role dr
	   SET deleg_permission_set = 3
	 WHERE dr.delegation_sid = dr.inherited_from_sid
	   AND NOT EXISTS (
		SELECT NULL FROM csr.delegation WHERE app_sid = dr.app_sid AND delegation_sid = dr.delegation_sid AND parent_sid = app_sid
		)
	   AND NOT EXISTS (
		SELECT NULL FROM security.securable_object so JOIN security.acl ON so.dacl_id = acl.acl_id WHERE so.sid_id = dr.delegation_sid AND acl.sid_id = dr.delegation_sid AND permission_set = 263139
	   );
	
	--Delete users and roles from delegation groups
	DELETE
	  FROM security.group_members gm
	 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = gm.group_sid_id);
	
	-- Stop delegations being a group
	DELETE
	  FROM security.group_table gt
	 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = gt.sid_id);
	
	-- Delete delegation aces from delegations.
	DELETE
	  FROM security.acl
	 WHERE EXISTS (SELECT NULL FROM csr.delegation WHERE delegation_sid = acl.sid_id);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../delegation_body

@update_tail
