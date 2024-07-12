
DECLARE
	v_class_id 		security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);	
	
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'Chain Company', 'chain.company_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'Chain Uninvited Supplier', 'chain.uninvited_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		security.class_pkg.CreateClass(v_act, null, 'ChainFileUpload', 'chain.upload_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	BEGIN
		security.class_pkg.CreateClass(v_act, null, 'ChainCompoundFilter', 'chain.filter_pkg', null, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	security.user_pkg.LogOff(v_act);
END;
/
commit;
