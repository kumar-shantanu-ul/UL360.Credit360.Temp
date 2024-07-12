PROMPT please enter host:

DECLARE
	v_groups_sid						security_pkg.T_SID_ID;
	v_admins_sid						security_pkg.T_SID_ID;
	v_menu_admin						security_pkg.T_SID_ID;
	v_act							security_pkg.T_ACT_ID;
	v_app							security_pkg.T_SID_ID;
	v_new_menu_item						security_pkg.T_SID_ID;

BEGIN
	--log on
	security.user_pkg.logonadmin('&&1');
	v_app := sys_context('security','app');
	v_act := sys_context('security','act');
	
	--read groups
	v_groups_sid :=	security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');
	
	--add all deleg menu item
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu_admin, 'csr_delegation_admin', 'All Delegations',
			'/csr/site/delegation/admindeleg.acds',
			12, null, V_new_menu_item);
		
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			V_new_menu_item := security.securableobject_pkg.GetSidFromPath(v_act, v_menu_admin, 				'csr_delegation_all');
	END;

	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(V_new_menu_item), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.PropogateACEs(v_act, V_new_menu_item); 

END;
/

