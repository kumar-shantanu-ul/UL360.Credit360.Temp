PROMPT please enter: host

DECLARE
	v_menu_help			security.security_pkg.T_SID_ID;
	v_act				security.security_pkg.T_ACT_ID;
	v_admins			security.security_pkg.T_SID_ID;
	v_reg_users			security.security_pkg.T_SID_ID;
	-- web resources	
	v_wwwroot_sid		security.security_pkg.T_SID_ID;
	v_csr_site_sid 		security.security_pkg.T_SID_ID;
	v_newhelp_sid 		security.security_pkg.T_SID_ID;
	v_editor_sid 		security.security_pkg.T_SID_ID;
	-- help
    v_host  			csr.customer.host%TYPE;
    v_id   				number(10);
BEGIN
	-- log on
	user_pkg.LogonAdmin('&&1');	
	v_act       := security.security_pkg.getACT;
	v_admins    := security.securableobject_pkg.GetSidFromPath(v_act, security.security_pkg.GetApp, 'Groups/Administrators');
	v_reg_users := security.securableobject_pkg.GetSidFromPath(v_act, security.security_pkg.GetApp, 'Groups/RegisteredUsers');
    --
	FOR r IN (SELECT 1
				FROM all_tables
			   WHERE owner = 'OWL' and table_name = 'CLIENT_MODULE') LOOP
		EXECUTE IMMEDIATE 
			'INSERT INTO owl.CLIENT_MODULE (client_module_id, client_sid, credit_module_id, enabled, date_enabled)'||CHR(10)||
				 'SELECT cms.item_id_seq.nextval, security.security_pkg.getApp, credit_module_id, 1, SYSDATE'||CHR(10)||
				   'FROM owl.credit_module'||CHR(10)||
				  'WHERE lookup_Key = ''HELP'' AND EXISTS ('||CHR(10)||
					'SELECT null FROM owl.owl_client WHERE client_sid = security.security_pkg.getApp'||CHR(10)||
				')';
	END LOOP;
	  
	-- will be admins by default since we're under the admin menu....
	security.menu_pkg.CreateMenu(v_act, securableobject_pkg.GetSIDFromPath(v_act, security.security_pkg.GetApp, 'menu/admin'),
		'csr_new_help', --'csr_help_viewhelp', 
		'Help editor', '/csr/site/newHelp/editor/editor.acds', 20, null, v_menu_help);
		
	-- web resources
	v_wwwroot_sid   := security.securableobject_pkg.GetSIDFromPath(v_act, security.security_pkg.getApp, 'wwwroot');
	v_csr_site_sid  := security.securableobject_pkg.GetSIDFromPath(v_act, v_wwwroot_sid, 'csr/site');
		
	BEGIN
		security.web_pkg.CreateResource(v_act, v_wwwroot_sid, v_csr_site_sid, 'newhelp', security.Security_Pkg.SO_WEB_RESOURCE, null, v_newhelp_sid);
		security.acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_newhelp_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_reg_users, security.security_pkg.PERMISSION_STANDARD_READ);		
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_newhelp_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_csr_site_sid, 'newhelp');
	END;
	
	BEGIN
		security.web_pkg.CreateResource(v_act, v_wwwroot_sid, v_newhelp_sid, 'editor', security.Security_Pkg.SO_WEB_RESOURCE, null, v_editor_sid);
		security.securableobject_pkg.ClearFlag(v_act, v_editor_sid, security.security_pkg.SOFLAG_INHERIT_DACL); 
		security.acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_editor_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
			v_admins, security.security_pkg.PERMISSION_STANDARD_READ);	
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_editor_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_newhelp_sid, 'editor');
	END;
	
	security.acl_pkg.PropogateACEs(v_act, v_newhelp_sid);
	
	-- custom language for host... (needs fixing so that it creates objects under customer?)
	v_id := csr.help_pkg.GetDefaultLangId(security.security_pkg.getapp);
	IF v_id = 1 THEN
		SELECT host 
		  INTO v_host 
		  FROM csr.customer 
		 WHERE app_sid = security.security_pkg.getapp;	
		UPDATE csr.customer_help_lang 
		   SET is_default = 0 
		 WHERE help_lang_id = v_id;
		csr.help_pkg.AddLanguage(v_act, 1, 'English ('||v_host||')', v_id);
		INSERT INTO csr.customer_help_lang (help_lang_id, is_default) VALUES (v_id, 1);
	END IF;
    
	COMMIT;
END;
/
exit
