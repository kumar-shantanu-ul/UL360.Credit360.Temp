PROMPT please enter: host

DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;

	v_group_sid				security.security_pkg.T_SID_ID;
	v_app_admins_sid		security.security_pkg.T_SID_ID;
	v_chain_admins_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid			security.security_pkg.T_SID_ID;

	v_admin_menu			security.security_pkg.T_SID_ID;
	v_tc_menu				security.security_pkg.T_SID_ID;
	
	v_www_sid				security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_www_csr_site_profile	security.security_pkg.T_SID_ID;	
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	
	v_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_app_admins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Administrators');
	
	BEGIN
		v_chain_admins_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
			NULL;
	END;
	
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, 'RegisteredUsers');
	
	v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin');

	BEGIN
		v_tc_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_profile_terms');	
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_profile_terms',  'Terms and conditions',  '/csr/site/profile/terms.acds',  0, null, v_tc_menu);

				-- add chain admins, normal admins already set by default
				IF v_chain_admins_sid IS NOT NULL THEN
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_tc_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
						security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_chain_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				END IF;
	END;
	
	--security.acl_pkg.PropogateACEs(v_act_id, v_tc_menu);
	
	-- web resource for csr/site/profile if needed (reg. users+admins+chain admins)
	/*
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');	
	BEGIN
		v_www_csr_site_profile := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'profile');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site, 'profile', v_www_csr_site_profile);

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_profile), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
				
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_profile), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_app_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);					
				
			IF v_chain_admins_sid IS NOT NULL THEN
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_profile), -1, security.security_pkg.ACE_TYPE_ALLOW, 
					security.security_pkg.ACE_FLAG_DEFAULT, v_chain_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			END IF;
				
	END;
	*/
END;
/
exit
