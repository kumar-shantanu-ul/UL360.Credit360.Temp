-- Please update version.sql too -- this keeps clean builds in sync
define version=3005
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	-- For all sites...
	security.user_pkg.logonadmin;

	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.logonadmin(r.host);

		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID;
			v_app_sid 					security.security_pkg.T_SID_ID;
			v_admin_menu				security.security_pkg.T_SID_ID;
			v_translations_menu			security.security_pkg.T_SID_ID;
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;

			BEGIN
				v_translations_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/Admin/csr_admin_translations_import');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/Admin');
					security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_admin_translations_import',  'Translations import',  '/csr/site/admin/translations/translationsImport.acds',  12, null, v_translations_menu);
			END;

			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_translations_menu));
						
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_translations_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END; 
	END LOOP;

	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/

BEGIN

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (91, 'Translations import (for client admins)', 'EnableTranslationsImport', 'Enables the translations import tool for client admins. Adds the capability and adds the menu for them.');

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
