VAR b_exit_code	NUMBER;

DECLARE
	v_www_sid				security.security_pkg.T_SID_ID;
	v_www_issues2_sid		security_pkg.T_SID_ID;
BEGIN
	
	:b_exit_code := 0;
	security.user_pkg.logonadmin('&&1');
	
	BEGIN
		v_www_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'wwwroot');
		v_www_issues2_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetACT, v_www_sid, 'csr/site/issues2');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			:b_exit_code := 255;
	END;
END;
/

EXIT :b_exit_code;