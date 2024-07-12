PROMPT please enter: host

-- test data
DECLARE
	v_act_id			security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_class_id			security_pkg.T_CLASS_ID;
	v_groups_sid		security_pkg.T_SID_ID;
	v_sid				security_pkg.T_SID_ID;
BEGIN
	-- log on
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	v_app_sid := securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//aspen/applications/&&1');
	security_pkg.SetACT(v_act_id, v_app_sid);
	-- create new groups
	v_class_id := class_pkg.GetClassId('CSRUserGroup');
	v_groups_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
    group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
        'Data Providers', v_class_id, v_sid);    
    group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
        'Auditors', v_class_id, v_sid);     
    group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
        'Reporters', v_class_id, v_sid);    
	COMMIT;
END;
/
exit
