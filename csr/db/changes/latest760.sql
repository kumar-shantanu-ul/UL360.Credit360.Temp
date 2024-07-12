-- Please update version.sql too -- this keeps clean builds in sync
define version=760
@update_header

declare
	v_new_cap_sid	number(10);
	v_copy_dacl_id	number(10);
	v_new_dacl_id	number(10);
begin	
	user_pkg.logonadmin;
	for r in (
		select parent_sid_id, sid_id 
		  from security.securable_object 
		 where name = 'Manage emission factors'
		   and parent_sid_id NOT IN (
				select parent_sid_id 
				  from security.securable_object 
				 where name = 'View emission factors'
		   )
	)
	loop
		-- copy sec obj		
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
	        r.parent_sid_id, 
	        class_pkg.GetClassId('CSRCapability'),
	        'View emission factors',
	        v_new_cap_sid
	    );
	    -- copy acls...
		v_copy_dacl_id := acl_pkg.GetDACLIDForSID(r.sid_id);
		v_new_dacl_id := acl_pkg.GetDACLIDForSID(v_new_Cap_sid);
		acl_pkg.DeleteAllACEs(SYS_CONTEXT('SECURITY','ACT'), v_new_dacl_id);
		for s in (
			SELECT acl_index, ace_type, ace_flags, sid_id, permission_set
			  FROM security.acl
			 WHERE acl_id = v_copy_dacl_id
		)
		loop
			acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), v_new_dacl_id, s.acl_index, s.ace_type, s.ace_flags, s.sid_id, s.permission_set);
		end loop;
	end loop;
end;
/

@update_tail
