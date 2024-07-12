declare
	v_clone_group_name	security_pkg.T_SO_NAME := 'Administrators';
	v_new_group_name	security_pkg.T_SO_NAME := 'Regional Administrators';
	v_clone_group_sid	security_pkg.T_SID_ID;
	v_new_group_sid		security_pkg.T_SID_ID;
	v_parent_sid_id 	security_pkg.T_SID_ID;
begin
	user_pkg.logonAdmin('hammerson.credit360.com');
	v_clone_group_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups/'||v_clone_group_name);
	SELECT parent_sid_id 
	  INTO v_parent_sid_id 
	  FROM security.securable_object
	 WHERE sid_id = v_clone_group_sid;
	-- create new group
	group_pkg.CreateGroupWithClass(security_pkg.getACT, v_parent_sid_id,
		security_pkg.GROUP_TYPE_SECURITY, v_new_group_name, class_pkg.getClassId('CSRUserGroup'), 
		v_new_group_sid);
	FOR r IN (
		SELECT acl_id, ace_type, ace_flags, permission_set
		  FROM security.acl
		 WHERE sid_id = v_clone_group_sid
	)
	LOOP
		acl_pkg.AddACE(security_pkg.getACT, r.acl_id, security_pkg.ACL_INDEX_LAST, 
			r.ace_type, r.ace_flags, v_new_group_sid, r.permission_set);
	END LOOP;
end;
/

