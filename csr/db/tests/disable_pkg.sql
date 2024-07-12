CREATE OR REPLACE PACKAGE CSR.disable_pkg IS

PROCEDURE DisableActions;

PROCEDURE DisableAlert(
	in_std_alert_type_id			IN NUMBER
);

PROCEDURE DisableAudit;

PROCEDURE DisableAuditMaps;

PROCEDURE DisableAuditFiltering;

PROCEDURE DisableAuditsOnUsers;

PROCEDURE DisableMultipleAuditSurveys;

PROCEDURE DisableBounceTracking;

PROCEDURE DisableCompanyDedupePreProc;

PROCEDURE DisableBsciIntegration;

PROCEDURE DisableCalendar;

PROCEDURE DisableCampaigns;

PROCEDURE DisableCarbonEmissions;

-- TODO : Remove this as it creates a broken site
PROCEDURE DisableChain(
	siteName IN VARCHAR2
);

PROCEDURE DisableChainActivities;

PROCEDURE DisableChainOneTier(
	in_site_name			IN VARCHAR2,
	in_top_company_name		IN VARCHAR2
);

PROCEDURE DisableChainTwoTier(
	in_top_company_name		IN VARCHAR2
);

PROCEDURE DisableCorpReporter;

PROCEDURE DisableCustomIssues;

PROCEDURE DisableDelegPlan;

PROCEDURE DisableDivisions;

PROCEDURE DisableDocLib;

PROCEDURE DisableDonations;

PROCEDURE DisableExcelModels;

PROCEDURE DisableFeeds(
	in_user IN CSR_USER.user_NAME%TYPE,
	in_password IN VARCHAR2
);

PROCEDURE DisableFilterAlerts;

PROCEDURE DisableFogbugz(
	in_customer_fogbugz_project_id IN NUMBER,
	in_customer_fogbugz_area IN VARCHAR2
);

PROCEDURE DisableGRESB(
	in_use_sandbox			IN VARCHAR2
);

PROCEDURE DisableHigg (
	in_ftp_profile					VARCHAR2,
	in_ftp_folder					VARCHAR2
);

PROCEDURE DisableImageChart;

PROCEDURE DisableInitiatives(
	in_setup_base_data	IN VARCHAR2
);

PROCEDURE DisableInitiativesAuditTab;

PROCEDURE DisableIssues2;

PROCEDURE DisableMap;

PROCEDURE DisableMeasureConversions;

PROCEDURE DisableCompanySelfReg;

PROCEDURE DisablePropertyMeterListTab;

PROCEDURE DisablePortal;

PROCEDURE DisablePortalPLSQL;

PROCEDURE DisableRestAPI (
	in_disable_guest_access IN VARCHAR2 DEFAULT NULL
);

PROCEDURE DisableRReports;

PROCEDURE DisableScenarios;

PROCEDURE DisableScheduledTasks;

PROCEDURE DisableSheets2;

PROCEDURE DisableSupplierMaps;

PROCEDURE DisableSurveys;

PROCEDURE DisableTemplatedReports;

PROCEDURE DisableWorkflow;

PROCEDURE DisableChangeBranding;

PROCEDURE DisableFrameworks;

PROCEDURE DisableReportingIndicators;

PROCEDURE DisableAutomatedExportImport;

PROCEDURE DisableApprovalDashboards;

PROCEDURE DisableDelegationSummary;

PROCEDURE DisableMultipleDashboards;

PROCEDURE DisableDelegationReports;

PROCEDURE DisableDelegationStatusReports;

PROCEDURE DisableAuditLogReports;

PROCEDURE DsableDashboardAuditLogReports;

PROCEDURE DisableDataChangeRequests;

PROCEDURE DisablePropertyDashboards;

PROCEDURE DisableChainCountryRisk;

PROCEDURE DisableEnergyStar;

/**
 * Creates the support menu items and OwlSupport user group
 */
PROCEDURE DisableOwlSupport;


/**
 * METERING
 */

PROCEDURE DisableMeteringBase;

PROCEDURE DisableMeterUtilities;

PROCEDURE DisableRealtimeMetering;

PROCEDURE DisableMeteringFeeds;

PROCEDURE DisableMeterMonitoring;

PROCEDURE DisableMeterReporting;

PROCEDURE DisableMeteringGapDetection;

PROCEDURE DisableMeteringAutoPatching;

PROCEDURE DisableUrjanet (
	in_ftp_path						IN	VARCHAR2
);

PROCEDURE DisableManagementCompanyTree;

PROCEDURE DisableLikeforlike;

PROCEDURE DisableDegreeDays(
	in_account_name					degreeday_settings.account_name%TYPE DEFAULT 'default'
);

PROCEDURE DisableTraining;

PROCEDURE DisableSSO;

PROCEDURE DsableCapabilitiesUserListPage;

PROCEDURE DisableCompliance (
	in_disable_regulation_flow		IN	VARCHAR2,
	in_disable_requirement_flow		IN	VARCHAR2,
	in_disable_campaign				IN	VARCHAR2
);

PROCEDURE DisableEnhesa(
	in_client_id					IN	enhesa_options.client_id%TYPE
);

PROCEDURE DisableIncidents;

PROCEDURE DisableProperties(
	in_company_name		IN VARCHAR2,
	in_property_type	IN VARCHAR2
);

PROCEDURE DisableEmFactorsProfileTool(
	in_disable			IN	NUMBER,
	in_position			IN	NUMBER
);

PROCEDURE DisableEmFactorsClassicTool(
	in_disable			IN	NUMBER,
	in_position			IN	NUMBER
);

PROCEDURE DisableDocLibDocTypes;

PROCEDURE DisableForecasting;

PROCEDURE DisablePropertyDocLib;

PROCEDURE DisableTranslationsImport;

PROCEDURE DisableProductCompliance;

PROCEDURE DisableQuestionLibrary;
PROCEDURE DisableFileSharingApi(
	in_provider_hint			IN	VARCHAR2 DEFAULT NULL,
	in_switch_confirmation		IN	NUMBER DEFAULT 0
);

PROCEDURE DisablePermits;

PROCEDURE DisableApiIntegrations;

PROCEDURE DisableHrIntegration(
	in_disable			IN	NUMBER
);

PROCEDURE DisableRegionEmFactorCascading(
	in_disable			IN	NUMBER
);

PROCEDURE DisableRegionFiltering;

PROCEDURE DisableValuesApi;

PROCEDURE DisableAmforiIntegration;

END disable_pkg;
/
