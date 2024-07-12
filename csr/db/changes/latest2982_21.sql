-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=21
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
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_menu_sid						security.security_pkg.T_SID_ID;
	v_menu_sas_sid					security.security_pkg.T_SID_ID;
	v_sa_sid						security.security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT c.app_sid, w.website_name
		  FROM csr.customer c, security.website w
		 WHERE c.app_sid = w.application_sid_id
	) LOOP
		security.user_pkg.logonadmin(r.website_name);
		v_app_sid := security.security_pkg.getApp;
		v_act_id := security.security_pkg.getACT;

		-- add menu item
		BEGIN
		v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN 
			  v_menu_sid := NULL;
		END;
		
		IF v_menu_sid IS NOT NULL THEN
			BEGIN
				security.menu_pkg.CreateMenu(v_act_id, v_menu_sid, 'csr_site_admin_SuperAdmin_setup', 'SuperAdmin Setup', '/csr/site/admin/superadmin/setup.acds', 2, null, v_menu_sas_sid);
			EXCEPTION
			  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_menu_sas_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_site_admin_SuperAdmin_setup');
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_menu_sas_sid, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sas_sid));
			-- Add SA permission
			v_sa_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sas_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);


			-- remove links to pages that now exist in the new Super Admin page.
			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/cms_admin_forms');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/cms_admin_doctemplates');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_admin_factor_sets');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin/csr_site_admin_emissionFactors_manage');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_admin_enable');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;

			BEGIN
			v_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/setup/csr_admin_utilscripts');
			security.securableobject_pkg.DeleteSO(v_act_id, v_menu_sid);
			EXCEPTION
			  WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
		END IF;

		security.user_pkg.logonadmin;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
