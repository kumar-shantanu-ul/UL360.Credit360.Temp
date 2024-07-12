-- Please update version.sql too -- this keeps clean builds in sync
define version=3398
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_reg_users_sid							security.security_pkg.T_SID_ID;
	v_act_id								security.security_pkg.T_ACT_ID;
	v_root_menu_sid							security.security_pkg.T_SID_ID;
	v_admin_menu_sid						security.security_pkg.T_SID_ID;
	v_disclosures_admin_menu_sid			security.security_pkg.T_SID_ID;
	v_frameworks_menu_sid					security.security_pkg.T_SID_ID;
	v_www_sid								security.security_pkg.T_SID_ID;
	v_www_app_sid							security.security_pkg.T_SID_ID;
	v_www_app_ui_disclosures_admin_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT DISTINCT so.application_sid_id, c.host
		  FROM security.securable_object so
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE so.name = 'ui.disclosures.admin'
	) LOOP
		security.user_pkg.logonadmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/RegisteredUsers');

		-- menu items
		v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id, 'menu');
		v_disclosures_admin_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_root_menu_sid, 'framework_disclosures');
		v_frameworks_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_disclosures_admin_menu_sid, 'framework_disclosures_frameworks');

		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_disclosures_admin_menu_sid), v_reg_users_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_disclosures_admin_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_frameworks_menu_sid), v_reg_users_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_frameworks_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

		-- web resource
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'wwwroot');
		v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'app');
		v_www_app_ui_disclosures_admin_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_app_sid, 'ui.disclosures.admin');

		security.securableobject_pkg.ClearFlag(v_act_id, v_www_app_ui_disclosures_admin_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
		security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_disclosures_admin_sid), v_reg_users_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_app_ui_disclosures_admin_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
	security.user_pkg.logonadmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
