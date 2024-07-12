DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_project_class_id security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- create actions classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'ActionsProject', 'actions.project_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('ActionsProject');
	END;
	BEGIN	
		-- if you can write to the container, then you can do everything to projects
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_ADD_COMMENT, 'Add comments to tasks');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_ADD_COMMENT);
		--
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_UPDATE_PROGRESS, 'Update progress');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_UPDATE_PROGRESS);
		--
		-- the logic of the app is that having UPDATE_PROGRESS implies UPDATE_PROGRESS_XML - we might want to alter the task_body code so that this isn't implicit?
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_UPDATE_PROGRESS_XML, 'Update progress text'); 
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_UPDATE_PROGRESS_XML);
		--
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_APPROVE_PROGRESS, 'Approve progress');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_APPROVE_PROGRESS);
		--
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_CHANGE_STATUS, 'Change status');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_CHANGE_STATUS);
		--
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_ASSIGN_USERS, 'Assign to other users');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_ASSIGN_USERS);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'ActionsTask', 'actions.task_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('ActionsTask');
	END;
	BEGIN	
		-- whatever you can do to the project, propagate to tasks (security maps it through automatically)
		--v_project_class_id:=security.class_pkg.GetClassId('ActionsProject');
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_ADD_COMMENT, 'Add comments to tasks');
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_UPDATE_PROGRESS, 'Update progress');
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_UPDATE_PROGRESS_XML, 'Update progress text');
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_APPROVE_PROGRESS, 'Approve progress');
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_CHANGE_STATUS, 'Change status');
		security.class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_ASSIGN_USERS, 'Assign to other users');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	security.user_pkg.LOGOFF(v_ACT);
END;
/
