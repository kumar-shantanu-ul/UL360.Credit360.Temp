VARIABLE version NUMBER
BEGIN :version := 12; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM supplier.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

DECLARE
	csr_user_class_id 	security_pkg.T_SID_ID;
	new_class_id 		security_pkg.T_SID_ID;
	v_act 				security_pkg.T_ACT_ID;
	v_attribute_id		security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	csr_user_class_id := class_pkg.GetClassID('CSRUser');
	BEGIN	
		class_pkg.CreateClass(v_act, csr_user_class_id, 'SupplierUser', 'supplier.supplier_user_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=class_pkg.getClassID('SupplierUser');
	END;
	UPDATE security.securable_object 
	   SET class_id = new_class_id 
	 WHERE SID_ID IN (SELECT DISTINCT CSR_USER_SID FROM SUPPLIER.COMPANY_USER);
	user_pkg.LOGOFF(v_ACT);
END;
/

GRANT EXECUTE ON supplier_user_pkg TO SECURITY;
	
	
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
