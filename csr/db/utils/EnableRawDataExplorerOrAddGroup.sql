PROMPT This adds read access to the dataviews SO and read access to the DataExplorer5 wwwroot to the group provided below
PROMPT Leave group blank to just add raw data explorer for super admins
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_raw_dacl					Security_Pkg.T_ACL_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_grp_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_raw					security.security_pkg.T_SID_ID;
	-- web resources	
	v_www_explr					security.security_pkg.T_SID_ID;
	v_count						NUMBER;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&host');
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	-- read groups
	v_groups_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
    v_grp_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, '&group');

	/* ADD MENU ITEM */
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/analysis'),
		'csr_rawexplorer', 'Raw Data Explorer', '/csr/site/dataExplorer5/dataNavigator/rawExplorer.acds', 8, null, v_menu_raw);
		--Remove Inherited
		security.securableobject_pkg.ClearFlag(v_act_id, v_menu_raw, security.security_pkg.SOFLAG_INHERIT_DACL); 
		v_raw_dacl := security.acl_pkg.GetDACLIDForSID(v_menu_raw);    
		DELETE FROM security.ACL
			  WHERE ACL_ID = v_raw_dacl
				AND bitand(ACE_FLAGS, Security_Pkg.ACE_FLAG_INHERITED) != 0;
		--Add SuperAdmins and Builtin Administrator
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_raw), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.SID_ROOT, 'csr/SuperAdmins'), 
			security.security_pkg.PERMISSION_STANDARD_ALL);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_raw), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.SID_ROOT, 'builtin/Administrators'), 
			security.security_pkg.PERMISSION_STANDARD_ALL);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_raw := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP,'menu/analysis/csr_rawexplorer');
	END;
	
	--If they didn't choose a group ignore.
	IF v_grp_sid != v_groups_sid THEN
		-- add group to menu option
		SELECT COUNT(*)
		  INTO v_count
		  FROM security.ACL
		 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_menu_raw)
		   AND sid_id = v_grp_sid
		   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
		   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
		   
		IF v_count = 0 THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_raw), -1, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, 
				v_grp_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END IF;				
		--
		/* WEB RESOURCE */
		BEGIN
			v_www_explr := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/dataExplorer5');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(
					v_act_id, 
					securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot'),
					securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site'), 
					'dataExplorer5', 
					v_www_explr
				);
		END;
				
		-- add grp to web resource
		SELECT COUNT(*)
		  INTO v_count
		  FROM security.ACL
		 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_www_explr)
		   AND sid_id = v_grp_sid
		   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
		   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
		   
		IF v_count = 0 THEN
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_explr), -1, 
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, 
				v_grp_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END IF;
		
		-- add grp to dataviews
		SELECT COUNT(*)
		  INTO v_count
		  FROM security.ACL
		 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Dataviews'))
		   AND sid_id = v_grp_sid
		   AND ace_type = security.security_pkg.ACE_TYPE_ALLOW
		   AND permission_set = security.security_pkg.PERMISSION_STANDARD_READ;
		   
		IF v_count = 0 THEN
			security.acl_pkg.AddACE(v_act_id, 
				security.acl_pkg.GetDACLIDForSID(security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Dataviews')), 
				-1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
				v_grp_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END IF;
	END IF;	
	--
	COMMIT;
END;
/
