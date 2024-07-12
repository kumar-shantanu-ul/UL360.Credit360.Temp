DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
	v_attribute_id	security.security_pkg.T_ATTRIBUTE_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- create csr app classes (inherits from aspenapp)
	BEGIN	
		security.class_pkg.CreateClass(v_act, security.class_pkg.getclassid('aspenapp'), 'CSRApp', 'csr.csr_app_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id := security.class_pkg.GetClassId('CSRApp');
	END;	
	BEGIN
		-- add an alter schema permission to the app object
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter schema');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- create csr classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRMeasure', 'csr.measure_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRMeasure');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter schema');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRIndicator', 'csr.indicator_pkg', NULL, new_class_id);
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'Pos', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.getClassID('CSRIndicator');
	END;
	BEGIN	
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_SET_TARGET, 'Set target');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, csr.Csr_Data_Pkg.PERMISSION_SET_TARGET);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter schema');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRRegion', 'csr.region_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRRegion');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter schema');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, security.security_pkg.SO_USER, 'CSRUser', 'csr.csr_user_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.getClassID('CSRUser');
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, '_language', 0, null, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, '_culture', 0, null, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, '_timezone', 0, null, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'details-confirmed', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'profile', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_LOGON_AS_USER, 'Logon as another user');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, security.security_pkg.SO_GROUP, 'CSRUserGroup', NULL, NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.getClassID('CSRUserGroup');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_LOGON_AS_USER, 'Logon as another user');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- create delegation class
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRDelegation', 'csr.delegation_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRDelegation');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter delegation details');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_CHANGE_PERMISSIONS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_OVERRIDE_DELEGATOR, 'Override delegator');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_TAKE_OWNERSHIP, new_class_id, csr.Csr_Data_Pkg.PERMISSION_OVERRIDE_DELEGATOR);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- create objective class
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRObjective', 'csr.objective_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRObjective');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_SET_STATUS, 'Set status');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, csr.Csr_Data_Pkg.PERMISSION_SET_STATUS);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- create dashboard class
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRDashboard', 'csr.target_dashboard_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRDashboard');
	END;
	-- create dataview classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRDataView', 'csr.dataview_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRDataView');
	END;
	-- create impSession class
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRImpSession', 'csr.imp_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRImpSession');
	END;
	-- create fileupload class
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRFileUpload', 'csr.fileupload_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRFileUpload');
	END;
	-- create form classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRForm', 'csr.form_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRForm');
	END;
	--- Report Index classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRReportIndex', 'csr.report_index_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRReportIndex');
	END;
	-- TRASH CAN
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'TrashCan', 'csr.trash_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.getClassID('TrashCan');
	END;
	BEGIN	
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_RESTORE_FROM_TRASH, 'Restore from trash');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, csr.Csr_Data_Pkg.PERMISSION_RESTORE_FROM_TRASH);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
	-- CSRQuickSURVEY
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRQuickSurvey', 'csr.quick_survey_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRQuickSurvey');
	END;
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> security.security_pkg.SO_WEB_RESOURCE,
			in_permission			=> csr.Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS,
			in_permission_name		=> 'View all results'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> security.security_pkg.SO_WEB_RESOURCE,
			in_permission			=> csr.Csr_Data_Pkg.PERMISSION_PUBLISH,
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	BEGIN	
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS, 'View all results');
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_PUBLISH, 'Publish survey');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, csr.Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS);
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_WEB_RESOURCE, csr.Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- CSRFeed
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRFeed', 'csr.feed_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRFeed');
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'support-details', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	-- ReportingPeriod
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRReportingPeriod', 'csr.reporting_period_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRReportingPeriod');
	END;
	BEGIN
		security.class_pkg.CreateClass(v_act, security.class_pkg.GetClassId('Container'), 'DocFolder', 'csr.doc_folder_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DocFolder');
	END;	

	BEGIN
		security.class_pkg.CreateClass(v_act, security.class_pkg.GetClassId('Container'), 'DocLibrary', 'csr.doc_lib_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DocLibrary');
	END;	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRRegionTree', 'csr.region_tree_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRRegionTree');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter schema');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- create RSS classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'RssFeed', 'csr.rss_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('RssFeed');
	END;
	-- create Role classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRRole', 'csr.role_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRRole');
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_LOGON_AS_USER, 'Logon as another user');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	-- create CSRCapability class
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRCapability', null, NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRCapability');
	END;
	-- Create CSRModel and CSRModelInstance Classes
	BEGIN	
    security.class_pkg.CreateClass(v_act, NULL, 'CSRModel', 'csr.model_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRModel');
	END;
  BEGIN
      security.class_pkg.CreateClass(v_act, NULL, 'CSRModelInstance', 'csr.model_pkg', NULL, new_class_id);
  EXCEPTION
      WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        new_class_id:=security.class_pkg.GetClassId('CSRModelInstance');
  END;
	BEGIN
        security.class_pkg.CreateClass(v_act, NULL, 'CSRTemplatedReport', 'csr.templated_report_pkg', NULL, new_class_id);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            NULL;
    END;
    BEGIN
        security.class_pkg.CreateClass(v_act, NULL, 'CSRDelegationPlan', 'csr.deleg_plan_pkg', NULL, new_class_id);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            NULL;
    END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRSqlReport', NULL, NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRAudit', 'csr.audit_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRScenario', 'csr.scenario_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRScenarioRun', 'csr.scenario_run_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRScenarioRunSnapshot', 'csr.scenario_run_snapshot_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRFlow', 'csr.flow_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRApprovalDashboard', 'csr.approval_dashboard_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRMetricDashboard', 'csr.metric_dashboard_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRBenchmarkingDashboard', 'csr.benchmarking_dashboard_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRSurveyCampaign', 'campaigns.campaign_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	-- create section root class
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRSectionRoot', 'csr.section_root_pkg', NULL, new_class_id);
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_CHANGE_TITLE, 'Change Title');
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_DOC_ADMIN, 'Doc Admin Menu');
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE, 'Edit section module');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.csr_data_pkg.PERMISSION_CHANGE_TITLE);
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, csr.csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRSectionRoot');
	END;
	BEGIN
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'root-menu-name', 0, NULL, v_attribute_id);
		security.Attribute_Pkg.CreateDefinition(v_act, new_class_id, 'root-menu-description', 0, NULL, v_attribute_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	-- create text section classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRSection', 'csr.section_pkg', NULL, new_class_id);
        security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_CHANGE_TITLE, 'Change Title');
		security.class_pkg.AddPermission(v_act, new_class_id, csr.csr_data_pkg.PERMISSION_DOC_ADMIN, 'Doc Admin Menu');
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRSection');
	END;

	BEGIN
		security.class_pkg.CreateClass(v_act, NULL, 'SectionStatus', 'csr.section_status_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('SectionStatus');
	END;
	
	BEGIN	
	security.class_pkg.CreateClass(v_act, NULL, 'SectionStatusTransition', 'csr.section_transition_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('SectionStatusTransition');
	END;
	-- create help classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRHelpTopic', 'csr.help_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRHelpTopic');
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRImgChart', 'csr.img_chart_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRImgChart');
	END;
	-- Create energy star classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'EnergyStarAccount', 'csr.energy_star_account_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('EnergyStarAccount');
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'EnergyStarCustomer', 'csr.energy_star_customer_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('EnergyStarCustomer');
	END;
	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRPortlet', NULL, NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRPortlet');
	END;
	--
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRRuleSet', NULL, NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('CSRRuleSet');
	END;
	-- Create calendar class type
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRCalendar', 'csr.calendar_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'CSRExportFeed', 'csr.export_feed_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	-- Create initiatives classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'InitiativeProject', 'csr.initiative_project_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'Initiative', 'csr.initiative_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, null, 'Teamroom', 'csr.teamroom_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ADMINISTER_TEAMROOM, 'Administer teamroom');
		security.class_pkg.createmapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_TAKE_OWNERSHIP, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ADMINISTER_TEAMROOM);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'GeoMap', 'csr.geo_map_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRAutomatedImport', 'csr.automated_import_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRAutomatedExport', 'csr.automated_export_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRLikeForLike', 'csr.like_for_like_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRPortalDashboard', 'csr.portal_dashboard_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, security.class_pkg.GetClassId('Mailbox'), 'CSRMailbox', 'csr.mailbox_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.class_pkg.CreateClass(v_act, NULL, 'CSRForecasting', 'csr.forecasting_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN
		security.user_pkg.logonadmin;
		security.class_pkg.CreateClass(v_act, null, 'CSRDataBucket', 'csr.data_bucket_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	BEGIN   
		security.user_pkg.logonadmin;
		security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRTemplatedReportsSchedule', 'csr.templated_report_schedule_pkg', null, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	--
	security.user_pkg.LOGOFF(v_ACT);
END;
/
commit;

