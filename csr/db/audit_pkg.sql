create or replace PACKAGE csr.audit_pkg AS

-- PL/SQL table of file upload cache keys
TYPE T_CACHE_KEYS IS TABLE OF aspen2.filecache.cache_key%TYPE INDEX BY PLS_INTEGER;

AUDIT_AGG_IND_GROUP			CONSTANT VARCHAR2(100) := 'InternalAudit';

IND_TYPE_FLOW_STATE_COUNT	CONSTANT NUMBER(10) := 1;
IND_TYPE_FLOW_STATE_TIME	CONSTANT NUMBER(10) := 2;

PRIMARY_AUDIT_TYPE_SURVEY_ID	CONSTANT NUMBER(10) := 0;

NCT_RPT_MATCH_UNIT_NONE			CONSTANT VARCHAR2(10) := 'none';
NCT_RPT_MATCH_UNIT_ALL			CONSTANT VARCHAR2(10) := 'all';
NCT_RPT_MATCH_UNIT_AUDITS		CONSTANT VARCHAR2(10) := 'audits';
NCT_RPT_MATCH_UNIT_MONTHS		CONSTANT VARCHAR2(10) := 'months';
NCT_RPT_MATCH_UNIT_YEARS		CONSTANT VARCHAR2(10) := 'years';

NCT_CARRY_FWD_RPT_TYPE_NORMAL	CONSTANT VARCHAR2(10) := 'normal';
NCT_CARRY_FWD_RPT_TYPE_AS_CRTD	CONSTANT VARCHAR2(10) := 'as_created';
NCT_CARRY_FWD_RPT_TYPE_NEVER	CONSTANT VARCHAR2(10) := 'never';

UNDEFINED_AUDIT_SOURCE_ID 		CONSTANT NUMBER(10) := 0;
INTERNAL_AUDIT_SOURCE_ID		CONSTANT NUMBER(10) := 1;
EXTERNAL_AUDIT_SOURCE_ID		CONSTANT NUMBER(10) := 2;
INTEGRATION_AUDIT_SOURCE_ID		CONSTANT NUMBER(10) := 3;

ERR_REGION_AUDIT			CONSTANT NUMBER := -20008;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashAudit (
	in_internal_audit_sid	IN	internal_audit.internal_audit_sid%TYPE
);

PROCEDURE DeleteAudit (
	in_internal_audit_sid	IN	internal_audit.internal_audit_sid%TYPE
);

PROCEDURE INTERNAL_CreateRefID_Non_Comp(
	in_non_compliance_id		IN	csr.non_compliance.non_compliance_id%TYPE
);

FUNCTION GetAuditsForUserAsTable
RETURN security.T_SID_TABLE;

FUNCTION GetAuditsWithCapabilityAsTable (
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_permission				IN	NUMBER,
	in_page						IN	security.T_ORDERED_SID_TABLE
) RETURN security.T_SID_TABLE;

FUNCTION SupportsDueAudits
RETURN NUMBER;

