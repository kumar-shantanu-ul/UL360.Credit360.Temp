PROMPT please enter: host, groupname

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
        '&&2', v_class_id, v_sid);    
	
	csr.csr_data_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_GROUP_CHANGE, security_pkg.GetAPP, security_pkg.GetSID, 'Created group "{0}"', '&&2');
	COMMIT;
END;
/
exit
