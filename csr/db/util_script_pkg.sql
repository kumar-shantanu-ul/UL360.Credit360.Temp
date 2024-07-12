CREATE OR REPLACE PACKAGE CSR.util_script_pkg IS

ERR_INTEGRITY_CONSTRAINT CONSTANT NUMBER := -2291;

PROCEDURE AddNewBranding(
	in_folder IN VARCHAR2,
	in_brandname IN VARCHAR2,
	in_author IN VARCHAR2
);

PROCEDURE CreateDelegationSheetsFuture(
	in_deleg_sid			NUMBER,
	in_date					VARCHAR2
);

PROCEDURE RecalcOneRestricted(
	in_start_year	NUMBER,
	in_end_year		NUMBER
);

PROCEDURE RecalcOne;

PROCEDURE CreateImapFolder(
	in_folder_name			VARCHAR2,
	in_suffixes				VARCHAR2
);

PROCEDURE CreateCustomDelegLayout(
	in_deleg_sid			NUMBER
);

PROCEDURE ToggleDelegMultiPeriodFlag(
	in_deleg_sid			NUMBER
);

PROCEDURE AddQualityFlags;

PROCEDURE SetStartMonth(
	in_start_month			NUMBER,
	in_start_year			NUMBER,
	in_end_year				NUMBER
);

PROCEDURE AddMissingAlert (
	in_std_alert_type_id   NUMBER
);

PROCEDURE SetToleranceChkrMergedDataReq(
	in_setting			NUMBER
);

PROCEDURE MapindicatorsFromSurvey(
	in_survey_sid		NUMBER,
	in_score_type_id	NUMBER
);

PROCEDURE SetSelfRegistrationPermissions(
	in_setting			IN	NUMBER
);

PROCEDURE FixPropertyCompanyRegionTree(
	in_root_region_sid			IN	NUMBER
);

PROCEDURE EnableMeterWashingMachine;

PROCEDURE SynchScoreTypeAggTypes;

PROCEDURE EnableCalculationSurveyScore;

PROCEDURE SyncDelegPlanNames(
    in_deleg_template_sid           IN NUMBER
);

PROCEDURE SetAutoPCSheetStatusFlag(
    in_flag_value                   IN NUMBER
);

PROCEDURE AllowOldChartEngine(
	in_allow			IN	NUMBER
);

PROCEDURE ChartAlgorithmVersion(
	in_ver			IN	NUMBER
);

PROCEDURE AddNewRelicToSite;
PROCEDURE RemoveNewRelicFromSite;

PROCEDURE SetCDNServer (
	in_cdn_server_name	IN	VARCHAR2
);

PROCEDURE RemoveCDNServer;

PROCEDURE SetUserPickerExtraFields(
	in_extra_fields				IN	customer.user_picker_extra_fields%TYPE
);

PROCEDURE AddMissingProperties(
	in_property_type		IN	VARCHAR2
);

PROCEDURE AddMissingCompanyDocFolders;

PROCEDURE RecordTimeInFlowStates (
	in_flow_sid			IN flow.flow_sid%TYPE
);

PROCEDURE ClearLastUsdMeasureConversions (
	in_user_sid			NUMBER
);

PROCEDURE MigrateEmissionFactorTool (
	in_profile_name			VARCHAR2
);

PROCEDURE ResyncDefaultComplianceFlows;

PROCEDURE ResyncDefaultPermitFlows;

PROCEDURE SetBatchJobTimeoutOverride(
	in_batch_job_type_id		NUMBER,
	in_timeout_mins				NUMBER
);

PROCEDURE ShowHideDelegPlan (
	in_deleg_plan_sid		IN  deleg_plan.deleg_plan_sid%TYPE,
	in_show					IN  NUMBER
);

PROCEDURE ChangeIntApiCompanyUserGroup(
	in_group_name			IN	VARCHAR2,
	in_delete				IN	NUMBER DEFAULT 0
);

PROCEDURE CreateAPIClient(
	in_user_name			IN	VARCHAR2,
	in_client_id			IN	VARCHAR2,
	in_client_secret		IN	VARCHAR2
);

PROCEDURE UpdateAPIClientSecret(
	in_client_id			IN	VARCHAR2,
	in_client_secret		IN	VARCHAR2
);

PROCEDURE CreateProfilesForUsers;

PROCEDURE SetUserRegionRoleLazyLoad(
	in_lazy_load				IN	customer.lazy_load_role_membership%TYPE
);

PROCEDURE SetCalcFutureWindow(
	in_calc_future_window				IN	customer.calc_future_window%TYPE
);

PROCEDURE SetCalcStartDate(
	in_date								IN	VARCHAR2
);

PROCEDURE RemoveMatrixLayout(
	in_deleg_sid			IN	security.security_pkg.T_SID_ID
);

PROCEDURE CreateUniqueMatrixLayoutCopy(
	in_deleg_sid			IN	security.security_pkg.T_SID_ID
);

PROCEDURE DeleteOutOfScopeCompItems(
	in_delete_comp_items_w_issues		IN	VARCHAR2		-- 'y' = also delete compliance items with issues and sched issues.
);

PROCEDURE SetEnhesaDupesOutOfScope;

