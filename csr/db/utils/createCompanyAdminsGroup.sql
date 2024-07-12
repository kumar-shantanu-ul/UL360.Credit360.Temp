PROMPT please enter: host, company SID, new group name
DEFINE host = '&&1'
DEFINE company_sid = &&2
DEFINE group = '&&3'

DECLARE
	v_company_users_sid	security.security_pkg.T_SID_ID;
	v_class_id			security.security_pkg.T_CLASS_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_new_group_sid		security.security_pkg.T_SID_ID;
	v_admins_sid		security.security_pkg.T_SID_ID;
	
	v_act						security.security_pkg.T_ACT_ID;
	v_app						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin('&&host');
	
	v_app := SYS_CONTEXT('SECURITY','APP');
	v_act := SYS_CONTEXT('SECURITY','ACT');
	
	-- Get the admins group specific to this company
	SELECT group_sid
	  INTO v_company_users_sid
	  FROM chain.company_group
	 WHERE company_sid = &&company_sid
	   AND company_group_type_id = 1; -- Company admins
	
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');
	v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
	
	-- create a new group and add the company specific group to it - all users made admins for that company will now have this new group
	security.group_pkg.CreateGroupWithClass(v_act, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, '&&group', v_class_id, v_new_group_sid);
	
	security.group_pkg.AddMember(v_act, v_company_users_sid, v_new_group_sid);
	
	-- clear the write flag for administrators, this means admins aren't tempted to add additional users to this group
	-- as that would only confuse people (because it wouldn't be adding them to the company).
	security.securableobject_pkg.ClearFlag(v_act, v_new_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(v_act, security.acl_pkg.GetDACLIDForSID(v_new_group_sid));
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_new_group_sid),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT,
		v_admins_sid,
		security.security_pkg.PERMISSION_STANDARD_ALL - security.security_pkg.PERMISSION_WRITE);
END;
/

exit