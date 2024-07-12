-- Please update version.sql too -- this keeps clean builds in sync
define version=654
@update_header

DECLARE
	v_act 			security_pkg.T_ACT_ID;
	new_class_id 	security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	BEGIN
		class_pkg.CreateClass(v_act, NULL, 'CSRDelegationPlan', 'csr.deleg_plan_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

@update_tail


