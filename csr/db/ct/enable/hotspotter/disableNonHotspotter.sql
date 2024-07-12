EXEC user_pkg.logonadmin('&&1');

DECLARE
	v_act_id 					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid 					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	-- well known sids	
	v_menu						security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
	v_everyone_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Everyone');
BEGIN
	-- NOTE: If the admin menu requires special permissions it should be done by adding deny to everyone in first pos, and then
	-- the required ALLOWS, in the first position (effectively pushing everyone deny down)
	
	/* HIDE all other menus*/
	FOR r IN (
		SELECT sid_id FROM security.securable_object WHERE parent_sid_id = v_menu AND name NOT IN ('hotspot_dashboard', 'admin', 'ct_hs_about')
	) LOOP
		acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(r.sid_id), security_pkg.ACL_INDEX_FIRST, security_pkg.ACE_TYPE_DENY,
			security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_ALL);	
	END LOOP;
END;
/
