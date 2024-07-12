CREATE OR REPLACE PACKAGE CSRIMP.imp_pkg AS

-- Parent key not found exception
PARENT_KEY_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(PARENT_KEY_NOT_FOUND, -02291);

FUNCTION MapCustomerSchema(
	in_old_procedure_call			IN	VARCHAR2
)
RETURN VARCHAR2;

PROCEDURE BeginCsrImpSession(
	in_host							IN	csrimp.customer.host%TYPE,
	out_csrimp_session_id			OUT	csrimp.csrimp_session.csrimp_session_id%TYPE,
	out_step						OUT	csrimp.csrimp_session.step%TYPE,
	out_table_number				OUT	csrimp.csrimp_session.table_number%TYPE,
	out_table_row					OUT	csrimp.csrimp_session.table_row%TYPE
);

PROCEDURE CompleteImpSession;

PROCEDURE TableDataImported(
	in_obfuscate_email_addresses	IN	NUMBER,
	in_obfuscate_values				IN	NUMBER
);

PROCEDURE Step(
	in_step							IN	csrimp.csrimp_session.step%TYPE
);

PROCEDURE SetTableProgress(
	in_table_number					IN	csrimp.csrimp_session.table_number%TYPE,
	in_table_row					IN	csrimp.csrimp_session.table_row%TYPE
);

PROCEDURE AddKnownSOs;

PROCEDURE CreateSuperAdmins;

PROCEDURE AddRenameMappings;

PROCEDURE GatherStats;

PROCEDURE PopulateIDMappings;

PROCEDURE CreateSecurableObjects;

PROCEDURE SetAppSid;

PROCEDURE CreateDynamicTableObjects;

PROCEDURE CreateMail;

PROCEDURE CreateCustomerIndsRegions;

PROCEDURE CreateFactors;

PROCEDURE CreateIndSelectionGroups;

PROCEDURE CreateUsers;

PROCEDURE AddExistingSuperAdmins;

PROCEDURE CreateRoles;

PROCEDURE CreateFileUploads;

PROCEDURE CreatePending;

PROCEDURE CreateVarExpls;

PROCEDURE CreateDelegations;

PROCEDURE CreateSheets;

PROCEDURE CreateForms;

PROCEDURE CreateDataViews;

PROCEDURE CreateImgCharts;

PROCEDURE CreateImports;

PROCEDURE CreateVals;

PROCEDURE CreateSections;

PROCEDURE CreateFlow;

PROCEDURE CreateFlowItems;

PROCEDURE CreateCms;

PROCEDURE CreateFlowAlerts;

PROCEDURE CreateMeters;

PROCEDURE CreateIncidentTypes;

PROCEDURE CreateIssues;

PROCEDURE CreatePortlets;

PROCEDURE ImportCmsData;

PROCEDURE CreateDoclib;

PROCEDURE CreatePortalDashboards;

PROCEDURE CreateApprovalDashboards;

PROCEDURE CreateApprovalDashInstances;

PROCEDURE CreateTemplatedReports;

PROCEDURE CreateDashboards;

PROCEDURE CreateModels;

PROCEDURE CreatePostIts;

PROCEDURE CreateAudits;

PROCEDURE CreateQuestionLibrary;

PROCEDURE CreateQuickSurvey;

PROCEDURE CreateQuickSurveyFilters;

PROCEDURE CreateRegionSets;

PROCEDURE CreateIndSets;

PROCEDURE CreateScenarios;

PROCEDURE CreateTargetDashboards;

PROCEDURE CreateQuickSurveyExprActions;

PROCEDURE CreateAuditLog;

PROCEDURE CreateTrash;

PROCEDURE CreateTemplates;

PROCEDURE CreateExportFeeds;

PROCEDURE CreateAlertBounceTrack;

PROCEDURE CreateRegionMetrics;

PROCEDURE CreatePropertyOptions;

PROCEDURE CreateProperties;

PROCEDURE CreatePropertiesDashboards;

PROCEDURE CreateCurrencies;

PROCEDURE CreatePlugins;

PROCEDURE CreateSuppliers;

PROCEDURE CreateBasicChain;

PROCEDURE CreateChainActivities;

PROCEDURE CreateChainCards;

PROCEDURE CreateChainProductTypes;

PROCEDURE SetDedupeData;

PROCEDURE GetMapInd(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMapRegion(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMapUser(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMapPendingInd(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMapPendingRegion(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMapPendingPeriod(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMapApprovalStep(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CreateChainMiscellaneous;

PROCEDURE CreateChainAudits;

PROCEDURE CreateChainBusinessUnits;

PROCEDURE CreateChainCompanies;

PROCEDURE CreateChainFilesAndFilters;

PROCEDURE CreateChainCompanyTabs;

PROCEDURE CreateChainProductTabs;

PROCEDURE CreateChainComponents;

PROCEDURE CreateChainInvitations;

PROCEDURE CreateChainAlerts;

PROCEDURE CreateChainMessages;

PROCEDURE CreateChainProducts;

PROCEDURE CreateChainQuestionnaires;

PROCEDURE CreateChainTasks;

PROCEDURE CreateChainUserMessageLog;

PROCEDURE CreateChainBusinessRelnships;

PROCEDURE CreateHigg;

--PROCEDURE CreateBsci;

PROCEDURE CreateWorksheets;

PROCEDURE CreateChem;

PROCEDURE CreateRReports;

PROCEDURE CreateScheduledStoredProcs;

PROCEDURE CreateLikeForLike;

PROCEDURE CreateDegreeDays;

PROCEDURE CreateInitiatives;

PROCEDURE CreateCustomFactors;

PROCEDURE CreateEmissionFactorProfiles;

PROCEDURE CreateCompliance;

PROCEDURE CreateCalendar;

PROCEDURE CreateClientUtilScripts;

PROCEDURE CreateIntegrationApiTables;

PROCEDURE CreateOshaMappings;

PROCEDURE CreateSysTranslationsAuditLogs;

PROCEDURE CreateDataBuckets;

PROCEDURE CreateIntegrationQuestionAnswer;

PROCEDURE CreateRegionCertificates;

PROCEDURE CreateRegionEnergyRatings;

PROCEDURE CreateModuleHistory;

PROCEDURE CreateBaselineConfigs;

END imp_pkg;
/
