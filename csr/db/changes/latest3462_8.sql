-- Please update version.sql too -- this keeps clean builds in sync
define version=3462
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
DELETE FROM csr.module_history WHERE module_id = (SELECT module_id FROM csr.module WHERE module_name = 'Baseline calculations');
DELETE FROM csr.module_param WHERE module_id = (SELECT module_id FROM csr.module WHERE module_name = 'Baseline calculations');
DELETE FROM csr.module WHERE module_name = 'Baseline calculations';
DELETE FROM csr.capability WHERE name = 'Baseline calculations';

-- Add the Admin | Baseline calculations menu
DECLARE
	v_act					security.security_pkg.T_ACT_ID;
	v_sid					security.security_pkg.T_SID_ID;
	v_acl_id				security.security_pkg.T_ACL_ID;
	v_superadmins_sid		security.security_pkg.T_SID_ID;
	v_admin_menu			security.security_pkg.T_SID_ID;
	v_menu					security.security_pkg.T_SID_ID;
	v_bc_menu				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(
		in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
		in_act_timeout 	=> 172800,
		in_app_sid		=> NULL,
		out_act_id		=> v_act
	);

	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
	)
	LOOP
		v_menu := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'Menu');		
		BEGIN
			v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act, v_menu, 'Admin');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(
					in_act_id => v_act,
					in_parent_sid_id => v_menu,
					in_name => 'admin',
					in_description => 'Admin',
					in_action => '/csr/site/userSettings.acds',
					in_pos => 0,
					in_context => NULL,
					out_sid_id => v_admin_menu
				);
		END;

		BEGIN
			v_bc_menu := security.securableobject_pkg.GetSidFromPath(v_act, v_admin_menu, 'csr_site_admin_baseline_settings');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		-- Create menu item
				security.menu_pkg.CreateMenu(
					in_act_id => v_act,
					in_parent_sid_id => v_admin_menu,
					in_name => 'csr_site_admin_baseline_settings',
					in_description => 'Baseline settings',
					in_action => '/csr/site/admin/baseline/baselineSettings.acds',
					in_pos => NULL,
					in_context => NULL,
					out_sid_id => v_sid
				);
		END;
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_pkg

@../enable_body


@update_tail
