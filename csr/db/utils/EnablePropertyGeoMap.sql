PROMPT Please enter host name

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID; 
	v_act_id				SECURITY.SECURITY_PKG.T_ACT_ID;
	
	v_root_menu_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_property_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_map_menu_item_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_reg_users_sid			security.security_pkg.T_SID_ID;
	v_role_sid				SECURITY.SECURITY_PKG.T_SID_ID;

	v_tab_type_id			SECURITY.SECURITY_PKG.T_SID_ID;
	v_geo_map_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_geo_map_type_id		SECURITY.SECURITY_PKG.T_SID_ID;

BEGIN 
	security.user_pkg.logonadmin('&&1');
	
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;
	
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	BEGIN
		SELECT properties_geo_map_sid INTO v_geo_map_sid
		  FROM csr.property_options;
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_geo_map_sid := NULL;
		WHEN NO_DATA_FOUND THEN
			v_geo_map_sid := NULL;
	END;

	IF v_geo_map_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001,'This site already has a properties map.');
		RETURN;
	END IF;

	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');

	BEGIN
		v_property_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'csr_properties_menu');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				-- older sites still call it by the GP name
				v_property_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'gp_properties');			
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001,'Properties not enabled on this site. Run csr\db\utils\enableProperty first.');
					RETURN;
			END;
	END;

	
	v_role_sid := csr.role_pkg.GetRoleIDByKey('PROPERTY_MANAGER');
	
	IF v_role_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001,'PROPERTY_MANAGER role not found - check that properties is enabled on this site. Run csr\db\utils\enableProperty first.');
		RETURN;
	END IF;
	
	BEGIN
		SELECT geo_map_tab_type_id INTO v_tab_type_id
		  FROM csr.geo_map_tab_type
		 WHERE js_class = 'Credit360.GeoMapPopupTab.Property';
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'GeoMap not enabled on this site. Run csr\db\utils\enableGeoMap first.');
			RETURN;
	END;

	BEGIN
		INSERT INTO csr.customer_geo_map_tab_type (geo_map_tab_type_id) VALUES (v_tab_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN

		csr.geo_map_pkg.CreateGeoMap(
			in_label => 'Properties',
			in_region_selection_type_id => 6, -- "Selected items only" rather than Properties; we will poke the regions in by hand.
			in_tag_id => NULL,
			in_include_inactive_regions => 0,
			in_start_dtm => '01-JAN-14',
			in_end_dtm => NULL,
			in_interval => 'y',
			in_parent_sid => NULL,
			out_geo_map_sid => v_geo_map_sid
		);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	IF v_geo_map_sid IS NOT NULL THEN

		csr.geo_map_pkg.CreateGeoMapTab(
			in_geo_map_sid => v_geo_map_sid,
			in_label => 'Details',
			in_geo_map_tab_type_id => v_tab_type_id,
			in_pos => 1,
			out_geo_map_tab_id => v_geo_map_type_id
		);

		BEGIN
			INSERT INTO csr.property_options (properties_geo_map_sid) VALUES (v_geo_map_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.property_options
				   SET properties_geo_map_sid = v_geo_map_sid;
		END;
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_geo_map_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	END IF;

	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_property_menu_sid, 'gp_properties_map', 'Map', '/csr/site/property/properties/Map.acds', 5, null, v_map_menu_item_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_map_menu_item_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	COMMIT;
END;
/

exit
