-- Please update version.sql too -- this keeps clean builds in sync
define version=3477
define minor_version=14
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
	v_act							security.security_pkg.T_ACT_ID;
	v_www_app_sid					security.security_pkg.T_SID_ID;
	v_www_notifications_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT w.application_sid_id app_sid, w.web_root_sid_id www_sid
		  FROM security.website w
		  JOIN csr.customer c ON w.application_sid_id = c.app_sid
	)
	LOOP
		-- Create wwwroot/ui.notifications (asset path)
		BEGIN
			security.web_pkg.CreateResource(
				in_act_id			=> v_act,
				in_web_root_sid_id	=> r.www_sid,
				in_parent_sid_id	=> r.www_sid,
				in_page_name		=> 'ui.notifications',
				in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
				in_rewrite_path		=> NULL,
				out_page_sid_id		=> v_www_notifications_sid
			);

			security.acl_pkg.AddACE(
				in_act_id			=> v_act,
				in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_www_notifications_sid),
				in_acl_index		=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=> security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id			=> security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups/Administrators'),
				in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		-- Create wwwroot/app
		BEGIN
			security.web_pkg.CreateResource(
				in_act_id			=> v_act,
				in_web_root_sid_id	=> r.www_sid,
				in_parent_sid_id	=> r.www_sid,
				in_page_name		=> 'app',
				in_class_id			=> security.security_pKg.SO_WEB_RESOURCE,
				in_rewrite_path		=> NULL,
				out_page_sid_id		=> v_www_app_sid
			);

			security.acl_pkg.AddACE(
				in_act_id			=> v_act,
				in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_www_app_sid),
				in_acl_index		=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=> security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id			=> security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups/RegisteredUsers'),
				in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.www_sid, 'app');
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		-- Create wwwroot/app/ui.notifications (routed path)
		BEGIN
			security.web_pkg.CreateResource(
				in_act_id			=> v_act,
				in_web_root_sid_id	=> r.www_sid,
				in_parent_sid_id	=> v_www_app_sid,
				in_page_name		=> 'ui.notifications',
				in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
				in_rewrite_path		=> NULL,
				out_page_sid_id		=> v_www_notifications_sid
			);

			security.securableobject_pkg.ClearFlag(
				in_act_id			=> v_act,
				in_sid_id			=> v_www_notifications_sid,
				in_flag				=> security.security_pkg.SOFLAG_INHERIT_DACL
			);

			-- All accesible features are currently admin only
			security.acl_pkg.AddACE(
				in_act_id			=> v_act,
				in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_www_notifications_sid),
				in_acl_index		=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=> security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id			=> security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups/Administrators'),
				in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../notification_body

@update_tail
