-- Please update version.sql too -- this keeps clean builds in sync
define version=69
@update_header

VARIABLE version NUMBER
BEGIN :version := 69; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	



DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_class			security_pkg.T_CLASS_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_act);
		
	v_class := class_pkg.GetClassID('AspenApp');
	attribute_pkg.CreateDefinition(v_act, v_class, '_language', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_culture', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_timezone', 0, null, v_attribute_id);
	
	v_class := class_pkg.GetClassID('User');
	attribute_pkg.CreateDefinition(v_act, v_class, '_language', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_culture', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_timezone', 0, null, v_attribute_id);
	
	v_class := class_pkg.GetClassID('FPUser');
	attribute_pkg.CreateDefinition(v_act, v_class, '_language', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_culture', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_timezone', 0, null, v_attribute_id);
	
	v_class := class_pkg.GetClassID('CSRUser');
	attribute_pkg.CreateDefinition(v_act, v_class, '_language', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_culture', 0, null, v_attribute_id);
	attribute_pkg.CreateDefinition(v_act, v_class, '_timezone', 0, null, v_attribute_id);
	
	user_pkg.LogOff(v_act);
END;
/


UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
