PROMPT Please enter host name and menu item position

WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
	v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID;
	v_act_id				SECURITY.SECURITY_PKG.T_ACT_ID;

	-- groups
	v_groups_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_reg_users_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_admins_sid			SECURITY.SECURITY_PKG.T_SID_ID;
    v_client_admins_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_superadmins_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_t_admin_group_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_t_man_group_sid		SECURITY.SECURITY_PKG.T_SID_ID;

	-- role
	v_role_sid				SECURITY.SECURITY_PKG.T_SID_ID;

	-- menu
	v_root_menu_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_setup_menu_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_menu_training			SECURITY.SECURITY_PKG.T_SID_ID;
	v_menu_training_admin	SECURITY.SECURITY_PKG.T_SID_ID;
	v_menu_item				SECURITY.SECURITY_PKG.T_SID_ID;

	-- web resources
	v_www_root 				SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_csr_site			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_schema			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_schema_new		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training 			SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_cr 		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_myt		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_t		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_c		SECURITY.SECURITY_PKG.T_SID_ID;
	v_www_training_cs		SECURITY.SECURITY_PKG.T_SID_ID;

	v_capability_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_calendar_sid			SECURITY.SECURITY_PKG.T_SID_ID;
	v_flow_root_sid			SECURITY.SECURITY_PKG.T_SID_ID;
