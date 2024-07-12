PROMPT please enter: host

DECLARE
	v_groups_sid					security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;	
	v_menu_admin					security_pkg.T_SID_ID;
	v_menu1							security_pkg.T_SID_ID;	
	-- web resources	
	v_www_sid				security.security_pkg.T_SID_ID;
	v_www_csr_site_audit	security.security_pkg.T_SID_ID;
	v_www_csr_site			security.security_pkg.T_SID_ID;
	v_act							security_pkg.T_ACT_ID;
	v_app							security_pkg.T_SID_ID;
BEGIN
	-- log on
	user_pkg.logonadmin('&&1');
	v_app := sys_context('security','app');
	v_act := sys_context('security','act');
	
	-- read groups
	v_groups_sid 	:= securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid 	:= securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');

	-- add deleg plan menu items
	v_menu_admin := securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu_admin,
			'csr_auditlog_reports',
			'Audit log reports',
			'/csr/site/auditlog/reports.acds',
			10, null, v_menu1);
		
		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_READ);
		
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	
	/*** WEB RESOURCE ***/
	-- add permissions on pre-created web-resources
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'csr/site');
	BEGIN
		security.web_pkg.CreateResource(v_act, v_www_sid, v_www_csr_site, 'auditlog', v_www_csr_site_audit);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_www_csr_site_audit := security.securableobject_pkg.GetSidFromPath(v_act, v_www_csr_site, 'auditlog');
	END;
	-- add administrators to web resource
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_audit), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
		v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
	/*** CAPABILITY ***/
	csr.csr_data_pkg.enablecapability('Can generate audit log reports');
	
END;
/
exit