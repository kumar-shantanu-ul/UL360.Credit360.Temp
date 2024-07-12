PROMPT Please enter host name

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID; 
	v_act_id				SECURITY.SECURITY_PKG.T_ACT_ID;
	
	v_root_menu_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_training_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_reg_users_sid			security.security_pkg.T_SID_ID;

	v_geo_map_sid			SECURITY.SECURITY_PKG.T_SID_ID;

BEGIN 
	security.user_pkg.logonadmin('&&1');
	
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;
	
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	BEGIN
		SELECT geo_map_sid INTO v_geo_map_sid
		  FROM csr.training_options
		  WHERE app_sid = v_app_sid;
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_geo_map_sid := NULL;
		WHEN NO_DATA_FOUND THEN
			v_geo_map_sid := NULL;
	END;

	IF v_geo_map_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001,'This site already has a trainings map.');
		RETURN;
	END IF;

	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');

	BEGIN
		v_training_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'csr_training');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'Training not enabled on this site. Run csr\db\utils\enableTraining first.');
			RETURN;
	END;
	
	BEGIN
		csr.geo_map_pkg.CreateGeoMap(
			in_label => 'Training',
			in_region_selection_type_id => 6, -- "Selected items only" rather than Properties; we will poke the regions in by hand.
			in_tag_id => NULL,
			in_include_inactive_regions => 0,
			in_start_dtm => '01-JAN-15',
			in_end_dtm => NULL,
			in_interval => 'y',
			in_parent_sid => NULL,
			out_geo_map_sid => v_geo_map_sid
		);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'Geo Map not enabled on this site. Run csr\db\utils\enableGeoMap first.');
			RETURN;
	END;

	IF v_geo_map_sid IS NOT NULL THEN
		
		BEGIN
			INSERT INTO csr.training_options (app_sid, geo_map_sid) VALUES (v_app_sid, v_geo_map_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.training_options
				   SET geo_map_sid = v_geo_map_sid
				 WHERE app_sid = v_app_sid;
		END;
		
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_geo_map_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	COMMIT;
END;
/

exit
