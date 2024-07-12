CREATE OR REPLACE PACKAGE CSR.enable_pkg IS

/*
	Enable page procedures
*/

PROCEDURE GetAllModules(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetModuleParams(
	in_module_id	IN MODULE.module_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetEnableModule(
	in_module_id	IN MODULE.module_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE LogEnableAction(
	in_module_id	IN MODULE.module_id%TYPE,
	in_user_sid		IN security.security_pkg.T_SID_ID
);
/*
	End Enable page procedures
	Please place the actual enable scripts below this block.
*/


PROCEDURE CreateSecondaryRegionTree(
	secondaryTreeName IN VARCHAR2
);

PROCEDURE EnableActions;

PROCEDURE EnableAudit;

PROCEDURE EnableAuditMaps;

PROCEDURE EnableAuditFiltering;

PROCEDURE EnableAuditsOnUsers;

PROCEDURE EnableMultipleAuditSurveys;

PROCEDURE EnableBounceTracking;

PROCEDURE EnableCompanyDedupePreProc;

PROCEDURE EnableAmforiIntegration;

PROCEDURE EnableCalendar;

PROCEDURE EnableCampaigns;

PROCEDURE EnableCarbonEmissions;

-- TODO : Remove this as it creates a broken site
PROCEDURE EnableChain(
	siteName IN VARCHAR2
);

PROCEDURE EnableChainActivities;

PROCEDURE EnableChainOneTier(
	in_site_name			IN VARCHAR2,
	in_top_company_name		IN VARCHAR2
);

PROCEDURE EnableChainTwoTier(
	in_top_company_name		IN VARCHAR2
);

PROCEDURE CreateOwlClient(
	in_admin_access IN VARCHAR2,
	in_handling_office IN VARCHAR2,
	in_customer_name IN VARCHAR2,
	in_parenthost IN VARCHAR2
);

PROCEDURE EnableCorpReporter;

PROCEDURE EnableCustomIssues;

PROCEDURE EnableDelegPlan;

PROCEDURE EnableDivisions;

PROCEDURE EnableDocLib;

PROCEDURE EnableDonations;

PROCEDURE EnableExcelModels;

PROCEDURE EnableFeeds(
	in_user IN CSR_USER.user_NAME%TYPE,
	in_password IN VARCHAR2
);

PROCEDURE EnableFilterAlerts;

PROCEDURE EnableFogbugz(
	in_customer_fogbugz_project_id IN NUMBER,
	in_customer_fogbugz_area IN VARCHAR2
);

FUNCTION IsGRESBEnabled
RETURN NUMBER;

PROCEDURE EnableGRESB(
	in_environment				IN VARCHAR2,
	in_floor_area_measure_type	IN VARCHAR2
);

PROCEDURE DisableGRESB;

PROCEDURE EnableHigg (
	in_ftp_profile					VARCHAR2,
	in_ftp_folder					VARCHAR2
);

PROCEDURE EnableImageChart;

PROCEDURE EnableInitiatives(
	in_setup_base_data			IN VARCHAR2,
	in_metrics_end_year			IN NUMBER
);

PROCEDURE EnableInitiativesAuditTab;

PROCEDURE EnableIssues2;

PROCEDURE EnableLandingPages;
PROCEDURE DisableLandingPages;

PROCEDURE EnableMeasureConversions;

PROCEDURE EnableCompanySelfReg;

PROCEDURE EnablePropertyMeterListTab;

PROCEDURE EnablePortal;

PROCEDURE EnablePortalPLSQL;

PROCEDURE EnableRestAPI (
	in_enable_guest_access IN VARCHAR2 DEFAULT NULL
);

PROCEDURE EnableDroidAPI (
	in_enable_guest_access IN VARCHAR2 DEFAULT NULL
);

PROCEDURE EnableRReports;

PROCEDURE EnableRBAIntegration;
PROCEDURE DisableRBAIntegration;
PROCEDURE DeleteRBAIntegration;

PROCEDURE EnableSalesSite;

PROCEDURE EnableScenarios;

PROCEDURE EnableScheduledTasks;

PROCEDURE EnableSheets2;

PROCEDURE EnableSupplierMaps;

PROCEDURE EnableSurveys;

PROCEDURE EnableTemplatedReports;

PROCEDURE EnableWorkflow;

PROCEDURE InsertIntoOWLClientModule(
	in_lookup_key1 IN VARCHAR2,
	in_lookup_key2 IN VARCHAR2
);

PROCEDURE EnableChangeBranding;

PROCEDURE EnableFrameworks;

PROCEDURE EnableReportingIndicators;

PROCEDURE EnableAutomatedExportImport;

FUNCTION IsDashboardsEnabled
RETURN NUMBER;

PROCEDURE EnableApprovalDashboards;

PROCEDURE EnableDelegationSummary;

PROCEDURE EnableMultipleDashboards;

PROCEDURE EnableDelegationReports;

PROCEDURE EnableDelegationStatusReports;

PROCEDURE EnableFactorStartMonth(
	in_enable			IN	NUMBER
);

PROCEDURE EnableAuditLogReports;

PROCEDURE EnableDashboardAuditLogReports;

PROCEDURE EnableDataChangeRequests;

PROCEDURE EnablePropertyDashboards;

PROCEDURE EnableChainCountryRisk;

FUNCTION IsEnergyStarEnabled
RETURN NUMBER;

PROCEDURE EnableEnergyStar;

PROCEDURE SetDisabledChartFeatureFlags(
	in_data_explorer_show_ranking	IN	customer.data_explorer_show_ranking%TYPE,
	in_data_explorer_show_markers	IN	customer.data_explorer_show_markers%TYPE,
	in_data_explorer_show_trends	IN	customer.data_explorer_show_trends%TYPE,
	in_data_explorer_show_scatter	IN	customer.data_explorer_show_scatter%TYPE,
	in_data_explorer_show_radar		IN	customer.data_explorer_show_radar%TYPE,
	in_data_explorer_show_gauge		IN	customer.data_explorer_show_gauge%TYPE,
	in_data_explorer_show_wfall		IN	customer.data_explorer_show_waterfall%TYPE
);

PROCEDURE GetSidOrNullFromPath(
	in_parent_sid	IN security.security_pkg.T_SID_ID,
	in_path			IN VARCHAR2,
	out_sid_id		OUT security.security_pkg.T_SID_ID);

/**
 * Creates the support menu items and OwlSupport user group
 */
PROCEDURE EnableOwlSupport;


/**
 * METERING
 */

PROCEDURE EnableMeteringBase;

PROCEDURE EnableMeterUtilities;

PROCEDURE EnableRealtimeMetering;

PROCEDURE EnableMeteringFeeds;

PROCEDURE EnableMeterMonitoring;

PROCEDURE EnableMeterReporting;

PROCEDURE EnableMeteringGapDetection;

PROCEDURE EnableMeteringAutoPatching;

PROCEDURE EnableUrjanet (
	in_ftp_path						IN	VARCHAR2
);

PROCEDURE EnableManagementCompanyTree;

PROCEDURE EnableLikeforlike;

PROCEDURE EnableDegreeDays(
	in_account_name					degreeday_settings.account_name%TYPE DEFAULT 'default'
);

PROCEDURE EnableTraining;

PROCEDURE EnableSSO;

PROCEDURE EnableCapabilitiesUserListPage;

PROCEDURE EnableCompliance (
	in_enable_regulation_flow		IN	VARCHAR2,
	in_enable_requirement_flow		IN	VARCHAR2,
	in_enable_campaign				IN	VARCHAR2
);

PROCEDURE EnableEnhesa(
	in_client_id					IN	enhesa_options.client_id%TYPE,
	in_username						IN	enhesa_options.username%TYPE DEFAULT null,
	in_password						IN	enhesa_options.password%TYPE DEFAULT null
);

PROCEDURE EnableIncidents;

FUNCTION IsPropertyEnabled
RETURN NUMBER;

PROCEDURE EnableProperties(
	in_company_name		IN VARCHAR2,
	in_property_type	IN VARCHAR2
);

PROCEDURE EnableEmFactorsProfileTool(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
);
PROCEDURE EnableEmFactorsClassicTool(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
);

PROCEDURE EnableDocLibDocTypes;

PROCEDURE EnableForecasting;

PROCEDURE EnableAuditsApi;

PROCEDURE EnableCmsApi;

PROCEDURE EnableScheduledExportApi(
	in_enable			IN	NUMBER
);

PROCEDURE EnableForms;

PROCEDURE EnablePropertyDocLib;

PROCEDURE EnableTranslationsImport;

PROCEDURE EnableProductCompliance;

PROCEDURE EnableQuestionLibrary;
PROCEDURE EnableFileSharingApi(
	in_provider_hint			IN	VARCHAR2 DEFAULT NULL,
	in_switch_confirmation		IN	NUMBER DEFAULT 0
);

PROCEDURE EnablePermits;

FUNCTION IsApiIntegrationsEnabled RETURN BOOLEAN;
PROCEDURE EnableApiIntegrations;

PROCEDURE EnableHrIntegration(
	in_enable			IN	NUMBER
);

PROCEDURE EnableRegionEmFactorCascading(
	in_enable			IN	NUMBER
);

PROCEDURE EnableRegionFiltering;

PROCEDURE EnableValuesApi;

PROCEDURE EnableOSHAModule;

PROCEDURE EnableBranding;

PROCEDURE EnableDataBuckets;

PROCEDURE EnableManagedPackagedContent(
	in_package_name	IN VARCHAR2,
	in_package_ref	IN VARCHAR2
);

PROCEDURE EnableCredentialManagement(
	in_position			IN	NUMBER
);

PROCEDURE EnableManagedContentRegistryUI;

PROCEDURE EnableFrameworkDisclosures;

PROCEDURE EnableIntegrationQuestionAnswer;

PROCEDURE EnableIntegrationQuestionAnswerApi;

PROCEDURE EnableSustainEssentials(
	in_include_cat	IN VARCHAR2
);

PROCEDURE EnableDelegStatusOverview;

PROCEDURE EnableMeasureConversionsPage;

PROCEDURE EnableConsentSettings(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
);

PROCEDURE EnableAlert(
	in_alert_id 			IN NUMBER
);

PROCEDURE EnableSuperadminSsoSite;

PROCEDURE EnableMaxMind(
	in_enable			IN	NUMBER
);

PROCEDURE EnableTargetPlanning(
	in_enable			IN	NUMBER,
	in_position			IN	NUMBER
);



FUNCTION GetModuleId (
	in_module_name	IN	VARCHAR2
) RETURN NUMBER;

PROCEDURE LogEnable(
	in_module_name	IN	VARCHAR2
);
PROCEDURE LogDisable(
	in_module_name	IN	VARCHAR2
);
PROCEDURE LogDelete(
	in_module_name	IN	VARCHAR2
);

END enable_pkg;
/
