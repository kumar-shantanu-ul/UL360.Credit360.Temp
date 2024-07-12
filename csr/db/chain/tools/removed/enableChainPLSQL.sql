/* WARNING: This PL/SQL block is pulled into scripts at the SQL*Plus level (via EnableChain.sql) as well as */
/* at the PL/SQL level (e.g. via \cvs\clients\chaindemo\db\chain\setup.sql), and so it absolutely must not  */
/* contain any SQL*Plus commands, including / (slash) to execute the block.                                 */
/* &&1 indicates a light setup 																				*/

DECLARE
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_setup_menus			BOOLEAN 			  DEFAULT UPPER('&&1') = 'Y';
	v_change_login_and_home	BOOLEAN 			  DEFAULT UPPER('&&1') = 'Y';
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'RegisteredUsers');
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Everyone');
	v_app_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Administrators');
	v_admins_sid			security_pkg.T_SID_ID; -- chain admins
	v_users_sid				security_pkg.T_SID_ID;
	v_user_container_sid	security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users');
	v_ucd_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_user_container_sid, 'UserCreatorDaemon');
	v_indicators_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Indicators');
	v_chain_sid				security_pkg.T_SID_ID;
	v_companies_sid			security_pkg.T_SID_ID;
	v_www_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_www_sid, 'csr/site');
	v_csr_site_chain_sid    security_pkg.T_SID_ID;
	v_csr_site_alerts_sid   security_pkg.T_SID_ID;
	v_chain_cards_sid 		security_pkg.T_SID_ID;
	v_chain_components_sid 	security_pkg.T_SID_ID;
	v_chain_public_sid 		security_pkg.T_SID_ID;
	v_alerts_mergeFld_sid   security_pkg.T_SID_ID;
	
	v_dacl_id    			security_Pkg.T_ACL_ID;
	
	v_menu  				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu'); 
	v_login_menu  			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_menu, 'login'); 
	v_logout_menu  			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_menu, 'logout'); 
	v_chain_menu			security_pkg.T_SID_ID;
	v_admin_menu			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
	v_new_menu				security_pkg.T_SID_ID;
	v_built_in				security_pkg.T_SID_ID;
	v_respondent			security_pkg.T_SID_ID;
