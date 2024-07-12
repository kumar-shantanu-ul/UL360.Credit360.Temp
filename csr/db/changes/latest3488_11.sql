-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=11
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
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;

	v_exportimport_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_imports_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_exports_container_sid 	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE security.menu
	   SET action = '/csr/site/automatedExportImport/admin/list.acds'
	 WHERE action = '/csr/site/automatedExportImport/impinstances.acds';


	FOR r IN (
		SELECT DISTINCT host 
		  FROM csr.customer c
		  JOIN security.website w ON c.host = w.website_name
		 WHERE EXISTS (
			SELECT * 
			  FROM security.securable_object
			 WHERE name = 'AutomatedImports'
			   AND application_sid_id = c.app_sid
		  )
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');

		BEGIN
			security.securableobject_pkg.CreateSO(v_act_id,
				v_app_sid,
				security.security_pkg.SO_CONTAINER,
				'AutomatedExportImport',
				v_exportimport_container_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExportImport');
		END;

		FOR r IN (
			SELECT sid_id
			  FROM security.SECURABLE_OBJECT
			WHERE name IN ('AutomatedExports', 'AutomatedImports')
			  AND application_sid_id = v_app_sid
			  AND parent_sid_id = v_app_sid
		)
		LOOP
			security.securableobject_pkg.MoveSO(v_act_id, r.sid_id, v_exportimport_container_sid);
		END LOOP;
	END LOOP;

	security.user_pkg.LogonAdmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_export_pkg
@..\automated_import_pkg
@..\automated_export_import_pkg

@..\enable_body
@..\automated_export_body
@..\automated_import_body
@..\automated_export_import_body

@update_tail
