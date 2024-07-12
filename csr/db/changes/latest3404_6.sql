-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE ASPEN2.APPLICATION ADD GA4_ENABLED NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE ASPEN2.APPLICATION ADD CONSTRAINT CK_GA4_ENABLED CHECK (GA4_ENABLED IN (0,1,2));

ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD GA4_ENABLED NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION MODIFY (GA4_ENABLED DEFAULT NULL);
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD CONSTRAINT CK_GA4_ENABLED CHECK (GA4_ENABLED IN (0,1,2));


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Google Analytics Management', 0);

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (123, 'Consent Settings', 'EnableConsentSettings', 'Enable Consent Settings page.');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (123, 'State', 1, '0 (disable) or 1 (enable)');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (123, 'Menu Position', 2, '-1=end, or 1 based position');


-- Not Creating an Admin menu item for all existing sites just yet.
/*
DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;

	v_capability_sid		security.security_pkg.T_SID_ID;
	v_capabilities_sid		security.security_pkg.T_SID_ID;

	v_menu					security.security_pkg.T_SID_ID;
	v_admin_menu			security.security_pkg.T_SID_ID;
	v_ga_menu				security.security_pkg.T_SID_ID;
	v_position				NUMBER := -1;
BEGIN
	security.user_pkg.LogonAdmin();
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		security.user_pkg.LogonAuthenticated(
			in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_act_timeout	=> 30000,
			in_app_sid		=> r.application_sid_id,
			out_act_id		=> v_act_id);

		BEGIN
		v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Menu');
		v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
		END;
		
		IF v_admin_menu IS NOT NULL THEN
			BEGIN
				v_ga_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_site_admin_consent_settings');
				security.menu_pkg.SetPos(
					in_act_id => v_act_id,
					in_sid_id => v_ga_menu,
					in_pos => v_position
				);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(
						in_act_id => v_act_id,
						in_parent_sid_id => v_admin_menu,
						in_name => 'csr_site_admin_consent_settings',
						in_description => 'Consent Settings',
						in_action => '/csr/site/admin/superadmin/consentSettings/consentSettings.acds',
						in_pos => v_position,
						in_context => NULL,
						out_sid_id => v_ga_menu
					);
			END;
		END IF;

		-- csr_data_pkg.EnableCapability;
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Google Analytics Management',
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
	END LOOP;

	security.user_pkg.LogonAdmin();
END;
/
*/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/db/aspenapp_body

@../csr_data_pkg
@../customer_pkg
@../enable_pkg
@../schema_pkg

@../csr_data_body
@../customer_body
@../enable_body
@../schema_body

@../csrimp/imp_body

@update_tail
