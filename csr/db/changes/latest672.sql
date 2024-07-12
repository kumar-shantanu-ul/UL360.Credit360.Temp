-- Please update version.sql too -- this keeps clean builds in sync
define version=672
@update_header

DECLARE
		v_act 			security_pkg.T_ACT_ID;
		v_attribute_id	security_pkg.T_ATTRIBUTE_ID;		
BEGIN
	BEGIN
		user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
		Attribute_Pkg.CreateDefinition(v_act, class_pkg.GetClassId('CSRData'), 'delegbrowser-show-rag', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

@update_tail
