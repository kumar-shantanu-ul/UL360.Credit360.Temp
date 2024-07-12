CREATE OR REPLACE PACKAGE BODY CSR.disable_pkg IS

PROCEDURE DisableActions
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableAudit
AS
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	-- groups
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_auditors_sid				security.security_pkg.T_SID_ID;
	v_auditor_admins_sid		security.security_pkg.T_SID_ID;
	-- audits container
	v_audits_sid				security.security_pkg.T_SID_ID;
	-- menu
	v_menu_audit				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site_audit		security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	-- temp variables
	v_sid						security.security_pkg.T_SID_ID;
BEGIN	
	SELECT MIN(internal_audit_type_id)
	  INTO v_sid
	  FROM internal_audit_type
	 WHERE label = 'Default';
	 
	IF v_sid IS NOT NULL THEN
		audit_pkg.DeleteInternalAuditType(
			in_internal_audit_type_id		=> v_sid
		);
	END IF;
	
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	
	v_auditor_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Audit administrators');
	DELETE FROM csr.flow_state_role_capability WHERE group_sid = v_auditor_admins_sid;
	DELETE FROM csr.flow_state_role WHERE group_sid = v_auditor_admins_sid;
	security.securableobject_pkg.DeleteSO(v_act_id, v_auditor_admins_sid);
	
	v_auditors_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Audit users');
	DELETE FROM csr.flow_state_role_capability WHERE group_sid = v_auditors_sid;
	DELETE FROM csr.flow_state_role WHERE group_sid = v_auditors_sid;
	security.securableobject_pkg.DeleteSO(v_act_id, v_auditors_sid);
	
	v_audits_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Audits');
	security.securableobject_pkg.DeleteSO(v_act_id, v_audits_sid);
	
	v_menu_audit := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/ia');
	security.securableobject_pkg.DeleteSO(v_act_id, v_menu_audit);

	v_sid := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/admin/csr_default_non_compliances');
	security.securableobject_pkg.DeleteSO(v_act_id, v_sid);
	
	v_sid := security.securableobject_pkg.getSidFromPath(v_act_id, v_app_sid, 'menu/admin/non_compliance_types');
	security.securableobject_pkg.DeleteSO(v_act_id, v_sid);
	
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
	v_www_csr_site_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'audit');
	security.securableobject_pkg.DeleteSO(v_act_id, v_www_csr_site_audit);
	
	DELETE FROM inbound_issue_account WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM internal_audit_type_group WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;	
	DELETE FROM issue_custom_field WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_due_source WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_template WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_scheduled_task WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_type_aggregate_ind_grp WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_type_rag_status WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_type WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	
	DELETE FROM aggregate_ind_calc_job
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM aggregate_ind_group_member
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM aggregate_ind_val_detail
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM calc_job_aggregate_ind_group
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM flow
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM issue_type_aggregate_ind_grp
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM quick_survey
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	 
	DELETE FROM batch_job_data_bucket_agg_ind
 	 WHERE aggregate_ind_group_id IN (SELECT aggregate_ind_group_id FROM aggregate_ind_group WHERE name = 'InternalAudit');
	
	DELETE FROM aggregate_ind_group
	 WHERE name = 'InternalAudit';
	
	v_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities/Close audits');
	security.securableobject_pkg.DeleteSO(v_act_id, v_sid);
	
	DELETE FROM alert_template_body
	 WHERE customer_alert_type_id IN (SELECT customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id IN (45, 46));
	
	DELETE FROM alert_template
	 WHERE customer_alert_type_id IN (SELECT customer_alert_type_id FROM customer_alert_type WHERE std_alert_type_id IN (45, 46));
	
	DELETE FROM customer_alert_type
	 WHERE std_alert_type_id IN (45, 46);
	
	BEGIN 
		v_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Calendars/audits');
		security.securableobject_pkg.DeleteSO(v_act_id, v_sid);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	DELETE FROM flow_inv_type_alert_class WHERE flow_alert_class = 'audit';
	
	DELETE FROM flow_involvement_type WHERE product_area = 'audit';
	
	FOR R IN ( SELECT flow_sid FROM csr.flow WHERE flow_alert_class = 'audit')
	LOOP
		security.securableobject_pkg.DeleteSO(v_act_id, R.flow_sid);
	END LOOP;
	
	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'audit';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	chain.card_pkg.RemoveGroupCard('Survey Response Filter', 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter');
	chain.card_pkg.RemoveGroupCard('Internal Audit Filter', 'Credit360.Audit.Filters.InternalAuditFilter');
	chain.card_pkg.RemoveGroupCard('Internal Audit Filter', 'Credit360.Audit.Filters.AuditFilterAdapter');
	chain.card_pkg.RemoveGroupCard('Internal Audit Filter', 'Credit360.Audit.Filters.AuditCMSFilter');
	chain.card_pkg.RemoveGroupCard('Internal Audit Filter', 'Credit360.Audit.Filters.SurveyResponse');	
	chain.card_pkg.RemoveGroupCard('Non-compliance Filter', 'Credit360.Audit.Filters.NonComplianceFilter');
	chain.card_pkg.RemoveGroupCard('Non-compliance Filter', 'Credit360.Audit.Filters.NonComplianceFilterAdapter');
END;

PROCEDURE DisableAuditMaps
AS
BEGIN
	UPDATE customer
	   SET show_map_on_audit_list = 0
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE DisableAuditFiltering
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableAuditsOnUsers
AS
BEGIN
	UPDATE customer
	   SET audits_on_users = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DisableMultipleAuditSurveys
AS
BEGIN
	UPDATE customer
	   SET multiple_audit_surveys = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DisableBounceTracking

AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCompanyDedupePreProc
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableBsciIntegration
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCalendar
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCampaigns
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCarbonEmissions
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableChain(
	siteName IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableChainActivities
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableChainOneTier(
	in_site_name			IN VARCHAR2,
	in_top_company_name		IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableChainTwoTier(
	in_top_company_name		IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE CreateOwlClient(
	in_admin_access			IN VARCHAR2,
	in_handling_office		IN VARCHAR2,
	in_customer_name		IN VARCHAR2,
	in_parenthost			IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE CreateSectionStatus(
	in_act_id				security.security_pkg.T_ACT_ID,
	in_app_sid				security.security_pkg.T_SID_ID
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE CreateDocLibReportsFolder
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCorpReporter
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCustomIssues
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDelegPlan
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDivisions
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDocLib
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDonations
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableExcelModels
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableFeeds(
	in_user IN CSR_USER.user_NAME%TYPE,
	in_password IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableFilterAlerts
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableFogbugz(
	in_customer_fogbugz_project_id 	IN NUMBER,
	in_customer_fogbugz_area 		IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableGRESB(
	in_use_sandbox			IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableHigg (
	in_ftp_profile					VARCHAR2,
	in_ftp_folder					VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableImageChart
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableInitiatives (
	in_setup_base_data			IN VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableInitiativesAuditTab
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableIssues2
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMap
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeasureConversions
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisablePropertyMeterListTab
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisablePortal
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisablePortalPLSQL
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableRestAPI (
	in_Disable_guest_access IN VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableRReports
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableScenarios
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableScheduledTasks
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableSheets2
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableSupplierMaps
AS
BEGIN
	UPDATE chain.customer_options
	   SET show_map_on_supplier_list = 0
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE RemoveOWLClientModule(
	in_lookup_key1 IN	VARCHAR2,
	in_lookup_key2 IN	VARCHAR2
)
AS
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tables
		  WHERE owner = 'OWL' AND table_name = 'CLIENT_MODULE')
	LOOP
		EXECUTE IMMEDIATE
			'UPDATE owl.client_module SET enabled = 0, date_disabled = SYSDATE WHERE credit_module_id IN ('||CHR(10)||
				'SELECT credit_module_id'||CHR(10)||
				  'FROM owl.credit_module'||CHR(10)||
				 'WHERE ((:k1 IS NOT NULL AND :k2 IS NULL AND lookup_key = :k1) OR (:k1 IS NOT NULL AND :k2 IS NOT NULL AND lookup_Key IN (:k1, :k2))))'||CHR(10)||
			   'AND client_sid = security.security_pkg.getApp'
		USING in_lookup_key1, in_lookup_key2, in_lookup_key1, in_lookup_key1, in_lookup_key2, in_lookup_key1, in_lookup_key2;
	END LOOP;
END;

PROCEDURE DisableSurveys
--test data
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	-- surveys web resource
	v_surveys_sid					security.security_pkg.T_SID_ID;
	v_campaigns_sid					security.security_pkg.T_SID_ID;
	-- menu
	v_menu_survey_list				security.security_pkg.T_SID_ID;
	-- web resources
	v_www_sid						security.security_pkg.T_SID_ID;
	v_www_csr_quicksurvey			security.security_pkg.T_SID_ID;
	v_publish_survey_permission 	security_pkg.T_PERMISSION := 131072; -- from surveys.question_library_pkg.PERMISSION_PUBLISH_SURVEY
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	RemoveOWLClientModule('SURVEY_MGR', null);

	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	BEGIN
		v_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'surveys');	
		security.acl_pkg.DeleteAllACES(v_act_id, acl_pkg.GetDACLIDForSID(v_surveys_sid));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_menu_survey_list := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin/csr_quicksurvey_admin');
		securableobject_pkg.DeleteSO(v_act_id, v_menu_survey_list);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_www_csr_quicksurvey := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site/quickSurvey');
		securableobject_pkg.DeleteSO(v_act_id, v_www_csr_quicksurvey);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN	
		chain.card_pkg.RemoveGroupCard('Simple Survey Filter', 'QuickSurvey.Cards.SurveyResultsFilter');
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	BEGIN
		chain.card_pkg.RemoveGroupCard('Survey Response Filter', 'Credit360.QuickSurvey.Filters.SurveyResponseFilter');
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	BEGIN
		v_campaigns_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'campaigns');
		security.acl_pkg.DeleteAllACES(v_act_id, acl_pkg.GetDACLIDForSID(v_campaigns_sid));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
END;

PROCEDURE DisableTemplatedReports
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableWorkflow
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableChangeBranding
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableFrameworks
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableReportingIndicators
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableAutomatedExportImport
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableApprovalDashboards
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDelegationSummary
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMultipleDashboards
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDelegationReports
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDelegationStatusReports
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableAuditLogReports
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DsableDashboardAuditLogReports
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableAlert(
	in_std_alert_type_id			IN NUMBER
)
AS
	v_customer_alert_type_id		NUMBER;
BEGIN
	BEGIN
		SELECT customer_alert_type_id
		  INTO v_customer_alert_type_id
		  FROM customer_alert_type
		 WHERE std_alert_type_id = in_std_alert_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RETURN;
	END;

	DELETE FROM alert_template_body
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	DELETE FROM alert_template
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	DELETE FROM alert_batch_run
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	DELETE FROM customer_alert_type
	 WHERE std_alert_type_id = in_std_alert_type_id;
END;

PROCEDURE DisableDataChangeRequests
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisablePropertyDashboards
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableChainCountryRisk
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableEnergyStar
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableOwlSupport
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCompanySelfReg
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

--- METERING ---
PROCEDURE DisableMeteringBase
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeterUtilities
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableRealtimeMetering
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeteringFeeds
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeterMonitoring
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeterReporting
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeteringGapDetection
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableMeteringAutoPatching
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableUrjanet (
	in_ftp_path						IN  VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableManagementCompanyTree
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableLikeforlike
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDegreeDays(
	in_account_name					degreeday_settings.account_name%TYPE
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableTraining
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableSSO
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DsableCapabilitiesUserListPage
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableComplianceBase
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCompliance (
	in_disable_regulation_flow		IN	VARCHAR2,
	in_disable_requirement_flow		IN	VARCHAR2,
	in_disable_campaign				IN	VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableEnhesa(
	in_client_id					IN	enhesa_options.client_id%TYPE
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableIncidents
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableProperties(
	in_company_name		IN	VARCHAR2,
	in_property_type	IN	VARCHAR2
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableEmFactorsClassicTool(
	in_disable			IN	NUMBER,
	in_position			IN	NUMBER
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableEmFactorsProfileTool(
	in_disable			IN	NUMBER,
	in_position			IN	NUMBER
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableDocLibDocTypes
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableForecasting
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisablePropertyDocLib
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableTranslationsImport
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableProductCompliance
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableCapability (
	in_name							VARCHAR2
)
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_capability_sid				security_pkg.T_SID_ID;
BEGIN
	v_capability_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/' || in_name);
	securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
END;

PROCEDURE DisableQuestionLibrary
AS
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;

	-- groups
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_group_sid						security.security_pkg.T_SID_ID;
	-- menu
	v_root_menu_sid					security_pkg.T_SID_ID;
	v_admin_menu_sid				security_pkg.T_SID_ID;
	v_library_menu_sid				security_pkg.T_SID_ID;
	v_menu_survey_list				security.security_pkg.T_SID_ID;
	
	-- web resources
	v_www_sid						security_pkg.T_SID_ID;
	v_www_csr_quicksurvey			security_pkg.T_SID_ID;
	v_www_csr_quicksurvey_library	security_pkg.T_SID_ID;
	v_www_surveys_sid				security_pkg.T_SID_ID;
	v_www_api_surveys_sid			security_pkg.T_SID_ID;

	-- question library permissions
	v_question_library_sid			security_pkg.T_SID_ID;

	-- SurveyAuthorisedGuest user sid
	v_sag_sid						security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAdmin(v_act_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can run DisableQuestionLibrary');
	END IF;

	v_www_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_root_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	v_admin_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_root_menu_sid, 'admin');

	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');

	-- delete groups
	BEGIN
		v_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Question library admins');
		security.group_pkg.DeleteGroup(v_act_id, v_group_sid);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_group_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Question library editors');
		security.group_pkg.DeleteGroup(v_act_id, v_group_sid);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_www_csr_quicksurvey := securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site/quickSurvey');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_www_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'surveys');	
		security.acl_pkg.DeleteAllACES(v_act_id, acl_pkg.GetDACLIDForSID(v_www_surveys_sid));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_www_csr_quicksurvey_library := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_quicksurvey, 'library');	
		securableobject_pkg.DeleteSO(v_act_id, v_www_csr_quicksurvey_library);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_library_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_admin_menu_sid, 'csr_question_library');
		securableobject_pkg.DeleteSO(v_act_id, v_library_menu_sid);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_library_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_admin_menu_sid, 'csr_question_library_surveys');
		securableobject_pkg.DeleteSO(v_act_id, v_library_menu_sid);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_www_api_surveys_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'api.surveys');	
		securableobject_pkg.DeleteSO(v_act_id, v_www_api_surveys_sid);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		v_question_library_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'QuestionLibrary');
		security.acl_pkg.DeleteAllACES(v_act_id, acl_pkg.GetDACLIDForSID(v_question_library_sid));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	UPDATE csr.customer
	   SET question_library_enabled = 0
	 WHERE app_sid = v_app_sid;
	
	SELECT MIN(csr_user_sid)
	  INTO v_sag_sid
	  FROM csr_user
	 WHERE user_name = 'surveyauthorisedguest';
	
	BEGIN
		securableobject_pkg.DeleteSO(v_act_id, v_sag_sid);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	BEGIN
		DisableCapability('System management');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
END;

PROCEDURE DisableFileSharingApi(
	in_provider_hint			IN	VARCHAR2 DEFAULT NULL,
	in_switch_confirmation		IN	NUMBER DEFAULT 0
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;


PROCEDURE DisablePermitsDocLib
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisablePermits
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableApiIntegrations
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableHrIntegration(
	in_disable			IN	NUMBER
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableRegionEmFactorCascading(
	in_disable			IN	NUMBER
)
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableRegionFiltering
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableValuesApi
AS
BEGIN
	RAISE_APPLICATION_ERROR(-20001, 'Not implemented');
END;

PROCEDURE DisableAmforiIntegration
AS
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_bsci_19_audit_type_id 		security.security_pkg.T_SID_ID;
	v_workflow_sid					security.security_pkg.T_SID_ID;
	v_tag_group_id					tag_group.tag_group_id%TYPE;
	PROCEDURE RemoveClosureType(
		in_audit_type_id			csr.internal_audit_type.internal_audit_type_id%TYPE,
		in_label					VARCHAR2,
		in_lookup					VARCHAR2
	) AS
		v_audit_closure_type_id			csr.audit_closure_type.audit_closure_type_id%TYPE;
	BEGIN
		SELECT MAX(audit_closure_type_id)
		  INTO v_audit_closure_type_id
		  FROM csr.audit_closure_type
		 WHERE app_sid = security.security_pkg.GetApp
		   AND lookup_key = in_lookup;
		
		DELETE FROM csr.audit_type_closure_type WHERE audit_closure_type_id = v_audit_closure_type_id;
		
		DELETE FROM csr.audit_closure_type WHERE audit_closure_type_id = v_audit_closure_type_id;
	END;
BEGIN
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	SELECT MIN(internal_audit_type_id)
	  INTO v_bsci_19_audit_type_id
	  FROM internal_audit_type
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'AMFORI_BSCI';

	IF v_bsci_19_audit_type_id IS NOT NULL THEN
		RemoveClosureType(v_bsci_19_audit_type_id, 'A', 'A');
		RemoveClosureType(v_bsci_19_audit_type_id, 'B', 'B');
		RemoveClosureType(v_bsci_19_audit_type_id, 'C', 'C');
		RemoveClosureType(v_bsci_19_audit_type_id, 'D', 'D');
		RemoveClosureType(v_bsci_19_audit_type_id, 'E', 'E');
		
		DELETE FROM internal_audit_type_tag_group WHERE internal_audit_type_id = v_bsci_19_audit_type_id;
		
		audit_pkg.DeleteInternalAuditType(v_bsci_19_audit_type_id);
	END IF;
	
	SELECT MIN(tag_group_id)
	  INTO v_tag_group_id
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'AMFORI_ANNOUNCE';
	
	IF v_tag_group_id IS NOT NULL THEN 
		tag_pkg.DeleteTagGroup(
			in_act_id			=> v_act_id,
			in_tag_group_id		=> v_tag_group_id
		);
	END IF;
	
	SELECT MIN(tag_group_id)
	  INTO v_tag_group_id
	  FROM tag_group
	 WHERE app_sid = security.security_pkg.getapp
	   AND UPPER(lookup_key) = 'AMFORI_MONITORING';
	
	IF v_tag_group_id IS NOT NULL THEN 
		tag_pkg.DeleteTagGroup(
			in_act_id			=> v_act_id,
			in_tag_group_id		=> v_tag_group_id
		);
	END IF;
	
	DELETE FROM chain.reference WHERE lookup_key = 'AMFORI_SITEAMFORIID';
	DELETE FROM chain.reference WHERE lookup_key = 'AMFORI_COMPANYAMFORIID';

	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Amfori_BSCI');
		
		security.securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), v_workflow_sid);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;		
END;

END disable_pkg;
/
