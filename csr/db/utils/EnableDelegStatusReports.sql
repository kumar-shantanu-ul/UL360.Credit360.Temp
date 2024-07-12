exec security.user_pkg.logonadmin('&&host');

DECLARE
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_container_sid			security.security_pkg.T_SID_ID;
	v_menu_admin			security.security_pkg.T_SID_ID;
	v_menu_deleg_status		security.security_pkg.T_SID_ID;
	v_act_id				security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid				security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
BEGIN
	-- read admin group
	v_admins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');

	-- enable deleg status reports
	BEGIN
		v_container_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Delegation Reports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Delegation Reports', v_container_sid);

			-- grant admins full permissions on the container
			security.acl_pkg.AddACE(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_container_sid),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				v_admins_sid,
				security.security_pkg.PERMISSION_STANDARD_ALL
			);
	END;

	-- add deleg plan menu items
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
			'status_overview',
			'Delegation status overview',
			'/csr/site/delegation/manage/statusOverview.acds',
			10, null, v_menu_deleg_status);

		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_deleg_status), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);

	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/