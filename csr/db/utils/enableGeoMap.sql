
PROMPT please enter: host

DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_geomap				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_geomap		security.security_pkg.T_SID_ID;
	-- temp variables
	v_new_sid_id            	security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	
	v_act_id := security.security_pkg.getAct;
	v_app_sid := security.security_pkg.getApp;
	
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	
	/*** MENU ***/
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin'),
			'csr_geo_map_list', 'Maps', '/csr/site/geomap/MapList.acds', 10, null, v_menu_geomap);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	/*** WEB RESOURCE ***/
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	BEGIN
		v_www_csr_site_geomap := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'geomap');
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_geomap), v_reg_users_sid);
		-- add reg users to geomap web resource
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_geomap), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'geomap', v_www_csr_site_geomap);
			-- add reg users to issues web resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_geomap), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	/*** SEC OBJECT */
	BEGIN
		security.SecurableObject_pkg.CreateSO(security.security_pkg.getact, security.security_pkg.getapp, security.security_pkg.SO_CONTAINER, 'GeoMaps', v_new_sid_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	/*** PORTLET ***/
	csr.portlet_pkg.EnablePortletForCustomer(1048);

	COMMIT;
END;
/