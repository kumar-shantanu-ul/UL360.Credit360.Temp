/* WARNING: This script is not embedded in \cvs\csr\CreateSite2, but probably should be. Consider this if changing the passed parameters or including other scripts. */
/*          (Included scripts will need to be embedded as well, and they can only really be included via @@ from the current directory   */
/*          at the moment.)                                                                                                              */

PROMPT please enter: host

-- data
DECLARE
	v_app_sid			security.security_pkg.T_SID_ID;
	v_act_id			security.security_pkg.T_ACT_ID;
	-- groups
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_admins_sid		security.security_pkg.T_SID_ID;
	-- menu
	v_menu_admin		security.security_pkg.T_SID_ID;
	v_menu_measureconversions	security.security_pkg.T_SID_ID;
	-- www
    v_wwwroot_sid		security.security_pkg.T_SID_ID;
    v_www_sid           security.security_pkg.T_SID_ID;
    v_www_csr_site		security.security_pkg.T_SID_ID;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&1');
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	
	-- read groups
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
    v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');

	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');

	/*** ADD MENU ITEM ***/
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin'),
			'csr_measure_conversions', 'Measure conversions', '/csr/site/schema/measureConversions/measureConversions.acds', 8, null, v_menu_measureconversions);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_menu_measureconversions := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_admin, 'csr_measure_conversions');
	END;

	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_measureconversions), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_ALL);

	security.acl_pkg.PropogateACEs(v_act_id, v_menu_measureconversions); 

	/*** ADD WEB RESOURCE ***/
	v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, sys_context('security','app'), 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site/schema');
	security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'measureConversions', v_www_sid);
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_sid), -1,
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security_pkg.PERMISSION_STANDARD_ALL);

	COMMIT;
END;
/
