PROMPT please enter: host

DECLARE
	v_menu_help		security_pkg.T_SID_ID;
	v_act			security_pkg.T_ACT_ID;
BEGIN
	-- log on
	user_pkg.LogonAdmin('&&1');	
	v_act := security_pkg.getACT;
	security.menu_pkg.CreateMenu(v_act, security.securableobject_pkg.GetSIDFromPath(v_act, security_pkg.GetApp, 'menu'),
		'help', --'csr_help_viewhelp', 
		'Help', '/csr/site/help/viewHelp.acds', 12, null, v_menu_help);
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_menu_help), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, 
		security.securableobject_pkg.GetSidFromPath(v_act, security_pkg.GetApp, 'Groups/RegisteredUsers'), 
		security_pkg.PERMISSION_STANDARD_READ);		
	COMMIT;
END;
/
exit
