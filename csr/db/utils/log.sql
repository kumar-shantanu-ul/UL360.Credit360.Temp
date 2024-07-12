DECLARE
	v_out_act security.security_pkg.T_ACT_ID;
	v_site_name VARCHAR2(255);
BEGIN
	IF '&&1' = 'x' THEN
		security.user_pkg.logonadmin('');
	ELSIF '&&1' = 'off' THEN
		security.user_pkg.logoff(sys_context('security','act'));
	ELSE
		BEGIN
			security.user_pkg.logonadmin('&&1');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
			BEGIN
				SELECT MIN(website_name)
				  INTO v_site_name
				  FROM security.website
				 WHERE lower(website_name) LIKE '&&1..credit360.%';
				 
				security.user_pkg.logonadmin(NVL(v_site_name, '&&1'));
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
				BEGIN
					security.user_pkg.LogonAuthenticated(
						in_sid_id => TO_NUMBER('&&1'), 
						in_act_timeout => NULL, 
						out_act_id => v_out_act);
				EXCEPTION
					WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
						RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'You should  log into application (@log client_name) before using user sid ');
				END;
			END;
		END;
	END IF;
END;
/
