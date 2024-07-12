/* Redirects an existing soft link domain to a different app*/
/* @RedirectWebsiteDomainSoftLink.sql maerskredirect.credit360.com www.maerskcsr.com*/
DECLARE
	v_act	security_pkg.t_act_id;
	v_softlink_sid	security_pkg.t_sid_id;
	v_app_sid	security_pkg.t_sid_id;
	v_app_name	varchar2(100);
	v_domain_name	varchar2(100);
begin
	v_app_name := '&&AppName';--eg: maersk.credit360.com
	v_domain_name := '&&DomainName';--eg: maersksoftlink.com
	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 333333, v_act);
	v_app_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), 0, '//Aspen/Applications/' || v_app_name);

	--GetSIDFromPath returns NVL(link_sid, sid_id), so it's not applicable here, todo: is it a better way?
	SELECT sid_id
	  INTO v_softlink_sid
	  FROM security.securable_object
	 WHERE lower(name) = lower(v_domain_name);
	   
	-- MoveSoftLink validates if v_domain_name is a soft link
	security.softlink_pkg.MoveSoftLink(security_pkg.GetACT(), v_softlink_sid, v_app_sid);
				
	UPDATE security.website
	   SET (website_name, application_sid_id, web_root_sid_id, denied_page, 
		server_group, ACT_TIMEOUT, CERT_ACT_TIMEOUT, SECURE_ONLY, http_only_cookies, xsrf_check_enabled) = (
			SELECT v_domain_name, application_sid_id, web_root_sid_id, denied_page, 
				server_group, ACT_TIMEOUT, CERT_ACT_TIMEOUT, 1, http_only_cookies, xsrf_check_enabled
			  FROM security.website
			 WHERE lower(website_name) = lower(v_app_name)
		)
	 WHERE lower(website_name) = lower(v_domain_name);
	 --security_pkg.debugMsg('redirect rows affected: ' || sql%rowcount);
END;
/
commit;

PROMPT 'IISRESET TO CHECK THE REDIRECT WORKS!!'

exit
--IISRESET TO CHECK THE REDIRECT WORKS!!
