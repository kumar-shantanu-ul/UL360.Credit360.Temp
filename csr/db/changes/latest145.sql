-- Please update version.sql too -- this keeps clean builds in sync
define version=145
@update_header

DECLARE
	new_class_id 	security_pkg.T_SID_ID;
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	new_class_id:=class_pkg.GetClassId('CSRData');
	
	BEGIN
		Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'targetdashboard-show-flash', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'modules-metering', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	COMMIT;
END;
/

@update_tail
