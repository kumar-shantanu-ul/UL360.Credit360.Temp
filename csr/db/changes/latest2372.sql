-- Please update version.sql too -- this keeps clean builds in sync
define version=2372
@update_header


CREATE SEQUENCE CSR.MODULE_ID
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    nocycle
    CACHE 5
    noorder;

--NO RLS
CREATE TABLE CSR.MODULE (
	module_id			NUMBER(10) NOT NULL,
	module_name			VARCHAR2(1023) NOT NULL,
	enable_sp			VARCHAR2(1023),
	description			VARCHAR2(1023),
	license_warning		NUMBER(1) DEFAULT NULL,
	CONSTRAINT pk_module_id PRIMARY KEY (module_id)
	USING INDEX
);

--NO RLS
CREATE TABLE CSR.MODULE_PARAM (
	module_id			NUMBER(10) NOT NULL,
	param_name			VARCHAR2(1023) NOT NULL,
	param_hint			VARCHAR2(1023),
	pos					NUMBER(2) NOT NULL,
  CONSTRAINT fk_module_param_id FOREIGN KEY (module_id)
	REFERENCES CSR.MODULE(module_id)
);

--web user now need to be able to execute the enable pkg
create or replace package csr.enable_pkg as end;
/
grant execute on csr.enable_pkg to web_user;
 
--Add the data
BEGIN
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (1, 'Create secondary region tree', 'CreateSecondaryRegionTree', 'Creates a secondary region hierarchy with the name specified.');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (2, 'Scorecarding', 'EnableActions', 'Enables scorecarding (formerly actions)');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
		VALUES (3, 'Audit', 'EnableAudit', 'Enables audits', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (4, 'Bounce tracking', 'EnableBounceTracking', 'Enables bounce tracking');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (5, 'Calendar', 'EnableCalendar', 'Enables the calendar');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (6, 'Carbon Emissions', 'EnableCarbonEmissions', 'Enables carbon emissions');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (7, 'Corp reporter', 'EnableCorpReporter', 'Enables corporate reporter');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (8, 'Custom issues', 'EnableCustomIssues', 'Enables custom issues');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (9, 'Deleg plan', 'EnableDelegPlan', 'Enables delegation planner');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (10, 'Divisions', 'EnableDivisions', 'Enables divisions');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (11, 'Document library', 'EnableDocLib', 'Enables the document library');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
		VALUES (12, 'Community', 'EnableDonations', 'Enables the community module (formerly donations)', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
		VALUES (13, 'Ethics', 'EnableEthics', 'Enables ethics, AKA evaluation', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
		VALUES (14, 'Excel models', 'EnableExcelModels', 'Enables excel models', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (15, 'Feeds', 'EnableFeeds', 'Enables RSS feeds');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (16, 'Image chart', 'EnableImageChart', 'Enables image charts');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (17, 'Issues 2', 'EnableIssues2', 'Enables version 2 of issues');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (18, 'Issues filtering', 'EnableIssuesFiltering', 'Enables issues filtering');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (19, 'Map', 'EnableMap', 'Enables the map module');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (20, 'Metering', 'EnableMetering', 'Enables metering');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (21, 'Portal', 'EnablePortal', 'Enables portal (system default)');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
		VALUES (22, 'Scenarios', 'EnableScenarios', 'Enables scenarios', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (23, 'Scheduled actions', 'EnableScheduledTasks', 'Enables scheduled actions');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (24, 'Sheets2', 'EnableSheets2', 'Enables version 2 of sheets (system default)');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (25, 'Surveys', 'EnableSurveys', 'Enable surverys');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (26, 'Templated reports', 'EnableTemplatedReports', 'Enables templated reports - word2 version');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (27, 'Workflow', 'EnableWorkflow', 'Enables workflows');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (28, 'Change branding', 'EnableChangeBranding', 'Enables the change branding page. Should not be run against live client sites.');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (29, 'Frameworks', 'EnableIndexes', 'Enables frameworks (GRI and CDP only)');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (30, 'Reporting indicators', 'EnableReportingIndicators', 'Enables reporting indicators');
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
		VALUES (31, 'Data explorer 5', 'EnableDE5', 'Upgrade a site from data explorer 4 to 5');


	--Add the params
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (1, 'secondaryTreeName', 0, 'The name you want for the secondary tree');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (7, 'siteName', 0, '');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (13, 'in_company_name', 0, '');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (15, 'in_user',      0, '');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	  VALUES (15, 'in_password',  1, '');
	  
	--Create the menu item for all sites
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_setup_menu				security.security_pkg.T_SID_ID;
			v_enable_menu				security.security_pkg.T_SID_ID;
			
		BEGIN
			BEGIN
				v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup',  'Setup',  '/csr/site/admin/config/global.acds',  0, null, v_setup_menu);
			END;
		
			BEGIN
				v_enable_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'csr_admin_enable');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'csr_admin_enable',  'Enable modules',  '/csr/site/admin/enable/enablePage.acds',  0, null, v_enable_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_enable_menu, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_enable_menu));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_enable_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	commit;
END;
/

@..\enable_pkg
@..\enable_body

@update_tail
