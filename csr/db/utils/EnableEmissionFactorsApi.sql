DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_api						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id
		  FROM security.securable_object
		 WHERE name = 'Can import std factor set'
	)
	LOOP
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');

		BEGIN
			v_www_api := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.emissionfactor');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				security.security_pkg.SetApp(r.application_sid_id);
				security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.emissionfactor', v_www_api);

				v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.application_sid_id, 'Groups');
				v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
				security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_api), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				security.security_pkg.SetApp(null);
			END;
		END;
		
	END LOOP;
	security.user_pkg.LogOff(v_act);
END;
/

exit;
