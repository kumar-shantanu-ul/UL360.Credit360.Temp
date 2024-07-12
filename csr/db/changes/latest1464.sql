-- Please update version.sql too -- this keeps clean builds in sync
define version=1464
@update_header

grant execute on csr.import_feed_pkg to security;

DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);	
	
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRImportFeed', 'csr.import_feed_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	security.user_pkg.LOGOFF(v_ACT);
END;
/

@..\import_feed_pkg
@..\import_feed_body

@update_tail