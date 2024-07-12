-- Please update version.sql too -- this keeps clean builds in sync
define version=332
@update_header

@..\pending_pkg.sql
@..\pending_body.sql

DECLARE
	new_class_id	security_pkg.T_SID_ID;
	v_act		security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	BEGIN
		class_pkg.CreateClass(v_act, security_pkg.SO_GROUP, 'CSRApprovalStep', NULL, NULL, new_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id := class_pkg.GetClassId('CSRApprovalStep');
	END;
	BEGIN
		class_pkg.AddPermission(v_act, new_class_id, 65536, 'Submit / Merge');
		class_pkg.CreateMapping(v_act, class_pkg.GetClassId('CSRReportingPeriod'), security_pkg.PERMISSION_WRITE, new_class_id, 65536);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	user_pkg.LogOff(v_act);
END;
/

@update_tail
