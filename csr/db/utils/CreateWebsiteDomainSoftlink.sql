whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	v_act				security.security_pkg.t_act_id;
	v_softlink_sid		security.security_pkg.t_sid_id;
	v_app_sid			security.security_pkg.t_sid_id;
	v_app_name			varchar2(100);
	v_domain_name		varchar2(100);
begin
	v_app_name := '&&AppName';
	v_domain_name := '&&DomainName';
	
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 333333, v_act);
	v_app_sid := security.SecurableObject_pkg.GetSIDFromPath(security.security_pkg.GetACT(), 0, '//Aspen/Applications/' || v_app_name);

	security.softlink_pkg.createsoftlink(security.security_pkg.GetACT(), 
		security.SecurableObject_pkg.GetSIDFromPath(security.security_pkg.GetACT(), 0, '//Aspen/Applications'), 
		v_domain_name,
		security.SecurableObject_pkg.GetSIDFromPath(security.security_pkg.GetACT(), 0, '//Aspen/Applications/' || v_app_name),
		v_softlink_sid
		);

	INSERT INTO SECURITY.WEBSITE (website_name, application_sid_id, web_root_sid_id, denied_page, 
		server_group, ACT_TIMEOUT, CERT_ACT_TIMEOUT, SECURE_ONLY, http_only_cookies, xsrf_check_enabled)
	SELECT v_domain_name, application_sid_id, web_root_sid_id, denied_page, 
		server_group, ACT_TIMEOUT, CERT_ACT_TIMEOUT, 1, http_only_cookies, xsrf_check_enabled
	FROM SECURITY.WEBSITE
	WHERE WEBSITE_NAME = v_app_name;
	
	INSERT INTO security.home_page (app_sid, sid_id, host, url)
    SELECT app_sid, sid_id, v_domain_name, url
	  FROM security.home_page
	 WHERE lower(host) = lower(v_app_name);
END;
/

commit;

exit

