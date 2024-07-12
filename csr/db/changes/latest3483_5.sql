-- Please update version.sql too -- this keeps clean builds in sync
define version=3483
define minor_version=5
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
BEGIN
-- DELETE notification menu item
	FOR r IN (
		SELECT so.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		 WHERE description = 'Failed notifications'
		   AND action = '/app/ui.notifications/notifications')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = (SELECT dacl_id
						   FROM security.securable_object
						  WHERE sid_id = r.sid_id);
		DELETE FROM security.menu
		 WHERE sid_id = r.sid_id;
		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;
END;
/

DECLARE
	v_www_ui_notifications  	security.security_pkg.T_SID_ID;
	v_app_ui_notifications		security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_registered_users			security.security_pkg.T_SID_ID;
	v_ui_notifications_dacl 	NUMBER(10);
	v_ui_app_notifications_dacl	NUMBER(10);
	v_act						security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT w.application_sid_id app_sid
		  FROM security.website w
		  JOIN csr.customer c ON w.application_sid_id = c.app_sid
	)
	LOOP
		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'wwwroot');
			v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'app');

			-- web resource for the ui
			v_www_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'ui.notifications');
			v_ui_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_www_ui_notifications);

			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_notifications_dacl
			);
			-- Read/write www ui for registered users
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);

			-- web resource for the ui
			v_app_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_app_sid, 'ui.notifications');
			v_ui_app_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_app_ui_notifications);
			
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_app_notifications_dacl
			);

			-- Read/write app ui for admins
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_app_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
			WHEN OTHERS THEN
				NULL;
		END;
	END LOOP;

	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../notification_body

@update_tail
