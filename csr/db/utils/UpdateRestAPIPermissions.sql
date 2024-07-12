DECLARE
	v_act_id										security.security_pkg.T_ACT_ID;
	v_app_sid										security.security_pkg.T_SID_ID;

	-- users
	v_groups_sid									security.security_pkg.T_SID_ID;
	v_registered_users_sid							security.security_pkg.T_SID_ID;
	
	-- web resources
	v_www_sid										security.security_pkg.T_SID_ID;
	v_www_restapi									security.security_pkg.T_SID_ID;
	v_www_surveys									security.security_pkg.T_SID_ID;

BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	
	v_act_id := sys_context('SECURITY','ACT');
	v_app_sid := sys_context('SECURITY','APP');

	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_registered_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	
	BEGIN
	
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		v_www_restapi := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'restapi');

		BEGIN
			-- If Quick Surveys are enabled, give registered users permission to list the surveys
			v_www_surveys := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'surveys');
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_surveys), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_registered_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				-- Quick surveys are not enabled, so nothing to do
				NULL;
		END;
	
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			-- Rest API is not enabled, so nothing to do
			NULL;
	END;

	COMMIT;
END;
/