FUNCTION HasReadAccess (
	in_audit_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

/* Compatible with C# */
FUNCTION SQL_HasReadAccess (
	in_audit_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION HasWriteAccess (
	in_audit_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION HasDeleteAccess (
	in_audit_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION GetPermissionOnAudit(
in_sid_id				IN	internal_audit.internal_audit_sid%TYPE
)RETURN NUMBER;

FUNCTION SQL_IsAuditAdministrator
RETURN BINARY_INTEGER;

FUNCTION IsFlowAudit(
	in_internal_audit_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION SQL_HasCapabilityAccess(
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_permission				IN	NUMBER
) RETURN BINARY_INTEGER;

FUNCTION HasCapabilityAccess(
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_permission				IN	NUMBER
) RETURN BOOLEAN;

PROCEDURE GetAbilities (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_include_all				IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR,
	out_surveys_cur				OUT	SYS_REFCURSOR,
	out_non_compliance_types	OUT	SYS_REFCURSOR
);

PROCEDURE GetAbilities (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR,
	out_surveys_cur				OUT	SYS_REFCURSOR,
	out_non_compliance_types	OUT SYS_REFCURSOR
);

FUNCTION GetAbilities (
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_include_all				IN	NUMBER
) RETURN T_AUDIT_ABILITY_TABLE;

PROCEDURE GetDetails(
	in_sid_id				IN	internal_audit.internal_audit_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditTypeCarryForwards (
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SetAuditTypeCarryForwards (
	in_to_ia_type_id			IN	internal_audit.internal_audit_type_id%TYPE,
	in_from_ia_type_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetSidOfAuditToCarryForward (
	in_region_sid				IN	internal_audit.region_sid%TYPE,
	in_internal_audit_type		IN	internal_audit.internal_audit_type_id%TYPE,
	in_audit_dtm				IN	internal_audit.audit_dtm%TYPE,
	out_carry_from_audit_sid	OUT	security_pkg.T_SID_ID,
	out_label					OUT	internal_audit.label%TYPE
);

PROCEDURE GetAuditsToCarryForward (
	in_carry_to_audit_type_id	IN	internal_audit.internal_audit_type_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetResponsesToCarryForward (
	in_carry_from_audit_sid		IN	security_pkg.T_SID_ID,
	in_survey_sids				IN	security_pkg.T_SID_IDS,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_audit_dtm				IN	DATE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE CheckForCarryForward (
	in_carry_from_audit_sid		IN	security_pkg.T_SID_ID,
	in_carry_to_audit_type_id	IN	internal_audit.internal_audit_type_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR,
	out_cur_documents			OUT	SYS_REFCURSOR,
	out_cur_postits				OUT	SYS_REFCURSOR
);

PROCEDURE Save(
	in_sid_id					IN	internal_audit.internal_audit_sid%TYPE,
	in_audit_ref				IN	internal_audit.internal_audit_ref%TYPE,
	in_survey_sid				IN	internal_audit.survey_sid%TYPE,
	in_region_sid				IN	internal_audit.region_sid%TYPE,
	in_label					IN	internal_audit.label%TYPE,
	in_audit_dtm				IN	internal_audit.audit_dtm%TYPE,
	in_auditor_user_sid			IN	internal_audit.auditor_user_sid%TYPE,
	in_notes					IN	internal_audit.notes%TYPE,
	in_internal_audit_type		IN	internal_audit.internal_audit_type_id%TYPE,
	in_auditor_name				IN	internal_audit.auditor_name%TYPE,
	in_auditor_org				IN	internal_audit.auditor_organisation%TYPE,
	in_response_to_audit		IN	internal_audit.comparison_response_id%TYPE DEFAULT NULL,
	in_created_by_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_auditee_user_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_auditee_company_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_auditor_company_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_created_by_company_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_permit_id				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_external_audit_ref		IN	internal_audit.external_audit_ref%TYPE DEFAULT NULL,
	in_external_parent_ref		IN	internal_audit.external_parent_ref%TYPE DEFAULT NULL,
	in_external_url				IN	internal_audit.external_url%TYPE DEFAULT NULL,
	out_sid_id					OUT	internal_audit.internal_audit_sid%TYPE
);

PROCEDURE SaveSupplierAudit (
	in_internal_audit_sid		IN	security_pkg.T_SID_ID,
	in_auditee_company_sid		IN	security_pkg.T_SID_ID,
	in_auditor_company_sid		IN	security_pkg.T_SID_ID,
	in_created_by_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE SetAuditorCompanySid (
	in_audit_sid			IN	internal_audit.internal_audit_sid%TYPE,
	in_auditor_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE DeleteAFileFromAnAudit(
	in_internal_audit_sid				IN	security_pkg.T_SID_ID,
	in_internal_audit_file_data_id		IN	security_pkg.T_SID_ID
);

PROCEDURE DeleteInternalAuditFiles(
	in_internal_audit_sid		IN	internal_audit.internal_audit_sid%TYPE,
	in_current_file_uploads		IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE InsertInternalAuditFiles(
	in_internal_audit_sid		IN	internal_audit.internal_audit_sid%TYPE,
	in_new_file_uploads			IN	T_CACHE_KEYS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInternalAuditFile(
	in_int_audit_file_data_id	IN	internal_audit_file_data.internal_audit_file_data_id%TYPE,
	in_sha1						IN  internal_audit_file_data.sha1%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveNonInteractiveAudit(
	in_sid_id					IN	internal_audit.internal_audit_sid%TYPE,
	in_region_sid				IN	internal_audit.region_sid%TYPE,
	in_internal_audit_type		IN	internal_audit.internal_audit_type_id%TYPE,
	in_label					IN	internal_audit.label%TYPE,
	in_audit_dtm				IN	internal_audit.audit_dtm%TYPE,
	in_audit_closure_type_id	IN	internal_audit.audit_closure_type_id%TYPE,
	in_current_file_uploads		IN	security_pkg.T_SID_IDS,
	in_new_file_uploads			IN	T_CACHE_KEYS,
	in_audit_ref				IN	internal_audit.internal_audit_ref%TYPE DEFAULT csr_data_pkg.PRESERVE_NUMBER,
	out_sid_id					OUT	internal_audit.internal_audit_sid%TYPE
);

PROCEDURE GetAuditSummary(
	in_internal_audit_sid		IN  internal_audit.internal_audit_sid%TYPE,
	out_audit_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_documents_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditSummaries(
	in_parent_region_sid		IN  internal_audit.internal_audit_sid%TYPE,
	in_internal_audit_source_id	IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT EXTERNAL_AUDIT_SOURCE_ID,
	in_skip_count				IN	NUMBER DEFAULT 0,
	in_take_count				IN	NUMBER DEFAULT 99999999999999999999999999999999999999, /* Max int a NUMBER can hold, 38 digits */
	out_audit_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_documents_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInternalAudits(
	in_internal_audit_source_id	IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
	in_region_sid				IN  NUMBER,
	in_internal_audit_type		IN	internal_audit.internal_audit_type_id%TYPE,
	in_ia_type_group_id			IN	internal_audit_type.internal_audit_type_group_id%TYPE,
	in_my_audits_only			IN	NUMBER,
	in_skip_count				IN	NUMBER DEFAULT 0,
	in_take_count				IN	NUMBER DEFAULT 99999999999999999999999999999999999999, /* Max int a NUMBER can hold, 38 digits */
	out_audits_cur				OUT	SYS_REFCURSOR,
	out_documents_cur			OUT	SYS_REFCURSOR
);

PROCEDURE CarryForwardPostits (
	in_from_audit_sid		IN	security_pkg.T_SID_ID,
	in_to_audit_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CarryForwardDocuments (
	in_from_audit_sid		IN	security_pkg.T_SID_ID,
	in_to_audit_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CarryForwardOpenNCs (
	in_from_audit_sid		IN	security_pkg.T_SID_ID,
	in_to_audit_sid			IN	security_pkg.T_SID_ID,
	in_take_ownership_of_issues	IN  NUMBER DEFAULT 0
);

PROCEDURE CarryForwardSurveyResponse (
	in_from_response_id				IN	internal_audit.survey_response_id%TYPE,
	in_to_audit_sid					IN	security.security_pkg.T_SID_ID,
	in_to_audit_type_survey_id		IN	internal_audit_survey.internal_audit_type_survey_id%TYPE,
	out_response_id					OUT	quick_survey_response.survey_response_id%TYPE
);

-- Deprecated. Still used by portlets, calendar and RestAPI - but new things should use audit_report_pkg.GetAuditList
PROCEDURE Browse(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_parent_region_sids	IN	security_pkg.T_SID_IDS,
	in_open_non_compliance	IN	NUMBER,
	in_overdue				IN	NUMBER,
	in_internal_audit_type	IN	internal_audit.internal_audit_type_id%TYPE,
	in_ia_type_group_id		IN	internal_audit_type.internal_audit_type_group_id%TYPE,
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_my_audits_only		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

/*A lightweight version for plugins that returns only the data needed
eventually we will retire all browse SP versions*/
PROCEDURE BrowseForPlugin(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_parent_region_sids	IN	security_pkg.T_SID_IDS,
	in_open_non_compliance	IN	NUMBER,
	in_overdue				IN	NUMBER,
	in_internal_audit_type	IN	internal_audit.internal_audit_type_id%TYPE,
	in_ia_type_group_id		IN	internal_audit_type.internal_audit_type_group_id%TYPE,
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_my_audits_only		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SearchAudits (
	in_search_term			VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SearchAuditsMore (
	in_search_term					VARCHAR2,
	in_internal_audit_source_id		IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
	in_audit_type_group_id 			IN  internal_audit_type.internal_audit_type_group_id%TYPE DEFAULT NULL,
	in_my_audits_only 				IN  NUMBER DEFAULT 0,
	in_skip_count					IN	NUMBER DEFAULT 0,
	in_take_count					IN	NUMBER DEFAULT 99999999999999999999999999999999999999, /* Max int a NUMBER can hold, 38 digits */
	out_cur							OUT	SYS_REFCURSOR
);

-- Deprecated. Still used by RestAPI - but new things should use non_compliance_report_pkg.GetNonComplianceList
PROCEDURE BrowseNonCompliances(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_parent_region_sids	IN	security_pkg.T_SID_IDS,
	in_open_actions			IN	NUMBER,
	in_internal_audit_type	IN	internal_audit.internal_audit_type_id%TYPE,
	in_ia_type_group_id		IN	internal_audit_type.internal_audit_type_group_id%TYPE,
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_my_audits_only		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR,
	out_tags				OUT	SYS_REFCURSOR
);

PROCEDURE BrowseDueAudits(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_parent_region_sids	IN	security_pkg.T_SID_IDS,
	in_internal_audit_type	IN	internal_audit.internal_audit_type_id%TYPE,
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_my_audits_only		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetNonComplianceAudits(
	in_non_compliance_ids	IN security_pkg.T_SID_IDS, -- not sids, but this the closest type
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueTypeFromAudit (
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_issue_type_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetDetails(
	in_sid_id					IN	security_pkg.T_SID_ID,
	out_details_cur				OUT	SYS_REFCURSOR,
	out_nc_cur					OUT	SYS_REFCURSOR,
	out_nc_upload_cur			OUT	SYS_REFCURSOR,
	out_nc_tag_cur				OUT	SYS_REFCURSOR,
	out_documents_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetExtraDetails(
	in_sid_id					IN	security_pkg.T_SID_ID,
	out_nc_cur					OUT	SYS_REFCURSOR,
	out_nc_upload_cur			OUT	SYS_REFCURSOR,
	out_nc_tag_cur				OUT	SYS_REFCURSOR,
	out_documents_cur			OUT SYS_REFCURSOR,
	out_action_documents_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetDetailsForMailMerge(
	in_sid_id					IN	security_pkg.T_SID_ID,
	in_report_id 				IN  security_pkg.T_SID_ID,
	out_details_cur				OUT	SYS_REFCURSOR,
	out_nc_cur					OUT	SYS_REFCURSOR,
	out_nc_upload_cur			OUT	SYS_REFCURSOR,
	out_nc_tag_cur				OUT	SYS_REFCURSOR,
	out_issues_cur				OUT	SYS_REFCURSOR,
	out_template_cur			OUT	SYS_REFCURSOR,
	out_issues_fields_cur		OUT	SYS_REFCURSOR,
	out_issue_logs_cur			OUT SYS_REFCURSOR,
	out_issue_log_files_cur		OUT	SYS_REFCURSOR,
	out_issue_action_log_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetDetailsForMailMergeAllFiles(
	in_sid_id					IN	security_pkg.T_SID_ID,
	in_report_id 				IN  security_pkg.T_SID_ID,
	out_details_cur				OUT	SYS_REFCURSOR,
	out_nc_cur					OUT	SYS_REFCURSOR,
	out_nc_upload_cur			OUT	SYS_REFCURSOR,
	out_nc_tag_cur				OUT	SYS_REFCURSOR,
	out_issues_cur				OUT	SYS_REFCURSOR,
	out_template_cur			OUT	SYS_REFCURSOR,
	out_issues_fields_cur		OUT	SYS_REFCURSOR,
	out_postit_files_cur		OUT SYS_REFCURSOR,
	out_audit_files_cur			OUT SYS_REFCURSOR,
	out_issue_logs_cur			OUT SYS_REFCURSOR,
	out_issue_log_files_cur		OUT	SYS_REFCURSOR,
	out_issue_action_log_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetNonCompliancesForAudit(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_nc_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetNonCompliancesForAudit(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_nc_cur				OUT	SYS_REFCURSOR,
	out_nc_tags_cur			OUT	SYS_REFCURSOR
);

Function PopulatePermissibleNCs
RETURN security.T_SID_TABLE;

PROCEDURE ExportAuditsFindingsAndActions(
	in_internal_audit_type	IN	internal_audit.internal_audit_type_id%TYPE,
	out_nc_cur				OUT	SYS_REFCURSOR,
	out_nc_tags_cur			OUT	SYS_REFCURSOR,
	out_issue_fields_cur	OUT	SYS_REFCURSOR,
	out_audit_tags_cur		OUT	SYS_REFCURSOR,
	out_scores_cur			OUT	SYS_REFCURSOR
);

-- Export NCs and their actions in a format for round-tripping
-- i.e. one line per action with NC details duplicated
PROCEDURE ExportFindingsAndActions(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_nc_cur				OUT	SYS_REFCURSOR,
	out_nc_tags_cur			OUT	SYS_REFCURSOR,
	out_issue_fields_cur	OUT	SYS_REFCURSOR
);

-- Folder handler sprocs
PROCEDURE GetDefaultNCFoldersWithDepth(
	in_parent_id				IN	non_comp_default_folder.parent_folder_id%TYPE,
	in_fetch_depth				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateDefaultNonCompFolder (
	in_parent_id				IN	non_comp_default_folder.parent_folder_id%TYPE,
	in_label					IN	non_comp_default_folder.label%TYPE,
	out_folder_id				OUT non_comp_default_folder.non_comp_default_folder_id%TYPE
);

PROCEDURE GetOrCreateDNCFolderFromPath (
	in_path						IN	VARCHAR2,
	out_folder_id				OUT non_comp_default_folder.non_comp_default_folder_id%TYPE
);

PROCEDURE DeleteDefaultNonCompFolder (
	in_folder_id				IN	non_comp_default_folder.non_comp_default_folder_id%TYPE
);

PROCEDURE RenameDefaultNonCompFolder (
	in_folder_id				IN	non_comp_default_folder.non_comp_default_folder_id%TYPE,
	in_label					IN	non_comp_default_folder.label%TYPE
);

PROCEDURE MoveDefaultNonCompFolder (
	in_folder_id				IN	non_comp_default_folder.non_comp_default_folder_id%TYPE,
	in_parent_id				IN	non_comp_default_folder.parent_folder_id%TYPE
);

PROCEDURE MoveDefaultNonCompliance (
	in_default_non_comp_id		IN	non_comp_default.non_comp_default_id%TYPE,
	in_parent_id				IN	non_comp_default.non_comp_default_folder_id%TYPE
);

PROCEDURE GetAllDNCFolders (
	in_internal_audit_type_id	IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

-- Default Non-Compliance management sprocs
FUNCTION GetCustomPermissibleAuditNCTs(
	in_access				IN	security_pkg.T_PERMISSION
) RETURN csr.T_AUDIT_PERMISSIBLE_NCT_TABLE;

FUNCTION GetPermissibleNCTypeIds(
	in_audit_sid			IN	internal_audit.internal_audit_sid%TYPE,
	in_access				IN	security_pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

FUNCTION HasFlowAuditNonComplAccess(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_audit_sid			IN	internal_audit.internal_audit_sid%TYPE,
	in_access				IN	security_pkg.T_PERMISSION
) RETURN BOOLEAN;

FUNCTION HasFlowAuditNonComplTagAccess(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_audit_sid			IN	internal_audit.internal_audit_sid%TYPE,
	in_access				IN	security_pkg.T_PERMISSION
) RETURN BOOLEAN;

PROCEDURE GetNonComplianceDetails(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	out_nc_cur				OUT	SYS_REFCURSOR,
	out_nc_upload_cur		OUT	SYS_REFCURSOR,
	out_nc_tag_cur			OUT	SYS_REFCURSOR,
	out_nc_audits_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetNonComplianceDefaults (
	in_internal_audit_type_id		IN	audit_type_non_comp_default.internal_audit_type_id%TYPE,
	in_folder_id					IN	non_comp_default.non_comp_default_folder_id%TYPE,
	out_nc_defaults_cur				OUT SYS_REFCURSOR,
	out_nc_audit_types_cur			OUT SYS_REFCURSOR,
	out_nc_issues_cur				OUT SYS_REFCURSOR,
	out_nc_tags_cur					OUT SYS_REFCURSOR
);

PROCEDURE SetNonComplianceDefault (
	in_non_comp_default_id			IN  non_comp_default.non_comp_default_id%TYPE,
	in_folder_id					IN	non_comp_default.non_comp_default_folder_id%TYPE,
	in_label						IN  non_comp_default.label%TYPE,
	in_detail						IN  non_comp_default.detail%TYPE,
	in_non_compliance_type_id		IN  non_comp_default.non_compliance_type_id%TYPE,
	in_root_cause					IN  non_comp_default.root_cause%TYPE,
	in_suggested_action				IN  non_comp_default.suggested_action%TYPE,
	in_unique_reference				IN  non_comp_default.unique_reference%TYPE,
	out_non_comp_default_id			OUT non_comp_default.non_comp_default_id%TYPE
);

PROCEDURE DeleteNonComplianceDefault (
	in_non_comp_default_id			IN  non_comp_default.non_comp_default_id%TYPE
);

PROCEDURE SetAuditTypeNonCompDefaults (
	in_non_comp_default_id			IN  audit_type_non_comp_default.non_comp_default_id%TYPE,
	in_internal_audit_type_ids		IN  security_pkg.T_SID_IDS
);

PROCEDURE SetNonCompDefaultTags (
	in_non_comp_default_id			IN  audit_type_non_comp_default.non_comp_default_id%TYPE,
	in_tag_ids						IN  security_pkg.T_SID_IDS
);

PROCEDURE SetNonCompDefaultIssue (
	in_non_comp_default_issue_id	IN  non_comp_default_issue.non_comp_default_issue_id%TYPE,
	in_non_comp_default_id			IN  non_comp_default_issue.non_comp_default_id%TYPE,
	in_label						IN  non_comp_default_issue.label%TYPE,
	in_description					IN  non_comp_default_issue.description%TYPE,
	in_due_dtm_relative				IN  non_comp_default_issue.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN  non_comp_default_issue.due_dtm_relative_unit%TYPE,
	out_non_comp_default_issue_id	OUT non_comp_default_issue.non_comp_default_issue_id%TYPE
);

PROCEDURE DeleteRemainingNCDIssues (
	in_non_comp_default_id			IN  non_comp_default_issue.non_comp_default_id%TYPE,
	in_issue_ids_to_keep			IN  security_pkg.T_SID_IDS
);

PROCEDURE CheckNonComplianceAccess (
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_access				IN	security_pkg.T_PERMISSION,
	in_access_denied_msg	IN	VARCHAR2 DEFAULT NULL
);

PROCEDURE CheckNonComplianceTagAccess (
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_access				IN	security_pkg.T_PERMISSION,
	in_access_denied_msg	IN	VARCHAR2 DEFAULT NULL
);

PROCEDURE UpdateNonCompClosureStatus (
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE
);

PROCEDURE SaveNonCompliance_UNSEC(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_internal_audit_sid		IN	security_pkg.T_SID_ID,
	in_from_non_comp_default_id	IN  non_compliance.from_non_comp_default_id%TYPE,
	in_label					IN	non_compliance.label%TYPE,
	in_detail					IN	non_compliance.detail%TYPE,
	in_non_compliance_type_id	IN  non_compliance.non_compliance_type_id%TYPE,
	in_is_closed				IN  non_compliance.is_closed%TYPE,
	in_question_id				IN	non_compliance.question_id%TYPE DEFAULT NULL,
	in_question_option_id		IN	non_compliance.question_option_id%TYPE DEFAULT NULL,
	in_root_cause				IN  non_compliance.root_cause%TYPE DEFAULT NULL,
	in_suggested_action			IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
	in_ia_type_survey_id 		IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
	in_non_compliance_ref		IN	non_compliance.non_compliance_ref%TYPE DEFAULT NULL,
	out_non_compliance_id		OUT	non_compliance.non_compliance_id%TYPE
);

PROCEDURE SaveNonCompliance(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_internal_audit_sid		IN	security_pkg.T_SID_ID,
	in_from_non_comp_default_id	IN  non_compliance.from_non_comp_default_id%TYPE,
	in_label					IN	non_compliance.label%TYPE,
	in_detail					IN	non_compliance.detail%TYPE,
	in_non_compliance_type_id	IN  non_compliance.non_compliance_type_id%TYPE,
	in_is_closed				IN  non_compliance.is_closed%TYPE,
	in_current_file_uploads		IN	security_pkg.T_SID_IDS,
	in_new_file_uploads			IN	T_CACHE_KEYS,
	in_tag_ids					IN	security_pkg.T_SID_IDS, --not sids but will do
	in_question_id				IN	non_compliance.question_id%TYPE,
	in_question_option_id		IN	non_compliance.question_option_id%TYPE,
	in_root_cause				IN  non_compliance.root_cause%TYPE DEFAULT NULL,
	in_suggested_action			IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
	in_ia_type_survey_id 		IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
	in_non_compliance_ref		IN	non_compliance.non_compliance_ref%TYPE DEFAULT NULL,
	out_nc_cur					OUT	SYS_REFCURSOR,
	out_nc_upload_cur			OUT	SYS_REFCURSOR,
	out_nc_tag_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CloseNonCompliance(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE
);

PROCEDURE ReopenNonCompliance(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE
);

PROCEDURE DeleteNonCompliance(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_delete_issues		IN	NUMBER
);

PROCEDURE AddNCIssueForDefFlgFindingType(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_issue_type_id			IN	issue_type.issue_type_id%TYPE,
	in_label					IN  issue.label%TYPE,
	in_description				IN  issue.description%TYPE,
	in_assign_to_role_sid		IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_assign_to_user_sid		IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_due_dtm					IN	issue.due_dtm%TYPE						DEFAULT NULL,
	in_is_urgent				IN	NUMBER									DEFAULT NULL,
	in_is_critical				IN	NUMBER									DEFAULT 0,
	out_issue_id				OUT issue.issue_id%TYPE
);

PROCEDURE AddNonComplianceIssue(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE,
	in_label					IN  issue.label%TYPE,
	in_description				IN  issue.description%TYPE,
	in_assign_to_role_sid		IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_assign_to_user_sid		IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_due_dtm					IN	issue.due_dtm%TYPE						DEFAULT NULL,
	in_is_urgent				IN	NUMBER									DEFAULT NULL,
	in_is_critical				IN	NUMBER									DEFAULT 0,
	out_issue_id				OUT issue.issue_id%TYPE
);

-- Checks that an issue belongs to the non-compliance
FUNCTION CheckNonComplianceIssue(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE,
	in_issue_id					IN	issue.issue_id%TYPE
) RETURN NUMBER;

PROCEDURE SetPostIt(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	in_postit_id			IN	postit.postit_id%TYPE,
	out_postit_id			OUT postit.postit_id%TYPE
);

PROCEDURE GetPostIts(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetAuditWithComparisonFromSurv(
	in_survey_sid			IN	quick_survey.survey_sid%TYPE,
	in_survey_response_id	IN	quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER;

FUNCTION GetAuditFromResponseId(
	in_survey_response_id	IN	quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER;

PROCEDURE GetComparisonSubmission(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLatestCampaignSubmission(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOrCreateSurveyResponse(
	in_internal_audit_sid			IN	security_pkg.T_SID_ID,
	in_ia_type_survey_id			IN	internal_audit_survey.internal_audit_type_survey_id%TYPE,
	in_survey_version				IN	quick_survey_response.survey_version%TYPE DEFAULT NULL,
	out_is_new_response				OUT NUMBER,
	out_survey_sid					OUT security_pkg.T_SID_ID,
	out_response_id					OUT	quick_survey_response.survey_response_id%TYPE
);

PROCEDURE CopyPreviousSubmission(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	in_survey_response_id	IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_response.survey_response_id%TYPE,
	in_audit_type_survey_id	IN	internal_audit_survey.internal_audit_type_survey_id%TYPE,
	out_response_id					OUT	quick_survey_response.survey_response_id%TYPE
);

PROCEDURE GetOrCreateSummaryResponse(
	in_internal_audit_sid			IN	security_pkg.T_SID_ID,
	in_survey_version				IN	quick_survey_response.survey_version%TYPE DEFAULT NULL,
	out_is_new_response				OUT NUMBER,
	out_survey_sid					OUT security_pkg.T_SID_ID,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	quick_survey_response.survey_response_id%TYPE
);

PROCEDURE GetAuditTypeFlowStates(
	in_internal_audit_type_id	IN internal_audit_type.internal_audit_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInternalAuditTypeGroupsFast(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetInternalAuditTypeGroups(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetInternalAuditTypes(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetInternalAuditTypes(
	in_internal_audit_source_id	IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
	out_cur						OUT	SYS_REFCURSOR,
	out_expiry_alert_role_cur	OUT SYS_REFCURSOR,
	out_involvement_type_cur	OUT SYS_REFCURSOR,
	out_carry_forward_cur		OUT SYS_REFCURSOR,
	out_closure_type_cur		OUT SYS_REFCURSOR,
	out_survey_type_cur			OUT SYS_REFCURSOR,
	out_iat_flow_states_cur		OUT SYS_REFCURSOR,
	out_iat_reports_cur 		OUT SYS_REFCURSOR
);

PROCEDURE FilterInternalAuditTypes(
	in_query					VARCHAR2,
	in_internal_audit_source_id	internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteInternalAuditTypeGroup(
	in_ia_type_group_id			IN	internal_audit_type_group.internal_audit_type_group_id%TYPE
);

PROCEDURE DeleteInternalAuditType(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
);

FUNCTION AreAllAuditsInTrash(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
) RETURN BOOLEAN;

FUNCTION AreAllAuditsInTrash_SQL(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
) RETURN NUMBER;

PROCEDURE SaveInternalAuditTypeGroup(
	in_ia_type_group_id				IN  internal_audit_type_group.internal_audit_type_group_id%TYPE,
	in_label						IN	internal_audit_type_group.label%TYPE,
	in_lookup_key					IN	internal_audit_type_group.lookup_key%TYPE, -- NULL will preserve the existing lookup key on update or generate one on create
	in_applies_to_regions			IN	internal_audit_type_group.applies_to_regions%TYPE,
	in_applies_to_users				IN	internal_audit_type_group.applies_to_users%TYPE,
	in_use_user_primary_region		IN	internal_audit_type_group.use_user_primary_region%TYPE,
	in_ref_prefix					IN	internal_audit_type_group.internal_audit_ref_prefix%TYPE,
	in_issue_type_id				IN	internal_audit_type_group.issue_type_id%TYPE,
	in_audit_singular_label			IN	internal_audit_type_group.audit_singular_label%TYPE,
	in_audit_plural_label			IN	internal_audit_type_group.audit_plural_label%TYPE,
	in_auditee_user_label			IN	internal_audit_type_group.auditee_user_label%TYPE,
	in_auditor_user_label			IN	internal_audit_type_group.auditor_user_label%TYPE,
	in_auditor_name_label			IN	internal_audit_type_group.auditor_name_label%TYPE,
	in_block_css_class				IN	internal_audit_type_group.block_css_class%TYPE,
	in_applies_to_permits			IN	internal_audit_type_group.applies_to_permits%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MakeInternalAuditTypeGroupMenu(
	in_ia_type_group_id				IN  internal_audit_type_group.internal_audit_type_group_id%TYPE,
	in_include_non_compliances		IN	NUMBER,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveInternalAuditType(
	in_internal_audit_type_id		IN	internal_audit_type.internal_audit_type_id%TYPE,
	in_label						IN	internal_audit_type.label%TYPE,
	in_every_n_months				IN	internal_audit_type.every_n_months%TYPE,
	in_auditor_role_sid				IN	internal_audit_type.auditor_role_sid%TYPE,
	in_audit_contact_role_sid		IN	internal_audit_type.audit_contact_role_sid%TYPE,
	in_default_survey_sid			IN	internal_audit_type.default_survey_sid%TYPE,
	in_default_auditor_org			IN	internal_audit_type.default_auditor_org%TYPE,
	in_override_issue_dtm			IN	internal_audit_type.override_issue_dtm%TYPE,
	in_assign_issues_to_role		IN	internal_audit_type.assign_issues_to_role%TYPE,
	in_involve_auditor_in_issues	IN	internal_audit_type.involve_auditor_in_issues%TYPE,
	in_auditor_can_take_ownership	IN  internal_audit_type.auditor_can_take_ownership%TYPE,
	in_add_nc_per_question			IN	internal_audit_type.add_nc_per_question%TYPE,
	in_nc_audit_child_region		IN	internal_audit_type.nc_audit_child_region%TYPE,
	in_flow_sid						IN  internal_audit_type.flow_sid%TYPE,
	in_internal_audit_source_id		IN  internal_audit_type.internal_audit_type_source_id%TYPE,
	in_summary_survey_sid			IN  internal_audit_type.summary_survey_sid%TYPE,
	in_send_auditor_expiry_alerts	IN  internal_audit_type.send_auditor_expiry_alerts%TYPE,
	in_expiry_alert_roles			IN  security_pkg.T_SID_IDS,
	in_validity_months				IN	internal_audit_type.validity_months%TYPE,
	in_audit_c_role_or_group_sid	IN  internal_audit_type.audit_coord_role_or_group_sid%TYPE DEFAULT NULL,
	in_tab_sid						IN  internal_audit_type.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  internal_audit_type.form_path%TYPE DEFAULT NULL,
	in_form_sid						IN  internal_audit_type.form_sid%TYPE DEFAULT NULL,
	in_ia_type_group_id				IN  internal_audit_type.internal_audit_type_group_id%TYPE DEFAULT NULL,
	in_nc_score_type_id				IN	internal_audit_type.nc_score_type_id%TYPE DEFAULT NULL,
	in_active 						IN  internal_audit_type.active%TYPE DEFAULT 1,
	in_show_primary_survey_in_hdr	IN	internal_audit_type.show_primary_survey_in_header%TYPE DEFAULT 1,
	in_use_legacy_closed_def		IN	internal_audit_type.use_legacy_closed_definition%TYPE DEFAULT 0,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplate(
	in_internal_audit_type_id		IN	internal_audit_type.internal_audit_type_id%TYPE,
	in_internal_audit_type_rep_id 	IN  internal_audit_type_report.internal_audit_type_report_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateMappedIndicators (
	in_audit_type_id			IN	internal_audit_type.internal_audit_type_id%TYPE,
	in_include_tot_clsd			IN	NUMBER := 0
);

PROCEDURE CreateMappedIndicators (
	in_audit_type_id				internal_audit_type.internal_audit_type_id%TYPE,
	in_lookup_key					internal_audit_type.lookup_key%TYPE,
	in_folder_ind_sid				security_pkg.T_SID_ID,
	in_measure_sid					security_pkg.T_SID_ID
);

PROCEDURE GetIndicatorValues (
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);
/*
PROCEDURE GetFlowIndicatorValues(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);
*/
FUNCTION GetIssueAuditUrl(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;

FUNCTION GetIssueAuditUrlWithNonCompId(
	in_internal_audit_sid	IN	security_pkg.T_SID_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE
) RETURN VARCHAR2;

PROCEDURE TriggerAuditJobs;

PROCEDURE GetClosureTypes(
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteClosureType(
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE SaveClosureType(
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE,
	in_label					IN	audit_closure_type.label%TYPE,
	in_is_failure				IN	audit_closure_type.is_failure%TYPE,
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetClosureTypesByAuditType(
	in_internal_audit_type_id	IN	audit_type_closure_type.internal_audit_type_id%TYPE,
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAuditTypeClosureType(
	in_internal_audit_type_id	IN	audit_type_closure_type.internal_audit_type_id%TYPE,
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE SaveAuditTypeClosureType(
	in_internal_audit_type_id	IN	audit_type_closure_type.internal_audit_type_id%TYPE,
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE,
	in_re_audit_due_after		IN	audit_type_closure_type.re_audit_due_after%TYPE,
	in_re_audit_due_after_type	IN	audit_type_closure_type.re_audit_due_after_type%TYPE,
	in_reminder_offset_days		IN	audit_type_closure_type.reminder_offset_days%TYPE,
	in_reportable_for_months	IN	audit_type_closure_type.reportable_for_months%TYPE,
	in_manual_expiry_date		IN	audit_type_closure_type.manual_expiry_date%TYPE,
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE ChangeClosureTypeIcon(
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE,
	in_cache_key				IN	aspen2.filecache.cache_key%type
);

PROCEDURE GetClosureTypeIcon(
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetClosureStatus(
	in_internal_audit_sid		IN	security_pkg.T_SID_ID,
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE SetOvwValidityDtm (
	in_internal_audit_sid 		IN  security_pkg.T_SID_ID,
	in_ovw_validity_dtm			IN  DATE,
	in_run_helper				IN NUMBER DEFAULT 0
);

PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RecordReminderSent(
	in_internal_audit_sid		IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE RecordOverdueSent(
	in_internal_audit_sid		IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE GetNonCompliancesRprt(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	in_tpl_region_type_id		IN	tpl_region_type.tpl_region_type_id%TYPE,
	in_tag_id					IN	tag.tag_id%TYPE,
	out_cur_ncs					OUT	SYS_REFCURSOR,
	out_cur_tags				OUT	SYS_REFCURSOR
);

PROCEDURE FixUpFiles(
	in_non_compliance_id		IN	non_compliance.non_compliance_id%TYPE,
	in_current_file_uploads		IN	security_pkg.T_SID_IDS,
	in_new_file_uploads			IN	T_CACHE_KEYS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CacheKeysArrayToTable(
	in_strings			IN	T_CACHE_KEYS
) RETURN security.T_VARCHAR2_TABLE;

PROCEDURE GetNonComplianceFile(
	in_noncompliance_file_id	IN	non_compliance_file.non_compliance_file_id%TYPE,
	in_sha1				IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFlowTransitions(
	in_audit_sid		IN  security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

PROCEDURE GenerateInvolmTypeAlertEntries(
	in_flow_item_id 				IN flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN security_pkg.T_SID_ID,
	in_flow_transition_alert_id		IN flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id		IN flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 			IN flow_state_log.flow_state_log_id%TYPE,
	in_subject_override				IN flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN flow_item_generated_alert.body_override%TYPE DEFAULT NULL
);

PROCEDURE GetFlowAlerts(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_refs					OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR,
	out_scores					OUT	security_pkg.T_OUTPUT_CUR,
	out_reports 				OUT	security_pkg.T_OUTPUT_CUR,
	out_audit_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_primary_purchasers		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForAuditPaged(
	in_audit_sid		IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditLogForAudit(
	in_audit_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditFlowRoleUsers(
	in_audit_sid					IN	security_pkg.T_SID_ID,
	out_role_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditFlowGroupUsers(
	in_audit_sid					IN	security_pkg.T_SID_ID,
	out_group_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckNonCompIssuesClosed(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE GetAuditTags (
	in_audit_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLockedAuditSurveyTags (
	in_audit_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetLockedAuditSurveyTags (
	in_audit_sid			IN	security_pkg.T_SID_ID,
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_survey_version		IN	quick_survey_response.survey_version%TYPE DEFAULT NULL,
	in_tag_ids 				IN	security_pkg.T_SID_IDS
);

PROCEDURE GetNonOverridenAuditRegionTags (
	in_audit_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditTabs (
	in_internal_audit_type_id		IN  internal_audit_type.internal_audit_type_id%TYPE,
	in_internal_audit_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SetAuditTab (
	in_internal_audit_type_id		IN  audit_type_tab.internal_audit_type_id%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  audit_type_tab.pos%TYPE,
	in_tab_label					IN  audit_type_tab.tab_label%TYPE,
	in_flow_capability_id			IN	audit_type_tab.flow_capability_id%TYPE DEFAULT NULL
);

PROCEDURE SetAuditTab(
	in_internal_audit_type_id		IN  audit_type_tab.internal_audit_type_id%TYPE,
	in_plugin_id					IN  audit_type_tab.plugin_id%TYPE,
	in_pos							IN  audit_type_tab.pos%TYPE,
	in_tab_label					IN  audit_type_tab.tab_label%TYPE,
	in_flow_capability_id			IN	audit_type_tab.flow_capability_id%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveAuditTab(
	in_internal_audit_type_id		IN  audit_type_tab.internal_audit_type_id%TYPE,
	in_plugin_id					IN  audit_type_tab.plugin_id%TYPE
);

PROCEDURE GetAuditHeaders (
	in_internal_audit_type_id		IN  internal_audit_type.internal_audit_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SetAuditHeader(
	in_internal_audit_type_id		IN  audit_type_header.internal_audit_type_id%TYPE,
	in_plugin_id					IN  audit_type_header.plugin_id%TYPE,
	in_pos							IN  audit_type_header.pos%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveAuditHeader(
	in_internal_audit_type_id		IN  audit_type_header.internal_audit_type_id%TYPE,
	in_plugin_id					IN  audit_type_header.plugin_id%TYPE
);

PROCEDURE GetAuditorRegions(
	in_search_phrase				IN	VARCHAR2,
	in_modified_since_dtm			IN	audit_log.audit_date%TYPE,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetResponseToAudit (
	in_survey_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetAuditsWithAllIssuesClosed(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordAuditAllIssuesClosed(
	in_app_sid						IN  audit_iss_all_closed_alert.app_sid%TYPE,
	in_internal_audit_sid			IN	audit_iss_all_closed_alert.internal_audit_sid%TYPE,
	in_user_sid						IN	audit_iss_all_closed_alert.CSR_USER_SID%TYPE
);

PROCEDURE GetNonComplianceTypes (
	in_internal_audit_type_id		IN  non_comp_type_audit_type.internal_audit_type_id%TYPE DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_audit_type_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_repeat_audit_type_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetNonComplianceType (
	in_non_compliance_type_id			IN  non_compliance_type.non_compliance_type_id%TYPE,
	in_label							IN  non_compliance_type.label%TYPE,
	in_lookup_key						IN  non_compliance_type.lookup_key%TYPE,
	in_position							IN  non_compliance_type.position%TYPE,
	in_colour_when_open					IN  non_compliance_type.colour_when_open%TYPE,
	in_colour_when_closed				IN  non_compliance_type.colour_when_closed%TYPE,
	in_can_have_actions					IN  non_compliance_type.can_have_actions%TYPE,
	in_closure_behaviour_id				IN  non_compliance_type.closure_behaviour_id%TYPE,
	in_score							IN	non_compliance_type.score%TYPE DEFAULT NULL,
	in_repeat_score						IN	non_compliance_type.repeat_score%TYPE DEFAULT NULL,
	in_root_cause_enabled				IN	non_compliance_type.root_cause_enabled%TYPE DEFAULT 0,
	in_suggested_action_enabled			IN	non_compliance_type.suggested_action_enabled%TYPE DEFAULT 0,
	in_match_repeats_by_carry_fwd		IN	non_compliance_type.match_repeats_by_carry_fwd%TYPE DEFAULT 0,		
	in_match_repeats_by_dflt_ncs		IN	non_compliance_type.match_repeats_by_default_ncs%TYPE DEFAULT 0,	
	in_match_repeats_by_surveys			IN	non_compliance_type.match_repeats_by_surveys%TYPE DEFAULT 0,
	in_find_repeats_in_unit				IN	non_compliance_type.find_repeats_in_unit%TYPE DEFAULT NCT_RPT_MATCH_UNIT_NONE,
	in_find_repeats_in_qty				IN	non_compliance_type.find_repeats_in_qty%TYPE DEFAULT NULL,
	in_carry_fwd_repeat_type			IN	non_compliance_type.carry_fwd_repeat_type%TYPE DEFAULT NCT_CARRY_FWD_RPT_TYPE_NORMAL,
	in_is_default_survey_finding		IN	non_compliance_type.is_default_survey_finding%TYPE DEFAULT 0,
	in_is_flow_capability_enabled		IN	NUMBER	DEFAULT 0,
	in_repeat_audit_type_ids			IN	security_pkg.T_SID_IDS,
	out_non_compliance_type_id			OUT	non_compliance_type.non_compliance_type_id%TYPE
);

PROCEDURE DeleteNonComplianceType (
	in_non_compliance_type_id		IN  non_compliance_type.non_compliance_type_id%TYPE
);

PROCEDURE SetAuditTypeNonCompType (
	in_internal_audit_type_id	IN  non_comp_type_audit_type.internal_audit_type_id%TYPE,
	in_non_compliance_type_id	IN  non_comp_type_audit_type.non_compliance_type_id%TYPE
);

PROCEDURE DeleteAuditTypeNonCompType (
	in_internal_audit_type_id	IN  non_comp_type_audit_type.internal_audit_type_id%TYPE,
	in_non_compliance_type_id	IN  non_comp_type_audit_type.non_compliance_type_id%TYPE
);

FUNCTION GetNonComplianceTypeId (
	in_nc_type_label			IN	NVARCHAR2,
	in_audit_sid				IN	security.security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE RecalculateAuditNCScore(
	in_internal_audit_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE RecalculateAuditNCScoreThrsh(
	in_internal_audit_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE IsAuditDeletable(
	in_internal_audit_sid	IN	internal_audit.internal_audit_sid%TYPE,
	out_is_deletable		OUT NUMBER
);

PROCEDURE OverwriteNCScoreThreshold(
	in_internal_audit_sid	IN	internal_audit.internal_audit_sid%TYPE,
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE
);

PROCEDURE GetIndSidByLookupKey (
	in_lookup_key				IN	ind.lookup_key%TYPE,
	out_ind_sid					OUT	ind.ind_sid%TYPE
);

PROCEDURE GetOrCreateAggregateInd(
	in_parent				IN	ind.parent_sid%TYPE,
	in_name					IN	ind.name%TYPE,
	in_desc					IN	ind_description.description%TYPE,
	in_lookup_key			IN	ind.lookup_key%TYPE,
	in_divisibility			IN	ind.divisibility%TYPE,
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_info_definition		IN  VARCHAR2,
	out_ind_sid				OUT	ind.ind_sid%TYPE
);

FUNCTION GetAuditFlowStateIndName (
	in_flow_state_id				IN	flow_state.flow_state_id%TYPE,
	in_flow_st_audit_ind_type_id	IN	flow_state_audit_ind_type.flow_state_audit_ind_type_id%TYPE
) RETURN VARCHAR2;

PROCEDURE SetAuditFlowStateInd(
	in_flow_state_id				IN	flow_state.flow_state_id%TYPE,
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_flow_state_type_ind_id		IN	flow_state_audit_ind_type.flow_state_audit_ind_type_id%TYPE,
	in_internal_audit_type_id		IN	internal_audit.internal_audit_type_id%TYPE
);

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetAvailableFlowInvTypes (
	in_internal_audit_type_id		IN	internal_audit_type.internal_audit_type_id%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditTypeFlowInvTypes (
	in_internal_audit_type_id		IN	internal_audit_type.internal_audit_type_id%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvolvedUsers (
	in_internal_audit_sid			IN	internal_audit.internal_audit_sid%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveAuditTypeInvType(
	in_adt_type_flow_inv_type_id	IN	audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
	in_flow_involvement_type_id		IN 	audit_type_flow_inv_type.flow_involvement_type_id%TYPE,
	in_internal_audit_type_id		IN	audit_type_flow_inv_type.internal_audit_type_id%TYPE,
	in_users_role_or_group_sid		IN	audit_type_flow_inv_type.users_role_or_group_sid%TYPE,
	in_min_users					IN	audit_type_flow_inv_type.min_users%TYPE,
	in_max_users					IN	audit_type_flow_inv_type.max_users%TYPE,
	out_adt_type_flow_inv_type_id	OUT	audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE
);

PROCEDURE DeleteAuditTypeFlowInvType (
	in_adt_type_flow_inv_type_id	IN	audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE
);

PROCEDURE SetAuditInvolvedUsers (
	in_audit_sid					IN	internal_audit.internal_audit_sid%TYPE,
	in_adt_type_flow_inv_type_id	IN	audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
	in_user_sids					IN	security.security_pkg.T_SID_IDS
);

PROCEDURE SetAuditInvolvedUsers (
	in_audit_sid					IN	internal_audit.internal_audit_sid%TYPE,
	in_adt_type_flow_inv_type_id	IN	audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
	in_flow_involvement_type_id		IN	flow_involvement_type.flow_involvement_type_id%TYPE,
	in_user_sids					IN	security.security_pkg.T_SID_IDS
);

PROCEDURE UNSEC_SetAuditInvolvedUsers (
	in_audit_sid					IN	internal_audit.internal_audit_sid%TYPE,
	in_adt_type_flow_inv_type_id	IN	audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
	in_flow_involvement_type_id		IN	flow_involvement_type.flow_involvement_type_id%TYPE,
	in_user_sids					IN	security.security_pkg.T_SID_IDS
);

PROCEDURE CopySurveyAnswersToSummary (
	in_audit_sid					IN	internal_audit.internal_audit_sid%TYPE
);

FUNCTION MultipleSurveysEnabled
RETURN BOOLEAN;

PROCEDURE GetAuditTypeSurveyGroups (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAuditTypeSurveyGroup (
	in_ia_type_survey_group_id		IN	ia_type_survey_group.ia_type_survey_group_id%TYPE,
	in_label						IN	ia_type_survey_group.label%TYPE,
	in_lookup_key					IN	ia_type_survey_group.lookup_key%TYPE,
	out_ia_type_survey_group_id		OUT	ia_type_survey_group.ia_type_survey_group_id%TYPE
);

PROCEDURE DeleteAuditTypeSurveyGroup (
	in_ia_type_survey_group_id		IN	ia_type_survey_group.ia_type_survey_group_id%TYPE
);

PROCEDURE GetAuditTypeSurveys(
	in_internal_audit_type_id		IN	internal_audit_type_survey.internal_audit_type_id%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDefaultSurvey(
	in_internal_audit_type_id		IN	internal_audit_type_survey.internal_audit_type_id%TYPE,
	in_default_survey_sid			IN	internal_audit_type_survey.default_survey_sid%TYPE
);

PROCEDURE SetAuditTypeSurvey(
	in_internal_audit_type_id		IN	internal_audit_type_survey.internal_audit_type_id%TYPE,
	in_ia_type_survey_id			IN	internal_audit_type_survey.internal_audit_type_survey_id%TYPE,
	in_active						IN	internal_audit_type_survey.active%TYPE,
	in_label						IN	internal_audit_type_survey.label%TYPE,
	in_ia_type_survey_group_id		IN	internal_audit_type_survey.ia_type_survey_group_id%TYPE,
	in_default_survey_sid			IN	internal_audit_type_survey.default_survey_sid%TYPE,
	in_mandatory					IN	internal_audit_type_survey.mandatory%TYPE,
	in_survey_fixed					IN	internal_audit_type_survey.survey_fixed%TYPE,
	in_survey_group_key				IN	internal_audit_type_survey.survey_group_key%TYPE,
	out_ia_type_survey_id			OUT	internal_audit_type_survey.internal_audit_type_survey_id%TYPE
);

PROCEDURE DeleteAuditTypeSurveys(
	in_internal_audit_type_id		IN	internal_audit_type_survey.internal_audit_type_id%TYPE,
	in_keep_ia_type_survey_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetAuditTypeSurveyDefaultPerms(
	in_internal_audit_type_id		IN	internal_audit_type_survey.internal_audit_type_id%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_auditee_user_sid				IN	security_pkg.T_SID_ID,
	in_auditor_user_sid				IN	security_pkg.T_SID_ID,
	in_auditor_company_sid			IN	security_pkg.T_SID_ID,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

FUNCTION SQL_HasSurveyAccess(
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_ia_type_survey_id		IN	internal_audit_survey.internal_audit_type_survey_id%TYPE,
	in_change_survey			IN	NUMBER
) RETURN BINARY_INTEGER;

FUNCTION HasSurveyAccess(
	in_audit_sid				IN	security_pkg.T_SID_ID,
	in_ia_type_survey_id		IN	internal_audit_survey.internal_audit_type_survey_id%TYPE,
	in_change_survey			IN	NUMBER
) RETURN BOOLEAN;

PROCEDURE GetAuditSurveys(
	in_internal_audit_sid			IN	internal_audit_survey.internal_audit_sid%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAuditSurvey(
	in_internal_audit_sid			IN	internal_audit_survey.internal_audit_sid%TYPE,
	in_ia_type_survey_id			IN	internal_audit_survey.internal_audit_type_survey_id%TYPE,
	in_survey_sid					IN	internal_audit_survey.survey_sid%TYPE
);

PROCEDURE DeleteAuditSurvey(
	in_internal_audit_sid			IN	internal_audit_survey.internal_audit_sid%TYPE,
	in_ia_type_survey_id			IN	internal_audit_survey.internal_audit_type_survey_id%TYPE
);

PROCEDURE GetFixedSurveys(
	in_internal_audit_type_id	IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetNonComplianceTypes(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetIATExpiryAlertRoles(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetIATInvolmentTypes(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SetAuditTags (
	in_audit_sid					IN	internal_audit.internal_audit_sid%TYPE,
	in_tag_ids						IN	security.security_pkg.T_SID_IDS,
	in_copy_locked_tags_from_sid	IN	security.security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE UNSEC_SyncRegionsForUser(
	in_user_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE FilterUsersByRoleGroupRegion(
	in_group_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_role_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_region_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,	
	in_filter_name			IN	csr_user.full_name%TYPE DEFAULT NULL,
	in_auditor_company_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR,
	out_total_num_users		OUT SYS_REFCURSOR
);

FUNCTION GetPrimarySurveyScoreTypeIds 
RETURN security.T_SID_TABLE;

PROCEDURE GetPrimarySurveyScoreTypeIds(
	out_cur		 OUT	SYS_REFCURSOR
);

PROCEDURE GetSurveyGroupScoreTypes(
	out_cur		 OUT	SYS_REFCURSOR
);

PROCEDURE GetInternalAuditTypeReports(
	in_audit_type_id 	IN  internal_audit_type.internal_audit_type_id%TYPE,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE SetAuditTypeReports(
	in_internal_audit_type_id		IN	internal_audit_type_survey.internal_audit_type_id%TYPE,
	in_keep_ia_type_report_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetPublicReport (
	in_guid							IN	internal_audit_report_guid.guid%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePublicReport (
	in_internal_audit_type_rpt_id	IN	internal_audit_type_report.internal_audit_type_report_id%TYPE,
	in_filename 					IN  internal_audit_report_guid.filename%TYPE,
	in_doc_type 					IN  internal_audit_report_guid.doc_type%TYPE,
	in_document 					IN  internal_audit_report_guid.document%TYPE,
	in_guid 						IN  internal_audit_report_guid.guid%TYPE
);

PROCEDURE GetInternalAuditReportGroups (
	out_cur 			OUT  SYS_REFCURSOR
);

PROCEDURE SaveInternalAuditTypeReport (
	in_audit_type_report_id 		IN  internal_audit_type_report.internal_audit_type_report_id%TYPE,
	in_internal_audit_type_id 		IN  internal_audit.internal_audit_sid%TYPE,
	in_label 						IN  internal_audit_type_report.label%TYPE,
	in_cache_key 					IN  aspen2.filecache.cache_key%type,
	in_ia_type_report_group_id 		IN  internal_audit_type_report.ia_type_report_group_id%TYPE,
	in_use_guid						IN	internal_audit_type_report.use_merge_field_guid%TYPE,
	in_guid_expiration				IN	internal_audit_type_report.guid_expiration_days%TYPE DEFAULT NULL,
	out_internal_audit_report_id 	OUT internal_audit_type_report.internal_audit_type_report_id%TYPE
);

PROCEDURE SaveIATypeReportGroup (
	in_ia_type_report_group_id 		IN  ia_type_report_group.ia_type_report_group_id%TYPE,
	in_label 						IN  ia_type_survey_group.label%TYPE,
	out_ia_type_report_group_id 	OUT ia_type_report_group.ia_type_report_group_id%TYPE
);

PROCEDURE ProcessExpiredPublicReports;

PROCEDURE GetAuditScores(
	in_internal_audit_sid			IN	internal_audit.internal_audit_sid%TYPE,
	in_internal_audit_type_id		IN	internal_audit.internal_audit_type_id%TYPE,
	in_flow_item_id					IN	internal_audit.flow_item_id%TYPE,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAuditScore(
	in_internal_audit_sid			IN	internal_audit_score.internal_audit_sid%TYPE,
	in_score_type_id				IN	internal_audit_score.score_type_id%TYPE,
	in_score						IN	internal_audit_score.score%TYPE,
	in_score_threshold_id			IN	internal_audit_score.score_threshold_id%TYPE,
	in_override_system_threshold	IN	NUMBER DEFAULT 0
);

PROCEDURE UNSEC_SetAuditScore(
	in_internal_audit_sid			IN	internal_audit_score.internal_audit_sid%TYPE,
	in_score_type_id				IN	internal_audit_score.score_type_id%TYPE,
	in_score						IN	internal_audit_score.score%TYPE,
	in_score_threshold_id			IN	internal_audit_score.score_threshold_id%TYPE,
	in_override_system_threshold	IN	NUMBER
);

PROCEDURE GetAuditsByInternalRef (
	in_internal_audit_ref		IN internal_audit.internal_audit_ref%TYPE,
	out_audits_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditsByExternalAuditRef (
	in_external_audit_ref		IN internal_audit.external_audit_ref%TYPE,
	out_audits_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditsByExternalParentRef (
	in_external_parent_ref		IN internal_audit.external_parent_ref%TYPE,
	out_audits_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditsByInternalAuditTypeAndCompanySid (
	in_internal_audit_type_id		IN internal_audit.internal_audit_type_id%TYPE,
	in_company_sid					IN security_pkg.T_SID_ID,
	out_audits_cur					OUT	SYS_REFCURSOR
);

FUNCTION GetAuditTypeByLookup (
	in_audit_type_lookup			IN  internal_audit_type.lookup_key%TYPE
) RETURN NUMBER;

PROCEDURE DeleteAuditsOfTypeFromRegion (
	in_act_sid						IN  security_pkg.T_ACT_ID,
	in_audit_type_lookup			IN  internal_audit_type.lookup_key%TYPE,
	in_region_sid					IN	internal_audit.region_sid%TYPE
);

FUNCTION UNSEC_CountInvUsersForType(
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_involv_type_lookup_key	IN  flow_involvement_type.lookup_key%TYPE
) RETURN NUMBER;

FUNCTION GetIndLookup(
	in_parent_lookup_key	IN	VARCHAR2,
	in_prefix				IN	VARCHAR2,
	in_lookup_key			IN	VARCHAR2,
	in_name					IN	VARCHAR2
) RETURN VARCHAR2;

PROCEDURE DeleteSurveyAndResponseDataFromAuditType(
	in_internal_audit_type_id		IN internal_audit.internal_audit_type_id%TYPE,
	in_keep_ia_type_survey_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetAllDocuments(
	in_sid_id					IN	security_pkg.T_SID_ID,
	out_audit_docs_cur			OUT SYS_REFCURSOR,
	out_finding_docs_cur		OUT	SYS_REFCURSOR,
	out_action_docs_cur			OUT SYS_REFCURSOR
);

END audit_pkg;
/
