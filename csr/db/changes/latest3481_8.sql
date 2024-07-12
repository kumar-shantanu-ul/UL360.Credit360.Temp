-- Please update version.sql too -- this keeps clean builds in sync
define version=3481
define minor_version=8
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
	v_act_id					security.security_pkg.T_ACT_ID;
	v_menu_sid					security.security_pkg.T_SID_ID;
	v_fd_menu_sid				security.security_pkg.T_SID_ID;
	v_fd_assignments_menu_sid	security.security_pkg.T_SID_ID;
	v_fd_disclosures_menu_sid	security.security_pkg.T_SID_ID;
	v_fd_frameworks_menu_sid	security.security_pkg.T_SID_ID;
	v_reg_users_sid				security.security_pkg.T_SID_ID;
	v_disclosures_admin_sid		security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
	)
	LOOP
		security.user_pkg.LogonAuthenticated(
			in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_act_timeout 	=> 172800,
			in_app_sid		=> r.application_sid_id,
			out_act_id		=> v_act_id
		);

		v_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Menu');

		BEGIN
			v_fd_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_sid, 'framework_disclosures');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				BEGIN
					v_fd_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu_sid, 'ui.disclosures_disclosures');
				EXCEPTION
					WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
						v_fd_menu_sid := NULL;
				END;
		END;

		IF v_fd_menu_sid IS NOT NULL THEN

			security.SecurableObject_pkg.RenameSO(v_act_id, v_fd_menu_sid, 'ui.disclosures_disclosures');
			security.menu_pkg.SetMenuAction(v_act_id, v_fd_menu_sid, '/app/ui.disclosures/disclosures#/');

			v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/RegisteredUsers');
			v_disclosures_admin_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Groups/Framework Disclosure Admins');

			BEGIN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_fd_menu_sid,
					in_name => 'assignments',
					in_description => 'Assignments',
					in_action => '/app/ui.disclosures/disclosures#/',
					in_pos => 1,
					in_context => NULL,
					out_sid_id => v_fd_assignments_menu_sid
				);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_fd_assignments_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id,'menu/ui.disclosures_disclosures/assignments');
			END;

			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_assignments_menu_sid), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_assignments_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

			BEGIN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_fd_menu_sid,
					in_name => 'disclosures',
					in_description => 'Disclosures',
					in_action => '/app/ui.disclosures/disclosures#/disclosures',
					in_pos => 2,
					in_context => NULL,
					out_sid_id => v_fd_disclosures_menu_sid
				);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_fd_disclosures_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id,'menu/ui.disclosures_disclosures/disclosures');
			END;

			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_disclosures_menu_sid), v_reg_users_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_disclosures_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);

			BEGIN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act_id,
					in_parent_sid_id => v_fd_menu_sid,
					in_name => 'frameworks',
					in_description => 'Frameworks',
					in_action => '/app/ui.disclosures/disclosures#/frameworks',
					in_pos => 3,
					in_context => NULL,
					out_sid_id => v_fd_frameworks_menu_sid
				);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_fd_frameworks_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.application_sid_id,'menu/ui.disclosures_disclosures/frameworks');
			END;

			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_frameworks_menu_sid), v_disclosures_admin_sid);
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_fd_frameworks_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_disclosures_admin_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END IF;

		security.user_pkg.logonadmin();
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_body

@update_tail
