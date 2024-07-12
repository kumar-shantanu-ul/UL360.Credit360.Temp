-- Please update version.sql too -- this keeps clean builds in sync
define version=296
@update_header

-- create SqlReport class
DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_class_id          security_pkg.T_CLASS_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
	BEGIN	
		class_pkg.CreateClass(v_act, NULL, 'CSRSqlReport', NULL, NULL, v_class_id);
		EXCEPTION
	WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
		v_class_id:=class_pkg.GetClassId('CSRSqlReport');
	END;
END;
/

@..\sqlreport_pkg
@..\sqlreport_body

grant execute on sqlreport_pkg to web_user;

@update_tail
