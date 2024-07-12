
DECLARE
	v_approver_role_sid			security.security_pkg.T_SID_ID;
	v_admin_role_sid			security.security_pkg.T_SID_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_initiatives_users_sid		security.security_pkg.T_SID_ID;
	v_class_id					security.security_pkg.T_CLASS_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
	v_menu_initiatives_sid		security.security_pkg.T_SID_ID;
	v_myinitiatives				security.security_pkg.T_SID_ID;
	v_create					security.security_pkg.T_SID_ID;
	v_timeline					security.security_pkg.T_SID_ID;
	v_reports					security.security_pkg.T_SID_ID;
	v_import					security.security_pkg.T_SID_ID;
	v_issues					security.security_pkg.T_SID_ID;
	v_actions_tree_sid			security.security_pkg.T_SID_ID;
	v_region_tree_sid			security.security_pkg.T_SID_ID;
	v_ind_tree_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	-- Insert default customer options
	UPDATE actions.customer_options 
	   SET initiative_end_dtm = DATE '2014-01-01',
	   	   region_picker_config = '[]',
	   	   use_standard_region_picker = 1,
	   	   gantt_period_colour = 1,
	   	   initiative_hide_ongoing_radio = 1,
	   	   my_initiatives_options = '
	   	   	{
			  completeDlgShowDates: true, 
			  completeDlgShowMetrics: false, 
			  showStatus: true,
			  showAddComment: true, 
			  showStateChange: true, 
			  showProgressUpdate: true,
			  enableMetricDetails: false,
			  createPage:"/csr/site/actions2/initiatives/createFull.acds"
			}'
	 WHERE app_sid = security.security_pkg.GetApp;
	
	-- Add roles
	csr.role_pkg.SetRole(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Initiative approver', v_approver_role_sid);
	csr.role_pkg.SetRole(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Initiative administrator', v_admin_role_sid);
	
	-- Get standard groups
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Groups');
    v_admins_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_groups_sid, 'Administrators');
	
	-- Create the initiatives users group if required
	BEGIN
		v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
		security.group_pkg.CreateGroupWithClass(security.security_pkg.GetACT, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Initiatives users', v_class_id, v_initiatives_users_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_initiatives_users_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_groups_sid, 'Initiatives users');
	END;
    
    -- make admins members of initiatives users
    security.group_pkg.AddMember(security.security_pkg.GetACT, v_admins_sid, v_initiatives_users_sid);
	
	-- Allow initiatives users to write to all actions projects
	v_actions_tree_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Actions');
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_actions_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_initiatives_users_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_actions_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_approver_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_actions_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_actions_tree_sid);
	
	-- Currently initiatives user need write permission of the region tree
	v_region_tree_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Regions');
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_region_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_initiatives_users_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_region_tree_sid);
	
	-- Currently initiatives user need write permission of the indicator tree
	v_ind_tree_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Indicators');
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_ind_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_initiatives_users_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_ind_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_approver_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_ind_tree_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_ind_tree_sid);
	
	-- Add initiatives menus
	v_menu_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu');
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_sid, 'initiatives', 'Initiatives', '/csr/site/actions2/Initiatives/myInitiatives.acds', 6, null, v_menu_initiatives_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_initiatives_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP,'menu/initiatives');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_myinitiatives', 'My Initiatives', '/csr/site/actions2/initiatives/myInitiatives.acds', 1, null, v_myinitiatives);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_myinitiatives := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_myinitiatives');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_create', 'New Initiative', '/csr/site/actions2/initiatives/createFull.acds', 2, null, v_create);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_create := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_create');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_timeline', 'Timeline', '/csr/site/actions2/initiatives/timeline.acds', 3, null, v_timeline);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_timeline := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_timeline');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_periodic', 'Periodic report', '/csr/site/actions2/initiatives/periodicReport/periodicReport.acds', 4, null, v_reports);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_reports := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_periodic');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_reports', 'Report', '/csr/site/actions2/initiatives/reporting/explorer.acds', 5, null, v_reports);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_reports := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_reports');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'csr_issue', 'Issues', '/csr/site/issues/issueList.acds', 6, null, v_issues);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_issues := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/csr_issue');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_import', 'Import initiatives', '/csr/site/actions2/import/actionsImport.acds', 7, null, v_import);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_import := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_import');
	END;
	BEGIN
		security.menu_pkg.CreateMenu(security.security_pkg.GetACT, v_menu_initiatives_sid, 'initiatives_project_role', 'Project roles', '/csr/site/actions2/initiatives/admin/projectRole.acds', 8, null, v_import);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_import := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'menu/initiatives/initiatives_project_role');
	END;
	
	-- Add initiatives users to top level menu option (inheritable)
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_initiatives_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_approver_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(security.security_pkg.GetACT, security.acl_pkg.GetDACLIDForSID(v_menu_initiatives_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
		security.security_pkg.ACE_FLAG_DEFAULT, v_admin_role_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.PropogateACEs(security.security_pkg.GetACT, v_menu_initiatives_sid);

	-- Add submitted, approved and rejected alert types to client
	--INSERT INTO csr.customer_alert_type (app_sid, alert_type_id) VALUES (security.security_pkg.GetAPP, 2000);
	--INSERT INTO csr.customer_alert_type (app_sid, alert_type_id) VALUES (security.security_pkg.GetAPP, 2001);
	--INSERT INTO csr.customer_alert_type (app_sid, alert_type_id) VALUES (security.security_pkg.GetAPP, 2002);
	
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT security.security_pkg.getapp, csr.customer_alert_type_id_seq.nextval, std_alert_type_id 
		  FROM csr.std_alert_type 
		 WHERE std_alert_type_id = 2014;
		 
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT security.security_pkg.getapp, csr.customer_alert_type_id_seq.nextval, std_alert_type_id 
		  FROM csr.std_alert_type 
		 WHERE std_alert_type_id = 2015;
		 
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT security.security_pkg.getapp, csr.customer_alert_type_id_seq.nextval, std_alert_type_id 
		  FROM csr.std_alert_type 
		 WHERE std_alert_type_id = 2016;
		 
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT security.security_pkg.getapp, csr.customer_alert_type_id_seq.nextval, std_alert_type_id 
		  FROM csr.std_alert_type 
		 WHERE std_alert_type_id = 2019;	
END;
/
