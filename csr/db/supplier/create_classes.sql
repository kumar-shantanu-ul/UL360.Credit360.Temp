
DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- create deliverable class
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'SupplierCompany', 'supplier.company_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('SupplierCompany');
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'SupplierTagGroup', 'supplier.tag_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('SupplierTagGroup');
	END;		
	BEGIN	
		security.class_pkg.CreateClass(v_act, security.security_pkg.SO_USER, 'SupplierUser', 'supplier.supplier_security.user_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.getClassID('SupplierUser');
	END;
	security.user_pkg.LOGOFF(v_ACT);
END;
/
commit;