BEGIN
	
	/**************************************************************************************
		CREATE GROUPS
	**************************************************************************************/
	BEGIN
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, v_group_sid, security_pkg.GROUP_TYPE_SECURITY, chain.chain_pkg.CHAIN_ADMIN_GROUP, v_admins_sid);

			-- give the group ALL permission on itself
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_admins_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
			
			-- give the group ALL permission on INDICATORS so that we can create users
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_indicators_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END;
	
	BEGIN
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_USER_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, v_group_sid, security_pkg.GROUP_TYPE_SECURITY, chain.chain_pkg.CHAIN_USER_GROUP, v_users_sid);

			-- give the group READ permission on itself
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_users_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
		
	/**************************************************************************************
		ADD OBJECTS TO GROUPS
	**************************************************************************************/
	-- add the Chain Administrators group to the Chain Users group
	group_pkg.AddMember(v_act_id, v_admins_sid, v_users_sid);
	
	-- add the Administrators group to the Chain Administrators group
	group_pkg.AddMember(v_act_id, v_app_admins_sid, v_admins_sid);
	
	-- add UserCreatorDaemon to the Chain Administratos group so that it can create companies and users
	group_pkg.AddMember(v_act_id, v_ucd_sid, v_admins_sid);
	
	
	
	/**************************************************************************************
		CREATE CONTAINERS
	**************************************************************************************/
	BEGIN
		v_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Chain', v_chain_sid);

			securableobject_pkg.SetFlags(v_act_id, v_chain_sid, 0);			
			
			security.ACL_Pkg.GetNewID(v_dacl_id);
			
			acl_pkg.AddACE(v_act_id, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);
			
			acl_pkg.SetDACL(v_act_id, v_chain_sid, v_dacl_id);
	END;
	
	BEGIN
		v_companies_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_chain_sid, 'Companies');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, v_chain_sid, security_pkg.SO_CONTAINER, 'Companies', v_companies_sid);
	END;	

	BEGIN
		v_built_in := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_chain_sid, 'BuiltIn');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND then
			securableobject_pkg.CreateSO(security_pkg.GetACT, v_chain_sid, class_pkg.GetClassID('Container'), 'BuiltIn', v_built_in);
	END;
	
	/**************************************************************************************
		CREATE BUILT IN DAEMON USER
	**************************************************************************************/

	BEGIN
		v_respondent := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_built_in, 'Invitation Respondent');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND then

			user_pkg.CreateUser(
				in_act_id						=> security_pkg.GetACT,
				in_parent_sid				=> v_built_in,
				in_login_name				=> 'Invitation Respondent',
				in_class_id					=> class_pkg.GetClassID('User'),
				in_account_expiry_enabled	=> 0,
				out_user_sid				=> v_respondent
			);

			-- we need to stuff this user into the csr user so that we can use it within chain as well
			INSERT INTO csr.csr_user
			(csr_user_sid, guid, user_name, friendly_name, send_alerts, show_portal_help, hidden)
			VALUES
			(v_respondent, user_pkg.GenerateAct, 'Invitation Respondent', 'Chain Invitation Respondent', 0, 0, 1);
			
			-- add the user to chain
			helper_pkg.AddUserToChain(v_respondent);
			
			-- grant all on the user container
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_user_container_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_ALL);	
	END;	
	
	/**************************************************************************************
		CREATE WEB RESOURCES
	**************************************************************************************/
	BEGIN
		v_csr_site_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_sid, 'chain');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_sid, 'chain', v_csr_site_chain_sid);	
			
			-- give the RegisteredUsers group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_csr_site_chain_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;				
			
	BEGIN
		v_chain_public_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'public');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'public', v_chain_public_sid);	
			
			-- give the Everyone group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_chain_public_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;				
	
	BEGIN
		v_chain_components_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'components');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'components', v_chain_components_sid);	

			-- give the Everyone group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_chain_components_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	BEGIN
		v_chain_cards_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_chain_sid, 'cards');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_chain_sid, 'cards', v_chain_cards_sid);	

			-- give the Everyone group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_chain_cards_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	v_csr_site_alerts_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_www_csr_site_sid, 'alerts');
	BEGIN
		v_alerts_mergeFld_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_alerts_sid, 'renderMergeField.ashx');
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_alerts_sid, 'renderMergeField.ashx', v_alerts_mergeFld_sid);	

			-- give the RegisteredUsers group READ permission on the resource
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_alerts_mergeFld_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	/**************************************************************************************
		CREATE MENUS
	**************************************************************************************/
	IF v_setup_menus THEN
		-- chain top level
		BEGIN
			v_chain_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_menu, 'chain',  'Chain',  '/csr/site/chain/dashboard.acds',  1, null, v_chain_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_chain_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- chain dashboard
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_dashboard');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_dashboard',  'Dashboard',  '/csr/site/chain/dashboard.acds',  102, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Actions
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_actions');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_actions',  'Activity browser',  '/csr/site/chain/activityBrowser.acds',  103, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Questionnaire Management
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_q_management');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_q_management',  'Questionnaires',  '/csr/site/chain/questionnaireManagement.acds',  104, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;


		-- Search for supplier
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_chain_menu, 'chain_supplier_search');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_chain_menu, 'chain_supplier_search',  'Supplier search',  '/csr/site/chain/supplierDetails.acds',  105, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Change my user details
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_my_details');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_my_details',  'My details',  '/csr/site/chain/myDetails.acds',  21, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- Change my company details
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_my_company');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_my_company',  'My company',  '/csr/site/chain/myCompany.acds',  22, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- News setup
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_news_setup');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_news_setup',  'Newsflash setup',  '/csr/site/chain/newsflash.acds',  23, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;
	
		-- dev page
		/*BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_dev_open_invites');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_dev_open_invites',  'DEV - Open Invitations',  '/csr/site/chain/dev/OpenInvitations.acds',  100, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_app_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;

		-- dev page
		BEGIN
			v_new_menu := securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_dev_manage_companies');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN 
				security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_dev_manage_companies',  'DEV - Manage Companies',  '/csr/site/chain/dev/ManageCompanies.acds',  101, null, v_new_menu);

				acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_menu), -1, security_pkg.ACE_TYPE_ALLOW, 
					security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_app_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
		END;*/
	END IF;
	
	/**************************************************************************************
			ALTER EXISTING SO ATTRIBUTES
	**************************************************************************************/

	IF v_change_login_and_home THEN
		security.menu_pkg.SetMenuAction(v_act_id, v_admin_menu, '/csr/site/chain/myDetails.acds');
		security.menu_pkg.SetMenuAction(v_act_id, v_login_menu, '/csr/site/chain/public/login.acds');
		security.menu_pkg.SetMenuAction(v_act_id, v_logout_menu, '/fp/aspen/public/logout.asp?page=%2fcsr%2fsite%2fchain%2fpublic%2flogin.acds%3floggedoff%3d1');
		security.securableobject_pkg.SetNamedStringAttribute(v_act_id, v_app_sid, 'logon-url', '/csr/site/chain/public/login.acds');
		security.securableobject_pkg.SetNamedStringAttribute(v_act_id, v_app_sid, 'default-url', '/csr/site/chain/dashboard.acds');
	END IF;
	
				
	/**************************************************************************************
			SET OPTIONS
	**************************************************************************************/
	-- update the self reg group unless it's already been set
	UPDATE csr.customer
	   SET self_reg_group_sid = v_reg_users_sid
	 WHERE app_Sid = security_pkg.GetApp
	   AND self_reg_group_sid IS NULL;
	
	-- ensure that self reg doesn't need approval
	UPDATE csr.customer
	   SET self_reg_needs_approval = 0
	 WHERE app_Sid = security_pkg.GetApp;
	
	BEGIN
		INSERT INTO chain.customer_options (app_sid) VALUES (v_app_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
	END;
	
	-- add the ucd to chain 
	chain.helper_pkg.AddUserToChain(v_ucd_sid);
	
	
	/**************************************************************************************
			MISC
	**************************************************************************************/
	
	-- this is required for rejecting invitations
	FOR s IN (
		SELECT v_user_container_sid sid_id FROM DUAL
		 UNION ALL
		SELECT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Trash') sid_id FROM DUAL
		 UNION ALL
		SELECT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'chain/companies') sid_id FROM DUAL
	) LOOP

		acl_pkg.AddACE(
			v_act_id, 
			acl_pkg.GetDACLIDForSID(s.sid_id), 
			security_pkg.ACL_INDEX_LAST, 
			security_pkg.ACE_TYPE_ALLOW, 
			security_pkg.ACE_FLAG_DEFAULT, 
			v_ucd_sid, 
			security_pkg.PERMISSION_STANDARD_ALL
		);	

		acl_pkg.PropogateACEs(v_act_id, s.sid_id);
	END LOOP;

END;

/* WARNING: This PL/SQL block is pulled into scripts at the SQL*Plus level (via EnableChain.sql) as well as */
/* at the PL/SQL level (e.g. via \cvs\clients\chaindemo\db\chain\setup.sql), and so it absolutely must not  */
/* contain any SQL*Plus commands, including / (slash) to execute the block.                                 */
