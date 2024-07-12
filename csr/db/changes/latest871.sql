-- Please update version.sql too -- this keeps clean builds in sync
define version=871
@update_header

DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRUserContainer', 'csr.user_container_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRUserContainer');
	END;
END;
/

@..\user_container_pkg
@..\user_container_body

@update_tail
