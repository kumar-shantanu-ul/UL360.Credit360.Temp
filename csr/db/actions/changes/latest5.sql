DECLARE
	v_class_id 	security_pkg.T_SID_ID;
	v_act 		security_pkg.T_ACT_ID;
BEGIN	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- apply to project
	v_class_id:=class_pkg.GetClassId('ActionsProject');	
	class_pkg.AddPermission(v_act, v_class_id, actions.task_pkg.PERMISSION_ASSIGN_USERS, 'Assign to other users');
	class_pkg.CreateMapping(v_act, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_WRITE, v_class_id, actions.task_pkg.PERMISSION_ASSIGN_USERS);
	-- apply to task
	v_class_id:=class_pkg.GetClassId('ActionsTask');
	class_pkg.AddPermission(v_act, v_class_id, actions.task_pkg.PERMISSION_ASSIGN_USERS, 'Assign to other users');
END;
/
COMMIT;
