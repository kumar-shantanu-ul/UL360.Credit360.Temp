define host="&&1"

declare
	v_sso_daemon_name		VARCHAR2(1024) := 'SSO';
	v_sso_daemon_full_name 	VARCHAR2(1024) := 'Single Sign On system';
	v_sso_daemons_group_name	VARCHAR2(1024) := 'SSO Logon Daemons';
	v_sso_users_group_name		VARCHAR2(1024) := 'SSO Users';
	v_administrators_group_name	VARCHAR2(1024) := 'Administrators';
	v_direct_logon_capability	VARCHAR2(1024) := 'Logon directly';
	v_users_sid			security.security_pkg.T_SID_ID;
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_sso_daemon_sid		security.security_pkg.T_SID_ID;
	v_sso_daemons_group_sid		security.security_pkg.T_SID_ID;
	v_sso_users_group_sid		security.security_pkg.T_SID_ID;
	v_reg_users_group_sid		security.security_pkg.T_SID_ID;
	v_super_admins_group_sid	security.security_pkg.T_SID_ID;
	v_administrators_group_sid	security.security_pkg.T_SID_ID;
	v_direct_logon_capability_sid	security.security_pkg.T_SID_ID;
	v_permission_set		security.security_pkg.T_PERMISSION;
begin
	security.user_pkg.LogonAdmin('&&host');

	v_users_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Users');
	v_groups_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Groups');
	
	v_reg_users_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, 'RegisteredUsers');	
	
	begin
		v_sso_daemon_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_users_sid, v_sso_daemon_name);
		csr.csr_user_pkg.activateUser(security.security_pkg.GetACT, v_sso_daemon_sid);
		dbms_output.put_line('"' || v_sso_daemon_name || '" user found (#' || v_sso_daemon_sid || '). Activated user if it was disabled.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
				csr.csr_user_pkg.createUser(
					in_act			 			=> security.security_pkg.getACT,
					in_app_sid					=> security.security_pkg.getApp,
					in_user_name				=> v_sso_daemon_name,
					in_password 				=> null,
					in_full_name				=> v_sso_daemon_full_name,
					in_friendly_name			=> v_sso_daemon_name,
					in_email		 			=> 'no-reply@cr360.com',
					in_job_title				=> null,
					in_phone_number				=> null,
					in_info_xml					=> null,
					in_send_alerts				=> 0,
					in_account_expiry_enabled	=> 0,
					out_user_sid 				=> v_sso_daemon_sid
				);
		dbms_output.put_line('"' || v_sso_daemon_name || '" user not found. Created one. (#' || v_sso_daemon_sid || ')');
	end;
	
	-- Don't want SSO logon daemon to be visible in the UI
	update csr.csr_user set hidden = 1 where app_sid = security.security_pkg.getApp and csr_user_sid = v_sso_daemon_sid;
	
	begin
		v_sso_daemons_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_sso_daemons_group_name);
		dbms_output.put_line('"' || v_sso_daemons_group_name || '" group (#' || v_sso_daemons_group_sid || ') found.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.group_pkg.CreateGroupWithClass(security.security_pkg.GetACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, v_sso_daemons_group_name, security.security_pkg.SO_GROUP, v_sso_daemons_group_sid);
			dbms_output.put_line('"' || v_sso_daemons_group_name || '" group not found. Created one. (#' || v_sso_daemons_group_sid || ')');
	end;

	begin
		v_sso_users_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_sso_users_group_name);
		dbms_output.put_line('"' || v_sso_users_group_name || '" group (#' || v_sso_users_group_sid || ') found.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			security.group_pkg.CreateGroupWithClass(security.security_pkg.GetACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, v_sso_users_group_name, security.class_pkg.GetClassID('CSRUserGroup'), v_sso_users_group_sid);
			dbms_output.put_line('"' || v_sso_users_group_name || '" group not found. Created one. (#' || v_sso_users_group_sid || ')');
	end;

	begin
		v_administrators_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_groups_sid, v_administrators_group_name);
		dbms_output.put_line('Site has an "' || v_administrators_group_name || '" group (#' || v_administrators_group_sid || '). Members will be given permission to manage "' || v_sso_users_group_name || '" group membership.');
	exception
		when security.security_pkg.OBJECT_NOT_FOUND then
			v_administrators_group_sid := NULL;
			dbms_output.put_line('Site does not have an "' || v_administrators_group_name || '" group. Only super admins will be able to manage "' || v_sso_users_group_name || '" group membership unless existing inheritable permission dictate otherwise.');
	end;

	-- Restrict access to the SSO Logon Daemons group, which also hides it from the UI for normal users.

	security.securableobject_pkg.ClearFlag(security.security_pkg.GetACT, v_sso_daemons_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_daemons_group_sid));
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_daemons_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_users_sid, 'UserCreatorDaemon'), security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_daemons_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, security.security_pkg.SID_BUILTIN_ADMINISTRATOR, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.group_pkg.AddMember(security.security_pkg.GetACT, v_sso_daemon_sid, v_sso_daemons_group_sid);

	dbms_output.put_line('Permissions on the "' || v_sso_daemons_group_name || '" group restricted to remove it from the UI. You do not need to modify membership of this group.');

	-- Give the SSO Logon Daemons group permission to log on as users who are members of the SSO Users group.

	SELECT p.permission INTO v_permission_set
	  FROM security.securable_object so
	  JOIN security.permission_name p ON so.class_id = p.class_id
	 WHERE p.permission_name = 'Logon as another user'
	   AND so.sid_id = v_sso_users_group_sid;

	v_permission_set := security.bitwise_pkg.bitor(v_permission_set, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), v_sso_daemons_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, v_permission_set);

	dbms_output.put_line('"' || v_sso_daemons_group_name || '" group has been given permission to log on as members of the "' || v_sso_users_group_name || '" group.');

	-- Give the SSO Logon Daemons group permission to read users, which it needs to do to find out if they are SSO Users or not.
	-- Also give write permission on users, to allow them to amend user details.

	security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), v_sso_daemons_group_sid);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_users_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_sso_daemons_group_sid, security.security_pkg.PERMISSION_WRITE);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_users_sid);

	dbms_output.put_line('"' || v_sso_daemons_group_name || '" group has been given permission read and write all users.');
	
	-- Allow CRedit360 employees to manage SSO User group membership.

	security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), security.security_pkg.SID_BUILTIN_ADMINISTRATORS);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, security.security_pkg.SID_BUILTIN_ADMINISTRATORS, security.bitwise_pkg.bitor(security.security_pkg.PERMISSION_STANDARD_READ, security.security_pkg.PERMISSION_WRITE));

	dbms_output.put_line('Super Admins have given permission to manage "' || v_sso_users_group_name || '" group membership.');

	-- If there is an Administrators group, then allow its memmbers to manage SSO User group membership as well.

	if v_administrators_group_sid is not null then
		security.acl_pkg.RemoveACEsForSID(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), v_administrators_group_sid);
		security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_sso_users_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_administrators_group_sid, security.bitwise_pkg.bitor(security.security_pkg.PERMISSION_STANDARD_READ, security.security_pkg.PERMISSION_WRITE));
		dbms_output.put_line('Members of the "' || v_administrators_group_name || '" group have given permission to manage "' || v_sso_users_group_name || '" group membership.');
	end if;

	-- Deny SSO Users the ability to log on directly with a user name and password, and ensure than non-SSO users can still log on directly.

	csr.csr_data_pkg.EnableCapability(v_direct_logon_capability, 1);

	v_direct_logon_capability_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetApp, 'Capabilities/' || v_direct_logon_capability);

	security.securableobject_pkg.ClearFlag(security.security_pkg.GetACT, v_direct_logon_capability_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid));

	-- If RegisteredUsers group later gets added to the SSO Users group, this is required to allow SuperAdmins to log in directly.
	v_super_admins_group_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, 0, 'csr/SuperAdmins');
	
	security.acl_pkg.AddACE(security.security_pkg.GetACT, 
		security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid), 
		0, 
		security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, 
		v_super_admins_group_sid, 
		security.security_pkg.PERMISSION_WRITE);
	
	security.acl_pkg.AddACE(security.security_pkg.GetACT, 
		security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid), 
		0, 
		security.security_pkg.ACE_TYPE_DENY, 
		security.security_pkg.ACE_FLAG_DEFAULT, 
		v_sso_users_group_sid, 
		security.security_pkg.PERMISSION_WRITE);

	dbms_output.put_line('Members of the "' || v_sso_users_group_name || '" group have been denied permission to log on directly using a user name and password. Edit the "' || v_direct_logon_capability || '" capability''s permissions if you want to change this.');

	security.acl_pkg.AddACE(security.security_pkg.GetACT, 
		security.acl_pkg.GetDACLIDForSID(v_direct_logon_capability_sid), 
		-1, 
		security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, 
		v_reg_users_group_sid, 
		security.security_pkg.PERMISSION_WRITE);

	dbms_output.put_line('All non-SSO users still have permission to log on directly.');
	dbms_output.put_line('Done. This script is safe to re-run if necessary.');
end;
/
