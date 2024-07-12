-- Please update version.sql too -- this keeps clean builds in sync
define version=316
@update_header

DECLARE
	v_act 			security_pkg.T_ACT_ID;
	v_class_id		security_pkg.T_SID_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);	
	v_class_id := class_pkg.GetClassId('CSRData');
	attribute_pkg.CreateDefinition(v_act, v_class_id, 'region-disposal-date', 0, NULL, v_attribute_id);
	COMMIT;
EXCEPTION
	WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
END;
/


@update_tail
