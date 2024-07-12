DECLARE
	v_project_class_id security_pkg.T_SID_ID;
	new_class_id 	security_pkg.T_SID_ID;
	v_act 		security_pkg.T_ACT_ID;
BEGIN	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
			new_class_id:=class_pkg.GetClassId('ActionsTask');	
	v_project_class_id:=class_pkg.GetClassId('ActionsProject');
		class_pkg.AddPermission(v_act, new_class_id, actions.task_pkg.PERMISSION_CHANGE_STATUS, 'Change status');
		class_pkg.CreateMapping(v_act, v_project_class_id, security_pkg.PERMISSION_WRITE, new_class_id, actions.task_pkg.PERMISSION_CHANGE_STATUS);
END;
