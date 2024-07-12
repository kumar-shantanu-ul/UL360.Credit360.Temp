exec user_pkg.logonadmin('&&host');

DECLARE
	v_act_id				security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid				security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
	v_container_sid			security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_container_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Export Feed');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(v_act_id, v_app_sid, security.security_pkg.SO_CONTAINER, 'Export Feed', v_container_sid);
			
			-- grant admins full permissions on the container 
			security.acl_pkg.AddACE(
				v_act_id, 
				security.acl_pkg.GetDACLIDForSID(v_container_sid), 
				security.security_pkg.ACL_INDEX_LAST, 
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, 
				security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators'), 
				security.security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
END;
/