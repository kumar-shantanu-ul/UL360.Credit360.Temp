-- Please update version.sql too -- this keeps clean builds in sync
define version=3025
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
-- Enable automated exports/imports for sites with the data sources page, since the data sources
-- are now dependent on them
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;
	-- container
	v_auto_imports_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_exports_container_sid 	security.security_pkg.T_SID_ID;
	-- web resources
	v_www_root 						security.security_pkg.T_SID_ID;
	v_www_csr_site 					security.security_pkg.T_SID_ID;
	v_www_csr_site_automated		security.security_pkg.T_SID_ID;
	--Menu
	v_admin_menu					security.security_pkg.T_SID_ID;
	v_admin_automated_menu			security.security_pkg.T_SID_ID;
	--Alert id
	v_importcomplete_alert_type_id	NUMBER;
	v_exportcomplete_alert_type_id	NUMBER;
	v_capability_sid				security.security_pkg.T_SID_ID;
	v_capabilities_sid				security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT host 
		  FROM security.menu m 
		  JOIN security.securable_object so ON m.sid_id = so.sid_id 
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid 
		 WHERE LOWER(m.action) = '/csr/site/meter/monitor/datasource/datasourcelist.acds'
		   AND NOT EXISTS (
			SELECT * 
			  FROM security.securable_object
			 WHERE LOWER(name) = 'automatedimports'
			   AND parent_sid_id = c.app_sid
			   AND application_sid_id = c.app_sid
		  )
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		-- THIS IS LIFTED FROM csr.enable_pkg
		--Variables
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');

		-- read groups
		v_groups_sid 	:= security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.getApp, 'Groups');
		v_admins 		:= security.securableobject_pkg.GetSIDFromPath(v_act_id, v_groups_sid, 'Administrators');

		v_importcomplete_alert_type_id := 66;
		v_exportcomplete_alert_type_id := 72;

		--Create the container for the SOs
		--I don't add any ACLs as the administrators group should inherit down from root node
		BEGIN
			security.securableobject_pkg.CreateSO(v_act_id,
				v_app_sid,
				security.security_pkg.SO_CONTAINER,
				'AutomatedImports',
				v_auto_imports_container_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_auto_imports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedImports');
		END;
		BEGIN
			security.securableobject_pkg.CreateSO(v_act_id,
				v_app_sid,
				security.security_pkg.SO_CONTAINER,
				'AutomatedExports',
				v_auto_exports_container_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_auto_exports_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExports');
		END;

		--Create the web resources
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');

		BEGIN
			v_www_csr_site_automated := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/automatedExportImport');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_csr_site, 'automatedExportImport', v_www_csr_site_automated);
				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_automated), -1, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, v_admins, security.security_pkg.PERMISSION_STANDARD_READ);
		END;

		--Create the menu item
		v_admin_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu/admin');
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, v_admin_menu,
				'csr_site_cmsimp_impinstances',
				'Scheduled exports and imports',
				'/csr/site/automatedExportImport/impinstances.acds',
				12, null, v_admin_automated_menu);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;

		--Add the capability - will inherit from the container (administrators)		
		-- just create a sec obj of the right type in the right place
	    BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Manually import automated import instances',
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Can run additional automated import instances',
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Can run additional automated export instances',
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Can preview automated exports',
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;

		--Create the alerts
		BEGIN
				INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
				VALUES (v_app_sid, csr.customer_alert_type_id_seq.nextval, v_importcomplete_alert_type_id);

				INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
				SELECT v_app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
				  FROM csr.alert_frame af
				  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
				 WHERE af.app_sid = v_app_sid
				   AND cat.std_alert_type_id = v_importcomplete_alert_type_id
				 GROUP BY cat.customer_alert_type_id
				HAVING MIN(af.alert_frame_id) > 0;

				INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
				SELECT v_app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
				  FROM csr.default_alert_template_body d
				  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
				  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
				  CROSS JOIN aspen2.translation_set t
				 WHERE d.std_alert_type_id = v_importcomplete_alert_type_id
				   AND d.lang='en'
				   AND t.application_sid = v_app_sid
				   AND cat.app_sid = v_app_sid;
			EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (v_app_sid, csr.customer_alert_type_id_seq.nextval, v_exportcomplete_alert_type_id);

			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT v_app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'automatic'
			  FROM csr.alert_frame af
			  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = v_app_sid
			   AND cat.std_alert_type_id = v_exportcomplete_alert_type_id
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;

			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT v_app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM csr.default_alert_template_body d
			  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id = v_exportcomplete_alert_type_id
			   AND d.lang='en'
			   AND t.application_sid = v_app_sid
			   AND cat.app_sid = v_app_sid;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	security.user_pkg.LogonAdmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