PROCEDURE RestartFailedCampaign(
	in_campaign_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE GeotagCompanies;

PROCEDURE ResubmitFailedRawMeterData(
	in_from_dtm				IN	VARCHAR2
);

PROCEDURE EnableMeteringSameDayAvg(
	in_enable				IN	NUMBER
);

PROCEDURE EnableMeteringCoreSameDayAvg(
	in_enable				IN	NUMBER
);

PROCEDURE EnableMeteringCoreDayNorm(
	in_enable				IN	NUMBER
);

PROCEDURE EnableMeteringCoreExtended(
	in_enable				IN	NUMBER
);

PROCEDURE EnableMeteringDayStats(
	in_enable				IN	NUMBER
);

PROCEDURE EnableUrjanetStatementIdAggr(
	in_enable				IN	NUMBER
);

PROCEDURE EnableDisplayCookiePolicy(
	in_enable				IN	NUMBER
);

PROCEDURE EnableUrjanetRenewEnergy(
	in_enable				IN	NUMBER
);

PROCEDURE CanMigrateAudits;

PROCEDURE EnableTestCube;

PROCEDURE EnableScragPP(
	in_approved_ref					IN VARCHAR2 DEFAULT NULL
);

PROCEDURE MigrateAudits(
	in_force				IN	NUMBER DEFAULT 0
);

PROCEDURE ClearTrashedIndCalcXml(
	in_ind_sid					IN csr.ind.ind_sid%TYPE
);

PROCEDURE EnableCCOnAlerts;

PROCEDURE DisableCCOnAlerts;

PROCEDURE SetCustomerHelperAssembly(
	in_helper_assembly			IN VARCHAR2 DEFAULT NULL
);

FUNCTION SanitiseIndDescForXml(
	in_description		IN	csr.ind_description.description%TYPE
)
RETURN VARCHAR2;

PROCEDURE SetCmsFormsImpSP(
	in_form_id					IN VARCHAR2,
	in_helper_sp				IN VARCHAR2,
	in_delete					IN VARCHAR2,
	in_use_new_sp_sig			IN VARCHAR2,
	in_child_helper_sp			IN VARCHAR2
);

PROCEDURE SetCalcDependenciesInDataview(
	in_calc_ind_sid				IN	csr.ind.ind_sid%TYPE,
	in_dataview_sid				IN	csr.dataview.dataview_sid%TYPE
);

PROCEDURE CreateAllDataExport(
	in_export_name		IN	automated_export_class.label%TYPE,
	in_dataview_sid		IN	csr.dataview.dataview_sid%TYPE
);

PROCEDURE TerminatedClientData(
	in_setup			IN 	NUMBER
);

PROCEDURE ToggleViewSourceToDeepestSheet(
	in_enable			IN	NUMBER
);

/*
	Util script page procedures

	Please place the actual enable scripts above this block.
*/
FUNCTION CleanLookupKey (
	in_label	VARCHAR2
)
RETURN VARCHAR2;

PROCEDURE AddClientUtilScript(
    in_util_script_name             IN  client_util_script.util_script_name%TYPE,
    in_description                  IN  client_util_script.description%TYPE,
    in_util_script_sp               IN  client_util_script.util_script_sp%TYPE,
    in_wiki_article                 IN  client_util_script.wiki_article%TYPE,
    out_util_script_id              OUT client_util_script.client_util_script_id%TYPE
);

PROCEDURE AddClientUtilScriptParam(
    in_client_util_script_id        IN client_util_script_param.client_util_script_id%TYPE,
    in_param_name                   IN client_util_script_param.param_name%TYPE,
    in_param_hint                   IN client_util_script_param.param_hint%TYPE,
    in_param_pos                    IN client_util_script_param.pos%TYPE,
    in_param_value                  IN client_util_script_param.param_value%TYPE,
    in_param_hidden                 IN client_util_script_param.param_hidden%TYPE
);

PROCEDURE GetAllUtilScripts(
    out_generic_cur                 OUT SYS_REFCURSOR,
    out_specific_cur                OUT SYS_REFCURSOR
);

PROCEDURE GetUtilScriptParams(
	in_util_script_id	IN util_script.util_script_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetClientUtilScriptParams(
	in_client_util_script_id	IN client_util_script.client_util_script_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetEnableSP(
	in_util_script_id	IN util_script.util_script_id%TYPE,
	out_script_sp		OUT util_script.util_script_sp%TYPE
);

PROCEDURE GetClientEnableSP(
	in_client_util_script_id	IN  client_util_script.client_util_script_id%TYPE,
	out_script_sp				OUT client_util_script.util_script_sp%TYPE
);

PROCEDURE LogScriptRun(
	in_util_script_id	IN	util_script.util_script_id%TYPE,
	in_user_sid			IN	util_script_run_log.csr_user_sid%TYPE,
	in_param_string		IN	util_script_run_log.params%TYPE
);

PROCEDURE LogClientScriptRun(
	in_client_util_script_id	IN	client_util_script.client_util_script_id%TYPE,
	in_user_sid					IN	util_script_run_log.csr_user_sid%TYPE,
	in_param_string				IN	util_script_run_log.params%TYPE
);

PROCEDURE SetRegionLookupKey(
	in_region_sid				IN SECURITY_PKG.T_SID_ID,
	in_lookup_key				IN csr.region.lookup_key%TYPE
);

PROCEDURE EnableJavaAuth;

PROCEDURE DisableJavaAuth;

PROCEDURE SetupStandaloneIssueType;

PROCEDURE RecalcLogistics (
	in_transport_mode			IN transport_mode.transport_mode_id%TYPE
);

PROCEDURE ToggleRenderChartsAsSvg;

PROCEDURE SetAuditCalcChangesFlag(
	in_flag_value				IN NUMBER
);

PROCEDURE SetCheckToleranceAgainstZeroFlag(
	in_flag_value				IN NUMBER
);

PROCEDURE ResetAnonymisePiiDataPermissions;

PROCEDURE CreateChainSystemAdminRole(
	in_secondary_company_type_id	IN  chain.company_type.company_type_id%TYPE
);

PROCEDURE CreateSupplierAdminRole(
	in_secondary_company_type_id	IN  chain.company_type.company_type_id%TYPE
);

END util_script_pkg;
/
