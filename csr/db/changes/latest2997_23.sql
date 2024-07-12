-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.delegation_description
ADD last_changed_dtm DATE;
ALTER TABLE csrimp.delegation_description
ADD last_changed_dtm DATE;

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
			v_menu						security.security_pkg.T_SID_ID;
			v_admin_menu				security.security_pkg.T_SID_ID;
			v_translations_menu			security.security_pkg.T_SID_ID;
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;

			v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');

			BEGIN
				v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'admin',  'Admin',  '/csr/site/userSettings.acds',  0, null, v_admin_menu);
			END;

			BEGIN
				v_translations_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_admin_translations_import');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_admin_translations_import',  'Translations import',  '/csr/site/admin/translations/translationsImport.acds',  12, null, v_translations_menu);
			END;
		END; 
	END LOOP;

	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/

BEGIN
	INSERT INTO csr.batched_export_type
	  (batch_export_type_id, label, assembly)
	VALUES
	  (16, 'Delegation translations', 'Credit360.ExportImport.Export.Batched.Exporters.DelegationTranslationExporter');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\delegation_pkg
@..\delegation_body

@..\schema_body
@..\csrimp\imp_body

@update_tail
