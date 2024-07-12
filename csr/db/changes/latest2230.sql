-- Please update version.sql too -- this keeps clean builds in sync
define version=2230
@update_header

DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_reg_users 					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;
	v_www_root 						security.security_pkg.T_SID_ID;
	v_www_csr_site 					security.security_pkg.T_SID_ID;
	v_www_csr_site_flow				security.security_pkg.T_SID_ID;
	v_www_csr_site_flow_admin		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer
	) LOOP
		BEGIN
			v_reg_users := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'Groups/RegisteredUsers');
			v_admins := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'Groups/Administrators');
			
			/*** WEB RESOURCE ***/
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
			
			-- /csr/site/flow
			BEGIN
				v_www_csr_site_flow := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site/flow');	
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					BEGIN
						v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site');
						security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'flow', v_www_csr_site_flow);
						security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_flow), -1, security.security_pkg.ACE_TYPE_ALLOW, 	
							security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security.security_pkg.PERMISSION_STANDARD_READ);
					EXCEPTION
						WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
							NULL; -- Assume that if they don't have /csr/site then they don't need /csr/site/flow
					END;
			END;
			
			BEGIN
				v_www_csr_site_flow_admin := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site/flow/admin');	
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					BEGIN
						v_www_csr_site_flow := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot/csr/site/flow');
						security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site_flow, 'admin', v_www_csr_site_flow_admin);
						security.securableobject_pkg.ClearFlag(v_act_id, v_www_csr_site_flow_admin, security.security_pkg.SOFLAG_INHERIT_DACL);	
							security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_flow_admin));	
						security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_flow_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, 	
							security.security_pkg.ACE_FLAG_DEFAULT, v_admins, security.security_pkg.PERMISSION_STANDARD_READ);
					EXCEPTION
						WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
							NULL;
					END;
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/

@update_tail