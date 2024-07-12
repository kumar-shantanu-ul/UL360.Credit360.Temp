-- Please update version.sql too -- this keeps clean builds in sync
define version=334
@update_header

DECLARE
	new_class_id	security_pkg.T_SID_ID;
	v_act		security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	BEGIN
		class_pkg.CreateClass(v_act, NULL, 'CSRDataset', NULL, NULL, new_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id := class_pkg.GetClassId('CSRDataset');
	END;
	BEGIN
		class_pkg.CreateMapping(v_act, new_class_id, security_pkg.PERMISSION_WRITE, class_pkg.GetClassId('CSRApprovalStep'), 65536);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	DELETE FROM security.permission_mapping WHERE parent_class_id = class_pkg.GetClassId('CSRReportingPeriod') AND child_class_id = class_pkg.GetClassId('CSRApprovalStep') AND child_permission = 65536;
	
	user_pkg.LogOff(v_act);
END;
/

@update_tail
