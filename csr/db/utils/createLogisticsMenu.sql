PROMPT please enter: host

DECLARE
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins_sid					security.security_pkg.T_SID_ID;
	
	v_menu							security.security_pkg.T_SID_ID;
	v_menu_logistics				security.security_pkg.T_SID_ID;
	v_menu_individual				security.security_pkg.T_SID_ID;
	
	v_www							security.security_pkg.T_SID_ID;
	v_www_logistics					security.security_pkg.T_SID_ID;
	
	v_act							security.security_pkg.T_ACT_ID;
	v_app							security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	v_app := sys_context('security','app');
	v_act := sys_context('security','act');
	
	-- read groups
	v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'Groups');
	v_admins_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'Administrators');
  
	-- add menu items
	v_menu := security.securableobject_pkg.GetSIDFromPath(v_act, v_app,'menu');
	BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu,
    	'csr_logistics',
    	'Logistics', '/csr/site/logistics/approve.acds',
    	1, null, v_menu_logistics);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            v_menu_logistics := security.securableobject_pkg.GetSidFromPath(v_act, v_menu, 'csr_logistics');
    END;
    
    BEGIN
		security.menu_pkg.CreateMenu(v_act, v_menu_logistics,
    	'csr_site_logistics_approve',
    	'Admin', '/csr/site/logistics/approve.acds',
    	1, null, v_menu_individual);
    	
    	security.menu_pkg.CreateMenu(v_act, v_menu_logistics,
    	'csr_site_logistics_manage_distance',
    	'Manage distances', '/csr/site/logistics/manageDistance.acds',
    	2, null, v_menu_individual);
    	
    	security.menu_pkg.CreateMenu(v_act, v_menu_logistics,
    	'csr_site_logistics_import',
    	'Import', '/csr/site/logistics/import.acds',
    	3, null, v_menu_individual);
    EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
    END;
	
	-- create web-resources
	v_www := security.securableobject_pkg.GetSidFromPath(v_act, v_app, 'wwwroot');
	BEGIN
        security.web_pkg.CreateResource(v_act, v_www, security.securableobject_pkg.GetSidFromPath(v_act, v_www, 'csr/site'), 'logistics', v_www_logistics);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            v_www_logistics := security.securableobject_pkg.GetSidFromPath(v_act, v_www, 'csr/site/logistics');
	END;
	
	security.securableobject_pkg.ClearFlag(v_act, v_www_logistics, security.security_pkg.SOFLAG_INHERIT_DACL);
	security.acl_pkg.DeleteAllACEs(v_act, security.acl_pkg.GetDACLIDForSID(v_www_logistics));
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_logistics),
		security.security_pkg.ACL_INDEX_LAST,
		security.security_pkg.ACE_TYPE_ALLOW,
        security.security_pkg.ACE_FLAG_DEFAULT,
        v_admins_sid,
        security.security_pkg.PERMISSION_STANDARD_READ);

	security.acl_pkg.PropogateACEs(v_act, v_www_logistics);
END;
/
exit
