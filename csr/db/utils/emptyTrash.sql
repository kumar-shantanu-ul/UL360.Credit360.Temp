PROMPT Enter host

DECLARE
	v_act				security.security_pkg.T_ACT_ID;
	v_app				security.security_pkg.T_SID_ID;
	v_trash_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	v_act := security.security_pkg.getACT;
	v_app := security.security_pkg.getApp;
	
	-- get sid for trash
	v_trash_sid := security.securableobject_pkg.GetSidFromPath(v_act,v_app,'trash');
	 
	-- empty the trash...
	csr.trash_pkg.EmptyTrash(v_act, v_app);
END;
/
