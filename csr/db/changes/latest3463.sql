define version=3463
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



DROP TABLE CMS.TEMP_REGION_PATH;
DROP TABLE CMS.TEMP_IND_PATH;
ALTER TABLE CSR.CUSTOMER ADD SHOW_DATA_APPROVE_CONFIRM NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_SHOW_DATA_APPROVE_CONFIRM CHECK (SHOW_DATA_APPROVE_CONFIRM IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD SHOW_DATA_APPROVE_CONFIRM NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (SHOW_DATA_APPROVE_CONFIRM DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_SHOW_DATA_APPROVE_CONFIRM CHECK (SHOW_DATA_APPROVE_CONFIRM IN (0,1));










DELETE FROM csr.module_history WHERE module_id = (SELECT module_id FROM csr.module WHERE module_name = 'Baseline calculations');
DELETE FROM csr.module_param WHERE module_id = (SELECT module_id FROM csr.module WHERE module_name = 'Baseline calculations');
DELETE FROM csr.module WHERE module_name = 'Baseline calculations';
DELETE FROM csr.capability WHERE name = 'Baseline calculations';
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






@..\csr_data_pkg
@..\enable_pkg


@..\..\..\aspen2\cms\db\filter_body
@..\audit_body
@..\non_compliance_report_body
@..\supplier_body
@..\csr_data_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\company_body
@..\flow_body
@..\enable_body



@update_tail
