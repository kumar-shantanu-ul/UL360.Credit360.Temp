PROMPT please enter host:

DECLARE
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
	v_menu_data						security.security_pkg.T_SID_ID;
	v_act							security.security_pkg.T_ACT_ID;
	v_app							security.security_pkg.T_SID_ID;
	v_new_menu_item					security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_site					security.security_pkg.T_SID_ID;
	v_www_csr_site_regionmgr		security.security_pkg.T_SID_ID;
	v_www_csr_site_indregion		security.security_pkg.T_SID_ID;
BEGIN
	--log on
	security.user_pkg.logonadmin('&&1');
	v_app := sys_context('security','app');
	v_act := sys_context('security','act');
	
	--read groups
	v_groups_sid :=	security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
	
	--add all deleg menu item
	v_menu_data := security.securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu/data');
	BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu_data, 'csr_regionmanager', 'Property manager',
			'/csr/site/regionManager/regionManager.acds',
			12, null, V_new_menu_item);
		
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			V_new_menu_item := security.securableobject_pkg.GetSidFromPath(v_act, v_menu_data,'csr_regionmanager');
	END;
	
	/*** WEB RESOURCE ***/
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'csr/site');

	-- this should exist
	v_www_csr_site_indregion := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'csr/site/schema/indRegion');

	BEGIN
		v_www_csr_site_regionmgr := security.securableobject_pkg.GetSidFromPath(v_act, v_www_csr_site, 'regionManager');
		security.acl_pkg.RemoveACEsForSid(v_act, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_regionmgr), v_reg_users_sid);
		security.securableobject_pkg.ClearFlag(v_act, v_www_csr_site_regionmgr, security.security_pkg.SOFLAG_INHERIT_DACL);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act, v_www_sid, v_www_csr_site, 'regionManager', v_www_csr_site_regionmgr);
	END;
	
	
	FOR r IN (
		SELECT role_sid FROM csr.role WHERE is_property_manager = 1
	)
	LOOP
		acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(V_new_menu_item), -1,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				r.role_sid, 
				security.security_pkg.PERMISSION_STANDARD_READ);
		acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_regionmgr), -1,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				r.role_sid, 
				security.security_pkg.PERMISSION_STANDARD_READ);
		acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_indregion), -1,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				r.role_sid, 
				security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/