BEGIN
	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('START ENABLE TRAINING');
	-----------------------------------------------------------------------------------------------
	security.user_pkg.logonadmin('&&host');

	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;

	BEGIN
		INSERT INTO csr.training_options (app_sid)
			 VALUES (SYS_CONTEXT('SECURITY','APP'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('GROUPS');
	-----------------------------------------------------------------------------------------------
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_client_admins_sid     := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_admins_sid 			:= security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'BuiltIn/Administrators');
	v_superadmins_sid 		:= security.securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');

	DBMS_OUTPUT.PUT_LINE('create training administrator group');
	BEGIN
		v_t_admin_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Training Administrator');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			DBMS_OUTPUT.PUT_LINE('Create empty group, add admins and super admins');
			security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Training Administrator', security.class_pkg.GetClassId('CSRUserGroup'), v_t_admin_group_sid);
			security.group_pkg.DeleteAllMembers(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin));
			security.group_pkg.AddMember(v_act_id, v_superadmins_sid, v_t_admin_group_sid);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_t_admin_group_sid);

			DBMS_OUTPUT.PUT_LINE('Clear permissions, add admins and super admins');
			security.securableObject_pkg.ClearFlag(v_act_id, v_t_admin_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	DBMS_OUTPUT.PUT_LINE('create training manager group');
	BEGIN
		v_t_man_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Training Manager');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			DBMS_OUTPUT.PUT_LINE('Create empty group, add admins and super admins');
			security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Training Manager', security.class_pkg.GetClassId('CSRUserGroup'), v_t_man_group_sid);
			security.group_pkg.DeleteAllMembers(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin));
			security.group_pkg.AddMember(v_act_id, v_superadmins_sid, v_t_admin_group_sid);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_t_admin_group_sid);

			DBMS_OUTPUT.PUT_LINE('Clear permissions, add admins and super admins');
			security.securableObject_pkg.ClearFlag(v_act_id, v_t_admin_group_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_t_admin_group_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('ROLES');
	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('create training admin role');
	BEGIN
		v_t_man_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Training Admin');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND	THEN
			csr.role_pkg.SetRole(v_act_id, v_app_sid, 'Training Admin', 'TRAINING_ADMIN', v_role_sid);

			DBMS_OUTPUT.PUT_LINE('Clear permissions, add admins and super admins');
			security.securableObject_pkg.ClearFlag(v_act_id, v_role_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid));
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_role_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_client_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('MENU ITEMS');
	-----------------------------------------------------------------------------------------------
	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');

	BEGIN
		v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'setup');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'admin');
	END;

	DBMS_OUTPUT.PUT_LINE('Add to top menu : Training');
	security.menu_pkg.CreateMenu(v_act_id, v_root_menu_sid, 'csr_training', 'Training', '/csr/site/training/myTraining/myTraining.acds', &&menu_position, null, v_menu_training);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_training, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training, 'training_admin', 'Training Admin', '/csr/site/training/course/courseList.acds', 4, null, v_menu_training_admin);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_training_admin, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_training_admin), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Course Schedules');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_course_schedules', 'MANAGE COURSE SCHEUDLES', '/csr/site/training/courseSchedule/courseSchedule.acds', 6, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Course Types');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_course_type', 'MANAGE COURSE TYPES', '/csr/site/training/courseType/courseType.acds', 8, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Courses');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_courses', 'MANAGE COURSES', '/csr/site/training/course/courseList.acds', 5, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Places');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_places', 'MANAGE PLACES', '/csr/site/schema/new/places.acds', 9, null, v_menu_item);
	DBMS_OUTPUT.PUT_LINE('Add sub menu : Training Admin/Manage Trainers');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training_admin, 'training_trainer', 'MANAGE TRAINERS', '/csr/site/training/trainer/trainer.acds', 7, null, v_menu_item);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : My Learning');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training, 'training_my_training', 'My Learning', '/csr/site/training/myTraining/myTraining.acds', 1, null, v_menu_item);

	DBMS_OUTPUT.PUT_LINE('Add sub menu : Employee Directory');
	security.menu_pkg.CreateMenu(v_act_id, v_menu_training, 'training_requests', 'Employee Directory', '/csr/site/training/courseRequests/courseRequests.acds', 2, null, v_menu_item);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_man_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.menu_pkg.CreateMenu(v_act_id, v_setup_menu_sid, 'user_rel_types', 'User relationship types', '/csr/site/schema/new/userRelationshipTypes.acds', 21, null, v_menu_item);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_item, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	security.menu_pkg.CreateMenu(v_act_id, v_setup_menu_sid, 'job_functions', 'Job functions', '/csr/site/schema/new/jobFunctions.acds', 22, null, v_menu_item);
	security.securableObject_pkg.ClearFlag(v_act_id, v_menu_item, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACES(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item));
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_item), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('WEB RESOURCES');
	-----------------------------------------------------------------------------------------------
	v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'csr/site');

	BEGIN
		v_www_training := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'training');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'training', v_www_training);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Inherit for ''training/myTraining''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'myTraining', v_www_training_myt);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_myt), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_myt), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_myt), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Managers (all) for ''training/courseRequests''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'courseRequests', v_www_training_cr);
			security.securableObject_pkg.ClearFlag(v_act_id, v_www_training_cr, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cr), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cr), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_man_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cr), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) and Registered Users (read only) for ''training/course''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'course', v_www_training_c);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_c), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_c), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_c), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) and Registered Users (read only) for ''training/courseSchedule''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'courseSchedule', v_www_training_cs);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cs), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cs), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_cs), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) for ''training/trainer''');
			security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_training, 'trainer', v_www_training_t);
			security.securableObject_pkg.ClearFlag(v_act_id, v_www_training_t, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_t), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_t), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training_t), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) for ''schema''');
			BEGIN
				v_www_schema := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'schema');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'schema', v_www_schema);
					security.securableObject_pkg.ClearFlag(v_act_id, v_www_schema, security.security_pkg.SOFLAG_INHERIT_DACL);
					security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema), v_reg_users_sid);
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			END;

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			DBMS_OUTPUT.PUT_LINE('Training Administrators (all) for ''schema/new''');
			BEGIN
				v_www_schema_new := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_schema, 'new');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_schema, 'new', v_www_schema_new);
					security.securableObject_pkg.ClearFlag(v_act_id, v_www_schema_new, security.security_pkg.SOFLAG_INHERIT_DACL);
					security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema_new), v_reg_users_sid);
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema_new), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			END;

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_schema_new), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	DBMS_OUTPUT.PUT_LINE('don''t inherit');
	security.securableObject_pkg.ClearFlag(v_act_id, v_www_training, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), security.security_pkg.SID_BUILTIN_EVERYONE);
	security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), v_admins_sid);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_training), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('CAPABILITIES');
	-----------------------------------------------------------------------------------------------
	BEGIN
		csr.csr_data_pkg.enablecapability('Edit user relationships');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Edit user relationships');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr.csr_data_pkg.enablecapability('Edit user job functions');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Edit user job functions');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr.csr_data_pkg.enablecapability('Can edit course details');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Can edit course details');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr.csr_data_pkg.enablecapability('Can edit course schedule');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Can edit course schedule');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		csr.csr_data_pkg.enablecapability('Can manage course requests');
		v_capability_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Can manage course requests');
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_admin_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_capability_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_t_man_group_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('PLUGIN');
	-----------------------------------------------------------------------------------------------
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, app_sid, details, preview_image_path, tab_sid, form_path, group_key, control_lookup_keys)
		VALUES (
			csr.plugin_id_seq.NEXTVAL,
			(SELECT plugin_type_id FROM csr.plugin_type WHERE description = 'Calendar'),
			'Course schedules',
			'/csr/shared/calendar/includes/training.js',
			'Credit360.Calendars.Training',
			'Credit360.Plugins.PluginDto',
			NULL, NULL, NULL, NULL, NULL, NULL, NULL
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('CALENDAR');
	-----------------------------------------------------------------------------------------------
	BEGIN
		csr.calendar_pkg.RegisterCalendar(
			'courseSchedules',
			'/csr/shared/calendar/includes/training.js',
			'Credit360.Calendars.Training',
			'Course schedules',
			1, -- Global
			0, -- not teamrooms
			0, -- not initiatives
			'Credit360.Plugins.PluginDto',
			v_calendar_sid
		);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_calendar_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		BEGIN
			INSERT INTO csr.training_options (app_sid, geo_map_sid) VALUES (v_app_sid, v_calendar_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.training_options
				   SET calendar_sid = v_calendar_sid
				   WHERE app_sid = v_app_sid;
		END;
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('WORKFLOW');
	-----------------------------------------------------------------------------------------------
	BEGIN
		INSERT INTO CSR.CUSTOMER_FLOW_ALERT_CLASS (APP_SID, FLOW_ALERT_CLASS)
		VALUES (v_app_sid, 'training');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- it's in DB already
			NULL;
	END;

	DECLARE
		v_workflow_sid			security.security_pkg.T_SID_ID;
		v_complete_xml			CLOB;
		v_s0					security.security_pkg.T_SID_ID;
		v_s1					security.security_pkg.T_SID_ID;
		v_s2					security.security_pkg.T_SID_ID;
		v_s3					security.security_pkg.T_SID_ID;
		v_s4					security.security_pkg.T_SID_ID;
		v_s5					security.security_pkg.T_SID_ID;
		v_s6					security.security_pkg.T_SID_ID;
		v_s7					security.security_pkg.T_SID_ID;
		v_s8					security.security_pkg.T_SID_ID;
		v_xml_p1				CLOB;
		v_str					VARCHAR2(2000);
	BEGIN
		BEGIN
			DBMS_OUTPUT.PUT_LINE('Find workflow');
			v_workflow_sid := security.securableobject_pkg.getsidfrompath(v_act_id, v_app_sid, 'Workflows/Training Workflow');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('create our workflow');
				csr.flow_pkg.CreateFlow(
					in_label			=> 'Training Workflow',
					in_parent_sid		=> v_flow_root_sid,
					in_flow_alert_class	=> 'training',
					out_flow_sid		=> v_workflow_sid
				);
		END;

		-- Get CMS Tab Sids.

		-- Create alert templates.

		-- Get/Create roles.

		-- Get/Create states.

		DBMS_OUTPUT.PUT_LINE('Get/Create States and store vals here so we don''t end up using different IDs if the place-holders are in different workflow XML chunks.');
		v_s0 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'DRAFT'), csr.flow_pkg.GetNextStateID);
		v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE_REQUESTED'), csr.flow_pkg.GetNextStateID);
		v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE_INVITED'), csr.flow_pkg.GetNextStateID);
		v_s3 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CONFIRMED'), csr.flow_pkg.GetNextStateID);
		v_s4 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE_DECLINED'), csr.flow_pkg.GetNextStateID);
		v_s5 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_ATTENDED'), csr.flow_pkg.GetNextStateID);
		v_s6 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_MISSED'), csr.flow_pkg.GetNextStateID);
		v_s7 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_PASSED'), csr.flow_pkg.GetNextStateID);
		v_s8 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_FAILED'), csr.flow_pkg.GetNextStateID);

		v_xml_p1 := '<';
		v_str := UNISTR('flow label="Training workflow" cmsTabSid="" default-state-id="$S0$" flow-alert-class="training"><state id="$S0$" label="Draft" pos="0" final="0" colour="" lookup-key="DRAFT"><attributes x="228.2" y="893" /><transition flow-state-transition-id="782" to-state-id="$S2$" verb="Invite" helper-sp="" lookup-key="INVITE" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="" /><transition flow-state-transition-id="783" to-state-id="$S1$" verb="Request" helper-sp="" lookup-key="USER_REQUEST" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="" /></state><state id="$S1$" label="Requested" pos="1" final="0" colour="" lookup-key="PRE_REQUESTED"><attributes x="338.2" y="1081" /><transition flow-state-transition-id="703" to-state-id="$S4$" verb="Decline" helper-sp="" lookup-key="DECLINE" ask-for-comment="required" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_c');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR('ross.gif" /><transition flow-state-transition-id="704" to-state-id="$S3$" verb="Approve" helper-sp="" lookup-key="APPROVE_REQUEST" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif" /></state><state id="$S2$" label="Invited" pos="2" final="0" colour="" lookup-key="PRE_INVITED"><attributes x="331.2" y="697" /><transition flow-state-transition-id="701" to-state-id="$S3$" verb="Confirm" helper-sp="" lookup-key="USER_CONFIRM_INVITE" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif" /><transition flow-state-transition-id="702" to-state-id="$S4$" verb="Decline" helper-sp="" lookup-key="USER_DECLINE" ask-for-comment="required" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_cross.gif" /></state><state id="$S3$" label="Confirmed" pos="3" final="0" colour="" lookup-key="CONFIRMED"><attributes x="651.2"');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR(' y="839" /><transition flow-state-transition-id="705" to-state-id="$S5$" verb="Confirm attendance" helper-sp="" lookup-key="CONFIRM_ATTENDANCE" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif" /><transition flow-state-transition-id="706" to-state-id="$S6$" verb="Confirm missed" helper-sp="" lookup-key="CONFIRM_MISSED" ask-for-comment="required" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_cross.gif" /><transition flow-state-transition-id="722" to-state-id="$S4$" verb="Cancel" helper-sp="" lookup-key="CANCEL" ask-for-comment="required" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_cross.gif" /></state><state id="$S4$" label="Declined" pos="4" final="0" colour="" lookup-key="PRE_DECLINED"><attributes x="650.2" y="1088" /><transition flow-state-transition-id="723" to-state-id="$S3$" verb="Approve" helper-sp="" lookup-ke');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR('y="APPROVE_DECLINED" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif" /><transition flow-state-transition-id="724" to-state-id="$S2$" verb="Resend" helper-sp="" lookup-key="RESEND_INVITATION" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_redo.png" /></state><state id="$S5$" label="Attended" pos="5" final="0" colour="" lookup-key="POST_ATTENDED"><attributes x="956.2" y="841" /><transition flow-state-transition-id="707" to-state-id="$S7$" verb="Confirm pass" helper-sp="" lookup-key="CONFIRM_PASSED" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif" /><transition flow-state-transition-id="715" to-state-id="$S8$" verb="Confirm fail" helper-sp="" lookup-key="CONFIRM_FAIL" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-ic');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR('on-path="/fp/shared/images/ic_cross.gif" /></state><state id="$S6$" label="Missed" pos="6" final="1" colour="" lookup-key="POST_MISSED"><attributes x="650.2" y="697" /></state><state id="$S7$" label="Passed" pos="7" final="1" colour="" lookup-key="POST_PASSED"><attributes x="1241.2" y="953" /></state><state id="$S8$" label="Failed" pos="8" final="1" colour="" lookup-key="POST_FAILED"><attributes x="1244.2" y="745" /></state></flow>');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);

		-- #### Replace place-holders in XML chunk. ####

		-- Alerts

		-- Roles

		DBMS_OUTPUT.PUT_LINE('States');
		v_xml_p1 := REPLACE(v_xml_p1, '$S0$', v_s0);
		v_xml_p1 := REPLACE(v_xml_p1, '$S1$', v_s1);
		v_xml_p1 := REPLACE(v_xml_p1, '$S2$', v_s2);
		v_xml_p1 := REPLACE(v_xml_p1, '$S3$', v_s3);
		v_xml_p1 := REPLACE(v_xml_p1, '$S4$', v_s4);
		v_xml_p1 := REPLACE(v_xml_p1, '$S5$', v_s5);
		v_xml_p1 := REPLACE(v_xml_p1, '$S6$', v_s6);
		v_xml_p1 := REPLACE(v_xml_p1, '$S7$', v_s7);
		v_xml_p1 := REPLACE(v_xml_p1, '$S8$', v_s8);

		dbms_lob.createtemporary(v_complete_xml, true);

		v_complete_xml := v_xml_p1;

		csr.flow_pkg.SetFlowFromXml(v_workflow_sid, XMLType(v_complete_xml));
		dbms_lob.freetemporary (v_complete_xml);

		BEGIN
			INSERT INTO csr.training_options (app_sid, flow_sid) VALUES (v_app_sid, v_workflow_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.training_options
				   SET flow_sid = v_workflow_sid
				 WHERE app_sid = v_app_sid;
		END;
	END;

	-----------------------------------------------------------------------------------------------
	DBMS_OUTPUT.PUT_LINE('FINISH ENABLE TRAINING');
	-----------------------------------------------------------------------------------------------

	COMMIT;
END;
/

EXIT
