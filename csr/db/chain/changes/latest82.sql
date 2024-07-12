define version=82
@update_header

DECLARE
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_www_sid				security_pkg.T_SID_ID;
	v_www_csr_site_sid		security_pkg.T_SID_ID;
	v_csr_site_alerts_sid   security_pkg.T_SID_ID;
	v_alerts_mergeFld_sid   security_pkg.T_SID_ID;
	v_reg_users_sid			security_pkg.T_SID_ID;
	v_group_sid				security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT * FROM v$chain_host
	) LOOP
	
		user_pkg.logonadmin(r.host);
		
		v_act_id := security_pkg.GetAct;
		v_app_sid := security_pkg.GetApp;
		v_www_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
		v_www_csr_site_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_sid, 'csr/site');
		v_group_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
		v_reg_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'RegisteredUsers');
		v_csr_site_alerts_sid := 0;

		BEGIN
			v_csr_site_alerts_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_sid, 'alerts');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN NULL;
		END;
		
		IF v_csr_site_alerts_sid<>0 THEN
			BEGIN
				v_alerts_mergeFld_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_alerts_sid, 'renderMergeField.ashx');
			EXCEPTION 
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_alerts_sid, 'renderMergeField.ashx', v_alerts_mergeFld_sid);	

					-- give the RegisteredUsers group READ permission on the resource
					acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_alerts_mergeFld_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
			END;
		END IF;
		
	END LOOP;
END;
/

@update_tail