-- Please update version.sql too -- this keeps clean builds in sync
define version=3481
define minor_version=7
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
-- Create menu item.
DECLARE
	v_admin_menu_sid			security.security_pkg.T_SID_ID;
	v_superadmin_sid			security.security_pkg.T_SID_ID;
	v_www_ui_notifications  	security.security_pkg.T_SID_ID;
	v_app_ui_notifications		security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_admins					security.security_pkg.T_SID_ID;
	v_ui_notifications_dacl 	NUMBER(10);
	v_ui_app_notifications_dacl	NUMBER(10);
	v_act						security.security_pkg.T_ACT_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT w.application_sid_id app_sid
		  FROM security.website w
		  JOIN csr.customer c ON w.application_sid_id = c.app_sid
	)
	LOOP
		BEGIN
			v_admin_menu_sid := security.securableObject_pkg.GetSidFromPath(v_act, r.app_sid, 'menu/admin');
			v_superadmin_sid := security.securableobject_pkg.getsidfrompath(v_act, 0, 'csr/SuperAdmins');

			security.menu_pkg.CreateMenu(
				in_act_id => v_act,
				in_parent_sid_id => v_admin_menu_sid,
				in_name => 'failednotications',
				in_description => 'Failed notifications',
				in_action => '/app/ui.notifications/notifications',
				in_pos => NULL,
				in_context => NULL,
				out_sid_id => v_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := security.securableObject_pkg.GetSidFromPath(v_act, r.app_sid, 'menu/admin/failednotications');
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

		BEGIN
			security.securableObject_pkg.ClearFlag(v_act, v_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
			security.acl_pkg.DeleteAllACES(v_act, security.acl_pkg.GetDACLIDForSID(v_sid));
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_superadmin_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		END;

		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'wwwroot');
			v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'app');

			-- web resource for the ui
			BEGIN
				v_www_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'ui.notifications');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act, v_www_root, v_www_root, 'ui.notifications', v_www_ui_notifications);
			END;

			-- web resource for the ui
			BEGIN
				v_app_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_app_sid, 'ui.notifications');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act, v_www_root, v_www_app_sid, 'ui.notifications', v_www_ui_notifications);
			END;

			v_ui_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_www_ui_notifications);
			v_ui_app_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_app_ui_notifications);

			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_notifications_dacl
			);
		
			-- Read/write www ui for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);

			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_app_notifications_dacl
			);
		
			-- Read/write app ui for admins
			v_admins := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/Administrators'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_app_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_admins,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../notification_body

@update_tail
