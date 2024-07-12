create or replace PACKAGE csr.temp_audit_pkg AS

-- PL/SQL table of file upload cache keys
TYPE T_CACHE_KEYS IS TABLE OF aspen2.filecache.cache_key%TYPE INDEX BY PLS_INTEGER;

AUDIT_AGG_IND_GROUP            CONSTANT VARCHAR2(100) := 'InternalAudit';

IND_TYPE_FLOW_STATE_COUNT    CONSTANT NUMBER(10) := 1;
IND_TYPE_FLOW_STATE_TIME    CONSTANT NUMBER(10) := 2;

PRIMARY_AUDIT_TYPE_SURVEY_ID    CONSTANT NUMBER(10) := 0;

NCT_RPT_MATCH_UNIT_NONE            CONSTANT VARCHAR2(10) := 'none';
NCT_RPT_MATCH_UNIT_ALL            CONSTANT VARCHAR2(10) := 'all';
NCT_RPT_MATCH_UNIT_AUDITS        CONSTANT VARCHAR2(10) := 'audits';
NCT_RPT_MATCH_UNIT_MONTHS        CONSTANT VARCHAR2(10) := 'months';
NCT_RPT_MATCH_UNIT_YEARS        CONSTANT VARCHAR2(10) := 'years';

NCT_CARRY_FWD_RPT_TYPE_NORMAL    CONSTANT VARCHAR2(10) := 'normal';
NCT_CARRY_FWD_RPT_TYPE_AS_CRTD    CONSTANT VARCHAR2(10) := 'as_created';
NCT_CARRY_FWD_RPT_TYPE_NEVER    CONSTANT VARCHAR2(10) := 'never';

UNDEFINED_AUDIT_SOURCE_ID         CONSTANT NUMBER(10) := 0;
INTERNAL_AUDIT_SOURCE_ID        CONSTANT NUMBER(10) := 1;
EXTERNAL_AUDIT_SOURCE_ID        CONSTANT NUMBER(10) := 2;
INTEGRATION_AUDIT_SOURCE_ID        CONSTANT NUMBER(10) := 3;

ERR_REGION_AUDIT            CONSTANT NUMBER := -20008;

-- Securable object callbacks
PROCEDURE CreateObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID,
    in_class_id                IN security_pkg.T_CLASS_ID,
    in_name                    IN security_pkg.T_SO_NAME,
    in_parent_sid_id        IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID,
    in_new_name                IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID,
    in_new_parent_sid_id    IN security_pkg.T_SID_ID,
    in_old_parent_sid_id    IN security_pkg.T_SID_ID
);

PROCEDURE TrashAudit (
    in_internal_audit_sid    IN    internal_audit.internal_audit_sid%TYPE
);

PROCEDURE INTERNAL_CreateRefID_Non_Comp(
    in_non_compliance_id        IN    csr.non_compliance.non_compliance_id%TYPE
);

FUNCTION GetAuditsForUserAsTable
RETURN security.T_SID_TABLE;

FUNCTION GetAuditsWithCapabilityAsTable (
    in_capability_id            IN    flow_capability.flow_capability_id%TYPE,
    in_permission                IN    NUMBER,
    in_page                        IN    security.T_ORDERED_SID_TABLE
) RETURN security.T_SID_TABLE;

FUNCTION SupportsDueAudits
RETURN NUMBER;

FUNCTION HasReadAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN BOOLEAN;

/* Compatible with C# */
FUNCTION SQL_HasReadAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION HasWriteAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION HasDeleteAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION GetPermissionOnAudit(
in_sid_id                IN    internal_audit.internal_audit_sid%TYPE
)RETURN NUMBER;

FUNCTION SQL_IsAuditAdministrator
RETURN BINARY_INTEGER;

FUNCTION IsFlowAudit(
    in_internal_audit_sid        IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION SQL_HasCapabilityAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_capability_id            IN    flow_capability.flow_capability_id%TYPE,
    in_permission                IN    NUMBER
) RETURN BINARY_INTEGER;

FUNCTION HasCapabilityAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_capability_id            IN    flow_capability.flow_capability_id%TYPE,
    in_permission                IN    NUMBER
) RETURN BOOLEAN;

PROCEDURE GetAbilities (
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_include_all                IN    NUMBER,
    out_cur                        OUT    SYS_REFCURSOR,
    out_surveys_cur                OUT    SYS_REFCURSOR,
    out_non_compliance_types    OUT    SYS_REFCURSOR
);

PROCEDURE GetAbilities (
    in_audit_sid                IN    security_pkg.T_SID_ID,
    out_cur                        OUT    SYS_REFCURSOR,
    out_surveys_cur                OUT    SYS_REFCURSOR,
    out_non_compliance_types    OUT SYS_REFCURSOR
);

FUNCTION GetAbilities (
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_include_all                IN    NUMBER
) RETURN T_AUDIT_ABILITY_TABLE;

PROCEDURE GetDetails(
    in_sid_id                IN    internal_audit.internal_audit_sid%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetAuditTypeCarryForwards (
    out_cur                        OUT    SYS_REFCURSOR
);

PROCEDURE SetAuditTypeCarryForwards (
    in_to_ia_type_id            IN    internal_audit.internal_audit_type_id%TYPE,
    in_from_ia_type_ids            IN    security_pkg.T_SID_IDS
);

PROCEDURE GetSidOfAuditToCarryForward (
    in_region_sid                IN    internal_audit.region_sid%TYPE,
    in_internal_audit_type        IN    internal_audit.internal_audit_type_id%TYPE,
    in_audit_dtm                IN    internal_audit.audit_dtm%TYPE,
    out_carry_from_audit_sid    OUT    security_pkg.T_SID_ID,
    out_label                    OUT    internal_audit.label%TYPE
);

PROCEDURE GetAuditsToCarryForward (
    in_carry_to_audit_type_id    IN    internal_audit.internal_audit_type_id%TYPE,
    out_cur                        OUT    SYS_REFCURSOR
);

PROCEDURE GetResponsesToCarryForward (
    in_carry_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_survey_sids                IN    security_pkg.T_SID_IDS,
    in_region_sid                IN    security_pkg.T_SID_ID,
    in_audit_dtm                IN    DATE,
    out_cur                        OUT    SYS_REFCURSOR
);

PROCEDURE CheckForCarryForward (
    in_carry_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_carry_to_audit_type_id    IN    internal_audit.internal_audit_type_id%TYPE,
    out_cur                        OUT    SYS_REFCURSOR,
    out_cur_documents            OUT    SYS_REFCURSOR,
    out_cur_postits                OUT    SYS_REFCURSOR
);

PROCEDURE Save(
    in_sid_id                    IN    internal_audit.internal_audit_sid%TYPE,
    in_audit_ref                IN    internal_audit.internal_audit_ref%TYPE,
    in_survey_sid                IN    internal_audit.survey_sid%TYPE,
    in_region_sid                IN    internal_audit.region_sid%TYPE,
    in_label                    IN    internal_audit.label%TYPE,
    in_audit_dtm                IN    internal_audit.audit_dtm%TYPE,
    in_auditor_user_sid            IN    internal_audit.auditor_user_sid%TYPE,
    in_notes                    IN    internal_audit.notes%TYPE,
    in_internal_audit_type        IN    internal_audit.internal_audit_type_id%TYPE,
    in_auditor_name                IN    internal_audit.auditor_name%TYPE,
    in_auditor_org                IN    internal_audit.auditor_organisation%TYPE,
    in_response_to_audit        IN    internal_audit.comparison_response_id%TYPE DEFAULT NULL,
    in_created_by_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_auditee_user_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_auditee_company_sid        IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_auditor_company_sid        IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_created_by_company_sid    IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_permit_id                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_external_audit_ref        IN    internal_audit.external_audit_ref%TYPE DEFAULT NULL,
    in_external_parent_ref        IN    internal_audit.external_parent_ref%TYPE DEFAULT NULL,
    in_external_url                IN    internal_audit.external_url%TYPE DEFAULT NULL,
    out_sid_id                    OUT    internal_audit.internal_audit_sid%TYPE
);

PROCEDURE SaveSupplierAudit (
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_auditee_company_sid        IN    security_pkg.T_SID_ID,
    in_auditor_company_sid        IN    security_pkg.T_SID_ID,
    in_created_by_company_sid    IN    security_pkg.T_SID_ID
);

PROCEDURE SetAuditorCompanySid (
    in_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_auditor_company_sid    IN    security_pkg.T_SID_ID
);

PROCEDURE DeleteInternalAuditFiles(
    in_internal_audit_sid        IN    internal_audit.internal_audit_sid%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE InsertInternalAuditFiles(
    in_internal_audit_sid        IN    internal_audit.internal_audit_sid%TYPE,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInternalAuditFile(
    in_int_audit_file_data_id    IN    internal_audit_file_data.internal_audit_file_data_id%TYPE,
    in_sha1                        IN  internal_audit_file_data.sha1%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveNonInteractiveAudit(
    in_sid_id                    IN    internal_audit.internal_audit_sid%TYPE,
    in_region_sid                IN    internal_audit.region_sid%TYPE,
    in_internal_audit_type        IN    internal_audit.internal_audit_type_id%TYPE,
    in_label                    IN    internal_audit.label%TYPE,
    in_audit_dtm                IN    internal_audit.audit_dtm%TYPE,
    in_audit_closure_type_id    IN    internal_audit.audit_closure_type_id%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    in_audit_ref                IN    internal_audit.internal_audit_ref%TYPE DEFAULT csr_data_pkg.PRESERVE_NUMBER,
    out_sid_id                    OUT    internal_audit.internal_audit_sid%TYPE
);

PROCEDURE GetAuditSummary(
    in_internal_audit_sid        IN  internal_audit.internal_audit_sid%TYPE,
    out_audit_cur                OUT security_pkg.T_OUTPUT_CUR,
    out_documents_cur            OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditSummaries(
    in_parent_region_sid        IN  internal_audit.internal_audit_sid%TYPE,
    in_internal_audit_source_id    IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT EXTERNAL_AUDIT_SOURCE_ID,
    out_audit_cur                OUT security_pkg.T_OUTPUT_CUR,
    out_documents_cur            OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CarryForwardPostits (
    in_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_to_audit_sid            IN    security_pkg.T_SID_ID
);

PROCEDURE CarryForwardDocuments (
    in_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_to_audit_sid            IN    security_pkg.T_SID_ID
);

PROCEDURE CarryForwardOpenNCs (
    in_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_to_audit_sid            IN    security_pkg.T_SID_ID,
    in_take_ownership_of_issues    IN  NUMBER DEFAULT 0
);

PROCEDURE CarryForwardSurveyResponse (
    in_from_response_id                IN    internal_audit.survey_response_id%TYPE,
    in_to_audit_sid                    IN    security.security_pkg.T_SID_ID,
    in_to_audit_type_survey_id        IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
);

-- Deprecated. Still used by portlets, calendar and RestAPI - but new things should use audit_report_pkg.GetAuditList
PROCEDURE Browse(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_non_compliance    IN    NUMBER,
    in_overdue                IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_ia_type_group_id        IN    internal_audit_type.internal_audit_type_group_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
);

/*A lightweight version for plugins that returns only the data needed
eventually we will retire all browse SP versions*/
PROCEDURE BrowseForPlugin(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_non_compliance    IN    NUMBER,
    in_overdue                IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_ia_type_group_id        IN    internal_audit_type.internal_audit_type_group_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE SearchAudits (
    in_search_term            VARCHAR2,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE SearchAuditsMore (
    in_search_term                    VARCHAR2,
    in_internal_audit_source_id        IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                            OUT    SYS_REFCURSOR
);

-- Deprecated. Still used by RestAPI - but new things should use non_compliance_report_pkg.GetNonComplianceList
PROCEDURE BrowseNonCompliances(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_actions            IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_ia_type_group_id        IN    internal_audit_type.internal_audit_type_group_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR,
    out_tags                OUT    SYS_REFCURSOR
);

PROCEDURE BrowseDueAudits(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetNonComplianceAudits(
    in_non_compliance_ids    IN security_pkg.T_SID_IDS, -- not sids, but this the closest type
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetIssueTypeFromAudit (
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_issue_type_cur        OUT    SYS_REFCURSOR
);

PROCEDURE GetDetails(
    in_sid_id                IN    security_pkg.T_SID_ID,
    out_details_cur            OUT    SYS_REFCURSOR,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_upload_cur        OUT    SYS_REFCURSOR,
    out_nc_tag_cur            OUT    SYS_REFCURSOR,
    out_documents_cur        OUT SYS_REFCURSOR
);

PROCEDURE GetExtraDetails(
    in_sid_id                IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_upload_cur        OUT    SYS_REFCURSOR,
    out_nc_tag_cur            OUT    SYS_REFCURSOR,
    out_documents_cur        OUT SYS_REFCURSOR
);

PROCEDURE GetDetailsForMailMerge(
    in_sid_id                    IN    security_pkg.T_SID_ID,
    in_report_id                 IN  security_pkg.T_SID_ID,
    out_details_cur                OUT    SYS_REFCURSOR,
    out_nc_cur                    OUT    SYS_REFCURSOR,
    out_nc_upload_cur            OUT    SYS_REFCURSOR,
    out_nc_tag_cur                OUT    SYS_REFCURSOR,
    out_issues_cur                OUT    SYS_REFCURSOR,
    out_template_cur            OUT    SYS_REFCURSOR,
    out_issues_fields_cur        OUT    SYS_REFCURSOR,
    out_issue_logs_cur            OUT SYS_REFCURSOR,
    out_issue_log_files_cur        OUT    SYS_REFCURSOR,
    out_issue_action_log_cur    OUT    SYS_REFCURSOR
);

PROCEDURE GetDetailsForMailMergeAllFiles(
    in_sid_id                    IN    security_pkg.T_SID_ID,
    in_report_id                 IN  security_pkg.T_SID_ID,
    out_details_cur                OUT    SYS_REFCURSOR,
    out_nc_cur                    OUT    SYS_REFCURSOR,
    out_nc_upload_cur            OUT    SYS_REFCURSOR,
    out_nc_tag_cur                OUT    SYS_REFCURSOR,
    out_issues_cur                OUT    SYS_REFCURSOR,
    out_template_cur            OUT    SYS_REFCURSOR,
    out_issues_fields_cur        OUT    SYS_REFCURSOR,
    out_postit_files_cur        OUT SYS_REFCURSOR,
    out_audit_files_cur            OUT SYS_REFCURSOR,
    out_issue_logs_cur            OUT SYS_REFCURSOR,
    out_issue_log_files_cur        OUT    SYS_REFCURSOR,
    out_issue_action_log_cur    OUT    SYS_REFCURSOR
);

PROCEDURE GetNonCompliancesForAudit(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR
);

PROCEDURE GetNonCompliancesForAudit(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_tags_cur            OUT    SYS_REFCURSOR
);

PROCEDURE ExportAuditsFindingsAndActions(
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_tags_cur            OUT    SYS_REFCURSOR,
    out_issue_fields_cur    OUT    SYS_REFCURSOR,
    out_audit_tags_cur        OUT    SYS_REFCURSOR,
    out_scores_cur            OUT    SYS_REFCURSOR
);

-- Export NCs and their actions in a format for round-tripping
-- i.e. one line per action with NC details duplicated
PROCEDURE ExportFindingsAndActions(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_tags_cur            OUT    SYS_REFCURSOR,
    out_issue_fields_cur    OUT    SYS_REFCURSOR
);

-- Folder handler sprocs
PROCEDURE GetDefaultNCFoldersWithDepth(
    in_parent_id                IN    non_comp_default_folder.parent_folder_id%TYPE,
    in_fetch_depth                IN    NUMBER,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateDefaultNonCompFolder (
    in_parent_id                IN    non_comp_default_folder.parent_folder_id%TYPE,
    in_label                    IN    non_comp_default_folder.label%TYPE,
    out_folder_id                OUT non_comp_default_folder.non_comp_default_folder_id%TYPE
);

PROCEDURE GetOrCreateDNCFolderFromPath (
    in_path                        IN    VARCHAR2,
    out_folder_id                OUT non_comp_default_folder.non_comp_default_folder_id%TYPE
);

PROCEDURE DeleteDefaultNonCompFolder (
    in_folder_id                IN    non_comp_default_folder.non_comp_default_folder_id%TYPE
);

PROCEDURE RenameDefaultNonCompFolder (
    in_folder_id                IN    non_comp_default_folder.non_comp_default_folder_id%TYPE,
    in_label                    IN    non_comp_default_folder.label%TYPE
);

PROCEDURE MoveDefaultNonCompFolder (
    in_folder_id                IN    non_comp_default_folder.non_comp_default_folder_id%TYPE,
    in_parent_id                IN    non_comp_default_folder.parent_folder_id%TYPE
);

PROCEDURE MoveDefaultNonCompliance (
    in_default_non_comp_id        IN    non_comp_default.non_comp_default_id%TYPE,
    in_parent_id                IN    non_comp_default.non_comp_default_folder_id%TYPE
);

PROCEDURE GetAllDNCFolders (
    in_internal_audit_type_id    IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
    out_cur                        OUT SYS_REFCURSOR
);

-- Default Non-Compliance management sprocs
FUNCTION GetCustomPermissibleAuditNCTs(
    in_access                IN    security_pkg.T_PERMISSION
) RETURN csr.T_AUDIT_PERMISSIBLE_NCT_TABLE;

FUNCTION GetPermissibleNCTypeIds(
    in_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_access                IN    security_pkg.T_PERMISSION
) RETURN security.T_SID_TABLE;

FUNCTION HasFlowAuditNonComplAccess(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_access                IN    security_pkg.T_PERMISSION
) RETURN BOOLEAN;

PROCEDURE GetNonComplianceDetails(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_upload_cur        OUT    SYS_REFCURSOR,
    out_nc_tag_cur            OUT    SYS_REFCURSOR,
    out_nc_audits_cur        OUT SYS_REFCURSOR
);

PROCEDURE GetNonComplianceDefaults (
    in_internal_audit_type_id        IN    audit_type_non_comp_default.internal_audit_type_id%TYPE,
    in_folder_id                    IN    non_comp_default.non_comp_default_folder_id%TYPE,
    out_nc_defaults_cur                OUT SYS_REFCURSOR,
    out_nc_audit_types_cur            OUT SYS_REFCURSOR,
    out_nc_issues_cur                OUT SYS_REFCURSOR,
    out_nc_tags_cur                    OUT SYS_REFCURSOR
);

PROCEDURE SetNonComplianceDefault (
    in_non_comp_default_id            IN  non_comp_default.non_comp_default_id%TYPE,
    in_folder_id                    IN    non_comp_default.non_comp_default_folder_id%TYPE,
    in_label                        IN  non_comp_default.label%TYPE,
    in_detail                        IN  non_comp_default.detail%TYPE,
    in_non_compliance_type_id        IN  non_comp_default.non_compliance_type_id%TYPE,
    in_root_cause                    IN  non_comp_default.root_cause%TYPE,
    in_suggested_action                IN  non_comp_default.suggested_action%TYPE,
    in_unique_reference                IN  non_comp_default.unique_reference%TYPE,
    out_non_comp_default_id            OUT non_comp_default.non_comp_default_id%TYPE
);

PROCEDURE DeleteNonComplianceDefault (
    in_non_comp_default_id            IN  non_comp_default.non_comp_default_id%TYPE
);

PROCEDURE SetAuditTypeNonCompDefaults (
    in_non_comp_default_id            IN  audit_type_non_comp_default.non_comp_default_id%TYPE,
    in_internal_audit_type_ids        IN  security_pkg.T_SID_IDS
);

PROCEDURE SetNonCompDefaultTags (
    in_non_comp_default_id            IN  audit_type_non_comp_default.non_comp_default_id%TYPE,
    in_tag_ids                        IN  security_pkg.T_SID_IDS
);

PROCEDURE SetNonCompDefaultIssue (
    in_non_comp_default_issue_id    IN  non_comp_default_issue.non_comp_default_issue_id%TYPE,
    in_non_comp_default_id            IN  non_comp_default_issue.non_comp_default_id%TYPE,
    in_label                        IN  non_comp_default_issue.label%TYPE,
    in_description                    IN  non_comp_default_issue.description%TYPE,
    in_due_dtm_relative                IN  non_comp_default_issue.due_dtm_relative%TYPE,
    in_due_dtm_relative_unit        IN  non_comp_default_issue.due_dtm_relative_unit%TYPE,
    out_non_comp_default_issue_id    OUT non_comp_default_issue.non_comp_default_issue_id%TYPE
);

PROCEDURE DeleteRemainingNCDIssues (
    in_non_comp_default_id            IN  non_comp_default_issue.non_comp_default_id%TYPE,
    in_issue_ids_to_keep            IN  security_pkg.T_SID_IDS
);

PROCEDURE CheckNonComplianceAccess (
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_access                IN    security_pkg.T_PERMISSION,
    in_access_denied_msg    IN    VARCHAR2 DEFAULT NULL
);

PROCEDURE UpdateNonCompClosureStatus (
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
);

PROCEDURE SaveNonCompliance_UNSEC(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_region_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_from_non_comp_default_id    IN  non_compliance.from_non_comp_default_id%TYPE,
    in_label                    IN    non_compliance.label%TYPE,
    in_detail                    IN    non_compliance.detail%TYPE,
    in_non_compliance_type_id    IN  non_compliance.non_compliance_type_id%TYPE,
    in_is_closed                IN  non_compliance.is_closed%TYPE,
    in_question_id                IN    non_compliance.question_id%TYPE DEFAULT NULL,
    in_question_option_id        IN    non_compliance.question_option_id%TYPE DEFAULT NULL,
    in_root_cause                IN  non_compliance.root_cause%TYPE DEFAULT NULL,
    in_suggested_action            IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
    in_ia_type_survey_id         IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
    in_lookup_key                IN    non_compliance.lookup_key%TYPE DEFAULT NULL,
    out_non_compliance_id        OUT    non_compliance.non_compliance_id%TYPE
);

PROCEDURE SaveNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_region_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_from_non_comp_default_id    IN  non_compliance.from_non_comp_default_id%TYPE,
    in_label                    IN    non_compliance.label%TYPE,
    in_detail                    IN    non_compliance.detail%TYPE,
    in_non_compliance_type_id    IN  non_compliance.non_compliance_type_id%TYPE,
    in_is_closed                IN  non_compliance.is_closed%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    in_tag_ids                    IN    security_pkg.T_SID_IDS, --not sids but will do
    in_question_id                IN    non_compliance.question_id%TYPE,
    in_question_option_id        IN    non_compliance.question_option_id%TYPE,
    in_root_cause                IN  non_compliance.root_cause%TYPE DEFAULT NULL,
    in_suggested_action            IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
    in_ia_type_survey_id         IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
    in_lookup_key                IN    non_compliance.lookup_key%TYPE DEFAULT NULL,
    out_nc_cur                    OUT    SYS_REFCURSOR,
    out_nc_upload_cur            OUT    SYS_REFCURSOR,
    out_nc_tag_cur                OUT    SYS_REFCURSOR
);

PROCEDURE CloseNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
);

PROCEDURE ReopenNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
);

PROCEDURE DeleteNonCompliance(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_delete_issues        IN    NUMBER
);

PROCEDURE AddNCIssueForDefFlgFindingType(
    in_response_id                IN    quick_survey_response.survey_response_id%TYPE,
    in_issue_type_id            IN    issue_type.issue_type_id%TYPE,
    in_label                    IN  issue.label%TYPE,
    in_description                IN  issue.description%TYPE,
    in_assign_to_role_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_assign_to_user_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_due_dtm                    IN    issue.due_dtm%TYPE                        DEFAULT NULL,
    in_is_urgent                IN    NUMBER                                    DEFAULT NULL,
    in_is_critical                IN    NUMBER                                    DEFAULT 0,
    out_issue_id                OUT issue.issue_id%TYPE
);

PROCEDURE AddNonComplianceIssue(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_label                    IN  issue.label%TYPE,
    in_description                IN  issue.description%TYPE,
    in_assign_to_role_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_assign_to_user_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_due_dtm                    IN    issue.due_dtm%TYPE                        DEFAULT NULL,
    in_is_urgent                IN    NUMBER                                    DEFAULT NULL,
    in_is_critical                IN    NUMBER                                    DEFAULT 0,
    out_issue_id                OUT issue.issue_id%TYPE
);

-- Checks that an issue belongs to the non-compliance
FUNCTION CheckNonComplianceIssue(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_issue_id                    IN    issue.issue_id%TYPE
) RETURN NUMBER;

PROCEDURE SetPostIt(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_postit_id            IN    postit.postit_id%TYPE,
    out_postit_id            OUT postit.postit_id%TYPE
);

PROCEDURE GetPostIts(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR,
    out_cur_files            OUT    security_pkg.T_OUTPUT_CUR
);

FUNCTION GetAuditWithComparisonFromSurv(
    in_survey_sid            IN    quick_survey.survey_sid%TYPE,
    in_survey_response_id    IN    quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER;

FUNCTION GetAuditFromResponseId(
    in_survey_response_id    IN    quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER;

PROCEDURE GetComparisonSubmission(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLatestCampaignSubmission(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOrCreateSurveyResponse(
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_survey_version                IN    quick_survey_response.survey_version%TYPE DEFAULT NULL,
    out_is_new_response                OUT NUMBER,
    out_survey_sid                    OUT security_pkg.T_SID_ID,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
);

PROCEDURE CopyPreviousSubmission(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_survey_response_id    IN    quick_survey_response.survey_response_id%TYPE,
    in_submission_id        IN    quick_survey_response.survey_response_id%TYPE,
    in_audit_type_survey_id    IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
);

PROCEDURE GetOrCreateSummaryResponse(
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    in_survey_version                IN    quick_survey_response.survey_version%TYPE DEFAULT NULL,
    out_is_new_response                OUT NUMBER,
    out_survey_sid                    OUT security_pkg.T_SID_ID,
    out_guid                        OUT quick_survey_response.guid%TYPE,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
);

PROCEDURE GetAuditTypeFlowStates(
    in_internal_audit_type_id    IN internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
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
    in_internal_audit_source_id    IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                        OUT    SYS_REFCURSOR,
    out_expiry_alert_role_cur    OUT SYS_REFCURSOR,
    out_involvement_type_cur    OUT SYS_REFCURSOR,
    out_carry_forward_cur        OUT SYS_REFCURSOR,
    out_closure_type_cur        OUT SYS_REFCURSOR,
    out_survey_type_cur            OUT SYS_REFCURSOR,
    out_iat_flow_states_cur        OUT SYS_REFCURSOR,
    out_iat_reports_cur         OUT SYS_REFCURSOR
);

PROCEDURE FilterInternalAuditTypes(
    in_query                    VARCHAR2,
    in_internal_audit_source_id    internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteInternalAuditTypeGroup(
    in_ia_type_group_id            IN    internal_audit_type_group.internal_audit_type_group_id%TYPE
);

PROCEDURE DeleteInternalAuditType(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
);

FUNCTION AreAllAuditsInTrash(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
) RETURN BOOLEAN;

FUNCTION AreAllAuditsInTrash_SQL(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
) RETURN NUMBER;

PROCEDURE SaveInternalAuditTypeGroup(
    in_ia_type_group_id                IN  internal_audit_type_group.internal_audit_type_group_id%TYPE,
    in_label                        IN    internal_audit_type_group.label%TYPE,
    in_lookup_key                    IN    internal_audit_type_group.lookup_key%TYPE, -- NULL will preserve the existing lookup key on update or generate one on create
    in_applies_to_regions            IN    internal_audit_type_group.applies_to_regions%TYPE,
    in_applies_to_users                IN    internal_audit_type_group.applies_to_users%TYPE,
    in_use_user_primary_region        IN    internal_audit_type_group.use_user_primary_region%TYPE,
    in_ref_prefix                    IN    internal_audit_type_group.internal_audit_ref_prefix%TYPE,
    in_issue_type_id                IN    internal_audit_type_group.issue_type_id%TYPE,
    in_audit_singular_label            IN    internal_audit_type_group.audit_singular_label%TYPE,
    in_audit_plural_label            IN    internal_audit_type_group.audit_plural_label%TYPE,
    in_auditee_user_label            IN    internal_audit_type_group.auditee_user_label%TYPE,
    in_auditor_user_label            IN    internal_audit_type_group.auditor_user_label%TYPE,
    in_auditor_name_label            IN    internal_audit_type_group.auditor_name_label%TYPE,
    in_block_css_class                IN    internal_audit_type_group.block_css_class%TYPE,
    in_applies_to_permits            IN    internal_audit_type_group.applies_to_permits%TYPE,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE MakeInternalAuditTypeGroupMenu(
    in_ia_type_group_id                IN  internal_audit_type_group.internal_audit_type_group_id%TYPE,
    in_include_non_compliances        IN    NUMBER,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveInternalAuditType(
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    in_label                        IN    internal_audit_type.label%TYPE,
    in_every_n_months                IN    internal_audit_type.every_n_months%TYPE,
    in_auditor_role_sid                IN    internal_audit_type.auditor_role_sid%TYPE,
    in_audit_contact_role_sid        IN    internal_audit_type.audit_contact_role_sid%TYPE,
    in_default_survey_sid            IN    internal_audit_type.default_survey_sid%TYPE,
    in_default_auditor_org            IN    internal_audit_type.default_auditor_org%TYPE,
    in_override_issue_dtm            IN    internal_audit_type.override_issue_dtm%TYPE,
    in_assign_issues_to_role        IN    internal_audit_type.assign_issues_to_role%TYPE,
    in_involve_auditor_in_issues    IN    internal_audit_type.involve_auditor_in_issues%TYPE,
    in_auditor_can_take_ownership    IN  internal_audit_type.auditor_can_take_ownership%TYPE,
    in_add_nc_per_question            IN    internal_audit_type.add_nc_per_question%TYPE,
    in_nc_audit_child_region        IN    internal_audit_type.nc_audit_child_region%TYPE,
    in_flow_sid                        IN  internal_audit_type.flow_sid%TYPE,
    in_internal_audit_source_id        IN  internal_audit_type.internal_audit_type_source_id%TYPE,
    in_summary_survey_sid            IN  internal_audit_type.summary_survey_sid%TYPE,
    in_send_auditor_expiry_alerts    IN  internal_audit_type.send_auditor_expiry_alerts%TYPE,
    in_expiry_alert_roles            IN  security_pkg.T_SID_IDS,
    in_validity_months                IN    internal_audit_type.validity_months%TYPE,
    in_audit_c_role_or_group_sid    IN  internal_audit_type.audit_coord_role_or_group_sid%TYPE DEFAULT NULL,
    in_tab_sid                        IN  internal_audit_type.tab_sid%TYPE DEFAULT NULL,
    in_form_path                    IN  internal_audit_type.form_path%TYPE DEFAULT NULL,
    in_form_sid                        IN  internal_audit_type.form_sid%TYPE DEFAULT NULL,
    in_ia_type_group_id                IN  internal_audit_type.internal_audit_type_group_id%TYPE DEFAULT NULL,
    in_nc_score_type_id                IN    internal_audit_type.nc_score_type_id%TYPE DEFAULT NULL,
    in_active                         IN  internal_audit_type.active%TYPE DEFAULT 1,
    in_show_primary_survey_in_hdr    IN    internal_audit_type.show_primary_survey_in_header%TYPE DEFAULT 1,
    in_use_legacy_closed_def        IN    internal_audit_type.use_legacy_closed_definition%TYPE DEFAULT 0,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTemplate(
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    in_internal_audit_type_rep_id     IN  internal_audit_type_report.internal_audit_type_report_id%TYPE,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateMappedIndicators (
    in_audit_type_id            IN    internal_audit_type.internal_audit_type_id%TYPE,
    in_include_tot_clsd            IN    NUMBER := 0
);

PROCEDURE CreateMappedIndicators (
    in_audit_type_id                internal_audit_type.internal_audit_type_id%TYPE,
    in_lookup_key                    internal_audit_type.lookup_key%TYPE,
    in_folder_ind_sid                security_pkg.T_SID_ID,
    in_measure_sid                    security_pkg.T_SID_ID
);

PROCEDURE GetIndicatorValues (
    in_aggregate_ind_group_id    IN    aggregate_ind_group.aggregate_ind_group_id%TYPE,
    in_start_dtm                IN    DATE,
    in_end_dtm                    IN    DATE,
    out_cur                        OUT security_pkg.T_OUTPUT_CUR
);
/*
PROCEDURE GetFlowIndicatorValues(
    in_aggregate_ind_group_id    IN    aggregate_ind_group.aggregate_ind_group_id%TYPE,
    in_start_dtm                IN    DATE,
    in_end_dtm                    IN    DATE,
    out_cur                        OUT security_pkg.T_OUTPUT_CUR
);
*/
FUNCTION GetIssueAuditUrl(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID
) RETURN VARCHAR2;

FUNCTION GetIssueAuditUrlWithNonCompId(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE
) RETURN VARCHAR2;

PROCEDURE TriggerAuditJobs;

PROCEDURE GetClosureTypes(
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteClosureType(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE SaveClosureType(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    in_label                    IN    audit_closure_type.label%TYPE,
    in_is_failure                IN    audit_closure_type.is_failure%TYPE,
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetClosureTypesByAuditType(
    in_internal_audit_type_id    IN    audit_type_closure_type.internal_audit_type_id%TYPE,
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAuditTypeClosureType(
    in_internal_audit_type_id    IN    audit_type_closure_type.internal_audit_type_id%TYPE,
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE SaveAuditTypeClosureType(
    in_internal_audit_type_id    IN    audit_type_closure_type.internal_audit_type_id%TYPE,
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    in_re_audit_due_after        IN    audit_type_closure_type.re_audit_due_after%TYPE,
    in_re_audit_due_after_type    IN    audit_type_closure_type.re_audit_due_after_type%TYPE,
    in_reminder_offset_days        IN    audit_type_closure_type.reminder_offset_days%TYPE,
    in_reportable_for_months    IN    audit_type_closure_type.reportable_for_months%TYPE,
    in_manual_expiry_date        IN    audit_type_closure_type.manual_expiry_date%TYPE,
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE ChangeClosureTypeIcon(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    in_cache_key                IN    aspen2.filecache.cache_key%type
);

PROCEDURE GetClosureTypeIcon(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetClosureStatus(
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE SetOvwValidityDtm (
    in_internal_audit_sid         IN  security_pkg.T_SID_ID,
    in_ovw_validity_dtm            IN  DATE
);

PROCEDURE GetReminderAlerts(
    out_cur                            OUT    SYS_REFCURSOR
);

PROCEDURE GetOverdueAlerts(
    out_cur                            OUT    SYS_REFCURSOR
);

PROCEDURE RecordReminderSent(
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_user_sid                    IN    security_pkg.T_SID_ID
);

PROCEDURE RecordOverdueSent(
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_user_sid                    IN    security_pkg.T_SID_ID
);

PROCEDURE GetNonCompliancesRprt(
    in_region_sid                IN    security_pkg.T_SID_ID,
    in_start_dtm                IN    DATE,
    in_end_dtm                    IN    DATE,
    in_tpl_region_type_id        IN    tpl_region_type.tpl_region_type_id%TYPE,
    in_tag_id                    IN    tag.tag_id%TYPE,
    out_cur_ncs                    OUT    SYS_REFCURSOR,
    out_cur_tags                OUT    SYS_REFCURSOR
);

PROCEDURE FixUpFiles(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
);

FUNCTION CacheKeysArrayToTable(
    in_strings            IN    T_CACHE_KEYS
) RETURN security.T_VARCHAR2_TABLE;

PROCEDURE GetNonComplianceFile(
    in_noncompliance_file_id    IN    non_compliance_file.non_compliance_file_id%TYPE,
    in_sha1                IN    VARCHAR2,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFlowTransitions(
    in_audit_sid        IN  security_pkg.T_SID_ID,
    out_cur             OUT SYS_REFCURSOR
);

FUNCTION GetFlowRegionSids(
    in_flow_item_id        IN    csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

PROCEDURE GenerateInvolmTypeAlertEntries(
    in_flow_item_id                 IN flow_item.flow_item_id%TYPE,
    in_set_by_user_sid                IN security_pkg.T_SID_ID,
    in_flow_transition_alert_id        IN flow_transition_alert.flow_transition_alert_id%TYPE,
    in_flow_involvement_type_id        IN flow_involvement_type.flow_involvement_type_id%TYPE,
    in_flow_state_log_id             IN flow_state_log.flow_state_log_id%TYPE,
    in_subject_override                IN flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
    in_body_override                IN flow_item_generated_alert.body_override%TYPE DEFAULT NULL
);

PROCEDURE GetFlowAlerts(
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR,
    out_refs                    OUT    security_pkg.T_OUTPUT_CUR,
    out_tags                    OUT    security_pkg.T_OUTPUT_CUR,
    out_scores                    OUT    security_pkg.T_OUTPUT_CUR,
    out_reports                 OUT    security_pkg.T_OUTPUT_CUR,
    out_audit_tags                OUT    security_pkg.T_OUTPUT_CUR,
    out_primary_purchasers        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForAuditPaged(
    in_audit_sid        IN    security_pkg.T_SID_ID,
    in_order_by            IN    VARCHAR2, -- redundant but needed for quick list output
    in_start_row        IN    NUMBER,
    in_page_size        IN    NUMBER,
    in_start_date        IN    DATE,
    in_end_date            IN    DATE,
    out_total            OUT    NUMBER,
    out_cur                OUT    SYS_REFCURSOR
);

PROCEDURE GetAuditLogForAudit(
    in_audit_sid        IN    security_pkg.T_SID_ID,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditFlowRoleUsers(
    in_audit_sid                    IN    security_pkg.T_SID_ID,
    out_role_cur                    OUT    security_pkg.T_OUTPUT_CUR,
    out_user_cur                    OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditFlowGroupUsers(
    in_audit_sid                    IN    security_pkg.T_SID_ID,
    out_group_cur                    OUT security_pkg.T_OUTPUT_CUR,
    out_user_cur                    OUT    security_pkg.T_OUTPUT_CUR
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
    in_audit_sid            IN  security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLockedAuditSurveyTags (
    in_audit_sid            IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetLockedAuditSurveyTags (
    in_audit_sid            IN    security_pkg.T_SID_ID,
    in_survey_sid            IN    security_pkg.T_SID_ID,
    in_survey_version        IN    quick_survey_response.survey_version%TYPE DEFAULT NULL,
    in_tag_ids                 IN    security_pkg.T_SID_IDS
);

PROCEDURE GetNonOverridenAuditRegionTags (
    in_audit_sid            IN  security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditTabs (
    in_internal_audit_type_id        IN  internal_audit_type.internal_audit_type_id%TYPE,
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    out_cur                            OUT SYS_REFCURSOR
);

PROCEDURE SetAuditTab (
    in_internal_audit_type_id        IN  audit_type_tab.internal_audit_type_id%TYPE,
    in_js_class                        IN  csr.plugin.js_class%TYPE,
    in_form_path                    IN  csr.plugin.form_path%TYPE,
    in_group_key                    IN  csr.plugin.group_key%TYPE,
    in_pos                            IN  audit_type_tab.pos%TYPE,
    in_tab_label                    IN  audit_type_tab.tab_label%TYPE,
    in_flow_capability_id            IN    audit_type_tab.flow_capability_id%TYPE DEFAULT NULL
);

PROCEDURE SetAuditTab(
    in_internal_audit_type_id        IN  audit_type_tab.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_tab.plugin_id%TYPE,
    in_pos                            IN  audit_type_tab.pos%TYPE,
    in_tab_label                    IN  audit_type_tab.tab_label%TYPE,
    in_flow_capability_id            IN    audit_type_tab.flow_capability_id%TYPE DEFAULT NULL,
    out_cur                            OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveAuditTab(
    in_internal_audit_type_id        IN  audit_type_tab.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_tab.plugin_id%TYPE
);

PROCEDURE GetAuditHeaders (
    in_internal_audit_type_id        IN  internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                            OUT SYS_REFCURSOR
);

PROCEDURE SetAuditHeader(
    in_internal_audit_type_id        IN  audit_type_header.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_header.plugin_id%TYPE,
    in_pos                            IN  audit_type_header.pos%TYPE,
    out_cur                            OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveAuditHeader(
    in_internal_audit_type_id        IN  audit_type_header.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_header.plugin_id%TYPE
);

PROCEDURE GetAuditorRegions(
    in_search_phrase                IN    VARCHAR2,
    in_modified_since_dtm            IN    audit_log.audit_date%TYPE,
    in_show_inactive                IN    NUMBER,
    out_cur                            OUT SYS_REFCURSOR
);

PROCEDURE GetResponseToAudit (
    in_survey_response_id            IN    quick_survey_response.survey_response_id%TYPE,
    out_cur                            OUT SYS_REFCURSOR
);

PROCEDURE GetAuditsWithAllIssuesClosed(
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordAuditAllIssuesClosed(
    in_app_sid                        IN  audit_iss_all_closed_alert.app_sid%TYPE,
    in_internal_audit_sid            IN    audit_iss_all_closed_alert.internal_audit_sid%TYPE,
    in_user_sid                        IN    audit_iss_all_closed_alert.CSR_USER_SID%TYPE
);

PROCEDURE GetNonComplianceTypes (
    in_internal_audit_type_id        IN  non_comp_type_audit_type.internal_audit_type_id%TYPE DEFAULT NULL,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR,
    out_audit_type_cur                OUT    security_pkg.T_OUTPUT_CUR,
    out_repeat_audit_type_cur        OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetNonComplianceType (
    in_non_compliance_type_id            IN  non_compliance_type.non_compliance_type_id%TYPE,
    in_label                            IN  non_compliance_type.label%TYPE,
    in_lookup_key                        IN  non_compliance_type.lookup_key%TYPE,
    in_position                            IN  non_compliance_type.position%TYPE,
    in_colour_when_open                    IN  non_compliance_type.colour_when_open%TYPE,
    in_colour_when_closed                IN  non_compliance_type.colour_when_closed%TYPE,
    in_can_have_actions                    IN  non_compliance_type.can_have_actions%TYPE,
    in_closure_behaviour_id                IN  non_compliance_type.closure_behaviour_id%TYPE,
    in_score                            IN    non_compliance_type.score%TYPE DEFAULT NULL,
    in_repeat_score                        IN    non_compliance_type.repeat_score%TYPE DEFAULT NULL,
    in_root_cause_enabled                IN    non_compliance_type.root_cause_enabled%TYPE DEFAULT 0,
    in_suggested_action_enabled            IN    non_compliance_type.suggested_action_enabled%TYPE DEFAULT 0,
    in_match_repeats_by_carry_fwd        IN    non_compliance_type.match_repeats_by_carry_fwd%TYPE DEFAULT 0,        
    in_match_repeats_by_dflt_ncs        IN    non_compliance_type.match_repeats_by_default_ncs%TYPE DEFAULT 0,    
    in_match_repeats_by_surveys            IN    non_compliance_type.match_repeats_by_surveys%TYPE DEFAULT 0,
    in_find_repeats_in_unit                IN    non_compliance_type.find_repeats_in_unit%TYPE DEFAULT NCT_RPT_MATCH_UNIT_NONE,
    in_find_repeats_in_qty                IN    non_compliance_type.find_repeats_in_qty%TYPE DEFAULT NULL,
    in_carry_fwd_repeat_type            IN    non_compliance_type.carry_fwd_repeat_type%TYPE DEFAULT NCT_CARRY_FWD_RPT_TYPE_NORMAL,
    in_is_default_survey_finding        IN    non_compliance_type.is_default_survey_finding%TYPE DEFAULT 0,
    in_is_flow_capability_enabled        IN    NUMBER    DEFAULT 0,
    in_repeat_audit_type_ids            IN    security_pkg.T_SID_IDS,
    out_non_compliance_type_id            OUT    non_compliance_type.non_compliance_type_id%TYPE
);

PROCEDURE DeleteNonComplianceType (
    in_non_compliance_type_id        IN  non_compliance_type.non_compliance_type_id%TYPE
);

PROCEDURE SetAuditTypeNonCompType (
    in_internal_audit_type_id    IN  non_comp_type_audit_type.internal_audit_type_id%TYPE,
    in_non_compliance_type_id    IN  non_comp_type_audit_type.non_compliance_type_id%TYPE
);

PROCEDURE DeleteAuditTypeNonCompType (
    in_internal_audit_type_id    IN  non_comp_type_audit_type.internal_audit_type_id%TYPE,
    in_non_compliance_type_id    IN  non_comp_type_audit_type.non_compliance_type_id%TYPE
);

FUNCTION GetNonComplianceTypeId (
    in_nc_type_label            IN    NVARCHAR2,
    in_audit_sid                IN    security.security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE RecalculateAuditNCScore(
    in_internal_audit_sid            IN  security_pkg.T_SID_ID
);

PROCEDURE RecalculateAuditNCScoreThrsh(
    in_internal_audit_sid            IN  security_pkg.T_SID_ID
);

PROCEDURE IsAuditDeletable(
    in_internal_audit_sid    IN    internal_audit.internal_audit_sid%TYPE,
    out_is_deletable        OUT NUMBER
);

PROCEDURE OverwriteNCScoreThreshold(
    in_internal_audit_sid    IN    internal_audit.internal_audit_sid%TYPE,
    in_score_threshold_id    IN    score_threshold.score_threshold_id%TYPE
);

PROCEDURE GetIndSidByLookupKey (
    in_lookup_key                IN    ind.lookup_key%TYPE,
    out_ind_sid                    OUT    ind.ind_sid%TYPE
);

PROCEDURE GetOrCreateAggregateInd(
    in_parent                IN    ind.parent_sid%TYPE,
    in_name                    IN    ind.name%TYPE,
    in_desc                    IN    ind_description.description%TYPE,
    in_lookup_key            IN    ind.lookup_key%TYPE,
    in_divisibility            IN    ind.divisibility%TYPE,
    in_measure_sid            IN    ind.measure_sid%TYPE,
    in_info_definition        IN  VARCHAR2,
    out_ind_sid                OUT    ind.ind_sid%TYPE
);

FUNCTION GetAuditFlowStateIndName (
    in_flow_state_id                IN    flow_state.flow_state_id%TYPE,
    in_flow_st_audit_ind_type_id    IN    flow_state_audit_ind_type.flow_state_audit_ind_type_id%TYPE
) RETURN VARCHAR2;

PROCEDURE SetAuditFlowStateInd(
    in_flow_state_id                IN    flow_state.flow_state_id%TYPE,
    in_ind_sid                        IN    ind.ind_sid%TYPE,
    in_flow_state_type_ind_id        IN    flow_state_audit_ind_type.flow_state_audit_ind_type_id%TYPE,
    in_internal_audit_type_id        IN    internal_audit.internal_audit_type_id%TYPE
);

FUNCTION FlowItemRecordExists(
    in_flow_item_id        IN    csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetAvailableFlowInvTypes (
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditTypeFlowInvTypes (
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvolvedUsers (
    in_internal_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveAuditTypeInvType(
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_flow_involvement_type_id        IN     audit_type_flow_inv_type.flow_involvement_type_id%TYPE,
    in_internal_audit_type_id        IN    audit_type_flow_inv_type.internal_audit_type_id%TYPE,
    in_users_role_or_group_sid        IN    audit_type_flow_inv_type.users_role_or_group_sid%TYPE,
    in_min_users                    IN    audit_type_flow_inv_type.min_users%TYPE,
    in_max_users                    IN    audit_type_flow_inv_type.max_users%TYPE,
    out_adt_type_flow_inv_type_id    OUT    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE
);

PROCEDURE DeleteAuditTypeFlowInvType (
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE
);

PROCEDURE SetAuditInvolvedUsers (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_user_sids                    IN    security.security_pkg.T_SID_IDS
);

PROCEDURE SetAuditInvolvedUsers (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_flow_involvement_type_id        IN    flow_involvement_type.flow_involvement_type_id%TYPE,
    in_user_sids                    IN    security.security_pkg.T_SID_IDS
);

PROCEDURE UNSEC_SetAuditInvolvedUsers (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_flow_involvement_type_id        IN    flow_involvement_type.flow_involvement_type_id%TYPE,
    in_user_sids                    IN    security.security_pkg.T_SID_IDS
);

PROCEDURE CopySurveyAnswersToSummary (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE
);

FUNCTION MultipleSurveysEnabled
RETURN BOOLEAN;

PROCEDURE GetAuditTypeSurveyGroups (
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAuditTypeSurveyGroup (
    in_ia_type_survey_group_id        IN    ia_type_survey_group.ia_type_survey_group_id%TYPE,
    in_label                        IN    ia_type_survey_group.label%TYPE,
    in_lookup_key                    IN    ia_type_survey_group.lookup_key%TYPE,
    out_ia_type_survey_group_id        OUT    ia_type_survey_group.ia_type_survey_group_id%TYPE
);

PROCEDURE DeleteAuditTypeSurveyGroup (
    in_ia_type_survey_group_id        IN    ia_type_survey_group.ia_type_survey_group_id%TYPE
);

PROCEDURE GetAuditTypeSurveys(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDefaultSurvey(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_default_survey_sid            IN    internal_audit_type_survey.default_survey_sid%TYPE
);

PROCEDURE SetAuditTypeSurvey(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_ia_type_survey_id            IN    internal_audit_type_survey.internal_audit_type_survey_id%TYPE,
    in_active                        IN    internal_audit_type_survey.active%TYPE,
    in_label                        IN    internal_audit_type_survey.label%TYPE,
    in_ia_type_survey_group_id        IN    internal_audit_type_survey.ia_type_survey_group_id%TYPE,
    in_default_survey_sid            IN    internal_audit_type_survey.default_survey_sid%TYPE,
    in_mandatory                    IN    internal_audit_type_survey.mandatory%TYPE,
    in_survey_fixed                    IN    internal_audit_type_survey.survey_fixed%TYPE,
    in_survey_group_key                IN    internal_audit_type_survey.survey_group_key%TYPE,
    out_ia_type_survey_id            OUT    internal_audit_type_survey.internal_audit_type_survey_id%TYPE
);

PROCEDURE DeleteAuditTypeSurveys(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_keep_ia_type_survey_ids        IN    security_pkg.T_SID_IDS
);

PROCEDURE GetAuditTypeSurveyDefaultPerms(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_region_sid                    IN    security_pkg.T_SID_ID,
    in_auditee_user_sid                IN    security_pkg.T_SID_ID,
    in_auditor_user_sid                IN    security_pkg.T_SID_ID,
    in_auditor_company_sid            IN    security_pkg.T_SID_ID,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

FUNCTION SQL_HasSurveyAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_ia_type_survey_id        IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_change_survey            IN    NUMBER
) RETURN BINARY_INTEGER;

FUNCTION HasSurveyAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_ia_type_survey_id        IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_change_survey            IN    NUMBER
) RETURN BOOLEAN;

PROCEDURE GetAuditSurveys(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAuditSurvey(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_survey_sid                    IN    internal_audit_survey.survey_sid%TYPE
);

PROCEDURE DeleteAuditSurvey(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE
);

PROCEDURE GetFixedSurveys(
    in_internal_audit_type_id    IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
    out_cur                        OUT SYS_REFCURSOR
);

PROCEDURE GetNonComplianceTypes(
    out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetIATExpiryAlertRoles(
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR    
);

PROCEDURE GetIATInvolmentTypes(
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR    
);

PROCEDURE SetAuditTags (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_tag_ids                        IN    security.security_pkg.T_SID_IDS,
    in_copy_locked_tags_from_sid    IN    security.security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE UNSEC_SyncRegionsForUser(
    in_user_sid        IN    security_pkg.T_SID_ID
);

PROCEDURE FilterUsersByRoleGroupRegion(
    in_group_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,    
    in_role_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,    
    in_region_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,    
    in_filter_name            IN    csr_user.full_name%TYPE DEFAULT NULL,
    in_auditor_company_sid    IN    security_pkg.T_SID_ID DEFAULT NULL,
    out_cur                    OUT    SYS_REFCURSOR,
    out_total_num_users        OUT SYS_REFCURSOR
);

FUNCTION GetPrimarySurveyScoreTypeIds 
RETURN security.T_SID_TABLE;

PROCEDURE GetPrimarySurveyScoreTypeIds(
    out_cur         OUT    SYS_REFCURSOR
);

PROCEDURE GetSurveyGroupScoreTypes(
    out_cur         OUT    SYS_REFCURSOR
);

PROCEDURE GetInternalAuditTypeReports(
    in_audit_type_id     IN  internal_audit_type.internal_audit_type_id%TYPE,
    out_cur             OUT SYS_REFCURSOR
);

PROCEDURE SetAuditTypeReports(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_keep_ia_type_report_ids        IN    security_pkg.T_SID_IDS
);

PROCEDURE GetPublicReport (
    in_guid                            IN    internal_audit_report_guid.guid%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePublicReport (
    in_internal_audit_type_rpt_id    IN    internal_audit_type_report.internal_audit_type_report_id%TYPE,
    in_filename                     IN  internal_audit_report_guid.filename%TYPE,
    in_doc_type                     IN  internal_audit_report_guid.doc_type%TYPE,
    in_document                     IN  internal_audit_report_guid.document%TYPE,
    in_guid                         IN  internal_audit_report_guid.guid%TYPE
);

PROCEDURE GetInternalAuditReportGroups (
    out_cur             OUT  SYS_REFCURSOR
);

PROCEDURE SaveInternalAuditTypeReport (
    in_audit_type_report_id         IN  internal_audit_type_report.internal_audit_type_report_id%TYPE,
    in_internal_audit_type_id         IN  internal_audit.internal_audit_sid%TYPE,
    in_label                         IN  internal_audit_type_report.label%TYPE,
    in_cache_key                     IN  aspen2.filecache.cache_key%type,
    in_ia_type_report_group_id         IN  internal_audit_type_report.ia_type_report_group_id%TYPE,
    in_use_guid                        IN    internal_audit_type_report.use_merge_field_guid%TYPE,
    in_guid_expiration                IN    internal_audit_type_report.guid_expiration_days%TYPE DEFAULT NULL,
    out_internal_audit_report_id     OUT internal_audit_type_report.internal_audit_type_report_id%TYPE
);

PROCEDURE SaveIATypeReportGroup (
    in_ia_type_report_group_id         IN  ia_type_report_group.ia_type_report_group_id%TYPE,
    in_label                         IN  ia_type_survey_group.label%TYPE,
    out_ia_type_report_group_id     OUT ia_type_report_group.ia_type_report_group_id%TYPE
);

PROCEDURE ProcessExpiredPublicReports;

PROCEDURE GetAuditScores(
    in_internal_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_internal_audit_type_id        IN    internal_audit.internal_audit_type_id%TYPE,
    in_flow_item_id                    IN    internal_audit.flow_item_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAuditScore(
    in_internal_audit_sid            IN    internal_audit_score.internal_audit_sid%TYPE,
    in_score_type_id                IN    internal_audit_score.score_type_id%TYPE,
    in_score                        IN    internal_audit_score.score%TYPE,
    in_score_threshold_id            IN    internal_audit_score.score_threshold_id%TYPE,
    in_override_system_threshold    IN    NUMBER DEFAULT 0
);

PROCEDURE UNSEC_SetAuditScore(
    in_internal_audit_sid            IN    internal_audit_score.internal_audit_sid%TYPE,
    in_score_type_id                IN    internal_audit_score.score_type_id%TYPE,
    in_score                        IN    internal_audit_score.score%TYPE,
    in_score_threshold_id            IN    internal_audit_score.score_threshold_id%TYPE,
    in_override_system_threshold    IN    NUMBER
);

PROCEDURE GetAuditsByInternalRef (
    in_internal_audit_ref        IN internal_audit.internal_audit_ref%TYPE,
    out_audits_cur                OUT    SYS_REFCURSOR
);

PROCEDURE GetAuditsByExternalAuditRef (
    in_external_audit_ref        IN internal_audit.external_audit_ref%TYPE,
    out_audits_cur                OUT    SYS_REFCURSOR
);

PROCEDURE GetAuditsByExternalParentRef (
    in_external_parent_ref        IN internal_audit.external_parent_ref%TYPE,
    out_audits_cur                OUT    SYS_REFCURSOR
);

PROCEDURE GetAuditsByInternalAuditTypeAndCompanySid (
    in_internal_audit_type_id        IN internal_audit.internal_audit_type_id%TYPE,
    in_company_sid                    IN security_pkg.T_SID_ID,
    out_audits_cur                    OUT    SYS_REFCURSOR
);

FUNCTION GetAuditTypeByLookup (
    in_audit_type_lookup            IN  internal_audit_type.lookup_key%TYPE
) RETURN NUMBER;

PROCEDURE DeleteAuditsOfTypeFromRegion (
    in_act_sid                        IN  security_pkg.T_ACT_ID,
    in_audit_type_lookup            IN  internal_audit_type.lookup_key%TYPE,
    in_region_sid                    IN    internal_audit.region_sid%TYPE
);

END temp_audit_pkg;
/

sho err;

create or replace PACKAGE BODY csr.temp_audit_pkg AS

PROC_NOT_FOUND                EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE INTERNAL_CallHelperPkg(
    in_procedure_name    IN    VARCHAR2,
    in_audit_sid        IN    security_pkg.T_SID_Id,
    in_object_id        IN  security_pkg.T_SID_Id
)
AS
    v_helper_pkg        customer.audit_helper_pkg%TYPE;
BEGIN
    -- call helper proc if there is one, to setup custom forms
    BEGIN
        SELECT audit_helper_pkg
          INTO v_helper_pkg
          FROM customer
         WHERE app_sid = security_pkg.GetApp;
    EXCEPTION
        WHEN no_data_found THEN
            null;
    END;
    
    IF v_helper_pkg IS NOT NULL THEN
        BEGIN
            EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1, :2);end;'
                USING in_audit_sid, in_object_id;
        EXCEPTION
            WHEN PROC_NOT_FOUND THEN
                NULL; -- it is acceptable that it is not supported
        END;
    END IF;
END;

PROCEDURE INTERNAL_CallHelperPkg(
    in_procedure_name    IN    VARCHAR2,
    in_audit_sid        IN    security_pkg.T_SID_Id
)
AS
    v_helper_pkg        customer.audit_helper_pkg%TYPE;
BEGIN
    -- call helper proc if there is one, to setup custom forms
    BEGIN
        SELECT audit_helper_pkg
          INTO v_helper_pkg
          FROM customer
         WHERE app_sid = security_pkg.GetApp;
    EXCEPTION
        WHEN no_data_found THEN
            null;
    END;

    IF v_helper_pkg IS NOT NULL THEN
        BEGIN
            EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1);end;'
                USING in_audit_sid;
        EXCEPTION
            WHEN PROC_NOT_FOUND THEN
                NULL; -- it is acceptable that it is not supported
        END;
    END IF;
END;

PROCEDURE SetAuditRef (
    in_audit_sid    IN    security_pkg.T_SID_ID,
    in_audit_ref    IN    internal_audit.internal_audit_ref%TYPE
)
AS
BEGIN
    UPDATE internal_audit
       SET internal_audit_ref = in_audit_ref
     WHERE internal_audit_sid = in_audit_sid;
END;

PROCEDURE SetExternalRef (
    in_audit_sid            IN    security_pkg.T_SID_ID,
    in_external_audit_ref    IN    internal_audit.external_audit_ref%TYPE,
    in_external_parent_ref    IN    internal_audit.external_parent_ref%TYPE,
    in_external_url            IN    internal_audit.external_url%TYPE
)
AS
BEGIN
    UPDATE internal_audit
       SET external_audit_ref = in_external_audit_ref,
           external_parent_ref = in_external_parent_ref,
           external_url = in_external_url
     WHERE internal_audit_sid = in_audit_sid;
END;

PROCEDURE INTERNAL_CreateRefID_Audit(
    in_audit_sid        IN    security_pkg.T_SID_ID
)
AS
    v_audit_ref_helper_func        csr.internal_audit_type.internal_audit_ref_helper_func%TYPE;
    v_generated_number            NUMBER;
BEGIN
    -- Get the helper function to generate id
    SELECT iat.internal_audit_ref_helper_func
      INTO v_audit_ref_helper_func
      FROM internal_audit ia
      JOIN internal_audit_type iat
        ON iat.internal_audit_type_id = ia.internal_audit_type_id AND iat.app_sid = ia.app_sid
     WHERE ia.app_sid = security.security_pkg.GetApp
       AND ia.internal_audit_sid = in_audit_sid;

    IF v_audit_ref_helper_func IS NOT NULL THEN
        IF aspen2.utils_pkg.INTERNAL_FunctionExists(v_audit_ref_helper_func) THEN

            EXECUTE IMMEDIATE 'BEGIN :1 := ' || v_audit_ref_helper_func || '; END;' USING IN OUT v_generated_number;

            UPDATE csr.internal_audit
               SET internal_audit_ref = v_generated_number
             WHERE app_sid = security.security_pkg.GetApp
               AND internal_audit_sid = in_audit_sid;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Defined helper function could not be found: ' ||v_audit_ref_helper_func || ' (see csr.internal_audit_type.internal_audit_ref_helper_func)' );
        END IF;
    END IF;

END;

PROCEDURE INTERNAL_CreateRefID_Non_Comp(
    in_non_compliance_id        IN    csr.non_compliance.non_compliance_id%TYPE
)
AS
    v_non_comp_ref_helper_func        csr.non_compliance_type.inter_non_comp_ref_helper_func%TYPE;
    v_generated_number            NUMBER;
BEGIN
    -- Get the helper function to generate id
    SELECT nct.inter_non_comp_ref_helper_func
      INTO v_non_comp_ref_helper_func
      FROM non_compliance nc
      LEFT JOIN non_compliance_type nct
        ON nct.non_compliance_type_id = nc.non_compliance_type_id AND nct.app_sid = nc.app_sid
     WHERE nc.app_sid = security.security_pkg.GetApp
       AND nc.non_compliance_id = in_non_compliance_id;

    IF v_non_comp_ref_helper_func IS NOT NULL THEN
        IF aspen2.utils_pkg.INTERNAL_FunctionExists(v_non_comp_ref_helper_func) THEN

            EXECUTE IMMEDIATE 'BEGIN :1 := ' || v_non_comp_ref_helper_func || '; END;' USING IN OUT v_generated_number;

            UPDATE csr.non_compliance
               SET non_compliance_ref = v_generated_number
             WHERE app_sid = security.security_pkg.GetApp
               AND non_compliance_id = in_non_compliance_id;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Defined helper function could not be found: ' ||v_non_comp_ref_helper_func || ' (see csr.non_compliance_type.inter_non_comp_ref_helper_func)' );
        END IF;
    END IF;
END;

-- Returns a table collection of Audit_Sids that the logged in user has access to
FUNCTION GetAuditsForUserAsTable
RETURN security.T_SID_TABLE AS
    v_act_id            security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
    v_audits_sid        security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_table                security.T_SID_TABLE;
    v_trash_sid            security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Trash');
    v_ownership_rights    NUMBER := security_pkg.SQL_IsAccessAllowedSID(v_act_id, v_audits_sid, security.security_pkg.PERMISSION_TAKE_OWNERSHIP);
BEGIN

    SELECT DISTINCT audit_id
      BULK COLLECT INTO v_table
      FROM(
        SELECT t.sid_id audit_id
          FROM TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security_pkg.PERMISSION_READ)) t
          JOIN csr.internal_audit ia on ia.internal_audit_sid = t.sid_id
         WHERE ia.flow_item_id IS NULL
         UNION
        SELECT ia.internal_audit_sid audit_id
          FROM csr.internal_audit ia
          JOIN csr.internal_audit_type iat
            ON ia.internal_audit_type_id = iat.internal_audit_type_id
          JOIN csr.region_role_member rrm
            ON (iat.auditor_role_sid = rrm.role_sid
            OR iat.audit_contact_role_sid = rrm.role_sid)
           AND rrm.region_sid = ia.region_sid
          JOIN security.securable_object so ON ia.internal_audit_sid = so.sid_id
         WHERE rrm.user_sid = security.security_pkg.GetSid
           AND so.parent_sid_id != v_trash_sid
           AND ia.flow_item_id IS NULL
           AND ia.deleted = 0
         UNION
        SELECT ia.internal_audit_sid
          FROM internal_audit ia
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
         WHERE ia.deleted = 0
           AND (((SYS_CONTEXT('SECURITY', 'SID') = ia.auditor_user_sid
            OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover))
           AND fi.current_state_id IN (
                SELECT flow_state_id
                  FROM flow_state_involvement fsi
                 WHERE fsi.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDITOR
            ))
            OR (SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') = ia.auditor_company_sid
           AND fi.current_state_id IN (
                SELECT flow_state_id
                  FROM flow_state_involvement fsi
                 WHERE fsi.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
            ))
            OR (v_ownership_rights = 1
           AND (fi.current_state_id IN (
                SELECT flow_state_id
                  FROM flow_state_involvement
                 UNION
                SELECT flow_state_id
                  FROM flow_state_role
            )))
            OR EXISTS (
                SELECT 1
                  FROM region_role_member rrm
                  JOIN flow_state_role fsr ON fsr.role_sid = rrm.role_sid
                 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
                   AND rrm.region_sid = ia.region_sid
                   AND fsr.flow_state_id = fi.current_state_id
            )
            OR EXISTS (
                SELECT 1
                  FROM flow_state_role fsr
                  JOIN security.act act ON act.sid_id = fsr.group_sid 
                 WHERE act.act_id = v_act_id
                   AND fsr.flow_state_id = fi.current_state_id
            )
            OR EXISTS (
                SELECT 1
                  FROM flow_item_involvement fii
                  JOIN flow_state_involvement fsi
                    ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
                 WHERE SYS_CONTEXT('SECURITY','SID') = fii.user_sid
                   AND fii.flow_item_id = ia.flow_item_id
                   AND fi.current_state_id = fsi.flow_state_id
            ))
         UNION 
        SELECT ia.internal_audit_sid
          FROM internal_audit ia
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
         WHERE ia.deleted = 0
           AND EXISTS(
                SELECT 1
                  FROM flow_state_involvement fsi
                  JOIN chain.v$purchaser_involvement pi ON pi.flow_involvement_type_id = fsi.flow_involvement_type_id
                  JOIN supplier s ON pi.supplier_company_sid = s.company_sid
                 WHERE fi.current_state_id = fsi.flow_state_id
                   AND s.region_sid = ia.region_sid
           )
        );

     RETURN v_table;
END;

-- Returns a table collection of Audit_Sids that the logged in user has specified workflow access to
FUNCTION GetAuditsWithCapabilityAsTable (
    in_capability_id            IN    flow_capability.flow_capability_id%TYPE,
    in_permission                IN    NUMBER,
    in_page                        IN    security.T_ORDERED_SID_TABLE
) RETURN security.T_SID_TABLE AS
    v_audits_sid        security_pkg.T_SID_ID;
    v_table                security.T_SID_TABLE;
    v_trash_sid            security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash');
    v_ownership_rights    NUMBER;
    v_log_id            NUMBER;
BEGIN
    aspen2.request_queue_pkg.AssertRequestStillActive;
    v_log_id := chain.filter_pkg.StartDebugLog('csr.audit_pkg.GetAuditsWithCapabilityAsTable');

    v_audits_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    v_ownership_rights := security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security.security_pkg.PERMISSION_TAKE_OWNERSHIP);

    SELECT DISTINCT internal_audit_sid
      BULK COLLECT INTO v_table
      FROM(
        SELECT ia.internal_audit_sid
          FROM internal_audit ia
          LEFT JOIN TABLE(in_page) p ON ia.internal_audit_sid = p.sid_id
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
         WHERE ia.deleted = 0
           AND (in_page IS NULL OR p.sid_id IS NOT NULL)
           AND (((SYS_CONTEXT('SECURITY', 'SID') = ia.auditor_user_sid
            OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover))
           AND fi.current_state_id IN (
                SELECT flow_state_id
                  FROM flow_state_role_capability fsrc
                 WHERE fsrc.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDITOR
                   AND fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
            ))
            OR (SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') = ia.auditor_company_sid
           AND fi.current_state_id IN (
                SELECT flow_state_id
                  FROM flow_state_role_capability fsrc
                 WHERE fsrc.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
                   AND fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
            ))
            OR (v_ownership_rights = 1
           AND (fi.current_state_id IN (
                SELECT flow_state_id
                  FROM flow_state_role_capability fsrc
                 WHERE fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
            )))
            OR EXISTS (
                SELECT 1
                  FROM region_role_member rrm
                  JOIN flow_state_role_capability fsrc ON fsrc.role_sid = rrm.role_sid
                 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
                   AND rrm.region_sid = ia.region_sid
                   AND fsrc.flow_state_id = fi.current_state_id
                   AND fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
            )
            OR EXISTS (
                SELECT 1
                  FROM flow_state_role_capability fsrc 
                  JOIN security.act act ON fsrc.group_sid = act.sid_id
                 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
                   AND fsrc.flow_state_id = fi.current_state_id
                   AND fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
            )
            OR EXISTS (
                SELECT 1
                  FROM flow_item_involvement fii
                  JOIN flow_state_role_capability fsrc
                    ON fsrc.flow_involvement_type_id = fii.flow_involvement_type_id
                 WHERE SYS_CONTEXT('SECURITY','SID') = fii.user_sid
                   AND fii.flow_item_id = ia.flow_item_id
                   AND fi.current_state_id = fsrc.flow_state_id
                   AND fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
            ))
         UNION 
        SELECT ia.internal_audit_sid
          FROM internal_audit ia
          LEFT JOIN TABLE(in_page) p ON ia.internal_audit_sid = p.sid_id
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
         WHERE ia.deleted = 0
           AND (in_page IS NULL OR p.sid_id IS NOT NULL)
           AND EXISTS(
                   SELECT 1
                  FROM flow_state_role_capability fsrc
                  JOIN chain.v$purchaser_involvement pi ON fsrc.flow_involvement_type_id = pi.flow_involvement_type_id
                  JOIN supplier s ON pi.supplier_company_sid = s.company_sid
                 WHERE s.region_sid = ia.region_sid
                   AND fi.current_state_id = fsrc.flow_state_id
                   AND fsrc.flow_capability_id = in_capability_id
                   AND BITAND(fsrc.permission_set, in_permission) = in_permission
           )
        );

    chain.filter_pkg.EndDebugLog(v_log_id);
    
    RETURN v_table;
END;

FUNCTION MultipleSurveysEnabled
RETURN BOOLEAN AS
    v_multiple_audit_surveys        customer.multiple_audit_surveys%TYPE;
BEGIN
    SELECT multiple_audit_surveys
      INTO v_multiple_audit_surveys
      FROM customer;

    RETURN v_multiple_audit_surveys = 1;
END;

FUNCTION IsFlowAudit(
    in_internal_audit_sid        IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
    v_flow_item_id                internal_audit.flow_item_id%TYPE;
BEGIN
    BEGIN
        SELECT flow_item_id
          INTO v_flow_item_id
          FROM internal_audit
         WHERE internal_audit_sid = in_internal_audit_sid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
    END;

    IF v_flow_item_id IS NOT NULL THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;

FUNCTION SQL_HasCapabilityAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_capability_id            IN    flow_capability.flow_capability_id%TYPE,
    in_permission                IN    NUMBER
) RETURN BINARY_INTEGER
AS
BEGIN
    IF HasCapabilityAccess(in_audit_sid, in_capability_id, in_permission) THEN
        RETURN 1;
    END IF;

    RETURN 0;
END;

FUNCTION IsInCapabilitiesTT(
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
    v_count                NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM tt_audit_capability
     WHERE internal_audit_sid = in_audit_sid;
    
    RETURN v_count > 0;
END;

/* Separate version that is being called only by GetAuditSummaries. THe reason the query
is not being refactored and re-used is that it returns a very different number of rows depending on the caller
and that makes oracle changing the order of the joins in the plan (it seems to defer joining the sid table with audits to a later step). 
Having 2 versions should give us better control over their execution */

PROCEDURE PopulateAuditCapabilitiesTT(
    in_audits_t        security.T_SID_TABLE
)
AS
    v_sid                security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
    v_act_id            security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
    v_perm_take_own        NUMBER := security_pkg.SQL_IsAccessAllowedSID(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16); -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
BEGIN
    DELETE FROM tt_audit_capability;
    
    INSERT INTO tt_audit_capability(internal_audit_sid, internal_audit_type_id, flow_capability_id, permission_set)
    SELECT ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id,
           MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
           MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
      FROM TABLE(in_audits_t) t_a
      JOIN internal_audit ia ON t_a.column_value = ia.internal_audit_sid
      JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
      JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
      LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
       AND rrm.user_sid = v_sid
       AND rrm.role_sid = fsrc.role_sid
      LEFT JOIN security.act act ON act.sid_id = fsrc.group_sid AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
      LEFT JOIN (
        SELECT fii.flow_involvement_type_id, fii.flow_item_id, fsi.flow_state_id
          FROM flow_item_involvement fii
          JOIN flow_state_involvement fsi
            ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
         WHERE fii.user_sid = v_sid
        ) finv
        ON finv.flow_item_id = fi.flow_item_id
       AND finv.flow_involvement_type_id = fsrc.flow_involvement_type_id
       AND finv.flow_state_id = fi.current_state_id
      LEFT JOIN supplier s ON ia.region_sid = s.region_sid
      LEFT JOIN chain.v$purchaser_involvement pi ON fsrc.flow_involvement_type_id = pi.flow_involvement_type_id 
       AND s.company_sid = pi.supplier_company_sid
     WHERE ia.deleted = 0
       AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
       AND (ia.auditor_user_sid = v_sid
        OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
        OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
       AND fsrc.flow_involvement_type_id = 2)    -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
        OR finv.flow_involvement_type_id IS NOT NULL
        OR rrm.role_sid IS NOT NULL
        OR act.sid_id IS NOT NULL
        OR pi.flow_involvement_type_id IS NOT NULL
        OR v_perm_take_own = 1)
     GROUP BY ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id;
END;

PROCEDURE PopulateAuditCapabilitiesTT(
    in_audit_sid            IN    security_pkg.T_SID_ID
)
AS
    v_sid                security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
    v_act_id            security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
    v_perm_take_own        NUMBER := security_pkg.SQL_IsAccessAllowedSID(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16); -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
BEGIN
    DELETE FROM tt_audit_capability;
    
    INSERT INTO tt_audit_capability(internal_audit_sid, internal_audit_type_id, flow_capability_id, permission_set)
    SELECT ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id,
           MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
           MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
      FROM internal_audit ia
      JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
      JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
      LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
       AND rrm.user_sid = v_sid
       AND rrm.role_sid = fsrc.role_sid
      LEFT JOIN security.act act ON act.sid_id = fsrc.group_sid AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
      LEFT JOIN (
        SELECT fii.flow_involvement_type_id, fii.flow_item_id, fsi.flow_state_id
          FROM flow_item_involvement fii
          JOIN flow_state_involvement fsi
            ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
         WHERE fii.user_sid = v_sid
        ) finv
        ON finv.flow_item_id = fi.flow_item_id
       AND finv.flow_involvement_type_id = fsrc.flow_involvement_type_id
       AND finv.flow_state_id = fi.current_state_id
      LEFT JOIN supplier s ON ia.region_sid = s.region_sid
      LEFT JOIN chain.v$purchaser_involvement pi ON fsrc.flow_involvement_type_id = pi.flow_involvement_type_id 
       AND s.company_sid = pi.supplier_company_sid
     WHERE ia.internal_audit_sid = in_audit_sid
       AND ia.deleted = 0
       AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
       AND (ia.auditor_user_sid = v_sid
        OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
        OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
       AND fsrc.flow_involvement_type_id = 2)    -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
        OR finv.flow_involvement_type_id IS NOT NULL
        OR rrm.role_sid IS NOT NULL
        OR act.sid_id IS NOT NULL
        OR pi.flow_involvement_type_id IS NOT NULL
        OR v_perm_take_own = 1)
     GROUP BY ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id;
END;

FUNCTION HasCapabilityAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_capability_id            IN    flow_capability.flow_capability_id%TYPE,
    in_permission                IN    NUMBER
) RETURN BOOLEAN
AS
BEGIN
    IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
        RETURN TRUE;
    END IF;

    IF NOT IsInCapabilitiesTT(in_audit_sid) THEN
        PopulateAuditCapabilitiesTT(in_audit_sid); 
    END IF;

    FOR r IN (
        SELECT * FROM dual WHERE EXISTS (
            SELECT *
              FROM tt_audit_capability
             WHERE internal_audit_sid = in_audit_sid
               AND flow_capability_id = in_capability_id
               AND bitand(permission_set, in_permission) = in_permission
        )
    ) LOOP
        RETURN TRUE;
    END LOOP;

    RETURN FALSE;
END;

PROCEDURE GetAbilities (
    in_audit_sid                IN    security_pkg.T_SID_ID,
    out_cur                        OUT    SYS_REFCURSOR,
    out_surveys_cur                OUT    SYS_REFCURSOR,
    out_non_compliance_types    OUT SYS_REFCURSOR
)
AS
BEGIN
    GetAbilities(in_audit_sid, 0, out_cur, out_surveys_cur, out_non_compliance_types);
END;

FUNCTION GetAbilities (
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_include_all                IN    NUMBER
) RETURN T_AUDIT_ABILITY_TABLE
AS
    v_abilities_t                T_AUDIT_ABILITY_TABLE;
BEGIN
    IF NOT IsInCapabilitiesTT(in_audit_sid) THEN
        PopulateAuditCapabilitiesTT(in_audit_sid); 
    END IF;

    -- Get maximum set of permissions between all involvement types that the user is involved by.
    -- Administrators get the maximum set between all involement types for the current state
    SELECT T_AUDIT_ABILITY(flow_capability_id, permission_set)
      BULK COLLECT INTO v_abilities_t
      FROM tt_audit_capability
     WHERE internal_audit_sid = in_audit_sid
       AND (in_include_all = 1 OR flow_capability_id < 1000000)
     ORDER BY flow_capability_id;

    RETURN v_abilities_t;
END;

PROCEDURE GetAbilities (
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_include_all                IN    NUMBER,
    out_cur                        OUT    SYS_REFCURSOR,
    out_surveys_cur                OUT    SYS_REFCURSOR,
    out_non_compliance_types    OUT SYS_REFCURSOR
)
AS
    v_survey_permission_set                security_pkg.T_PERMISSION;
    v_change_survey_permission_set        security_pkg.T_PERMISSION;
    v_audit_abilities    T_AUDIT_ABILITY_TABLE := GetAbilities(in_audit_sid, in_include_all);
BEGIN
    OPEN out_cur FOR 
        SELECT flow_capability_id, permission_set
          FROM TABLE (v_audit_abilities);

    BEGIN
        SELECT permission_set 
          INTO v_survey_permission_set
          FROM tt_audit_capability
         WHERE internal_audit_sid = in_audit_sid
           AND flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_SURVEY;
    EXCEPTION
        WHEN no_data_found THEN
            v_survey_permission_set := 0;
    END;

    BEGIN
        SELECT permission_set 
          INTO v_change_survey_permission_set
          FROM tt_audit_capability
         WHERE internal_audit_sid = in_audit_sid
           AND flow_capability_id = csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY;
    EXCEPTION
        WHEN no_data_found THEN
            v_change_survey_permission_set := 0;
    END;

    OPEN out_surveys_cur FOR
        SELECT primary_audit_type_survey_id internal_audit_type_survey_id, NULL label,
               v_survey_permission_set survey_permission_set, 
               v_change_survey_permission_set change_survey_permission_set
          FROM dual
         UNION
        SELECT iats.internal_audit_type_survey_id, iats.label,
               CASE WHEN iats.ia_type_survey_group_id IS NULL THEN v_survey_permission_set ELSE NVL(sac.permission_set, 0) END survey_permission_set,
               CASE WHEN iats.ia_type_survey_group_id IS NULL THEN v_change_survey_permission_set ELSE NVL(scac.permission_set, 0) END change_survey_permission_set
          FROM internal_audit_type_survey iats
          LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id
                                               AND iatsg.app_sid = iats.app_sid
          LEFT JOIN tt_audit_capability sac ON sac.flow_capability_id = iatsg.survey_capability_id
                                          AND sac.internal_audit_sid = in_audit_sid
          LEFT JOIN tt_audit_capability scac ON scac.flow_capability_id = iatsg.change_survey_capability_id
                                           AND scac.internal_audit_sid = in_audit_sid
         WHERE iats.app_sid = SYS_CONTEXT('SECURITY', 'APP');

    OPEN out_non_compliance_types FOR
        SELECT nct.non_compliance_type_id, tt.permission_set
          FROM csr.non_compliance_type nct
          JOIN tt_audit_capability tt
            ON NVL(nct.flow_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL) = tt.flow_capability_id
         WHERE nct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND tt.internal_audit_sid = in_audit_sid;

END;

/* Audit Findings security functions */

-- Returns a dictionary of audits and permissible NC types linked to a custom flow cap ONLY
-- The standard Finding capability is not considered in this particular func 
-- The caller will have to consider it separately
FUNCTION GetCustomPermissibleAuditNCTs(
    in_access                IN    security_pkg.T_PERMISSION
) RETURN csr.T_AUDIT_PERMISSIBLE_NCT_TABLE
AS
    v_ret_tab                    csr.T_AUDIT_PERMISSIBLE_NCT_TABLE := csr.T_AUDIT_PERMISSIBLE_NCT_TABLE();
    v_current_tab                csr.T_AUDIT_PERMISSIBLE_NCT_TABLE;
    v_tmp_audits_by_cap            security.T_SID_TABLE;
BEGIN
    FOR r IN (
        SELECT flow_capability_id, non_compliance_type_id
          FROM non_compliance_type nct
         WHERE nct.app_sid = security.security_pkg.getapp
           AND flow_capability_id IS NOT NULL
    )
    LOOP
        v_tmp_audits_by_cap := GetAuditsWithCapabilityAsTable(r.flow_capability_id, in_access, NULL);

        SELECT CSR.T_AUDIT_PERMISSIBLE_NCT (t.column_value, r.non_compliance_type_id)
          BULK COLLECT INTO v_current_tab
          FROM TABLE(v_tmp_audits_by_cap) t;

        v_ret_tab := v_current_tab MULTISET UNION v_ret_tab;
    END LOOP;
    RETURN v_ret_tab;
END;

FUNCTION GetPermissibleNCTypeIds(
    in_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_access                IN    security_pkg.T_PERMISSION
) RETURN security.T_SID_TABLE
AS
    v_perm_ids             security.T_SID_TABLE := security.T_SID_TABLE();
    v_has_std_cap         BOOLEAN DEFAULT HasCapabilityAccess(in_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, in_access);
BEGIN
    FOR r IN (
        SELECT nct.flow_capability_id, nct.non_compliance_type_id
          FROM non_compliance_type nct
         WHERE nct.app_sid = security.security_pkg.getapp
    )
    LOOP
        IF r.flow_capability_id IS NOT NULL AND HasCapabilityAccess(in_audit_sid, r.flow_capability_id, in_access) THEN
            v_perm_ids.EXTEND;
            v_perm_ids(v_perm_ids.COUNT) := r.non_compliance_type_id;
        ELSIF r.flow_capability_id IS NULL AND v_has_std_cap THEN
            v_perm_ids.EXTEND;
            v_perm_ids(v_perm_ids.COUNT) := r.non_compliance_type_id;
        END IF;
    END LOOP;

    RETURN v_perm_ids;
END;

FUNCTION HasFlowAuditNonComplTypeAccess(
    in_non_compliance_type_id        IN    non_compliance_type.non_compliance_type_id%TYPE,
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_access                        IN    security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
    v_flow_capability_id            non_compliance_type.flow_capability_id%TYPE;
BEGIN
    BEGIN
        SELECT flow_capability_id
          INTO v_flow_capability_id
          FROM non_compliance_type
         WHERE app_sid = security.security_pkg.getapp
           AND non_compliance_type_id = in_non_compliance_type_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN -- allow for type to be null
            v_flow_capability_id := NULL;
    END;
    RETURN HasCapabilityAccess(in_audit_sid, NVL(v_flow_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL), in_access);
END;

FUNCTION HasFlowAuditNonComplAccess(
    in_non_compliance_id            IN    non_compliance.non_compliance_id%TYPE,
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_access                        IN    security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
    v_non_compliance_type_id        non_compliance_type.non_compliance_type_id%TYPE;
BEGIN
    SELECT non_compliance_type_id
      INTO v_non_compliance_type_id
      FROM non_compliance
     WHERE app_sid = security.security_pkg.getapp
       AND non_compliance_id = in_non_compliance_id;
    
    RETURN HasFlowAuditNonComplTypeAccess(v_non_compliance_type_id, in_audit_sid, in_access);
END;

/* End of Audit Findings security functions */

FUNCTION IsInAuditorRole(
    in_audit_sid                IN    security_pkg.T_SID_ID
)
RETURN BOOLEAN AS
    v_auditor_role_sid            security_pkg.T_SID_ID;
    v_region_sid                security_pkg.T_SID_ID;
BEGIN
    SELECT MIN(auditor_role_sid), MIN(region_sid)
      INTO v_auditor_role_sid, v_region_sid
      FROM v$audit
     WHERE internal_audit_sid = in_audit_sid;

    RETURN role_pkg.IsUserInRole(v_auditor_role_sid, v_region_sid);
END;

FUNCTION IsInAuditContactRole(
    in_audit_sid                IN    security_pkg.T_SID_ID
)
RETURN BOOLEAN AS
    v_audit_contact_role_sid    security_pkg.T_SID_ID;
    v_region_sid                security_pkg.T_SID_ID;
BEGIN
    SELECT MIN(audit_contact_role_sid), MIN(region_sid)
      INTO v_audit_contact_role_sid, v_region_sid
      FROM v$audit
     WHERE internal_audit_sid = in_audit_sid;

    RETURN role_pkg.IsUserInRole(v_audit_contact_role_sid, v_region_sid);
END;

FUNCTION IsAuditAdministrator
RETURN BOOLEAN AS
    v_audits_sid            security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    -- Use take ownership permission to establish heavy duty (i.e. administrator) permissions
    RETURN security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP);
END;


FUNCTION SQL_IsAuditAdministrator
RETURN BINARY_INTEGER AS
BEGIN
    IF IsAuditAdministrator THEN
        RETURN 1;
    END IF;

    RETURN 0;
END;

FUNCTION HasReadAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
)
RETURN BOOLEAN AS
    v_auditor_role_sid            security_pkg.T_SID_ID;
    v_audit_contact_role_sid    security_pkg.T_SID_ID;
BEGIN
    IF IsFlowAudit(in_audit_sid) THEN
        RETURN HasCapabilityAccess(in_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT, security_pkg.PERMISSION_READ);
    END IF;
    
    IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
        RETURN TRUE;
    END IF;
    
    IF(security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_audit_sid, security_pkg.PERMISSION_READ)) THEN
        RETURN TRUE;
    END IF;

    IF IsInAuditorRole(in_audit_sid) THEN
        RETURN TRUE;
    END IF;

    IF IsInAuditContactRole(in_audit_sid) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;

FUNCTION SQL_HasReadAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
    IF HasReadAccess(in_audit_sid) THEN
        RETURN 1;
    ELSE 
        RETURN 0;
    END IF;
END;

FUNCTION HasWriteAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
    IF IsFlowAudit(in_audit_sid) THEN
        RETURN HasCapabilityAccess(in_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT, security_pkg.PERMISSION_WRITE);
    END IF;
    
    IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
        RETURN TRUE;
    END IF;
    
    IF(security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_audit_sid, security_pkg.PERMISSION_WRITE)) THEN
        RETURN TRUE;
    END IF;

    IF IsInAuditorRole(in_audit_sid) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;

FUNCTION HasDeleteAccess (
    in_audit_sid            IN    security_pkg.T_SID_ID
)
RETURN BOOLEAN 
AS
BEGIN
    IF IsFlowAudit(in_audit_sid) THEN
        RETURN HasCapabilityAccess(in_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_DELETE, security_pkg.PERMISSION_WRITE);
    END IF;
    
    IF security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
        RETURN TRUE;
    END IF;
    
    IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_audit_sid, security_pkg.PERMISSION_DELETE) THEN
        RETURN TRUE;
    END IF;

    -- roles can't delete audits
    
    RETURN FALSE;
END;

FUNCTION GetPermissionOnAudit(
    in_sid_id                IN    internal_audit.internal_audit_sid%TYPE
)
RETURN NUMBER AS
BEGIN
    
    --this function is used in left joins so it might be passed null values
    IF in_sid_id IS NULL THEN
        RETURN 0; 
    END IF;

    -- This means that delete access would infer write access - this may not always
    -- be the case
    IF HasDeleteAccess(in_sid_id) THEN
        RETURN security.security_pkg.PERMISSION_DELETE;
    END IF;
    IF HasWriteAccess(in_sid_id) THEN
        RETURN security.security_pkg.PERMISSION_WRITE;
    END IF;
    IF HasReadAccess(in_sid_id) THEN
        RETURN security.security_pkg.PERMISSION_READ;
    END IF;
    RETURN 0;
END;

PROCEDURE CheckNonComplianceReadable(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE
)
AS
BEGIN
    CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_READ);
END;

PROCEDURE CheckNonComplianceWriteable(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE
)
AS
BEGIN
    CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE);
END;

PROCEDURE TriggerAuditAgg(
    in_start_dtm        IN    DATE DEFAULT DATE '1980-01-01',
    in_end_dtm            IN    DATE DEFAULT DATE '2021-01-01'
)
AS
BEGIN
    FOR r IN (
        SELECT aggregate_ind_group_id
          FROM aggregate_ind_group
         WHERE name IN ('InternalAudit')
           AND app_sid = security_pkg.GetApp
    ) LOOP
        calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id, in_start_dtm, in_end_dtm);
    END LOOP;
END;

PROCEDURE TriggerAuditAgg(
    in_audit_sid    IN    security_pkg.T_SID_ID
)
AS
    v_audit_dtm        internal_audit.audit_dtm%TYPE;
BEGIN
    SELECT audit_dtm
      INTO v_audit_dtm
      FROM internal_audit
     WHERE internal_audit_sid = in_audit_sid;

    TriggerAuditAgg(TRUNC(v_audit_dtm,'MONTH'), ADD_MONTHS(TRUNC(v_audit_dtm,'MONTH'),1));
END;

-- Securable object callbacks
PROCEDURE CreateObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID,
    in_class_id                IN security_pkg.T_CLASS_ID,
    in_name                    IN security_pkg.T_SO_NAME,
    in_parent_sid_id        IN security_pkg.T_SID_ID
)
AS
BEGIN
    NULL;
END;

PROCEDURE RenameObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID,
    in_new_name                IN security_pkg.T_SO_NAME
)
AS
BEGIN
    NULL;
END;

PROCEDURE DeleteObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID
)
AS
    v_response_id            NUMBER(10);
    v_summary_response_id    NUMBER(10);
    v_response_ids            security.T_SID_TABLE;
    v_non_compliance_ids    security.T_SID_TABLE;
    v_flow_item_id            NUMBER(10);
BEGIN

    INTERNAL_CallHelperPkg('AuditDeleted', in_sid_id);
    
    DELETE FROM csr.internal_audit_score
     WHERE internal_audit_sid = in_sid_id;

    SELECT survey_response_id, summary_response_id
      INTO v_response_id, v_summary_response_id
      FROM internal_audit
     WHERE internal_audit_sid = in_sid_id;

    SELECT survey_response_id
      BULK COLLECT INTO v_response_ids
      FROM internal_audit_survey
     WHERE internal_audit_sid = in_sid_id;

    UPDATE internal_audit
       SET survey_response_id = NULL,
           summary_response_id = NULL
     WHERE internal_audit_sid = in_sid_id;
    
    DELETE FROM chain.higg_config_profile
      WHERE internal_audit_sid = in_sid_id;

    DELETE FROM internal_audit_survey
     WHERE internal_audit_sid = in_sid_id;

    DELETE FROM qs_submission_file
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id
        OR survey_response_id IN (
            SELECT column_value FROM TABLE(v_response_ids)
        );

    DELETE FROM qs_answer_file
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id
        OR survey_response_id IN (
            SELECT column_value FROM TABLE(v_response_ids)
        );

    DELETE FROM qs_response_file
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id
        OR survey_response_id IN (
            SELECT column_value FROM TABLE(v_response_ids)
        );

    DELETE FROM qs_answer_log
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id
        OR survey_response_id IN (
            SELECT column_value FROM TABLE(v_response_ids)
        );

    DELETE FROM issue_survey_answer
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id
        OR survey_response_id IN (
            SELECT column_value FROM TABLE(v_response_ids)
        );

    DELETE FROM quick_survey_answer
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id
        OR survey_response_id IN (
            SELECT column_value FROM TABLE(v_response_ids)
        );

    UPDATE audit_non_compliance
       SET repeat_of_audit_nc_id = NULL
     WHERE repeat_of_audit_nc_id IN (
        SELECT audit_non_compliance_id
          FROM audit_non_compliance
         WHERE internal_audit_sid = in_sid_id
     );

    SELECT del.non_compliance_id
      BULK COLLECT INTO v_non_compliance_ids
      FROM audit_non_compliance del
     WHERE del.internal_audit_sid = in_sid_id
       AND NOT EXISTS (
        SELECT NULL
          FROM audit_non_compliance keep
         WHERE keep.non_compliance_id = del.non_compliance_id
           AND keep.internal_audit_sid != in_sid_id
    );

    DELETE FROM audit_non_compliance
     WHERE internal_audit_sid = in_sid_id;

    DELETE FROM non_compliance_expr_action
     WHERE non_compliance_id IN (
        SELECT column_value FROM TABLE(v_non_compliance_ids)
        );

    UPDATE quick_survey_response
       SET last_submission_id = NULL
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id;

    DELETE FROM quick_survey_submission
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id;

    DELETE FROM quick_survey_response
     WHERE survey_response_id = v_response_id
        OR survey_response_id = v_summary_response_id;

    UPDATE issue_log
       SET issue_id = NULL
     WHERE issue_id IN (
        SELECT issue_id
          FROM issue
         WHERE issue_non_compliance_id IN (
            SELECT issue_non_compliance_id
              FROM issue_non_compliance
             WHERE non_compliance_id IN (
                SELECT column_value FROM TABLE(v_non_compliance_ids)
            )
        )
    );

    UPDATE issue_action_log
       SET issue_id = NULL
     WHERE issue_id IN (
        SELECT issue_id
          FROM issue
         WHERE issue_non_compliance_id IN (
            SELECT issue_non_compliance_id
              FROM issue_non_compliance
             WHERE non_compliance_id IN (
                SELECT column_value FROM TABLE(v_non_compliance_ids)
            )
        )
    );

    DELETE FROM issue_involvement
     WHERE issue_id IN (
        SELECT issue_id
          FROM issue
         WHERE issue_non_compliance_id IN (
            SELECT issue_non_compliance_id
              FROM issue_non_compliance
             WHERE non_compliance_id IN (
                SELECT column_value FROM TABLE(v_non_compliance_ids)
            )
        )
    );

    DELETE FROM issue_user_cover
     WHERE issue_id in (
        SELECT issue_id
          FROM issue
         WHERE issue_non_compliance_id IN (
            SELECT issue_non_compliance_id
              FROM issue_non_compliance
             WHERE non_compliance_id IN (
                SELECT column_value FROM TABLE(v_non_compliance_ids)
            )
        )
    );

    -- This could to blow up because of unresolved FB7828
    FOR r IN (
        SELECT issue_id
          FROM issue
         WHERE issue_non_compliance_id IN (
            SELECT issue_non_compliance_id
              FROM issue_non_compliance
             WHERE non_compliance_id IN (
                SELECT column_value FROM TABLE(v_non_compliance_ids)
            )
        )
    ) LOOP
        issue_pkg.UNSEC_DeleteIssue(r.issue_id);
    END LOOP;

    DELETE FROM issue_non_compliance
     WHERE non_compliance_id IN (
        SELECT column_value FROM TABLE(v_non_compliance_ids)
    );

    DELETE FROM non_compliance_tag
     WHERE non_compliance_id IN (
        SELECT column_value FROM TABLE(v_non_compliance_ids)
    );

    DELETE FROM non_compliance_file
     WHERE non_compliance_id IN (
        SELECT column_value FROM TABLE(v_non_compliance_ids)
    );

    DELETE FROM non_compliance
     WHERE non_compliance_id IN (
        SELECT column_value FROM TABLE(v_non_compliance_ids)
    );


    UPDATE non_compliance nc
       SET (created_in_audit_sid) = (
        SELECT MIN(internal_audit_sid)
          FROM audit_non_compliance anc
         WHERE anc.non_compliance_id = nc.non_compliance_id
        )
     WHERE created_in_audit_sid = in_sid_id;

    DELETE FROM audit_alert
     WHERE internal_audit_sid = in_sid_id;

    DELETE FROM audit_user_cover
     WHERE internal_audit_sid = in_sid_id;

    SELECT MIN(flow_item_id)
      INTO v_flow_item_id
      FROM internal_audit
     WHERE internal_audit_sid = in_sid_id;

    UPDATE internal_audit
       SET flow_item_id = NULL
     WHERE internal_audit_sid = in_sid_id;

    DELETE FROM flow_item_generated_alert
     WHERE flow_item_id = v_flow_item_id;

    DELETE FROM flow_state_log
     WHERE flow_item_id = v_flow_item_id;

    DELETE FROM flow_item
     WHERE flow_item_id = v_flow_item_id;

    DELETE FROM internal_audit_file_data
     WHERE internal_audit_file_data_id IN (
        SELECT internal_audit_file_data_id
          FROM internal_audit_file
         WHERE internal_audit_sid = in_sid_id
        )
       AND internal_audit_file_data_id NOT IN (    -- delete an internal file only if the it is not being used by another audit
        SELECT internal_audit_file_data_id
          FROM internal_audit_file
         WHERE internal_audit_sid != in_sid_id
        );

    DELETE FROM internal_audit_file
     WHERE internal_audit_sid = in_sid_id;

    DELETE FROM chain.supplier_audit
     WHERE audit_sid = in_sid_id;

    DELETE FROM internal_audit_postit
     WHERE internal_audit_sid = in_sid_id;

    DELETE FROM internal_audit_tag
     WHERE internal_audit_sid = in_sid_id;

    chain.bsci_pkg.DeleteAudit(in_sid_id);
     
    DELETE FROM internal_audit
     WHERE internal_audit_sid = in_sid_id;

END;

PROCEDURE MoveObject(
    in_act_id                IN security_pkg.T_ACT_ID,
    in_sid_id                IN security_pkg.T_SID_ID,
    in_new_parent_sid_id    IN security_pkg.T_SID_ID,
    in_old_parent_sid_id    IN security_pkg.T_SID_ID
)
AS
    v_trash_sid                security_pkg.T_SID_ID;
BEGIN

    v_trash_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash');

    IF in_new_parent_sid_id != v_trash_sid THEN
        UPDATE internal_audit
           SET deleted = 0
         WHERE internal_audit_sid = in_sid_id;

        UPDATE issue
           SET deleted = 0
         WHERE deleted = 1
           AND issue_non_compliance_id IN (
            SELECT inc.issue_non_compliance_id
              FROM issue_non_compliance inc
              JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
             WHERE anc.internal_audit_sid = in_sid_id
            );
        
        chain.filter_pkg.ClearCacheForAllUsers (
            in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
        );
        
        chain.filter_pkg.ClearCacheForAllUsers (
            in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
        );
    END IF;

    TriggerAuditAgg(in_sid_id);
END;

PROCEDURE TrashAudit (
    in_internal_audit_sid    IN    internal_audit.internal_audit_sid%TYPE
)
AS
    v_description            internal_audit.label%TYPE;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_internal_audit_sid, security_pkg.PERMISSION_DELETE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting the audit with sid '||in_internal_audit_sid);
    END IF;

    UPDATE internal_audit
       SET deleted = 1
     WHERE internal_audit_sid = in_internal_audit_sid;

    UPDATE issue
       SET deleted = 1
     WHERE issue_non_compliance_id IN (
        SELECT inc.issue_non_compliance_id
          FROM issue_non_compliance inc
          JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
         WHERE anc.internal_audit_sid = in_internal_audit_sid
        )
      AND issue_non_compliance_id NOT IN (
        SELECT inc.issue_non_compliance_id
          FROM issue_non_compliance inc
          JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
          JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = inc.app_sid
         WHERE ia.deleted = 0
        );

    SELECT label
      INTO v_description
      FROM internal_audit
     WHERE internal_audit_sid = in_internal_audit_sid;

    csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
        'Moved to trash: {0} ({1})', v_description, in_internal_audit_sid);

    trash_pkg.TrashObject(security_pkg.GetAct, in_internal_audit_sid,
        securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash'),
        v_description);

    INTERNAL_CallHelperPkg('AuditDeleted', in_internal_audit_sid);
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
    );
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
    );
END;

FUNCTION SupportsDueAudits
RETURN NUMBER
AS
BEGIN
    FOR r IN (
        SELECT *
          FROM dual
         WHERE EXISTS(SELECT NULL FROM audit_type_closure_type WHERE re_audit_due_after IS NOT NULL)
    ) LOOP
        RETURN 1;
    END LOOP;
    RETURN 0;
END;

PROCEDURE GetDetails(
    in_sid_id                IN    internal_audit.internal_audit_sid%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_trash_sid                security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash');
    v_perm_level            NUMBER := GetPermissionOnAudit(in_sid_id);
    v_read_on_survey        NUMBER;
    v_read_on_closure        NUMBER;
    v_read_on_exec_sum        NUMBER;
    v_read_on_auditee        NUMBER;
BEGIN

    IF NOT (HasReadAccess(in_sid_id)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_sid_id);
    END IF;

    v_read_on_survey := SQL_HasCapabilityAccess(in_sid_id, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security.security_pkg.PERMISSION_READ);
    v_read_on_closure := SQL_HasCapabilityAccess(in_sid_id, csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ);
    v_read_on_exec_sum := SQL_HasCapabilityAccess(in_sid_id, csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, security.security_pkg.PERMISSION_READ);
    v_read_on_auditee := SQL_HasCapabilityAccess(in_sid_id, csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE, security.security_pkg.PERMISSION_READ);

    OPEN out_cur FOR
        SELECT ia.internal_audit_sid, ia.custom_audit_id, ia.region_sid, ia.region_description,
               ia.label, ia.audit_dtm, ia.created_by_user_sid, cc.full_name created_by_full_name,
               ia.created_dtm, ia.auditor_user_sid, ia.auditor_email, ia.auditor_full_name,
               ia.full_notes notes, ia.internal_audit_type_id,
               ia.audit_type_label internal_audit_type_label, ia.audit_type_source_id,
               ia.auditor_name, ia.auditor_organisation,
               ia.tab_sid, ia.form_path, ia.form_sid,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_auditee = 1 THEN ia.auditee_user_sid ELSE NULL END auditee_user_sid,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_auditee = 1 THEN ia.auditee_full_name ELSE NULL END auditee_full_name,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_auditee = 1 THEN ia.auditee_email ELSE NULL END auditee_email,
               CASE WHEN wr.sid_id IS NOT NULL AND (ia.flow_item_id IS NULL OR v_read_on_survey = 1) THEN ia.survey_sid ELSE null END survey_sid,
               CASE WHEN wr.sid_id IS NOT NULL AND (ia.flow_item_id IS NULL OR v_read_on_survey = 1) THEN ia.survey_label ELSE null END survey_label,
               CASE WHEN wr.sid_id IS NOT NULL AND (ia.flow_item_id IS NULL OR v_read_on_survey = 1) THEN ia.survey_response_id ELSE null END survey_response_id,
               CASE WHEN wr.sid_id IS NOT NULL AND (ia.flow_item_id IS NULL OR v_read_on_survey = 1) THEN ia.survey_version ELSE null END survey_version,
               ia.survey_overall_score survey_overall_score,
               CASE WHEN wr.sid_id IS NOT NULL AND (ia.flow_item_id IS NULL OR v_read_on_survey = 1) THEN ia.survey_completed ELSE null END survey_completed,
               CASE WHEN ia.flow_item_id IS NULL OR (ia.flow_item_id IS NOT NULL AND ia.use_legacy_closed_definition = 1) OR v_read_on_closure = 1 THEN
                    ia.audit_closure_type_id
               ELSE
                    NULL 
               END audit_closure_type_id,
               CASE WHEN ia.flow_item_id IS NULL OR (ia.flow_item_id IS NOT NULL AND ia.use_legacy_closed_definition = 1) OR v_read_on_closure = 1 THEN
                    ia.closure_label
               ELSE 
                    NULL
               END audit_closure_type_label,
               ia.icon_image_filename audit_closure_type_filename, ia.icon_image_sha1 audit_closure_type_sha1,
               ia.auditor_role_sid, ia.assign_issues_to_role, ia.add_nc_per_question, ia.cover_auditor_sid, v_perm_level permission_level,
               CASE WHEN EXISTS(
                    SELECT 1 FROM region_role_member rrm
                     WHERE rrm.role_sid = ia.auditor_role_sid
                       AND region_sid = ia.region_sid
               ) THEN 1 ELSE 0 END users_exist_in_auditor_role,
               ia.flow_sid, ia.flow_label, ia.flow_item_id, ia.current_state_id, 
               fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.is_final flow_state_is_final,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_exec_sum = 1 THEN ia.summary_survey_sid ELSE null END summary_survey_sid,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_exec_sum = 1 THEN ia.summary_survey_label ELSE null END summary_survey_label,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_exec_sum = 1 THEN ia.summary_response_id ELSE null END summary_response_id,
               CASE WHEN ia.flow_item_id IS NULL OR v_read_on_exec_sum = 1 THEN ia.summary_survey_version ELSE null END summary_survey_version,
               qss.overall_score, vand.next_audit_due_dtm, qsr.last_submission_id, ia.comparison_response_id, ia.nc_audit_child_region,
               ia.ia_type_group_label, ia.ia_type_group_lookup_key, ia.internal_audit_type_group_id, 
               ia.audit_singular_label, ia.audit_plural_label, ia.auditee_user_label, ia.auditor_user_label, ia.auditor_name_label,
               ia.survey_score_type_id, ia.survey_score_thrsh_id, st.description survey_threshold_description, ia.survey_score_format_mask, ia.survey_overall_max_score, ia.survey_score_label,
               ia.nc_score, ia.nc_score_type_id, ia.nc_score_thrsh_id, ia.nc_max_score, ia.nc_score_label, ia.nc_score_format_mask,
               ia.open_non_compliances, c.company_sid, c.company_type_id, ac.name auditor_company, ia.auditor_company_sid, ia.permit_id,
               ia.use_legacy_closed_definition, ia.ovw_validity_dtm, ia.external_audit_ref, ia.external_parent_ref, ia.external_url
          FROM v$audit ia
          JOIN csr_user cc ON ia.created_by_user_sid = cc.csr_user_sid AND ia.app_sid = cc.app_sid
          JOIN security.securable_object so ON ia.internal_audit_sid = so.sid_id
          LEFT JOIN flow_state fs ON fs.flow_state_id = ia.current_state_id
          LEFT JOIN v$audit_next_due vand ON vand.internal_audit_sid = ia.internal_audit_sid
          LEFT JOIN quick_survey_response qsr ON qsr.survey_response_id = ia.survey_response_id
          LEFT JOIN quick_survey_submission qss ON qss.survey_response_id = ia.survey_response_id AND qss.submission_id = qsr.last_submission_id
          LEFT JOIN security.web_resource wr ON ia.survey_sid = wr.sid_id -- check to see if survey hasn't been trashed
          LEFT JOIN csr.supplier s ON ia.region_sid = s.region_sid
          LEFT JOIN chain.company c ON s.company_sid = c.company_sid AND c.deleted = 0 AND c.pending = 0
          LEFT JOIN chain.company ac ON ia.auditor_company_sid = ac.company_sid
          LEFT JOIN score_threshold st ON st.score_threshold_id = ia.survey_score_thrsh_id
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.internal_audit_sid = in_sid_id
           AND so.parent_sid_id != v_trash_sid;
END;

PROCEDURE GetDocuments(
    in_internal_audit_sid        IN    internal_audit.internal_audit_sid%TYPE,
    in_internal_audit_source_id    IN  internal_audit_type_source.internal_audit_type_source_id%TYPE DEFAULT NULL,
    out_cur                        OUT    SYS_REFCURSOR
)
AS
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_cap_audit_docs_perm    NUMBER := SQL_HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, security.security_pkg.PERMISSION_READ);
BEGIN
    OPEN out_cur FOR
        SELECT iafd.internal_audit_file_data_id, iaf.internal_audit_sid, iafd.filename, iafd.mime_type,
               cast(iafd.sha1 as varchar2(40)) sha1, iafd.uploaded_dtm
          FROM internal_audit_file iaf
          JOIN internal_audit_file_data iafd
            ON iafd.internal_audit_file_data_id = iaf.internal_audit_file_data_id
          JOIN internal_audit ia
            ON iaf.internal_audit_sid = ia.internal_audit_sid
          JOIN TABLE(
                v_table
                ) so ON ia.internal_audit_sid = so.column_value
          JOIN internal_audit_type iat
            ON ia.internal_audit_type_id = iat.internal_audit_type_id
         WHERE iat.internal_audit_type_source_id = NVL(in_internal_audit_source_id, iat.internal_audit_type_source_id)
           AND ia.internal_audit_sid = in_internal_audit_sid
           AND (ia.flow_item_id IS NULL OR v_cap_audit_docs_perm = 1);
END;

FUNCTION CheckAccessCreateAudit
RETURN security_pkg.T_SID_ID
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_admins_sid            security_pkg.T_SID_ID;
BEGIN
    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
                SYS_CONTEXT('SECURITY','APP'),
                security_pkg.SO_CONTAINER,
                'Audits',
                v_audits_sid
            );
            -- allow administrators access
            BEGIN
                v_admins_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Groups/Administrators');
                acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), acl_pkg.GetDACLIDForSID(v_audits_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
                    security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_READ);
            EXCEPTION
                WHEN security_pkg.OBJECT_NOT_FOUND THEN
                    -- skip if no administrators group
                    NULL;
            END;
    END;
    RETURN v_audits_sid;
END;

PROCEDURE GetAuditTypeCarryForwards (
    out_cur                        OUT    SYS_REFCURSOR
)
AS
BEGIN
    -- no security, these aren't secret
    OPEN out_cur FOR
        SELECT from_internal_audit_type_id, to_internal_audit_type_id
          FROM internal_audit_type_carry_fwd
      ORDER BY from_internal_audit_type_id, to_internal_audit_type_id;
END;

PROCEDURE SetAuditTypeCarryForwards (
    in_to_ia_type_id            IN    internal_audit.internal_audit_type_id%TYPE,
    in_from_ia_type_ids            IN    security_pkg.T_SID_IDS
)
AS
    v_audits_sid                    security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_keeper_id_tbl                    security.T_SID_TABLE;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit type carry forwards');
    END IF;
    
    -- crap hack for ODP.NET
    IF in_from_ia_type_ids IS NULL OR (in_from_ia_type_ids.COUNT = 1 AND in_from_ia_type_ids(1) IS NULL) THEN
        v_keeper_id_tbl := security.T_SID_TABLE();
    ELSE
        v_keeper_id_tbl := security_pkg.SidArrayToTable(in_from_ia_type_ids);
    END IF;
    
    DELETE FROM internal_audit_type_carry_fwd
    WHERE to_internal_audit_type_id = in_to_ia_type_id;
    
    INSERT INTO internal_audit_type_carry_fwd (from_internal_audit_type_id, to_internal_audit_type_id)
    SELECT column_value, in_to_ia_type_id FROM TABLE(v_keeper_id_tbl);
END;

PROCEDURE GetSidOfAuditToCarryForward (
    in_region_sid                IN    internal_audit.region_sid%TYPE,
    in_internal_audit_type        IN    internal_audit.internal_audit_type_id%TYPE,
    in_audit_dtm                IN    internal_audit.audit_dtm%TYPE,
    out_carry_from_audit_sid    OUT    security_pkg.T_SID_ID,
    out_label                    OUT    internal_audit.label%TYPE
)
AS
    v_table                        security.T_SID_TABLE := GetAuditsForUserAsTable;
BEGIN
    -- Find the audit we may carry forward Non-compliances, Postits, Documents from
    BEGIN
        -- First criterion: audit which is the latest (rn = 1)
        SELECT x.internal_audit_sid, x.label
        INTO out_carry_from_audit_sid, out_label
          FROM (
            SELECT ia.internal_audit_sid, label, ROW_NUMBER() OVER (ORDER BY ia.audit_dtm DESC) rn
              FROM internal_audit ia
              JOIN internal_audit_type_carry_fwd iatcf 
                ON ia.internal_audit_type_id = iatcf.from_internal_audit_type_id
              -- This filters by permission and filters out items in the trash
              JOIN TABLE(
                    v_table
                    ) so ON ia.internal_audit_sid = so.column_value
             WHERE ia.region_sid = in_region_sid
               AND ia.region_sid IS NOT NULL
               AND ia.auditee_user_sid IS NULL
               AND iatcf.to_internal_audit_type_id = in_internal_audit_type
          ) x
        WHERE rn = 1
        AND (
            in_audit_dtm IS NULL OR EXISTS ( -- Second criterion: audit must be before our new audit ( < in_audit_dtm)
                SELECT NULL
                  FROM internal_audit ia
                 WHERE ia.internal_audit_sid = x.internal_audit_sid
                   AND ia.audit_dtm < in_audit_dtm
            )
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            out_carry_from_audit_sid := -1;
            out_label := NULL;
    END;
END;

PROCEDURE GetAuditsToCarryForward (
    in_carry_to_audit_type_id    IN    internal_audit.internal_audit_type_id%TYPE,
    out_cur                        OUT    SYS_REFCURSOR
)
AS
    v_table                        security.T_SID_TABLE := GetAuditsForUserAsTable;
BEGIN
    OPEN out_cur FOR
        SELECT region_sid, internal_audit_sid, audit_dtm
          FROM (
            SELECT ia.region_sid, ia.internal_audit_sid, ia.audit_dtm, ROW_NUMBER() OVER (PARTITION BY ia.region_sid ORDER BY ia.audit_dtm DESC) rn
              FROM internal_audit ia
              -- This filters by permission and filters out items in the trash
              JOIN TABLE(
                    v_table
                 ) so ON ia.internal_audit_sid = so.column_value
              JOIN internal_audit_type_carry_fwd iatcf ON iatcf.from_internal_audit_type_id = ia.internal_audit_type_id
             WHERE ia.region_sid IS NOT NULL
               AND ia.auditee_user_sid IS NULL
               AND iatcf.to_internal_audit_type_id = in_carry_to_audit_type_id
          ) x
        WHERE rn = 1;
END;

PROCEDURE GetResponsesToCarryForward (
    in_carry_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_survey_sids                IN    security_pkg.T_SID_IDS,
    in_region_sid                IN    security_pkg.T_SID_ID,
    in_audit_dtm                IN    DATE,
    out_cur                        OUT    SYS_REFCURSOR
)
AS
    t_survey_sids                security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_survey_sids);
    v_can_read_audit_surveys    NUMBER(10);
BEGIN
    v_can_read_audit_surveys := SQL_HasCapabilityAccess(in_carry_from_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security.security_pkg.PERMISSION_READ);

    /* TODO: just start again... 
        1.    The query seems to be doing a lot of duplicating, particularly the subqueries to get the submissions to copy forward. The whole query needs restructuring,
            but that probably means doing more work in C# putting in the work to understand what the code as a whole does at the moment and what it should do after a
            restructure.
        2.    We return the version of the response, not the submission that we are (I hope) actually copying forward. This is probably wrong and needs a separate defect.
        3.    The permission checks done in WHERE clauses are just flaky (e.g. quick_survey_pkg.GetResponseAccess throws an error if the response has hidden = 1, which
            caused DE11625) and probably a performance bottleneck, and mean you have to ensure the subquery is limited to a minimal set to avoid permission checks on
            responses you don't care about. It's just a bad pattern. Again, see point 1.
    */
    OPEN out_cur FOR
        SELECT ia_type_survey_group_id, internal_audit_type_survey_id, survey_response_id, survey_sid, survey_label, submitted_dtm, submitted_by, campaign_name,
            CASE WHEN rn = 1 THEN 1 ELSE 0 END selected
        FROM (
            SELECT reg_resp.ia_type_survey_group_id, reg_resp.internal_audit_type_survey_id, qsr.survey_response_id, qsv.survey_sid, qsv.label survey_label, qss.submitted_dtm, u.full_name submitted_by, reg_resp.campaign_name,
                ROW_NUMBER() OVER (PARTITION BY qsr.survey_sid ORDER BY qss.submitted_dtm DESC) rn
              FROM quick_survey_response qsr
              JOIN quick_survey_submission qss
                ON qss.survey_response_id = qsr.survey_response_id
               AND qss.submission_id = qsr.last_submission_id
              JOIN quick_survey_version qsv
                ON qsv.survey_sid = qsr.survey_sid
               AND qsv.survey_version = qsr.survey_version
              JOIN TABLE(t_survey_sids) t
                ON t.column_value = qsr.survey_sid
              JOIN csr_user u 
                ON u.csr_user_sid = qss.submitted_by_user_sid
              -- This is where we actually get the available responses to copy. The previous stuff is just getting the most recent submission for these responses
              -- and any additional data to return to the user
              JOIN (
                -- First, get the most recent campaign responses for the relevant surveys
                SELECT NULL ia_type_survey_group_id, NULL internal_audit_type_survey_id, survey_response_id, survey_sid, campaign_name
                  FROM (
                    SELECT rsr.survey_response_id, qsr.survey_sid, qsc.name campaign_name,
                        ROW_NUMBER() OVER (
                            PARTITION BY rsr.region_sid, rsr.survey_sid
                            ORDER BY qss.submitted_dtm DESC
                        ) rn
                      FROM region_survey_response rsr
                      JOIN quick_survey_submission qss
                        ON rsr.survey_response_id = qss.survey_response_id
                      JOIN quick_survey_response qsr
                        ON qsr.survey_response_id = rsr.survey_response_id
                      JOIN TABLE(t_survey_sids) t
                        ON t.column_value = qsr.survey_sid
                      JOIN campaigns.campaign qsc
                        ON qsc.campaign_sid = qsr.qs_campaign_sid
                     WHERE rsr.region_sid = in_region_sid
                       AND qss.submitted_dtm IS NOT NULL
                       AND rsr.period_start_dtm <= in_audit_dtm
                       -- Only consider responses that are not hidden for copy forward, so if the most recent submission
                       -- is hidden we disregard it rather than say there is nothing to copy forward
                       AND qsr.hidden = 0
                    )
                 WHERE rn = 1
                   AND quick_survey_pkg.GetResponseAccess(survey_response_id) IN (security_pkg.PERMISSION_READ, security_pkg.PERMISSION_WRITE)
                 UNION
                -- Now get the primary survey response for the most recent audit if relevant and allowed
                SELECT NULL ia_type_survey_group_id, PRIMARY_AUDIT_TYPE_SURVEY_ID internal_audit_type_survey_id, ia.survey_response_id, qsr.survey_sid, NULL
                  FROM internal_audit ia
                  JOIN quick_survey_response qsr ON qsr.survey_response_id = ia.survey_response_id
                  JOIN TABLE(t_survey_sids) t
                    ON t.column_value = qsr.survey_sid
                 WHERE ia.internal_audit_sid = in_carry_from_audit_sid
                   AND (v_can_read_audit_surveys = 1 OR ia.flow_item_id IS NULL)
                   AND qsr.hidden = 0
                 UNION
                -- Now get any secondary survey responses for the most recent audit if relevant and allowed
                SELECT iatsg.ia_type_survey_group_id, ias.internal_audit_type_survey_id, ias.survey_response_id, qsr.survey_sid, NULL
                  FROM internal_audit_survey ias
                  JOIN quick_survey_response qsr ON qsr.survey_response_id = ias.survey_response_id
                  JOIN TABLE(t_survey_sids) t
                    ON t.column_value = qsr.survey_sid
                  JOIN internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
                  JOIN internal_audit_type_survey iast ON iast.internal_audit_type_id = ia.internal_audit_type_id AND iast.internal_audit_type_survey_id = ias.internal_audit_type_survey_id
                  LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iast.ia_type_survey_group_id
                 WHERE ia.internal_audit_sid = in_carry_from_audit_sid
                   AND qsr.hidden = 0
                   AND (
                        ia.flow_item_id IS NULL OR
                        (iatsg.survey_capability_id IS NULL AND v_can_read_audit_surveys = 1) OR
                        (iatsg.survey_capability_id IS NOT NULL AND SQL_HasCapabilityAccess(ia.internal_audit_sid, iatsg.survey_capability_id, security.security_pkg.PERMISSION_READ) = 1)
                   )
              ) reg_resp 
                ON reg_resp.survey_response_id = qsr.survey_response_id
             )
         ORDER BY survey_label, submitted_dtm DESC;
END;

PROCEDURE CheckForCarryForward (
    in_carry_from_audit_sid        IN    security_pkg.T_SID_ID,
    in_carry_to_audit_type_id    IN    internal_audit.internal_audit_type_id%TYPE,
    out_cur                        OUT    SYS_REFCURSOR,
    out_cur_documents            OUT    SYS_REFCURSOR,
    out_cur_postits                OUT    SYS_REFCURSOR
)
AS
    v_audits_sid                security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_permissible_nct_ids        security.T_SID_TABLE := GetPermissibleNCTypeIds(in_carry_from_audit_sid, security.security_pkg.PERMISSION_READ);
    v_cap_anc                     NUMBER := SQL_HasCapabilityAccess(in_carry_from_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security.security_pkg.PERMISSION_READ);
BEGIN
    -- Check that user can add/create audits
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create audits');
    END IF;
    
    -- Open non-compliances to carry forward
    OPEN out_cur FOR
        SELECT n.non_compliance_id, n.non_compliance_type_id, n.label, n.created_dtm, onca.open_non_compliance_actions, n.can_carry_forward
          FROM (
                SELECT nc.non_compliance_id, nc.non_compliance_type_id, nc.label, nc.created_dtm,
                       CASE WHEN nc.non_compliance_type_id IS NULL OR nctat.non_compliance_type_id IS NOT NULL THEN 1 ELSE 0 END can_carry_forward
                  FROM audit_non_compliance anc
                  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
                    LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
                  LEFT JOIN non_comp_type_audit_type nctat ON nctat.non_compliance_type_id = nc.non_compliance_type_id
                                                          AND nctat.internal_audit_type_id = in_carry_to_audit_type_id
                 WHERE anc.internal_audit_sid = in_carry_from_audit_sid
                   AND (
                        (nc.non_compliance_type_id IS NULL AND v_cap_anc = 1) OR 
                        (nc.non_compliance_type_id IS NOT NULL AND pnct.column_value IS NOT NULL)
                   )
        ) n JOIN (
                SELECT nc.non_compliance_id, count(distinct i.issue_non_compliance_id) open_non_compliance_actions
                  FROM audit_non_compliance anc
                  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
                  LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
                  LEFT JOIN issue_non_compliance inc  ON inc.non_compliance_id = anc.non_compliance_id
                  LEFT JOIN issue i ON i.issue_non_compliance_id = inc.issue_non_compliance_id
                 WHERE anc.internal_audit_sid = in_carry_from_audit_sid
                   AND (
                        (nc.non_compliance_type_id IS NULL AND v_cap_anc = 1) OR 
                        (nc.non_compliance_type_id IS NOT NULL AND pnct.column_value IS NOT NULL)
                   )
                   AND ((nc.is_closed IS NULL
                   AND i.resolved_dtm IS NULL
                   AND i.rejected_dtm IS NULL
                   AND i.deleted = 0)
                    OR nc.is_closed = 0)
              GROUP BY nc.non_compliance_id
        ) onca ON n.non_compliance_id = onca.non_compliance_id
        ORDER BY n.created_dtm, n.non_compliance_id;

    -- Documents to carry forward
    OPEN out_cur_documents FOR
        SELECT iafd.filename
          FROM internal_audit_file iaf
          JOIN internal_audit_file_data iafd
            ON iafd.internal_audit_file_data_id = iaf.internal_audit_file_data_id
          JOIN internal_audit ia
            ON ia.internal_audit_sid = iaf.internal_audit_sid
         WHERE iaf.internal_audit_sid = in_carry_from_audit_sid;

    -- Postits to carry forward
    OPEN out_cur_postits FOR
        SELECT p.message, pf.filename
          FROM internal_audit_postit iap
          JOIN postit p
            ON p.postit_id = iap.postit_id
          JOIN internal_audit ia
            ON ia.internal_audit_sid = iap.internal_audit_sid
          LEFT JOIN postit_file pf
            on pf.postit_id = p.postit_id
         WHERE iap.internal_audit_sid = in_carry_from_audit_sid;
END;

PROCEDURE UNSEC_SyncRegionsForUser(
    in_user_sid        IN    security_pkg.T_SID_ID
)
AS
BEGIN
    FOR r IN (
        SELECT ia.internal_audit_sid, u.primary_region_sid
          FROM internal_audit ia
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
          JOIN internal_audit_type_group iatg ON iatg.internal_audit_type_group_id = iat.internal_audit_type_group_id
          JOIN csr_user u ON u.csr_user_sid = ia.auditee_user_sid
         WHERE iatg.use_user_primary_region = 1
           AND ia.auditee_user_sid = in_user_sid
    ) LOOP
        UPDATE internal_audit
           SET region_sid = r.primary_region_sid
         WHERE internal_audit_sid = r.internal_audit_sid;

        TriggerAuditAgg(r.internal_audit_sid);
    END LOOP;
END;

PROCEDURE ApplyAuditTypeToRegionSid(
    in_region_sid            IN    internal_audit.region_sid%TYPE,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_auditee_user_sid        IN    security_pkg.T_SID_ID DEFAULT NULL,
    out_region_sid            OUT    internal_audit.region_sid%TYPE
)
AS
    v_use_user_primary_region    internal_audit_type_group.use_user_primary_region%TYPE;
BEGIN
    SELECT iatg.use_user_primary_region
      INTO v_use_user_primary_region
      FROM internal_audit_type iat 
      LEFT JOIN internal_audit_type_group iatg ON iatg.internal_audit_type_group_id = iat.internal_audit_type_group_id
     WHERE internal_audit_type_id = in_internal_audit_type;

    IF v_use_user_primary_region = 1 THEN
        SELECT primary_region_sid
          INTO out_region_sid
          FROM csr.csr_user
         WHERE csr_user_sid = in_auditee_user_sid;
    ELSE
        out_region_sid := in_region_sid;
    END IF;
END;

FUNCTION CheckPreserve_ (
    in_new_value            NUMBER,
    in_old_value            NUMBER
) RETURN NUMBER
AS
BEGIN
    IF in_new_value = csr_data_pkg.PRESERVE_NUMBER THEN
        RETURN in_old_value;
    END IF;
    RETURN in_new_value;
END;

PROCEDURE Save(
    in_sid_id                    IN    internal_audit.internal_audit_sid%TYPE,
    in_audit_ref                IN    internal_audit.internal_audit_ref%TYPE,
    in_survey_sid                IN    internal_audit.survey_sid%TYPE,
    in_region_sid                IN    internal_audit.region_sid%TYPE,
    in_label                    IN    internal_audit.label%TYPE,
    in_audit_dtm                IN    internal_audit.audit_dtm%TYPE,
    in_auditor_user_sid            IN    internal_audit.auditor_user_sid%TYPE,
    in_notes                    IN    internal_audit.notes%TYPE,
    in_internal_audit_type        IN    internal_audit.internal_audit_type_id%TYPE,
    in_auditor_name                IN    internal_audit.auditor_name%TYPE,
    in_auditor_org                IN    internal_audit.auditor_organisation%TYPE,
    in_response_to_audit        IN    internal_audit.comparison_response_id%TYPE DEFAULT NULL,
    in_created_by_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_auditee_user_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_auditee_company_sid        IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_auditor_company_sid        IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_created_by_company_sid    IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_permit_id                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_external_audit_ref        IN    internal_audit.external_audit_ref%TYPE DEFAULT NULL,
    in_external_parent_ref        IN    internal_audit.external_parent_ref%TYPE DEFAULT NULL,
    in_external_url                IN    internal_audit.external_url%TYPE DEFAULT NULL,
    out_sid_id                    OUT    internal_audit.internal_audit_sid%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
    v_flow_item_id                flow_item.flow_item_id%TYPE;
    v_response_id                NUMBER;
    v_is_new                    NUMBER;
    v_sid                        security_pkg.T_SID_ID;
    v_region_sid                security_pkg.T_SID_ID DEFAULT in_region_sid;
    v_auditee_user_sid            security_pkg.T_SID_ID;
    v_survey_sid                security_pkg.T_SID_ID;
    v_internal_audit_type_label    internal_audit_type.label%TYPE;
    v_involve_auditor_in_issues    internal_audit_type.involve_auditor_in_issues%TYPE;
    v_auditor_org                internal_audit.auditor_organisation%TYPE := in_auditor_org;

    v_created_by_sid            security_pkg.T_SID_ID := NVL(in_created_by_sid, SYS_CONTEXT('SECURITY', 'SID'));
    v_created_by_company_sid    security_pkg.T_SID_ID := NVL(in_created_by_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
    v_old_notes                    VARCHAR2(100 CHAR);
    v_new_notes                    VARCHAR2(100 CHAR);
    v_old_auditor_sid            security_pkg.T_SID_ID;
    v_old_auditor_company_sid    security_pkg.T_SID_ID;
    v_is_auditor_company_top    chain.company_type.is_top_company%TYPE;
    v_audit_ref                 internal_audit.internal_audit_ref%TYPE;
    v_is_chain_enabled             NUMBER;
    v_supplier_company_sid         security_pkg.T_SID_ID;
    v_auditor_company_sid        security_pkg.T_SID_ID DEFAULT NVL(in_auditor_company_sid, v_created_by_company_sid);
    v_auditor_user_sid            security_pkg.T_SID_ID := in_auditor_user_sid;
    v_auditor_name                csr.internal_audit.auditor_name%TYPE := in_auditor_name;
    v_temp_auditor_company_sid    security_pkg.T_SID_ID;
    v_other_audit_count            NUMBER;
    v_dummy_cur                    SYS_REFCURSOR;
    CURSOR c IS
        SELECT app_sid, label, region_sid, auditee_user_sid, audit_dtm, auditor_user_sid, survey_sid,
               internal_audit_type_id, auditor_name, auditor_organisation, notes, flow_item_id
          FROM internal_audit ia
         WHERE ia.internal_audit_sid = in_sid_id;
    r c%ROWTYPE;
BEGIN
    -- TODO: remove the company context check once we've determined it is ok to enable the force_logon_as_company
    -- customer option on all chain/property sites
    IF chain.helper_pkg.IsChainSite = 1 AND SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NOT NULL THEN
        v_created_by_company_sid := NVL(v_created_by_company_sid, chain.helper_pkg.GetTopCompanySid);
        v_auditor_company_sid := NVL(v_auditor_company_sid, v_created_by_company_sid);

        IF v_auditor_user_sid IS NULL AND v_auditor_company_sid IS NOT NULL THEN
            -- favour users that are active
            BEGIN
                SELECT user_sid, full_name
                  INTO v_auditor_user_sid, v_auditor_name
                  FROM (
                    SELECT ca.user_sid, ca.full_name              
                      FROM chain.v$company_admin ca
                     WHERE company_sid = v_auditor_company_sid
                     ORDER BY account_enabled DESC
                       )
                 WHERE ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20001, 'Could not find an admin for company with sid: '  || v_auditor_company_sid);
            END;
        END IF;
    
        IF v_auditor_org IS NULL AND v_auditor_company_sid IS NOT NULL THEN
            v_auditor_org := SUBSTR(chain.company_pkg.GetCompanyName(v_auditor_company_sid), 0, 50);
        END IF;
    END IF;
    
    IF v_region_sid IS NULL AND in_auditee_company_sid IS NOT NULL THEN
        SELECT region_sid
          INTO v_region_sid
          FROM supplier
         WHERE company_sid = in_auditee_company_sid;
    ELSIF v_region_sid IS NOT NULL THEN
        SELECT COALESCE(link_to_region_sid, region_sid)
          INTO v_region_sid
          FROM region
         WHERE region_sid = v_region_sid;
    END IF;

    -- if no label is supplied then default it to the audit type
    SELECT label
      INTO v_internal_audit_type_label
      FROM internal_audit_type
     WHERE internal_audit_type_id = in_internal_audit_type;
    
    IF in_sid_id IS NULL THEN
        v_audits_sid := CheckAccessCreateAudit;
        
        SecurableObject_pkg.CreateSO(
            SYS_CONTEXT('SECURITY', 'ACT'),
            v_audits_sid,
            class_pkg.GetClassId('CSRAudit'),
            NULL, -- Don't make the name unique
            out_sid_id);

        v_survey_sid := in_survey_sid;

        ApplyAuditTypeToRegionSid(v_region_sid, in_internal_audit_type, in_auditee_user_sid, v_region_sid);

        -- if we're using multiple surveys, then we set this with SetAuditSurvey instead.
        IF MultipleSurveysEnabled() THEN
            SELECT default_survey_sid
              INTO v_survey_sid
              FROM internal_audit_type
             WHERE internal_audit_type_id = in_internal_audit_type;
        END IF;

        INSERT INTO internal_audit (
            internal_audit_sid, survey_sid, region_sid, auditee_user_sid, label, audit_dtm,
            auditor_user_sid, notes, internal_audit_type_id, auditor_name,
            auditor_organisation, comparison_response_id, created_by_user_sid, auditor_company_sid, permit_id)
        VALUES (
            out_sid_id, v_survey_sid, v_region_sid, in_auditee_user_sid, NVL(in_label, v_internal_audit_type_label), in_audit_dtm,
            v_auditor_user_sid, in_notes, in_internal_audit_type, v_auditor_name,
            v_auditor_org, in_response_to_audit, v_created_by_sid, v_auditor_company_sid, in_permit_id);

        flow_pkg.AddAuditItem(out_sid_id, v_flow_item_id);    

        -- Rolls back the creation of the audit SO if user doesn't have roles on the regions.
        IF NOT HasWriteAccess(out_sid_id) THEN
            RAISE_APPLICATION_ERROR(ERR_REGION_AUDIT, 'You do not have permission to create an audit on this region.');
        END IF;

        IF in_response_to_audit IS NOT NULL THEN
            GetOrCreateSurveyResponse(out_sid_id, PRIMARY_AUDIT_TYPE_SURVEY_ID, NULL, v_is_new, v_sid, v_response_id);
            quick_survey_pkg.CopyResponse(in_response_to_audit, NULL, v_response_id);
        END IF;

        IF MultipleSurveysEnabled() THEN
            INSERT INTO internal_audit_survey (internal_audit_sid, internal_audit_type_survey_id, survey_sid)
            SELECT out_sid_id internal_audit_sid, internal_audit_type_survey_id, default_survey_sid survey_sid
              FROM internal_audit_type_survey
             WHERE internal_audit_type_id = in_internal_audit_type
               AND active = 1
               AND default_survey_sid IS NOT NULL;
        END IF;

        csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'), out_sid_id,
            'Audit created: {0} ({1})', in_label, out_sid_id);

        TriggerAuditAgg(TRUNC(in_audit_dtm,'MONTH'), ADD_MONTHS(TRUNC(in_audit_dtm,'MONTH'),1));

        INTERNAL_CallHelperPkg('AuditCreated', out_sid_id);
        RecalculateAuditNCScore(out_sid_id);
        
        IF in_audit_ref IS NULL OR in_audit_ref = csr_data_pkg.PRESERVE_NUMBER THEN
            INTERNAL_CreateRefID_Audit(out_sid_id);
        ELSE
            SetAuditRef(out_sid_id, in_audit_ref);
        END IF;
        
        SetExternalRef(out_sid_id, in_external_audit_ref, in_external_parent_ref, in_external_url);
        
        chain.filter_pkg.ClearCacheForAllUsers (
            in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
        );

        SaveSupplierAudit(
            in_internal_audit_sid        => out_sid_id,
            in_auditee_company_sid        => in_auditee_company_sid,
            in_auditor_company_sid        => v_auditor_company_sid,
            in_created_by_company_sid    => v_created_by_company_sid
        );
        
        RETURN;
    END IF;

    IF NOT HasWriteAccess(in_sid_id) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the audit with sid '||in_sid_id);
    END IF;

    OPEN c;
    FETCH c INTO r;
    IF c%NOTFOUND THEN
        RETURN;
    END IF;

    -- Audit changes
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Label', r.label, in_label);
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Audit date', r.audit_dtm, in_audit_dtm);
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Auditor user SID', r.auditor_user_sid, v_auditor_user_sid);
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Audit type ID', r.internal_audit_type_id, in_internal_audit_type);
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Auditor name', r.auditor_name, v_auditor_name);
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Auditor organisation', r.auditor_organisation, v_auditor_org);

    IF DBMS_LOB.getLength(r.notes) > 100 THEN
        v_old_notes := TO_CHAR(DBMS_LOB.SUBSTR(r.notes, 97))||'...';
    ELSE
        v_old_notes := TO_CHAR(r.notes);
    END IF;

    IF DBMS_LOB.getLength(in_notes) > 100 THEN
        v_new_notes := TO_CHAR(DBMS_LOB.SUBSTR(in_notes, 97))||'...';
    ELSE
        v_new_notes := TO_CHAR(in_notes);
    END IF;
    
    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
        in_sid_id, 'Notes', v_old_notes, v_new_notes);

    v_region_sid := r.region_sid;
    v_auditee_user_sid := r.auditee_user_sid;

    IF r.flow_item_id IS NULL OR HasCapabilityAccess(in_sid_id, csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE, security_pkg.PERMISSION_WRITE) THEN
        v_auditee_user_sid := in_auditee_user_sid;
        ApplyAuditTypeToRegionSid(v_region_sid, in_internal_audit_type, v_auditee_user_sid, v_region_sid);

        csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, r.app_sid,
            in_sid_id, 'Auditee user SID', r.auditee_user_sid, in_auditee_user_sid);
    END IF;
    
    SELECT ia.auditor_user_sid, ia.auditor_company_sid, iat.involve_auditor_in_issues
      INTO v_old_auditor_sid, v_old_auditor_company_sid, v_involve_auditor_in_issues
      FROM internal_audit ia
      JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
     WHERE internal_audit_sid = in_sid_id;

    BEGIN
        SELECT internal_audit_ref, auditor_company_sid
          INTO v_audit_ref, v_temp_auditor_company_sid
          FROM internal_audit
         WHERE internal_audit_sid = in_sid_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_audit_ref := NULL;
    END;

    v_audit_ref := CheckPreserve_(in_audit_ref, v_audit_ref);
    IF in_auditor_company_sid IS NULL THEN
        v_auditor_company_sid := v_temp_auditor_company_sid;
    END IF;

    UPDATE internal_audit
       SET internal_audit_ref = v_audit_ref,
           label = NVL(in_label, v_internal_audit_type_label),
           audit_dtm = in_audit_dtm,
           auditor_user_sid = v_auditor_user_sid,
           notes = in_notes,
           auditor_name = v_auditor_name,
           auditor_organisation = v_auditor_org,
           auditor_company_sid = v_auditor_company_sid,
           external_audit_ref = in_external_audit_ref,
           external_parent_ref = in_external_parent_ref,
           external_url = in_external_url
     WHERE internal_audit_sid = in_sid_id;    

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The audit with sid '||in_sid_id||' could not be found');
    END IF;
    
    IF v_auditor_user_sid != v_old_auditor_sid THEN
        chain.filter_pkg.ClearCacheForUser (
            in_card_group_id    => chain.filter_pkg.FILTER_TYPE_AUDITS,
            in_user_sid         => v_auditor_user_sid
        );
        
        chain.filter_pkg.ClearCacheForUser (
            in_card_group_id    => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES,
            in_user_sid            => v_auditor_user_sid
        );
        
        chain.filter_pkg.ClearCacheForUser (
            in_card_group_id    => chain.filter_pkg.FILTER_TYPE_AUDITS,
            in_user_sid            => v_old_auditor_sid
        );
        
        chain.filter_pkg.ClearCacheForUser (
            in_card_group_id    => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES,
            in_user_sid            => v_old_auditor_sid
        );
    END IF;

    -- Update intermediary company involvement in issues where appropriate
    IF in_auditor_company_sid != v_old_auditor_company_sid AND v_involve_auditor_in_issues = 1 THEN
        SELECT ct.is_top_company
          INTO v_is_auditor_company_top
          FROM chain.company c
          JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
         WHERE c.company_sid = in_auditor_company_sid;
        
        FOR r IN (
            SELECT i.issue_id, COUNT (DISTINCT anc2.internal_audit_sid) audit_count
              FROM audit_non_compliance anc
              JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id
              JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
              JOIN issue_non_compliance inc2 ON i.issue_non_compliance_id = inc2.issue_non_compliance_id
              JOIN audit_non_compliance anc2 ON inc2.non_compliance_id = anc2.non_compliance_id
             WHERE anc.internal_audit_sid = in_sid_id
          GROUP BY i.issue_id
        ) LOOP
            SELECT COUNT(*)
              INTO v_other_audit_count
              FROM csr.issue i
              JOIN csr.issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id
              JOIN csr.audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id
              JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
             WHERE i.issue_id = r.issue_id
               AND anc.internal_audit_sid != in_sid_id
               AND ia.auditor_company_sid = v_old_auditor_company_sid;

            IF v_other_audit_count = 0 THEN
                -- Only remove the previous auditor company involvement if there are no other audits
                -- linked to the issue that also involve the previous auditor company
                issue_pkg.RemoveCompany(
                    in_issue_id        => r.issue_id,
                    in_company_sid     => v_old_auditor_company_sid);
            END IF;

            IF v_is_auditor_company_top = 0 THEN
                -- Note that the following sproc will only involve the company if it is not yet involved
                -- and so we don't need to check here whether the new auditor company is already involved
                issue_pkg.AddCompany(
                    in_issue_id        => r.issue_id,
                    in_company_sid    => in_auditor_company_sid,
                    out_cur            => v_dummy_cur);
            END If;
        END LOOP;
    END IF;
            
         
    -- if we're using multiple surveys, then we set this with SetAuditSurvey instead.
    IF NOT MultipleSurveysEnabled() THEN
        UPDATE internal_audit
           SET survey_sid = in_survey_sid,
               survey_response_id = CASE WHEN in_survey_sid = r.survey_sid THEN survey_response_id ELSE NULL END
         WHERE internal_audit_sid = in_sid_id;
    END IF;

    TriggerAuditAgg(TRUNC(LEAST(r.audit_dtm, in_audit_dtm),'MONTH'), ADD_MONTHS(TRUNC(GREATEST(r.audit_dtm, in_audit_dtm),'MONTH'),1));

    INTERNAL_CallHelperPkg('AuditUpdated', in_sid_id);
    RecalculateAuditNCScore(in_sid_id);

    SaveSupplierAudit(
        in_internal_audit_sid => in_sid_id,
        in_auditee_company_sid => in_auditee_company_sid,
        in_auditor_company_sid => v_auditor_company_sid,
        in_created_by_company_sid => in_created_by_company_sid
    );

    out_sid_id := in_sid_id;
END;

PROCEDURE SaveSupplierAudit (
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_auditee_company_sid        IN    security_pkg.T_SID_ID,
    in_auditor_company_sid        IN    security_pkg.T_SID_ID,
    in_created_by_company_sid    IN    security_pkg.T_SID_ID
)
AS
    v_created_by_company_sid    security_pkg.T_SID_ID;
    v_auditee_company_sid        security_pkg.T_SID_ID DEFAULT in_auditee_company_sid;
    v_supplier_company_sid        security_pkg.T_SID_ID;
    v_active                    chain.supplier_relationship.active%TYPE;
    v_ucd_sid                    security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon');
BEGIN
    
    IF (NOT chain.helper_pkg.IsChainSite = 1) OR (SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL) THEN 
        RETURN;
    END IF;

    SELECT s.company_sid
      INTO v_supplier_company_sid
      FROM internal_audit ia
      LEFT JOIN supplier s ON s.region_sid = ia.region_sid
     WHERE ia.internal_audit_sid = in_internal_audit_sid;

    --check auditee company data input for inconsistencies (as we store redundant data in separate tables)
    IF v_supplier_company_sid IS NULL THEN
        IF v_auditee_company_sid IS NULL THEN
            RETURN;
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'You cannot create a supplier audit for company with sid:'|| v_auditee_company_sid || ' as the auditee region is not linked to a supplier.');
        END IF;
    ELSE 
        IF v_auditee_company_sid IS NULL THEN
            v_auditee_company_sid := v_supplier_company_sid;
        ELSIF v_supplier_company_sid <> v_auditee_company_sid THEN
            RAISE_APPLICATION_ERROR(-20001, 'Inconsistent data. Supplier company sid:' || v_supplier_company_sid ||' and auditee company sid:'||v_auditee_company_sid|| ' do not match');
        END IF;
    END IF;

    IF NOT chain.helper_pkg.UseTypeCapabilities THEN
        RAISE_APPLICATION_ERROR(-20001, 'SaveSupplierAudit can be applied only for type capabilities');
    END IF;

    v_created_by_company_sid := in_created_by_company_sid;
    IF in_created_by_company_sid IS NULL THEN
        v_created_by_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
    END IF;
    
    -- There is a special case whereby the audits are being imported by a super admin using the import page.
    -- In this case a relationship between auditor and auditee still needs to be created but the check on the company
    -- creating the supplier audit should be skipped. This is the only case where the "created by"
    -- company may not be the company of the logged in user (context company). It is assumed that the import would be
    -- run while logged in as top company but we do not enforce that.
    IF v_created_by_company_sid IS NULL THEN
        RETURN;
    END IF;

    -- Create a supplier audit 
    IF v_auditee_company_sid IS NOT NULL THEN
        
        IF in_created_by_company_sid <> in_auditor_company_sid THEN
            --it is an 'on behalf' action
            
            -- If there isn't an active relationship between auditor and supplier then create one
            SELECT MIN(sr.active)
              INTO v_active
              FROM chain.supplier_relationship sr
             WHERE purchaser_company_sid = in_auditor_company_sid
               AND supplier_company_sid = v_auditee_company_sid
               AND deleted = 0;
            
            IF v_active IS NULL OR v_active = 0 THEN
                -- This checks logged in user can create the relationship. Calling start/activate relationship doesn't
                chain.company_pkg.EstablishRelationship(
                    in_purchaser_company_sid        => in_auditor_company_sid,
                    in_supplier_company_sid            => v_auditee_company_sid
                );
            END IF;
            
            IF security.user_pkg.IsSuperAdmin != 1 AND SYS_CONTEXT('SECURITY', 'SID') != v_ucd_sid THEN
                IF NOT chain.type_capability_pkg.CheckCapability(v_created_by_company_sid, in_auditor_company_sid, v_auditee_company_sid, chain.chain_pkg.CREATE_SUPPL_AUDIT_ON_BEHLF_OF) THEN
                    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to company with sid:' || v_created_by_company_sid || ' creating a supplier audit for the auditor with sid:' || in_auditor_company_sid || ' against the supplier with sid:' || v_auditee_company_sid);
                END IF;
            END IF;
        ELSIF security.user_pkg.IsSuperAdmin != 1 AND SYS_CONTEXT('SECURITY', 'SID') != v_ucd_sid THEN
            IF NOT chain.type_capability_pkg.CheckCapability(v_created_by_company_sid, v_auditee_company_sid, chain.chain_pkg.CREATE_SUPPLIER_AUDITS) THEN
                RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to company with sid:' || v_created_by_company_sid || ' creating a supplier audit for the auditor with sid:' || in_auditor_company_sid || ' against the supplier with sid:' || v_auditee_company_sid);
            END IF;
        END IF;

        BEGIN
            INSERT INTO chain.supplier_audit(app_sid, audit_sid, auditor_company_sid, supplier_company_sid, created_by_company_sid)
                 VALUES (security_pkg.GetApp, in_internal_audit_sid, NVL(in_auditor_company_sid, v_created_by_company_sid), v_auditee_company_sid, v_created_by_company_sid);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                -- only update if the actual values have been supplied
                IF in_auditor_company_sid IS NOT NULL THEN
                    UPDATE chain.supplier_audit
                       SET auditor_company_sid = in_auditor_company_sid
                     WHERE audit_sid = in_internal_audit_sid;
                END IF;
                IF in_auditee_company_sid IS NOT NULL AND 
                   in_created_by_company_sid IS NOT NULL THEN
                    UPDATE chain.supplier_audit
                       SET supplier_company_sid = v_auditee_company_sid,
                           created_by_company_sid = v_created_by_company_sid
                     WHERE audit_sid = in_internal_audit_sid;
                END IF;
        END;
    END IF;

    chain.chain_link_pkg.SaveSupplierAudit(
        in_internal_audit_sid,
        v_auditee_company_sid,
        in_auditor_company_sid,
        v_created_by_company_sid
    );    
END;

PROCEDURE SetAuditorCompanySid (
    in_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_auditor_company_sid    IN    security_pkg.T_SID_ID
)
AS
BEGIN
    IF NOT HasWriteAccess(in_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the audit with sid '||in_audit_sid);
    END IF;

    UPDATE internal_audit
       SET auditor_company_sid = in_auditor_company_sid
     WHERE internal_audit_sid = in_audit_sid;
END;

PROCEDURE DeleteInternalAuditFiles(
    in_internal_audit_sid        IN    internal_audit.internal_audit_sid%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,  -- list of files which needs to stay untouched (will keep exist and attached to the audit)
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_keeper_id_tbl                security.T_SID_TABLE;        -- this is equal to in_current_file_uploads but in table format
    v_delete_id_tbl                security.T_SID_TABLE;       -- files to delete from audit
BEGIN
    IF (NOT IsFlowAudit(in_internal_audit_sid) AND NOT HasWriteAccess(in_internal_audit_sid)) OR
       (IsFlowAudit(in_internal_audit_sid) AND NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, security.security_pkg.PERMISSION_WRITE)) THEN
        -- don't have write access, just return rather than blow up due to the way this is coded w/ current vs. new
        -- the UI should prevent them from getting here if they don't have access anyway
        RETURN;
    END IF;

    -- crap hack for ODP.NET
    IF in_current_file_uploads IS NULL OR (in_current_file_uploads.COUNT = 1 AND in_current_file_uploads(1) IS NULL) THEN

        -- remove all files of audit (a file itself will be deleted only if it is not being used by another audit)
        DELETE FROM internal_audit_file_data
         WHERE internal_audit_file_data_id IN (
        SELECT internal_audit_file_data_id
          FROM internal_audit_file
         WHERE internal_audit_sid = in_internal_audit_sid
             )
           AND internal_audit_file_data_id NOT IN (    -- delete an internal file only if it is not being used by another audit
        SELECT internal_audit_file_data_id
          FROM internal_audit_file
         WHERE internal_audit_sid != in_internal_audit_sid
            );

        FOR r IN (
            SELECT iafd.filename
              FROM internal_audit_file iaf
              JOIN internal_audit_file_data iafd
                ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
             WHERE iaf.internal_audit_sid = in_internal_audit_sid
             ) LOOP

                csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DOCUMENTS, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
                    'Removed document {0}', r.filename);

            END LOOP;

        DELETE FROM internal_audit_file
         WHERE internal_audit_sid = in_internal_audit_sid;
    ELSE
        v_keeper_id_tbl := security_pkg.SidArrayToTable(in_current_file_uploads);

        -- Get files into v_delete_id_tbl which need to be deleted from csr.internal_audit_file and possibly from csr.internal_audit_file_data as well
        SELECT internal_audit_file_data_id
          BULK COLLECT INTO v_delete_id_tbl
          FROM internal_audit_file
         WHERE internal_audit_sid = in_internal_audit_sid
           AND internal_audit_file_data_id NOT IN (
            SELECT column_value FROM TABLE(v_keeper_id_tbl));

        FOR r IN (
            SELECT iafd.filename
              FROM internal_audit_file iaf
              JOIN internal_audit_file_data iafd
                ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
             WHERE iaf.internal_audit_sid = in_internal_audit_sid
               AND iaf.internal_audit_file_data_id NOT IN (
                    SELECT column_value FROM TABLE(v_keeper_id_tbl))
             ) LOOP

                csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DOCUMENTS, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
                    'Removed document {0}', r.filename);

            END LOOP;

        -- delete documents from the connection table
        DELETE FROM internal_audit_file
         WHERE internal_audit_sid = in_internal_audit_sid
           AND internal_audit_file_data_id IN (
            SELECT column_value FROM TABLE(v_delete_id_tbl));

        -- delete documents from internal_audit_file_data which are not in internal_audit_file any more. (no other audit uses them)
        FOR r IN (
                SELECT column_value
                  FROM TABLE(v_delete_id_tbl)
                 WHERE column_value NOT IN(
                    SELECT internal_audit_file_data_id
                      FROM internal_audit_file
                     )
            )
        LOOP
            DELETE FROM internal_audit_file_data
             WHERE internal_audit_file_data_id = r.column_value;

        END LOOP;
    END IF;

    -- return a nice clean list
    OPEN out_cur FOR
        SELECT iafd.internal_audit_file_data_id, iaf.internal_audit_sid, iafd.filename, iafd.mime_type, cast(iafd.sha1 as varchar2(40)) sha1, iafd.uploaded_dtm
          FROM internal_audit_file_data iafd
          JOIN internal_audit_file iaf
            ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
         WHERE iaf.internal_audit_sid = in_internal_audit_sid;
END;

PROCEDURE InsertInternalAuditFiles(
    in_internal_audit_sid        IN    internal_audit.internal_audit_sid%TYPE,
    in_new_file_uploads            IN    T_CACHE_KEYS,             -- new files to put into internal_audit_file_data and attach to the audit (internal_audit_file)
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_cache_key_tbl                security.T_VARCHAR2_TABLE;
BEGIN
    IF (NOT IsFlowAudit(in_internal_audit_sid) AND NOT HasWriteAccess(in_internal_audit_sid)) OR
       (IsFlowAudit(in_internal_audit_sid) AND NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, security.security_pkg.PERMISSION_WRITE)) THEN
        -- don't have write access, just return rather than blow up due to the way this is coded w/ current vs. new
        -- the UI should prevent them from getting here if they don't have access anyway
        RETURN;
    END IF;

    v_cache_key_tbl := CacheKeysArrayToTable(in_new_file_uploads);

    -- insert into two table (do it in a loop because of internal_audit_file_id_seq.nextval)
    FOR r IN (
            SELECT internal_audit_file_id_seq.nextval nextvalue, filename, mime_type, object obj, dbms_crypto.hash(object, dbms_crypto.hash_sh1) hash
              FROM aspen2.filecache
             WHERE cache_key IN (
                SELECT value FROM TABLE(v_cache_key_tbl)
            )
        )
    LOOP
        INSERT INTO internal_audit_file_data
            (internal_audit_file_data_id, filename, mime_type, data, sha1)
            VALUES (r.nextvalue, r.filename, r.mime_type, r.obj, r.hash);

        INSERT INTO internal_audit_file (app_sid, internal_audit_sid, internal_audit_file_data_id)
            VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid, r.nextvalue);

        csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DOCUMENTS, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
            'Added document {0}', r.filename);

    END LOOP;

    -- return a nice clean list
    OPEN out_cur FOR
        SELECT iafd.internal_audit_file_data_id, iaf.internal_audit_sid, iafd.filename, iafd.mime_type, cast(iafd.sha1 as varchar2(40)) sha1, iafd.uploaded_dtm
          FROM internal_audit_file_data iafd
          JOIN internal_audit_file iaf
            ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
         WHERE iaf.internal_audit_sid = in_internal_audit_sid;
END;

PROCEDURE GetInternalAuditFile(
    in_int_audit_file_data_id    IN    internal_audit_file_data.internal_audit_file_data_id%TYPE,
    in_sha1                        IN  internal_audit_file_data.sha1%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_table                        security.T_SID_TABLE;
BEGIN
    -- Access check
    FOR r IN (
        SELECT iaf.internal_audit_sid
          FROM internal_audit_file_data iafd
          JOIN internal_audit_file iaf
            ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
         WHERE iafd.internal_audit_file_data_id = in_int_audit_file_data_id
    )
    LOOP
        IF (NOT IsFlowAudit(r.internal_audit_sid) AND NOT HasReadAccess(r.internal_audit_sid)) OR
            (IsFlowAudit(r.internal_audit_sid) AND NOT HasCapabilityAccess(r.internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, security.security_pkg.PERMISSION_READ)) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the file on audit with sid '||r.internal_audit_sid);
        END IF;
    END LOOP;

    OPEN out_cur FOR
        SELECT iafd.internal_audit_file_data_id, iafd.filename, iafd.mime_type,
               cast(iafd.sha1 as varchar2(40)) sha1, iafd.uploaded_dtm, iafd.data
          FROM internal_audit_file_data iafd
         WHERE iafd.internal_audit_file_data_id = in_int_audit_file_data_id
           AND iafd.sha1 = in_sha1;
END;

PROCEDURE SaveNonInteractiveAudit(
    in_sid_id                    IN  internal_audit.internal_audit_sid%TYPE,
    in_region_sid                IN  internal_audit.region_sid%TYPE,
    in_internal_audit_type        IN  internal_audit.internal_audit_type_id%TYPE,
    in_label                    IN  internal_audit.label%TYPE,
    in_audit_dtm                IN  internal_audit.audit_dtm%TYPE,
    in_audit_closure_type_id    IN  internal_audit.audit_closure_type_id%TYPE,
    in_current_file_uploads        IN  security_pkg.T_SID_IDS,
    in_new_file_uploads            IN  T_CACHE_KEYS,
    in_audit_ref                IN    internal_audit.internal_audit_ref%TYPE DEFAULT csr_data_pkg.PRESERVE_NUMBER,
    out_sid_id                    OUT internal_audit.internal_audit_sid%TYPE
)
AS
    v_audit_type_label            internal_audit_type.label%TYPE;
    v_internal_audit_source_id    internal_audit_type.internal_audit_type_source_id%TYPE;
    v_dummy_cur                    security_pkg.T_OUTPUT_CUR;
    v_current_auditor_sid        security_pkg.T_SID_ID;
BEGIN
    SELECT label, internal_audit_type_source_id
      INTO v_audit_type_label, v_internal_audit_source_id
      FROM internal_audit_type
     WHERE internal_audit_type_id = in_internal_audit_type;

    SELECT MIN(auditor_user_sid)
      INTO v_current_auditor_sid
      FROM internal_audit
     WHERE internal_audit_sid = in_sid_id;
     
    IF v_internal_audit_source_id = INTERNAL_AUDIT_SOURCE_ID THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cannot create a non-internal audit of type '||v_audit_type_label||' as it is marked as internal');
    END IF;

    -- permissions handled by this call to save
    Save (
        in_sid_id                => in_sid_id,
        in_audit_ref            => in_audit_ref,
        in_survey_sid            => NULL,
        in_region_sid            => in_region_sid,
        in_label                => NVL(in_label, v_audit_type_label),
        in_audit_dtm            => in_audit_dtm,
        in_auditor_user_sid        => NVL(v_current_auditor_sid, security.security_pkg.GetSid),
        in_notes                => NULL,
        in_internal_audit_type    => in_internal_audit_type,
        in_auditor_name            => NULL,
        in_auditor_org            => NULL,
        out_sid_id                => out_sid_id
    );

    IF in_sid_id IS NULL THEN
        INTERNAL_CallHelperPkg('AuditCreated', out_sid_id);
    ELSE
        INTERNAL_CallHelperPkg('AuditUpdated', in_sid_id);
    END IF;

    SetClosureStatus(out_sid_id, in_audit_closure_type_id);
    DeleteInternalAuditFiles(out_sid_id, in_current_file_uploads, v_dummy_cur);
    InsertInternalAuditFiles(out_sid_id, in_new_file_uploads, v_dummy_cur);
END;

PROCEDURE GetAuditSummary(
    in_internal_audit_sid        IN  internal_audit.internal_audit_sid%TYPE,
    out_audit_cur                OUT security_pkg.T_OUTPUT_CUR,
    out_documents_cur            OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_cap_clos_t            NUMBER := SQL_HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ);
    v_perm_level            NUMBER := GetPermissionOnAudit(in_internal_audit_sid);
BEGIN

    OPEN out_audit_cur FOR
        SELECT a.internal_audit_sid, a.region_sid, a.region_description, a.audit_dtm, a.label,
               a.auditor_user_sid, a.auditor_full_name, a.audit_type_id, a.audit_type_label,
               CASE WHEN a.flow_item_id IS NULL OR v_cap_clos_t = 1 THEN a.audit_closure_type_id ELSE null END audit_closure_type_id,
               CASE WHEN a.flow_item_id IS NULL OR v_cap_clos_t = 1 THEN a.closure_label ELSE null END closure_label,
               a.internal_audit_type_id, a.flow_item_id, a.current_state_id, a.flow_state_label, iat.internal_audit_type_source_id,
               CASE (act.re_audit_due_after_type)
                WHEN 'd' THEN nvl(ovw_validity_dtm, a.audit_dtm + re_audit_due_after)
                WHEN 'w' THEN nvl(ovw_validity_dtm, a.audit_dtm + (re_audit_due_after*7))
                WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(a.audit_dtm, re_audit_due_after))
                WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(a.audit_dtm, re_audit_due_after*12))
               END next_audit_due_dtm, v_perm_level permission_level
          FROM v$audit a
          JOIN TABLE(
                v_table
                ) so ON a.internal_audit_sid = so.column_value
          JOIN internal_audit_type iat
            ON a.internal_audit_type_id = iat.internal_audit_type_id
          LEFT JOIN audit_type_closure_type act
            ON a.app_sid = act.app_sid
           AND a.internal_audit_type_id = act.internal_audit_type_id
           AND a.audit_closure_type_id = act.audit_closure_type_id
         WHERE iat.internal_audit_type_source_id <> INTERNAL_AUDIT_SOURCE_ID
           AND a.internal_audit_sid = in_internal_audit_sid;


    GetDocuments(
        in_internal_audit_sid             => in_internal_audit_sid,
        in_internal_audit_source_id     => EXTERNAL_AUDIT_SOURCE_ID,
        out_cur                            => out_documents_cur
    );
END;

PROCEDURE GetAuditSummaries(
    in_parent_region_sid        IN  internal_audit.internal_audit_sid%TYPE,
    in_internal_audit_source_id    IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT EXTERNAL_AUDIT_SOURCE_ID,
    out_audit_cur                OUT security_pkg.T_OUTPUT_CUR,
    out_documents_cur            OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_ord_table                security.T_ORDERED_SID_TABLE;
    v_cap_clos_t            security.T_SID_TABLE;
    v_doc_clos_t            security.T_SID_TABLE;
    v_audits_t                security.T_SID_TABLE;
BEGIN

    SELECT internal_audit_sid
      BULK COLLECT INTO v_audits_t
      FROM v$audit a
      LEFT JOIN (
            /* hierarchical query might be an overkill for a large input of regions sids */
            SELECT DISTINCT app_sid, nvl(link_to_region_sid, region_sid) region_sid
              FROM region /* we want the child regions of all input region sids*/
             START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = in_parent_region_sid
           CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
        ) r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
      JOIN TABLE(v_table) so ON a.internal_audit_sid = so.column_value
      JOIN internal_audit_type iat ON a.internal_audit_type_id = iat.internal_audit_type_id
     WHERE iat.internal_audit_type_source_id = in_internal_audit_source_id
       AND ((in_parent_region_sid IS NULL AND a.region_sid IS NULL) OR r.region_sid IS NOT NULL);

    PopulateAuditCapabilitiesTT(v_audits_t);

    SELECT security.T_ORDERED_SID_ROW(sid_id => column_value, pos => 0)
      BULK COLLECT INTO v_ord_table
      FROM TABLE(v_audits_t);

    v_cap_clos_t := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ, v_ord_table);
    v_doc_clos_t := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS, security.security_pkg.PERMISSION_READ, v_ord_table);

    OPEN out_audit_cur FOR
        SELECT a.internal_audit_sid, a.region_sid, a.region_description, a.audit_dtm, a.label,
               a.auditor_user_sid, a.auditor_full_name, a.auditor_organisation, a.audit_type_id, a.audit_type_label,
               CASE WHEN a.flow_item_id IS NULL OR t.column_value IS NOT NULL THEN a.audit_closure_type_id ELSE null END audit_closure_type_id,
               CASE WHEN a.flow_item_id IS NULL OR t.column_value IS NOT NULL THEN a.closure_label ELSE null END closure_label,
               CASE WHEN a.flow_item_id IS NULL OR t.column_value IS NOT NULL THEN a.is_failure ELSE null END is_failure,
               a.internal_audit_type_id, a.flow_item_id, a.current_state_id, a.flow_state_label,
               CASE (act.re_audit_due_after_type)
                WHEN 'd' THEN nvl(ovw_validity_dtm, a.audit_dtm + re_audit_due_after)
                WHEN 'w' THEN nvl(ovw_validity_dtm, a.audit_dtm + (re_audit_due_after*7))
                WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(a.audit_dtm, re_audit_due_after))
                WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(a.audit_dtm, re_audit_due_after*12))
               END next_audit_due_dtm, a.survey_completed survey_completed_dtm, a.open_non_compliances,
               qss.overall_score, GetPermissionOnAudit(a.internal_audit_sid) permission_level,
               a.nc_score, a.nc_score_type_id, a.nc_max_score, a.nc_score_label, a.nc_score_format_mask
          FROM v$audit a
          JOIN TABLE(v_audits_t) t_a ON t_a.column_value = a.internal_audit_sid
          LEFT JOIN TABLE(v_cap_clos_t) t ON a.internal_audit_sid = t.column_value          
          LEFT JOIN audit_type_closure_type act ON a.app_sid = act.app_sid AND a.internal_audit_type_id = act.internal_audit_type_id AND a.audit_closure_type_id = act.audit_closure_type_id
          LEFT JOIN quick_survey_response qsr ON qsr.survey_response_id = a.survey_response_id
          LEFT JOIN quick_survey_submission qss ON qss.survey_response_id = a.survey_response_id AND qss.submission_id = qsr.last_submission_id
         ORDER BY a.audit_type_id, a.audit_dtm DESC;

    OPEN out_documents_cur FOR
        SELECT iafd.internal_audit_file_data_id, iaf.internal_audit_sid, iafd.filename, iafd.mime_type,
               cast(iafd.sha1 as varchar2(40)) sha1, iafd.uploaded_dtm
          FROM internal_audit_file_data iafd
          JOIN internal_audit_file iaf
            ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
          JOIN internal_audit ia
            ON iaf.internal_audit_sid = ia.internal_audit_sid
          JOIN TABLE(v_audits_t) t_a ON t_a.column_value = ia.internal_audit_sid
          LEFT JOIN TABLE(v_doc_clos_t) tdc
             ON ia.internal_audit_sid = tdc.column_value
         WHERE (ia.flow_item_id IS NULL OR tdc.column_value IS NOT NULL);
END;

PROCEDURE CarryForwardDocuments (
    in_from_audit_sid            IN    security_pkg.T_SID_ID,
    in_to_audit_sid                IN    security_pkg.T_SID_ID
)
AS
BEGIN
    INSERT INTO internal_audit_file (internal_audit_sid, internal_audit_file_data_id)
         SELECT in_to_audit_sid, iafc.internal_audit_file_data_id
           FROM internal_audit_file iafc
          WHERE iafc.internal_audit_sid = in_from_audit_sid;
END;

PROCEDURE CarryForwardPostits (
    in_from_audit_sid            IN    security_pkg.T_SID_ID,
    in_to_audit_sid                IN    security_pkg.T_SID_ID
)
AS
BEGIN
    INSERT INTO internal_audit_postit (internal_audit_sid, postit_id)
         SELECT in_to_audit_sid, iap.postit_id
           FROM internal_audit_postit iap
          WHERE iap.internal_audit_sid = in_from_audit_sid;
END;

PROCEDURE CarryForwardOpenNCs (
    in_from_audit_sid            IN    security_pkg.T_SID_ID,
    in_to_audit_sid                IN    security_pkg.T_SID_ID,
    in_take_ownership_of_issues    IN  NUMBER DEFAULT 0
)
AS
    v_to_auditor_sid            security_pkg.T_SID_ID;
    v_to_auditor_company_sid    security_pkg.T_SID_ID;
    v_can_take_ownership        NUMBER(1);
    v_take_ownership            NUMBER(1) := 0;
    v_involve_auditor_in_issues    NUMBER(1);
    v_dummy_cur                    SYS_REFCURSOR;
BEGIN
    INSERT INTO audit_non_compliance (
                audit_non_compliance_id, internal_audit_sid, 
                non_compliance_id, attached_to_primary_survey, internal_audit_type_survey_id
    )
         SELECT audit_non_compliance_id_seq.nextval, in_to_audit_sid, 
                non_compliance_id, attached_to_primary_survey, internal_audit_type_survey_id
           FROM (
                SELECT anc.non_compliance_id, anc.attached_to_primary_survey, tiats.internal_audit_type_survey_id
                  FROM audit_non_compliance anc
                  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
                  LEFT JOIN internal_audit_type_survey fiats
                    ON fiats.internal_audit_type_survey_id = anc.internal_audit_type_survey_id
                  JOIN internal_audit tia ON tia.internal_audit_sid = in_to_audit_sid
                  LEFT JOIN internal_audit_type_survey tiats                   
                    ON tiats.internal_audit_type_id = tia.internal_audit_type_id
                   AND (
                        tiats.internal_audit_type_survey_id = fiats.internal_audit_type_survey_id OR
                        tiats.ia_type_survey_group_id = fiats.ia_type_survey_group_id
                   )
                  LEFT JOIN non_comp_type_audit_type nctat
                         ON nctat.non_compliance_type_id = nc.non_compliance_type_id
                        AND nctat.internal_audit_type_id = tia.internal_audit_type_id
                 WHERE anc.internal_audit_sid = in_from_audit_sid
                   AND (nc.non_compliance_type_id IS NULL OR nctat.non_compliance_type_id IS NOT NULL)
                   AND EXISTS (
                        SELECT NULL
                          FROM non_compliance nc
                          LEFT JOIN issue_non_compliance inc ON nc.non_compliance_id = inc.non_compliance_id
                          LEFT JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
                         WHERE nc.non_compliance_id = anc.non_compliance_id
                           AND (
                             (
                                nc.is_closed IS NULL
                                 AND i.resolved_dtm IS NULL
                                 AND i.rejected_dtm IS NULL
                                AND i.deleted = 0
                             )
                             OR nc.is_closed = 0
                           )
                   )
                  GROUP BY anc.non_compliance_id, anc.attached_to_primary_survey, tiats.internal_audit_type_survey_id
           );

    SELECT auditor_can_take_ownership, involve_auditor_in_issues
      INTO v_can_take_ownership, v_involve_auditor_in_issues
      FROM internal_audit_type iat
      JOIN internal_audit ia
        ON iat.internal_audit_type_id = ia.internal_audit_type_id
     WHERE ia.internal_audit_sid = in_from_audit_sid;

    IF v_can_take_ownership = 1 AND in_take_ownership_of_issues = 1 THEN
        v_take_ownership := 1;
    END IF;
    
    IF v_take_ownership = 1 OR v_involve_auditor_in_issues = 1 THEN    
        SELECT auditor_user_sid, auditor_company_sid
          INTO v_to_auditor_sid, v_to_auditor_company_sid
          FROM internal_audit
         WHERE internal_audit_sid = in_to_audit_sid;

        FOR r IN (
            SELECT i.issue_id
              FROM issue_non_compliance inc
              JOIN audit_non_compliance anc ON anc.non_compliance_id = inc.non_compliance_id
              JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
             WHERE anc.internal_audit_sid = in_to_audit_sid
        ) LOOP
            IF v_take_ownership = 1 THEN
                UPDATE issue
                   SET owner_user_sid = v_to_auditor_sid,
                       owner_role_sid = null
                 WHERE issue_id = r.issue_id;

                BEGIN
                    INSERT INTO issue_involvement (issue_id, is_an_owner, user_sid)
                    VALUES (r.issue_id, 1, v_to_auditor_sid);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                        NULL; -- Ignore if the user is alreaday assigned
                END;
            END IF;
            
            IF v_involve_auditor_in_issues = 1 THEN
                issue_pkg.AddCompany(
                    in_issue_id        => r.issue_id,
                    in_company_sid    => v_to_auditor_company_sid,
                    out_cur            => v_dummy_cur);
            END IF;
                
        END LOOP;
    END IF;

    FOR r IN (
        SELECT anc1.internal_audit_sid
          FROM audit_non_compliance anc1
          JOIN audit_non_compliance anc2 ON anc2.non_compliance_id = anc1.non_compliance_id
         WHERE anc2.internal_audit_sid = in_from_audit_sid
            OR anc2.internal_audit_sid = in_to_audit_sid
      GROUP BY anc1.internal_audit_sid
    ) LOOP
        RecalculateAuditNCScore(r.internal_audit_sid);
    END LOOP;
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
    );
END;

PROCEDURE CarryForwardSurveyResponse (
    in_from_response_id                IN    internal_audit.survey_response_id%TYPE,
    in_to_audit_sid                    IN    security.security_pkg.T_SID_ID,
    in_to_audit_type_survey_id        IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
)
AS
    v_audits_sid                    security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_submission_id                    csr.quick_survey_response.last_submission_id%TYPE;
BEGIN
    -- Check that user can add/create audits
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create audits');
    END IF;

    SELECT last_submission_id 
      INTO v_submission_id
      FROM quick_survey_response qsr
     WHERE survey_response_id = in_from_response_id;

    CopyPreviousSubmission(in_to_audit_sid, in_from_response_id, v_submission_id, in_to_audit_type_survey_id, out_response_id);
END;

/*We need to ditch this SP at some point. Atm it returns data we throw away in most of the cases and it doesn't provide any paging */
PROCEDURE Browse(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_non_compliance    IN    NUMBER,
    in_overdue                IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_ia_type_group_id        IN    internal_audit_type.internal_audit_type_group_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_company_region_sid    security_pkg.T_SID_ID;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_region_sid_table        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_parent_region_sids);
    v_audit_perm_t            security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
    v_perm                    NUMBER;
    v_cap_auditee            security.T_SID_TABLE; 
    v_survey_cap            security.T_SID_TABLE; 
    v_closure_cap            security.T_SID_TABLE;    
    v_score_cap                security.T_SID_TABLE; 
    v_exec_sum                security.T_SID_TABLE; 
    v_user_sid                 security_pkg.T_SID_ID := security_pkg.GetSid;    
BEGIN

    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            OPEN out_cur FOR
                SELECT null internal_audit_sid, null region_sid, null region_description, null audit_dtm, null label,
                       null auditor_user_sid, null auditor_full_name, null survey_completed,
                       null open_non_compliances, null auditor_name, null auditor_organisation
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
    END;

    DELETE FROM TT_AUDIT_BROWSE;
    INSERT INTO TT_AUDIT_BROWSE (internal_audit_sid, region_sid, region_description, audit_dtm, label, 
        auditor_user_sid, auditor_full_name, custom_audit_id,
        open_non_compliances, auditor_name, auditor_organisation, auditor_email,
        region_type, region_type_class_name, short_notes, full_notes,
        audit_type_id, audit_type_label, 
        internal_audit_type_group_id, ia_type_group_label,
        icon_image_filename, icon_image_sha1, internal_audit_type_id,
        flow_sid, flow_label, flow_item_id, current_state_id, 
        flow_state_label, flow_state_lookup_key, flow_state_is_final,
        survey_score_type_id, survey_score_format_mask, survey_overall_max_score, survey_score_label,
        nc_score_type_id, nc_max_score, nc_score_label, nc_score_format_mask, nc_score,
        summary_response_id, summary_survey_label, summary_survey_sid, summary_survey_version,
        auditee_user_sid, auditee_full_name, auditee_email, survey_sid, survey_label, survey_completed,
        survey_response_id, survey_version, audit_closure_type_id, closure_label, survey_overall_score,
        next_audit_due_dtm)
    SELECT a.internal_audit_sid, a.region_sid, a.region_description, a.audit_dtm, a.label,
        a.auditor_user_sid, a.auditor_full_name, a.custom_audit_id,
        a.open_non_compliances, a.auditor_name, a.auditor_organisation, a.auditor_email,
        a.region_type, a.region_type_class_name, a.short_notes, a.full_notes,
        a.audit_type_id, a.audit_type_label, 
        a.internal_audit_type_group_id, a.ia_type_group_label,
        a.icon_image_filename, a.icon_image_sha1, a.internal_audit_type_id,
        a.flow_sid, a.flow_label, a.flow_item_id, a.current_state_id, 
        fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.is_final flow_state_is_final,
        a.survey_score_type_id, a.survey_score_format_mask, a.survey_overall_max_score, a.survey_score_label,
        a.nc_score_type_id, a.nc_max_score, a.nc_score_label, a.nc_score_format_mask, a.nc_score,
        a.summary_response_id, a.summary_survey_label, a.summary_survey_sid, a.summary_survey_version,
        a.auditee_user_sid, a.auditee_full_name, a.auditee_email, a.survey_sid, a.survey_label, a.survey_completed,
        a.survey_response_id, a.survey_version, a.audit_closure_type_id, a.closure_label, a.survey_overall_score,
        a.next_audit_due_dtm
      FROM v$audit a
      JOIN (
            /* hierarchical query might be an overkill for a large input of regions sids */
        SELECT DISTINCT app_sid, nvl(link_to_region_sid, region_sid) region_sid
            FROM region /* we want the child regions of all input region sids*/
            START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid IN (
            SELECT column_value
                FROM TABLE (v_region_sid_table)
            )
        CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
        ) r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
        -- This filters by permission and filters out items in the trash
      JOIN TABLE(
            v_table
        ) so ON a.internal_audit_sid = so.column_value
       LEFT JOIN flow_state fs ON fs.flow_state_id = a.current_state_id
       LEFT JOIN region_role_member rrm ON a.region_sid = rrm.region_sid
        AND a.auditor_role_sid = rrm.role_sid AND a.app_sid = rrm.app_sid AND rrm.user_sid = v_user_sid
      WHERE (in_start_dtm IS NULL OR a.audit_dtm >= in_start_dtm)
        AND (in_end_dtm IS NULL OR a.audit_dtm < in_end_dtm)
        AND (in_open_non_compliance = 0 OR a.open_non_compliances > 0)
        -- TODO: what is 'overdue'?
        AND (in_overdue = 0 OR (a.audit_dtm < SYSDATE AND a.survey_completed IS NULL AND a.survey_sid IS NOT NULL))
        AND NVL(in_internal_audit_type, a.internal_audit_type_id) = a.internal_audit_type_id
        AND (in_ia_type_group_id IS NULL OR NVL(a.internal_audit_type_group_id, 0) = in_ia_type_group_id)
        AND (in_my_audits_only = 0 OR a.auditor_user_sid = v_user_sid OR rrm.user_sid = v_user_sid)
        AND (in_flow_state_id IS NULL OR a.current_state_id = in_flow_state_id);
    
    FOR r IN (
        SELECT internal_audit_sid
          FROM TT_AUDIT_BROWSE t
    )
    LOOP
        v_perm := GetPermissionOnAudit(r.internal_audit_sid);
        v_audit_perm_t.extend(1);
        v_audit_perm_t(v_audit_perm_t.COUNT) := security.T_ORDERED_SID_ROW(sid_id => r.internal_audit_sid, pos => v_perm);
    END LOOP;

    v_cap_auditee := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE, security.security_pkg.PERMISSION_READ, v_audit_perm_t);
    v_survey_cap := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security.security_pkg.PERMISSION_READ, v_audit_perm_t);
    v_closure_cap := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ, v_audit_perm_t);
    v_score_cap    := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ, v_audit_perm_t);
    v_exec_sum    := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, security.security_pkg.PERMISSION_READ, v_audit_perm_t);

    OPEN out_cur FOR
        SELECT internal_audit_sid, region_sid, region_description, audit_dtm, label,
            auditor_user_sid, auditor_full_name, custom_audit_id,
            open_non_compliances, auditor_name, auditor_organisation, auditor_email,
            region_type, region_type_class_name, short_notes, full_notes,
            audit_type_id, audit_type_label, 
            internal_audit_type_group_id, ia_type_group_label,
            icon_image_filename, icon_image_sha1, internal_audit_type_id,
            flow_sid, flow_label, flow_item_id, current_state_id, 
            flow_state_label, flow_state_lookup_key, flow_state_is_final,
            survey_score_type_id, survey_score_format_mask, survey_overall_max_score, survey_score_label,
            nc_score_type_id, nc_max_score, nc_score_label, nc_score_format_mask, next_audit_due_dtm,
            CASE WHEN t.flow_item_id IS NULL OR auditee_cap.column_value IS NOT NULL THEN t.auditee_user_sid ELSE null END auditee_user_sid, 
            CASE WHEN t.flow_item_id IS NULL OR auditee_cap.column_value IS NOT NULL THEN t.auditee_full_name ELSE null END auditee_full_name, 
            CASE WHEN t.flow_item_id IS NULL OR auditee_cap.column_value IS NOT NULL THEN t.auditee_email ELSE null END auditee_email, 
            CASE WHEN t.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN t.survey_sid ELSE null END survey_sid, 
            CASE WHEN t.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN t.survey_label ELSE null END survey_label, 
            CASE WHEN t.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN t.survey_completed ELSE null END survey_completed, 
            CASE WHEN t.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN t.survey_response_id ELSE null END survey_response_id, 
            CASE WHEN t.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN t.survey_version ELSE null END survey_version, 
            CASE WHEN t.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN t.audit_closure_type_id ELSE null END audit_closure_type_id, 
            CASE WHEN t.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN t.closure_label ELSE null END closure_label, 
            CASE WHEN t.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL THEN t.survey_overall_score ELSE null END survey_overall_score, 
            CASE WHEN t.flow_item_id IS NULL OR score_cap.column_value IS NOT NULL THEN t.nc_score ELSE null END nc_score, 
            CASE WHEN t.flow_item_id IS NULL OR exec_sum.column_value IS NOT NULL THEN t.summary_survey_sid ELSE null END summary_survey_sid, 
            CASE WHEN t.flow_item_id IS NULL OR exec_sum.column_value IS NOT NULL THEN t.summary_survey_label ELSE null END summary_survey_label, 
            CASE WHEN t.flow_item_id IS NULL OR exec_sum.column_value IS NOT NULL THEN t.summary_response_id ELSE null END summary_response_id, 
            CASE WHEN t.flow_item_id IS NULL OR exec_sum.column_value IS NOT NULL THEN t.summary_survey_version ELSE null END summary_survey_version, 
            perm.pos permission
        FROM TT_AUDIT_BROWSE t
        LEFT JOIN (SELECT column_value FROM TABLE(v_cap_auditee) ORDER BY column_value) auditee_cap ON t.internal_audit_sid = auditee_cap.column_value
        LEFT JOIN (SELECT column_value FROM TABLE(v_survey_cap) ORDER BY column_value) survey_cap ON t.internal_audit_sid = survey_cap.column_value
        LEFT JOIN (SELECT column_value FROM TABLE(v_closure_cap) ORDER BY column_value) closure_cap ON t.internal_audit_sid = closure_cap.column_value
        LEFT JOIN (SELECT column_value FROM TABLE(v_score_cap) ORDER BY column_value) score_cap ON t.internal_audit_sid = score_cap.column_value
        LEFT JOIN (SELECT column_value FROM TABLE(v_exec_sum) ORDER BY column_value) exec_sum ON t.internal_audit_sid = exec_sum.column_value
        JOIN (SELECT sid_id, pos FROM TABLE(v_audit_perm_t) ORDER BY sid_id) perm ON t.internal_audit_sid = perm.sid_id;
END;

/*A lightweight version for plugins that returns only the data needed
eventually we will retire all browse SP versions <- LOL!*/
PROCEDURE BrowseForPlugin(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_non_compliance    IN    NUMBER,
    in_overdue                IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_ia_type_group_id        IN    internal_audit_type.internal_audit_type_group_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_company_region_sid    security_pkg.T_SID_ID;
    v_perm_ids_t            security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_region_sid_table        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_parent_region_sids);
    v_audits_t                security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
    v_survey_cap            security.T_SID_TABLE; 
    v_closure_cap            security.T_SID_TABLE;
    v_user_sid                 security_pkg.T_SID_ID := security_pkg.GetSid;    
BEGIN

    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            OPEN out_cur FOR
                SELECT null internal_audit_sid, null region_sid, null region_description, null audit_dtm, null label,
                       null auditor_user_sid, null auditor_full_name, null survey_completed,
                       null open_non_compliances, null auditor_name, null auditor_organisation
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
    END;

    SELECT security.T_ORDERED_SID_ROW(sid_id => ia.internal_audit_sid, pos => -1 )
      BULK COLLECT INTO v_audits_t
      FROM internal_audit ia
      JOIN TABLE(v_perm_ids_t) p ON ia.internal_audit_sid = p.column_value
      JOIN (
            /* hierarchical query might be an overkill for a large input of regions sids */
        SELECT DISTINCT app_sid, nvl(link_to_region_sid, region_sid) region_sid
            FROM region /* we want the child regions of all input region sids*/
            START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid IN (
            SELECT column_value
                FROM TABLE (v_region_sid_table)
            )
        CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
          ) r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
      LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
      LEFT JOIN region_role_member rrm ON ia.region_sid = rrm.region_sid
           AND iat.auditor_role_sid = rrm.role_sid AND iat.app_sid = rrm.app_sid AND rrm.user_sid = v_user_sid

      LEFT JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
      LEFT JOIN flow_state fs ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
      LEFT JOIN internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
      LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
      LEFT JOIN (
       SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
         FROM csr.audit_non_compliance anc
         JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
         LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
         LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
        WHERE ((nnc.is_closed IS NULL
          AND i.resolved_dtm IS NULL
          AND i.rejected_dtm IS NULL
          AND i.deleted = 0)
           OR nnc.is_closed = 0)
        GROUP BY anc.app_sid, anc.internal_audit_sid
      ) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
     WHERE ia.deleted = 0
       AND (in_start_dtm IS NULL OR ia.audit_dtm >= in_start_dtm)
       AND (in_end_dtm IS NULL OR ia.audit_dtm < in_end_dtm)
       AND (in_open_non_compliance = 0 OR  NVL(nc.cnt, 0) > 0)
       -- TODO: what is 'overdue'?
       AND (in_overdue = 0 OR (ia.audit_dtm < SYSDATE AND sr.submitted_dtm IS NULL AND ia.survey_sid IS NOT NULL))
       AND NVL(in_internal_audit_type, ia.internal_audit_type_id) = ia.internal_audit_type_id
       AND (in_ia_type_group_id IS NULL OR NVL(atg.internal_audit_type_group_id, 0) = in_ia_type_group_id)
       AND (in_my_audits_only = 0 OR ia.auditor_user_sid = v_user_sid OR rrm.user_sid = v_user_sid)
       AND (in_flow_state_id IS NULL OR fi.current_state_id = in_flow_state_id);

    v_survey_cap := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security.security_pkg.PERMISSION_READ, v_audits_t);
    v_closure_cap := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_READ, v_audits_t);

    --use a more lightweight version of v$audit 
    OPEN out_cur FOR
        SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
            ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, NVL(nc.cnt, 0) open_non_compliances, ia.auditor_name, 
            ia.auditor_organisation, NVL(cu.email, au.email) auditor_email,
            iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, 
            act.icon_image_filename, CAST(act.icon_image_sha1  as varchar2(40)) icon_image_sha1, ia.internal_audit_type_id,
            f.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, 
            fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, rt.class_name region_type_class_name,
            CASE WHEN ia.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN sr.survey_sid ELSE null END survey_sid, 
            CASE WHEN ia.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN qs.label ELSE null END survey_label, 
            CASE WHEN ia.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN sr.submitted_dtm ELSE null END survey_completed, 
            CASE WHEN ia.flow_item_id IS NULL OR survey_cap.column_value IS NOT NULL THEN ia.survey_response_id ELSE null END survey_response_id,
            CASE WHEN ia.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN act.label ELSE null END closure_label, 
            CASE WHEN ia.flow_item_id IS NULL OR closure_cap.column_value IS NOT NULL THEN ia.audit_closure_type_id ELSE null END audit_closure_type_id,
            CASE (atct.re_audit_due_after_type)
                WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
                WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
                WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
                WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
                ELSE ia.ovw_validity_dtm END next_audit_due_dtm
        FROM TABLE(v_audits_t) t
        JOIN internal_audit ia ON ia.internal_audit_sid = t.sid_id
        LEFT JOIN (
            SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
                   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
                   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
              FROM csr.audit_user_cover auc
              JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
             CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
        ) cvru  
          ON ia.internal_audit_sid = cvru.internal_audit_sid
         AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
         AND cvru.rn = 1
        LEFT JOIN (
            SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
              FROM csr.audit_non_compliance anc
              JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
              LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
              LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
             WHERE ((nnc.is_closed IS NULL
               AND i.resolved_dtm IS NULL
               AND i.rejected_dtm IS NULL
               AND i.deleted = 0)
                OR nnc.is_closed = 0)
             GROUP BY anc.app_sid, anc.internal_audit_sid
            ) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid        
        JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
        LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
        LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
        LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
        LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
        LEFT JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
        LEFT JOIN flow_state fs ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
        LEFT JOIN csr.flow f ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
        LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
        LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
        LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
        LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
        LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
        LEFT JOIN (SELECT column_value FROM TABLE(v_survey_cap) ORDER BY column_value) survey_cap ON ia.internal_audit_sid = survey_cap.column_value
        LEFT JOIN (SELECT column_value FROM TABLE(v_closure_cap) ORDER BY column_value) closure_cap ON ia.internal_audit_sid = closure_cap.column_value;
END;

PROCEDURE SearchAudits (
    in_search_term            VARCHAR2,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_search                VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
BEGIN
    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            OPEN out_cur FOR
                SELECT null internal_audit_sid, null label
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
    END;

    OPEN out_cur FOR
        SELECT a.internal_audit_sid, a.label
          FROM v$audit a
          JOIN TABLE(
                v_table
                ) so ON a.internal_audit_sid = so.column_value
         WHERE LOWER(a.label) LIKE v_search;
END;

PROCEDURE SearchAuditsMore (
    in_search_term                    VARCHAR2,
    in_internal_audit_source_id        IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                            OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_search                VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
BEGIN
    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            OPEN out_cur FOR
                SELECT null internal_audit_sid, null label
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
    END;

    OPEN out_cur FOR
        SELECT a.internal_audit_sid, a.label, a.audit_type_label, a.region_description, a.audit_dtm, a.audit_type_id, a.region_sid
          FROM v$audit a
          JOIN internal_audit_type iat ON a.internal_audit_type_id = iat.internal_audit_type_id
          JOIN TABLE(
                v_table
                ) so ON a.internal_audit_sid = so.column_value
         WHERE iat.internal_audit_type_source_id = in_internal_audit_source_id
           AND (LOWER(a.label) LIKE v_search
             OR LOWER(a.audit_type_label) LIKE v_search
            OR LOWER(a.region_description) LIKE v_search);
END;

PROCEDURE BrowseNonCompliances(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_actions            IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_ia_type_group_id        IN    internal_audit_type.internal_audit_type_group_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR,
    out_tags                OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_region_sid_table        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_parent_region_sids);
    v_my_audits_only        NUMBER;
    v_ord_table                security.T_ORDERED_SID_TABLE;
    v_nc_cap_t                security.T_SID_TABLE;
    v_audits_by_custom_cap    T_AUDIT_PERMISSIBLE_NCT_TABLE;
BEGIN

    FOR r IN (
        SELECT column_value
          FROM TABLE(v_region_sid_table)
     )
    LOOP
        IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, r.column_value, security_pkg.PERMISSION_READ) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading non-compliances on with sid: '||r.column_value);
        END IF;
    END LOOP;

    IF in_my_audits_only <> 1 AND csr.csr_data_pkg.SQL_CheckCapability('Can view others audits') <> 1 THEN
        v_my_audits_only := 0;
    ELSE
        v_my_audits_only := in_my_audits_only;
    END IF;

    SELECT security.T_ORDERED_SID_ROW(sid_id => column_value, pos => 0)
      BULK COLLECT INTO v_ord_table
      FROM TABLE(v_table);

    v_nc_cap_t := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security.security_pkg.PERMISSION_READ, v_ord_table);
    v_audits_by_custom_cap := audit_pkg.GetCustomPermissibleAuditNCTs(security.security_pkg.PERMISSION_READ);

    OPEN out_cur FOR
        SELECT nc.non_compliance_id, nc.label, nc.detail, nc.from_non_comp_default_id,
               nc.created_dtm, nc.created_in_audit_sid, cia.internal_audit_type_id created_in_audit_type_id,
               nc.created_by_user_sid, cc.full_name created_by_full_name,
               anc.internal_audit_sid sid_id, ia.label audit_label, iat.Label audit_type_lbl, ia.Auditor_Organisation,
               qsr.survey_response_id,
               CASE WHEN anc.attached_to_primary_survey = 1 THEN 0 ELSE anc.internal_audit_type_survey_id END internal_audit_type_survey_id,
               qsq.question_id, qsq.label question_label,
               qsqo.question_option_id, qsqo.label question_option_label,
               nc.non_compliance_type_id, nct.label non_compliance_type_label, nc.is_closed,
               NVL(i.closed_issues, 0) closed_issues,
               NVL(i.open_issues, 0) open_issues, NVL(i.total_issues, 0) total_issues,
               r.region_sid, r.description region_description, anc.internal_audit_sid,
               NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, null) custom_non_compliance_id
          FROM non_compliance nc
          JOIN (
                SELECT ancX.app_sid, ancX.non_compliance_id, MAX(ancX.internal_audit_sid) internal_audit_sid,
                       MAX(ia.region_sid) region_sid,
                       MAX(ancX.attached_to_primary_survey) KEEP (DENSE_RANK LAST ORDER BY ancX.internal_audit_sid) attached_to_primary_survey,
                       MAX(ancX.internal_audit_type_survey_id) KEEP (DENSE_RANK LAST ORDER BY ancX.internal_audit_sid) internal_audit_type_survey_id
                  FROM audit_non_compliance ancX
                  JOIN non_compliance nc ON nc.non_compliance_id = ancx.non_compliance_id
                  JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
                  JOIN internal_audit ia ON ancX.internal_audit_sid = ia.internal_audit_sid AND ancX.app_sid = ia.app_sid
                  JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
                  LEFT JOIN flow_item fi
                    ON ia.flow_item_id = fi.flow_item_id
                  LEFT JOIN TABLE(v_nc_cap_t) cap_t ON ia.internal_audit_sid = cap_t.column_value
                  LEFT JOIN TABLE(v_audits_by_custom_cap) c_cap_t 
                    ON ancX.internal_audit_sid = c_cap_t.audit_sid
                   AND nct.non_compliance_type_id = c_cap_t.non_compliance_type_id
                  JOIN TABLE(v_table) so ON ia.internal_audit_sid = so.column_value
                 WHERE (in_start_dtm IS NULL OR ia.audit_dtm >= in_start_dtm)
                   AND (in_end_dtm IS NULL OR ia.audit_dtm <= in_end_dtm)
                   AND NVL(in_internal_audit_type, ia.internal_audit_type_id) = ia.internal_audit_type_id
                   AND (in_ia_type_group_id IS NULL OR NVL(iat.internal_audit_type_group_id, 0) = in_ia_type_group_id)
                   AND (in_flow_state_id IS NULL OR fi.current_state_id = in_flow_state_id)
                   AND (ia.flow_item_id IS NULL 
                    OR (nct.flow_capability_id IS NULL AND cap_t.column_value IS NOT NULL)
                    OR (nct.flow_capability_id IS NOT NULL AND c_cap_t.audit_sid IS NOT NULL)
                   )
                   AND (v_my_audits_only = 0 OR ia.auditor_user_sid = security_pkg.GetSid)
                 GROUP BY ancX.app_sid, ancX.non_compliance_id
                  ) anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN internal_audit ia On anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = ia.app_sid
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
          JOIN internal_audit cia On nc.created_in_audit_sid = cia.internal_audit_sid AND nc.app_sid = cia.app_sid
          LEFT JOIN internal_audit_survey ias ON ias.internal_audit_sid = ia.internal_audit_sid AND ias.internal_audit_type_survey_id = anc.internal_audit_type_survey_id
          LEFT JOIN quick_survey_response qsr ON NVL(ias.survey_response_id, CASE WHEN attached_to_primary_survey = 1 THEN ia.survey_response_id ELSE NULL END) = qsr.survey_response_id
          LEFT JOIN quick_survey_question qsq ON qsq.question_id = nc.question_id AND qsq.survey_version = qsr.survey_version
          LEFT JOIN qs_question_option qsqo ON qsqo.question_id = nc.question_id AND qsqo.question_option_id = nc.question_option_id AND qsqo.survey_version = qsr.survey_version
          JOIN csr_user cc ON nc.created_by_user_sid = cc.csr_user_sid AND nc.app_sid = cc.app_sid
          LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
          LEFT JOIN (
                SELECT inc.app_sid, inc.non_compliance_id,
                       COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
                       COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
                  FROM issue_non_compliance inc, issue i
                 WHERE inc.app_sid = i.app_sid
                   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
                 GROUP BY inc.app_sid, inc.non_compliance_id
                ) i ON nc.non_compliance_id = i.non_compliance_id AND nc.app_sid = i.app_sid
         LEFT JOIN (
                SELECT DISTINCT app_sid, nvl(link_to_region_sid, region_sid) region_sid, description
                  FROM v$region /* we want the child regions of all input region sids*/
                 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid IN (
                      SELECT column_value
                        FROM TABLE (v_region_sid_table)
                 )
                       CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
                ) r ON r.region_sid = NVL(nc.region_sid, cia.region_sid) AND r.app_sid = nc.app_sid
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND (in_open_actions = 0 OR i.open_issues > 0)
           AND (NVL(nc.region_sid, cia.region_sid) IS NULL OR r.region_sid IS NOT NULL)
         ORDER BY nct.position, nc.non_compliance_id;

    OPEN out_tags FOR
        SELECT DISTINCT nct.non_compliance_id, tgm.tag_group_id, t.tag_id, t.tag, tgm.pos
          FROM tag_group_member tgm
          JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
          LEFT JOIN (non_compliance_tag nct
               JOIN audit_non_compliance anc ON nct.non_compliance_id = anc.non_compliance_id AND nct.app_sid = anc.app_sid
               JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND anc.app_sid = ia.app_sid
               LEFT JOIN (
                SELECT inc.app_sid, inc.non_compliance_id,
                       COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
                  FROM issue_non_compliance inc, issue i
                 WHERE inc.app_sid = i.app_sid
                   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
                 GROUP BY inc.app_sid, inc.non_compliance_id
               ) i ON i.non_compliance_id = anc.non_compliance_id AND i.app_sid = anc.app_sid
          ) ON tgm.tag_id = nct.tag_id AND tgm.app_sid = nct.app_sid
          LEFT JOIN flow_item fi
            ON ia.flow_item_id = fi.flow_item_id
          LEFT JOIN TABLE(v_nc_cap_t) cap_t 
            ON ia.internal_audit_sid = cap_t.column_value
         WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND ia.region_sid IN (
            SELECT DISTINCT nvl(link_to_region_sid, region_sid)
              FROM region /* we want the child regions of all input region sids*/
              START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid IN (
                    SELECT column_value
                      FROM TABLE (v_region_sid_table)
              )
              CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
            )
           AND ia.internal_audit_sid IN (
            SELECT column_value
              FROM TABLE(v_table)
            )
           AND (in_start_dtm IS NULL OR ia.audit_dtm >= in_start_dtm)
           AND (in_end_dtm IS NULL OR ia.audit_dtm <= in_end_dtm)
           AND (in_open_actions = 0 OR i.open_issues > 0)
           AND NVL(in_internal_audit_type, ia.internal_audit_type_id) = ia.internal_audit_type_id
           AND (v_my_audits_only = 0 OR ia.auditor_user_sid = security_pkg.GetSid)
           AND (in_flow_state_id IS NULL OR fi.current_state_id = in_flow_state_id)
           AND (ia.flow_item_id IS NULL OR cap_t.column_value IS NOT NULL)
         ORDER BY tgm.tag_group_id, tgm.pos;
END;

PROCEDURE BrowseDueAudits(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_company_region_sid    security_pkg.T_SID_ID;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_region_sid_table        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_parent_region_sids);
BEGIN

    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            OPEN out_cur FOR
                SELECT null internal_audit_sid, null region_sid, null region_description, null audit_dtm, null label,
                       null auditor_user_sid, null auditor_full_name, null survey_completed,
                       null open_non_compliances, null auditor_name, null auditor_organisation
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
    END;

    OPEN out_cur FOR
        SELECT ad.internal_audit_sid, ad.region_sid, r.description region_description,
               r.region_type, rt.class_name region_type_class_name, iat.label audit_type_label,
               ad.audit_closure_type_id, ad.closure_label, ad.icon_image_filename,
               ad.next_audit_due_dtm, ad.internal_audit_type_id, ad.icon_image_sha1
          FROM v$audit_next_due ad
          JOIN v$region r ON ad.region_sid = r.region_sid AND ad.app_sid = r.app_sid
          JOIN region_type rt ON r.region_type = rt.region_type
          JOIN internal_audit_type iat ON ad.internal_audit_type_id = iat.internal_audit_type_id
           AND ad.app_sid = iat.app_sid
           LEFT JOIN flow_item fi
            ON ad.flow_item_id = fi.flow_item_id
          JOIN (
                SELECT DISTINCT app_sid, nvl(link_to_region_sid, region_sid) region_sid
                  FROM region /* we want the child regions of all input region sids*/
                 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid IN (
                     SELECT column_value
                       FROM TABLE (v_region_sid_table)
                    )
                CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
                ) rtree ON ad.region_sid = rtree.region_sid AND ad.app_sid = rtree.app_sid
               -- This filters by permission and filters out items in the trash
          JOIN TABLE(
                v_table
                ) so ON ad.internal_audit_sid = so.column_value
          LEFT JOIN region_role_member rrm ON ad.region_sid = rrm.region_sid
           AND iat.auditor_role_sid = rrm.role_sid AND ad.app_sid = rrm.app_sid AND rrm.user_sid = security_pkg.GetSid
         WHERE (in_start_dtm IS NULL OR ad.next_audit_due_dtm >= in_start_dtm)
           AND (in_end_dtm IS NULL OR ad.next_audit_due_dtm < in_end_dtm)
           AND (in_internal_audit_type IS NULL OR ad.internal_audit_type_id = in_internal_audit_type)
           AND (in_flow_state_id IS NULL OR fi.current_state_id = in_flow_state_id)
           AND (in_my_audits_only = 0 OR ad.previous_auditor_user_sid = security_pkg.GetSid OR rrm.user_sid = security_pkg.GetSid);
END;

PROCEDURE GetFlowStateCounts(
    in_start_dtm            IN    DATE,
    in_end_dtm                IN    DATE,
    in_parent_region_sids    IN    security_pkg.T_SID_IDS,
    in_open_non_compliance    IN    NUMBER,
    in_overdue                IN    NUMBER,
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    in_flow_state_id        IN    flow_state.flow_state_id%TYPE,
    in_my_audits_only        IN    NUMBER,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_region_sid_table        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_parent_region_sids);
BEGIN
    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            OPEN out_cur FOR
                SELECT null label, 0 count
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
    END;

    OPEN out_cur FOR
        SELECT a.flow_state_label label, count(*) count
          FROM v$audit a
          JOIN (
                 /* hierarchical query might be an overkill for a large input of regions sids */
                SELECT DISTINCT app_sid, nvl(link_to_region_sid, region_sid) region_sid
                  FROM region /* we want the child regions of all input region sids*/
                 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid IN (
                    SELECT column_value
                      FROM TABLE (v_region_sid_table)
                 )
                CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
                ) r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
               -- This filters by permission and filters out items in the trash
          JOIN TABLE(
                v_table
                ) so ON a.internal_audit_sid = so.column_value
          LEFT JOIN region_role_member rrm ON a.region_sid = rrm.region_sid
           AND a.auditor_role_sid = rrm.role_sid AND a.app_sid = rrm.app_sid AND rrm.user_sid = security_pkg.GetSid
         WHERE (in_start_dtm IS NULL OR a.audit_dtm >= in_start_dtm)
           AND (in_end_dtm IS NULL OR a.audit_dtm < in_end_dtm)
           AND (in_open_non_compliance = 0 OR a.open_non_compliances > 0)
           AND (in_overdue = 0 OR (a.audit_dtm < SYSDATE AND a.survey_completed IS NULL AND a.survey_sid IS NOT NULL))
           AND (in_internal_audit_type IS NULL OR a.internal_audit_type_id = in_internal_audit_type)
           AND (in_my_audits_only = 0 OR a.auditor_user_sid = security_pkg.GetSid OR rrm.user_sid = security_pkg.GetSid)
           AND (in_flow_state_id IS NULL OR a.current_state_id = in_flow_state_id)
           AND a.flow_state_label IS NOT NULL
         GROUP BY a.flow_state_label;
END;

PROCEDURE GetNonComplianceAudits(
    in_non_compliance_ids    IN security_pkg.T_SID_IDS, -- not sids, but this the closest type
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_non_compliance_table    security.T_SID_TABLE;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
BEGIN
    v_non_compliance_table := security_pkg.SidArrayToTable(in_non_compliance_ids);

    OPEN out_cur FOR
        SELECT nc.non_compliance_id, anc.internal_audit_sid, iat.internal_audit_type_group_id,
               CASE WHEN anc.repeat_of_audit_nc_id IS NULL THEN 0 ELSE 1 END is_repeat,
               ria.internal_audit_sid repeat_of_audit_sid, ria.label repeat_of_audit_label, ria.audit_dtm repeat_of_audit_dtm,
               rnc.non_compliance_id repeat_of_non_compliance_id, rnc.label repeat_of_non_compliance_label,
               CASE WHEN anc.attached_to_primary_survey = 1 THEN 0 ELSE anc.internal_audit_type_survey_id END internal_audit_type_survey_id
          FROM non_compliance nc
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN TABLE(v_table) sec_tbl ON sec_tbl.column_value = anc.internal_audit_sid
          JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id AND iat.app_sid = ia.app_sid
          LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id AND ranc.app_sid = anc.app_sid
          LEFT JOIN internal_audit ria ON ranc.internal_audit_sid = ria.internal_audit_sid AND anc.app_sid = ria.app_sid
          LEFT JOIN non_compliance rnc ON ranc.non_compliance_id = rnc.non_compliance_id AND anc.app_sid = rnc.app_sid
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND nc.non_compliance_id IN (SELECT * FROM TABLE (v_non_compliance_table))
      ORDER BY nc.non_compliance_id;
END;

PROCEDURE GetIssueTypeFromAudit (
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_issue_type_cur        OUT    SYS_REFCURSOR
)
AS
    v_issue_type_id            issue_type.issue_type_id%TYPE;
BEGIN
    BEGIN
        SELECT iatg.issue_type_id
          INTO v_issue_type_id
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN internal_audit_type_group iatg ON iat.internal_audit_type_group_id = iatg.internal_audit_type_group_id  AND iat.app_sid = iatg.app_sid
         WHERE ia.app_sid = SYS_CONTEXT('SECURITY','APP')
           AND ia.deleted = 0
           AND ia.internal_audit_sid = in_internal_audit_sid;
    EXCEPTION
        WHEN no_data_found THEN
            v_issue_type_id := NULL;
    END;

    issue_pkg.GetIssueType(NVL(v_issue_type_id, csr_data_pkg.ISSUE_NON_COMPLIANCE), out_issue_type_cur);
END;

PROCEDURE GetDetails(
    in_sid_id                IN    security_pkg.T_SID_ID,
    out_details_cur            OUT    SYS_REFCURSOR,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_upload_cur        OUT    SYS_REFCURSOR,
    out_nc_tag_cur            OUT    SYS_REFCURSOR,
    out_documents_cur        OUT SYS_REFCURSOR
)
AS
BEGIN
    GetDetails(in_sid_id, out_details_cur);
    GetExtraDetails(in_sid_id, out_nc_cur, out_nc_upload_cur, out_nc_tag_cur, out_documents_cur);
END;

PROCEDURE GetExtraDetails(
    in_sid_id                IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_upload_cur        OUT    SYS_REFCURSOR,
    out_nc_tag_cur            OUT    SYS_REFCURSOR,
    out_documents_cur        OUT SYS_REFCURSOR
)
AS
    v_permissible_nct_ids    security.T_SID_TABLE := GetPermissibleNCTypeIds(in_sid_id, security.security_pkg.PERMISSION_READ);
    v_cap_anc                 NUMBER := SQL_HasCapabilityAccess(in_sid_id, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security.security_pkg.PERMISSION_READ);
BEGIN
    IF NOT (HasReadAccess(in_sid_id)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_sid_id);
    END IF;

    OPEN out_nc_cur FOR
        SELECT nc.non_compliance_id, nc.label, nc.detail, nc.from_non_comp_default_id,
               nc.created_dtm, nc.created_in_audit_sid, cia.internal_audit_type_id created_in_audit_type_id,
               nc.created_by_user_sid, cc.full_name created_by_full_name, nc.root_cause, nc.suggested_action,
               ia.internal_audit_sid sid_id, ia.label audit_label,
               NVL(i.closed_issues, 0) closed_issues, NVL(i.total_issues, 0) total_issues,
               NVL(i.open_issues, 0) open_issues, r.region_sid, r.description region_description,
               qsr.survey_response_id, 
               CASE WHEN anc.attached_to_primary_survey = 1 THEN 0 ELSE anc.internal_audit_type_survey_id END internal_audit_type_survey_id,
               qsq.question_id, qsq.label question_label,
               qsqo.question_option_id, qsqo.label question_option_label,
               nc.non_compliance_type_id, nct.label non_compliance_type_label, nc.is_closed,
               NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, null) custom_non_compliance_id, in_sid_id internal_audit_sid,
               substr(nc_folders.path, 2) non_compliance_folder_path, ncd.unique_reference def_non_comp_unique_ref,
               CASE WHEN anc.repeat_of_audit_nc_id IS NULL THEN 0 ELSE 1 END is_repeat,
               ria.internal_audit_sid repeat_of_audit_sid, ria.label repeat_of_audit_label, ria.audit_dtm repeat_of_audit_dtm,
               rnc.non_compliance_id repeat_of_non_compliance_id, rnc.label repeat_of_non_compliance_label
          FROM non_compliance nc
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
          JOIN internal_audit cia On nc.created_in_audit_sid = cia.internal_audit_sid AND nc.app_sid = cia.app_sid
          LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
          LEFT JOIN internal_audit_survey ias ON ias.internal_audit_sid = ia.internal_audit_sid AND ias.internal_audit_type_survey_id = anc.internal_audit_type_survey_id AND ias.app_sid = ia.app_sid
          LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id AND ranc.app_sid = anc.app_sid
          LEFT JOIN internal_audit ria ON ranc.internal_audit_sid = ria.internal_audit_sid AND anc.app_sid = ria.app_sid
          LEFT JOIN non_compliance rnc ON ranc.non_compliance_id = rnc.non_compliance_id AND anc.app_sid = rnc.app_sid
          JOIN csr_user cc ON nc.created_by_user_sid = cc.csr_user_sid AND nc.app_sid = cc.app_sid
          LEFT JOIN v$region r ON nc.region_sid = r.region_sid AND ia.app_sid = r.app_sid
          LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
          LEFT JOIN (
                SELECT inc.app_sid, inc.non_compliance_id,
                       COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
                       COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
                  FROM issue_non_compliance inc, issue i
                 WHERE inc.app_sid = i.app_sid
                   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
                   AND i.deleted = 0
                 GROUP BY inc.app_sid, inc.non_compliance_id
                ) i ON nc.non_compliance_id = i.non_compliance_id AND nc.app_sid = i.app_sid
          LEFT JOIN quick_survey_response qsr ON NVL(ias.survey_response_id, CASE WHEN anc.attached_to_primary_survey = 1 THEN ia.survey_response_id ELSE NULL END) = qsr.survey_response_id
          LEFT JOIN quick_survey_question qsq ON qsq.question_id = nc.question_id AND qsq.survey_version = qsr.survey_version AND qsq.survey_sid = qsr.survey_sid
          LEFT JOIN qs_question_option qsqo ON qsqo.question_id = nc.question_id AND qsqo.question_option_id = nc.question_option_id AND qsqo.survey_version = qsr.survey_version
          LEFT JOIN non_comp_default ncd ON nc.from_non_comp_default_id = ncd.non_comp_default_id AND nc.app_sid = ncd.app_sid
          LEFT JOIN (
                  SELECT non_comp_default_folder_id, sys_connect_by_path(replace(label, '|', '-'), '|') path
                  FROM non_comp_default_folder
                 START WITH parent_folder_id IS NULL
               CONNECT BY PRIOR non_comp_default_folder_id = parent_folder_id
          ) nc_folders ON ncd.non_comp_default_folder_id = nc_folders.non_comp_default_folder_id
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND anc.internal_audit_sid = in_sid_id
           AND (ia.flow_item_id IS NULL OR (
               (nc.non_compliance_type_id IS NULL AND v_cap_anc = 1) OR 
               (nc.non_compliance_type_id IS NOT NULL AND pnct.column_value IS NOT NULL)
            ))
         ORDER BY nct.position, nct.label, nc.non_compliance_id;

    OPEN out_nc_upload_cur FOR
        SELECT nc.non_compliance_id, ncf.non_compliance_file_id, ncf.filename, ncf.mime_type, cast(ncf.sha1 as varchar2(40)) sha1, ncf.uploaded_dtm
          FROM csr.non_compliance_file ncf
          JOIN csr.non_compliance nc ON nc.non_compliance_id = ncf.non_compliance_id AND nc.app_sid = ncf.app_sid
          JOIN csr.audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN csr.internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND ia.app_sid = anc.app_sid
          LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND ia.internal_audit_sid = in_sid_id
           AND (ia.flow_item_id IS NULL OR (
               (nc.non_compliance_type_id IS NULL AND v_cap_anc = 1) OR 
               (nc.non_compliance_type_id IS NOT NULL AND pnct.column_value IS NOT NULL)
            ))
         ORDER BY nc.non_compliance_id, ncf.non_compliance_file_id;

    OPEN out_nc_tag_cur FOR    
        SELECT nc.non_compliance_id, nct.tag_id, nct.tag_group_id, nct.tag
          FROM non_compliance nc
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN tag_group_ir_member nct ON nc.non_compliance_id = nct.non_compliance_id
          JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
          LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND anc.internal_audit_sid = in_sid_id
           AND (ia.flow_item_id IS NULL OR (
               (nc.non_compliance_type_id IS NULL AND v_cap_anc = 1) OR 
               (nc.non_compliance_type_id IS NOT NULL AND pnct.column_value IS NOT NULL)
            ))
          ORDER BY nc.non_compliance_id, nct.tag_group_id, nct.pos, nct.tag_id;

    GetDocuments(
        in_internal_audit_sid     => in_sid_id,
        out_cur                    => out_documents_cur
    );
END;

PROCEDURE GetNonComplianceFile(
    in_noncompliance_file_id    IN    non_compliance_file.non_compliance_file_id%TYPE,
    in_sha1                        IN    VARCHAR2,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_noncompliance_id            non_compliance.non_compliance_id%TYPE;
BEGIN
    SELECT non_compliance_id
      INTO v_noncompliance_id
      FROM non_compliance_file
     WHERE non_compliance_file_id = in_noncompliance_file_Id
       AND sha1 = in_sha1;

    CheckNonComplianceReadable(v_noncompliance_id);

    OPEN out_cur FOR
        SELECT filename, mime_type, data, cast(sha1 as varchar2(40)) sha1, uploaded_dtm
          FROM non_compliance_file
         WHERE non_compliance_file_id = in_noncompliance_file_id
           AND sha1 = in_sha1;
END;

PROCEDURE GetDetailsForMailMerge(
    in_sid_id                    IN    security_pkg.T_SID_ID,
    in_report_id                 IN  security_pkg.T_SID_ID,
    out_details_cur                OUT    SYS_REFCURSOR,
    out_nc_cur                    OUT    SYS_REFCURSOR,
    out_nc_upload_cur            OUT    SYS_REFCURSOR,
    out_nc_tag_cur                OUT    SYS_REFCURSOR,
    out_issues_cur                OUT    SYS_REFCURSOR,
    out_template_cur            OUT    SYS_REFCURSOR,
    out_issues_fields_cur        OUT    SYS_REFCURSOR,
    out_issue_logs_cur            OUT SYS_REFCURSOR,
    out_issue_log_files_cur        OUT    SYS_REFCURSOR,
    out_issue_action_log_cur    OUT    SYS_REFCURSOR
)
AS
    v_internal_audit_type_id    internal_audit_type.internal_audit_type_id%TYPE;
    v_dummy_cur                    SYS_REFCURSOR;
BEGIN
    GetDetails(in_sid_id, out_details_cur, out_nc_cur, out_nc_upload_cur, out_nc_tag_cur, v_dummy_cur);

    SELECT internal_audit_type_id
      INTO v_internal_audit_type_id
      FROM internal_audit
     WHERE internal_audit_sid = in_sid_id;

    GetTemplate(v_internal_audit_type_id, in_report_id, out_template_cur);

    OPEN out_issues_cur FOR
        SELECT i.issue_id, i.label, i.description, i.resolved_dtm, i.manual_completion_dtm, nc.non_compliance_id,
               CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
               CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected,
               assigned_to_user_sid, NVL(cu.full_name, rl.name) assigned_to_full_name,
               raised_by_user_sid, rcu.full_name raised_by_full_name, i.due_dtm,
               ip.description priority, NVL2(i.issue_ref, it.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id,
               il.message latest_edit, il.logged_dtm latest_edit_dtm, cuil.full_name latest_edit_full_name, i.forecast_dtm, i.var_expl overdue_note,
               i.correspondent_id, cor.full_name correspondent_full_name
          FROM issue i
          JOIN issue_type it ON i.issue_type_id = it.issue_type_id AND i.app_sid = it.app_sid
          JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
          JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          LEFT JOIN csr_user cu ON i.assigned_to_user_sid = cu.csr_user_sid AND i.app_sid = cu.app_sid
          LEFT JOIN role rl ON i.assigned_to_role_sid = rl.role_sid AND i.app_sid = rl.app_sid
          JOIN csr_user rcu ON i.raised_by_user_sid = rcu.csr_user_sid AND i.app_sid = rcu.app_sid
          LEFT JOIN issue_priority ip ON i.issue_priority_id = ip.issue_priority_id AND i.app_sid = ip.app_sid
          LEFT JOIN issue_log il ON i.last_issue_log_id = il.issue_log_id AND i.app_sid = il.app_sid
          LEFT JOIN csr_user cuil ON il.logged_by_user_sid = cuil.csr_user_sid AND il.app_sid = cuil.app_sid
          LEFT JOIN correspondent cor ON i.correspondent_id = cor.correspondent_id
         WHERE anc.internal_audit_sid = in_sid_id
           AND i.deleted = 0;

    OPEN out_issues_fields_cur FOR
        SELECT i.issue_id, nc.non_compliance_id, isf.issue_custom_field_id, MIN(isf.label) custom_field_label,
               stragg(NVL(vals.string_value, op.label)) value, MIN(isf.field_type)
          FROM issue i
          JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
          JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN (
            SELECT issue_id, string_value, null issue_custom_field_opt_id, issue_custom_field_id
              FROM issue_custom_field_str_val sv
             UNION
            SELECT issue_id, null, issue_custom_field_opt_id, issue_custom_field_id
              FROM issue_custom_field_opt_sel
             UNION
            SELECT issue_id, TO_CHAR(date_value, 'DD-MON-YYYY'), null, issue_custom_field_id
              FROM issue_custom_field_date_val
               ) vals ON i.issue_id = vals.issue_id
          JOIN issue_custom_field isf ON vals.issue_custom_field_id = isf.issue_custom_field_id
          JOIN TABLE(csr.issue_pkg.GetPermissibleCustomFields(i.issue_type_id)) pcf on pcf.column_value = isf.issue_custom_field_id
          LEFT JOIN issue_custom_field_option op ON vals.issue_custom_field_opt_id = op.issue_custom_field_opt_id AND vals.issue_custom_field_id = op.issue_custom_field_id
         WHERE anc.internal_audit_sid = in_sid_id
           AND i.deleted = 0
         GROUP BY i.issue_id, nc.non_compliance_id, isf.issue_custom_field_id;

    OPEN out_issue_logs_cur FOR
        SELECT i.issue_id, il.issue_log_id, il.message, il.logged_dtm, il.logged_by_user_sid, il.logged_by_correspondent_id,
               lbu.full_name logged_by_user_full_name, cor.full_name logged_by_correspondent_full_name
          FROM issue i
          JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
          JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN issue_log il ON i.issue_id = il.issue_id
     LEFT JOIN csr_user lbu ON il.logged_by_user_sid = lbu.csr_user_sid
     LEFT JOIN correspondent cor ON il.logged_by_correspondent_id = cor.correspondent_id
         WHERE anc.internal_audit_sid = in_sid_id
           AND i.deleted = 0;

    OPEN out_issue_log_files_cur FOR
        SELECT i.issue_id, ilf.issue_log_file_id, ilf.issue_log_id, ilf.filename, ilf.mime_type, ilf.uploaded_dtm, cast(ilf.sha1 as varchar2(40)) as SHA1
          FROM issue i
          JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
          JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN issue_log il ON i.issue_id = il.issue_id
          JOIN issue_log_file ilf ON il.issue_log_id = ilf.issue_log_id
         WHERE anc.internal_audit_sid = in_sid_id
           AND i.deleted = 0;

    OPEN out_issue_action_log_cur FOR
        SELECT ial.issue_action_log_id, ial.issue_action_type_id, ial.issue_id, ial.issue_log_id, 
                ial.logged_by_user_sid, ial.logged_by_correspondent_id,
                lcu.user_name logged_by_user_name, lcu.full_name logged_by_user_full_name, c.full_name logged_by_correspondent_full_name, NVL(lcu.email, c.email) logged_by_email, 
                ial.logged_dtm, SYSDATE now_dtm, ial.assigned_to_role_sid, ar.name assigned_to_role_name,
                ial.assigned_to_user_sid, acu.user_name assigned_to_user_name, acu.full_name assigned_to_full_name, acu.email assigned_to_email,
                ial.owner_user_sid, ocu.user_name owner_user_name, ocu.full_name owner_full_name, ocu.email owner_email,
                ial.re_user_sid, reu.user_name re_user_name, reu.full_name re_full_name, reu.email re_email,
                ial.re_role_sid, rer.name re_role_name,
                ial.old_due_dtm, ial.new_due_dtm, ial.old_forecast_dtm, ial.new_forecast_dtm, ial.old_priority_id, ial.new_priority_id, ial.old_label, ial.new_label,
                ial.old_description, ial.new_description, ial.new_manual_comp_dtm_set_dtm, ial.new_manual_comp_dtm,
                oip.description old_priority_description, nip.description new_priority_description
          FROM issue i
          JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
          JOIN non_compliance nc         ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN issue_action_log ial        ON i.issue_id = ial.issue_id
     LEFT JOIN csr_user lcu             ON ial.logged_by_user_sid = lcu.csr_user_sid
     LEFT JOIN role ar                    ON ial.assigned_to_role_sid = ar.role_sid
     LEFT JOIN csr_user acu                ON ial.assigned_to_user_sid = acu.csr_user_sid
     LEFT JOIN csr_user ocu                ON ial.owner_user_sid = ocu.csr_user_sid
     LEFT JOIN correspondent c            ON ial.logged_by_correspondent_id = c.correspondent_id
     LEFT JOIN csr_user reu                ON ial.re_user_sid = reu.csr_user_sid
     LEFT JOIN role rer                    ON ial.re_role_sid = rer.role_sid
     LEFT JOIN issue_priority oip        ON ial.old_priority_id = oip.issue_priority_id
     LEFT JOIN issue_priority nip        ON ial.old_priority_id = nip.issue_priority_id
         WHERE anc.internal_audit_sid = in_sid_id
           AND i.deleted = 0;

END;

PROCEDURE GetDetailsForMailMergeAllFiles(
    in_sid_id                    IN    security_pkg.T_SID_ID,
    in_report_id                 IN  security_pkg.T_SID_ID,
    out_details_cur                OUT    SYS_REFCURSOR,
    out_nc_cur                    OUT    SYS_REFCURSOR,
    out_nc_upload_cur            OUT    SYS_REFCURSOR,
    out_nc_tag_cur                OUT    SYS_REFCURSOR,
    out_issues_cur                OUT    SYS_REFCURSOR,
    out_template_cur            OUT    SYS_REFCURSOR,
    out_issues_fields_cur        OUT    SYS_REFCURSOR,
    out_postit_files_cur        OUT SYS_REFCURSOR,
    out_audit_files_cur            OUT SYS_REFCURSOR,
    out_issue_logs_cur            OUT SYS_REFCURSOR,
    out_issue_log_files_cur        OUT    SYS_REFCURSOR,
    out_issue_action_log_cur    OUT    SYS_REFCURSOR
)
AS
BEGIN
    GetDetailsForMailMerge(in_sid_id, in_report_id, out_details_cur,
        out_nc_cur, out_nc_upload_cur, out_nc_tag_cur,
        out_issues_cur, out_template_cur, out_issues_fields_cur, out_issue_logs_cur, out_issue_log_files_cur, out_issue_action_log_cur);

    OPEN out_postit_files_cur FOR
        SELECT pf.postit_id, pf.postit_file_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1
        FROM internal_audit_postit iapi
        JOIN postit_file pf ON pf.postit_id=iapi.postit_id
        WHERE iapi.internal_audit_sid = in_sid_id;

    OPEN out_audit_files_cur FOR
        SELECT iafd.internal_audit_file_data_id, iafd.filename, iafd.mime_type, cast(iafd.sha1 as varchar2(40)) sha1
        FROM internal_audit_file iaf
        JOIN internal_audit_file_data iafd ON iaf.internal_audit_file_data_id = iafd.internal_audit_file_data_id
        WHERE iaf.internal_audit_sid = in_sid_id;
END;

PROCEDURE GetNonCompliancesForAudit(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR
)
AS
    v_permissible_nct_ids    security.T_SID_TABLE := GetPermissibleNCTypeIds(in_internal_audit_sid, security.security_pkg.PERMISSION_READ);
    v_cap_anc                 NUMBER := SQL_HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security.security_pkg.PERMISSION_READ);
BEGIN
    IF NOT HasReadAccess(in_internal_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_internal_audit_sid);
    END IF;
    
    -- Not sure why internal_audit_sid is set to sid_id so just leave it...
    -- Only reference is "FB35285 - Bettercoal - Update audits security to work based on roles"
    OPEN out_nc_cur FOR
        SELECT nc.non_compliance_id, nc.label, nc.detail, nc.created_dtm, nc.created_by_user_sid, nc.lookup_key,
               ia.internal_audit_sid, ia.internal_audit_sid sid_id, ia.label audit_label, cc.full_name created_by_full_name,
               NVL(i.closed_issues, 0) closed_issues, NVL(i.total_issues, 0) total_issues, nc.root_cause, nc.suggested_action,
               NVL(i.open_issues, 0) open_issues, r.region_sid, r.description region_description,
               nc.non_compliance_type_id, nct.label non_compliance_type_label, nc.is_closed, nc.override_score,
               CASE WHEN anc.repeat_of_audit_nc_id IS NULL THEN 0 ELSE 1 END is_repeat,
               ranc.internal_audit_sid repeat_of_audit_sid, ranc.non_compliance_id repeat_of_non_compliance_id
          FROM non_compliance nc
          JOIN csr_user cc ON nc.created_by_user_sid = cc.csr_user_sid AND nc.app_sid = cc.app_sid
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id AND ranc.app_sid = anc.app_sid
          JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid AND nc.app_sid = ia.app_sid AND anc.internal_audit_sid = ia.internal_audit_sid
          LEFT JOIN v$region r ON r.region_sid = NVL(nc.region_sid, ia.region_sid) AND r.app_sid = nc.app_sid
          LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
          LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nct.non_compliance_type_id
          LEFT JOIN (
                SELECT inc.app_sid, inc.non_compliance_id,
                       COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
                       COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
                  FROM issue_non_compliance inc, issue i
                 WHERE inc.app_sid = i.app_sid
                   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
                 GROUP BY inc.app_sid, inc.non_compliance_id
                ) i ON nc.non_compliance_id = i.non_compliance_id AND nc.app_sid = i.app_sid
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND anc.internal_audit_sid = in_internal_audit_sid
           AND (ia.flow_item_id IS NULL OR (
               (nc.non_compliance_type_id IS NULL AND v_cap_anc = 1) OR 
               (nc.non_compliance_type_id IS NOT NULL AND pnct.column_value IS NOT NULL)
            ))
         ORDER BY nct.position, nc.non_compliance_id;
END;

PROCEDURE GetNonCompliancesForAudit(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_tags_cur            OUT    SYS_REFCURSOR
)
AS
BEGIN
    GetNonCompliancesForAudit(in_internal_audit_sid, out_nc_cur);

    OPEN out_nc_tags_cur FOR
        SELECT anc.non_compliance_id, nct.tag_id, nct.tag_group_id, nct.tag
          FROM audit_non_compliance anc
          JOIN tag_group_ir_member nct ON anc.non_compliance_id = nct.non_compliance_id
         WHERE anc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND anc.internal_audit_sid = in_internal_audit_sid
          ORDER BY anc.non_compliance_id, nct.tag_group_id, nct.pos, nct.tag_id;
END;

PROCEDURE ExportAuditsFindingsAndActions(
    in_internal_audit_type    IN    internal_audit.internal_audit_type_id%TYPE,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_tags_cur            OUT    SYS_REFCURSOR,
    out_issue_fields_cur    OUT    SYS_REFCURSOR,
    out_audit_tags_cur        OUT    SYS_REFCURSOR,
    out_scores_cur            OUT    SYS_REFCURSOR
)
AS
BEGIN

    IF security.user_pkg.IsSuperAdmin <> 1 THEN
        RAISE_APPLICATION_ERROR(security.Security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions to Export Audits');
    END IF;

    OPEN out_nc_cur FOR
        SELECT ia.internal_audit_sid, ia.internal_audit_ref, ia.label audit_label, ia.audit_dtm, iat.label internal_audit_type, iar.region_sid audit_region_sid,
               iar.name audit_region_name, act.label audit_result, audit_user.full_name audit_coordinator, ia.auditor_name auditor, ia.auditor_organisation audit_organisation, ia.notes audit_notes,
               ia.ovw_validity_dtm,
               nc.non_compliance_id finding_id, i.issue_id action_id,
               nc.label finding_label, nc.detail finding_detail, nct.label finding_type,
               nc.region_sid, r.description region_description, nc.root_cause, nc.suggested_action,
               qsq.lookup_key question_lookup_key, nc.is_closed,
               i.label action_label, i.description action_detail, i.due_dtm due_dtm,
               i.assigned_to_user_sid, acu.full_name assigned_to_full_name,
               i.assigned_to_role_sid, rl.name assigned_to_role_name,
               ip.description action_priority,
               CASE
                WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
                WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
                WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
                WHEN i.issue_id IS NOT NULL THEN 'Ongoing' 
               END action_status,
               sa.auditor_company_sid, sa.created_by_company_sid, sa.supplier_company_sid auditee_company_sid
          FROM internal_audit ia
          LEFT JOIN audit_non_compliance anc
            ON ia.internal_audit_sid = anc.internal_audit_sid
          LEFT JOIN non_compliance nc
            ON nc.non_compliance_id = anc.non_compliance_id
          JOIN internal_audit_type iat
            ON iat.internal_audit_type_id = ia.internal_audit_type_id
          JOIN region iar
            ON iar.region_sid = ia.region_sid
          LEFT JOIN audit_closure_type act
            ON ia.audit_closure_type_id = act.audit_closure_type_id
          LEFT JOIN csr_user audit_user
            ON audit_user.csr_user_sid = ia.auditor_user_sid   
          LEFT JOIN issue_non_compliance inc
            ON nc.non_compliance_id = inc.non_compliance_id
          LEFT JOIN issue i
            ON inc.issue_non_compliance_id = i.issue_non_compliance_id
           AND i.deleted = 0
          LEFT JOIN v$region r
            ON nc.region_sid = r.region_sid
          LEFT JOIN non_compliance_type nct
            ON nc.non_compliance_type_id = nct.non_compliance_type_id
          LEFT JOIN csr_user acu
            ON i.assigned_to_user_sid = acu.csr_user_sid
          LEFT JOIN role rl
            ON i.assigned_to_role_sid = rl.role_sid
          LEFT JOIN issue_priority ip
            ON i.issue_priority_id = ip.issue_priority_id
          LEFT JOIN quick_survey_question qsq
            ON nc.question_id = qsq.question_id
           AND qsq.survey_version = 0 -- link to draft survey, we know we always have a draft version and question could come from exec summary
          LEFT JOIN chain.supplier_audit sa
            ON sa.audit_sid = ia.internal_audit_sid

         WHERE ia.internal_audit_type_id = in_internal_audit_type
           AND ia.deleted = 0
         ORDER BY ia.internal_audit_sid desc;

    OPEN out_nc_tags_cur FOR
        SELECT anc.non_compliance_id finding_id, nct.tag_id, nct.tag_group_id, nct.tag
          FROM audit_non_compliance anc
          JOIN tag_group_ir_member nct
            ON anc.non_compliance_id = nct.non_compliance_id
          JOIN internal_audit ia
            ON ia.internal_audit_sid = anc.internal_audit_sid
         WHERE ia.internal_audit_type_id = in_internal_audit_type;

    OPEN out_issue_fields_cur FOR
        SELECT i.issue_id action_id, isf.issue_custom_field_id, isf.label custom_field_label,
               NVL(vals.string_value, op.label) value, vals.date_value, isf.field_type
          FROM issue i
          JOIN issue_non_compliance inc
            ON i.issue_non_compliance_id = inc.issue_non_compliance_id
          JOIN audit_non_compliance anc
            ON inc.non_compliance_id = anc.non_compliance_id
          JOIN internal_audit ia
            ON ia.internal_audit_sid = anc.internal_audit_sid
          JOIN (
            SELECT issue_id, string_value, null issue_custom_field_opt_id, issue_custom_field_id, null date_value
              FROM issue_custom_field_str_val sv
             UNION
            SELECT issue_id, null, issue_custom_field_opt_id, issue_custom_field_id, null
              FROM issue_custom_field_opt_sel
             UNION
            SELECT issue_id, null, null, issue_custom_field_id, date_value
              FROM issue_custom_field_date_val
               ) vals ON i.issue_id = vals.issue_id
          JOIN issue_custom_field isf ON vals.issue_custom_field_id = isf.issue_custom_field_id
          LEFT JOIN issue_custom_field_option op ON vals.issue_custom_field_opt_id = op.issue_custom_field_opt_id AND vals.issue_custom_field_id = op.issue_custom_field_id
         WHERE ia.internal_audit_type_id = in_internal_audit_type
           AND i.deleted = 0;

    OPEN out_audit_tags_cur FOR
        SELECT ia.internal_audit_sid, t.tag_id, t.tag, tg.tag_group_id
          FROM internal_audit ia
          JOIN internal_audit_tag at ON ia.internal_audit_sid = at.internal_audit_sid AND ia.app_sid = at.app_sid
          JOIN v$tag t ON at.app_sid = t.app_sid and at.tag_id = t.tag_id
          JOIN tag_group_member tgm ON t.app_sid = tgm.app_sid and t.tag_id = tgm.tag_id
          JOIN tag_group tg ON tgm.app_sid = tg.app_sid and tgm.tag_group_id = tg.tag_group_id
         WHERE ia.app_sid = security.security_pkg.GetApp
           AND ia.internal_audit_type_id = in_internal_audit_type;

    OPEN out_scores_cur FOR
        SELECT ias.internal_audit_sid, ias.score, ias.score_threshold_id,
               st.label score_type_label, sth.description score_threshold_description
          FROM internal_audit_score ias
          JOIN internal_audit ia ON ias.internal_audit_sid = ia.internal_audit_sid
          JOIN score_type st ON st.score_type_id = ias.score_type_id
          LEFT JOIN score_threshold sth ON sth.score_threshold_id = ias.score_threshold_id
         WHERE ias.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND ia.internal_audit_type_id = in_internal_audit_type
           AND st.applies_to_audits = 1
         ORDER BY st.pos;
END;

-- Export NCs and their actions in a format for round-tripping
-- i.e. one line per action with NC details duplicated
PROCEDURE ExportFindingsAndActions(
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    out_nc_cur                        OUT    SYS_REFCURSOR,
    out_nc_tags_cur                    OUT    SYS_REFCURSOR,
    out_issue_fields_cur            OUT    SYS_REFCURSOR
)
AS
    v_has_read_on_nc_type            BINARY_INTEGER;
    v_permissible_custom_fields        security.T_SID_TABLE;
BEGIN
    IF NOT HasReadAccess(in_internal_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_internal_audit_sid);
    END IF;

    IF IsFlowAudit(in_internal_audit_sid) THEN
        IF NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security_pkg.PERMISSION_READ) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading non-compliances on audit with sid '||in_internal_audit_sid);
        END IF;

        v_has_read_on_nc_type := SQL_HasCapabilityAccess(in_internal_audit_sid,
            csr_data_pkg.FLOW_CAP_AUDIT_FINDING_TYPE, security_pkg.PERMISSION_READ);
    ELSE
        v_has_read_on_nc_type := 1;
    END IF;

    v_permissible_custom_fields := csr.issue_pkg.GetPermissibleCustomFields();

    -- TODO: round-trip default non-compliances (ideally need a ref column on non_comp_default)

    OPEN out_nc_cur FOR
        SELECT nc.non_compliance_id finding_id, i.issue_id action_id,
               nc.label finding_label, nc.detail finding_detail, nct.label finding_type,
               nc.region_sid, r.description region_description, nc.root_cause, nc.suggested_action,
               qsq.lookup_key question_lookup_key, nc.is_closed,
               --nc.from_non_comp_default_id, ncd.label default_finding_label,
               i.label action_label, i.description action_detail, i.due_dtm due_dtm,
               i.assigned_to_user_sid, acu.full_name assigned_to_full_name,
               i.assigned_to_role_sid, rl.name assigned_to_role_name,
               i.owner_user_sid, own.full_name owner_full_name,
               ip.description action_priority,
               CASE
                WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
                WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
                WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
                ELSE 'Ongoing'
               END action_status
          FROM non_compliance nc
          JOIN audit_non_compliance anc
            ON nc.non_compliance_id = anc.non_compliance_id
          LEFT JOIN issue_non_compliance inc
            ON nc.non_compliance_id = inc.non_compliance_id
          LEFT JOIN issue i
            ON inc.issue_non_compliance_id = i.issue_non_compliance_id
           AND i.deleted = 0
          JOIN v$region r
            ON nc.region_sid = r.region_sid
          LEFT JOIN non_compliance_type nct
            ON nc.non_compliance_type_id = nct.non_compliance_type_id
           AND v_has_read_on_nc_type = 1 -- hide non-compliacne type if no read capability on it
          LEFT JOIN csr_user acu
            ON i.assigned_to_user_sid = acu.csr_user_sid
          LEFT JOIN csr_user own
            ON i.owner_user_sid = own.csr_user_sid
          LEFT JOIN role rl
            ON i.assigned_to_role_sid = rl.role_sid
          LEFT JOIN issue_priority ip
            ON i.issue_priority_id = ip.issue_priority_id
          LEFT JOIN quick_survey_question qsq
            ON nc.question_id = qsq.question_id
           AND qsq.survey_version = 0 -- link to draft survey, we know we always have a draft version and question could come from exec summary
        --LEFT JOIN non_comp_default ncd
        --  ON nc.from_non_comp_default_id = ncd.non_comp_default_id
         WHERE anc.internal_audit_sid = in_internal_audit_sid;

    OPEN out_nc_tags_cur FOR
        SELECT anc.non_compliance_id finding_id, nct.tag_id, nct.tag_group_id, nct.tag
          FROM audit_non_compliance anc
          JOIN tag_group_ir_member nct
            ON anc.non_compliance_id = nct.non_compliance_id
         WHERE anc.internal_audit_sid = in_internal_audit_sid;

    OPEN out_issue_fields_cur FOR
        SELECT i.issue_id action_id, icf.issue_custom_field_id, icf.label custom_field_label,
               NVL(vals.string_value, op.label) value, vals.date_value, icf.field_type
          FROM issue i
          JOIN issue_non_compliance inc
            ON i.issue_non_compliance_id = inc.issue_non_compliance_id
          JOIN audit_non_compliance anc
            ON inc.non_compliance_id = anc.non_compliance_id
          JOIN (
            SELECT issue_id, string_value, null issue_custom_field_opt_id, issue_custom_field_id, null date_value
              FROM issue_custom_field_str_val sv
             UNION
            SELECT issue_id, null, issue_custom_field_opt_id, issue_custom_field_id, null
              FROM issue_custom_field_opt_sel
             UNION
            SELECT issue_id, null, null, issue_custom_field_id, date_value
              FROM issue_custom_field_date_val
               ) vals ON i.issue_id = vals.issue_id
          JOIN issue_custom_field icf ON vals.issue_custom_field_id = icf.issue_custom_field_id
          JOIN TABLE(v_permissible_custom_fields) pcf on pcf.column_value = icf.issue_custom_field_id
          LEFT JOIN issue_custom_field_option op ON vals.issue_custom_field_opt_id = op.issue_custom_field_opt_id AND vals.issue_custom_field_id = op.issue_custom_field_id
         WHERE anc.internal_audit_sid = in_internal_audit_sid
           AND i.deleted = 0;
END;

PROCEDURE GetDefaultNCFoldersWithDepth(
    in_parent_id                IN    non_comp_default_folder.parent_folder_id%TYPE,
    in_fetch_depth                IN    NUMBER,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- no security - can read the folders that DNCs fall into (as you can read the DNCs without any special security)
    OPEN out_cur FOR
        SELECT *
          FROM (
            SELECT non_comp_default_folder_id, label, parent_folder_id,
                   LEVEL lvl, connect_by_isleaf is_leaf, ROWNUM rn
              FROM non_comp_default_folder
             WHERE level <= in_fetch_depth
             START WITH parent_folder_id = in_parent_id OR (in_parent_id IS NULL AND parent_folder_id IS NULL)
             CONNECT BY PRIOR non_comp_default_folder_id = parent_folder_id
             ORDER SIBLINGS BY LOWER(label)
          )
     ORDER BY rn;
END;

PROCEDURE CreateDefaultNonCompFolder (
    in_parent_id                IN    non_comp_default_folder.parent_folder_id%TYPE,
    in_label                    IN    non_comp_default_folder.label%TYPE,
    out_folder_id                OUT non_comp_default_folder.non_comp_default_folder_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can create folders');
    END IF;

    BEGIN
        INSERT INTO non_comp_default_folder(non_comp_default_folder_id, parent_folder_id, label)
             VALUES (non_comp_default_folder_id_seq.NEXTVAL, in_parent_id, in_label)
          RETURNING non_comp_default_folder_id INTO out_folder_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A folder with parent: '||in_parent_id||' and name: '||in_label||' already exists');
    END;
END;

PROCEDURE GetOrCreateDNCFolderFromPath (
    in_path                        IN    VARCHAR2,
    out_folder_id                OUT non_comp_default_folder.non_comp_default_folder_id%TYPE
)
AS
    v_folder_id                    non_comp_default_folder.non_comp_default_folder_id%TYPE;
BEGIN
    out_folder_id := NULL;

    FOR r IN (
        SELECT item folder_name
          FROM TABLE(aspen2.utils_pkg.splitstring(in_path, '|'))
    ) LOOP
        SELECT MIN(non_comp_default_folder_id)
          INTO v_folder_id
          FROM non_comp_default_folder
         WHERE LOWER(LTRIM(RTRIM(label))) = LOWER(LTRIM(RTRIM(r.folder_name)))
           AND NVL(parent_folder_id, -1) = NVL(out_folder_id, -1);

        IF v_folder_id IS NULL THEN
            CreateDefaultNonCompFolder(out_folder_id, r.folder_name, v_folder_id);
        END IF;

        out_folder_id := v_folder_id;

    END LOOP;
END;

PROCEDURE DeleteDefaultNonCompFolder (
    in_folder_id                IN    non_comp_default_folder.non_comp_default_folder_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete folders');
    END IF;

    FOR chk IN (
        SELECT * FROM dual
         WHERE EXISTS (SELECT * FROM non_comp_default_folder WHERE parent_folder_id = in_folder_id)
            OR EXISTS (SELECT * FROM non_comp_default WHERE non_comp_default_folder_id = in_folder_id)
    ) LOOP
        RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_USE, 'The folder with ID: '||in_folder_id||' cannot be deleted because it is not empty');
    END LOOP;

    DELETE FROM non_comp_default_folder
     WHERE non_comp_default_folder_id = in_folder_id;
END;

PROCEDURE RenameDefaultNonCompFolder (
    in_folder_id                IN    non_comp_default_folder.non_comp_default_folder_id%TYPE,
    in_label                    IN    non_comp_default_folder.label%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can rename folders');
    END IF;

    BEGIN
        UPDATE non_comp_default_folder
          SET label = in_label
         WHERE non_comp_default_folder_id = in_folder_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A folder with name: '||in_label||' already exists');
    END;
END;

PROCEDURE MoveDefaultNonCompFolder (
    in_folder_id                IN    non_comp_default_folder.non_comp_default_folder_id%TYPE,
    in_parent_id                IN    non_comp_default_folder.parent_folder_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can move folders');
    END IF;

    BEGIN
        UPDATE non_comp_default_folder
          SET parent_folder_id = in_parent_id
         WHERE non_comp_default_folder_id = in_folder_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A folder with the same name already exists');
    END;
END;

PROCEDURE MoveDefaultNonCompliance (
    in_default_non_comp_id        IN    non_comp_default.non_comp_default_id%TYPE,
    in_parent_id                IN    non_comp_default.non_comp_default_folder_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can move default non compliances');
    END IF;

    UPDATE non_comp_default
       SET non_comp_default_folder_id = in_parent_id
     WHERE non_comp_default_id = in_default_non_comp_id;
END;

PROCEDURE GetNonComplianceDetails(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    out_nc_cur                OUT    SYS_REFCURSOR,
    out_nc_upload_cur        OUT    SYS_REFCURSOR,
    out_nc_tag_cur            OUT    SYS_REFCURSOR,
    out_nc_audits_cur        OUT SYS_REFCURSOR
)
AS
    v_perm                    NUMBER;
    v_audit_perm_t            security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
    CheckNonComplianceReadable(in_non_compliance_id);

    OPEN out_nc_cur FOR
        SELECT nc.non_compliance_id, nc.label, nc.detail, nc.from_non_comp_default_id,
               nc.created_dtm, nc.created_in_audit_sid, ia.internal_audit_type_id created_in_audit_type_id,
               nc.created_by_user_sid, cc.full_name created_by_full_name, nc.root_cause, nc.suggested_action,
               NVL(i.closed_issues, 0) closed_issues, NVL(i.total_issues, 0) total_issues,
               NVL(i.open_issues, 0) open_issues, ia.internal_audit_sid sid_id, ia.label audit_label,
               qsq.question_id, qsq.label question_label, 
               CASE WHEN anc.attached_to_primary_survey = 1 THEN 0 ELSE anc.internal_audit_type_survey_id END internal_audit_type_survey_id,
               qsqo.question_option_id, qsqo.label question_option_label,
               nc.non_compliance_type_id, nct.label non_compliance_type_label, nc.is_closed,
               r.region_sid, r.description region_description
          FROM non_compliance nc
          JOIN csr_user cc ON cc.csr_user_sid = nc.created_by_user_sid
                          AND cc.app_sid = nc.app_sid
          LEFT JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
                                           AND nct.app_sid = nc.app_sid
          JOIN audit_non_compliance anc ON anc.non_compliance_id = nc.non_compliance_id
                                       AND anc.internal_audit_sid = nc.created_in_audit_sid
                                       AND anc.app_sid = nc.app_sid
          LEFT JOIN internal_audit ia ON ia.internal_audit_sid = nc.created_in_audit_sid
                                     AND ia.app_sid = nc.app_sid
          LEFT JOIN internal_audit_survey ias ON ias.internal_audit_sid = ia.internal_audit_sid
                                             AND ias.app_sid = ia.app_sid
                                             AND ias.internal_audit_type_survey_id = anc.internal_audit_type_survey_id
          LEFT JOIN quick_survey_response qsr ON qsr.survey_response_id = NVL(ias.survey_response_id, CASE WHEN anc.attached_to_primary_survey = 1 THEN ia.survey_response_id ELSE NULL END)
                                             AND qsr.app_sid = ia.app_sid
          LEFT JOIN quick_survey_question qsq ON qsq.question_id = nc.question_id
                                             AND qsq.survey_version = qsr.survey_version
                                             AND qsq.app_sid = nc.app_sid
          LEFT JOIN qs_question_option qsqo   ON qsqo.question_id = nc.question_id
                                             AND qsqo.question_option_id = nc.question_option_id
                                             AND qsqo.survey_version = qsr.survey_version
                                             AND qsqo.app_sid = nc.app_sid
          LEFT JOIN v$region r ON r.region_sid = NVL(nc.region_sid, ia.region_sid) AND r.app_sid = nc.app_sid
          LEFT JOIN (
                SELECT inc.app_sid, inc.non_compliance_id,
                       COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
                       COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
                  FROM issue_non_compliance inc, issue i
                 WHERE inc.app_sid = i.app_sid
                   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
                 GROUP BY inc.app_sid, inc.non_compliance_id
         ) i ON i.non_compliance_id = nc.non_compliance_id AND i.app_sid = nc.app_sid
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND nc.non_compliance_id = in_non_compliance_id;

    OPEN out_nc_upload_cur FOR
        SELECT nc.non_compliance_id, ncf.non_compliance_file_id, ncf.filename, ncf.mime_type, cast(ncf.sha1 as varchar2(40)) sha1, ncf.uploaded_dtm
          FROM non_compliance nc
          JOIN non_compliance_file ncf ON nc.non_compliance_id = ncf.non_compliance_id
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND nc.non_compliance_id = in_non_compliance_id
          ORDER BY nc.non_compliance_id, ncf.non_compliance_file_id;

    OPEN out_nc_tag_cur FOR
        SELECT nc.non_compliance_id, nct.tag_id, nct.tag_group_id,
               t.tag, t.explanation, t.lookup_key
          FROM non_compliance nc
          JOIN tag_group_ir_member nct ON nc.non_compliance_id = nct.non_compliance_id
          JOIN v$tag t ON t.tag_id = nct.tag_id
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND nc.non_compliance_id = in_non_compliance_id
          ORDER BY nc.non_compliance_id, nct.tag_group_id, nct.pos, nct.tag_id;

    FOR r IN (
        SELECT internal_audit_sid
          FROM audit_non_compliance
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND non_compliance_id = in_non_compliance_id
    )
    LOOP
        v_perm := GetPermissionOnAudit(r.internal_audit_sid);
        v_audit_perm_t.extend(1);
        v_audit_perm_t(v_audit_perm_t.COUNT) := security.T_ORDERED_SID_ROW(sid_id => r.internal_audit_sid, pos => v_perm);
    END LOOP;

    OPEN out_nc_audits_cur FOR
        SELECT nc.non_compliance_id, anc.internal_audit_sid, iat.internal_audit_type_group_id,
               T.pos permission_level,
               CASE WHEN anc.repeat_of_audit_nc_id IS NULL THEN 0 ELSE 1 END is_repeat,
               ria.internal_audit_sid repeat_of_audit_sid, ria.label repeat_of_audit_label, ria.audit_dtm repeat_of_audit_dtm,
               rnc.non_compliance_id repeat_of_non_compliance_id, rnc.label repeat_of_non_compliance_label,
               CASE WHEN anc.attached_to_primary_survey = 1 THEN 0 ELSE anc.internal_audit_type_survey_id END internal_audit_type_survey_id
          FROM non_compliance nc
          JOIN audit_non_compliance anc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
          JOIN TABLE(v_audit_perm_t) T ON T.sid_id = ia.internal_audit_sid
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
          LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id AND ranc.app_sid = anc.app_sid
          LEFT JOIN internal_audit ria ON ranc.internal_audit_sid = ria.internal_audit_sid AND anc.app_sid = ria.app_sid
          LEFT JOIN non_compliance rnc ON ranc.non_compliance_id = rnc.non_compliance_id AND anc.app_sid = rnc.app_sid
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND nc.non_compliance_id = in_non_compliance_id
      ORDER BY anc.internal_audit_sid;

END;

PROCEDURE GetAllDNCFolders (
    in_internal_audit_type_id    IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
    out_cur                        OUT SYS_REFCURSOR
)
AS
BEGIN
    -- no permissions neeeded for reading default non compliances

    OPEN out_cur FOR
        SELECT non_comp_default_folder_id, parent_folder_id, label
          FROM non_comp_default_folder
         WHERE app_sid = security_pkg.GetApp
       AND non_comp_default_folder_id IN ( -- parent of a match to the right audit type
        SELECT non_comp_default_folder_id
          FROM non_comp_default_folder
         START WITH non_comp_default_folder_id IN (
            SELECT DISTINCT non_comp_default_folder_id
              FROM non_comp_default
             WHERE in_internal_audit_type_id IS NULL
                OR non_comp_default_id IN (
                    SELECT non_comp_default_id
                      FROM audit_type_non_comp_default
                     WHERE internal_audit_type_id = in_internal_audit_type_id
                )
            )
       CONNECT BY PRIOR parent_folder_id = non_comp_default_folder_id -- going up
       );
END;

PROCEDURE GetNonComplianceDefaults (
    in_internal_audit_type_id    IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
    in_folder_id                IN    non_comp_default.non_comp_default_folder_id%TYPE,
    out_nc_defaults_cur            OUT SYS_REFCURSOR,
    out_nc_audit_types_cur        OUT SYS_REFCURSOR,
    out_nc_issues_cur            OUT SYS_REFCURSOR,
    out_nc_tags_cur                OUT SYS_REFCURSOR
)
AS
    v_non_comp_default_ids        security.T_SID_TABLE;
BEGIN
    -- no permissions neeeded for reading default non compliances

    SELECT non_comp_default_id
      BULK COLLECT INTO v_non_comp_default_ids
      FROM non_comp_default
     WHERE app_sid = security_pkg.GetApp
       AND ((in_folder_id IS NULL) OR NVL(non_comp_default_folder_id, -1) = in_folder_id)
       AND (in_internal_audit_type_id IS NULL OR non_comp_default_id IN (
            SELECT non_comp_default_id
              FROM audit_type_non_comp_default
             WHERE internal_audit_type_id = in_internal_audit_type_id
               AND app_sid = security_pkg.GetApp
            )
       );

    OPEN out_nc_defaults_cur FOR
        SELECT ncd.non_comp_default_id, ncd.label, ncd.detail, ncd.non_compliance_type_id,
               ncd.non_comp_default_folder_id, ncd.root_cause, ncd.suggested_action,
               ncd.unique_reference, substr(folders.path, 2) folder_path
          FROM non_comp_default ncd
          LEFT JOIN (
            SELECT non_comp_default_folder_id, sys_connect_by_path(label, '|') path
              FROM non_comp_default_folder
             START WITH parent_folder_id IS NULL
           CONNECT BY PRIOR non_comp_default_folder_id = parent_folder_id
          ) folders ON ncd.non_comp_default_folder_id = folders.non_comp_default_folder_id
         WHERE non_comp_default_id IN (SELECT column_value FROM TABLE(v_non_comp_default_ids));

    OPEN out_nc_audit_types_cur FOR
        SELECT atncd.internal_audit_type_id, atncd.non_comp_default_id, iat.label
          FROM audit_type_non_comp_default atncd
          JOIN internal_audit_type iat ON atncd.internal_audit_type_id = iat.internal_audit_type_id
         WHERE atncd.non_comp_default_id IN (SELECT column_value FROM TABLE(v_non_comp_default_ids));

    OPEN out_nc_issues_cur FOR
        SELECT non_comp_default_issue_id, non_comp_default_id, label, description, due_dtm_relative,
               due_dtm_relative_unit
          FROM non_comp_default_issue
         WHERE non_comp_default_id IN (SELECT column_value FROM TABLE(v_non_comp_default_ids));

    OPEN out_nc_tags_cur FOR
        SELECT ncdt.non_comp_default_id, ncdt.tag_id, t.tag, tgm.tag_group_id
          FROM non_comp_default_tag ncdt
          JOIN v$tag t ON ncdt.tag_id = t.tag_id AND ncdt.app_sid = t.app_sid
          JOIN tag_group_member tgm ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
         WHERE non_comp_default_id IN (SELECT column_value FROM TABLE(v_non_comp_default_ids));
END;

PROCEDURE SetNonComplianceDefault (
    in_non_comp_default_id            IN  non_comp_default.non_comp_default_id%TYPE,
    in_folder_id                    IN    non_comp_default.non_comp_default_folder_id%TYPE,
    in_label                        IN  non_comp_default.label%TYPE,
    in_detail                        IN  non_comp_default.detail%TYPE,
    in_non_compliance_type_id        IN  non_comp_default.non_compliance_type_id%TYPE,
    in_root_cause                    IN  non_comp_default.root_cause%TYPE,
    in_suggested_action                IN  non_comp_default.suggested_action%TYPE,
    in_unique_reference                IN  non_comp_default.unique_reference%TYPE,
    out_non_comp_default_id            OUT non_comp_default.non_comp_default_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit non-compliance defaults');
    END IF;

    BEGIN
        IF in_non_comp_default_id IS NULL THEN
            INSERT INTO non_comp_default (non_comp_default_id, non_comp_default_folder_id, label,
                                          detail, non_compliance_type_id, root_cause, suggested_action,
                                          unique_reference)
                 VALUES (non_comp_default_id_seq.NEXTVAL, in_folder_id, in_label, in_detail,
                         in_non_compliance_type_id, in_root_cause, in_suggested_action,
                         in_unique_reference)
              RETURNING non_comp_default_id INTO out_non_comp_default_id;
        ELSE
            UPDATE non_comp_default
               SET non_comp_default_folder_id = in_folder_id,
                   label = in_label,
                   detail = in_detail,
                   non_compliance_type_id = in_non_compliance_type_id,
                   root_cause = in_root_cause,
                   suggested_action = in_suggested_action,
                   unique_reference = in_unique_reference
             WHERE app_sid = security_pkg.GetApp
               AND non_comp_default_id = in_non_comp_default_id;

            out_non_comp_default_id := in_non_comp_default_id;
        END IF;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Unique reference: '||in_unique_reference||' already exists');
    END;
END;

PROCEDURE DeleteNonComplianceDefault (
    in_non_comp_default_id        IN  non_comp_default.non_comp_default_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete non-compliance defaults');
    END IF;

    DELETE FROM audit_type_non_comp_default
     WHERE non_comp_default_id = in_non_comp_default_id
       AND app_sid = security_pkg.GetApp;

    DELETE FROM non_comp_default_issue
     WHERE non_comp_default_id = in_non_comp_default_id
       AND app_sid = security_pkg.GetApp;

    DELETE FROM non_comp_default_tag
     WHERE non_comp_default_id = in_non_comp_default_id
       AND app_sid = security_pkg.GetApp;

    UPDATE non_compliance
       SET from_non_comp_default_id = NULL
     WHERE from_non_comp_default_id = in_non_comp_default_id
       AND app_sid = security_pkg.GetApp;

    DELETE FROM non_comp_default
     WHERE non_comp_default_id = in_non_comp_default_id
       AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SetAuditTypeNonCompDefaults (
    in_non_comp_default_id            IN  audit_type_non_comp_default.non_comp_default_id%TYPE,
    in_internal_audit_type_ids        IN  security_pkg.T_SID_IDS
)
AS
    v_internal_audit_type_ids        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_internal_audit_type_ids);
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can set audit type non-compliance defaults');
    END IF;

    INSERT INTO audit_type_non_comp_default (non_comp_default_id, internal_audit_type_id)
    SELECT in_non_comp_default_id, t.column_value
      FROM TABLE(v_internal_audit_type_ids) t
     WHERE NOT EXISTS (
        SELECT *
          FROM audit_type_non_comp_default atncd
         WHERE atncd.non_comp_default_id = in_non_comp_default_id
           AND atncd.internal_audit_type_id = t.column_value
     );

    DELETE FROM audit_type_non_comp_default
     WHERE non_comp_default_id = in_non_comp_default_id
       AND internal_audit_type_id NOT IN (SELECT column_value FROM TABLE(v_internal_audit_type_ids));
END;

PROCEDURE SetNonCompDefaultTags (
    in_non_comp_default_id            IN  audit_type_non_comp_default.non_comp_default_id%TYPE,
    in_tag_ids                        IN  security_pkg.T_SID_IDS
)
AS
    v_tag_ids                        security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can set non-compliance default tags');
    END IF;

    INSERT INTO non_comp_default_tag (non_comp_default_id, tag_id)
    SELECT in_non_comp_default_id, t.column_value
      FROM TABLE(v_tag_ids) t
     WHERE NOT EXISTS (
        SELECT *
          FROM non_comp_default_tag ncdt
         WHERE ncdt.non_comp_default_id = in_non_comp_default_id
           AND ncdt.tag_id = t.column_value
     );

    DELETE FROM non_comp_default_tag
     WHERE non_comp_default_id = in_non_comp_default_id
       AND tag_id NOT IN (SELECT column_value FROM TABLE(v_tag_ids));
END;

PROCEDURE SetNonCompDefaultIssue (
    in_non_comp_default_issue_id    IN  non_comp_default_issue.non_comp_default_issue_id%TYPE,
    in_non_comp_default_id            IN  non_comp_default_issue.non_comp_default_id%TYPE,
    in_label                        IN  non_comp_default_issue.label%TYPE,
    in_description                    IN  non_comp_default_issue.description%TYPE,
    in_due_dtm_relative                IN  non_comp_default_issue.due_dtm_relative%TYPE,
    in_due_dtm_relative_unit        IN  non_comp_default_issue.due_dtm_relative_unit%TYPE,
    out_non_comp_default_issue_id    OUT non_comp_default_issue.non_comp_default_issue_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit non-compliance default issues');
    END IF;

    IF in_non_comp_default_issue_id IS NULL THEN
        INSERT INTO non_comp_default_issue (non_comp_default_issue_id, non_comp_default_id, label, description,
                    due_dtm_relative, due_dtm_relative_unit)
             VALUES (non_comp_default_issue_id_seq.NEXTVAL, in_non_comp_default_id, in_label, in_description,
                    in_due_dtm_relative, in_due_dtm_relative_unit)
          RETURNING non_comp_default_issue_id INTO out_non_comp_default_issue_id;
    ELSE
        UPDATE non_comp_default_issue
           SET non_comp_default_id = in_non_comp_default_id,
               label = in_label,
               description = in_description,
               due_dtm_relative = in_due_dtm_relative,
               due_dtm_relative_unit = in_due_dtm_relative_unit
         WHERE non_comp_default_issue_id = in_non_comp_default_issue_id
           AND app_sid = security_pkg.GetApp;

        out_non_comp_default_issue_id := in_non_comp_default_issue_id;
    END IF;
END;

PROCEDURE DeleteRemainingNCDIssues (
    in_non_comp_default_id            IN  non_comp_default_issue.non_comp_default_id%TYPE,
    in_issue_ids_to_keep            IN  security_pkg.T_SID_IDS
)
AS
    v_issue_ids_to_keep                security.T_SID_TABLE := security_pkg.SidArrayToTable(in_issue_ids_to_keep);
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can delete non-compliance default issues');
    END IF;

    DELETE FROM non_comp_default_issue
     WHERE non_comp_default_id = in_non_comp_default_id
       AND non_comp_default_issue_id NOT IN (SELECT column_value FROM TABLE(v_issue_ids_to_keep));
END;

PROCEDURE CheckNonComplianceAccess (
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_access                IN    security_pkg.T_PERMISSION,
    in_access_denied_msg    IN    VARCHAR2 DEFAULT NULL
)
AS
    v_access_denied_message        VARCHAR2(255) := NVL(in_access_denied_msg, CASE WHEN bitand(in_access, security_pkg.PERMISSION_WRITE)!=0 THEN 'Write' ELSE 'Read' END ||' access denied on non-compliance with ID: '||in_non_compliance_id);
BEGIN
    -- Look at the audits that this NC is linked to
    FOR aud IN (
        SELECT anc.internal_audit_sid, ia.flow_item_id
          FROM audit_non_compliance anc
          JOIN internal_audit ia
            ON anc.internal_audit_sid = ia.internal_audit_sid
         WHERE anc.non_compliance_id = in_non_compliance_id
    ) LOOP
        IF aud.flow_item_id IS NOT NULL THEN
            -- if audit is linked to flow, then use flow capability
            IF HasFlowAuditNonComplAccess(
                in_non_compliance_id => in_non_compliance_id, 
                in_audit_sid => aud.internal_audit_sid, 
                in_access => in_access
            ) THEN
                RETURN;
            END IF;
        ELSE
            -- else grant access if user has access to the audit
            IF in_access = SECURITY.SECURITY_PKG.PERMISSION_READ THEN
              IF HasReadAccess(aud.internal_audit_sid) THEN
                RETURN;
              END IF;
            END IF;
            IF in_access = SECURITY.SECURITY_PKG.PERMISSION_WRITE THEN
              IF HasWriteAccess(aud.internal_audit_sid) THEN
                RETURN;
              END IF;
            END IF;
        END IF;
    END LOOP;

    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, v_access_denied_message);
END;

PROCEDURE UpdateNonCompClosureStatus (
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
)
AS
    v_closure_behaviour            non_compliance_type.closure_behaviour_id%TYPE;
    v_open_issue_count            NUMBER;
    v_total_issue_count            NUMBER;
BEGIN
    BEGIN
        SELECT nct.closure_behaviour_id
          INTO v_closure_behaviour
          FROM non_compliance nc
          JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
         WHERE nc.non_compliance_id = in_non_compliance_id;
    EXCEPTION
        WHEN no_data_found THEN
            v_closure_behaviour := NULL;
    END;

    IF v_closure_behaviour = csr_data_pkg.NON_COMP_CLOSURE_ALWAYS_CLOSED THEN
        UPDATE non_compliance
           SET is_closed = 1
         WHERE non_compliance_id = in_non_compliance_id;
    ELSIF v_closure_behaviour = csr_data_pkg.NON_COMP_CLOSURE_AUTOMATIC THEN
        SELECT COUNT(*), COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END)
          INTO v_total_issue_count, v_open_issue_count
          FROM issue_non_compliance inc
          JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
         WHERE i.deleted = 0
           AND inc.non_compliance_id = in_non_compliance_id;

        UPDATE non_compliance
           SET is_closed = CASE WHEN v_open_issue_count = 0 AND v_total_issue_count > 0 THEN 1 ELSE 0 END
         WHERE non_compliance_id = in_non_compliance_id;
    END IF;
END;

PROCEDURE DidSaveNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_internal_audit_sid        IN    security_pkg.T_SID_ID
)
AS
    v_min_audit_dtm                internal_audit.audit_dtm%TYPE;
    v_max_audit_dtm                internal_audit.audit_dtm%TYPE;
BEGIN
    UpdateNonCompClosureStatus(in_non_compliance_id);

    -- Trigger re-calc on IA indicators
    SELECT MIN(ia.audit_dtm), MAX(ia.audit_dtm)
      INTO v_min_audit_dtm, v_max_audit_dtm
      FROM internal_audit ia
      JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
     WHERE anc.non_compliance_id = in_non_compliance_id;

    TriggerAuditAgg(TRUNC(LEAST(v_min_audit_dtm, v_max_audit_dtm),'MONTH'),
        ADD_MONTHS(TRUNC(GREATEST(v_min_audit_dtm, v_max_audit_dtm),'MONTH'),1));

    -- call helper pkg
    INTERNAL_CallHelperPkg('NonComplianceUpdated', in_internal_audit_sid, in_non_compliance_id);

    FOR r IN (
        SELECT anc.internal_audit_sid
          FROM audit_non_compliance anc
         WHERE anc.non_compliance_id = in_non_compliance_id
    ) LOOP
        RecalculateAuditNCScore(r.internal_audit_sid);
    END LOOP;
END;

PROCEDURE SaveNonCompliance_UNSEC(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_region_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_from_non_comp_default_id    IN  non_compliance.from_non_comp_default_id%TYPE,
    in_label                    IN    non_compliance.label%TYPE,
    in_detail                    IN    non_compliance.detail%TYPE,
    in_non_compliance_type_id    IN  non_compliance.non_compliance_type_id%TYPE,
    in_is_closed                IN  non_compliance.is_closed%TYPE,
    in_question_id                IN    non_compliance.question_id%TYPE DEFAULT NULL,
    in_question_option_id        IN    non_compliance.question_option_id%TYPE DEFAULT NULL,
    in_root_cause                IN  non_compliance.root_cause%TYPE DEFAULT NULL,
    in_suggested_action            IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
    in_ia_type_survey_id         IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
    in_lookup_key                IN    non_compliance.lookup_key%TYPE DEFAULT NULL,
    out_non_compliance_id        OUT    non_compliance.non_compliance_id%TYPE
)
AS
    v_is_closed                    non_compliance.is_closed%TYPE;
    v_old_label                    non_compliance.label%TYPE;
    v_region_sid                security_pkg.T_SID_ID;
    v_has_non_comp_type            NUMBER;
BEGIN
    v_is_closed := in_is_closed;

    -- if the region sid was not explicitly given, inherit the region sid of the audit the non-compliance refers to
    IF in_region_sid IS NULL THEN
        SELECT region_sid
          INTO v_region_sid
          FROM csr.internal_audit
         WHERE internal_audit_sid = in_internal_audit_sid;
    ELSE
        v_region_sid := in_region_sid;
    END IF;

    IF in_non_compliance_id IS NULL THEN

        -- Make sure that if non_compliance_type is not used then is_close is NULL instead of 0.
        IF v_is_closed = 0 AND in_non_compliance_type_id IS NULL THEN
            v_is_closed := NULL;
        END IF;

        INSERT INTO non_compliance (
            non_compliance_id, created_in_audit_sid, from_non_comp_default_id, label, detail,
            question_id, question_option_id,
            region_sid, non_compliance_type_id, is_closed, root_cause, suggested_action, lookup_key
        ) VALUES (
            non_compliance_id_seq.NEXTVAL, in_internal_audit_sid, in_from_non_comp_default_id, TruncateString(in_label, 2048), in_detail,
            in_question_id, in_question_option_id,
            v_region_sid, in_non_compliance_type_id, v_is_closed, in_root_cause, in_suggested_action, in_lookup_key
        ) RETURNING non_compliance_id INTO out_non_compliance_id;

        INSERT INTO audit_non_compliance (
            audit_non_compliance_id, non_compliance_id, internal_audit_sid,
            attached_to_primary_survey,
            internal_audit_type_survey_id
        ) VALUES (
            audit_non_compliance_id_seq.nextval, out_non_compliance_id, in_internal_audit_sid,
            CASE WHEN in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN 1 ELSE 0 END,
            CASE WHEN in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN NULL ELSE in_ia_type_survey_id END
        );

        csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_NON_COMPLIANCE, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
            'Finding added: {0} ({1})', in_label, out_non_compliance_id);

        INTERNAL_CreateRefID_Non_Comp(out_non_compliance_id);
        
        chain.filter_pkg.ClearCacheForAllUsers (
            in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
        );
    ELSE
        SELECT label
          INTO v_old_label
          FROM non_compliance
         WHERE non_compliance_id = in_non_compliance_id;

        csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_NON_COMPLIANCE, SYS_CONTEXT('SECURITY', 'APP'),
            in_internal_audit_sid, 'Finding label', v_old_label, TruncateString(in_label, 2048));

        UPDATE non_compliance
           SET non_compliance_type_id = in_non_compliance_type_id
         WHERE non_compliance_id = in_non_compliance_id;


        -- Make sure that if non_compliance_type is not used then is_close is NULL instead of 0.
        IF v_is_closed = 0 THEN
            SELECT COUNT(*)
              INTO v_has_non_comp_type
              FROM csr.non_compliance
             WHERE non_compliance_id = in_non_compliance_id
               AND non_compliance_type_id IS NOT NULL;

            IF v_has_non_comp_type = 0 THEN
                v_is_closed := NULL;
            END IF;
        END IF;

        UPDATE non_compliance
           SET label = TruncateString(in_label, 2048),
               detail = in_detail,
               region_sid = v_region_sid,
               is_closed = v_is_closed,
               root_cause = in_root_cause,
               suggested_action = in_suggested_action,
               lookup_key = in_lookup_key
         WHERE non_compliance_id = in_non_compliance_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The non-compliance with id '||in_non_compliance_id||' could not be found');
        END IF;

        -- if there are any issues with different region than of the NC, update them
        FOR r IN (
            SELECT i.issue_id
              FROM csr.issue i
              JOIN csr.issue_non_compliance inc ON inc.issue_non_compliance_id = i.issue_non_compliance_id
              JOIN csr.non_compliance nc ON nc.non_compliance_id = inc.non_compliance_id
             WHERE nc.non_compliance_id = in_non_compliance_id
               AND i.region_sid != nc.region_sid
        )
        LOOP
          UPDATE csr.issue
             SET region_sid = v_region_sid
           WHERE issue_id = r.issue_id;
        END LOOP;

        out_non_compliance_id := in_non_compliance_id;
    END IF;
END;

PROCEDURE INTERNAL_SaveNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_region_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_from_non_comp_default_id    IN  non_compliance.from_non_comp_default_id%TYPE,
    in_label                    IN    non_compliance.label%TYPE,
    in_detail                    IN    non_compliance.detail%TYPE,
    in_non_compliance_type_id    IN  non_compliance.non_compliance_type_id%TYPE,
    in_is_closed                IN  non_compliance.is_closed%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    in_tag_ids                    IN    security_pkg.T_SID_IDS, --not sids but will do
    in_question_id                IN    non_compliance.question_id%TYPE,
    in_question_option_id        IN    non_compliance.question_option_id%TYPE,
    in_root_cause                IN  non_compliance.root_cause%TYPE DEFAULT NULL,
    in_suggested_action            IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
    in_ia_type_survey_id         IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
    in_lookup_key                IN    non_compliance.lookup_key%TYPE DEFAULT NULL,
    out_non_compliance_id        OUT non_compliance.non_compliance_id%TYPE
)
AS
    v_internal_audit_sid        security_pkg.T_SID_ID;
    v_is_closed                    non_compliance.is_closed%TYPE;
    v_closure_behaviour            non_compliance_type.closure_behaviour_id%TYPE;
    v_can_add_non_compliance    BOOLEAN := FALSE;
BEGIN
    -- Check for write permissions on the existing audit object
    IF in_non_compliance_id IS NOT NULL THEN
        CheckNonComplianceWriteable(in_non_compliance_id);

        BEGIN
            SELECT internal_audit_sid
              INTO v_internal_audit_sid
              FROM audit_non_compliance
             WHERE non_compliance_id = in_non_compliance_id
               AND internal_audit_sid = in_internal_audit_sid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Error attempting to save a non-compliance to a different audit SID');
        END;

        BEGIN
            SELECT nct.closure_behaviour_id
              INTO v_closure_behaviour
              FROM non_compliance nc
              JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
             WHERE nc.non_compliance_id = in_non_compliance_id;
        EXCEPTION
            WHEN no_data_found THEN
                v_closure_behaviour := csr_data_pkg.NON_COMP_CLOSURE_MANUAL;
        END;

        IF v_closure_behaviour = csr_data_pkg.NON_COMP_CLOSURE_MANUAL THEN
            BEGIN
                SELECT NVL(is_closed, 0)
                  INTO v_is_closed
                  FROM non_compliance
                 WHERE non_compliance_id = in_non_compliance_id;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The non-compliance with id '||in_non_compliance_id||' could not be found');
            END;

            IF IsFlowAudit(in_internal_audit_sid) AND
               v_is_closed != in_is_closed AND
               NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_CLOSE_FINDINGS, security_pkg.PERMISSION_WRITE)
               THEN
                RAISE_APPLICATION_ERROR(-20001, 'Access denied changing closure status for non-compliance on the audit with sid '||in_internal_audit_sid);
            END IF;
        END IF;

    ELSE
        IF (NOT IsFlowAudit(in_internal_audit_sid)) THEN
            v_can_add_non_compliance := HasWriteAccess(in_internal_audit_sid);
        ELSE
            v_can_add_non_compliance := HasFlowAuditNonComplTypeAccess(in_non_compliance_type_id, in_internal_audit_sid, security.security_pkg.PERMISSION_WRITE);
        END IF;

        IF NOT v_can_add_non_compliance THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding non-compliance to the audit with sid '||in_internal_audit_sid);
        END IF;

        v_internal_audit_sid := in_internal_audit_sid;
    END IF;

    SaveNonCompliance_UNSEC(
        in_non_compliance_id        => in_non_compliance_id,
        in_region_sid                => in_region_sid,
        in_internal_audit_sid        => v_internal_audit_sid,
        in_from_non_comp_default_id    => in_from_non_comp_default_id,
        in_label                    => in_label,
        in_detail                    => in_detail,
        in_non_compliance_type_id    => in_non_compliance_type_id,
        in_is_closed                => in_is_closed,
        in_question_id                => in_question_id,
        in_question_option_id        => in_question_option_id,
        in_root_cause                => in_root_cause,
        in_suggested_action            => in_suggested_action,
        in_ia_type_survey_id         => in_ia_type_survey_id,
        in_lookup_key                => in_lookup_key,
        out_non_compliance_id        => out_non_compliance_id
    );
END;

PROCEDURE SaveNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_region_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_from_non_comp_default_id    IN  non_compliance.from_non_comp_default_id%TYPE,
    in_label                    IN    non_compliance.label%TYPE,
    in_detail                    IN    non_compliance.detail%TYPE,
    in_non_compliance_type_id    IN  non_compliance.non_compliance_type_id%TYPE,
    in_is_closed                IN  non_compliance.is_closed%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    in_tag_ids                    IN    security_pkg.T_SID_IDS, --not sids but will do
    in_question_id                IN    non_compliance.question_id%TYPE,
    in_question_option_id        IN    non_compliance.question_option_id%TYPE,
    in_root_cause                IN  non_compliance.root_cause%TYPE DEFAULT NULL,
    in_suggested_action            IN  non_compliance.suggested_action%TYPE DEFAULT NULL,
    in_ia_type_survey_id         IN  audit_non_compliance.internal_audit_type_survey_id%TYPE DEFAULT NULL,
    in_lookup_key                IN    non_compliance.lookup_key%TYPE DEFAULT NULL,
    out_nc_cur                    OUT    SYS_REFCURSOR,
    out_nc_upload_cur            OUT    SYS_REFCURSOR,
    out_nc_tag_cur                OUT    SYS_REFCURSOR
)
AS
    v_non_compliance_id                non_compliance.non_compliance_id%TYPE;
BEGIN
    INTERNAL_SaveNonCompliance(
        in_non_compliance_id            => in_non_compliance_id,
        in_region_sid                    => in_region_sid,
        in_internal_audit_sid            => in_internal_audit_sid,
        in_from_non_comp_default_id        => in_from_non_comp_default_id,
        in_label                        => in_label,
        in_detail                        => in_detail,
        in_non_compliance_type_id        => in_non_compliance_type_id,
        in_is_closed                    => in_is_closed,
        in_current_file_uploads            => in_current_file_uploads,
        in_new_file_uploads                => in_new_file_uploads,
        in_tag_ids                        => in_tag_ids,
        in_question_id                    => in_question_id,
        in_question_option_id            => in_question_option_id,
        in_root_cause                    => in_root_cause,
        in_suggested_action                => in_suggested_action,
        in_ia_type_survey_id             => in_ia_type_survey_id,
        in_lookup_key                    => in_lookup_key,
        out_non_compliance_id            => v_non_compliance_id
    );

    -- Clean up deleted file uploads and add new ones
    FixUpFiles(v_non_compliance_id, in_current_file_uploads, in_new_file_uploads, out_nc_upload_cur);

    -- Set tags - this checks for permissions so can't be done in unsec version
    tag_pkg.SetNonComplianceTags(security_pkg.GetAct, v_non_compliance_id, in_tag_ids);

    -- Run helper SPs etc...
    DidSaveNonCompliance(v_non_compliance_id, in_internal_audit_sid);

    -- Fetch the details again for the sending back to the page
    OPEN out_nc_cur FOR
        SELECT nc.non_compliance_id, nc.label, nc.detail, nc.question_id, nc.question_option_id, nc.created_dtm, nc.created_in_audit_sid,
               nc.created_by_user_sid, cc.full_name created_by_full_name, NVL(i.closed_issues, 0) closed_issues,
               NVL(i.total_issues, 0) total_issues, NVL(i.open_issues, 0) open_issues, nc.region_sid,
               CASE WHEN anc.repeat_of_audit_nc_id IS NULL THEN 0 ELSE 1 END is_repeat,
               ria.internal_audit_sid repeat_of_audit_sid, ria.label repeat_of_audit_label, ria.audit_dtm repeat_of_audit_dtm,
               rnc.non_compliance_id repeat_of_non_compliance_id, rnc.label repeat_of_non_compliance_label,
               nc.non_compliance_type_id, nc.is_closed, nc.root_cause, nc.suggested_action,
               NVL2(nc.non_compliance_ref, nct.inter_non_comp_ref_prefix || nc.non_compliance_ref, null) custom_non_compliance_id
          FROM audit_non_compliance anc
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
          JOIN csr_user cc ON nc.created_by_user_sid = cc.csr_user_sid AND nc.app_sid = cc.app_sid
          LEFT JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id AND nc.app_sid = nct.app_sid
          LEFT JOIN audit_non_compliance ranc ON ranc.audit_non_compliance_id = anc.repeat_of_audit_nc_id AND ranc.app_sid = anc.app_sid
          LEFT JOIN internal_audit ria ON ria.internal_audit_sid = ranc.internal_audit_sid AND ria.app_sid = ranc.app_sid
          LEFT JOIN non_compliance rnc ON rnc.non_compliance_id = ranc.non_compliance_id AND rnc.app_sid = ranc.app_sid
          LEFT JOIN (
                SELECT inc.app_sid, inc.non_compliance_id,
                       COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
                       COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
                  FROM issue_non_compliance inc, issue i
                 WHERE inc.app_sid = i.app_sid
                   AND i.deleted = 0
                   AND inc.issue_non_compliance_id = i.issue_non_compliance_id
                 GROUP BY inc.app_sid, inc.non_compliance_id
             ) i ON i.non_compliance_id = anc.non_compliance_id AND i.app_sid = anc.app_sid
         WHERE anc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND anc.non_compliance_id = v_non_compliance_id
           AND anc.internal_audit_sid = in_internal_audit_sid;

    OPEN out_nc_tag_cur FOR
        SELECT nc.non_compliance_id, nct.tag_id, nct.tag_group_id, nct.tag
          FROM non_compliance nc
          JOIN tag_group_ir_member nct ON nc.non_compliance_id = nct.non_compliance_id
         WHERE nc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND nc.non_compliance_id = v_non_compliance_id
          ORDER BY nc.non_compliance_id, nct.tag_group_id, nct.pos, nct.tag_id;

END;

PROCEDURE FixUpFiles(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_current_file_uploads        IN    security_pkg.T_SID_IDS,
    in_new_file_uploads            IN    T_CACHE_KEYS,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_keeper_id_tbl                security.T_SID_TABLE;
    v_cache_key_tbl                security.T_VARCHAR2_TABLE;
BEGIN
    CheckNonComplianceWriteable(in_non_compliance_id);

    -- crap hack for ODP.NET
    IF in_current_file_uploads IS NULL OR (in_current_file_uploads.COUNT = 1 AND in_current_file_uploads(1) IS NULL) THEN
        -- all removed
        DELETE FROM non_compliance_file
         WHERE non_compliance_id = in_non_compliance_id;
    ELSE
        v_keeper_id_tbl := security_pkg.SidArrayToTable(in_current_file_uploads);
        DELETE FROM non_compliance_file
         WHERE non_compliance_id = in_non_compliance_id
           AND non_compliance_file_id NOT IN (
            SELECT column_value FROM TABLE(v_keeper_id_tbl)
        );
    END IF;

    v_cache_key_tbl := CacheKeysArrayToTable(in_new_file_uploads);

    INSERT INTO non_compliance_file
        (non_compliance_file_id, non_compliance_id, filename, mime_type, data, sha1)
    SELECT non_compliance_file_id_seq.nextval, in_non_compliance_id, filename, mime_type, object,
           dbms_crypto.hash(object, dbms_crypto.hash_sh1)
      FROM aspen2.filecache
     WHERE cache_key IN (
        SELECT value FROM TABLE(v_cache_key_tbl)
     );

    -- return a nice clean list
    OPEN out_cur FOR
        SELECT ncf.non_compliance_file_id, ncf.non_compliance_id, ncf.filename, ncf.mime_type, cast(ncf.sha1 as varchar2(40)) sha1, ncf.uploaded_dtm
          FROM non_compliance_file ncf
         WHERE non_compliance_id = in_non_compliance_id;
END;

FUNCTION CacheKeysArrayToTable(
    in_strings            IN    T_CACHE_KEYS
) RETURN security.T_VARCHAR2_TABLE
AS
    v_table security.T_VARCHAR2_TABLE := security.T_VARCHAR2_TABLE();
BEGIN
    IF in_strings.COUNT = 0 OR (in_strings.COUNT = 1 AND in_strings(in_strings.FIRST) IS NULL) THEN
    -- hack for ODP.NET which doesn't support empty arrays - just return nothing
        RETURN v_table;
    END IF;

    FOR i IN in_strings.FIRST .. in_strings.LAST
    LOOP
        v_table.extend;
        v_table(v_table.COUNT) := security.T_VARCHAR2_ROW(i, in_strings(i));
    END LOOP;

    RETURN v_table;
END;

PROCEDURE CheckNonComplianceClosable(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
)
AS
    v_closure_behaviour            non_compliance_type.closure_behaviour_id%TYPE;
BEGIN
    CheckNonComplianceWriteable(in_non_compliance_id);

    BEGIN
        SELECT nct.closure_behaviour_id
          INTO v_closure_behaviour
          FROM non_compliance nc
          JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
         WHERE nc.non_compliance_id = in_non_compliance_id;
    EXCEPTION
        WHEN no_data_found THEN
            v_closure_behaviour := NULL;
    END;

    IF v_closure_behaviour <> csr_data_pkg.NON_COMP_CLOSURE_MANUAL THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Non-compliance ' || in_non_compliance_id || ' cannot be closed or reopened.');
    END IF;
END;

PROCEDURE CloseNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
)
AS
    v_internal_audit_sid        security_pkg.T_SID_ID;
    v_label                        non_compliance.label%TYPE;
BEGIN
    CheckNonComplianceClosable(in_non_compliance_id);

    SELECT label, created_in_audit_sid
      INTO v_label, v_internal_audit_sid
      FROM non_compliance
     WHERE non_compliance_id = in_non_compliance_id;

    csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_NON_COMPLIANCE, SYS_CONTEXT('SECURITY', 'APP'), v_internal_audit_sid,
        'Finding closed: {0} ({1})', v_label, in_non_compliance_id);

    UPDATE non_compliance
       SET is_closed = 1
     WHERE non_compliance_id = in_non_compliance_id;

    DidSaveNonCompliance(in_non_compliance_id, v_internal_audit_sid);
END;

PROCEDURE ReopenNonCompliance(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE
)
AS
    v_internal_audit_sid        security_pkg.T_SID_ID;
    v_label                        non_compliance.label%TYPE;
    v_has_non_comp_type            NUMBER;
BEGIN
    CheckNonComplianceClosable(in_non_compliance_id);

    SELECT label, created_in_audit_sid
      INTO v_label, v_internal_audit_sid
      FROM non_compliance
     WHERE non_compliance_id = in_non_compliance_id;

    csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_NON_COMPLIANCE, SYS_CONTEXT('SECURITY', 'APP'), v_internal_audit_sid,
        'Finding reopened: {0} ({1})', v_label, in_non_compliance_id);

    SELECT COUNT(*)
      INTO v_has_non_comp_type
      FROM csr.non_compliance
     WHERE non_compliance_id = in_non_compliance_id
       AND non_compliance_type_id IS NOT NULL;

    -- Make sure that if non_compliance_type is not used then is_close is NULL and not 0.
    IF v_has_non_comp_type = 0 THEN
        UPDATE non_compliance
           SET is_closed = NULL
         WHERE non_compliance_id = in_non_compliance_id;

    ELSE
        UPDATE non_compliance
           SET is_closed = 0
         WHERE non_compliance_id = in_non_compliance_id;

    END IF;

    DidSaveNonCompliance(in_non_compliance_id, v_internal_audit_sid);
END;

PROCEDURE DeleteNonCompliance(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_delete_issues        IN    NUMBER
)
AS
    v_label                    non_compliance.label%TYPE;
BEGIN
    CheckNonComplianceWriteable(in_non_compliance_id);

    SELECT label
      INTO v_label
      FROM non_compliance
     WHERE non_compliance_id = in_non_compliance_id;

    csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_NON_COMPLIANCE, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
        'Finding deleted: {0} ({1})', v_label, in_non_compliance_id);

    UPDATE audit_non_compliance
       SET repeat_of_audit_nc_id = NULL
     WHERE repeat_of_audit_nc_id IN (
        SELECT audit_non_compliance_id
          FROM audit_non_compliance
         WHERE non_compliance_id = in_non_compliance_id
           AND internal_audit_sid = in_internal_audit_sid
     );

    DELETE FROM audit_non_compliance
     WHERE non_compliance_id = in_non_compliance_id
       AND internal_audit_sid = in_internal_audit_sid;

    IF SQL%ROWCOUNT != 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Could not delete non_compliance with ID: '||in_non_compliance_id||' on audit with SID: '||in_internal_audit_sid);
    END IF;

    RecalculateAuditNCScore(in_internal_audit_sid);
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
    );
    
    FOR r IN (
        SELECT non_compliance_id
          FROM audit_non_compliance
         WHERE non_compliance_id = in_non_compliance_id
    ) LOOP
        -- don't fully delete if the non_compliance exists on another audit
        RETURN;
    END LOOP;

    IF in_delete_issues = 1 THEN
        FOR r IN (
            SELECT i.issue_id
              FROM issue i
              JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id
             WHERE inc.non_compliance_id = in_non_compliance_id
        ) LOOP
            -- If they have access to write to the NC then they should be able to delete its issues
            issue_pkg.UNSEC_DeleteIssue(r.issue_id);
        END LOOP;
    ELSE
        UPDATE issue
           SET issue_non_compliance_id = NULL
         WHERE issue_non_compliance_id IN (SELECT issue_non_compliance_id FROM issue_non_compliance where non_compliance_id = in_non_compliance_id);
    END IF;

    DELETE FROM issue_non_compliance
     WHERE non_compliance_id = in_non_compliance_id;

    DELETE FROM non_compliance_tag
     WHERE non_compliance_id = in_non_compliance_id;

    DELETE FROM non_compliance_file
     WHERE non_compliance_id = in_non_compliance_id;

    DELETE FROM non_compliance_expr_action
     WHERE non_compliance_id = in_non_compliance_id;

    DELETE FROM non_compliance
     WHERE non_compliance_id = in_non_compliance_id;

END;

FUNCTION CanAddActionsToNonCompliance(
    in_non_compliance_id        IN non_compliance.non_compliance_id%TYPE
) RETURN BOOLEAN
AS
    v_is_on_flow_audit            BOOLEAN := FALSE;
    v_can_have_actions            non_compliance_type.can_have_actions%TYPE;
BEGIN
    BEGIN
        SELECT nct.can_have_actions
          INTO v_can_have_actions
          FROM non_compliance nc
          JOIN non_compliance_type nct ON nc.non_compliance_type_id = nct.non_compliance_type_id
         WHERE non_compliance_id = in_non_compliance_id;
    EXCEPTION
        WHEN no_data_found THEN
            v_can_have_actions := 1;
    END;

    IF v_can_have_actions = 0 THEN
        RETURN FALSE;
    END IF;

    -- if the nc is on any audit with a flow, then check if any will
    -- allow this user to add action via capabilities
    FOR r IN (
        SELECT ia.internal_audit_sid
          FROM internal_audit ia
          JOIN audit_non_compliance anc
            ON ia.internal_audit_sid = anc.internal_audit_sid
         WHERE ia.flow_item_id IS NOT NULL
           AND anc.non_compliance_id = in_non_compliance_id
    ) LOOP
        IF HasCapabilityAccess(r.internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_ADD_ACTION, security.security_pkg.PERMISSION_WRITE) THEN
            RETURN TRUE;
        END IF;

        v_is_on_flow_audit := TRUE;
    END LOOP;

    -- if its not on a flow then they have access per old sec model
    RETURN NOT v_is_on_flow_audit;
END;

PROCEDURE GetOrSetNCForDefFlgFindingType(
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    out_non_compliance_id        OUT non_compliance.non_compliance_id%TYPE
)
AS
    v_non_compliance_type_id        non_compliance_type.non_compliance_type_id%TYPE;
    v_label                            non_compliance_type.label%TYPE;
    v_current_file_uploads            security_pkg.T_SID_IDS;
    v_new_file_uploads                T_CACHE_KEYS;
    v_tag_ids                        security_pkg.T_SID_IDS;
BEGIN
    SELECT MIN(nct.non_compliance_type_id)
      INTO v_non_compliance_type_id
      FROM internal_audit ia
      JOIN non_comp_type_audit_type nctat ON ia.internal_audit_type_id = nctat.internal_audit_type_id
      JOIN non_compliance_type nct ON nctat.non_compliance_type_id = nct.non_compliance_type_id
     WHERE nct.is_default_survey_finding = 1
       AND ia.internal_audit_sid = in_internal_audit_sid;
    
    IF v_non_compliance_type_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Audit type of audit sid '||in_internal_audit_sid||' does not have a finding type with default survey finding flag set.');
    END IF;

    SELECT MIN(non_compliance_id)
      INTO out_non_compliance_id
      FROM non_compliance
     WHERE created_in_audit_sid = in_internal_audit_sid
       AND non_compliance_type_id = v_non_compliance_type_id;

    IF out_non_compliance_id IS NULL THEN
        SELECT label
          INTO v_label
          FROM non_compliance_type
         WHERE non_compliance_type_id = v_non_compliance_type_id;

        INTERNAL_SaveNonCompliance(
            in_non_compliance_id            => NULL,
            in_internal_audit_sid            => in_internal_audit_sid,
            in_from_non_comp_default_id        => NULL,
            in_label                        => v_label,
            in_detail                        => NULL,
            in_non_compliance_type_id        => v_non_compliance_type_id,
            in_is_closed                    => 0,
            in_current_file_uploads            => v_current_file_uploads,
            in_new_file_uploads                => v_new_file_uploads,
            in_tag_ids                        => v_tag_ids,
            in_question_id                    => NULL,
            in_question_option_id            => NULL,
            out_non_compliance_id            => out_non_compliance_id
        );
    END IF;
END;

PROCEDURE AddNCIssueForDefFlgFindingType(
    in_response_id                IN    quick_survey_response.survey_response_id%TYPE,
    in_issue_type_id            IN    issue_type.issue_type_id%TYPE,
    in_label                    IN  issue.label%TYPE,
    in_description                IN  issue.description%TYPE,
    in_assign_to_role_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_assign_to_user_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_due_dtm                    IN    issue.due_dtm%TYPE                        DEFAULT NULL,
    in_is_urgent                IN    NUMBER                                    DEFAULT NULL,
    in_is_critical                IN    NUMBER                                    DEFAULT 0,
    out_issue_id                OUT issue.issue_id%TYPE
)
AS
    v_non_compliance_id                non_compliance.non_compliance_id%TYPE;
    v_internal_audit_sid            security.security_pkg.T_SID_ID;
BEGIN
    SELECT internal_audit_sid
      INTO v_internal_audit_sid
      FROM (
        SELECT internal_audit_sid
          FROM internal_audit
         WHERE survey_response_id = in_response_id
         UNION
        SELECT internal_audit_sid
          FROM internal_audit_survey
         WHERE survey_response_id = in_response_id
      );

    GetOrSetNCForDefFlgFindingType(
        in_internal_audit_sid     => v_internal_audit_sid,
        out_non_compliance_id    => v_non_compliance_id
    );

    AddNonComplianceIssue(
        in_non_compliance_id    => v_non_compliance_id,
        in_label                => in_label,
        in_description            => in_description,
        in_assign_to_role_sid    => in_assign_to_role_sid,
        in_assign_to_user_sid    => in_assign_to_user_sid,
        in_due_dtm                => in_due_dtm,
        in_is_urgent            => in_is_urgent,
        in_is_critical            => in_is_critical,
        out_issue_id            => out_issue_id
    );
END;

PROCEDURE AddNonComplianceIssue(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_label                    IN  issue.label%TYPE,
    in_description                IN  issue.description%TYPE,
    in_assign_to_role_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_assign_to_user_sid        IN    security_pkg.T_SID_ID                    DEFAULT NULL,
    in_due_dtm                    IN    issue.due_dtm%TYPE                        DEFAULT NULL,
    in_is_urgent                IN    NUMBER                                    DEFAULT NULL,
    in_is_critical                IN    NUMBER                                    DEFAULT 0,
    out_issue_id                OUT issue.issue_id%TYPE
)
AS
    v_min_audit_dtm                internal_audit.audit_dtm%TYPE;
    v_max_audit_dtm                internal_audit.audit_dtm%TYPE;
    v_region_sid                security_pkg.T_SID_ID;
    v_auditor_role_sid            internal_audit_type.auditor_role_sid%TYPE;
    v_audit_contact_role_sid    internal_audit_type.audit_contact_role_sid%TYPE;
    v_assign_issues_to_role        internal_audit_type.assign_issues_to_role%TYPE;
    v_assign_to_role_sid        security_pkg.T_SID_ID := in_assign_to_role_sid;
    v_assign_to_user_sid        security_pkg.T_SID_ID := in_assign_to_user_sid;
    v_auditor_user_sid            internal_audit.auditor_user_sid%TYPE;
    v_dummy_out_cur                security_pkg.T_OUTPUT_CUR;
    v_issue_type_id                issue_type.issue_type_id%TYPE;
    v_involve_auditor_in_issues    internal_audit_type.involve_auditor_in_issues%TYPE;
    v_auditor_company_sid        security_pkg.T_SID_ID;
    v_is_auditor_company_top    chain.company_type.is_top_company%TYPE;
BEGIN
    CheckNonComplianceReadable(in_non_compliance_id);

    IF NOT CanAddActionsToNonCompliance(in_non_compliance_id) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied adding action to non-compliance with id '||in_non_compliance_id);
    END IF;

    SELECT MIN(ia.audit_dtm), MIN(ia.audit_dtm), MIN(NVL(nc.Region_Sid, ia.region_sid)) , MIN(iat.auditor_role_sid),
           MIN(iat.audit_contact_role_sid), MIN(iat.assign_issues_to_role), MIN(auditor_user_sid)
           , MIN(iatg.issue_type_id) issue_type_id, MIN(iat.involve_auditor_in_issues), MIN(ia.auditor_company_sid)
           , MIN(cot.is_top_company)
      INTO v_min_audit_dtm, v_max_audit_dtm, v_region_sid, v_auditor_role_sid,
           v_audit_contact_role_sid, v_assign_issues_to_role, v_auditor_user_sid,
           v_issue_type_id, v_involve_auditor_in_issues, v_auditor_company_sid, v_is_auditor_company_top
      FROM internal_audit ia
      JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
      JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
      LEFT JOIN internal_audit_type_group iatg ON iat.internal_audit_type_group_id = iatg.internal_audit_type_group_id AND iat.app_sid = iatg.app_sid
      JOIN Non_Compliance nc ON nc.Non_Compliance_Id = anc.Non_Compliance_Id
      LEFT JOIN chain.company co ON ia.auditor_company_sid = co.company_sid
      LEFT JOIN chain.company_type cot ON co.company_type_id = cot.company_type_id
     WHERE anc.non_compliance_id = in_non_compliance_id;

    IF v_assign_to_role_sid IS NULL AND v_assign_issues_to_role=1 THEN
        FOR r IN (
            SELECT * FROM dual
             WHERE EXISTS(
                SELECT NULL FROM region_role_member
                 WHERE role_sid = v_auditor_role_sid
                   AND region_sid = v_region_sid
             )
        ) LOOP
            v_assign_to_role_sid := v_auditor_role_sid;
            v_assign_to_user_sid := null;
        END LOOP;
    END IF;

    IF v_issue_type_id IS NULL THEN
        v_issue_type_id := csr_data_pkg.ISSUE_NON_COMPLIANCE;
    END IF;

    -- TODO: issue_type_id should be droppped
    -- TODO: check constraint on issue is wrong?!
    -- find out what source label is used for
    issue_pkg.CreateIssue(
        in_label => in_label,
        in_description => in_description,
        in_source_label => NULL,
        in_issue_type_id => v_issue_type_id,
        in_correspondent_id => NULL,
        in_raised_by_user_sid => SYS_CONTEXT('SECURITY', 'SID'),
        in_assigned_to_user_sid => v_assign_to_user_sid,
        in_assigned_to_role_sid => v_assign_to_role_sid,
        in_priority_id => NULL,
        in_due_dtm => in_due_dtm,
        in_source_url => NULL,
        in_region_sid => v_region_sid,
        in_is_urgent => in_is_urgent,
        in_is_critical => in_is_critical,
        out_issue_id => out_issue_id);

    INSERT INTO issue_non_compliance (
        issue_non_compliance_id, non_compliance_id)
    VALUES (
        issue_non_compliance_id_seq.NEXTVAL, in_non_compliance_id);

    UPDATE issue
       SET issue_non_compliance_id = issue_non_compliance_id_seq.CURRVAL
     WHERE issue_id = out_issue_id;

    IF SYS_CONTEXT('SECURITY', 'SID') != v_auditor_user_sid THEN
        issue_pkg.AddUser(security_pkg.getact, out_issue_id, v_auditor_user_sid, v_dummy_out_cur);
    END IF;

    -- add auditor role to involved users if it has been set for the audit type
    IF v_auditor_role_sid IS NOT NULL THEN
        issue_pkg.AddRole(
            in_act_id     => security_pkg.GetAct,
            in_issue_id    => out_issue_id,
            in_role_sid    => v_auditor_role_sid,
            out_cur        => v_dummy_out_cur);
    END IF;

    -- add audit contact role to involved users if it has been set for the audit type
    IF v_audit_contact_role_sid IS NOT NULL THEN
        issue_pkg.AddRole(
            in_act_id     => security_pkg.GetAct,
            in_issue_id    => out_issue_id,
            in_role_sid    => v_audit_contact_role_sid,
            out_cur        => v_dummy_out_cur);
    END IF;

    -- involve the auditor company if the audit type stipulates it
    IF v_involve_auditor_in_issues = 1 AND v_is_auditor_company_top = 0 THEN
        issue_pkg.AddCompany(
            in_issue_id        => out_issue_id,
            in_company_sid    => v_auditor_company_sid,
            out_cur            => v_dummy_out_cur);
    END IF;
    
    UpdateNonCompClosureStatus(in_non_compliance_id);

    -- Trigger re-calc on IA indicators
    TriggerAuditAgg(TRUNC(LEAST(v_min_audit_dtm, SYSDATE),'MONTH'),
        ADD_MONTHS(TRUNC(GREATEST(SYSDATE, v_max_audit_dtm),'MONTH'),1));

END;

FUNCTION CheckNonComplianceIssue(
    in_non_compliance_id        IN    non_compliance.non_compliance_id%TYPE,
    in_issue_id                    IN    issue.issue_id%TYPE
) RETURN NUMBER
AS
    v_count                        NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM issue i
      JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id
     WHERE i.issue_id = in_issue_id
       AND inc.non_compliance_id = in_non_compliance_id;

    RETURN v_count;
END;

PROCEDURE SetPostIt(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_postit_id            IN    postit.postit_id%TYPE,
    out_postit_id            OUT postit.postit_id%TYPE
)
AS
BEGIN
    IF IsFlowAudit(in_internal_audit_sid) THEN
        IF NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD, security.security_pkg.PERMISSION_WRITE) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied writing post it to audit '||in_internal_audit_sid);
        END IF;
        -- We've done the security check ourselves
        postit_pkg.UNSEC_Save(in_postit_id, null, 'message', in_internal_audit_sid, out_postit_id);
    ELSE
        -- If not using flow capabilities, drop back to the old permissions of postits
        -- This isn't ideal as role users appear to be able to create postits but then errors
        -- when they click save
        postit_pkg.Save(in_postit_id, null, 'message', in_internal_audit_sid, out_postit_id);
    END IF;

    BEGIN
        INSERT INTO internal_audit_postit (internal_audit_sid, postit_id)
            VALUES (in_internal_audit_sid, out_postit_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL; -- ignore
    END;
END;

PROCEDURE GetPostIts(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR,
    out_cur_files            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT HasReadAccess(in_internal_audit_sid) OR (IsFlowAudit(in_internal_audit_sid)
       AND NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD, security.security_pkg.PERMISSION_READ)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading post its for audit '||in_internal_audit_sid);
    END IF;

    OPEN out_cur FOR
        SELECT iap.internal_audit_sid, p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid,
            p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
          FROM internal_audit_postit iap
            JOIN v$postit p ON iap.postit_id = p.postit_id AND iap.app_sid = p.app_sid
         WHERE internal_audit_sid = in_internal_audit_sid
         ORDER BY created_dtm;

    OPEN out_cur_files FOR
        SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
          FROM internal_audit_postit iap
            JOIN postit p ON iap.postit_id = p.postit_id AND iap.app_sid = p.app_sid
            JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
         WHERE internal_audit_sid = in_internal_audit_sid;
END;

PROCEDURE GetLatestCampaignSubmission(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT qsr.survey_response_id, qsr.last_submission_id
          FROM internal_audit ia
          JOIN region_survey_response rsr ON ia.survey_sid = rsr.survey_sid AND ia.region_sid = rsr.region_sid
          JOIN quick_survey_response qsr ON qsr.survey_response_id = rsr.survey_response_id
         WHERE ia.internal_audit_sid = in_internal_audit_sid
           AND qsr.last_submission_id > 0
           AND qsr.hidden = 0 -- until 
         ORDER BY rsr.period_end_dtm DESC;
END;

FUNCTION GetAuditWithComparisonFromSurv(
    in_survey_sid            IN    quick_survey.survey_sid%TYPE,
    in_survey_response_id    IN    quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER
AS
    v_audit_sid        security_pkg.T_SID_ID;
BEGIN
    SELECT internal_audit_sid
      INTO v_audit_sid
      FROM internal_audit
     WHERE survey_sid = in_survey_sid
       AND survey_response_id = in_survey_response_id
       AND comparison_response_id IS NOT NULL; -- this is a bit crap, but can't think of a way to check if a survey response is part of an audit which will be compared to a different survey response

    RETURN v_audit_sid;
END;

FUNCTION GetAuditFromResponseId(
    in_survey_response_id    IN    quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER
AS
    v_audit_sid        security_pkg.T_SID_ID;
BEGIN
    SELECT internal_audit_sid
      INTO v_audit_sid
      FROM internal_audit
     WHERE survey_response_id = in_survey_response_id;

    RETURN v_audit_sid;
END;

PROCEDURE GetComparisonSubmission(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT comparison_response_id, last_submission_id
          FROM internal_audit ia
          JOIN quick_survey_response qsr ON qsr.survey_response_id = ia.comparison_response_id
         WHERE internal_audit_sid = in_internal_audit_sid
           AND last_submission_id > 0
           AND comparison_response_id IS NOT NULL;
END;

PROCEDURE GetOrCreateSurveyResponse (
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_survey_version                IN    quick_survey_response.survey_version%TYPE DEFAULT NULL,
    out_is_new_response                OUT NUMBER,
    out_survey_sid                    OUT security_pkg.T_SID_ID,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
)
AS
    v_guid                    quick_survey_response.guid%TYPE;
    v_region_sid            security_pkg.T_SID_ID;
BEGIN
    IF in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
        SELECT survey_sid, survey_response_id, region_sid
          INTO out_survey_sid, out_response_id, v_region_sid
          FROM internal_audit
         WHERE internal_audit_sid = in_internal_audit_sid
          FOR UPDATE;
    ELSE
        SELECT ias.survey_sid, ias.survey_response_id, ia.region_sid
          INTO out_survey_sid, out_response_id, v_region_sid
          FROM internal_audit_survey ias
          JOIN internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid AND ia.app_sid = ias.app_sid
         WHERE ias.internal_audit_sid = in_internal_audit_sid
           AND ias.internal_audit_type_survey_id = in_ia_type_survey_id
          FOR UPDATE;
    END IF;

    out_is_new_response := 0;

    IF out_response_id IS NULL THEN
        -- get a new response
        quick_survey_pkg.NewResponse(out_survey_sid, in_survey_version, null, v_guid, out_response_id);
        -- store it
        IF in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
            UPDATE internal_audit
               SET survey_response_id = out_response_id
             WHERE internal_audit_sid = in_internal_audit_sid;
        ELSE
            UPDATE internal_audit_survey
               SET survey_response_id = out_response_id
             WHERE internal_audit_sid = in_internal_audit_sid
               AND internal_audit_type_survey_id = in_ia_type_survey_id;
        END IF;

        out_is_new_response := 1;

        --copy any answers for questions marked with "rembmer answer"
        quick_survey_pkg.CopyAnswersFromPrevious(out_survey_sid, out_response_id, v_region_sid, 0);
    END IF;
END;

PROCEDURE CopyPreviousSubmission(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_survey_response_id    IN    quick_survey_response.survey_response_id%TYPE,
    in_submission_id        IN    quick_survey_response.survey_response_id%TYPE,
    in_audit_type_survey_id    IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
)
AS
    v_is_new_response        NUMBER;
    v_survey_sid            security_pkg.T_SID_ID;
BEGIN
    GetOrCreateSurveyResponse(in_internal_audit_sid, in_audit_type_survey_id, NULL, v_is_new_response, v_survey_sid, out_response_id);
    
    UPDATE quick_survey_response
       SET question_xml_override = (
            SELECT question_xml_override
              FROM quick_survey_response
             WHERE survey_response_id = in_survey_response_id
       )
     WHERE survey_response_id = out_response_id;

    quick_survey_pkg.CopyResponse(in_survey_response_id, in_submission_id, out_response_id);

    IF in_audit_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
        UPDATE internal_audit
           SET comparison_response_id = in_survey_response_id
         WHERE internal_audit_sid = in_internal_audit_sid;
    END IF;
END;

PROCEDURE GetOrCreateSummaryResponse(
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    in_survey_version                IN    quick_survey_response.survey_version%TYPE DEFAULT NULL,
    out_is_new_response                OUT NUMBER,
    out_survey_sid                    OUT security_pkg.T_SID_ID,
    out_guid                        OUT quick_survey_response.guid%TYPE,
    out_response_id                    OUT    quick_survey_response.survey_response_id%TYPE
)
AS
BEGIN
    SELECT NVL(qsr.survey_sid, iat.summary_survey_sid), ia.summary_response_id
      INTO out_survey_sid, out_response_id
      FROM internal_audit ia
      JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
      LEFT JOIN csr.quick_survey_response qsr ON qsr.survey_response_id = ia.summary_response_id
     WHERE ia.internal_audit_sid = in_internal_audit_sid;

    out_is_new_response := 0;

    IF out_response_id IS NULL THEN
        -- get a new response
        quick_survey_pkg.NewResponse(out_survey_sid, in_survey_version, null, out_guid, out_response_id);
        -- store it
        UPDATE internal_audit
           SET summary_response_id = out_response_id
         WHERE internal_audit_sid = in_internal_audit_sid;

        out_is_new_response := 1;
    END IF;
END;

PROCEDURE GetAuditTypeFlowStates(
    in_internal_audit_type_id    IN internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- No permissions as audit types are on the portlet
    OPEN out_cur FOR
        SELECT iat.internal_audit_type_id, fs.flow_sid, fs.label, fs.flow_state_id,
               fs.lookup_key, fs.state_colour, fs.pos seq, f.label flow_label
          FROM internal_audit_type iat
          JOIN flow f ON iat.app_sid = f.app_sid AND iat.flow_sid = f.flow_sid
          JOIN flow_state fs ON f.app_sid = fs.app_sid AND f.flow_sid = fs.flow_sid
         WHERE iat.internal_audit_type_id = NVL(in_internal_audit_type_id, iat.internal_audit_type_id)
           AND fs.is_deleted = 0
         ORDER BY fs.pos;
END;

PROCEDURE GetInternalAuditTypeGroupsFast(
    out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
    -- We only need permission checks for the menu SOs, and we redact them if they're not readable.

    -- shorter version without menu ACLs as these are rarely required and this sproc can get called
    -- a lot by different filters
    OPEN out_cur FOR
        SELECT iatg.internal_audit_type_group_id, iatg.label, iatg.lookup_key,
               iatg.applies_to_regions, iatg.applies_to_users, iatg.use_user_primary_region,
               iatg.internal_audit_ref_prefix, iatg.issue_type_id,
               iatg.audit_singular_label, iatg.audit_plural_label,
               iatg.auditee_user_label, iatg.auditor_user_label, iatg.auditor_name_label,
               iatg.block_css_class
          FROM internal_audit_type_group iatg
         ORDER BY label;
END;

PROCEDURE GetInternalAuditTypeGroups(
    out_cur OUT SYS_REFCURSOR
)
AS
    v_menu_sid        security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'menu');
    v_so_table        security.T_SO_DESCENDANTS_TABLE := security.securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_menu_sid, security_pkg.PERMISSION_READ);
BEGIN
    -- We only need permission checks for the menu SOs, and we redact them if they're not readable.

    OPEN out_cur FOR
        SELECT iatg.internal_audit_type_group_id, iatg.label, iatg.lookup_key,
               iatg.applies_to_regions, iatg.applies_to_users, iatg.use_user_primary_region,
               iatg.internal_audit_ref_prefix, iatg.issue_type_id,
               iatg.audit_singular_label, iatg.audit_plural_label,
               iatg.auditee_user_label, iatg.auditor_user_label, iatg.auditor_name_label,
               iatg.block_css_class,
               at.sid_id audits_menu_sid, at.name audits_menu_name,
               nat.sid_id new_audit_menu_sid, nat.name new_audit_menu_name,
               nct.sid_id non_compliances_menu_sid, nct.name non_compliances_menu_name
          FROM internal_audit_type_group iatg
          LEFT JOIN TABLE(v_so_table) at ON at.sid_id = iatg.audits_menu_sid
          LEFT JOIN TABLE(v_so_table) nat ON nat.sid_id = iatg.new_audit_menu_sid
          LEFT JOIN TABLE(v_so_table) nct ON nct.sid_id = iatg.non_compliances_menu_sid
         ORDER BY label;
END;

PROCEDURE INTERNAL_GetInternalAuditTypes(
    in_internal_audit_source_id        IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                         OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR 
        SELECT iat.internal_audit_type_id, iat.label, iat.every_n_months,
                iat.auditor_role_sid, iat.audit_contact_role_sid,
                iat.default_survey_sid, qs.label default_survey_label,
                iat.default_auditor_org, iat.override_issue_dtm,
                NVL(cnt.mapped_indicator_count, 0) mapped_indicator_count,
                iat.assign_issues_to_role, iat.auditor_can_take_ownership, iat.add_nc_per_question,
                NVL(iat.nc_audit_child_region, 0) nc_audit_child_region, iat.flow_sid, f.label flow_label,
                atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key,
                atg.applies_to_regions, atg.applies_to_users, atg.use_user_primary_region,
                atg.audit_singular_label, atg.audit_plural_label, 
                atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
                iat.internal_audit_type_source_id, iat.summary_survey_sid, sqs.label summary_survey_label,
                iat.audit_coord_role_or_group_sid, CASE WHEN acr.role_sid IS NULL THEN 0 ELSE 1 END audit_coord_sid_is_role,
                iat.send_auditor_expiry_alerts, iat.validity_months, iat.tab_sid, iat.form_path, iat.form_sid,
                iat.internal_audit_type_group_id, iat.internal_audit_ref_helper_func,
                iat.nc_score_type_id, st.label nc_score_type_label,
                iat.active, iat.show_primary_survey_in_header,
                iat.primary_survey_active, NVL(iat.primary_survey_label, 'Survey'),
                iat.primary_survey_mandatory, iat.primary_survey_group_key,
                iat.use_legacy_closed_definition, iat.involve_auditor_in_issues, iat.lookup_key,
                CASE WHEN EXISTS (SELECT * FROM internal_audit ia WHERE ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.deleted = 0) THEN 0 ELSE 1 END all_audits_in_trash
          FROM internal_audit_type iat
          LEFT JOIN v$quick_survey qs ON iat.default_survey_sid = qs.survey_sid
          LEFT JOIN v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid
          LEFT JOIN flow f ON iat.flow_sid = f.flow_sid
          LEFT JOIN score_type st ON st.score_type_id = iat.nc_score_type_id
          LEFT JOIN internal_audit_type_group atg ON atg.Internal_Audit_Type_Group_Id = iat.Internal_Audit_Type_Group_Id
          LEFT JOIN role acr ON acr.role_sid = iat.audit_coord_role_or_group_sid
          LEFT JOIN (
            SELECT x.internal_audit_type_id, count(i.ind_sid) mapped_indicator_count
              FROM internal_audit_type x
              JOIN ind i ON x.app_sid = i.app_sid AND i.lookup_key LIKE x.lookup_key||'%'
             WHERE x.lookup_key IS NOT NULL
             GROUP BY x.internal_audit_type_id
          ) cnt ON iat.internal_audit_type_id = cnt.internal_audit_type_id
         WHERE iat.app_sid = security_pkg.GetApp
           AND iat.internal_audit_type_source_id = NVL(in_internal_audit_source_id, internal_audit_type_source_id)
         ORDER BY lower(iat.label), iat.internal_audit_type_id;
END;

PROCEDURE GetInternalAuditTypes(
    out_cur                     OUT SYS_REFCURSOR
)
AS
BEGIN
    INTERNAL_GetInternalAuditTypes(NULL, out_cur);
END;

PROCEDURE INTERNAL_GetIATExpiryAlrtRoles(
    in_internal_audit_source_id     IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- No permissions as audit types are on the portlet
    OPEN out_cur FOR
        SELECT iat.internal_audit_type_id, atrar.role_sid, iat.internal_audit_type_source_id
          FROM audit_type_expiry_alert_role atrar
          JOIN internal_audit_type iat
            ON atrar.internal_audit_type_id = iat.internal_audit_type_id
         WHERE iat.app_sid = security_pkg.GetApp
           AND iat.internal_audit_type_source_id = NVL(in_internal_audit_source_id, internal_audit_type_source_id);
END;

PROCEDURE GetIATExpiryAlertRoles(
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR    
)
AS
BEGIN
    -- No permissions as audit types are on the portlet
    INTERNAL_GetIATExpiryAlrtRoles(NULL, out_cur);
END;

PROCEDURE INTERNAL_GetIATInvolmentTypes(
    in_internal_audit_source_id        IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR    
)
AS
BEGIN
    -- No permissions as audit types are on the portlet
    OPEN out_cur FOR
        SELECT iat.internal_audit_type_id, iat.internal_audit_type_source_id,
               atfit.audit_type_flow_inv_type_id, atfit.flow_involvement_type_id, atfit.min_users, atfit.max_users,
               atfit.users_role_or_group_sid, CASE WHEN ur.role_sid IS NULL THEN 0 ELSE 1 END users_sid_is_role
          FROM internal_audit_type iat
          JOIN audit_type_flow_inv_type atfit ON atfit.internal_audit_type_id = iat.internal_audit_type_id
          LEFT JOIN role ur ON ur.role_sid = atfit.users_role_or_group_sid
         WHERE iat.app_sid = security.security_pkg.GetApp
           AND iat.internal_audit_type_source_id = NVL(in_internal_audit_source_id, internal_audit_type_source_id);
END;

PROCEDURE GetIATInvolmentTypes(
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR    
)
AS
BEGIN
    -- No permissions as audit types are on the portlet
    Internal_GetIATInvolmentTypes(NULL, out_cur);
END;

PROCEDURE GetInternalAuditTypes(
    in_internal_audit_source_id    IN  internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                        OUT    SYS_REFCURSOR,
    out_expiry_alert_role_cur    OUT SYS_REFCURSOR,
    out_involvement_type_cur    OUT SYS_REFCURSOR,
    out_carry_forward_cur        OUT SYS_REFCURSOR,
    out_closure_type_cur        OUT SYS_REFCURSOR,
    out_survey_type_cur            OUT SYS_REFCURSOR,
    out_iat_flow_states_cur        OUT SYS_REFCURSOR,
    out_iat_reports_cur         OUT SYS_REFCURSOR
)
AS
BEGIN
    -- No permissions as audit types are on the portlet
    INTERNAL_GetInternalAuditTypes(in_internal_audit_source_id, out_cur);
    INTERNAL_GetIATExpiryAlrtRoles(in_internal_audit_source_id,out_expiry_alert_role_cur);
    INTERNAL_GetIATInvolmentTypes(in_internal_audit_source_id, out_involvement_type_cur);
    GetAuditTypeCarryForwards(out_carry_forward_cur);
    GetClosureTypesByAuditType(NULL, out_closure_type_cur);
    GetAuditTypeSurveys(NULL, out_survey_type_cur);
    GetAuditTypeFlowStates(NULL, out_iat_flow_states_cur);
    GetInternalAuditTypeReports(NULL, out_iat_reports_cur);
END;

PROCEDURE FilterInternalAuditTypes(
    in_query                    VARCHAR2,
    in_internal_audit_source_id    internal_audit_type.internal_audit_type_source_id%TYPE DEFAULT INTERNAL_AUDIT_SOURCE_ID,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    -- No permissions as audit types are on the portlet
    -- this gets called by the randomly duplicated chain supplier audit creation page too.
    -- Only returns active types
    OPEN out_cur FOR
        SELECT internal_audit_type_id, label, every_n_months,
                auditor_role_sid, audit_contact_role_sid,
                default_survey_sid, default_auditor_org, override_issue_dtm,
                assign_issues_to_role, add_nc_per_question, flow_sid, internal_audit_type_source_id, summary_survey_sid,
                send_auditor_expiry_alerts, tab_sid, form_path, active
          FROM internal_audit_type
         WHERE app_sid = security_pkg.GetApp
           AND lower(label) like '%'||lower(in_query)||'%'
           AND internal_audit_type_source_id = NVL(in_internal_audit_source_id, internal_audit_type_source_id)
           AND active = 1
         ORDER BY lower(label), internal_audit_type_id;
END;

PROCEDURE DeleteTrashedAudits(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
)
AS
BEGIN
    FOR r IN
    (
        SELECT internal_audit_sid
          FROM internal_audit a
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND deleted = 1
           AND app_sid = security_pkg.GetApp
    )
    LOOP
        securableobject_pkg.DeleteSO(security_pkg.GetAct, r.internal_audit_sid);
    END LOOP;
END;

PROCEDURE DeleteInternalAuditTypeGroup(
    in_ia_type_group_id            IN    internal_audit_type_group.internal_audit_type_group_id%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit type groups');
    END IF;

    FOR r IN (
        SELECT internal_audit_type_id 
          FROM internal_audit_type
         WHERE internal_audit_type_group_id = in_ia_type_group_id
    ) LOOP
        IF NOT AreAllAuditsInTrash(r.internal_audit_type_id) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Audit type group '||in_ia_type_group_id||' cannot be deleted, because there are undeleted audits with type '||r.internal_audit_type_id||'!');
        END IF;
    END LOOP;

    UPDATE internal_audit_type
       SET internal_audit_type_group_id = NULL
     WHERE internal_audit_type_group_id = in_ia_type_group_id;

    DELETE FROM internal_audit_type_group
     WHERE internal_audit_type_group_id = in_ia_type_group_id;
END;

PROCEDURE DeleteInternalAuditType(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    IF AreAllAuditsInTrash(in_internal_audit_type_id) THEN
        FOR r IN (
            SELECT audit_closure_type_id
              FROM audit_type_closure_type
             WHERE internal_audit_type_id = in_internal_audit_type_id
               AND app_sid = security_pkg.GetApp
        ) LOOP
            DeleteAuditTypeClosureType(in_internal_audit_type_id, r.audit_closure_type_id);
        END LOOP;

        DELETE FROM audit_type_expiry_alert_role
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        DELETE FROM audit_type_tab
         WHERE internal_audit_type_id = in_internal_audit_type_id
            AND app_sid = security_pkg.GetApp;

        DELETE FROM audit_type_header
         WHERE internal_audit_type_id = in_internal_audit_type_id
            AND app_sid = security_pkg.GetApp;

        DELETE FROM non_comp_type_audit_type
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        DELETE FROM non_comp_type_rpt_audit_type
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        DELETE FROM flow_state_audit_ind
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        DELETE FROM internal_audit_type_carry_fwd
         WHERE (
                from_internal_audit_type_id = in_internal_audit_type_id OR
                to_internal_audit_type_id = in_internal_audit_type_id
         ) AND app_sid = security_pkg.GetApp;

        DeleteTrashedAudits(in_internal_audit_type_id);

        DELETE FROM internal_audit_type_survey
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        DELETE FROM internal_audit_type_report
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        DELETE FROM internal_audit_type
         WHERE internal_audit_type_id=in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;
    ELSE
        RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_AUDIT_TYPE_AUDIT_EXISTS, 'Audit type: '||in_internal_audit_type_id||' cannot be deleted, because there are undeleted audits with this type!');
    END IF;
END;

FUNCTION AreAllAuditsInTrash(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
)
RETURN BOOLEAN
AS
    v_count    NUMBER;
BEGIN
    FOR r IN (
        SELECT 1
          FROM internal_audit
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND deleted = 0
           AND app_sid = security_pkg.GetApp
    ) LOOP
        RETURN FALSE;
    END LOOP;

    RETURN TRUE;
END;

FUNCTION AreAllAuditsInTrash_SQL(
    in_internal_audit_type_id    IN    internal_audit_type.internal_audit_type_id%TYPE
)
RETURN NUMBER
AS
BEGIN
    IF AreAllAuditsInTrash(in_internal_audit_type_id) THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;

PROCEDURE SaveInternalAuditTypeGroup(
    in_ia_type_group_id                IN  internal_audit_type_group.internal_audit_type_group_id%TYPE,
    in_label                        IN    internal_audit_type_group.label%TYPE,
    in_lookup_key                    IN    internal_audit_type_group.lookup_key%TYPE,
    in_applies_to_regions            IN    internal_audit_type_group.applies_to_regions%TYPE,
    in_applies_to_users                IN    internal_audit_type_group.applies_to_users%TYPE,
    in_use_user_primary_region        IN    internal_audit_type_group.use_user_primary_region%TYPE,
    in_ref_prefix                    IN    internal_audit_type_group.internal_audit_ref_prefix%TYPE,
    in_issue_type_id                IN    internal_audit_type_group.issue_type_id%TYPE,
    in_audit_singular_label            IN    internal_audit_type_group.audit_singular_label%TYPE,
    in_audit_plural_label            IN    internal_audit_type_group.audit_plural_label%TYPE,
    in_auditee_user_label            IN    internal_audit_type_group.auditee_user_label%TYPE,
    in_auditor_user_label            IN    internal_audit_type_group.auditor_user_label%TYPE,
    in_auditor_name_label            IN    internal_audit_type_group.auditor_name_label%TYPE,
    in_block_css_class                IN    internal_audit_type_group.block_css_class%TYPE,
    in_applies_to_permits            IN    internal_audit_type_group.applies_to_permits%TYPE,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_audits_sid                    security_pkg.T_SID_ID  := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_menu_sid                        security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'menu');
    v_so_table                        security.T_SO_DESCENDANTS_TABLE := securableobject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_menu_sid, security_pkg.PERMISSION_READ);
    v_lookup_key                    internal_audit_type_group.lookup_key%TYPE;
    v_lookup_key_count                NUMBER := 0;
    v_lookup_key_suffix                NUMBER := 0;
    v_ia_type_group_id                internal_audit_type_group.internal_audit_type_group_id%TYPE;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit type groups');
    END IF;

    IF in_ia_type_group_id IS NULL THEN
        v_lookup_key := in_lookup_key;
        IF v_lookup_key IS NULL THEN
            v_lookup_key := UPPER(in_label);

            LOOP
                SELECT count(*)
                  INTO v_lookup_key_count
                  FROM internal_audit_type_group
                 WHERE UPPER(lookup_key) = UPPER(v_lookup_key);

                IF v_lookup_key_count = 0 THEN
                    EXIT;
                END IF;

                v_lookup_key_suffix := v_lookup_key_suffix + 1;
                v_lookup_key := UPPER(in_label) || v_lookup_key_suffix;
            END LOOP;
        END IF;

        INSERT INTO internal_audit_type_group (internal_audit_type_group_id, label, lookup_key,
                                               applies_to_regions, applies_to_users, use_user_primary_region,
                                               internal_audit_ref_prefix, issue_type_id,
                                               audit_singular_label, audit_plural_label,
                                               auditee_user_label, auditor_user_label, auditor_name_label,
                                               block_css_class, applies_to_permits)
                                       VALUES (internal_audit_type_group_seq.NEXTVAL, in_label, v_lookup_key,
                                               in_applies_to_regions, in_applies_to_users, in_use_user_primary_region,
                                               in_ref_prefix, in_issue_type_id,
                                               in_audit_singular_label, in_audit_plural_label,
                                               in_auditee_user_label, in_auditor_user_label, in_auditor_name_label,
                                               in_block_css_class, in_applies_to_permits)
        RETURNING internal_audit_type_group_id INTO v_ia_type_group_id;
    ELSE
        SELECT lookup_key
          INTO v_lookup_key
          FROM internal_audit_type_group
         WHERE internal_audit_type_group_id = in_ia_type_group_id;

        UPDATE internal_audit_type_group
           SET label = in_label,
               lookup_key = NVL(in_lookup_key, lookup_key),
               applies_to_regions = in_applies_to_regions,
               applies_to_users = in_applies_to_users,
               use_user_primary_region = in_use_user_primary_region,
               internal_audit_ref_prefix = in_ref_prefix,
               issue_type_id = in_issue_type_id,
               audit_singular_label = in_audit_singular_label,
               audit_plural_label = in_audit_plural_label,
               auditee_user_label = in_auditee_user_label,
               auditor_user_label = in_auditor_user_label,
               auditor_name_label = in_auditor_name_label,
               block_css_class = in_block_css_class,
               applies_to_permits = in_applies_to_permits
         WHERE internal_audit_type_group_id = in_ia_type_group_id;

        IF LOWER(NVL(in_lookup_key, v_lookup_key)) != LOWER(v_lookup_key) THEN
            UPDATE security.menu
               SET action = REPLACE(action, 'group=' || v_lookup_key,  'group=' || in_lookup_key)
             WHERE LOWER(action) LIKE '/csr/site/audit/%';
        END IF;

        v_ia_type_group_id := in_ia_type_group_id;
    END IF;

    OPEN out_cur FOR
        SELECT iatg.internal_audit_type_group_id, iatg.label, iatg.lookup_key,
               iatg.applies_to_regions, iatg.applies_to_users, iatg.use_user_primary_region,
               iatg.internal_audit_ref_prefix, iatg.issue_type_id,
               iatg.audit_singular_label, iatg.audit_plural_label,
               iatg.auditee_user_label, iatg.auditor_user_label, iatg.auditor_name_label,
               iatg.block_css_class, iatg.applies_to_permits,
               at.sid_id audits_menu_sid, at.name audits_menu_name,
               nat.sid_id new_audit_menu_sid, nat.name new_audit_menu_name,
               nct.sid_id non_compliances_menu_sid, nct.name non_compliances_menu_name
          FROM internal_audit_type_group iatg
          LEFT JOIN TABLE(v_so_table) at ON at.sid_id = iatg.audits_menu_sid
          LEFT JOIN TABLE(v_so_table) nat ON nat.sid_id = iatg.new_audit_menu_sid
          LEFT JOIN TABLE(v_so_table) nct ON nct.sid_id = iatg.non_compliances_menu_sid
         WHERE iatg.internal_audit_type_group_id = v_ia_type_group_id;
END;

PROCEDURE FindMenuSid(
    in_name            IN    security.security_pkg.T_SO_NAME,
    out_menu_sid     OUT security. security_pkg.T_SID_ID        
)
IS
    v_cur            security.security_pkg.T_OUTPUT_CUR;
    v_row            security.menu%ROWTYPE;
BEGIN
    security.menu_pkg.FindMenuItem(
        security.security_pkg.GetACT, 
        security.security_pkg.GetApp, 
        in_name,
        v_cur
    );

    IF v_cur%NOTFOUND THEN
        out_menu_sid := NULL;
    ELSE
        FETCH v_cur INTO v_row;
        out_menu_sid := v_row.sid_id;
    END IF;
END;

PROCEDURE MakeInternalAuditTypeGroupMenu(
    in_ia_type_group_id                IN  internal_audit_type_group.internal_audit_type_group_id%TYPE,
    in_include_non_compliances        IN    NUMBER,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
)
IS
    v_audits_sid                    security_pkg.T_SID_ID  := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    v_menu_sid                        security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'menu');
    v_lookup_key                    internal_audit_type_group.lookup_key%TYPE;
    v_label                            internal_audit_type_group.label%TYPE;
    v_audit_singular_label            internal_audit_type_group.audit_singular_label%TYPE;
    v_audit_plural_label            internal_audit_type_group.audit_plural_label%TYPE;
    v_audits_menu_sid                security_pkg.T_SID_ID;
    v_new_audit_menu_sid            security_pkg.T_SID_ID;
    v_non_compliances_menu_sid        security_pkg.T_SID_ID;
    v_parent_menu_sid                security_pkg.T_SID_ID;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit type groups');
    END IF;
    
    SELECT lookup_key, label, NVL(audit_singular_label, label), NVL(audit_plural_label, label),
           audits_menu_sid, new_audit_menu_sid, non_compliances_menu_sid
      INTO v_lookup_key, v_label, v_audit_singular_label, v_audit_plural_label,
           v_audits_menu_sid, v_new_audit_menu_sid, v_non_compliances_menu_sid
      FROM internal_audit_type_group
     WHERE internal_audit_type_group_id = in_ia_type_group_id;

    -- If we don't have a reference to a menu item by SID, can we find them by lookup key?

    IF v_audits_menu_sid IS NULL THEN
        FindMenuSid('csr_audit_browse_'    || LOWER(v_lookup_key), v_audits_menu_sid);
    END IF;

    IF v_new_audit_menu_sid IS NULL THEN
        FindMenuSid('csr_site_audit_editAudit_'    || LOWER(v_lookup_key), v_new_audit_menu_sid);
    END IF;

    IF v_non_compliances_menu_sid IS NULL THEN
        FindMenuSid('csr_non_compliance_list_'    || LOWER(v_lookup_key), v_non_compliances_menu_sid);
    END IF;

    -- If any of the existing menu items have a parent, we'll put any others that we create in with it.

    IF v_parent_menu_sid IS NULL AND v_audits_menu_sid IS NOT NULL THEN
        v_parent_menu_sid := securableobject_pkg.GetParent(SYS_CONTEXT('SECURITY', 'ACT'),  v_audits_menu_sid);
    END IF;

    IF v_parent_menu_sid IS NULL AND v_new_audit_menu_sid IS NOT NULL THEN
        v_parent_menu_sid := securableobject_pkg.GetParent(SYS_CONTEXT('SECURITY', 'ACT'),  v_new_audit_menu_sid);
    END IF;

    IF v_parent_menu_sid IS NULL AND v_non_compliances_menu_sid IS NOT NULL THEN
        v_parent_menu_sid := securableobject_pkg.GetParent(SYS_CONTEXT('SECURITY', 'ACT'), v_non_compliances_menu_sid);
    END IF;
    
    IF v_parent_menu_sid IS NULL THEN
        security.menu_pkg.CreateMenu(
            SYS_CONTEXT('SECURITY', 'ACT'), 
            v_menu_sid, 
            LOWER(v_lookup_key),
            v_label, 
            '/csr/site/audit/auditList.acds?group=' || v_lookup_key,
            -1, 
            null,
            v_parent_menu_sid
        );
    END IF;

    IF v_audits_menu_sid IS NULL THEN
        security.menu_pkg.CreateMenu(
            SYS_CONTEXT('SECURITY', 'ACT'), 
            v_parent_menu_sid, 
            'csr_audit_browse_'    || LOWER(v_lookup_key),
            v_audit_plural_label || ' list', 
            '/csr/site/audit/auditList.acds?group=' || v_lookup_key,
            -1, 
            null,
            v_audits_menu_sid
        );
    END IF;

    IF v_new_audit_menu_sid IS NULL THEN
        security.menu_pkg.CreateMenu(
            SYS_CONTEXT('SECURITY', 'ACT'), 
            v_parent_menu_sid, 
            'csr_site_audit_editAudit_'    || LOWER(v_lookup_key),
            'New ' || v_audit_singular_label, 
            '/csr/site/audit/editAudit.acds?group=' || v_lookup_key,
            -1, 
            null,
            v_new_audit_menu_sid
        );
    END IF;

    IF v_non_compliances_menu_sid IS NULL AND in_include_non_compliances > 0 THEN
        security.menu_pkg.CreateMenu(
            SYS_CONTEXT('SECURITY', 'ACT'), 
            v_parent_menu_sid, 
            'csr_non_compliance_list_'    || LOWER(v_lookup_key),
            'Findings', 
            '/csr/site/audit/nonComplianceList.acds?group=' || v_lookup_key,
            -1, 
            null,
            v_non_compliances_menu_sid
        );
    END IF;

    UPDATE internal_audit_type_group
       SET audits_menu_sid = v_audits_menu_sid,
           new_audit_menu_sid = v_new_audit_menu_sid,
           non_compliances_menu_sid = v_non_compliances_menu_sid
     WHERE internal_audit_type_group_id = in_ia_type_group_id;

    OPEN out_cur FOR
        SELECT audits_menu_sid, new_audit_menu_sid, non_compliances_menu_sid
          FROM internal_audit_type_group
         WHERE internal_audit_type_group_id = in_ia_type_group_id;
END;

PROCEDURE SaveInternalAuditType(
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    in_label                        IN    internal_audit_type.label%TYPE,
    in_every_n_months                IN    internal_audit_type.every_n_months%TYPE,
    in_auditor_role_sid                IN    internal_audit_type.auditor_role_sid%TYPE,
    in_audit_contact_role_sid        IN    internal_audit_type.audit_contact_role_sid%TYPE,
    in_default_survey_sid            IN    internal_audit_type.default_survey_sid%TYPE,
    in_default_auditor_org            IN    internal_audit_type.default_auditor_org%TYPE,
    in_override_issue_dtm            IN    internal_audit_type.override_issue_dtm%TYPE,
    in_assign_issues_to_role        IN    internal_audit_type.assign_issues_to_role%TYPE,
    in_involve_auditor_in_issues    IN    internal_audit_type.involve_auditor_in_issues%TYPE,
    in_auditor_can_take_ownership    IN  internal_audit_type.auditor_can_take_ownership%TYPE,
    in_add_nc_per_question            IN    internal_audit_type.add_nc_per_question%TYPE,
    in_nc_audit_child_region        IN    internal_audit_type.nc_audit_child_region%TYPE,
    in_flow_sid                        IN  internal_audit_type.flow_sid%TYPE,
    in_internal_audit_source_id        IN  internal_audit_type.internal_audit_type_source_id%TYPE,
    in_summary_survey_sid            IN  internal_audit_type.summary_survey_sid%TYPE,
    in_send_auditor_expiry_alerts    IN  internal_audit_type.send_auditor_expiry_alerts%TYPE,
    in_expiry_alert_roles            IN  security_pkg.T_SID_IDS,
    in_validity_months                IN    internal_audit_type.validity_months%TYPE,
    in_audit_c_role_or_group_sid    IN  internal_audit_type.audit_coord_role_or_group_sid%TYPE DEFAULT NULL,
    in_tab_sid                        IN  internal_audit_type.tab_sid%TYPE DEFAULT NULL,
    in_form_path                    IN  internal_audit_type.form_path%TYPE DEFAULT NULL,
    in_form_sid                        IN  internal_audit_type.form_sid%TYPE DEFAULT NULL,
    in_ia_type_group_id                IN  internal_audit_type.internal_audit_type_group_id%TYPE DEFAULT NULL,
    in_nc_score_type_id                IN    internal_audit_type.nc_score_type_id%TYPE DEFAULT NULL,
    in_active                        IN  internal_audit_type.active%TYPE DEFAULT 1,
    in_show_primary_survey_in_hdr    IN    internal_audit_type.show_primary_survey_in_header%TYPE DEFAULT 1,
    in_use_legacy_closed_def        IN    internal_audit_type.use_legacy_closed_definition%TYPE DEFAULT 0,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_internal_audit_type_id        internal_audit_type.internal_audit_type_id%TYPE := in_internal_audit_type_id;
    v_flow_sid                        internal_audit_type.flow_sid%TYPE := in_flow_sid;
    v_audits_sid                    security_pkg.T_SID_ID;
    v_old_nc_score_type_id            internal_audit_type.nc_score_type_id%TYPE;
    v_old_override_issue_dtm        internal_audit_type.override_issue_dtm%TYPE;
    v_expiry_alert_roles            security.T_SID_TABLE;
    v_tab_plugin_id                    plugin.plugin_id%TYPE;
    v_header_plugin_id                plugin.plugin_id%TYPE;
    v_show_primary_survey_in_hdr    internal_audit_type.show_primary_survey_in_header%TYPE;

BEGIN
    -- XXX: needs auditing adding
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    v_expiry_alert_roles := security_pkg.SidArrayToTable(in_expiry_alert_roles);

    IF MultipleSurveysEnabled THEN
        v_show_primary_survey_in_hdr := in_show_primary_survey_in_hdr;
    ELSE
        v_show_primary_survey_in_hdr := 1;
    END IF;
    
    IF NVL(in_internal_audit_type_id, -1)=-1 THEN
        INSERT INTO internal_audit_type (internal_audit_type_id, label,
                every_n_months, auditor_role_sid, audit_contact_role_sid,
                default_survey_sid, default_auditor_org, override_issue_dtm,
                assign_issues_to_role, auditor_can_take_ownership, add_nc_per_question, nc_audit_child_region, flow_sid,
                internal_audit_type_source_id, summary_survey_sid, audit_coord_role_or_group_sid,
                send_auditor_expiry_alerts, validity_months, tab_sid, form_path, form_sid,
                internal_audit_type_group_id, nc_score_type_id, active, show_primary_survey_in_header, use_legacy_closed_definition,
                involve_auditor_in_issues)
        VALUES (internal_audit_type_id_seq.NEXTVAL, in_label,
                in_every_n_months, in_auditor_role_sid, in_audit_contact_role_sid,
                in_default_survey_sid, in_default_auditor_org, in_override_issue_dtm,
                in_assign_issues_to_role, in_auditor_can_take_ownership, in_add_nc_per_question, in_nc_audit_child_region, in_flow_sid,
                in_internal_audit_source_id, in_summary_survey_sid, in_audit_c_role_or_group_sid,
                in_send_auditor_expiry_alerts, in_validity_months, in_tab_sid, in_form_path, in_form_sid,
                in_ia_type_group_id, in_nc_score_type_id, in_active, v_show_primary_survey_in_hdr, in_use_legacy_closed_def,
                in_involve_auditor_in_issues)
        RETURNING internal_audit_type_id INTO v_internal_audit_type_id;

        -- enable a default set of plugins so that the edit page is usable
        SELECT MIN(plugin_id)
          INTO v_tab_plugin_id
          FROM plugin
         WHERE js_class = 'Audit.Controls.ExecutiveSummary'
           AND app_sid IS NULL;

        INSERT INTO csr.audit_type_tab (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, tab_label, pos)
            VALUES (security_pkg.GetApp, v_internal_audit_type_id, csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB, v_tab_plugin_id, 'Executive Summary', 0);

        SELECT MIN(plugin_id)
          INTO v_tab_plugin_id
          FROM plugin
         WHERE js_class = 'Audit.Controls.FindingTab'
           AND app_sid IS NULL;

        INSERT INTO csr.audit_type_tab (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, tab_label, pos)
            VALUES (security_pkg.GetApp, v_internal_audit_type_id, csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB, v_tab_plugin_id, 'Findings', 1);

        SELECT MIN(plugin_id)
          INTO v_tab_plugin_id
          FROM plugin
         WHERE js_class = 'Audit.Controls.Documents'
           AND app_sid IS NULL;

        INSERT INTO csr.audit_type_tab (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, tab_label, pos)
            VALUES (security_pkg.GetApp, v_internal_audit_type_id, csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB, v_tab_plugin_id, 'Documents', 2);


        SELECT MIN(plugin_id)
          INTO v_header_plugin_id
          FROM plugin
         WHERE js_class = 'Audit.Controls.FullAuditHeader'
           AND app_sid IS NULL;

        INSERT INTO csr.audit_type_header (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, pos)
            VALUES (security_pkg.GetApp, v_internal_audit_type_id, csr_data_pkg.PLUGIN_TYPE_AUDIT_HEADER, v_header_plugin_id, 0);

        -- link to all exising non compliance types by default
        INSERT INTO non_comp_type_audit_type (internal_audit_type_id, non_compliance_type_id)
             SELECT v_internal_audit_type_id, non_compliance_type_id
               FROM non_compliance_type;
    ELSE
        SELECT override_issue_dtm, nc_score_type_id
          INTO v_old_override_issue_dtm, v_old_nc_score_type_id
          FROM internal_audit_type
         WHERE internal_audit_type_id = in_internal_audit_type_id;

        IF v_flow_sid IS NULL AND NOT AreAllAuditsInTrash(in_internal_audit_type_id) THEN
            SELECT flow_sid
              INTO v_flow_sid
              FROM internal_audit_type
             WHERE internal_audit_type_id = in_internal_audit_type_id;
        END IF;

        UPDATE internal_audit_type
           SET label = in_label,
                every_n_months = in_every_n_months,
                auditor_role_sid = in_auditor_role_sid,
                audit_contact_role_sid = in_audit_contact_role_sid,
                default_survey_sid = in_default_survey_sid,
                default_auditor_org = in_default_auditor_org,
                override_issue_dtm = in_override_issue_dtm,
                assign_issues_to_role = in_assign_issues_to_role,
                involve_auditor_in_issues = in_involve_auditor_in_issues,
                auditor_can_take_ownership = in_auditor_can_take_ownership,
                add_nc_per_question = in_add_nc_per_question,
                nc_audit_child_region = in_nc_audit_child_region,
                flow_sid = v_flow_sid,
                internal_audit_type_source_id = in_internal_audit_source_id,
                summary_survey_sid = in_summary_survey_sid,
                audit_coord_role_or_group_sid = in_audit_c_role_or_group_sid,
                send_auditor_expiry_alerts = in_send_auditor_expiry_alerts,
                validity_months = in_validity_months,
                tab_sid = in_tab_sid,
                form_path = in_form_path,
                form_sid = in_form_sid,
                internal_audit_type_group_id = in_ia_type_group_id,
                nc_score_type_id = in_nc_score_type_id,
                active = in_active,
                show_primary_survey_in_header = v_show_primary_survey_in_hdr,
                use_legacy_closed_definition = in_use_legacy_closed_def
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND app_sid = security_pkg.GetApp;

        IF null_pkg.ne(in_nc_score_type_id, v_old_nc_score_type_id) THEN
            IF in_nc_score_type_id IS NOT NULL THEN
                FOR r IN (
                    SELECT internal_audit_sid
                      FROM internal_audit
                     WHERE internal_audit_type_id = in_internal_audit_type_id
                ) LOOP
                    RecalculateAuditNCScore(r.internal_audit_sid);
                END LOOP;
            ELSE
                UPDATE internal_audit
                   SET nc_score = NULL
                 WHERE internal_audit_type_id = in_internal_audit_type_id;
            END IF;
        END IF;

        IF in_override_issue_dtm != v_old_override_issue_dtm THEN
            TriggerAuditAgg; -- Trigger for all dates as this change will affect returned data
        END IF;

    END IF;

    DELETE FROM audit_type_expiry_alert_role
     WHERE internal_audit_type_id = v_internal_audit_type_id;

    INSERT INTO audit_type_expiry_alert_role (internal_audit_type_id, role_sid)
    SELECT v_internal_audit_type_id, column_value
      FROM TABLE(v_expiry_alert_roles);
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
    );
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
    );
    
    OPEN out_cur FOR
        SELECT internal_audit_type_id, label, every_n_months,
                auditor_role_sid, audit_contact_role_sid,
                default_survey_sid, default_auditor_org, override_issue_dtm,
                assign_issues_to_role, add_nc_per_question, nc_audit_child_region, flow_sid, internal_audit_type_source_id, summary_survey_sid,
                send_auditor_expiry_alerts, tab_sid, form_path, audit_coord_role_or_group_sid, form_sid,
                involve_auditor_in_issues
          FROM internal_audit_type
         WHERE app_sid = security_pkg.GetApp
           AND internal_audit_type_id = v_internal_audit_type_id;
END;

PROCEDURE GetTemplate(
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    in_internal_audit_type_rep_id     IN internal_audit_type_report.internal_audit_type_report_id%TYPE,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    -- No security - anyone can get the template

    OPEN out_cur FOR
        SELECT internal_audit_type_id, report_filename, word_doc, label, ia_type_report_group_id
          FROM internal_audit_type_report
         WHERE app_sid = security_pkg.GetApp
           AND internal_audit_type_id = in_internal_audit_type_id
           AND internal_audit_type_report_id = in_internal_audit_type_rep_id;
END;

-- Put this in csr.audit_pkg because it has to return null if not exists
PROCEDURE GetIndSidByLookupKey (
    in_lookup_key                IN    ind.lookup_key%TYPE,
    out_ind_sid                    OUT    ind.ind_sid%TYPE
) AS
BEGIN
    SELECT ind_sid
      INTO out_ind_sid
      FROM ind
     WHERE lookup_key = in_lookup_key;
EXCEPTION
    WHEN no_data_found THEN
        out_ind_sid := NULL;
    WHEN too_many_rows THEN
        RAISE_APPLICATION_ERROR(-20001, 'Too many matches for an indicator of lookup key: '||in_lookup_key);
END;

PROCEDURE GetOrCreateInd (
    in_parent_sid_id        IN    ind.parent_sid%TYPE,
    in_name                    IN    ind.name%TYPE,
    in_description            IN    ind_description.description%TYPE,
    in_lookup_key            IN    ind.lookup_key%TYPE,
    in_ind_type                IN    ind.ind_type%TYPE DEFAULT 0,
    in_measure_sid            IN    ind.measure_sid%TYPE DEFAULT NULL,
    in_divisibility            IN    ind.divisibility%TYPE DEFAULT NULL,
    in_aggregate            IN    ind.aggregate%TYPE DEFAULT 'NONE',
    out_sid_id                OUT    ind.ind_sid%TYPE
) AS
    v_ind_sid                    ind.ind_sid%TYPE;
BEGIN
    GetIndSidByLookupKey(in_lookup_key, v_ind_sid);

    IF v_ind_sid IS NULL THEN
        indicator_pkg.CreateIndicator(
            in_parent_sid_id         => in_parent_sid_id,
            in_name                 => SUBSTR(REPLACE(in_name, '/', '\'),1,255), --' this comment is for Notepad++ users
            in_lookup_key            => in_lookup_key,
            in_description             => SUBSTR(in_description,1,1000),
            in_active                 => 1,
            in_ind_type                => in_ind_type,
            in_measure_sid            => in_measure_sid,
            in_divisibility            => in_divisibility,
            in_aggregate            => in_aggregate,
            in_is_system_managed    => 1,
            out_sid_id                => v_ind_sid
        );
    ELSE
        indicator_pkg.EnableIndicator(
            in_ind_sid                => v_ind_sid
        );
        indicator_pkg.MoveIndicator(
            in_act_id                => SYS_CONTEXT('SECURITY', 'ACT'),
            in_ind_sid                => v_ind_sid,
            in_parent_sid_id         => in_parent_sid_id
        );
    END IF;

    out_sid_id := v_ind_sid;
END;

PROCEDURE GetOrCreateAggregateInd (
    in_parent                IN    ind.parent_sid%TYPE,
    in_name                    IN    ind.name%TYPE,
    in_desc                    IN    ind_description.description%TYPE,
    in_lookup_key            IN    ind.lookup_key%TYPE,
    in_divisibility            IN    ind.divisibility%TYPE,
    in_measure_sid            IN    ind.measure_sid%TYPE,
    in_info_definition        IN  VARCHAR2,
    out_ind_sid                OUT    ind.ind_sid%TYPE
) AS
    v_ind_sid                    ind.ind_sid%TYPE;
    v_aggregate_ind_group_id    aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
    BEGIN
        SELECT aggregate_ind_group_id
          INTO v_aggregate_ind_group_id
          FROM aggregate_ind_group
         WHERE name='InternalAudit'
           AND app_sid = security_pkg.GetApp; -- Make sure we're logged into an app (this is likely to be called from sqlplus)
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO aggregate_ind_group (aggregate_ind_group_id, name, label, helper_proc)
            VALUES (aggregate_ind_group_id_seq.NEXTVAL, 'InternalAudit', 'InternalAudit', 'csr.audit_pkg.GetIndicatorValues')
            RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;

            --issue_pkg.RegisterAggregateIndGroup(csr_data_pkg.ISSUE_NON_COMPLIANCE, v_aggregate_ind_group_id);
    END;

    GetOrCreateInd(
        in_parent_sid_id         => in_parent,
        in_name                 => SUBSTR(REPLACE(in_name, '/', '\'),1,255), --' this comment is for Notepad++ users
        in_lookup_key            => in_lookup_key,
        in_description             => SUBSTR(in_desc,1,1000),
        in_divisibility            => in_divisibility,
        in_aggregate            => 'SUM',
        in_measure_sid            => in_measure_sid,
        in_ind_type                => csr_data_pkg.IND_TYPE_AGGREGATE,
        out_sid_id                => v_ind_sid
    );

    BEGIN
        INSERT INTO aggregate_ind_group_member(aggregate_ind_group_id, ind_sid)
        VALUES (v_aggregate_ind_group_id, v_ind_sid);
    EXCEPTION
        WHEN dup_val_on_index THEN
            NULL;
    END;

    IF in_info_definition IS NOT NULL THEN
        indicator_pkg.SetExtraInfoValue(security_pkg.getACT, v_ind_sid, 'definition', in_info_definition);
    END IF;

    calc_pkg.AddJobsForAggregateIndGroup(v_aggregate_ind_group_id);

    out_ind_sid := v_ind_sid;
END;

PROCEDURE CreateFlowIndicators(
    in_audit_type_id            internal_audit_type.internal_audit_type_id%TYPE,
    in_lookup_key                internal_audit_type.lookup_key%TYPE,
    in_count_measure_sid        security_pkg.T_SID_ID,
    in_audit_type_ind_sid        security_pkg.T_SID_ID
) AS
    v_ind_sid                    security_pkg.T_SID_ID;
    v_flow_sid                    security_pkg.T_SID_ID;
    v_flow_state_audit_ind_sid        security_pkg.T_SID_ID;
    v_flow_state_time_ind_sid    security_pkg.T_SID_ID;
    v_minutes_measure            security_pkg.T_SID_ID;
BEGIN
    SELECT flow_sid
      INTO v_flow_sid
      FROM internal_audit_type
     WHERE internal_audit_type_id = in_audit_type_id;

    IF v_flow_sid IS NULL THEN
        RETURN;
    END IF;

    GetOrCreateInd(
        in_parent_sid_id         => in_audit_type_ind_sid,
        in_name                 => 'workflow_state_container',
        in_lookup_key            => in_lookup_key||'_STATE',
        in_description             => 'Workflow state',
        out_sid_id                => v_flow_state_audit_ind_sid
    );

    GetOrCreateInd(
        in_parent_sid_id         => in_audit_type_ind_sid,
        in_name                 => 'Workflow timings',
        in_lookup_key            => in_lookup_key||'_STATE_TIME',
        in_description             => 'Indicators measuring time spent in different audit states',
        out_sid_id                => v_flow_state_time_ind_sid
    );

    IF v_minutes_measure IS NULL THEN
        -- either find a measure called 'Time', or create a new one
        BEGIN
            SELECT measure_sid
              INTO v_minutes_measure
              FROM measure
             WHERE name = 'Time'
               AND app_sid = security_pkg.GetApp;
        EXCEPTION
            WHEN no_data_found THEN
                measure_pkg.CreateMeasure(
                    in_name                    => 'Time',
                    in_description            => 'Time measured in minutes',
                    in_divisibility            => csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
                    out_measure_sid            => v_minutes_measure
                );
        END;
    END IF;


    FOR r IN (
        SELECT fs.label, fs.lookup_key, fs.flow_state_id, fs.flow_sid,
               GetAuditFlowStateIndName(fs.flow_state_id, audit_pkg.IND_TYPE_FLOW_STATE_COUNT) ind_name
          FROM flow_state fs
          JOIN internal_audit_type iat
            ON fs.flow_sid = iat.flow_sid
     LEFT JOIN flow_state_audit_ind fsi
            ON fsi.flow_state_id = fs.flow_state_id
           AND fsi.internal_audit_type_id = iat.internal_audit_type_id
           AND flow_state_audit_ind_type_id = audit_pkg.IND_TYPE_FLOW_STATE_COUNT
         WHERE fs.is_deleted = 0
           AND fsi.ind_sid IS NULL
           AND iat.internal_audit_type_id = in_audit_type_id
         ORDER BY fs.pos
    ) LOOP

        GetOrCreateAggregateInd(v_flow_state_audit_ind_sid, r.ind_name, r.ind_name, in_lookup_key||'_STATE_'||r.lookup_key,
            csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_count_measure_sid, null, v_ind_sid);

        SetAuditFlowStateInd(r.flow_state_id, v_ind_sid, audit_pkg.IND_TYPE_FLOW_STATE_COUNT, in_audit_type_id);

    END LOOP;

    FOR r IN (
        SELECT fs.label, fs.lookup_key, fs.flow_state_id, fs.flow_sid,
               GetAuditFlowStateIndName(fs.flow_state_id, audit_pkg.IND_TYPE_FLOW_STATE_TIME) ind_name
          FROM flow_state fs
          JOIN internal_audit_type iat
            ON fs.flow_sid = iat.flow_sid
     LEFT JOIN flow_state_audit_ind fsi
            ON fsi.flow_state_id = fs.flow_state_id
           AND fsi.internal_audit_type_id = iat.internal_audit_type_id
           AND flow_state_audit_ind_type_id = audit_pkg.IND_TYPE_FLOW_STATE_TIME
         WHERE fs.is_deleted = 0
           AND fsi.ind_sid IS NULL
           AND iat.internal_audit_type_id = in_audit_type_id
         ORDER BY fs.pos
    ) LOOP

        GetOrCreateAggregateInd(v_flow_state_time_ind_sid, r.ind_name, r.ind_name, in_lookup_key||'_STATE_TIME_'||r.lookup_key,
            csr_data_pkg.DIVISIBILITY_LAST_PERIOD, v_minutes_measure, null, v_ind_sid);

        SetAuditFlowStateInd(r.flow_state_id, v_ind_sid, audit_pkg.IND_TYPE_FLOW_STATE_TIME, in_audit_type_id);
    END LOOP;
END;

-- private
PROCEDURE CreateIssuesIndTree (
    in_audit_type_ind_sid        IN    security.security_pkg.T_SID_ID,
    in_lookup_key                IN    ind.lookup_key%TYPE,
    in_description                 IN    ind_description.description%TYPE,
    in_measure_sid                IN    security.security_pkg.T_SID_ID,
    in_ia_issue_label            IN    csr.issue_type.label%TYPE
)
AS
    v_nctype_ind_sid            security.security_pkg.T_SID_ID;
    v_actions_ind_sid            security.security_pkg.T_SID_ID;
    v_ncs_ind_sid                security.security_pkg.T_SID_ID;
    v_ncs_open_ind_sid            security.security_pkg.T_SID_ID;
    v_ncs_closed_ind_sid        security.security_pkg.T_SID_ID;
    v_iso_ind_sid                security.security_pkg.T_SID_ID;
    v_isod_ind_sid                security.security_pkg.T_SID_ID;
    v_isr_ind_sid                security.security_pkg.T_SID_ID;
    v_isco_ind_sid                security.security_pkg.T_SID_ID;
    v_iscl_ind_sid                security.security_pkg.T_SID_ID;
    v_isc_ind_sid                security.security_pkg.T_SID_ID;
    v_isc_u30_ind_sid            security.security_pkg.T_SID_ID;
    v_isc_u60_ind_sid            security.security_pkg.T_SID_ID;
    v_isc_u90_ind_sid            security.security_pkg.T_SID_ID;
    v_isc_o90_ind_sid            security.security_pkg.T_SID_ID;
    v_iso_nod_ind_sid            security.security_pkg.T_SID_ID;
    v_iso_u30_ind_sid            security.security_pkg.T_SID_ID;
    v_iso_u60_ind_sid            security.security_pkg.T_SID_ID;
    v_iso_u90_ind_sid            security.security_pkg.T_SID_ID;
    v_iso_o90_ind_sid            security.security_pkg.T_SID_ID;
    v_iso_o6m_ind_sid            security.security_pkg.T_SID_ID;
    v_is_rej_ind_sid            security.security_pkg.T_SID_ID;
    v_total_days_ind_sid        security.security_pkg.T_SID_ID;
    v_total_od_days_ind_sid        security.security_pkg.T_SID_ID;
    v_avg_days_ind_sid            security.security_pkg.T_SID_ID;
    v_avg_od_days_ind_sid        security.security_pkg.T_SID_ID;
    v_tag_group_ind_sid            security.security_pkg.T_SID_ID;
    v_priority_count            NUMBER;
    v_priority_group_ind_sid    security.security_pkg.T_SID_ID;
    v_ind_sid                    security.security_pkg.T_SID_ID;
    v_description                 ind_description.description%TYPE;
BEGIN
    v_description := NVL(in_description, 'Findings - No type specified');

    GetOrCreateInd(
        in_parent_sid_id         => in_audit_type_ind_sid,
        in_name                 => 'nc_type_'||LOWER(in_lookup_key),
        in_lookup_key            => in_lookup_key||'_NCTYPE',
        in_description             => v_description,
        out_sid_id                => v_nctype_ind_sid
    );

    -- indicator for no of NCs in closed state
    GetOrCreateAggregateInd(v_nctype_ind_sid, 'ncs_closed', 'Closed '||in_description||' findings', in_lookup_key||'_NCS_CLOSED', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_ncs_closed_ind_sid);

    -- indicator for no of NCs in open state
    GetOrCreateAggregateInd(v_nctype_ind_sid, 'ncs_open', 'Open '||in_description||' findings', in_lookup_key||'_NCS_OPEN', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_ncs_open_ind_sid);

    -- indicator for total no of NCs
    GetOrCreateAggregateInd(v_nctype_ind_sid, 'ncs_total', 'Total '||in_description||' findings', in_lookup_key||'_NCS', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_ncs_ind_sid);

    -- create the Actions folder
    GetOrCreateInd(
        in_parent_sid_id         => v_nctype_ind_sid,
        in_name                 => 'nc_type_action_'||LOWER(in_lookup_key),
        in_lookup_key            => in_lookup_key||'_ACTION',
        in_description             => 'Actions',
        out_sid_id                => v_actions_ind_sid
    );

    -- average days old when actions closed
    GetOrCreateInd(
        in_parent_sid_id         => v_actions_ind_sid,
        in_name                 => 'avg_days_calc_'||LOWER(in_lookup_key),
        in_lookup_key            => in_lookup_key||'_ISS_AVG_DAYS',
        in_description             => 'Average days old when '||in_description||' actions closed',
        in_measure_sid            => in_measure_sid,
        out_sid_id                => v_avg_days_ind_sid
    );

    GetOrCreateAggregateInd(v_avg_days_ind_sid, 'total_days', 'Total days old '||in_description||' actions closed', in_lookup_key||'_ISS_TOTAL_DAYS', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_total_days_ind_sid);

    -- average days overdue when actions closed
    GetOrCreateInd(
        in_parent_sid_id         => v_actions_ind_sid,
        in_name                 => 'avg_days_od_calc_'||LOWER(in_lookup_key),
        in_lookup_key            => in_lookup_key||'_ISS_AVG_OD_DAYS',
        in_description             => 'Average days overdue when '||in_description||' actions closed',
        in_measure_sid            => in_measure_sid,
        out_sid_id                => v_avg_od_days_ind_sid
    );

    GetOrCreateAggregateInd(v_avg_od_days_ind_sid, 'total_overdue_days', 'Total days overdue '||in_description||' actions closed', in_lookup_key||'_ISS_TOTAL_OD_DAYS', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_total_od_days_ind_sid);

    -- Closed actions
    GetOrCreateAggregateInd(v_actions_ind_sid, 'closed_issues', 'Closed '||in_description||' actions', in_lookup_key||'_ISS_CLOSED', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, 'This is a cumulative count of all closed audit actions, whether overdue or not.', v_isc_ind_sid);
    GetOrCreateAggregateInd(v_isc_ind_sid, 'closed_late_issues_u60', 'Closed '||in_description||' actions (between 30 and 60 days after due date)', in_lookup_key||'_ISS_CLOSED_OD_U60', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.', v_isc_u60_ind_sid);
    GetOrCreateAggregateInd(v_isc_ind_sid, 'closed_late_issues_u90', 'Closed '||in_description||' actions (between 60 and 90 days after due date)', in_lookup_key||'_ISS_CLOSED_OD_U90', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.', v_isc_u90_ind_sid);
    GetOrCreateAggregateInd(v_isc_ind_sid, 'closed_late_issues', 'Closed '||in_description||' actions (late)', in_lookup_key||'_ISS_CLOSED_OD', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.', v_iscl_ind_sid);
    GetOrCreateAggregateInd(v_isc_ind_sid, 'closed_late_issues_o90', 'Closed '||in_description||' actions (more than 90 days after due date)', in_lookup_key||'_ISS_CLOSED_OD_O90', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.', v_isc_o90_ind_sid);
    GetOrCreateAggregateInd(v_isc_ind_sid, 'closed_on_time_issues', 'Closed '||in_description||' actions (on time)', in_lookup_key||'_ISS_CLOSED_OT', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.', v_isco_ind_sid);
    GetOrCreateAggregateInd(v_isc_ind_sid, 'closed_late_issues_u30', 'Closed '||in_description||' actions (within 30 days after due date)', in_lookup_key||'_ISS_CLOSED_OD_U30', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved within the period selected.  It would be sensible to set a YTD calculation to count the number resolved so far this year.  These indicators are broken down according to their resolution date compared to due date.', v_isc_u30_ind_sid);

    -- Open and overdue actions
    GetOrCreateAggregateInd(v_actions_ind_sid, 'open_issues', 'Open '||in_description||' actions', in_lookup_key||'_ISS_OPEN', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, 'This is a cumulative count of all open audit actions, whether overdue or not.  E.g. if an audit action has not been resolved from 2012 it will roll forward to 2013 so this number always shows how many audit actions are un-resolved (open).  Since these indicators are cumulative, you cannot add the monthly values to get an annual total. You should not set a YTD calculation using this indicator.', v_iso_ind_sid);
    GetOrCreateAggregateInd(v_iso_ind_sid, 'open_issues_not_overdue', 'Open (not overdue) '||in_description||' actions', in_lookup_key||'_ISS_OPEN_NOD', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, null, v_iso_nod_ind_sid);
    GetOrCreateAggregateInd(v_iso_ind_sid, 'overdue_issues', 'Overdue '||in_description||' actions', in_lookup_key||'_ISS_OVER', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, 'This is a cumulative count of all audit actions that are open and overdue.  The same rules apply as with Open audit actions, it will show a cumulative total so you cannot add the monthly values to get the annual total. You also should not do a YTD action on this indicator.', v_isod_ind_sid);
    GetOrCreateAggregateInd(v_isod_ind_sid, 'open_late_issues_u30', 'Open (overdue) '||in_description||' actions (within 30 days after due date)', in_lookup_key||'_ISS_OPEN_OD_U30', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, null, v_iso_u30_ind_sid);
    GetOrCreateAggregateInd(v_isod_ind_sid, 'open_late_issues_u60', 'Open (overdue) '||in_description||' actions (between 30 and 60 days after due date)', in_lookup_key||'_ISS_OPEN_OD_U60', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, null, v_iso_u60_ind_sid);
    GetOrCreateAggregateInd(v_isod_ind_sid, 'open_late_issues_u90', 'Open (overdue) '||in_description||' actions (between 60 and 90 days after due date)', in_lookup_key||'_ISS_OPEN_OD_U90', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, null, v_iso_u90_ind_sid);
    GetOrCreateAggregateInd(v_isod_ind_sid, 'open_late_issues_o90', 'Open (overdue) '||in_description||' actions (more than 90 days after due date)', in_lookup_key||'_ISS_OPEN_OD_O90', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, null, v_iso_o90_ind_sid);
    GetOrCreateAggregateInd(v_isod_ind_sid, 'open_late_issues_o6m', 'Open (overdue) '||in_description||' actions (more than 6 months after due date)', in_lookup_key||'_ISS_OPEN_OD_O6M', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, null, v_iso_o6m_ind_sid);

    -- raised actions
    GetOrCreateAggregateInd(v_actions_ind_sid, 'raised_issues', 'Raised '||in_description||' actions', in_lookup_key||'_ISS_RAISED', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'Counts the number of audit actions raised in the selected reporting period. It takes into consideration when the record was created.  This is not a running total of audits raised to date - to get this you should create a YTD calculation.', v_isr_ind_sid);
    GetOrCreateAggregateInd(v_actions_ind_sid, 'rejected_issues', 'Rejected '||in_description||' actions', in_lookup_key||'_ISS_REJECTED', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_is_rej_ind_sid);

    -- Set calculation for average days old when closed
    -- TODO: 13p fix needed
    calc_pkg.SetCalcXMLAndDeps(
        in_act_id => security_pkg.GetAct,
        in_calc_ind_sid => v_avg_days_ind_sid,
        in_calc_xml => '<divide><left><path sid="'||v_total_days_ind_sid||'" description="Total days old issues were when closed" /></left><right><add><left><path sid="'||v_isco_ind_sid||'" description="Closed '||in_ia_issue_label||'s (on time)" /></left><right><path sid="'||v_iscl_ind_sid||'" description="Closed '||in_ia_issue_label||'s (late)" /></right></add></right></divide>',
        in_is_stored => 0,
        in_period_set_id => 1,
        in_period_interval_id => 1,
        in_do_temporal_aggregation => 1,
        in_calc_description => 'System calculation'
    );

    -- Set calculation for average days overdue when closed
    calc_pkg.SetCalcXMLAndDeps(
        in_act_id => security_pkg.GetAct,
        in_calc_ind_sid => v_avg_od_days_ind_sid,
        in_calc_xml => '<divide><left><path sid="'||v_total_od_days_ind_sid||'" description="Total days overdue issues were when closed" /></left><right><path sid="'||v_iscl_ind_sid||'" description="Closed '||in_ia_issue_label||'s (late)" /></right></divide>',
        in_is_stored => 0,
        in_period_set_id => 1,
        in_period_interval_id => 1,
        in_do_temporal_aggregation => 1,
        in_calc_description => 'System calculation'
    );

    -- issues raised by tag
    FOR r IN (
        SELECT t.tag, t.tag_id, t.lookup_key, tg.name tag_group_name
          FROM v$tag t
          JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
          JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id
          LEFT JOIN ind i ON i.lookup_key = in_lookup_key||'_TAG_'||t.lookup_key
         WHERE t.lookup_key IS NOT NULL
           AND tg.applies_to_non_compliances = 1
           AND i.ind_sid IS NULL
    ) LOOP
        BEGIN
            SELECT ind_sid
              INTO v_tag_group_ind_sid
              FROM ind
             WHERE parent_sid = v_ncs_ind_sid
               AND name = SUBSTR(REPLACE(r.tag_group_name, '/', '\'),1,255); --' this comment is for Notepad++ users

            indicator_pkg.EnableIndicator(
                in_ind_sid => v_tag_group_ind_sid
            );
        EXCEPTION
            WHEN no_data_found THEN
                indicator_pkg.CreateIndicator(
                    in_parent_sid_id         => v_ncs_ind_sid,
                    in_name                 => SUBSTR(REPLACE(r.tag_group_name, '/', '\'),1,255), --' this comment is for Notepad++ users
                    in_description             => SUBSTR('By ' || r.tag_group_name,1,1000),
                    in_active                 => 1,
                    out_sid_id                => v_tag_group_ind_sid
                );
        END;

        GetOrCreateAggregateInd(v_tag_group_ind_sid, r.tag, r.tag, in_lookup_key||'_TAG_'||r.lookup_key, csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_ind_sid);
    END LOOP;

    -- issues raised by priority
    BEGIN
        SELECT count(*)
          INTO v_priority_count
          FROM issue_priority;
    EXCEPTION
        WHEN no_data_found THEN
            v_priority_count := NULL;
    END;

    IF v_priority_count > 0 THEN
        BEGIN
            SELECT ind_sid
              INTO v_priority_group_ind_sid
              FROM ind
             WHERE parent_sid = v_isr_ind_sid
               AND name = 'issues_raise_by_priority';

            indicator_pkg.EnableIndicator(
                in_ind_sid => v_priority_group_ind_sid
            );
        EXCEPTION
            WHEN no_data_found THEN
                indicator_pkg.CreateIndicator(
                    in_parent_sid_id         => v_isr_ind_sid,
                    in_name                 => 'issues_raise_by_priority',
                    in_description             => 'By priority',
                    in_active                 => 1,
                    out_sid_id                => v_priority_group_ind_sid
                );
        END;

        FOR r IN (
            SELECT p.issue_priority_id, p.description
              FROM issue_priority p
              LEFT JOIN ind i ON i.lookup_key = in_lookup_key||'_ISS_PRI_'||p.issue_priority_id
             WHERE i.ind_sid IS NULL
        ) LOOP
            GetOrCreateAggregateInd(v_priority_group_ind_sid, 'issues_raise_by_priority_'||r.issue_priority_id, r.description, in_lookup_key||'_ISS_PRI_'||r.issue_priority_id, csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_ind_sid);
        END LOOP;
    END IF;
END;

PROCEDURE CreateMappedIndicators (
    in_audit_type_id            internal_audit_type.internal_audit_type_id%TYPE,
    in_lookup_key                internal_audit_type.lookup_key%TYPE,
    in_folder_ind_sid            security_pkg.T_SID_ID,
    in_measure_sid                security_pkg.T_SID_ID
) AS
    v_type_name                    internal_audit_type.label%TYPE;
    v_ia_issue_label            csr.issue_type.label%TYPE;
    v_audit_type_ind_sid        security.security_pkg.T_SID_ID;
    v_pln_ind_sid                security.security_pkg.T_SID_ID;
    v_cmp_ind_sid                security.security_pkg.T_SID_ID;
    v_opn_ind_sid                security.security_pkg.T_SID_ID;
    v_flow_state_audit_ind_sid        security.security_pkg.T_SID_ID;

    v_results_ind_sid            security.security_pkg.T_SID_ID;
    v_result_ind_description    ind_description.description%TYPE;
    v_result_ind_sid            security.security_pkg.T_SID_ID;
    v_results_count                NUMBER;

    v_issue_type_id                csr.issue_type.issue_type_id%TYPE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can map these indicators');
    END IF;

    SELECT iat.label, iatg.issue_type_id
      INTO v_type_name, v_issue_type_id
      FROM internal_audit_type iat
      LEFT JOIN internal_audit_type_group iatg ON iat.internal_audit_type_group_id = iatg.internal_audit_type_group_id AND iat.app_sid = iatg.app_sid
     WHERE internal_audit_type_id = in_audit_type_id;

    IF v_issue_type_id IS NULL THEN
        v_issue_type_id := csr_data_pkg.ISSUE_NON_COMPLIANCE;
    END IF;

    SELECT LOWER(label)
      INTO v_ia_issue_label
      FROM issue_type
     WHERE issue_type_id = v_issue_type_id;

    UPDATE internal_audit_type
       SET lookup_key = in_lookup_key
     WHERE internal_audit_type_id = in_audit_type_id;

    -- Create a folder for this
    GetOrCreateInd(
        in_parent_sid_id         => in_folder_ind_sid,
        in_name                 => v_type_name,
        in_lookup_key            => in_lookup_key||'_CONTAINER',
        in_description             => v_type_name,
        out_sid_id                => v_audit_type_ind_sid
    );

    GetOrCreateAggregateInd(v_audit_type_ind_sid, 'audits_planned', 'Audits planned', in_lookup_key||'_PLN', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'The number of audits created for that month. If you pull this indicator annually for the current year, it will give you the number of audits held for that year so far.  You create an audit (normally with a survey) ahead of time when the audit is booked/organised - this is why the indicator is called "planned audits". When the audit occurs the survey would normally be submitted and is therefore "audit completed".  If an audit doesn''t have a survey then "audits planned" is the closest equivalent to the number of audits carried out.', v_pln_ind_sid);
    GetOrCreateAggregateInd(v_audit_type_ind_sid, 'audits_completed', 'Audits completed', in_lookup_key||'_CMP', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, 'Count of audits that have a survey submitted (in order to submit a survey you have to choose an option for the "Question set" field when raising an audit)', v_cmp_ind_sid);
    GetOrCreateAggregateInd(v_audit_type_ind_sid, 'audits_open', 'Audits with open actions', in_lookup_key||'_OPN', csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_opn_ind_sid);

    -- create indicators for the issues where no issue type is specified (legacy behaviour)
    CreateIssuesIndTree(v_audit_type_ind_sid, in_lookup_key, NULL, in_measure_sid, v_ia_issue_label);

    -- create indicators for the issues with an issue type (for each issue type a set of indicators will be created)
    FOR r IN (
        SELECT nct.label, nct.lookup_key, nct.non_compliance_type_id
          FROM csr.non_compliance_type nct
          JOIN csr.non_comp_type_audit_type nctat ON nctat.non_compliance_type_id = nct.non_compliance_type_id
          JOIN csr.internal_audit_type iat ON iat.internal_audit_type_id = nctat.internal_audit_type_id
          LEFT JOIN csr.ind i ON i.lookup_key = in_lookup_key||'_'||UPPER(nct.lookup_key)
         WHERE nct.lookup_key IS NOT NULL
           AND i.ind_sid IS NULL
           AND iat.internal_audit_type_id = in_audit_type_id
         ORDER BY nct.position
    )
    LOOP
        CreateIssuesIndTree(v_audit_type_ind_sid, in_lookup_key||'_'||r.lookup_key, r.label, in_measure_sid, v_ia_issue_label);
    END LOOP;

    CreateFlowIndicators(in_audit_type_id, in_lookup_key, in_measure_sid, v_audit_type_ind_sid);


    SELECT COUNT(*)
      INTO v_results_count
      FROM audit_type_closure_type atct, audit_closure_type act
     WHERE atct.audit_closure_type_id = act.audit_closure_type_id
       AND atct.internal_audit_type_id = in_audit_type_id;

    IF v_results_count > 0 THEN
        GetOrCreateInd(
            in_parent_sid_id         => v_audit_type_ind_sid,
            in_name                 => 'results',
            in_lookup_key            => in_lookup_key||'_RESULTS',
            in_description             => 'Results (closure types)',
            out_sid_id                => v_results_ind_sid
        );

        FOR x IN (
            SELECT act.label, atct.ind_sid,
                   atct.internal_audit_type_id, atct.audit_closure_type_id
              FROM audit_type_closure_type atct, audit_closure_type act
             WHERE atct.audit_closure_type_id = act.audit_closure_type_id
               AND atct.internal_audit_type_id = in_audit_type_id
        ) LOOP
            v_result_ind_description := 'Audits closed with result '||x.label;

            IF x.ind_sid IS NOT NULL THEN
                v_result_ind_sid := x.ind_sid;
                indicator_pkg.EnableIndicator(
                    in_ind_sid => x.ind_sid
                );
                indicator_pkg.MoveIndicator(
                    in_act_id                => SYS_CONTEXT('SECURITY', 'ACT'),
                    in_ind_sid                => x.ind_sid,
                    in_parent_sid_id         => v_results_ind_sid
                );
            ELSE
                GetOrCreateAggregateInd(v_results_ind_sid, 'result_'||LOWER(x.label)||'_'||x.audit_closure_type_id, v_result_ind_description,
                        in_lookup_key||'_RESULT_'||UPPER(x.label), csr_data_pkg.DIVISIBILITY_DIVISIBLE, in_measure_sid, null, v_result_ind_sid);

                UPDATE audit_type_closure_type
                   SET ind_sid = v_result_ind_sid
                 WHERE audit_closure_type_id = x.audit_closure_type_id
                   AND internal_audit_type_id = x.internal_audit_type_id;
            END IF;

            indicator_pkg.RenameIndicator(v_result_ind_sid, v_result_ind_description);
        END LOOP;

    END IF;

END;

PROCEDURE CreateTotalClosedIndicator (
    in_audit_type_id            internal_audit_type.internal_audit_type_id%TYPE,
    in_lookup_key                internal_audit_type.lookup_key%TYPE,
    in_folder_ind_sid            security_pkg.T_SID_ID,
    in_measure_sid                security_pkg.T_SID_ID
) AS
    v_type_name                    internal_audit_type.label%TYPE;
    v_ia_issue_label            csr.issue_type.label%TYPE;

    v_audit_type_ind_sid        security.security_pkg.T_SID_ID;
    v_tot_clsd_ind_sid            security.security_pkg.T_SID_ID;
    v_tot_rejct_ind_sid            security.security_pkg.T_SID_ID;
    v_ind_sid                    security.security_pkg.T_SID_ID;
    v_issue_type_id                issue_type.issue_type_id%TYPE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can map these indicators');
    END IF;

    SELECT iat.label, iatg.issue_type_id
      INTO v_type_name, v_issue_type_id
      FROM internal_audit_type iat
      LEFT JOIN internal_audit_type_group iatg ON iat.internal_audit_type_group_id = iatg.internal_audit_type_group_id AND iat.app_sid = iatg.app_sid
     WHERE internal_audit_type_id = in_audit_type_id;

    IF v_issue_type_id IS NULL THEN
        v_issue_type_id := csr_data_pkg.ISSUE_NON_COMPLIANCE;
    END IF;

    SELECT LOWER(label)
      INTO v_ia_issue_label
      FROM issue_type
     WHERE issue_type_id = v_issue_type_id;

    UPDATE internal_audit_type
       SET lookup_key = in_lookup_key
     WHERE internal_audit_type_id = in_audit_type_id;

    -- Create a folder for this
    GetOrCreateInd(
        in_parent_sid_id         => in_folder_ind_sid,
        in_name                 => SUBSTR(REPLACE(v_type_name, '/', '\'),1,255), --' this comment is for Notepad++ users
        in_lookup_key            => in_lookup_key||'_CONTAINER',
        in_description             => SUBSTR(v_type_name,1,1000),
        out_sid_id                => v_audit_type_ind_sid
    );

    -- Create an indicator for number of issues closed since the beggining of time
    GetOrCreateAggregateInd(v_audit_type_ind_sid, 'total_closed_issues', 'Closed '||v_ia_issue_label||'s (total to date)', in_lookup_key||'_ISS_TOT_CLOSED', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, 'All the closed audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions resolved up to the end of the period selected.', v_tot_clsd_ind_sid);

    -- Create an indicator for number of issues rejected since the beggining of time
    GetOrCreateAggregateInd(v_audit_type_ind_sid, 'total_rejected_issues', 'Rejected '||v_ia_issue_label||'s (total to date)', in_lookup_key||'_ISS_TOT_REJECT', csr_data_pkg.DIVISIBILITY_LAST_PERIOD, in_measure_sid, 'All the rejected audit action indicators are updated as actions are RESOLVED and are updated each month.  The number returned in the reports will be the number of actions rejected up to the end of the period selected.', v_tot_rejct_ind_sid);
END;

PROCEDURE CreateMappedIndicators (
    in_audit_type_id            IN    internal_audit_type.internal_audit_type_id%TYPE,
    in_include_tot_clsd            IN    NUMBER := 0
)
AS
    v_folder_ind_sid            security_pkg.T_SID_ID;
    v_measure_sid                security_pkg.T_SID_ID;
    v_lookup_key                internal_audit_type.lookup_key%TYPE DEFAULT 'IAT_'||in_audit_type_id||'_A';
    v_root_ind_sid                security_pkg.T_SID_ID;
    v_trash_sid                    security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Trash');
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can map these indicators');
    END IF;

    BEGIN
        SELECT MIN(ci.parent_sid), MIN(i.measure_sid), MIN(iat.lookup_key)
          INTO v_folder_ind_sid, v_measure_sid, v_lookup_key
          FROM internal_audit_type iat
          JOIN ind ci
            ON iat.lookup_key||'_CONTAINER' = ci.lookup_key AND iat.app_sid = ci.app_sid
          JOIN ind i
            ON ci.ind_sid = i.parent_sid AND ci.app_sid = i.app_sid
         WHERE internal_audit_type_id = in_audit_type_id
           AND iat.app_sid = security_pkg.GetApp
         GROUP BY ci.ind_sid;
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END;

    IF v_folder_ind_sid IS NULL OR v_folder_ind_sid = v_trash_sid OR trash_pkg.IsInTrash(security_pkg.GetAct, v_folder_ind_sid) = 1 THEN
        -- create a parent folder for all audit type metrics
        SELECT ind_sid
          INTO v_root_ind_sid
          FROM ind
         WHERE parent_sid = security_pkg.GetApp
           AND app_sid = security_pkg.GetApp;

        BEGIN
            SELECT ind_sid
              INTO v_folder_ind_sid
              FROM ind
             WHERE parent_sid = v_root_ind_sid
               AND LOWER(name) = 'audits'
               AND app_sid = security_pkg.GetApp;
        EXCEPTION
            WHEN no_data_found THEN
                indicator_pkg.CreateIndicator(
                    in_parent_sid_id         => v_root_ind_sid,
                    in_name                 => 'Audits',
                    in_description             => 'Audits',
                    in_active                 => 1,
                    out_sid_id                => v_folder_ind_sid
                );
        END;
    END IF;

    -- make sure the folder is active
    indicator_pkg.EnableIndicator(
        in_ind_sid => v_folder_ind_sid
    );

    IF v_measure_sid IS NULL THEN
        -- either find a measure called '#', or create a new one
        BEGIN
            SELECT measure_sid
              INTO v_measure_sid
              FROM measure
             WHERE name = '#'
               AND app_sid = security_pkg.GetApp;
        EXCEPTION
            WHEN no_data_found THEN
                measure_pkg.CreateMeasure(
                    in_name                    => '#',
                    in_description            => '#',
                    in_divisibility            => csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
                    out_measure_sid            => v_measure_sid
                );
        END;
    END IF;

    CreateMappedIndicators(in_audit_type_id, v_lookup_key, v_folder_ind_sid, v_measure_sid);

    IF in_include_tot_clsd = 1 THEN
        CreateTotalClosedIndicator(in_audit_type_id, v_lookup_key, v_folder_ind_sid, v_measure_sid);
    END IF;
END;

PROCEDURE GetIndicatorValues(
    in_aggregate_ind_group_id    IN    aggregate_ind_group.aggregate_ind_group_id%TYPE,
    in_start_dtm                IN    DATE,
    in_end_dtm                    IN    DATE,
    out_cur                        OUT security_pkg.T_OUTPUT_CUR
) AS
    v_date                        DATE;
    v_sysdate                    DATE := getSysDate;
BEGIN
    IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetIndicatorValues');
    END IF;

    DELETE FROM temp_dates; -- Just in case
    -- Dates are for how many issues were open on that date - we actually want the number open
    -- at the end of each month - so add 1 month to all dates
    v_date := ADD_MONTHS(in_start_dtm, 1);
    WHILE v_date <= ADD_MONTHS(in_end_dtm, 1) AND v_date <= ADD_MONTHS(v_sysdate, 1) LOOP
        -- This is vastly quicker to join to than TABLE OF DATE
        INSERT INTO temp_dates (column_value, eff_date)
        VALUES (v_date, CASE WHEN v_date > v_sysdate THEN v_sysdate ELSE v_date END);
        v_date := ADD_MONTHS(v_date, 1);
    END LOOP;

    DELETE FROM temp_region_tree;

    -- get primary regions and all their children - this is to return
    -- data pre-aggregated up the region_tree (as issues created at mid-levels
    -- would otherwise act as blockers). Secondary tree aggregation works as normal
    INSERT INTO temp_region_tree (root_region_sid, child_region_sid)
    SELECT CONNECT_BY_ROOT region_sid, region_sid
      FROM region
     START WITH region_sid IN (SELECT region_sid FROM region START WITH region_sid IN (SELECT region_tree_root_sid FROM region_tree WHERE is_primary=1) CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid)
    CONNECT BY PRIOR app_sid = app_sid AND prior region_sid = parent_sid;

    DELETE FROM ind_list_2;

    INSERT INTO ind_list_2  (ind_sid)
    SELECT agm.ind_sid
      FROM aggregate_ind_group_member agm, ind_list il
     WHERE il.ind_sid= agm.ind_sid
       AND agm.aggregate_ind_group_id = in_aggregate_ind_group_id;

    DELETE FROM temp_new_val;

    -- Get all audits planned by audit_type and month
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(i, 10000)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_PLN'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get all audits completed broken down by audit_type and month
    -- We define an audit as being completed if the survey has been submitted and use the month the audit was scheduled (not the month the survey was submitted)
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10)
              CARDINALITY(i, 10000) CARDINALITY(sr, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_CMP'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
           AND sr.submitted_dtm IS NOT NULL
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get all audits with open NCs by audit_type and month
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10)
              CARDINALITY(inc, 50000) CARDINALITY(i, 10000)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH') period_start_dtm, COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_OPN'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
           AND EXISTS (
            SELECT NULL
              FROM audit_non_compliance anc
              JOIN non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
              LEFT JOIN issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
              LEFT JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
             WHERE anc.internal_audit_sid = ia.internal_audit_sid
               AND ((nnc.is_closed IS NULL
               AND i.resolved_dtm IS NULL
               AND i.rejected_dtm IS NULL
               AND i.deleted = 0)
                OR nnc.is_closed = 0)
           )
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get total count of non-compliances raised broken down by audit type only
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(i, 10000) CARDINALITY(anc, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH') period_start_dtm, COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_NCS'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND nc.non_compliance_type_id IS NULL
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get total counts of non-compliances raised broken down by audit type and NC type only
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(nct, 10) CARDINALITY(i, 10000) CARDINALITY(anc, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_NCS'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get count of open non-compliances raised broken down by audit type only
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000) CARDINALITY(anc, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          LEFT JOIN issue_non_compliance inc ON nc.non_compliance_id = inc.non_compliance_id
          LEFT JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_NCS_OPEN'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND nc.non_compliance_type_id IS NULL
           AND nc.is_closed IS NULL
           AND iss.resolved_dtm IS NULL
           AND iss.rejected_dtm IS NULL
           AND iss.deleted = 0
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get count of open non-compliances raised broken down by audit type and NC type only
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(nct, 10) CARDINALITY(i, 10000) CARDINALITY(anc, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_NCS_OPEN'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND nc.is_closed = 0
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get count of closed non-compliances raised broken down by audit type only
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000) CARDINALITY(anc, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          LEFT JOIN issue_non_compliance inc ON nc.non_compliance_id = inc.non_compliance_id
          LEFT JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_NCS_CLOSED'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND nc.non_compliance_type_id IS NULL
           AND nc.is_closed IS NULL
           AND iss.resolved_dtm IS NOT NULL
           AND iss.deleted = 0
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');


    -- Get count of closed non-compliances raised broken down by audit type and NC type only
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(nct, 10) CARDINALITY(i, 10000) CARDINALITY(anc, 500)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_NCS_CLOSED'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND nc.is_closed = 1
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get counts of non-compliances raised broken down by audit type
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10)
              CARDINALITY(nct, 10) CARDINALITY(i, 10000) CARDINALITY(anc, 500) CARDINALITY(nct, 100) CARDINALITY(t, 1000)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance_tag nct ON anc.non_compliance_id = nct.non_compliance_id AND anc.app_sid = nct.app_sid
          JOIN tag t ON nct.tag_id = t.tag_id AND nct.app_sid = t.app_sid
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_TAG_'||t.lookup_key
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get counts of non-compliances raised broken down by audit type and non-compliance tag
    -- XXX: Includes non-compliances re-raised
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10)
              CARDINALITY(nctype, 10) CARDINALITY(i, 10000) CARDINALITY(anc, 50000) CARDINALITY(nc, 50000)
              CARDINALITY(nct, 100000) CARDINALITY(t, 1000)*/
               trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_non_compliance anc ON ia.internal_audit_sid = anc.internal_audit_sid AND ia.app_sid = anc.app_sid
          JOIN non_compliance nc ON anc.non_compliance_id = nc.non_compliance_id
          JOIN non_compliance_type nctype ON nc.non_compliance_type_id = nctype.non_compliance_type_id
          JOIN non_compliance_tag nct ON anc.non_compliance_id = nct.non_compliance_id AND anc.app_sid = nct.app_sid
          JOIN tag t ON nct.tag_id = t.tag_id AND nct.app_sid = t.app_sid
              JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nctype.lookup_key||'_TAG_'||t.lookup_key
              JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');

    -- Get counts of issues raised / rejected / closed late / closed on time
    -- XXX: Does not count a Carried Forward Non-Compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT region_sid, ind_sid, TRUNC(issue_dtm, 'MONTH'), COUNT(*)
          FROM (
            SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
                   trt.root_region_sid region_sid, i.ind_sid,
                    CASE WHEN i.lookup_key = iat.lookup_key||'_ISS_RAISED' THEN CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END
                         WHEN i.lookup_key = iat.lookup_key||'_ISS_REJECTED' THEN iss.rejected_dtm
                         WHEN i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OT' THEN NVL(iss.manual_completion_dtm, iss.resolved_dtm)
                         WHEN i.lookup_key = iat.lookup_key||'_ISS_CLOSED' THEN NVL(iss.manual_completion_dtm, iss.resolved_dtm)
                         WHEN i.lookup_key LIKE iat.lookup_key||'_ISS_CLOSED_OD%' THEN NVL(iss.manual_completion_dtm, iss.resolved_dtm) END issue_dtm
              FROM internal_audit ia
              JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
              JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
              JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
              JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
              JOIN ind i ON (i.lookup_key = iat.lookup_key||'_ISS_RAISED' OR i.lookup_key = iat.lookup_key||'_ISS_REJECTED' OR i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OT' OR i.lookup_key LIKE iat.lookup_key||'_ISS_CLOSED_OD%')
              JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
              JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
             WHERE ia.app_sid = security_pkg.GetApp
               AND nc.non_compliance_type_id IS NULL
               AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
               AND ((i.lookup_key = iat.lookup_key||'_ISS_RAISED' AND CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END >= in_start_dtm AND CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END < in_end_dtm)
                OR (i.lookup_key = iat.lookup_key||'_ISS_REJECTED' AND iss.rejected_dtm >= in_start_dtm AND iss.rejected_dtm < in_end_dtm)
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm)
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OT' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND (iss.due_dtm IS NULL OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) <= iss.due_dtm))
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OD' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm)
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OD_U30' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < (iss.due_dtm + 30))
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OD_U60' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= (iss.due_dtm + 30) AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < (iss.due_dtm + 60))
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OD_U90' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= (iss.due_dtm + 60) AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < (iss.due_dtm + 90))
                OR (i.lookup_key = iat.lookup_key||'_ISS_CLOSED_OD_O90' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= (iss.due_dtm + 90)))
            )
         GROUP BY region_sid, ind_sid, TRUNC(issue_dtm, 'MONTH');

    -- Get counts of issues raised / rejected / closed late / closed on time [NC type specific]
    -- XXX: Does not count a Carried Forward Non-Compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT region_sid, ind_sid, TRUNC(issue_dtm, 'MONTH'), COUNT(*)
          FROM (
            SELECT /*+CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(nc, 50000) CARDINALITY(j, 500)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) */
                   trt.root_region_sid region_sid, j.ind_sid,
            CASE WHEN i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_RAISED' THEN CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END
                 WHEN i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_REJECTED' THEN iss.rejected_dtm
                 WHEN i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OT' THEN NVL(iss.manual_completion_dtm, iss.resolved_dtm)
                 WHEN i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED' THEN NVL(iss.manual_completion_dtm, iss.resolved_dtm)
                 WHEN i_lookup_key LIKE iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OD%' THEN NVL(iss.manual_completion_dtm, iss.resolved_dtm) END issue_dtm
              FROM internal_audit ia
              JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
              JOIN (
                SELECT iat.internal_audit_type_id, nct.non_compliance_type_id, i.ind_sid, iat.override_issue_dtm,
                       i.lookup_key i_lookup_key, nct.lookup_key nct_lookup_key, iat.lookup_key iat_lookup_key
                  FROM internal_audit_type iat 
            CROSS JOIN csr.non_compliance_type nct
                  JOIN ind i ON (i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_RAISED' OR i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_REJECTED' OR i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_CLOSED_OT' OR i.lookup_key LIKE iat.lookup_key||'_'||nct.lookup_key||'_ISS_CLOSED_OD%')
                  JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
                 WHERE rownum > 0 -- fully materialise inner query
                ) j ON ia.internal_audit_type_id = j.internal_audit_type_id AND nc.non_compliance_type_id = j.non_compliance_type_id
              JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
              JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
              JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
             WHERE ia.app_sid = security_pkg.GetApp
               AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
               AND ((i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_RAISED' AND CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END >= in_start_dtm AND CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END < in_end_dtm)
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_REJECTED' AND iss.rejected_dtm >= in_start_dtm AND iss.rejected_dtm < in_end_dtm)
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OT' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND (iss.due_dtm IS NULL OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) <= iss.due_dtm))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm)
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OD' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm)
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OD_U30' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < (iss.due_dtm + 30))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OD_U60' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= (iss.due_dtm + 30) AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < (iss.due_dtm + 60))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OD_U90' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= (iss.due_dtm + 60) AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < (iss.due_dtm + 90))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_CLOSED_OD_O90' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= (iss.due_dtm + 90)))
            )
         GROUP BY region_sid, ind_sid, TRUNC(issue_dtm, 'MONTH');

    -- Get counts of open issues per month, starting on issue raised dtm
    -- XXX: Does not count a re-raise non-compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
               trt.root_region_sid, i.ind_sid, ADD_MONTHS(TRUNC(dates.column_value, 'MONTH'), -1) period_start_dtm, COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_ISS_OPEN' OR i.lookup_key = iat.lookup_key||'_ISS_OVER' OR i.lookup_key LIKE iat.lookup_key||'_ISS_OPEN_OD%' OR i.lookup_key LIKE iat.lookup_key||'_ISS_OPEN_NOD'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN temp_dates dates ON -- TODO - Create a table to join to for the config below
                (i.lookup_key = iat.lookup_key||'_ISS_OPEN' AND iss.raised_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_NOD' AND iss.raised_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL) AND (iss.due_dtm IS NULL OR iss.due_dtm > dates.eff_date))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OVER' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_U30' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND iss.due_dtm >= (dates.eff_date - 30) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_U60' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 30) AND iss.due_dtm >= (dates.eff_date - 60) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_U90' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 60) AND iss.due_dtm >= (dates.eff_date - 90)  AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_O90' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 90) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_O6M' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 180) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
         WHERE iat.override_issue_dtm = 0
           AND nc.non_compliance_type_id IS NULL
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(dates.column_value, 'MONTH');

    -- Get counts of open issues per month, starting on issue raised dtm  [NC type specific]
    -- XXX: Does not count a re-raise non-compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(j, 500)*/
               trt.root_region_sid, j.ind_sid, ADD_MONTHS(TRUNC(dates.column_value, 'MONTH'), -1), COUNT(*)
          FROM internal_audit ia
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN (
                SELECT iat.internal_audit_type_id, nct.non_compliance_type_id, i.ind_sid, iat.override_issue_dtm,
                       i.lookup_key i_lookup_key, nct.lookup_key nct_lookup_key, iat.lookup_key iat_lookup_key
                  FROM internal_audit_type iat 
            CROSS JOIN csr.non_compliance_type nct
                  JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_OPEN' OR i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_OVER' OR i.lookup_key LIKE iat.lookup_key||'_'||nct.lookup_key||'_ISS_OPEN_OD%' OR i.lookup_key LIKE iat.lookup_key||'_'||nct.lookup_key||'_ISS_OPEN_NOD'
                  JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
                 WHERE iat.override_issue_dtm = 0
                   AND rownum > 0 -- fully materialise inner query
                ) j ON ia.internal_audit_type_id = j.internal_audit_type_id AND nc.non_compliance_type_id = j.non_compliance_type_id
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN temp_dates dates ON -- TODO - Create a table to join to for the config below
                (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN' AND iss.raised_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_NOD' AND iss.raised_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL) AND (iss.due_dtm IS NULL OR iss.due_dtm > dates.eff_date))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OVER' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_U30' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND iss.due_dtm >= (dates.eff_date - 30) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_U60' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 30) AND iss.due_dtm >= (dates.eff_date - 60) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_U90' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 60) AND iss.due_dtm >= (dates.eff_date - 90)  AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_O90' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 90) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_O6M' AND iss.raised_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 180) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
         WHERE ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, j.ind_sid, TRUNC(dates.column_value, 'MONTH');

    -- Get counts of open issues per month, starting on audit dtm
    -- XXX: Does not count a Carried Forward non-compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
               trt.root_region_sid, i.ind_sid, ADD_MONTHS(TRUNC(dates.column_value, 'MONTH'), -1), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_ISS_OPEN' OR i.lookup_key = iat.lookup_key||'_ISS_OVER' OR i.lookup_key LIKE iat.lookup_key||'_ISS_OPEN_OD%' OR i.lookup_key LIKE iat.lookup_key||'_ISS_OPEN_NOD'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN temp_dates dates ON -- TODO - Create a table to join to for the config below
                (i.lookup_key = iat.lookup_key||'_ISS_OPEN' AND ia.audit_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_NOD' AND ia.audit_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL) AND (iss.due_dtm IS NULL OR iss.due_dtm > dates.eff_date))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OVER' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_U30' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND iss.due_dtm >= (dates.eff_date - 30) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_U60' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 30) AND iss.due_dtm >= (dates.eff_date - 60) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_U90' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 60) AND iss.due_dtm >= (dates.eff_date - 90)  AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_O90' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 90) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i.lookup_key = iat.lookup_key||'_ISS_OPEN_OD_O6M' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 180) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
         WHERE iat.override_issue_dtm = 1
           AND nc.non_compliance_type_id IS NULL
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(dates.column_value, 'MONTH');

    -- Get counts of open issues per month, starting on audit dtm [NC type specific]
    -- XXX: Does not count a Carried Forward non-compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(j, 500)*/
               trt.root_region_sid, j.ind_sid, ADD_MONTHS(TRUNC(dates.column_value, 'MONTH'), -1), COUNT(*)
          FROM internal_audit ia
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN (
            SELECT iat.internal_audit_type_id, nct.non_compliance_type_id, i.ind_sid,
                   i.lookup_key i_lookup_key, nct.lookup_key nct_lookup_key, iat.lookup_key iat_lookup_key
              FROM internal_audit_type iat 
        CROSS JOIN csr.non_compliance_type nct
              JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_OPEN' OR i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_OVER' OR i.lookup_key LIKE iat.lookup_key||'_'||nct.lookup_key||'_ISS_OPEN_OD%' OR i.lookup_key LIKE iat.lookup_key||'_'||nct.lookup_key||'_ISS_OPEN_NOD'
              JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
             WHERE iat.override_issue_dtm = 1
               AND rownum > 0 -- fully materialise inner query
            ) j ON ia.internal_audit_type_id = j.internal_audit_type_id AND nc.non_compliance_type_id = j.non_compliance_type_id
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN temp_dates dates ON -- TODO - Create a table to join to for the config below
                (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN' AND ia.audit_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_NOD' AND ia.audit_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL) AND (iss.due_dtm IS NULL OR iss.due_dtm > dates.eff_date))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OVER' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_U30' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < dates.eff_date AND iss.due_dtm >= (dates.eff_date - 30) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_U60' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 30) AND iss.due_dtm >= (dates.eff_date - 60) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_U90' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 60) AND iss.due_dtm >= (dates.eff_date - 90)  AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_O90' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 90) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_OPEN_OD_O6M' AND ia.audit_dtm < dates.eff_date AND iss.due_dtm < (dates.eff_date - 180) AND (NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= dates.eff_date OR NVL(iss.manual_completion_dtm, iss.resolved_dtm) IS NULL) AND (iss.rejected_dtm >= dates.eff_date OR iss.rejected_dtm IS NULL))
         WHERE ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, j.ind_sid, TRUNC(dates.column_value, 'MONTH');

    -- Get counts of total closed issues from the beggining of time per month
    -- XXX: Does not count a Carried Forward non-compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
               trt.root_region_sid, i.ind_sid, ADD_MONTHS(TRUNC(dates.column_value, 'MONTH'), -1), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN ind i ON i.lookup_key = iat.lookup_key||'_ISS_TOT_CLOSED' OR i.lookup_key = iat.lookup_key||'_ISS_TOT_REJECT'
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN temp_dates dates ON (
                (i.lookup_key = iat.lookup_key||'_ISS_TOT_CLOSED' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < dates.eff_date) OR
                (i.lookup_key = iat.lookup_key||'_ISS_TOT_REJECT' AND iss.rejected_dtm < dates.eff_date))
         WHERE ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
           AND nc.non_compliance_type_id IS NULL
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(dates.column_value, 'MONTH');

    -- Get counts of total closed issues from the beggining of time per month [NC type specific]
    -- XXX: Does not count a Carried Forward non-compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(nc, 50000)
              CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(j, 500)*/
               trt.root_region_sid, j.ind_sid, ADD_MONTHS(TRUNC(dates.column_value, 'MONTH'), -1), COUNT(*)
          FROM internal_audit ia
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN (
            SELECT iat.internal_audit_type_id, nct.non_compliance_type_id, i.ind_sid,
                   i.lookup_key i_lookup_key, nct.lookup_key nct_lookup_key, iat.lookup_key iat_lookup_key
              FROM internal_audit_type iat 
        CROSS JOIN csr.non_compliance_type nct
              JOIN ind i ON i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_TOT_CLOSED' OR i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_TOT_REJECT'
              JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
             WHERE rownum > 0 -- fully materialise inner query
            ) j ON ia.internal_audit_type_id = j.internal_audit_type_id AND nc.non_compliance_type_id = j.non_compliance_type_id
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN temp_dates dates ON (
                (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_TOT_CLOSED' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < dates.eff_date) OR
                (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_TOT_REJECT' AND iss.rejected_dtm < dates.eff_date))
         WHERE ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, j.ind_sid, TRUNC(dates.column_value, 'MONTH');

    -- Gets totals of number of days issues took to ressolve
    -- XXX: Does not count a Carried Forward Non-Compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT region_sid, ind_sid, TRUNC(resolved_dtm, 'MONTH') period_start_dtm, SUM(ROUND(resolved_dtm - measure_from_dtm)) val_number
          FROM (
            SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
                    CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
                   trt.root_region_sid region_sid, i.ind_sid, NVL(iss.manual_completion_dtm, iss.resolved_dtm) resolved_dtm,
                    CASE WHEN i.lookup_key = iat.lookup_key||'_ISS_TOTAL_DAYS' AND iat.override_issue_dtm = 0 THEN iss.raised_dtm
                         WHEN i.lookup_key = iat.lookup_key||'_ISS_TOTAL_DAYS' AND iat.override_issue_dtm = 1 THEN ia.audit_dtm
                         WHEN i.lookup_key = iat.lookup_key||'_ISS_TOTAL_OD_DAYS' THEN iss.due_dtm END measure_from_dtm
              FROM internal_audit ia
              JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
              JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
              JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
              JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
              JOIN ind i ON (i.lookup_key = iat.lookup_key||'_ISS_TOTAL_DAYS' OR i.lookup_key = iat.lookup_key||'_ISS_TOTAL_OD_DAYS')
              JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
              JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
             WHERE ia.app_sid = security_pkg.GetApp
               AND nc.non_compliance_type_id IS NULL
               AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
               AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm
               AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm
               AND ((i.lookup_key = iat.lookup_key||'_ISS_TOTAL_DAYS')
                OR (i.lookup_key = iat.lookup_key||'_ISS_TOTAL_OD_DAYS' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm))
            )
         GROUP BY region_sid, ind_sid, TRUNC(resolved_dtm, 'MONTH');

    -- Gets totals of number of days issues took to ressolve [NC type specific]
    -- XXX: Does not count a Carried Forward Non-Compliance twice
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT region_sid, ind_sid, TRUNC(resolved_dtm, 'MONTH'), SUM(ROUND(resolved_dtm - measure_from_dtm)) val_number
          FROM (
            SELECT /*+CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(nc, 50000)
                    CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(j, 500)*/
                   trt.root_region_sid region_sid, j.ind_sid, NVL(iss.manual_completion_dtm, iss.resolved_dtm) resolved_dtm,
                    CASE WHEN i_lookup_key = iat_lookup_key||'_ISS_TOTAL_DAYS' AND j.override_issue_dtm = 0 THEN iss.raised_dtm
                         WHEN i_lookup_key = iat_lookup_key||'_ISS_TOTAL_DAYS' AND j.override_issue_dtm = 1 THEN ia.audit_dtm
                         WHEN i_lookup_key = iat_lookup_key||'_ISS_TOTAL_OD_DAYS' THEN iss.due_dtm END measure_from_dtm
              FROM internal_audit ia
              JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
              JOIN (
                SELECT iat.internal_audit_type_id, nct.non_compliance_type_id, i.ind_sid, iat.override_issue_dtm,
                       i.lookup_key i_lookup_key, nct.lookup_key nct_lookup_key, iat.lookup_key iat_lookup_key
                  FROM internal_audit_type iat 
            CROSS JOIN csr.non_compliance_type nct
                  JOIN ind i ON (i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_TOTAL_DAYS' OR i.lookup_key = iat.lookup_key||'_'||nct.lookup_key||'_ISS_TOTAL_OD_DAYS')
                  JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
                 WHERE rownum > 0 -- fully materialise inner query
                ) j ON ia.internal_audit_type_id = j.internal_audit_type_id AND nc.non_compliance_type_id = j.non_compliance_type_id
              JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
              JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
              JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
             WHERE ia.app_sid = security_pkg.GetApp
               AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
               AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) >= in_start_dtm
               AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) < in_end_dtm
               AND ((i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_TOTAL_DAYS')
                OR (i_lookup_key = iat_lookup_key||'_'||nct_lookup_key||'_ISS_TOTAL_OD_DAYS' AND NVL(iss.manual_completion_dtm, iss.resolved_dtm) > iss.due_dtm))
            )
         GROUP BY region_sid, ind_sid, TRUNC(resolved_dtm, 'MONTH');

    -- Gets totals of issues raised broken down by priority
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
                CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
               trt.root_region_sid, i.ind_sid,
               TRUNC(CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN ind i ON (i.lookup_key LIKE iat.lookup_key||'_ISS_PRI_'||iss.issue_priority_id)
          JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND nc.non_compliance_type_id IS NULL
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
           AND CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END >= in_start_dtm
           AND CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END < in_end_dtm
         GROUP BY trt.root_region_sid, i.ind_sid, TRUNC(CASE WHEN iat.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END, 'MONTH');

    -- Gets totals of issues raised broken down by priority [NC type specific]
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(nc, 50000)
              CARDINALITY(nct, 10) CARDINALITY(inc, 50000) CARDINALITY(iss, 50000) CARDINALITY(i, 10000)*/
               trt.root_region_sid, j.ind_sid,
               TRUNC(CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END, 'MONTH'), COUNT(*)
          FROM internal_audit ia
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
          JOIN (
            SELECT iat.internal_audit_type_id, nct.non_compliance_type_id, i.ind_sid, iat.override_issue_dtm, ip.issue_priority_id,
                   i.lookup_key i_lookup_key, nct.lookup_key nct_lookup_key, iat.lookup_key iat_lookup_key
              FROM internal_audit_type iat 
        CROSS JOIN csr.non_compliance_type nct
        CROSS JOIN csr.issue_priority ip
              JOIN ind i ON (i.lookup_key LIKE iat.lookup_key||'_'||nct.lookup_key||'_ISS_PRI_'||ip.issue_priority_id)
              JOIN ind_list_2 il ON i.ind_sid = il.ind_sid
             WHERE rownum > 0 -- fully materialise inner query
            ) j ON ia.internal_audit_type_id = j.internal_audit_type_id AND nc.non_compliance_type_id = j.non_compliance_type_id
          JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
          JOIN issue iss ON j.issue_priority_id = iss.issue_priority_id AND inc.issue_non_compliance_id = iss.issue_non_compliance_id AND inc.app_sid = iss.app_sid AND iss.deleted = 0
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
           AND CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END >= in_start_dtm
           AND CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END < in_end_dtm
         GROUP BY trt.root_region_sid, j.ind_sid, TRUNC(CASE WHEN j.override_issue_dtm=0 THEN iss.raised_dtm ELSE ia.audit_dtm END, 'MONTH');

    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(dates, 500) CARDINALITY(ia, 10000) CARDINALITY(iat, 10)
              CARDINALITY(i, 10000) CARDINALITY(fsli, 50000) CARDINALITY(fs, 50) CARDINALITY(fsi, 10)*/
               trt.root_region_sid, il.ind_sid, ADD_MONTHS(TRUNC(fsl.eff_date, 'MONTH'), -1), COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN (
                SELECT flow_item_id, flow_state_id, set_dtm, dates.column_value eff_date,
                       ROW_NUMBER() OVER (PARTITION BY flow_item_id, dates.column_value ORDER BY set_dtm DESC, flow_state_log_id DESC) rn
                  FROM flow_state_log fsli
                  JOIN temp_dates dates ON fsli.set_dtm < dates.eff_date
                ) fsl ON ia.flow_item_id = fsl.flow_item_id
          JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id AND fs.flow_sid = iat.flow_sid
          JOIN flow_state_audit_ind fsi
            ON fsi.flow_state_id = fs.flow_state_id
           AND fsi.internal_audit_type_id = ia.internal_audit_type_id
           AND fsi.flow_state_audit_ind_type_id = audit_pkg.IND_TYPE_FLOW_STATE_COUNT
          JOIN ind_list_2 il ON il.ind_sid = fsi.ind_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
           AND fsl.rn = 1
         GROUP BY trt.root_region_sid, il.ind_sid, TRUNC(fsl.eff_date, 'MONTH');

    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT region_sid, ind_sid, period_start_dtm, AVG(minutes_spent) val_number
          FROM (
             SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(fsi, 10)
                    CARDINALITY(fsli, 50000)*/
                    trt.root_region_sid region_sid, fsi.ind_sid, ia.internal_audit_sid,
                    TRUNC(SUM(a.post_set_dtm - a.set_dtm) * 24 * 60) minutes_spent,
                    ADD_MONTHS(a.period_date, -1) period_start_dtm
               FROM internal_audit ia
               JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
               JOIN flow_state_audit_ind fsi ON ia.internal_audit_type_id = fsi.internal_audit_type_id
               JOIN ind_list_2 il ON il.ind_sid = fsi.ind_sid
               JOIN (
                  SELECT fsl.flow_item_id, fsl.flow_state_id, fsl.set_dtm, NVL(fslpost.set_dtm, td.eff_date) post_set_dtm, td.column_value period_date,
                         ROW_NUMBER() OVER (PARTITION BY fsl.flow_item_id, fsl.set_dtm, fsl.flow_state_id ORDER BY fslpost.set_dtm ASC) rn
                    FROM flow_state_log fsl
                    JOIN csr.temp_dates td ON fsl.set_dtm < td.eff_date
               LEFT JOIN flow_state_log fslpost
                      ON fslpost.flow_item_id = fsl.flow_item_id
                     AND fslpost.set_dtm > fsl.set_dtm
                     AND fslpost.set_dtm < td.eff_date
                ) a
                 ON a.flow_state_id = fsi.flow_state_id
                AND a.flow_item_id = ia.flow_item_id
              WHERE fsi.flow_state_audit_ind_type_id = audit_pkg.IND_TYPE_FLOW_STATE_TIME
                   AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
                AND a.rn = 1
              GROUP BY trt.root_region_sid, fsi.ind_sid, ia.internal_audit_sid, a.period_date
        )
        GROUP BY region_sid, ind_sid, period_start_dtm;

    -- Get all audit closure type counts
    INSERT INTO temp_new_val (region_sid, ind_sid, period_start_dtm, val_number)
        SELECT /*+CARDINALITY(il, 250) CARDINALITY(trt, 40000) CARDINALITY(ia, 10000) CARDINALITY(iat, 10) CARDINALITY(atct, 10)*/
               trt.root_region_sid, atct.ind_sid, TRUNC(ia.audit_dtm, 'MONTH') period_start_dtm, COUNT(*)
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
          JOIN audit_type_closure_type atct ON iat.internal_audit_type_id = atct.internal_audit_type_id AND ia.audit_closure_type_id = atct.audit_closure_type_id
          JOIN temp_region_tree trt ON ia.region_sid = trt.child_region_sid
          JOIN ind_list_2 il ON il.ind_sid = atct.ind_sid
         WHERE ia.app_sid = security_pkg.GetApp
           AND ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
         GROUP BY trt.root_region_sid, atct.ind_sid, TRUNC(ia.audit_dtm, 'MONTH');
    
    OPEN out_cur FOR
        SELECT ind_sid, region_sid, error_code, val_number, period_start_dtm,
               NVL(period_end_dtm, ADD_MONTHS(period_start_dtm, 1)) period_end_dtm, 
               csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id
          FROM temp_new_val
         ORDER BY ind_sid, region_sid, period_start_dtm;
    
END;


FUNCTION GetIssueAuditUrl(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
BEGIN
    RETURN CASE WHEN in_internal_audit_sid IS NULL THEN NULL ELSE '/csr/site/audit/auditDetail.acds?sid='||in_internal_audit_sid END;
END;

FUNCTION GetIssueAuditUrlWithNonCompId(
    in_internal_audit_sid    IN    security_pkg.T_SID_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE
) RETURN VARCHAR2
AS
BEGIN
    RETURN CASE WHEN in_internal_audit_sid IS NULL THEN NULL ELSE '/csr/site/audit/auditDetail.acds?sid='||in_internal_audit_sid||CHR(38)||'noncompid='||in_non_compliance_id END;
END;

PROCEDURE INTERNAL_SetAuditExpired (
    in_internal_audit_sid    IN    security_pkg.T_SID_ID
)
AS
BEGIN
    IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run SetAuditExpired');
    END IF;

    UPDATE internal_audit
       SET expired = 1
     WHERE internal_audit_sid = in_internal_audit_sid;

    INTERNAL_CallHelperPkg('AuditExpired', in_internal_audit_sid);
END;

PROCEDURE TriggerAuditJobs
AS
BEGIN
    user_pkg.LogonAdmin(timeout => 86400);
    -- ensure we've rollforwarded first (the indicator_pkg.RollForward fn with no params excludes sites where we're copying values to new sheets)
    FOR r IN (
        SELECT app_sid, aggregate_ind_group_id
          FROM aggregate_ind_group
         WHERE name = 'InternalAudit'
    ) LOOP
        security_pkg.SetApp(r.app_sid);
        csr.calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id, TRUNC(ADD_MONTHS(SYSDATE, -1), 'MONTH'), TRUNC(ADD_MONTHS(SYSDATE, 1), 'MONTH'));
        security_pkg.SetApp(null);
        COMMIT;
    END LOOP;

    -- processed expired audits
    FOR r IN (
        SELECT ia.app_sid, ia.internal_audit_sid
          FROM csr.internal_audit ia
          JOIN csr.audit_type_closure_type act
            ON ia.audit_closure_type_id = act.audit_closure_type_id
           AND ia.internal_audit_type_id = act.internal_audit_type_id
         WHERE CASE (act.re_audit_due_after_type)
                WHEN 'd' THEN nvl(ovw_validity_dtm, ia.audit_dtm + re_audit_due_after)
                WHEN 'w' THEN nvl(ovw_validity_dtm, ia.audit_dtm + (re_audit_due_after*7))
                WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after))
                WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12))
               END <= SYSDATE
          AND expired = 0
    ) LOOP
        security_pkg.SetApp(r.app_sid);
        INTERNAL_SetAuditExpired(r.internal_audit_sid);
        security_pkg.SetApp(null);
        COMMIT;
    END LOOP;
    
    user_pkg.LogOff(security_pkg.GetAct);
END;

PROCEDURE GetClosureTypes(
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    
    OPEN out_cur FOR
        SELECT act.audit_closure_type_id, act.label, act.icon_image_filename, act.icon_image_mime_type,
               act.is_failure, act.lookup_key
          FROM audit_closure_type act
         ORDER BY LOWER(act.label);
END;

PROCEDURE DeleteClosureType(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE
)
AS
    v_audits_sid                security.security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security.security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security.security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    DELETE FROM audit_closure_type
     WHERE audit_closure_type_id = in_audit_closure_type_id
       AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE SaveClosureType(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    in_label                    IN    audit_closure_type.label%TYPE,
    in_is_failure                IN    audit_closure_type.is_failure%TYPE,
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
    v_audit_closure_type_id        audit_closure_type.audit_closure_type_id%TYPE := in_audit_closure_type_id;
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    IF in_audit_closure_type_id IS NULL THEN
        BEGIN
            INSERT INTO audit_closure_type (audit_closure_type_id, label, is_failure)
            VALUES (audit_closure_type_id_seq.NEXTVAL, in_label, in_is_failure)
         RETURNING audit_closure_type_id INTO v_audit_closure_type_id;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                UPDATE audit_closure_type
                   SET is_failure = in_is_failure
                 WHERE label = in_label
             RETURNING audit_closure_type_id INTO v_audit_closure_type_id;
        END;
    ELSE
        UPDATE audit_closure_type
           SET label = in_label,
               is_failure = in_is_failure
         WHERE audit_closure_type_id = in_audit_closure_type_id;
    END IF;

    OPEN out_cur FOR
        SELECT act.audit_closure_type_id, act.label, act.icon_image_filename, act.icon_image_mime_type, act.is_failure
          FROM audit_closure_type act
         WHERE act.app_sid = security.security_pkg.GetApp
           AND act.audit_closure_type_id = v_audit_closure_type_id;
END;

PROCEDURE GetClosureTypesByAuditType(
    in_internal_audit_type_id    IN    audit_type_closure_type.internal_audit_type_id%TYPE,
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- No permissions to get the list, used in filter basedata
    OPEN out_cur FOR
        SELECT atct.internal_audit_type_id, act.audit_closure_type_id, act.label,
               atct.re_audit_due_after, atct.re_audit_due_after_type, atct.reminder_offset_days,
               atct.reportable_for_months, act.icon_image_filename, act.icon_image_mime_type,
               act.is_failure, iat.label internal_audit_type_label, manual_expiry_date, act.lookup_key
          FROM audit_closure_type act
          JOIN audit_type_closure_type atct ON act.app_sid = atct.app_sid AND act.audit_closure_type_id = atct.audit_closure_type_id
          JOIN internal_audit_type iat ON atct.internal_audit_type_id = iat.internal_audit_type_id
         WHERE act.app_sid = security.security_pkg.GetApp
           AND atct.internal_audit_type_id = NVL(in_internal_audit_type_id, atct.internal_audit_type_id)
         ORDER BY LOWER(act.label);
END;

PROCEDURE DeleteAuditTypeClosureType(
    in_internal_audit_type_id    IN    audit_type_closure_type.internal_audit_type_id%TYPE,
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE
)
AS
    v_audits_sid                security.security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security.security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security.security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    DELETE FROM audit_type_closure_type
     WHERE internal_audit_type_id = in_internal_audit_type_id
       AND audit_closure_type_id = in_audit_closure_type_id
       AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE SaveAuditTypeClosureType(
    in_internal_audit_type_id    IN    audit_type_closure_type.internal_audit_type_id%TYPE,
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    in_re_audit_due_after        IN    audit_type_closure_type.re_audit_due_after%TYPE,
    in_re_audit_due_after_type    IN    audit_type_closure_type.re_audit_due_after_type%TYPE,
    in_reminder_offset_days        IN    audit_type_closure_type.reminder_offset_days%TYPE,
    in_reportable_for_months    IN    audit_type_closure_type.reportable_for_months%TYPE,
    in_manual_expiry_date        IN    audit_type_closure_type.manual_expiry_date%TYPE,
    out_cur                        OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    IF in_audit_closure_type_id IS NULL THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'in_audit_closure_type_id is not set');
    END IF;

    BEGIN
        INSERT INTO audit_type_closure_type (internal_audit_type_id, audit_closure_type_id,
                re_audit_due_after, re_audit_due_after_type,
                reminder_offset_days, reportable_for_months, manual_expiry_date)
        VALUES (in_internal_audit_type_id, in_audit_closure_type_id,
                in_re_audit_due_after, in_re_audit_due_after_type,
                in_reminder_offset_days, in_reportable_for_months, in_manual_expiry_date);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE audit_type_closure_type
               SET re_audit_due_after = in_re_audit_due_after,
                   re_audit_due_after_type = in_re_audit_due_after_type,
                   reminder_offset_days = in_reminder_offset_days,
                   reportable_for_months = in_reportable_for_months,
                   manual_expiry_date = in_manual_expiry_date
             WHERE internal_audit_type_id = in_internal_audit_type_id
               AND audit_closure_type_id = in_audit_closure_type_id;
    END;

    OPEN out_cur FOR
        SELECT atct.internal_audit_type_id, act.audit_closure_type_id, act.label,
               atct.re_audit_due_after, atct.re_audit_due_after_type, atct.reminder_offset_days,
               atct.reportable_for_months, act.icon_image_filename, act.icon_image_mime_type,
               act.is_failure, manual_expiry_date
          FROM audit_closure_type act
          JOIN audit_type_closure_type atct ON act.app_sid = atct.app_sid AND act.audit_closure_type_id = atct.audit_closure_type_id
         WHERE act.app_sid = security.security_pkg.GetApp
           AND atct.internal_audit_type_id = in_internal_audit_type_id
           AND act.audit_closure_type_id = in_audit_closure_type_id;
END;

PROCEDURE ChangeClosureTypeIcon(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    in_cache_key                IN    aspen2.filecache.cache_key%type
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    IF in_cache_key IS NULL THEN
        UPDATE audit_closure_type
           SET icon_image = NULL,
               icon_image_filename = NULL,
               icon_image_mime_type = NULL
         WHERE audit_closure_type_id = in_audit_closure_type_id;
    ELSE
        -- update image
        UPDATE audit_closure_type
           SET (icon_image, icon_image_filename, icon_image_mime_type, icon_image_sha1) = (
                SELECT object, filename, mime_type, sys.dbms_crypto.hash(object, sys.dbms_crypto.hash_sh1)
                  FROM aspen2.filecache
                 WHERE cache_key = in_cache_key
             )
         WHERE audit_closure_type_id = in_audit_closure_type_id;
    END IF;

END;

PROCEDURE GetClosureTypeIcon(
    in_audit_closure_type_id    IN    audit_closure_type.audit_closure_type_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- No security - it's just an icon

    OPEN out_cur FOR
        SELECT icon_image image, icon_image_filename filename, icon_image_mime_type mime_type
          FROM audit_closure_type
         WHERE app_sid = security.security_pkg.getApp
           AND audit_closure_type_id = in_audit_closure_type_id
           AND icon_image IS NOT NULL;
END;

PROCEDURE SetClosureStatus(
    in_internal_audit_sid                IN    security_pkg.T_SID_ID,
    in_audit_closure_type_id            IN    audit_closure_type.audit_closure_type_id%TYPE
)        
AS        
    v_old_status                        audit_closure_type.label%TYPE;
    v_new_status                        audit_closure_type.label%TYPE;
    v_old_reportable_months                audit_type_closure_type.reportable_for_months%TYPE;
    v_start_dtm                            DATE;
    v_end_dtm                            DATE;
    v_agg_ind_id                        aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
    IF IsFlowAudit(in_internal_audit_sid) THEN
        IF NOT (HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_WRITE)) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User does not have the closure result flow capability on the audit with sid: '||in_internal_audit_sid);
        END IF;
    ELSIF NOT (HasWriteAccess(in_internal_audit_sid) AND csr_data_pkg.CheckCapability('Close audits')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User does not have write access or the "Close Audit" capability on the audit with sid: '||in_internal_audit_sid);
    END IF;

    SELECT MIN(act.label)
      INTO v_old_status
      FROM audit_closure_type act
      JOIN internal_audit ia ON act.audit_closure_type_id = ia.audit_closure_type_id
     WHERE ia.internal_audit_sid = in_internal_audit_sid;

    SELECT MIN(label)
      INTO v_new_status
      FROM audit_closure_type
     WHERE audit_closure_type_id = in_audit_closure_type_id;

    csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'),
        in_internal_audit_sid, 'Status', v_old_status, v_new_status);

    BEGIN
        SELECT ac.reportable_for_months
          INTO v_old_reportable_months
          FROM internal_audit ia
          LEFT JOIN audit_type_closure_type ac ON ia.audit_closure_type_id = ac.audit_closure_type_id AND ia.internal_audit_type_id = ac.internal_audit_type_id AND ia.app_sid = ac.app_sid
         WHERE ia.internal_audit_sid = in_internal_audit_sid;
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END;

    UPDATE internal_audit
       SET audit_closure_type_id = in_audit_closure_type_id
     WHERE internal_audit_sid = in_internal_audit_sid;

    INTERNAL_CallHelperPkg('AuditClosureStatusChanged', in_internal_audit_sid);

    BEGIN
        SELECT qs.aggregate_ind_group_id, TRUNC(ia.audit_dtm, 'MONTH'), ADD_MONTHS(TRUNC(ia.audit_dtm,'MONTH'), NVL(NULLIF(GREATEST(NVL(iat.validity_months, 0), NVL(ac.reportable_for_months, 0), NVL(v_old_reportable_months, 0)), 0), 12)) --NVL? GREATEST? 12?
          INTO v_agg_ind_id, v_start_dtm, v_end_dtm
          FROM quick_survey_response qsr
          JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
          JOIN internal_audit ia ON qsr.survey_response_id = ia.survey_response_id AND qs.survey_sid = ia.survey_sid
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
          LEFT JOIN audit_type_closure_type ac ON ia.audit_closure_type_id = ac.audit_closure_type_id AND ia.internal_audit_type_id = ac.internal_audit_type_id AND ia.app_sid = ac.app_sid
         WHERE ia.internal_audit_sid = in_internal_audit_sid
           AND qs.audience = 'audit';
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END;

    IF v_agg_ind_id IS NOT NULL AND v_start_dtm IS NOT NULL AND v_end_dtm IS NOT NULL THEN
        calc_pkg.AddJobsForAggregateIndGroup(v_agg_ind_id, TRUNC(v_start_dtm, 'MONTH'), TRUNC(v_end_dtm, 'MONTH'));
    END IF;
END;

PROCEDURE SetOvwValidityDtm (
    in_internal_audit_sid         IN  security_pkg.T_SID_ID,
    in_ovw_validity_dtm            IN  DATE
)
AS 
    v_prev_ovw_validity_dtm        DATE;
BEGIN
    IF IsFlowAudit(in_internal_audit_sid) THEN
        IF NOT (HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE, security.security_pkg.PERMISSION_WRITE)) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User does not have the closure result flow capability on the audit with sid: '||in_internal_audit_sid);
        END IF;
    ELSIF NOT (HasWriteAccess(in_internal_audit_sid) AND csr_data_pkg.CheckCapability('Close audits')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User does not have write access or the "Close Audit" capability on the audit with sid: '||in_internal_audit_sid);
    END IF;
    
    BEGIN
        SELECT ovw_validity_dtm
          INTO v_prev_ovw_validity_dtm
          FROM internal_audit
         WHERE internal_audit_sid = in_internal_audit_sid; 
    EXCEPTION
        WHEN no_data_found THEN
            v_prev_ovw_validity_dtm := NULL;
    END;
    
    UPDATE internal_audit
       SET ovw_validity_dtm = in_ovw_validity_dtm
     WHERE internal_audit_sid = in_internal_audit_sid;
     
     csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'), in_internal_audit_sid,
        'Overwritten Expiry Date changed from {0} to {1}', NVL(TO_CHAR(v_prev_ovw_validity_dtm), 'Empty') , in_ovw_validity_dtm);
END;

PROCEDURE GetReminderAlerts(
    out_cur                            OUT    SYS_REFCURSOR
)
AS
BEGIN
    alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_AUDIT_EXPIRING);

    OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/nd.app_sid, u.csr_user_sid, r.description region_description,
               iat.label audit_type_label, nd.next_audit_due_dtm, nd.internal_audit_sid
          FROM v$audit_next_due nd
          JOIN internal_audit_type iat ON nd.internal_audit_type_id = iat.internal_audit_type_id AND nd.app_sid = iat.app_sid
          LEFT JOIN audit_type_expiry_alert_role atear ON iat.internal_audit_type_id = atear.internal_audit_type_id
          LEFT JOIN region_role_member rrm ON nd.region_sid = rrm.region_sid AND atear.role_sid = rrm.role_sid AND nd.app_sid = rrm.app_sid
          JOIN csr_user u ON (nd.previous_auditor_user_sid = u.csr_user_sid AND nd.app_sid = u.app_sid AND iat.send_auditor_expiry_alerts = 1)
            OR (rrm.user_sid = u.csr_user_sid AND rrm.app_sid = u.app_sid)
          JOIN v$region r ON nd.region_sid = r.region_sid AND nd.app_sid = r.app_sid
          LEFT JOIN audit_alert aa ON nd.internal_audit_sid = aa.internal_audit_sid AND nd.app_sid = aa.app_sid
           AND u.csr_user_sid = aa.csr_user_sid
          JOIN temp_alert_batch_run tabr ON u.csr_user_sid = tabr.csr_user_sid AND u.app_sid = tabr.app_sid
         WHERE nd.next_audit_due_dtm - NVL(nd.reminder_offset_days, 5) <= tabr.this_fire_time -- if the audit needs a reminder
           AND nd.next_audit_due_dtm > tabr.this_fire_time -- but isn't overdue (in the user's local time zone)
           AND tabr.std_alert_type_id = csr_data_pkg.ALERT_AUDIT_EXPIRING
           AND aa.reminder_sent_dtm IS NULL
         GROUP BY nd.app_sid, u.csr_user_sid, r.description, iat.label, nd.next_audit_due_dtm, nd.internal_audit_sid
         ORDER BY app_sid, csr_user_sid, region_description, audit_type_label, next_audit_due_dtm, internal_audit_sid;
END;

PROCEDURE GetOverdueAlerts(
    out_cur                            OUT    SYS_REFCURSOR
)
AS
BEGIN
    alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_AUDIT_OVERDUE);

    OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/nd.app_sid, u.csr_user_sid, r.description region_description,
               iat.label audit_type_label, nd.next_audit_due_dtm, nd.internal_audit_sid
          FROM v$audit_next_due nd
          JOIN internal_audit_type iat ON nd.internal_audit_type_id = iat.internal_audit_type_id AND nd.app_sid = iat.app_sid
          LEFT JOIN audit_type_expiry_alert_role atear ON iat.internal_audit_type_id = atear.internal_audit_type_id
          LEFT JOIN region_role_member rrm ON nd.region_sid = rrm.region_sid AND atear.role_sid = rrm.role_sid AND nd.app_sid = rrm.app_sid
          JOIN csr_user u ON (nd.previous_auditor_user_sid = u.csr_user_sid AND nd.app_sid = u.app_sid AND iat.send_auditor_expiry_alerts = 1)
            OR (rrm.user_sid = u.csr_user_sid AND rrm.app_sid = u.app_sid)
          JOIN v$region r ON nd.region_sid = r.region_sid AND nd.app_sid = r.app_sid
          LEFT JOIN audit_alert aa ON nd.internal_audit_sid = aa.internal_audit_sid AND nd.app_sid = aa.app_sid
           AND u.csr_user_sid = aa.csr_user_sid
          JOIN temp_alert_batch_run tabr ON u.csr_user_sid = tabr.csr_user_sid AND u.app_sid = tabr.app_sid
         WHERE nd.next_audit_due_dtm < tabr.this_fire_time -- is overdue (in the user's local time zone)
           AND tabr.std_alert_type_id = csr_data_pkg.ALERT_AUDIT_OVERDUE
           AND aa.overdue_sent_dtm IS NULL
         GROUP BY nd.app_sid, u.csr_user_sid, r.description, iat.label, nd.next_audit_due_dtm, nd.internal_audit_sid
         ORDER BY app_sid, csr_user_sid, region_description, audit_type_label, next_audit_due_dtm, internal_audit_sid;
END;

PROCEDURE RecordReminderSent(
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_user_sid                    IN    security_pkg.T_SID_ID
)
AS
BEGIN
    BEGIN
        INSERT INTO audit_alert (internal_audit_sid, csr_user_sid, reminder_sent_dtm)
        VALUES (in_internal_audit_sid, in_user_sid, SYSDATE);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE audit_alert
               SET reminder_sent_dtm = SYSDATE
             WHERE internal_audit_sid = in_internal_audit_sid
               AND csr_user_sid = in_user_sid;
    END;
END;

PROCEDURE RecordOverdueSent(
    in_internal_audit_sid        IN    security_pkg.T_SID_ID,
    in_user_sid                    IN    security_pkg.T_SID_ID
)
AS
BEGIN
    BEGIN
        INSERT INTO audit_alert (internal_audit_sid, csr_user_sid, overdue_sent_dtm)
        VALUES (in_internal_audit_sid, in_user_sid, SYSDATE);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE audit_alert
               SET overdue_sent_dtm = SYSDATE
             WHERE internal_audit_sid = in_internal_audit_sid
               AND csr_user_sid = in_user_sid;
    END;
END;

PROCEDURE GetNonCompliancesRprt(
    in_region_sid                IN    security_pkg.T_SID_ID,
    in_start_dtm                IN    DATE,
    in_end_dtm                    IN    DATE,
    in_tpl_region_type_id        IN    tpl_region_type.tpl_region_type_id%TYPE,
    in_tag_id                    IN    tag.tag_id%TYPE,
    out_cur_ncs                    OUT    SYS_REFCURSOR,
    out_cur_tags                OUT    SYS_REFCURSOR
)
AS
    v_audits_sid            security_pkg.T_SID_ID;
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
    v_ord_table                security.T_ORDERED_SID_TABLE;
    v_cap_anc_t                security.T_SID_TABLE ;
BEGIN
    BEGIN
        v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Audits module is not enabled');
    END;

    SELECT security.T_ORDERED_SID_ROW(sid_id => column_value, pos => 0)
      BULK COLLECT INTO v_ord_table
      FROM TABLE(v_table);

    v_cap_anc_t := GetAuditsWithCapabilityAsTable(csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL, security.security_pkg.PERMISSION_READ, v_ord_table);

    -- add selected region
    INSERT INTO temp_region_sid(region_sid) VALUES (in_region_sid);

    -- add child regions (if applicable)
    IF in_tpl_region_type_id IN (templated_report_pkg.TPL_REGION_TYPE_SEL_CHILD, templated_report_pkg.TPL_REGION_TYPE_SEL_CHILD_PAR) THEN
        INSERT INTO temp_region_sid(region_sid)
        SELECT region_sid
          FROM region
         START WITH parent_sid = in_region_sid
        CONNECT BY PRIOR region_sid = parent_sid;
    END IF;

    -- add parent regions (if applicable)
    IF in_tpl_region_type_id IN (templated_report_pkg.TPL_REGION_TYPE_SEL_CHILD, templated_report_pkg.TPL_REGION_TYPE_SEL_CHILD_PAR) THEN
        INSERT INTO temp_region_sid(region_sid)
        SELECT parent_sid
          FROM region
         WHERE parent_sid != app_sid
         START WITH region_sid = in_region_sid
        CONNECT BY PRIOR parent_sid = region_sid;
    END IF;

    OPEN out_cur_ncs FOR
        SELECT ia.label audit_label, ia.internal_audit_sid, nc.non_compliance_id, nc.label,
               nc.detail, nc.created_dtm, nc.created_by_user_sid, ncu.full_name created_by_full_name,
               NVL(ncc.closed_issues, 0) closed_issues, NVL(ncc.total_issues, 0) total_issues,
               NVL(ncc.open_issues, 0) open_issues, nc.non_compliance_type_id, nc.is_closed,
               r.description region_description, ia.audit_dtm, iat.label audit_type_label,
               nc.root_cause, nc.suggested_action
          FROM internal_audit ia
          JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
          JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid
          LEFT JOIN non_compliance_tag nct ON nc.non_compliance_id = nct.non_compliance_id AND nct.tag_id = in_tag_id
          JOIN temp_region_sid tr ON ia.region_sid = tr.region_sid
          JOIN v$region r ON ia.region_sid = r.region_sid
          JOIN csr_user ncu ON nc.created_by_user_sid = ncu.csr_user_sid
          JOIN TABLE(
            v_table
            ) so ON ia.internal_audit_sid = so.column_value
          LEFT JOIN (
            SELECT inc.app_sid, inc.non_compliance_id,
                   COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
                   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
              FROM issue_non_compliance inc
              JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
             GROUP BY inc.app_sid, inc.non_compliance_id
            ) ncc ON nc.non_compliance_id = ncc.non_compliance_id AND nc.app_sid = ncc.app_sid
          LEFT JOIN TABLE(v_cap_anc_t) cap_t ON ia.internal_audit_sid = cap_t.column_value
         WHERE ia.audit_dtm >= in_start_dtm
           AND ia.audit_dtm < in_end_dtm
           AND (in_tag_id IS NULL OR nct.tag_id = in_tag_id)
           AND (ia.flow_item_id IS NULL OR cap_t.column_value IS NOT NULL);

    OPEN out_cur_tags FOR
        SELECT nc.non_compliance_id, tg.name tag_group_name, t.tag
          FROM v$tag_group tg
         CROSS JOIN (
            SELECT nc.non_compliance_id
              FROM internal_audit ia
              JOIN non_compliance nc ON ia.internal_audit_sid = nc.created_in_audit_sid
              LEFT JOIN non_compliance_tag nct ON nc.non_compliance_id = nct.non_compliance_id AND nct.tag_id = in_tag_id
              JOIN temp_region_sid r ON ia.region_sid = r.region_sid
              JOIN TABLE(
                v_table
                ) so ON ia.internal_audit_sid = so.column_value
              LEFT JOIN TABLE(v_cap_anc_t) cap_t ON ia.internal_audit_sid = cap_t.column_value
             WHERE ia.audit_dtm >= in_start_dtm
               AND ia.audit_dtm < in_end_dtm
               AND (in_tag_id IS NULL OR nct.tag_id = in_tag_id)
               AND (ia.flow_item_id IS NULL OR cap_t.column_value IS NOT NULL)
         ) nc
          LEFT JOIN (
            SELECT nct2.non_compliance_id, nct2.tag_id, tgm.tag_group_id
              FROM non_compliance_tag nct2
              JOIN tag_group_member tgm ON nct2.tag_id = tgm.tag_id
          ) nct ON nc.non_compliance_id = nct.non_compliance_id AND tg.tag_group_id = nct.tag_group_id
          LEFT JOIN v$tag t ON nct.tag_id = t.tag_id
         WHERE tg.applies_to_non_compliances = 1;

END;

PROCEDURE GetFlowTransitions(
    in_audit_sid        IN  security_pkg.T_SID_ID,
    out_cur             OUT SYS_REFCURSOR
)
AS
    v_flow_sid            security_pkg.T_SID_ID;
BEGIN
    SELECT fi.flow_sid
      INTO v_flow_sid
      FROM flow_item fi
      JOIN internal_audit ia ON fi.flow_item_id = ia.flow_item_id
     WHERE ia.internal_audit_sid = in_audit_sid;

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
    END IF;

    OPEN out_cur FOR
        SELECT ia.flow_item_id, fst.flow_state_transition_id, fst.verb, fst.to_state_id,
               fst.pos transition_pos, fs.label to_state_label, fst.ask_for_comment,
               fs.state_colour to_state_colour, fst.button_icon_path
          FROM internal_audit ia
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
          JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
          JOIN flow_state_transition_role fstr ON fst.flow_state_transition_id = fstr.flow_state_transition_id
          JOIN flow_state fs ON fst.to_state_id = fs.flow_state_id
          JOIN region_role_member rrm ON ia.region_sid = rrm.region_sid AND ia.app_sid = rrm.app_sid
           AND fstr.role_sid = rrm.role_sid
         WHERE ia.internal_audit_sid = in_audit_sid
           AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
         UNION
         SELECT ia.flow_item_id, fst.flow_state_transition_id, fst.verb, fst.to_state_id,
               fst.pos transition_pos, fs.label to_state_label, fst.ask_for_comment,
               fs.state_colour to_state_colour, fst.button_icon_path
          FROM internal_audit ia
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
          JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
          JOIN flow_state_transition_role fstr ON fst.flow_state_transition_id = fstr.flow_state_transition_id
          JOIN flow_state fs ON fst.to_state_id = fs.flow_state_id
          JOIN security.act act ON fstr.group_sid = act.sid_id
           AND act.act_id = SYS_CONTEXT('SECURITY','ACT')
         WHERE ia.internal_audit_sid = in_audit_sid
         UNION
        SELECT ia.flow_item_id, fst.flow_state_transition_id, fst.verb, fst.to_state_id,
               fst.pos transition_pos, fs.label to_state_label, fst.ask_for_comment,
               fs.state_colour to_state_colour, fst.button_icon_path
          FROM internal_audit ia
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
          JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
          JOIN flow_state_transition_inv fsti ON fst.flow_state_transition_id = fsti.flow_state_transition_id
     LEFT JOIN flow_item_involvement fii
            ON fii.flow_involvement_type_id = fsti.flow_involvement_type_id
           AND fii.flow_item_id = fi.flow_item_id
          JOIN flow_state fs ON fst.to_state_id = fs.flow_state_id
         WHERE ia.internal_audit_sid = in_audit_sid
           AND ((fsti.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDITOR
           AND ia.auditor_user_sid = SYS_CONTEXT('SECURITY','SID'))
            OR (fsti.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
           AND ia.auditor_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY'))
            OR (fii.flow_involvement_type_id IS NOT NULL
           AND fii.user_sid = SYS_CONTEXT('SECURITY','SID')))
         UNION
        SELECT ia.flow_item_id, fst.flow_state_transition_id, fst.verb, fst.to_state_id,
               fst.pos transition_pos, fs.label to_state_label, fst.ask_for_comment,
               fs.state_colour to_state_colour, fst.button_icon_path
          FROM internal_audit ia
          JOIN flow_item fi ON ia.flow_item_id = fi.flow_item_id
          JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
          JOIN flow_state fs ON fst.to_state_id = fs.flow_state_id
          JOIN flow_state_transition_inv fsti ON fst.flow_state_transition_id = fsti.flow_state_transition_id
          JOIN supplier s ON ia.region_sid = s.region_sid
          JOIN chain.v$purchaser_involvement pi
            ON s.company_sid = pi.supplier_company_sid
           AND pi.flow_involvement_type_id = fsti.flow_involvement_type_id
         WHERE ia.internal_audit_sid = in_audit_sid
         ORDER BY transition_pos;
END;

FUNCTION GetFlowRegionSids(
    in_flow_item_id        IN    csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
    v_region_sids_t            security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
    SELECT region_sid
      BULK COLLECT INTO v_region_sids_t
      FROM v$audit
     WHERE app_sid = security_pkg.getApp
       AND flow_item_id = in_flow_item_id;

    RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
    in_flow_item_id        IN    csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
    v_count                    NUMBER;
BEGIN

    SELECT DECODE(count(*), 0, 0, 1)
      INTO v_count
      FROM v$audit
     WHERE app_sid = security_pkg.getApp
       AND flow_item_id = in_flow_item_id;

    RETURN v_count;
END;

PROCEDURE GenerateInvolmTypeAlertEntries(
    in_flow_item_id                 IN flow_item.flow_item_id%TYPE,
    in_set_by_user_sid                IN     security_pkg.T_SID_ID,
    in_flow_transition_alert_id      IN flow_transition_alert.flow_transition_alert_id%TYPE,
    in_flow_involvement_type_id      IN flow_involvement_type.flow_involvement_type_id%TYPE,
    in_flow_state_log_id             IN flow_state_log.flow_state_log_id%TYPE,
    in_subject_override                IN flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
    in_body_override                IN flow_item_generated_alert.body_override%TYPE DEFAULT NULL
)
AS
BEGIN

    IF in_flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDITOR THEN
        --to auditor user sid
        INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id,
            from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, subject_override, body_override)
        SELECT app_sid, flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id,
            in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id, in_subject_override,
            in_body_override
          FROM (
            SELECT DISTINCT ia.app_sid, ia.auditor_user_sid to_user_sid
              FROM internal_audit ia
             WHERE ia.flow_item_id = in_flow_item_id
               AND ia.deleted = 0
              AND NOT EXISTS(
                SELECT 1
                  FROM flow_item_generated_alert figa
                 WHERE figa.app_sid = ia.app_sid
                   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
                   AND figa.flow_state_log_id = in_flow_state_log_id
                   AND figa.to_user_sid = ia.auditor_user_sid

              )
         );
    ELSIF in_flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY THEN
        --to members of the auditor company
        INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id,
        from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, subject_override, body_override)
        SELECT app_sid, flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, in_set_by_user_sid, to_user_sid, NULL,
            in_flow_item_id, in_flow_state_log_id, in_subject_override, in_body_override
          FROM (
            SELECT DISTINCT ia.app_sid, cm.user_sid to_user_sid
              FROM internal_audit ia
              JOIN chain.v$company_member cm ON cm.company_sid = ia.auditor_company_sid
             WHERE ia.flow_item_id = in_flow_item_id
               AND ia.deleted = 0
              AND NOT EXISTS(
                SELECT 1
                  FROM flow_item_generated_alert figa
                 WHERE figa.app_sid = ia.app_sid
                   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
                   AND figa.flow_state_log_id = in_flow_state_log_id
                   AND figa.to_user_sid = cm.user_sid
              )
         );
    ELSE
        --non restricted purchaser pseudo-roles
        INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
            from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
        SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
            in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
          FROM (
            SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
              FROM internal_audit ia
              JOIN supplier s ON ia.region_sid = s.region_sid
              JOIN chain.supplier_relationship sr ON sr.supplier_company_sid = s.company_sid
              JOIN chain.company pc ON pc.company_sid = sr.purchaser_company_sid
              JOIN chain.company sc ON sc.company_sid = sr.supplier_company_sid
                JOIN chain.supplier_involvement_type sit
                ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
               AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
               AND (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_ANY
                OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_PRIMARY AND sr.is_primary = 1)
                OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_OWNER AND pc.company_sid = sc.parent_sid)
                )
              JOIN chain.v$company_user cu ON sr.purchaser_company_sid = cu.company_sid   
             WHERE ia.flow_item_id = in_flow_item_id
               AND sit.flow_involvement_type_id = in_flow_involvement_type_id
               AND sr.active = 1
               AND sr.deleted = 0
               AND sit.restrict_to_role_sid IS NULL
               AND NOT EXISTS(
                SELECT 1 
                  FROM flow_item_generated_alert figa
                 WHERE figa.app_sid = sr.app_sid
                   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
                   AND figa.flow_state_log_id = in_flow_state_log_id
                   AND figa.to_user_sid = cu.user_sid
              )
         );
        
        --RRM (on purchaser region) restricted purchaser pseudo-roles
        INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
            from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
        SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
            in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
          FROM (
            SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
              FROM internal_audit ia
              JOIN supplier s ON ia.region_sid = s.region_sid
              JOIN chain.supplier_relationship sr ON sr.supplier_company_sid = s.company_sid
              JOIN chain.company pc ON pc.company_sid = sr.purchaser_company_sid
              JOIN chain.company sc ON sc.company_sid = sr.supplier_company_sid
                JOIN chain.supplier_involvement_type sit
                ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
               AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
               AND (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_ANY
                OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_PRIMARY AND sr.is_primary = 1)
                OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_OWNER AND pc.company_sid = sc.parent_sid)
                )
              JOIN supplier ps ON ps.company_sid = sr.purchaser_company_sid
              JOIN chain.v$company_user cu ON sr.purchaser_company_sid = cu.company_sid
              JOIN region_role_member rrm
                ON rrm.region_sid = ps.region_sid
               AND rrm.user_sid = cu.user_sid
               AND rrm.role_sid = sit.restrict_to_role_sid
             WHERE ia.flow_item_id = in_flow_item_id
               AND sit.flow_involvement_type_id = in_flow_involvement_type_id
               AND sr.active = 1
               AND sr.deleted = 0
               AND sit.restrict_to_role_sid IS NOT NULL
               AND NOT EXISTS(
                SELECT 1 
                  FROM flow_item_generated_alert figa
                 WHERE figa.app_sid = sr.app_sid
                   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
                   AND figa.flow_state_log_id = in_flow_state_log_id
                   AND figa.to_user_sid = cu.user_sid
              )
         );
    END IF;
END;

PROCEDURE GetFlowAlerts(
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR,
    out_refs                    OUT    security_pkg.T_OUTPUT_CUR,
    out_tags                    OUT    security_pkg.T_OUTPUT_CUR,
    out_scores                    OUT    security_pkg.T_OUTPUT_CUR,
    out_reports                 OUT    security_pkg.T_OUTPUT_CUR,
    out_audit_tags                OUT    security_pkg.T_OUTPUT_CUR,
    out_primary_purchasers        OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    --no security as this is called by credit360.scheduledtasks.flow
    OPEN out_cur FOR
        SELECT figa.app_sid, figa.flow_item_generated_alert_id, figa.customer_alert_type_id, figa.from_state_label,
            figa.to_state_label, figa.set_by_user_sid, figa.set_by_full_name, figa.set_by_email, figa.set_by_user_name,
            figa.to_user_sid, figa.to_full_name, figa.to_email, figa.to_friendly_name, figa.to_user_name, figa.to_initiator,
            figa.flow_item_id, figa.subject_override, figa.body_override, r.region_sid, r.description region_description,
            a.internal_audit_sid, a.audit_dtm, a.label, a.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, a.auditor_name, a.auditor_organisation, ac.name auditor_company,
            dbms_lob.substr(a.notes,50,1) short_notes, dbms_lob.substr(a.notes,2000,1) full_notes, iat.internal_audit_type_id audit_type_id, iat.label audit_type_label,
            qs.label survey_label, a.created_by_user_sid, NVL(cu.email, au.email) auditor_email, fs.label flow_state_label, comment_text, flow_alert_helper, iat.tab_sid,
            c.company_sid, c.name company_name, c.address_1 company_address_1, c.address_2 company_address_2, c.address_3 company_address_3, c.address_4 company_address_4, sfs.label company_workflow_state,
            pc.name company_country, c.phone company_phone, c.fax company_fax, c.website company_website, rl.label company_country_risk_label, qsr.submitted_dtm survey_submitted_dtm,
            act.label audit_result
          FROM v$open_flow_item_gen_alert figa
     -- v$audit replacement
          JOIN internal_audit a ON a.flow_item_id = figa.flow_item_id AND a.app_sid = figa.app_sid
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = a.internal_audit_type_id  AND iat.app_sid = a.app_sid 
          JOIN flow_item fi ON a.flow_item_id = fi.flow_item_id AND a.app_sid = fi.app_sid
          JOIN flow_state fs ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid 
     LEFT JOIN csr_user au ON a.auditor_user_sid = au.csr_user_sid AND a.app_sid = au.app_sid
     LEFT JOIN (
         SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
               ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
               CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
          FROM audit_user_cover auc
          JOIN user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
         CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
     ) cvru
     ON a.internal_audit_sid = cvru.internal_audit_sid
     LEFT JOIN csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
     LEFT JOIN audit_closure_type act ON act.audit_closure_type_id = a.audit_closure_type_id AND act.app_sid = a.app_sid
     LEFT JOIN v$quick_survey qs ON a.survey_sid = qs.survey_sid AND a.app_sid = qs.app_sid
     LEFT JOIN v$quick_survey_response qsr ON a.survey_sid = qsr.survey_sid AND a.survey_response_id = qsr.survey_response_id
     LEFT JOIN v$region r ON a.app_sid = r.app_sid AND a.region_sid = r.region_sid
     -- v$audit ends
     LEFT JOIN supplier s ON a.region_sid = s.region_sid AND a.app_sid = s.app_sid
     LEFT JOIN chain.company c ON c.company_sid = s.company_sid AND c.app_sid = s.app_sid
     LEFT JOIN chain.v$current_country_risk_level crl ON crl.country = c.country_code AND crl.app_sid = c.app_sid
     LEFT JOIN postcode.country pc ON pc.country = c.country_code
     LEFT JOIN chain.risk_level rl ON rl.risk_level_id = crl.risk_level_id AND rl.app_sid = crl.app_sid
     LEFT JOIN chain.customer_options co ON co.app_sid = crl.app_sid
     LEFT JOIN chain.supplier_relationship sr ON sr.purchaser_company_sid = co.top_company_sid
           AND sr.supplier_company_sid = c.company_sid AND sr.app_sid = c.app_sid
     LEFT JOIN flow_item sfi ON sfi.flow_item_id = sr.flow_item_id AND sfi.app_sid = sr.app_sid
     LEFT JOIN flow_state sfs ON sfs.flow_state_id = fi.current_state_id AND sfs.app_sid = fi.app_sid
     LEFT JOIN chain.company ac ON ac.company_sid = a.auditor_company_sid
         WHERE a.deleted = 0
         ORDER BY figa.app_sid, figa.customer_alert_type_id, figa.to_user_sid, figa.flow_item_id;
         
    OPEN out_refs FOR 
        SELECT DISTINCT cr.app_sid, cr.reference_id, s.company_sid, r.label, cr.value
          FROM v$open_flow_item_gen_alert figa
          JOIN internal_audit a ON a.flow_item_id = figa.flow_item_id AND a.app_sid = figa.app_sid
          JOIN flow_item fi ON a.flow_item_id = fi.flow_item_id AND a.app_sid = fi.app_sid
          JOIN supplier s ON a.region_sid = s.region_sid AND a.app_sid = s.app_sid
          JOIN chain.company_reference cr ON s.company_sid = cr.company_sid AND s.app_sid = cr.app_sid
          JOIN chain.reference r ON cr.reference_id = r.reference_id AND cr.app_sid = r.app_sid
         WHERE a.deleted = 0;
             
    OPEN out_tags FOR 
        SELECT DISTINCT t.app_sid, t.tag_id, t.tag, tg.tag_group_id, tg.name tag_group_name, s.company_sid
          FROM v$open_flow_item_gen_alert figa
          JOIN internal_audit a ON a.flow_item_id = figa.flow_item_id AND a.app_sid = figa.app_sid
          JOIN supplier s ON a.region_sid = s.region_sid AND a.app_sid = s.app_sid
          JOIN region_tag rt ON a.region_sid = rt.region_sid AND a.app_sid = rt.app_sid
          JOIN v$tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
          JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND tgm.app_sid = t.app_sid
          JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tg.app_sid = tgm.app_sid
         WHERE a.deleted = 0;
    
    OPEN out_scores FOR
        SELECT DISTINCT css.app_sid, css.company_sid, ss.score, css.score_type_id, ss.score_threshold_id, t.format_mask, st.description description
          FROM v$open_flow_item_gen_alert figa
          JOIN internal_audit a ON a.flow_item_id = figa.flow_item_id AND a.app_sid = figa.app_sid
          JOIN supplier s ON a.region_sid = s.region_sid AND a.app_sid = s.app_sid
          JOIN current_supplier_score css ON css.company_sid = s.company_sid AND css.app_sid = s.app_sid
          JOIN supplier_score_log ss ON css.company_sid = ss.supplier_sid AND css.last_supplier_score_id = ss.supplier_score_id
          LEFT JOIN score_threshold st ON ss.score_threshold_id = st.score_threshold_id
          JOIN score_type t ON css.score_type_id = t.score_type_id
         WHERE a.deleted = 0;

    OPEN out_reports FOR
        SELECT DISTINCT iatr.app_sid, rg.ia_type_report_group_id audit_report_group_id, rg.label, iatr.internal_audit_type_id audit_type_id, 
               iatr.internal_audit_type_report_id audit_report_id, iatr.use_merge_field_guid is_public
          FROM v$open_flow_item_gen_alert figa
          JOIN internal_audit a ON a.flow_item_id = figa.flow_item_id AND figa.app_sid = a.app_sid
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = a.internal_audit_type_id AND iat.app_sid = a.app_sid
          JOIN internal_audit_type_report iatr ON iat.internal_audit_type_id = iatr.internal_audit_type_id AND iatr.app_sid = iat.app_sid
          JOIN ia_type_report_group rg ON rg.ia_type_report_group_id = iatr.ia_type_report_group_id AND rg.app_sid = iatr.app_sid
          JOIN internal_audit_type_report iatr 
            ON iatr.internal_audit_type_id = iat.internal_audit_type_id
           AND iatr.ia_type_report_group_id = rg.ia_type_report_group_id
           AND iatr.app_sid = rg.app_sid
         WHERE iat.active = 1;

    OPEN out_audit_tags FOR 
        SELECT DISTINCT t.app_sid, a.internal_audit_sid, t.tag_id, t.tag, tg.tag_group_id, tg.name tag_group_name
          FROM v$open_flow_item_gen_alert figa
          JOIN internal_audit a ON figa.flow_item_id = a.flow_item_id AND figa.app_sid = a.app_sid
          JOIN internal_audit_tag iat ON a.internal_audit_sid = iat.internal_audit_sid AND iat.app_sid = a.app_sid
          JOIN v$tag t ON iat.tag_id = t.tag_id AND iat.app_sid = t.app_sid
          JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
          JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
         WHERE a.deleted = 0;

    OPEN out_primary_purchasers FOR
        SELECT DISTINCT sr.supplier_company_sid company_sid, pc.company_sid purchaser_company_sid,
               pc.name purchaser_company_name, pc.company_type_id purchaser_type_id, ct.lookup_key purchaser_type_lookup_key
          FROM v$open_flow_item_gen_alert figa
          JOIN internal_audit a ON a.flow_item_id = figa.flow_item_id AND a.app_sid = figa.app_sid
          JOIN supplier s ON a.region_sid = s.region_sid AND a.app_sid = s.app_sid
          JOIN chain.supplier_relationship sr ON s.company_sid = sr.supplier_company_sid AND s.app_sid = sr.app_sid
          JOIN chain.company pc ON sr.purchaser_company_sid = pc.company_sid
          JOIN chain.company_type ct ON pc.company_type_id = ct.company_type_id
         WHERE a.deleted = 0
           AND sr.is_primary = 1
           AND sr.deleted = 0
           AND sr.active = 1; 
END;

PROCEDURE GetAuditLogForAuditPaged(
    in_audit_sid        IN    security_pkg.T_SID_ID,
    in_order_by            IN    VARCHAR2, -- redundant but needed for quick list output
    in_start_row        IN    NUMBER,
    in_page_size        IN    NUMBER,
    in_start_date        IN    DATE,
    in_end_date            IN    DATE,
    out_total            OUT    NUMBER,
    out_cur                OUT    SYS_REFCURSOR
)
AS
    v_app_sid security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
    v_permissible_nct_ids    security.T_SID_TABLE := GetPermissibleNCTypeIds(in_audit_sid, security.security_pkg.PERMISSION_READ);
BEGIN
    -- check permission.... new model has this as a capability.
    -- For old model look for write permissions - this includes audit admins and auditor roles but excludes audit contact
    IF IsFlowAudit(in_audit_sid) THEN
        IF NOT HasCapabilityAccess(in_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG, security_pkg.PERMISSION_WRITE) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
        END IF;
    ELSIF NOT HasWriteAccess(in_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    INSERT INTO temp_audit_log_ids(row_id, audit_dtm)
    (SELECT /*+ INDEX (audit_log IDX_AUDIT_LOG_OBJECT_SID) */ rowid, audit_date
       FROM csr.audit_log
      WHERE app_sid = v_app_sid AND object_sid = in_audit_sid
        AND audit_date >= in_start_date AND audit_date < in_end_date + 1
      UNION
     SELECT rowid, audit_date
       FROM csr.audit_log
      WHERE app_sid = v_app_sid AND user_sid = in_audit_sid
        AND audit_date >= in_start_date AND audit_date < in_end_date + 1);

     SELECT COUNT(row_id)
       INTO out_total
       FROM temp_audit_log_ids;


    OPEN out_cur FOR
        -- NOTE: audit log entries related to NC will be filtered out if they require a custom capability which the user does not have.
        --         Since the audit_log table is for general purpose the filtering mechanism is based on 
        --         description starts with 'Finding' (current events logged: Created, Deleted, Closed and Reopened)
        --         and param_2 interpreted as a non_compliance_type_id.

        SELECT al.audit_date, aut.label, cu.user_name, cu.full_name, al.param_1, al.param_2,
               al.param_3, al.description, al.remote_addr
          FROM (SELECT row_id, rn
                  FROM (SELECT row_id, rownum rn
                          FROM (SELECT row_id
                                  FROM temp_audit_log_ids
                              ORDER BY audit_dtm DESC, row_id DESC)
                         WHERE rownum < in_start_row + in_page_size)
                 WHERE rn >= in_start_row) alr
          JOIN audit_log al ON al.rowid = alr.row_id
          JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
          JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id
          LEFT JOIN non_compliance nc ON nc.non_compliance_id = al.param_2
          LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
          WHERE (al.description NOT LIKE 'Finding%' OR (al.param_2 = nc.non_compliance_id AND pnct.column_value = nc.non_compliance_type_id))
      ORDER BY alr.rn;
END;

PROCEDURE GetAuditLogForAudit(
    in_audit_sid        IN    security_pkg.T_SID_ID,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_permissible_nct_ids    security.T_SID_TABLE := GetPermissibleNCTypeIds(in_audit_sid, security.security_pkg.PERMISSION_READ);
BEGIN
    -- check permission.... new model has this as a capability.
    -- For old model look for write permissions - this includes audit admins and auditor roles but excludes audit contact
    IF IsFlowAudit(in_audit_sid) THEN
        IF NOT HasCapabilityAccess(in_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG, security_pkg.PERMISSION_WRITE) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
        END IF;
    ELSIF NOT HasWriteAccess(in_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT audit_date, audit_type_id, LABEL,
            object_sid, full_name, user_name, csr_user_sid, description, NAME, param_1, param_2, param_3, audit_date order_seq, order_seq2
          FROM (
            SELECT ROWNUM rn, x.*
              FROM (
                -- NOTE: audit log entries related to NC will be filtered out if they require a custom capability which the user does not have.
                --         Since the audit_log table is for general purpose the filtering mechanism is based on 
                --         description starts with 'Finding' (current events logged: Created, Deleted, Closed and Reopened)
                --         and param_2 interpreted as a non_compliance_type_id.

                SELECT al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, cu.user_name,
                       cu.csr_user_sid, al.description, so.NAME, al.param_1, al.param_2, al.param_3, al.remote_addr, NULL order_seq2
                  FROM audit_log al
                  JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id
                  JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
                  JOIN SECURITY.securable_object so ON so.sid_id = al.object_sid
                  LEFT JOIN non_compliance nc ON to_char(nc.non_compliance_id) = al.param_2
                  LEFT JOIN TABLE(v_permissible_nct_ids) pnct ON pnct.column_value = nc.non_compliance_type_id
                 WHERE al.app_sid = SYS_CONTEXT('SECURITY','APP')
                   AND nc.non_compliance_id IS NOT NULL
                   AND al.object_sid = in_audit_sid
                   AND al.sub_object_id IS NULL
                   AND (al.description NOT LIKE 'Finding%' OR (al.param_2 = nc.non_compliance_id AND pnct.column_value = nc.non_compliance_type_id))
                ORDER BY al.audit_date DESC    
              )x
            )
         --ORDER BY order_seq DESC
         UNION
        SELECT audit_date, audit_type_id, LABEL,
            object_sid, full_name, user_name, csr_user_sid, description, NAME, param_1, param_2, param_3, audit_date order_seq, order_seq2
          FROM (
            SELECT ROWNUM rn, x.*
              FROM (
                SELECT qss.submitted_dtm audit_date,-1 audit_type_id,'Executive Summary' LABEL,in_audit_sid object_sid, cu.full_name, cu.user_name,
                       cu.csr_user_sid,'Submitted changes' description,NULL NAME,NULL param_1,NULL param_2,NULL param_3, NULL order_seq2
                  FROM internal_audit ia
                  JOIN quick_survey_submission qss
                    ON ia.summary_response_id = qss.survey_response_id
                  JOIN csr_user cu
                    ON qss.submitted_by_user_sid = cu.csr_user_sid
                 WHERE ia.internal_audit_sid = in_audit_sid
                ORDER BY audit_date DESC
              )x
            )
         UNION
        SELECT audit_date, audit_type_id, LABEL,
            object_sid, full_name, user_name, csr_user_sid, description, NAME, param_1, param_2, param_3, audit_date order_seq, order_seq2
          FROM (
            SELECT ROWNUM rn, x.*
              FROM (
                SELECT qss.submitted_dtm audit_date,-1 audit_type_id,'Survey' LABEL,in_audit_sid object_sid, cu.full_name, cu.user_name,
                       cu.csr_user_sid,'Submitted changes' description,NULL NAME,NULL param_1,NULL param_2,NULL param_3, NULL order_seq2
                  FROM internal_audit ia
                  JOIN quick_survey_submission qss
                    ON ia.survey_response_id = qss.survey_response_id
                  JOIN csr_user cu
                    ON qss.submitted_by_user_sid = cu.csr_user_sid
                 WHERE ia.internal_audit_sid = in_audit_sid
                ORDER BY audit_date DESC
              )x
            )
         UNION
        SELECT audit_date, audit_type_id, LABEL,
            object_sid, full_name, user_name, csr_user_sid, description, NAME, param_1, param_2, param_3, audit_date order_seq, order_seq2
          FROM (
            SELECT ROWNUM rn, x.*
              FROM (
                SELECT fsl.set_dtm audit_date,-1 audit_type_id,'Workflow' LABEL,in_audit_sid object_sid, cu.full_name, cu.user_name,
                       cu.csr_user_sid,'Entered state: '||fs.label description,NULL NAME,NULL param_1,NULL param_2,NULL param_3, fsl.flow_state_log_id order_seq2
                  FROM internal_audit ia
                  JOIN flow_state_log fsl
                    ON ia.flow_item_id = fsl.flow_item_id
                  JOIN flow_state fs
                    ON fsl.flow_state_id = fs.flow_state_id
                  JOIN csr_user cu
                    ON fsl.set_by_user_sid = cu.csr_user_sid
                 WHERE ia.internal_audit_sid = in_audit_sid
                ORDER BY audit_date DESC
              )x
            )
         ORDER BY order_seq DESC, order_seq2 DESC;
END;

PROCEDURE GetAuditFlowRoleUsers(
    in_audit_sid                    IN    security_pkg.T_SID_ID,
    out_role_cur                    OUT    security_pkg.T_OUTPUT_CUR,
    out_user_cur                    OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_region_sid                    security_pkg.T_SID_ID;
    v_flow_sid                        security_pkg.T_SID_ID;
    v_current_state_id                security_pkg.T_SID_ID;
BEGIN
    IF NOT (HasReadAccess(in_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_audit_sid);
    END IF;

    SELECT ia.region_sid, fi.flow_sid, fi.current_state_id
      INTO v_region_sid, v_flow_sid, v_current_state_id
      FROM internal_audit ia
      JOIN flow_item fi ON fi.flow_item_id = ia.flow_item_id
     WHERE internal_audit_sid = in_audit_sid;

    OPEN out_role_cur FOR
        SELECT ro.role_sid, ro.name role_name
          FROM flow_state_role fsr
          JOIN flow_state fs ON fs.flow_state_id = fsr.flow_state_id
          JOIN role ro ON ro.role_sid = fsr.role_sid
         WHERE fs.flow_sid = v_flow_sid
           AND fs.flow_state_id = v_current_state_id
         GROUP BY ro.role_sid, ro.name;

    OPEN out_user_cur FOR
        SELECT ro.role_sid, u.user_name, u.full_name, u.email, u.csr_user_sid user_sid
          FROM flow_state_role fsr
          JOIN flow_state fs ON fs.flow_state_id = fsr.flow_state_id
          JOIN role ro ON ro.role_sid = fsr.role_sid
          JOIN region_role_member rrm ON fsr.role_sid = rrm.role_sid AND rrm.region_sid = v_region_sid
          JOIN v$csr_user u ON rrm.user_sid = u.csr_user_sid
         WHERE fs.flow_sid = v_flow_sid
           AND fs.flow_state_id = v_current_state_id
           AND u.active = 1
         GROUP BY ro.role_sid, u.user_name, u.full_name, u.email, u.csr_user_sid;
END;

PROCEDURE GetAuditFlowGroupUsers(
    in_audit_sid                    IN    security_pkg.T_SID_ID,
    out_group_cur                    OUT security_pkg.T_OUTPUT_CUR,
    out_user_cur                    OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_region_sid                    security_pkg.T_SID_ID;
    v_flow_sid                        security_pkg.T_SID_ID;
    v_current_state_id                security_pkg.T_SID_ID;
BEGIN
    IF NOT (HasReadAccess(in_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_audit_sid);
    END IF;

    SELECT ia.region_sid, fi.flow_sid, fi.current_state_id
      INTO v_region_sid, v_flow_sid, v_current_state_id
      FROM internal_audit ia
      JOIN flow_item fi ON fi.flow_item_id = ia.flow_item_id
     WHERE internal_audit_sid = in_audit_sid;

    OPEN out_group_cur FOR
        SELECT fsr.group_sid, so.name group_name
          FROM csr.flow_state_role fsr
          JOIN csr.flow_state fs ON fs.flow_state_id = fsr.flow_state_id
           JOIN security.securable_object so on fsr.group_sid = so.sid_id
         WHERE fs.flow_sid = v_flow_sid
           AND fs.flow_state_id = v_current_state_id
         GROUP BY group_sid, so.name;

    OPEN out_user_cur FOR
        SELECT so.sid_id group_sid, cu.user_name, cu.full_name, cu.email, cu.csr_user_sid user_sid
          FROM security.group_members gm
          JOIN csr.v$csr_user cu ON cu.csr_user_sid = gm.member_sid_id
          JOIN security.securable_object so ON so.sid_id = gm.group_sid_id
          JOIN csr.flow_state_role fsr ON fsr.group_sid = so.sid_id
          JOIN csr.flow_state fs ON fsr.flow_state_id = fs.flow_state_id
         WHERE fs.flow_sid = v_flow_sid
           AND fs.flow_state_id = v_current_state_id
           AND cu.active = 1
         GROUP BY so.sid_id, cu.user_name, cu.full_name, cu.email, cu.csr_user_sid;
END;

-- Called from flow as a state trans helper
PROCEDURE CheckNonCompIssuesClosed(
    in_flow_sid                 IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
    in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
    v_open_issues    NUMBER;
BEGIN
    SELECT COUNT (*)
      INTO v_open_issues
      FROM internal_audit ia
      JOIN non_compliance nc ON nc.created_in_audit_sid = ia.internal_audit_sid
      JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id
      JOIN issue i ON i.issue_non_compliance_id = inc.issue_non_compliance_id
     WHERE i.closed_dtm IS NULL AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL AND i.deleted = 0
       AND ia.flow_item_id = in_flow_item_id;

    IF v_open_issues > 0 THEN
        RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'All Finding issues need to be closed before you can proceed.'); -- i18n??
    END IF;
END;

PROCEDURE GetAuditTags (
    in_audit_sid            IN  security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT (HasReadAccess(in_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_audit_sid);
    END IF;

    OPEN out_cur FOR
        SELECT ia.internal_audit_sid, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag
          FROM internal_audit ia
          JOIN internal_audit_tag at ON ia.internal_audit_sid = at.internal_audit_sid AND ia.app_sid = at.app_sid
          JOIN v$tag t ON at.app_sid = t.app_sid and at.tag_id = t.tag_id
          JOIN tag_group_member tgm ON t.app_sid = tgm.app_sid and t.tag_id = tgm.tag_id
          JOIN v$tag_group tg ON tgm.app_sid = tg.app_sid and tgm.tag_group_id = tg.tag_group_id
         WHERE ia.app_sid = security.security_pkg.GetApp
           AND ia.internal_audit_sid = in_audit_sid;
END;

PROCEDURE GetLockedAuditSurveyTags (
    in_audit_sid            IN  security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT (HasReadAccess(in_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_audit_sid);
    END IF;

    OPEN out_cur FOR
        SELECT internal_audit_sid, tag_group_id, tag_id
          FROM internal_audit_locked_tag
         WHERE app_sid = security.security_pkg.GetApp
           AND internal_audit_sid = in_audit_sid;
END;

PROCEDURE SetLockedAuditSurveyTags (
    in_audit_sid            IN    security_pkg.T_SID_ID,
    in_survey_sid            IN    security_pkg.T_SID_ID,
    in_survey_version        IN    quick_survey_response.survey_version%TYPE DEFAULT NULL,
    in_tag_ids                 IN    security_pkg.T_SID_IDS
)
AS
    v_tag_ids                 security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
    v_version                quick_survey_response.survey_version%TYPE := in_survey_version;
    v_audit_type            internal_audit.internal_audit_type_id%TYPE;
    v_region_type            region.region_type%TYPE;
    v_ra_type_tg_ids        security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
    IF v_version IS NULL THEN
        SELECT current_version
          INTO v_version
          FROM quick_survey
         WHERE survey_sid = in_survey_sid;

        IF v_version IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Cannot get the current published version of survey with sid: '||in_survey_sid||' because it is has not been published.');
        END IF;
    END IF;

    SELECT internal_audit_type_id, region_type
      INTO v_audit_type, v_region_type
      FROM internal_audit ia
      JOIN region r ON ia.region_sid = r.region_sid
     WHERE ia.internal_audit_sid = in_audit_sid;

    SELECT tag_group_id
      BULK COLLECT INTO v_ra_type_tg_ids
      FROM tag_group
     WHERE (applies_to_regions = 1
            AND (tag_group_id IN (SELECT tag_group_id
                                    FROM region_type_tag_group
                                   WHERE region_type = v_region_type)
                 OR tag_group_id NOT IN 
                                 (SELECT tag_group_id
                                    FROM region_type_tag_group)))
        OR (applies_to_audits = 1
            AND (tag_group_id IN (SELECT tag_group_id
                                    FROM internal_audit_type_tag_group
                                   WHERE internal_audit_type_id = v_audit_type)
                 OR tag_group_id NOT IN 
                                 (SELECT tag_group_id
                                    FROM internal_audit_type_tag_group)));

    INSERT INTO internal_audit_locked_tag (internal_audit_sid, tag_group_id, tag_id)
    SELECT in_audit_sid, tgm.tag_group_id, t.column_value
      FROM TABLE(v_tag_ids) t
      JOIN tag_group_member tgm ON tgm.tag_id = t.column_value
     WHERE EXISTS (
            SELECT 1
              FROM quick_survey_question_tag qsqt
              JOIN quick_survey_question qsq ON qsq.question_id = qsqt.question_id
               AND qsq.survey_version = qsqt.survey_version
               AND qsq.survey_sid = in_survey_sid
               AND qsq.survey_version = v_version
              JOIN tag_group_member tgm_survey ON tgm_survey.tag_id = qsqt.tag_id
             WHERE tgm_survey.tag_group_id = tgm.tag_group_id
           )
       AND NOT EXISTS (
                SELECT 1
                  FROM internal_audit_locked_tag ialt
                 WHERE ialt.internal_audit_sid = in_audit_sid
                   AND ialt.tag_group_id = tgm.tag_group_id
           );

    INSERT INTO internal_audit_locked_tag (internal_audit_sid, tag_group_id, tag_id)
    SELECT DISTINCT in_audit_sid, t.column_value, null
      FROM TABLE(v_ra_type_tg_ids) t
      JOIN tag_group_member tgm ON tgm.tag_group_id = t.column_value
     WHERE EXISTS (
            SELECT 1
              FROM quick_survey_question_tag qsqt 
              JOIN quick_survey_question qsq ON qsq.question_id = qsqt.question_id
               AND qsq.survey_version = qsqt.survey_version 
               AND qsq.survey_sid = in_survey_sid
               AND qsq.survey_version = v_version
             WHERE qsqt.tag_id = tgm.tag_id
           )
       AND NOT EXISTS (
                SELECT 1
                  FROM internal_audit_locked_tag ialt
                 WHERE ialt.internal_audit_sid = in_audit_sid
                   AND ialt.tag_group_id = tgm.tag_group_id
           );
END;

PROCEDURE GetNonOverridenAuditRegionTags (
    in_audit_sid            IN  security_pkg.T_SID_ID,
    out_cur                    OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT (HasReadAccess(in_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_audit_sid);
    END IF;

    OPEN out_cur FOR
        SELECT ia.internal_audit_sid, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag
          FROM internal_audit ia
          JOIN region_tag rt on ia.app_sid = rt.app_sid and ia.region_sid = rt.region_sid
          JOIN v$tag t ON rt.app_sid = t.app_sid and rt.tag_id = t.tag_id
          JOIN tag_group_member tgm ON t.app_sid = tgm.app_sid and t.tag_id = tgm.tag_id
          JOIN v$tag_group tg ON tgm.app_sid = tg.app_sid and tgm.tag_group_id = tg.tag_group_id
         WHERE ia.app_sid = security.security_pkg.GetApp
           AND ia.internal_audit_sid = in_audit_sid
           AND (
                    tg.applies_to_audits = 0
                OR ( --tag group applies to audits, but not to the current audit type
                    NOT EXISTS (
                        SELECT 1
                          FROM internal_audit_type_tag_group iattg
                         WHERE iattg.app_sid = ia.app_sid
                           AND iattg.internal_audit_type_id = ia.internal_audit_type_id
                           AND iattg.tag_group_id = tg.tag_group_id
                    ) AND EXISTS (
                        SELECT 1
                          FROM internal_audit_type_tag_group iattg
                         WHERE iattg.app_sid = ia.app_sid
                           AND iattg.internal_audit_type_id <> ia.internal_audit_type_id
                           AND iattg.tag_group_id = tg.tag_group_id
                    )
                )
             );
END;

PROCEDURE GetAuditTabs (
    in_internal_audit_type_id        IN  internal_audit_type.internal_audit_type_id%TYPE,
    in_internal_audit_sid            IN    security_pkg.T_SID_ID,
    out_cur                            OUT SYS_REFCURSOR
)
AS
    v_cms_sid                        security_pkg.T_SID_ID;
    v_available_tabs                security.T_SO_TABLE := security.T_SO_TABLE();
BEGIN
    BEGIN
        v_cms_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'cms');
        v_available_tabs := securableobject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ);
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            NULL;
    END;

    IF NOT IsInCapabilitiesTT(in_internal_audit_sid) THEN
        PopulateAuditCapabilitiesTT(in_internal_audit_sid);
    END IF;

    OPEN out_cur FOR
        SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
               p.details, p.preview_image_path, att.tab_label, att.pos, att.internal_audit_type_id,
               p.tab_sid, p.form_path, p.saved_filter_sid, p.result_mode, p.pre_filter_sid,
               att.flow_capability_id, CASE
                   WHEN att.flow_capability_id IS NULL THEN security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE
                   ELSE NVL(ac.permission_set, 0)
               END permission_set, cfc.perm_type, cfc.description flow_capability_description, p.form_sid
          FROM plugin p
          JOIN audit_type_tab att ON p.plugin_id = att.plugin_id
     LEFT JOIN tt_audit_capability ac ON ac.internal_audit_sid = in_internal_audit_sid AND ac.flow_capability_id = att.flow_capability_id
     LEFT JOIN customer_flow_capability cfc ON cfc.flow_capability_id = att.flow_capability_id
         WHERE att.internal_audit_type_id = in_internal_audit_type_id
           AND (p.tab_sid IS NULL OR p.tab_sid IN (SELECT sid_id FROM TABLE(v_available_tabs)))
           AND (in_internal_audit_sid = 0 OR att.flow_capability_id IS NULL OR ac.permission_set > 0)
         GROUP BY p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
               p.details, p.preview_image_path, att.tab_label, att.pos, att.internal_audit_type_id,
               p.tab_sid, p.form_path, p.saved_filter_sid, p.result_mode, p.pre_filter_sid,
               att.flow_capability_id, ac.permission_set, cfc.perm_type, cfc.description, p.form_sid
         ORDER BY att.pos;
END;

PROCEDURE SetAuditTab (
    in_internal_audit_type_id        IN  audit_type_tab.internal_audit_type_id%TYPE,
    in_js_class                        IN  csr.plugin.js_class%TYPE,
    in_form_path                    IN  csr.plugin.form_path%TYPE,
    in_group_key                    IN  csr.plugin.group_key%TYPE,
    in_pos                            IN  audit_type_tab.pos%TYPE,
    in_tab_label                    IN  audit_type_tab.tab_label%TYPE,
    in_flow_capability_id            IN    audit_type_tab.flow_capability_id%TYPE DEFAULT NULL
)
AS
    v_plugin_id                        csr.plugin.plugin_id%TYPE;
    v_cur                            security_pkg.T_OUTPUT_CUR;
BEGIN
    SELECT plugin_id
      INTO v_plugin_id
      FROM csr.plugin
     WHERE lower(js_class) = lower(in_js_class)
       AND (form_path = in_form_path OR in_form_path IS NULL)
       AND (group_key = in_group_key OR in_group_key IS NULL);

    SetAuditTab (
        in_internal_audit_type_id    => in_internal_audit_type_id,
        in_plugin_id                => v_plugin_id,
        in_pos                        => in_pos,
        in_tab_label                => in_tab_label,
        in_flow_capability_id        => in_flow_capability_id,
        out_cur                        => v_cur
    );
END;

PROCEDURE SetAuditTab(
    in_internal_audit_type_id        IN  audit_type_tab.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_tab.plugin_id%TYPE,
    in_pos                            IN  audit_type_tab.pos%TYPE,
    in_tab_label                    IN  audit_type_tab.tab_label%TYPE,
    in_flow_capability_id            IN    audit_type_tab.flow_capability_id%TYPE DEFAULT NULL,
    out_cur                            OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_pos                            audit_type_tab.pos%TYPE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify audit plugins');
    END IF;

    v_pos := in_pos;

    IF in_pos < 0 THEN
        SELECT NVL(max(pos) + 1, 1)
          INTO v_pos
          FROM audit_type_tab
         WHERE internal_audit_type_id = in_internal_audit_type_id;
    END IF;

    BEGIN
        INSERT INTO audit_type_tab (internal_audit_type_id, plugin_type_id, plugin_id, pos, tab_label, flow_capability_id)
            VALUES (in_internal_audit_type_id, csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB, in_plugin_id, v_pos, in_tab_label, in_flow_capability_id);
    EXCEPTION
        WHEN dup_val_on_index THEN
            UPDATE audit_type_tab
               SET pos = v_pos,
                   tab_label = in_tab_label,
                   flow_capability_id = in_flow_capability_id
             WHERE internal_audit_type_id = in_internal_audit_type_id
               AND plugin_id = in_plugin_id;
    END;

    OPEN out_cur FOR
        SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
               p.details, p.preview_image_path, att.pos, att.tab_label, att.internal_audit_type_id, 
               p.form_path, att.flow_capability_id, p.form_sid
          FROM plugin p
          JOIN audit_type_tab att ON p.plugin_id = att.plugin_id
         WHERE att.internal_audit_type_id = in_internal_audit_type_id
           AND att.plugin_id = in_plugin_id;
END;

PROCEDURE RemoveAuditTab(
    in_internal_audit_type_id        IN  audit_type_tab.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_tab.plugin_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify audit plugins');
    END IF;

    DELETE FROM audit_type_tab
     WHERE internal_audit_type_id = in_internal_audit_type_id
       AND plugin_id = in_plugin_id;
END;

PROCEDURE GetAuditHeaders (
    in_internal_audit_type_id        IN  internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                            OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
               p.details, p.preview_image_path, ath.pos, ath.internal_audit_type_id, p.form_path, p.form_sid
          FROM plugin p
          JOIN audit_type_header ath ON p.plugin_id = ath.plugin_id
         WHERE ath.internal_audit_type_id = in_internal_audit_type_id
         GROUP BY p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
               p.details, p.preview_image_path, ath.pos, ath.internal_audit_type_id, p.form_path, p.form_sid
         ORDER BY ath.pos;
END;

PROCEDURE SetAuditHeader(
    in_internal_audit_type_id        IN  audit_type_header.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_header.plugin_id%TYPE,
    in_pos                            IN  audit_type_header.pos%TYPE,
    out_cur                            OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_pos                             audit_type_header.pos%TYPE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify audit plugins');
    END IF;

    v_pos := in_pos;

    IF in_pos < 0 THEN
        SELECT NVL(max(pos) + 1, 1)
          INTO v_pos
          FROM audit_type_header
         WHERE internal_audit_type_id = in_internal_audit_type_id;
    END IF;

    BEGIN
        INSERT INTO audit_type_header (internal_audit_type_id, plugin_type_id, plugin_id, pos)
            VALUES (in_internal_audit_type_id, csr_data_pkg.PLUGIN_TYPE_AUDIT_HEADER, in_plugin_id, v_pos);
    EXCEPTION
        WHEN dup_val_on_index THEN
            UPDATE audit_type_header
               SET pos = v_pos
             WHERE internal_audit_type_id = in_internal_audit_type_id
               AND plugin_id = in_plugin_id;
    END;

    OPEN out_cur FOR
        SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
               p.details, p.preview_image_path, ath.pos, ath.internal_audit_type_id, p.form_path, p.form_sid
          FROM plugin p
          JOIN audit_type_header ath ON p.plugin_id = ath.plugin_id
         WHERE ath.internal_audit_type_id = in_internal_audit_type_id
           AND ath.plugin_id = in_plugin_id;
END;

PROCEDURE RemoveAuditHeader(
    in_internal_audit_type_id        IN  audit_type_header.internal_audit_type_id%TYPE,
    in_plugin_id                    IN  audit_type_header.plugin_id%TYPE
)
AS
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify audit plugins');
    END IF;

    DELETE FROM audit_type_header
     WHERE internal_audit_type_id = in_internal_audit_type_id
       AND plugin_id = in_plugin_id;
END;

PROCEDURE GetAuditorRegions(
    in_search_phrase                IN    VARCHAR2,
    in_modified_since_dtm            IN    audit_log.audit_date%TYPE,
    in_show_inactive                IN    NUMBER,
    out_cur                            OUT SYS_REFCURSOR
)
AS
    v_table                    security.T_SID_TABLE := GetAuditsForUserAsTable;
BEGIN
    -- This lets the user see regions outside their region start point
    -- so that third-party auditors can see regions that they are auditing.
    OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/ r.region_sid sid_id, r.parent_sid parent_sid_id, r.description, r.geo_city_id,
               r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
               r.region_type, r.active, rt.class_name,
               lookup_key, region_ref, disposal_dtm, acquisition_dtm, info_xml, last_modified_dtm,
               CASE WHEN sr.region_sid IS NULL THEN 1 ELSE 0 END is_primary
          FROM v$resolved_region_description r
          JOIN region_type rt ON r.region_type = rt.region_type
          JOIN internal_audit ia ON ia.region_sid = r.region_sid
          JOIN TABLE( v_table ) so ON ia.internal_audit_sid = so.column_value
          LEFT JOIN (
                  SELECT srr.region_sid
                    FROM region srr
                    LEFT JOIN region_tree srrt ON srrt.region_tree_root_sid = srr.region_sid
                   START WITH srrt.is_primary = 0
                 CONNECT BY PRIOR srr.region_sid = srr.parent_sid
          ) sr ON sr.region_sid = r.region_sid
         WHERE (in_modified_since_dtm IS NULL OR r.last_modified_dtm >= in_modified_since_dtm)
           AND (in_search_phrase IS NULL OR (
                    LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'
                    OR UPPER(region_ref) = UPPER(in_search_phrase) -- exact match
               ))
           AND (in_show_inactive = 1 OR r.active = 1);
END;

PROCEDURE GetResponseToAudit (
    in_survey_response_id            IN    quick_survey_response.survey_response_id%TYPE,
    out_cur                            OUT SYS_REFCURSOR
)
AS
    v_response_access        NUMBER := quick_survey_pkg.GetResponseAccess(in_survey_response_id);
BEGIN
    IF v_response_access != security_pkg.PERMISSION_READ AND v_response_access != security_pkg.PERMISSION_WRITE THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to response: '||in_survey_response_id);
    END IF;

    OPEN out_cur FOR
        SELECT qsr.survey_response_id, qsr.survey_sid, qs.auditing_audit_type_id, srr.region_sid,
               iat.label auditing_audit_type_label, r.description region_description,
               qs.label survey_label
          FROM quick_survey_response qsr
          JOIN v$quick_survey qs ON qsr.survey_sid = qs.survey_sid
          JOIN internal_audit_type iat ON qs.auditing_audit_type_id = iat.internal_audit_type_id
          LEFT JOIN (
                SELECT ssr.survey_response_id, s.region_sid
                  FROM supplier_survey_response ssr
                  JOIN supplier s ON ssr.supplier_sid = s.company_sid
                 UNION
                SELECT rsr.survey_response_id, rsr.region_sid
                  FROM region_survey_response rsr ) srr
            ON srr.survey_response_id = qsr.survey_response_id
          JOIN v$region r ON srr.region_sid = r.region_sid
         WHERE qsr.survey_response_id = in_survey_response_id;
END;

PROCEDURE GetAuditsWithAllIssuesClosed(
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_open_issues    NUMBER;
BEGIN

    alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_AUDIT_ALL_ISSUES_CLOSED);

    OPEN out_cur FOR
        SELECT ia.app_sid, ia.auditor_user_sid, r.description region_description, ia.label, ia.internal_audit_sid
          FROM internal_audit ia
          JOIN v$region r on ia.region_sid = r.region_sid and ia.app_sid = r.app_sid
          JOIN customer_alert_type cat ON ia.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_AUDIT_ALL_ISSUES_CLOSED
          JOIN temp_alert_batch_run tabr ON ia.auditor_user_sid = tabr.csr_user_sid AND ia.app_sid = tabr.app_sid
          JOIN (
            SELECT anc.app_sid, anc.internal_audit_sid, COUNT(*) total_count, COUNT(i.closed_dtm) closed_count, MAX(i.closed_dtm) max_closed_dtm
              from audit_non_compliance anc
              JOIN issue_non_compliance inc ON inc.app_sid = anc.app_sid AND inc.non_compliance_id = anc.non_compliance_id
              JOIN issue i ON i.app_sid = inc.app_sid AND i.issue_non_compliance_id = inc.issue_non_compliance_id
             WHERE i.deleted = 0
             GROUP BY anc.app_sid, anc.internal_audit_sid
            ) closed_audits ON ia.app_sid = closed_audits.app_sid AND ia.internal_audit_sid = closed_audits.internal_audit_sid
          LEFT JOIN (
            SELECT app_sid, internal_audit_sid, csr_user_sid, max(alert_sent_dtm) max_alert_sent_dtm
              FROM audit_iss_all_closed_alert
             GROUP BY app_sid, internal_audit_sid, csr_user_sid
            ) sent_alerts ON ia.app_sid = sent_alerts.app_sid AND ia.internal_audit_sid = sent_alerts.internal_audit_sid AND ia.auditor_user_sid = sent_alerts.csr_user_sid
         WHERE ia.deleted = 0
           AND closed_audits.total_count = closed_audits.closed_count
           AND (sent_alerts.max_alert_sent_dtm IS NULL OR sent_alerts.max_alert_sent_dtm<closed_audits.max_closed_dtm)
           AND tabr.this_fire_time > closed_audits.max_closed_dtm
           AND tabr.std_alert_type_id = csr_data_pkg.ALERT_AUDIT_ALL_ISSUES_CLOSED
        ORDER BY ia.app_sid ASC, ia.auditor_user_sid ASC;
END;

PROCEDURE RecordAuditAllIssuesClosed(
    in_app_sid                IN  audit_iss_all_closed_alert.app_sid%TYPE,
    in_internal_audit_sid    IN    audit_iss_all_closed_alert.internal_audit_sid%TYPE,
    in_user_sid                IN    audit_iss_all_closed_alert.CSR_USER_SID%TYPE
)
AS
BEGIN
    INSERT INTO audit_iss_all_closed_alert (app_sid, internal_audit_sid, csr_user_sid, alert_sent_dtm)
    VALUES (in_app_sid, in_internal_audit_sid, in_user_sid, SYSDATE);
END;

PROCEDURE GetNonComplianceTypes(
    out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR 
        SELECT non_compliance_type_id, label, lookup_key, position, colour_when_open,
               colour_when_closed, can_have_actions, closure_behaviour_id,
               score, repeat_score, root_cause_enabled, suggested_action_enabled,
               match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
               find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type, is_default_survey_finding,
               NVL2 (flow_capability_id, 1, 0) is_flow_capability_enabled
          FROM non_compliance_type
         WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE GetNonComplianceTypes (
    in_internal_audit_type_id        IN  non_comp_type_audit_type.internal_audit_type_id%TYPE DEFAULT NULL,
    out_cur                            OUT    security_pkg.T_OUTPUT_CUR,
    out_audit_type_cur                OUT    security_pkg.T_OUTPUT_CUR,
    out_repeat_audit_type_cur        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_type_ids                        security.T_SID_TABLE;
BEGIN
    SELECT non_compliance_type_id
      BULK COLLECT INTO v_type_ids
      FROM non_compliance_type
     WHERE app_sid = security_pkg.GetApp
       AND (in_internal_audit_type_id IS NULL
        OR non_compliance_type_id IN (
            SELECT non_compliance_type_id
              FROM non_comp_type_audit_type
             WHERE internal_audit_type_id = in_internal_audit_type_id
        ));

    OPEN out_cur FOR
        SELECT non_compliance_type_id, label, lookup_key, position, colour_when_open,
               colour_when_closed, can_have_actions, closure_behaviour_id,
               score, repeat_score, root_cause_enabled, suggested_action_enabled,
               match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
               find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type,
               is_default_survey_finding, flow_capability_id,
               NVL2 (flow_capability_id, 1, 0) is_flow_capability_enabled
          FROM non_compliance_type
          JOIN TABLE (v_type_ids) t ON non_compliance_type_id = t.column_value
         ORDER BY position, label;

    OPEN out_audit_type_cur FOR
        SELECT internal_audit_type_id, non_compliance_type_id
          FROM non_comp_type_audit_type
          JOIN TABLE (v_type_ids) t ON non_compliance_type_id = t.column_value;

    OPEN out_repeat_audit_type_cur FOR
        SELECT internal_audit_type_id, non_compliance_type_id
          FROM non_comp_type_rpt_audit_type
          JOIN TABLE (v_type_ids) t ON non_compliance_type_id = t.column_value;
END;

PROCEDURE SetNonComplianceType (
    in_non_compliance_type_id            IN  non_compliance_type.non_compliance_type_id%TYPE,
    in_label                            IN  non_compliance_type.label%TYPE,
    in_lookup_key                        IN  non_compliance_type.lookup_key%TYPE,
    in_position                            IN  non_compliance_type.position%TYPE,
    in_colour_when_open                    IN  non_compliance_type.colour_when_open%TYPE,
    in_colour_when_closed                IN  non_compliance_type.colour_when_closed%TYPE,
    in_can_have_actions                    IN  non_compliance_type.can_have_actions%TYPE,
    in_closure_behaviour_id                IN  non_compliance_type.closure_behaviour_id%TYPE,
    in_score                            IN    non_compliance_type.score%TYPE DEFAULT NULL,
    in_repeat_score                        IN    non_compliance_type.repeat_score%TYPE DEFAULT NULL,
    in_root_cause_enabled                IN    non_compliance_type.root_cause_enabled%TYPE DEFAULT 0,
    in_suggested_action_enabled            IN    non_compliance_type.suggested_action_enabled%TYPE DEFAULT 0,
    in_match_repeats_by_carry_fwd        IN    non_compliance_type.match_repeats_by_carry_fwd%TYPE DEFAULT 0,        
    in_match_repeats_by_dflt_ncs        IN    non_compliance_type.match_repeats_by_default_ncs%TYPE DEFAULT 0,    
    in_match_repeats_by_surveys            IN    non_compliance_type.match_repeats_by_surveys%TYPE DEFAULT 0,
    in_find_repeats_in_unit                IN    non_compliance_type.find_repeats_in_unit%TYPE DEFAULT NCT_RPT_MATCH_UNIT_NONE,
    in_find_repeats_in_qty                IN    non_compliance_type.find_repeats_in_qty%TYPE DEFAULT NULL,
    in_carry_fwd_repeat_type            IN    non_compliance_type.carry_fwd_repeat_type%TYPE DEFAULT NCT_CARRY_FWD_RPT_TYPE_NORMAL,
    in_is_default_survey_finding        IN    non_compliance_type.is_default_survey_finding%TYPE DEFAULT 0,
    in_is_flow_capability_enabled        IN    NUMBER    DEFAULT 0,
    in_repeat_audit_type_ids            IN    security_pkg.T_SID_IDS,
    out_non_compliance_type_id            OUT    non_compliance_type.non_compliance_type_id%TYPE
)
AS
    v_audits_sid                    security_pkg.T_SID_ID;
    v_find_repeats_in_unit            non_compliance_type.find_repeats_in_unit%TYPE := NVL(in_find_repeats_in_unit, NCT_RPT_MATCH_UNIT_NONE);
    v_find_repeats_in_qty            non_compliance_type.find_repeats_in_unit%TYPE := in_find_repeats_in_qty;
    v_carry_fwd_repeat_type            non_compliance_type.carry_fwd_repeat_type%TYPE := NVL(in_carry_fwd_repeat_type, NCT_CARRY_FWD_RPT_TYPE_NORMAL);
    v_repeat_audit_type_tbl            security.T_SID_TABLE;
    v_finding_type_capability_id    non_compliance_type.flow_capability_id%TYPE;
    v_existing_flow_capability_id    non_compliance_type.non_compliance_type_id%TYPE;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update finding types');
    END IF;

    IF v_find_repeats_in_unit IN (NCT_RPT_MATCH_UNIT_NONE, NCT_RPT_MATCH_UNIT_ALL) THEN
        v_find_repeats_in_qty := NULL;
    ELSE
        v_find_repeats_in_qty := GREATEST(NVL(v_find_repeats_in_qty, 1), 1);
    END IF;

    IF (in_non_compliance_type_id IS NOT NULL) THEN
        SELECT flow_capability_id
          INTO v_existing_flow_capability_id
          FROM non_compliance_type
         WHERE non_compliance_type_id = in_non_compliance_type_id;
    END IF;

    IF (in_is_flow_capability_enabled = 1 AND (in_non_compliance_type_id IS NULL OR v_existing_flow_capability_id IS NULL)) THEN
        csr.flow_pkg.SaveCustomerFlowCapability(
            in_flow_capability_id    => NULL,
            in_flow_alert_class        => 'audit',
            in_description            => in_label,
            in_perm_type            => csr.csr_data_pkg.FLOW_CAP_SPECIFIC_PERMISSION,
            in_copy_capability_id    => csr.csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL,
            in_is_system_managed    => 1,
            out_flow_capability_id    => v_finding_type_capability_id
        );
        ELSE
            v_finding_type_capability_id := v_existing_flow_capability_id;
    END IF;

    IF in_non_compliance_type_id IS NULL THEN

        INSERT INTO non_compliance_type (non_compliance_type_id, label, lookup_key, position, colour_when_open,
                                        colour_when_closed, can_have_actions, closure_behaviour_id,
                                        score, repeat_score, root_cause_enabled, suggested_action_enabled,
                                        match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
                                        find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type, is_default_survey_finding, flow_capability_id)
             VALUES (non_compliance_type_id_seq.NEXTVAL, in_label, in_lookup_key, in_position, in_colour_when_open,
                     in_colour_when_closed, in_can_have_actions, in_closure_behaviour_id,
                     in_score, in_repeat_score, in_root_cause_enabled, in_suggested_action_enabled,
                     in_match_repeats_by_carry_fwd, in_match_repeats_by_dflt_ncs, in_match_repeats_by_surveys,
                     v_find_repeats_in_unit, v_find_repeats_in_qty, v_carry_fwd_repeat_type, in_is_default_survey_finding, v_finding_type_capability_id)
          RETURNING non_compliance_type_id INTO out_non_compliance_type_id;

        -- link to all exising audit types by default
        INSERT INTO non_comp_type_audit_type (internal_audit_type_id, non_compliance_type_id)
             SELECT internal_audit_type_id, out_non_compliance_type_id
               FROM internal_audit_type;
    ELSE
        UPDATE non_compliance_type
           SET label = in_label,
               lookup_key = in_lookup_key,
               position = in_position,
               colour_when_open = in_colour_when_open,
               colour_when_closed = in_colour_when_closed,
               can_have_actions = in_can_have_actions,
               closure_behaviour_id = in_closure_behaviour_id,
               score = in_score,
               repeat_score = in_repeat_score,
               root_cause_enabled = in_root_cause_enabled,
               suggested_action_enabled = in_suggested_action_enabled,
               match_repeats_by_carry_fwd = in_match_repeats_by_carry_fwd,
               match_repeats_by_default_ncs = in_match_repeats_by_dflt_ncs,    
               match_repeats_by_surveys = in_match_repeats_by_surveys,
               find_repeats_in_unit = v_find_repeats_in_unit,
               find_repeats_in_qty = v_find_repeats_in_qty,
               carry_fwd_repeat_type = v_carry_fwd_repeat_type,
               is_default_survey_finding = in_is_default_survey_finding,
               flow_capability_id = v_finding_type_capability_id
         WHERE non_compliance_type_id = in_non_compliance_type_id;

        out_non_compliance_type_id := in_non_compliance_type_id;
    
        DELETE FROM non_comp_type_rpt_audit_type
        WHERE non_compliance_type_id = out_non_compliance_type_id;
    END IF;

    IF v_find_repeats_in_unit != NCT_RPT_MATCH_UNIT_NONE AND in_repeat_audit_type_ids IS NOT NULL THEN
        v_repeat_audit_type_tbl := security_pkg.SidArrayToTable(in_repeat_audit_type_ids);
        
        INSERT INTO non_comp_type_rpt_audit_type (non_compliance_type_id, internal_audit_type_id)
        SELECT out_non_compliance_type_id, column_value FROM TABLE(v_repeat_audit_type_tbl);
    END IF;

    FOR r IN (
        SELECT anc.internal_audit_sid
          FROM audit_non_compliance anc
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
         WHERE nc.non_compliance_type_id = out_non_compliance_type_id
      GROUP BY anc.internal_audit_sid
    ) LOOP
        RecalculateAuditNCScore(r.internal_audit_sid);
    END LOOP;
END;

PROCEDURE DeleteNonComplianceType (
    in_non_compliance_type_id        IN  non_compliance_type.non_compliance_type_id%TYPE
)
AS
    v_audits_sid                    security_pkg.T_SID_ID;
    v_finding_type_capability_id    non_compliance_type.flow_capability_id%TYPE;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot delete finding types');
    END IF;

    SELECT flow_capability_id
    INTO v_finding_type_capability_id
    FROM non_compliance_type
    WHERE non_compliance_type_id = in_non_compliance_type_id;

    IF v_finding_type_capability_id IS NOT NULL THEN
        UPDATE non_compliance_type
        SET flow_capability_id = NULL
        WHERE non_compliance_type_id = in_non_compliance_type_id;

        csr.flow_pkg.DeleteCustomerFlowCapability(
            in_flow_capability_id    => v_finding_type_capability_id
        );
    END IF;

    UPDATE non_comp_default
       SET non_compliance_type_id = NULL
     WHERE non_compliance_type_id = in_non_compliance_type_id;

    UPDATE qs_expr_non_compl_action
       SET non_compliance_type_id = NULL
     WHERE non_compliance_type_id = in_non_compliance_type_id;

    DELETE FROM non_comp_type_audit_type
          WHERE non_compliance_type_id = in_non_compliance_type_id
            AND app_sid = security_pkg.GetApp;
            
    DELETE FROM non_comp_type_rpt_audit_type
          WHERE non_compliance_type_id = in_non_compliance_type_id
            AND app_sid = security_pkg.GetApp;

    DELETE FROM non_compliance_type
          WHERE non_compliance_type_id = in_non_compliance_type_id
            AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SetAuditTypeNonCompType (
    in_internal_audit_type_id    IN  non_comp_type_audit_type.internal_audit_type_id%TYPE,
    in_non_compliance_type_id    IN  non_comp_type_audit_type.non_compliance_type_id%TYPE
)
AS
v_audits_sid                    security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot link audit type to non-compliance type');
    END IF;

    BEGIN
        INSERT INTO non_comp_type_audit_type (internal_audit_type_id, non_compliance_type_id)
             VALUES (in_internal_audit_type_id, in_non_compliance_type_id);
    EXCEPTION
        WHEN dup_val_on_index THEN
            NULL;
    END;
END;

PROCEDURE DeleteAuditTypeNonCompType (
    in_internal_audit_type_id    IN  non_comp_type_audit_type.internal_audit_type_id%TYPE,
    in_non_compliance_type_id    IN  non_comp_type_audit_type.non_compliance_type_id%TYPE
)
AS
    v_audits_sid                    security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot remove link from audit type to non-compliance type');
    END IF;

    DELETE FROM non_comp_type_audit_type
     WHERE internal_audit_type_id = in_internal_audit_type_id
       AND non_compliance_type_id = in_non_compliance_type_id
       AND app_sid = security_pkg.GetApp;
END;

FUNCTION GetNonComplianceTypeId (
    in_nc_type_label            IN    NVARCHAR2,
    in_audit_sid                IN    security.security_pkg.T_SID_ID
) RETURN NUMBER
AS
    v_nc_type_id                NUMBER;
BEGIN
    BEGIN
        SELECT DISTINCT nct.non_compliance_type_id
          INTO v_nc_type_id
          FROM non_compliance_type nct
          JOIN non_comp_type_audit_type nctat ON nct.non_compliance_type_id = nctat.non_compliance_type_id
          JOIN internal_audit ia ON ia.internal_audit_type_id = nctat.internal_audit_type_id
         WHERE (UPPER(nct.label) = UPPER(in_nc_type_label) OR UPPER(nct.lookup_key) = UPPER(in_nc_type_label))
           AND (ia.internal_audit_sid = in_audit_sid);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_nc_type_id := 0;
    END;
    RETURN v_nc_type_id;
END;


PROCEDURE GetRepeatAuditNC(
    in_audit_non_compliance_id    IN    audit_non_compliance.audit_non_compliance_id%TYPE,
    out_audit_non_compliance_id    OUT    audit_non_compliance.audit_non_compliance_id%TYPE
)
AS
    v_audit_non_compliance_id        audit_non_compliance.audit_non_compliance_id%TYPE := in_audit_non_compliance_id;
    v_carried_from_audit_nc_id        audit_non_compliance.audit_non_compliance_id%TYPE;

    v_audit_dtm                        internal_audit.audit_dtm%TYPE;
    v_region_sid                    security_pkg.T_SID_ID;
    v_non_compliance_id                non_compliance.non_compliance_id%TYPE;
    v_from_non_comp_default_id        non_compliance.from_non_comp_default_id%TYPE;
    v_question_id                    non_compliance.question_id%TYPE;
    v_expr_action_id                non_compliance_expr_action.qs_expr_non_compl_action_id%TYPE;
    v_repeat_audit_type_tbl            security.T_SID_TABLE;

    CURSOR v_cfg_cur IS
        SELECT nct.non_compliance_type_id,
               match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
               find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type
          FROM non_compliance_type nct
          JOIN non_compliance nc ON nc.non_compliance_type_id = nct.non_compliance_type_id
          JOIN audit_non_compliance anc ON anc.non_compliance_id = nc.non_compliance_id
         WHERE anc.audit_non_compliance_id = in_audit_non_compliance_id;

    v_cfg v_cfg_cur%ROWTYPE;
BEGIN
    -- get the config from the non-compliance
    OPEN v_cfg_cur;
    FETCH v_cfg_cur INTO v_cfg;
    IF v_cfg_cur%NOTFOUND OR v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_NONE THEN
        out_audit_non_compliance_id := NULL;
        RETURN;
    END IF;

    -- find the original audit NC, if it's still there
    BEGIN
        SELECT cianc.audit_non_compliance_id
          INTO v_carried_from_audit_nc_id
          FROM audit_non_compliance anc
          JOIN audit_non_compliance cianc ON cianc.non_compliance_id = anc.non_compliance_id
          JOIN non_compliance nc ON nc.non_compliance_id = cianc.non_compliance_id
                                AND nc.created_in_audit_sid = cianc.internal_audit_sid
         WHERE anc.audit_non_compliance_id = in_audit_non_compliance_id;
    EXCEPTION
        WHEN no_data_found THEN
            v_carried_from_audit_nc_id := in_audit_non_compliance_id;
    END;

    -- if this is a carried-forward audit, find out what to do.
    IF v_audit_non_compliance_id != v_carried_from_audit_nc_id THEN
        IF v_cfg.carry_fwd_repeat_type = 'as_created' THEN
            v_audit_non_compliance_id := v_carried_from_audit_nc_id;
        ELSIF v_cfg.carry_fwd_repeat_type = 'never' THEN
            out_audit_non_compliance_id := NULL;
            RETURN;
        END IF;
    END IF;

    BEGIN
        -- get the things we could match against
        SELECT ia.audit_dtm, ia.region_sid,
               nc.non_compliance_id, nc.from_non_comp_default_id, nc.question_id,
               ncea.qs_expr_non_compl_action_id
          INTO v_audit_dtm, v_region_sid, 
               v_non_compliance_id, v_from_non_comp_default_id, v_question_id,
               v_expr_action_id
          FROM audit_non_compliance anc
          JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
          JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
          LEFT JOIN non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id
         WHERE anc.audit_non_compliance_id = v_audit_non_compliance_id;
        
        SELECT internal_audit_type_id
          BULK COLLECT INTO v_repeat_audit_type_tbl
          FROM non_comp_type_rpt_audit_type nctrat
         WHERE non_compliance_type_id = v_cfg.non_compliance_type_id;

        -- if there are no audit types, that's the same as all the audit types
        IF v_repeat_audit_type_tbl.count = 0 THEN
            SELECT internal_audit_type_id
              BULK COLLECT INTO v_repeat_audit_type_tbl
              FROM internal_audit_type;
        END IF;

        WITH eligible_audits AS (
            SELECT internal_audit_sid, audit_dtm, region_sid
              FROM (
                SELECT internal_audit_sid, audit_dtm, region_sid,
                       CASE WHEN v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_AUDITS THEN
                            ROW_NUMBER() OVER (PARTITION BY region_sid ORDER BY audit_dtm DESC, internal_audit_sid DESC) 
                       END audit_number
                  FROM internal_audit ia
                  JOIN TABLE(v_repeat_audit_type_tbl) rat ON ia.internal_audit_type_id = rat.column_value
                 WHERE ia.audit_dtm < v_audit_dtm
                   AND ia.deleted = 0
                   AND ia.region_sid = v_region_sid
              ) ia WHERE (
                    v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_ALL OR
                    (v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_AUDITS AND ia.audit_number <= v_cfg.find_repeats_in_qty) OR
                    (v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_MONTHS AND ia.audit_dtm >= ADD_MONTHS(v_audit_dtm, -1 * v_cfg.find_repeats_in_qty)) OR
                    (v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_YEARS AND ia.audit_dtm >= ADD_MONTHS(v_audit_dtm, -12 * v_cfg.find_repeats_in_qty))
               )
        )
        SELECT audit_non_compliance_id
          INTO out_audit_non_compliance_id
          FROM (
            SELECT audit_non_compliance_id, ROWNUM rn
              FROM (
                SELECT anc.audit_non_compliance_id
                  FROM audit_non_compliance anc
                  JOIN eligible_audits ia ON ia.internal_audit_sid = anc.internal_audit_sid
                  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
                  LEFT JOIN non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id AND nc.app_sid = ncea.app_sid
                 WHERE (
                        (v_cfg.match_repeats_by_carry_fwd = 1 AND nc.non_compliance_id = v_non_compliance_id) OR
                        (v_cfg.match_repeats_by_default_ncs = 1 AND nc.from_non_comp_default_id = v_from_non_comp_default_id) OR
                        (v_cfg.match_repeats_by_surveys = 1 AND (nc.question_id = v_question_id OR ncea.qs_expr_non_compl_action_id = v_expr_action_id))
                   )
                 ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC
              )
          ) WHERE rn = 1;
    EXCEPTION
        WHEN no_data_found THEN
            out_audit_non_compliance_id := NULL;
    END;
END;

PROCEDURE RecalculateAuditNCScore(
    in_internal_audit_sid            IN  security_pkg.T_SID_ID
)
AS
    v_repeat_of_audit_nc_id            audit_non_compliance.audit_non_compliance_id%TYPE;
    v_score_type_id                    score_type.score_type_id%TYPE;
    v_min_score                        score_type.min_score%TYPE;
    v_max_score                        score_type.max_score%TYPE;
    v_score                            score_type.start_score%TYPE;
    v_normalise_to_max_score        score_type.normalise_to_max_score%TYPE;
    v_applies_to_supplier            score_type.applies_to_supplier%TYPE;
BEGIN
    -- if we do this in one statement, we get ORA-04091, so we do it in a loop instead.
    FOR r IN (
        SELECT anc.audit_non_compliance_id
          FROM audit_non_compliance anc
         WHERE anc.internal_audit_sid = in_internal_audit_sid
    ) LOOP
        GetRepeatAuditNC(r.audit_non_compliance_id, v_repeat_of_audit_nc_id);

        UPDATE audit_non_compliance anc
           SET anc.repeat_of_audit_nc_id = v_repeat_of_audit_nc_id
         WHERE anc.audit_non_compliance_id = r.audit_non_compliance_id;
    END LOOP;

    BEGIN
        SELECT nc_score_type_id
          INTO v_score_type_id
          FROM internal_audit ia
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
         WHERE ia.internal_audit_sid = in_internal_audit_sid;
    EXCEPTION
        WHEN no_data_found THEN
            v_score_type_id := NULL;
    END;

    IF v_score_type_id IS NULL THEN
        v_score := NULL;
    ELSE
        SELECT min_score, max_score, start_score, normalise_to_max_score, applies_to_supplier
          INTO v_min_score, v_max_score, v_score, v_normalise_to_max_score, v_applies_to_supplier
          FROM score_type
         WHERE score_type_id = v_score_type_id;

        FOR r IN (
            SELECT anc.repeat_of_audit_nc_id, nct.score, nct.repeat_score, nc.override_score
              FROM audit_non_compliance anc
              JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
              JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
             WHERE anc.internal_audit_sid = in_internal_audit_sid
        ) LOOP
            -- TODO: override_score should live on audit_non_compliance
            IF r.override_score IS NOT NULL THEN
                v_score := v_score + r.override_score;
            ELSE
                IF r.repeat_of_audit_nc_id IS NULL THEN
                    v_score := v_score + NVL(r.score, 0);
                ELSE
                    v_score := v_score + NVL(r.repeat_score, NVL(r.score, 0));
                END IF;
            END IF;
        END LOOP;

        IF v_max_score IS NOT NULL AND v_score > v_max_score THEN
            v_score := v_max_score;
        END IF;

        IF v_min_score IS NOT NULL AND v_score < v_min_score THEN
            v_score := v_min_score;
        END IF;

        IF v_max_score IS NOT NULL AND v_normalise_to_max_score = 1 THEN
            v_score := v_score / v_max_score;
        END IF;

    END IF;

    UPDATE internal_audit
       SET nc_score = v_score
     WHERE internal_audit_sid = in_internal_audit_sid;

     RecalculateAuditNCScoreThrsh(in_internal_audit_sid);

    -- call helper pkg
    INTERNAL_CallHelperPkg('AuditScoreUpdated', in_internal_audit_sid);
END;

PROCEDURE RecalculateAuditNCScoreThrsh(
    in_internal_audit_sid            IN  security_pkg.T_SID_ID
)
AS
    v_score_type_id                    score_type.score_type_id%TYPE;
    v_score                            score_type.start_score%TYPE;
    v_score_threshold_id            score_threshold.score_threshold_id%TYPE;
BEGIN
    BEGIN
        SELECT iat.nc_score_type_id, ia.nc_score
          INTO v_score_type_id, v_score
          FROM internal_audit ia
          JOIN internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
         WHERE ia.internal_audit_sid = in_internal_audit_sid;
    EXCEPTION
        WHEN no_data_found THEN
            v_score_type_id := NULL;
            v_score := NULL;
    END;

    IF v_score_type_id IS NULL OR v_score IS NULL THEN
        v_score_threshold_id := NULL;
    ELSE
        v_score_threshold_id := quick_survey_pkg.GetThresholdFromScore(v_score_type_id, v_score);
    END IF;

    UPDATE internal_audit
       SET nc_score_thrsh_id = v_score_threshold_id
     WHERE internal_audit_sid = in_internal_audit_sid;
END;

PROCEDURE IsAuditDeletable(
    in_internal_audit_sid    IN    internal_audit.internal_audit_sid%TYPE,
    out_is_deletable        OUT NUMBER
)
AS
    v_closed_count            NUMBER := 0;
    v_total_count            NUMBER := 0;
BEGIN

    out_is_deletable := 0;

    SELECT COUNT(i.closed_dtm) closed_issues, COUNT(*) total_issues
      INTO v_closed_count, v_total_count
      FROM internal_audit ia
      JOIN audit_non_compliance anc ON anc.internal_audit_sid = ia.internal_audit_sid
      JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
      JOIN issue_non_compliance inc ON inc.non_compliance_id = nc.non_compliance_id
      JOIN issue i ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.deleted = 0
     WHERE ia.internal_audit_sid = in_internal_audit_sid
       AND ia.app_sid = SYS_CONTEXT('SECURITY', 'APP');

    IF v_total_count = v_closed_count THEN
        out_is_deletable := 1;
    END IF;

END;

PROCEDURE OverwriteNCScoreThreshold(
    in_internal_audit_sid    IN    internal_audit.internal_audit_sid%TYPE,
    in_score_threshold_id    IN    score_threshold.score_threshold_id%TYPE
)
AS
    v_count                    NUMBER(10) := 0;
    v_manual_set            NUMBER(1);
    v_score_type_id            NUMBER(10);
    v_score_threshold_id    NUMBER(10) := in_score_threshold_id;
BEGIN
    IF NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied overwriting score threshold for audit.');
    END IF;

    --check to make sure the score threshold we're trying to set exists in the score type associated with the audit, and that allow manual set is on
    BEGIN
        SELECT st.allow_manual_set, st.score_Type_id
          INTO v_manual_set, v_score_type_id
          FROM score_type st
          JOIN internal_audit_type iat
            ON st.score_type_id = iat.nc_score_type_id
          JOIN internal_audit ia
            ON ia.internal_audit_type_id = iat.internal_audit_type_id
         WHERE ia.internal_audit_sid = in_internal_audit_sid;

           IF v_manual_set = 0 THEN
                RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied overwriting score threshold for audit.');
           END IF;

           SELECT COUNT(*)
             INTO v_count
             FROM score_threshold
            WHERE score_type_id = v_score_type_id
              AND score_threshold_id = v_score_threshold_id;

            IF v_count = 0 AND v_score_threshold_id IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'Can only overwrite score threshold with a threshold from the score type associated with the audit.');
            END IF;

           EXCEPTION
            WHEN NO_DATA_FOUND THEN
                --looks like we're trying to overwrite the threshold of an audit that has no thresholds or no score type, better just set it to null
                v_score_threshold_id := NULL;
    END;

    UPDATE internal_audit
       SET ovw_nc_score_thrsh_id = v_score_threshold_id,
           ovw_nc_score_thrsh_dtm = SYSDATE,
           ovw_nc_score_thrsh_usr_sid = SYS_CONTEXT('SECURITY','SID')
     WHERE internal_audit_sid = in_internal_audit_sid;
END;

FUNCTION GetAuditFlowStateIndName (
    in_flow_state_id                IN    flow_state.flow_state_id%TYPE,
    in_flow_st_audit_ind_type_id    IN    flow_state_audit_ind_type.flow_state_audit_ind_type_id%TYPE
) RETURN VARCHAR2
AS
    v_name                flow_state.label%TYPE;
BEGIN
    SELECT CASE in_flow_st_audit_ind_type_id
               WHEN audit_pkg.IND_TYPE_FLOW_STATE_COUNT THEN label
               WHEN audit_pkg.IND_TYPE_FLOW_STATE_TIME THEN 'Time spent in state ' || label
           END
      INTO v_name
      FROM flow_state
     WHERE flow_state_id = in_flow_state_id;

    RETURN v_name;
END;

PROCEDURE SetAuditFlowStateInd(
    in_flow_state_id                IN    flow_state.flow_state_id%TYPE,
    in_ind_sid                        IN    ind.ind_sid%TYPE,
    in_flow_state_type_ind_id        IN    flow_state_audit_ind_type.flow_state_audit_ind_type_id%TYPE,
    in_internal_audit_type_id        IN    internal_audit.internal_audit_type_id%TYPE
)
AS
BEGIN
    BEGIN
        INSERT INTO flow_state_audit_ind (app_sid, ind_sid, flow_state_id, flow_state_audit_ind_type_id, internal_audit_type_id)
        VALUES (security.security_pkg.getapp, in_ind_sid, in_flow_state_id, in_flow_state_type_ind_id, in_internal_audit_type_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- Already exists - ignore.
            NULL;
    END;
END;

PROCEDURE GetAvailableFlowInvTypes (
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT fit.flow_involvement_type_id, fit.label, fit.product_area, fit.css_class
          FROM (
            SELECT flow_involvement_type_id
              FROM flow_involvement_type
             WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
               AND product_area = 'audit'
               AND flow_involvement_type_id >= flow_pkg.CUSTOMER_INV_TYPE_MIN
             MINUS
            SELECT flow_involvement_type_id
              FROM audit_type_flow_inv_type
             WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
               AND internal_audit_type_id = in_internal_audit_type_id
            ) av
          JOIN flow_involvement_type fit
            ON fit.flow_involvement_type_id = av.flow_involvement_type_id
         WHERE fit.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetAuditTypeFlowInvTypes (
    in_internal_audit_type_id        IN    internal_audit_type.internal_audit_type_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT fit.flow_involvement_type_id, fit.label, fit.css_class, fit.product_area,
               atfit.audit_type_flow_inv_type_id, NVL(atfit.min_users, 0) min_users, atfit.max_users,
               atfit.internal_audit_type_id, atfit.users_role_or_group_sid
          FROM flow_involvement_type fit
          JOIN audit_type_flow_inv_type atfit
            ON fit.app_sid = atfit.app_sid
           AND fit.flow_involvement_type_id = atfit.flow_involvement_type_id
         WHERE in_internal_audit_type_id IS NULL OR atfit.internal_audit_type_id = in_internal_audit_type_id;
END;

PROCEDURE GetInvolvedUsers (
    in_internal_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ia.internal_audit_sid, atfit.audit_type_flow_inv_type_id, atfit.flow_involvement_type_id,
               fii.user_sid, cu.full_name, cu.user_name, cu.email, fit.label, fit.lookup_key
          FROM csr.flow_item_involvement fii
          JOIN csr.internal_audit ia ON ia.flow_item_id = fii.flow_item_id
          JOIN csr.audit_type_flow_inv_type atfit
            ON atfit.flow_involvement_type_id = fii.flow_involvement_type_id
           AND atfit.internal_audit_type_id = ia.internal_audit_type_id
          JOIN csr.csr_user cu ON cu.csr_user_sid = fii.user_sid
          JOIN flow_involvement_type fit on fit.flow_involvement_type_id = fii.flow_involvement_type_id
         WHERE ia.internal_audit_sid = in_internal_audit_sid;
END;

PROCEDURE SaveAuditTypeInvType(
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_flow_involvement_type_id        IN     audit_type_flow_inv_type.flow_involvement_type_id%TYPE,
    in_internal_audit_type_id        IN    audit_type_flow_inv_type.internal_audit_type_id%TYPE,
    in_users_role_or_group_sid        IN    audit_type_flow_inv_type.users_role_or_group_sid%TYPE,
    in_min_users                    IN    audit_type_flow_inv_type.min_users%TYPE,
    in_max_users                    IN    audit_type_flow_inv_type.max_users%TYPE,
    out_adt_type_flow_inv_type_id    OUT    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    IF in_adt_type_flow_inv_type_id IS NOT NULL THEN
        out_adt_type_flow_inv_type_id := in_adt_type_flow_inv_type_id;
        UPDATE audit_type_flow_inv_type
           SET min_users = in_min_users,
               max_users = in_max_users,
               users_role_or_group_sid = in_users_role_or_group_sid
         WHERE audit_type_flow_inv_type_id = in_adt_type_flow_inv_type_id;
    ELSE
        INSERT INTO audit_type_flow_inv_type(audit_type_flow_inv_type_id, flow_involvement_type_id,
            internal_audit_type_id, min_users, max_users, users_role_or_group_sid)
        VALUES (audit_type_flw_inv_type_id_seq.NEXTVAL, in_flow_involvement_type_id, in_internal_audit_type_id,
            in_min_users, in_max_users, in_users_role_or_group_sid)
        RETURNING audit_type_flow_inv_type_id INTO out_adt_type_flow_inv_type_id;
    END IF;
END;

PROCEDURE DeleteAuditTypeFlowInvType (
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;

    DELETE FROM audit_type_flow_inv_type
     WHERE audit_type_flow_inv_type_id = in_adt_type_flow_inv_type_id;
END;

PROCEDURE SetAuditInvolvedUsers (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_user_sids                    IN    security.security_pkg.T_SID_IDS
)
AS
BEGIN
    SetAuditInvolvedUsers (in_audit_sid, in_adt_type_flow_inv_type_id, null, in_user_sids);
END;

PROCEDURE SetAuditInvolvedUsers (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_flow_involvement_type_id        IN    flow_involvement_type.flow_involvement_type_id%TYPE,
    in_user_sids                    IN    security.security_pkg.T_SID_IDS
)
AS
BEGIN
    IF NOT HasWriteAccess(in_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the audit with sid '||in_audit_sid);
    END IF;

    UNSEC_SetAuditInvolvedUsers(in_audit_sid, in_adt_type_flow_inv_type_id, in_flow_involvement_type_id, in_user_sids);
END;

PROCEDURE UNSEC_SetAuditInvolvedUsers (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_adt_type_flow_inv_type_id    IN    audit_type_flow_inv_type.audit_type_flow_inv_type_id%TYPE,
    in_flow_involvement_type_id        IN    flow_involvement_type.flow_involvement_type_id%TYPE,
    in_user_sids                    IN    security.security_pkg.T_SID_IDS
)
AS
    v_new_sid_table                    security.T_SID_TABLE;
    v_current_sid_table                security.T_SID_TABLE;
    v_flow_item_id                    internal_audit.internal_audit_sid%TYPE;
    v_flow_involvement_type_id        audit_type_flow_inv_type.flow_involvement_type_id%TYPE;
    v_current_user_sids                security_pkg.T_SID_IDS;
    v_flow_involvement_type_label    flow_involvement_type.label%TYPE;
BEGIN
    v_new_sid_table := security_pkg.SidArrayToTable(in_user_sids);

    SELECT flow_item_id
      INTO v_flow_item_id
      FROM internal_audit
     WHERE internal_audit_sid = in_audit_sid;

    IF in_flow_involvement_type_id IS NULL THEN
        SELECT flow_involvement_type_id
          INTO v_flow_involvement_type_id
          FROM audit_type_flow_inv_type
         WHERE audit_type_flow_inv_type_id = in_adt_type_flow_inv_type_id;
    ELSE
        v_flow_involvement_type_id := in_flow_involvement_type_id;
    END IF;

    SELECT label
      INTO v_flow_involvement_type_label
      FROM flow_involvement_type
     WHERE flow_involvement_type_id = v_flow_involvement_type_id;

    SELECT user_sid
      BULK COLLECT INTO v_current_user_sids
      FROM flow_item_involvement
     WHERE flow_item_id = v_flow_item_id
       AND flow_involvement_type_id = v_flow_involvement_type_id;

    v_current_sid_table := security_pkg.SidArrayToTable(v_current_user_sids);

    DELETE FROM flow_item_involvement
     WHERE flow_item_id = v_flow_item_id
       AND flow_involvement_type_id = v_flow_involvement_type_id;

    INSERT INTO flow_item_involvement (flow_involvement_type_id, flow_item_id, user_sid)
    SELECT v_flow_involvement_type_id, v_flow_item_id, column_value
      FROM TABLE(v_new_sid_table);

    FOR r IN (
        SELECT t1.column_value
          FROM TABLE(v_new_sid_table) t1
          WHERE column_value NOT IN (SELECT t2.column_value FROM TABLE(v_current_sid_table) t2)
    ) LOOP
        csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'),
            in_audit_sid, 'Involved user ('|| v_flow_involvement_type_label ||') SID', null, r.column_value); -- added
    END LOOP;

    FOR r IN (
        SELECT t1.column_value
          FROM TABLE(v_current_sid_table) t1
          WHERE t1.column_value NOT IN (SELECT t2.column_value FROM TABLE(v_new_sid_table) t2)
    ) LOOP
        csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'),
            in_audit_sid, 'Involved user ('|| v_flow_involvement_type_label ||') SID', r.column_value, null); -- removed
    END LOOP;
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_AUDITS
    );
    
    chain.filter_pkg.ClearCacheForAllUsers (
        in_card_group_id => chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES
    );
END;

PROCEDURE CopySurveyAnswersToSummary (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE
)
AS
    v_survey_response_id            csr.quick_survey_response.survey_response_id%TYPE;
    v_audit_region_sid                security.security_pkg.T_SID_ID;
    v_is_new_summary                NUMBER(1);
    v_summary_survey_sid            security.security_pkg.T_SID_ID;
    v_summary_guid                    csr.quick_survey_response.guid%TYPE;
    v_summary_resp_id                csr.quick_survey_response.survey_response_id%TYPE;
BEGIN
    SELECT ia.survey_response_id, iat.summary_survey_sid, ia.region_sid
      INTO v_survey_response_id, v_summary_survey_sid, v_audit_region_sid
      FROM csr.internal_audit ia
      JOIN csr.internal_audit_type iat ON iat.internal_audit_type_id = ia.internal_audit_type_id
     WHERE ia.internal_audit_sid = in_audit_sid;

    IF v_summary_survey_sid IS NULL THEN
        RETURN;
    END IF;

    csr.audit_pkg.GetOrCreateSummaryResponse(in_audit_sid, NULL, v_is_new_summary, v_summary_survey_sid,
        v_summary_guid, v_summary_resp_id);

    csr.quick_survey_pkg.UpdateLinkedResponse(v_survey_response_id, v_summary_resp_id);
END;

PROCEDURE GetAuditTypeSurveyGroups (
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ia_type_survey_group_id, label, lookup_key
          FROM ia_type_survey_group
         ORDER BY label;
END;

PROCEDURE SetAuditTypeSurveyGroup (
    in_ia_type_survey_group_id        IN    ia_type_survey_group.ia_type_survey_group_id%TYPE,
    in_label                        IN    ia_type_survey_group.label%TYPE,
    in_lookup_key                    IN    ia_type_survey_group.lookup_key%TYPE,
    out_ia_type_survey_group_id        OUT    ia_type_survey_group.ia_type_survey_group_id%TYPE
)
AS
    v_survey_capability_id            ia_type_survey_group.survey_capability_id%TYPE;
    v_change_survey_capability_id    ia_type_survey_group.change_survey_capability_id%TYPE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage audit type survey groups');
    END IF;

    IF in_ia_type_survey_group_id IS NULL THEN
        flow_pkg.SaveCustomerFlowCapability(
            in_flow_capability_id    => NULL,
            in_flow_alert_class        => 'audit',
            in_description            => in_label,
            in_perm_type            => csr_data_pkg.FLOW_CAP_SPECIFIC_PERMISSION,
            in_copy_capability_id    => csr_data_pkg.FLOW_CAP_AUDIT_SURVEY,
            out_flow_capability_id    => v_survey_capability_id
        );

        flow_pkg.SaveCustomerFlowCapability(
            in_flow_capability_id    => NULL,
            in_flow_alert_class        => 'audit',
            in_description            => 'Change ' || in_label,
            in_perm_type            => csr_data_pkg.FLOW_CAP_BOOLEAN_PERMISSION,
            in_copy_capability_id    => csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY,
            out_flow_capability_id    => v_change_survey_capability_id
        );

        INSERT INTO ia_type_survey_group (ia_type_survey_group_id, label, lookup_key, survey_capability_id, change_survey_capability_id)
        VALUES (ia_type_survey_group_id_seq.NEXTVAL, in_label, UPPER(in_lookup_key), v_survey_capability_id, v_change_survey_capability_id)
        RETURNING ia_type_survey_group_id INTO out_ia_type_survey_group_id;
    ELSE
        SELECT survey_capability_id, change_survey_capability_id
          INTO v_survey_capability_id, v_change_survey_capability_id
          FROM ia_type_survey_group
         WHERE ia_type_survey_group_id = in_ia_type_survey_group_id;

        flow_pkg.SaveCustomerFlowCapability(
            in_flow_capability_id    => v_survey_capability_id,
            in_description            => in_label,
            out_flow_capability_id    => v_survey_capability_id
        );

        flow_pkg.SaveCustomerFlowCapability(
            in_flow_capability_id    => v_change_survey_capability_id,
            in_description            => 'Change ' || in_label,
            out_flow_capability_id    => v_change_survey_capability_id
        );

        UPDATE ia_type_survey_group
           SET label = in_label,
               lookup_key = UPPER(in_lookup_key)
         WHERE ia_type_survey_group_id = in_ia_type_survey_group_id;

        out_ia_type_survey_group_id := in_ia_type_survey_group_id;
    END IF;
END;

PROCEDURE DeleteAuditTypeSurveyGroup (
    in_ia_type_survey_group_id        IN    ia_type_survey_group.ia_type_survey_group_id%TYPE
)
AS
    v_survey_capability_id            ia_type_survey_group.survey_capability_id%TYPE;
    v_change_survey_capability_id    ia_type_survey_group.change_survey_capability_id%TYPE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage audit type survey groups');
    END IF;

    SELECT survey_capability_id, change_survey_capability_id
      INTO v_survey_capability_id, v_change_survey_capability_id
      FROM ia_type_survey_group
     WHERE ia_type_survey_group_id = in_ia_type_survey_group_id;

    DELETE FROM ia_type_survey_group
     WHERE ia_type_survey_group_id = in_ia_type_survey_group_id;

    flow_pkg.DeleteCustomerFlowCapability(v_survey_capability_id);
    flow_pkg.DeleteCustomerFlowCapability(v_change_survey_capability_id);
END;

PROCEDURE GetAuditTypeSurveys(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT * FROM (
            SELECT PRIMARY_AUDIT_TYPE_SURVEY_ID internal_audit_type_survey_id, iat.internal_audit_type_id,
                    iat.primary_survey_active active, NVL(iat.primary_survey_label, 'Survey') label, NULL ia_type_survey_group_id,
                    iat.default_survey_sid, qs.label default_survey_label,
                    iat.primary_survey_mandatory mandatory, iat.primary_survey_fixed survey_fixed, iat.primary_survey_group_key survey_group_key,
                    NULL survey_capability_id, NULL change_survey_capability_id,
                    NULL ia_type_survey_group_label, NULL ia_type_survey_group_lkup_key
              FROM internal_audit_type iat
              LEFT JOIN v$quick_survey qs ON qs.survey_sid = iat.default_survey_sid AND qs.app_sid = iat.app_sid
             WHERE iat.internal_audit_type_id = in_internal_audit_type_id
                OR in_internal_audit_type_id IS NULL
             UNION
            SELECT iats.internal_audit_type_survey_id, iats.internal_audit_type_id,
                    iats.active, iats.label, iats.ia_type_survey_group_id,
                    iats.default_survey_sid, qs.label default_survey_label,
                    iats.mandatory, iats.survey_fixed, iats.survey_group_key,
                    iatsg.survey_capability_id, iatsg.change_survey_capability_id,
                    iatsg.label ia_type_survey_group_label, iatsg.lookup_key ia_type_survey_group_lkup_key
              FROM internal_audit_type_survey iats
              LEFT JOIN v$quick_survey qs ON qs.survey_sid = iats.default_survey_sid AND qs.app_sid = iats.app_sid
              LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id AND iatsg.app_sid = iats.app_sid
             WHERE iats.internal_audit_type_id = in_internal_audit_type_id
                OR in_internal_audit_type_id IS NULL
        ) ORDER BY internal_audit_type_id, internal_audit_type_survey_id;
END;

PROCEDURE SetDefaultSurvey(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_default_survey_sid            IN    internal_audit_type_survey.default_survey_sid%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
    END IF;
    
    UPDATE internal_audit_type
       SET default_survey_sid = in_default_survey_sid,
           show_primary_survey_in_header = 1
     WHERE internal_audit_type_id = in_internal_audit_type_id;       
END;

PROCEDURE SetAuditTypeSurvey(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_ia_type_survey_id            IN    internal_audit_type_survey.internal_audit_type_survey_id%TYPE,
    in_active                        IN    internal_audit_type_survey.active%TYPE,
    in_label                        IN    internal_audit_type_survey.label%TYPE,
    in_ia_type_survey_group_id        IN    internal_audit_type_survey.ia_type_survey_group_id%TYPE,
    in_default_survey_sid            IN    internal_audit_type_survey.default_survey_sid%TYPE,
    in_mandatory                    IN    internal_audit_type_survey.mandatory%TYPE,
    in_survey_fixed                    IN    internal_audit_type_survey.survey_fixed%TYPE,
    in_survey_group_key                IN    internal_audit_type_survey.survey_group_key%TYPE,
    out_ia_type_survey_id            OUT    internal_audit_type_survey.internal_audit_type_survey_id%TYPE
)
AS
    v_label                            internal_audit_type_survey.label%TYPE;
BEGIN
    IF NOT MultipleSurveysEnabled() THEN
        RETURN; -- rather than crash or corrupt data if they haven't bought the feature yet
    END IF;

    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage audit type surveys');
    END IF;

    IF in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
        UPDATE internal_audit_type
           SET primary_survey_active = in_active,
               primary_survey_label = in_label,
               default_survey_sid = in_default_survey_sid,
               primary_survey_mandatory = in_mandatory,
               primary_survey_fixed = in_survey_fixed,
               primary_survey_group_key = in_survey_group_key
         WHERE internal_audit_type_id = in_internal_audit_type_id;

        out_ia_type_survey_id := in_ia_type_survey_id;
        RETURN;
    END IF;

    BEGIN
        SELECT internal_audit_type_survey_id
          INTO out_ia_type_survey_id
          FROM internal_audit_type_survey
         WHERE (internal_audit_type_survey_id = in_ia_type_survey_id 
            OR (in_ia_type_survey_group_id IS NOT NULL AND ia_type_survey_group_id = in_ia_type_survey_group_id))
           AND internal_audit_type_id = in_internal_audit_type_id;
        
        UPDATE internal_audit_type_survey
           SET active = in_active,
               label = in_label,
               ia_type_survey_group_id = in_ia_type_survey_group_id,
               default_survey_sid = in_default_survey_sid,
               mandatory = in_mandatory,
               survey_fixed = in_survey_fixed,
               survey_group_key = in_survey_group_key
         WHERE internal_audit_type_survey_id = out_ia_type_survey_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO internal_audit_type_survey
                    (internal_audit_type_survey_id, internal_audit_type_id,
                    active, label, ia_type_survey_group_id,
                    default_survey_sid, mandatory, survey_fixed, survey_group_key)
            VALUES (ia_type_survey_id_seq.NEXTVAL, in_internal_audit_type_id,
                    in_active, in_label, in_ia_type_survey_group_id,
                    in_default_survey_sid, in_mandatory, in_survey_fixed, in_survey_group_key)
            RETURNING internal_audit_type_survey_id INTO out_ia_type_survey_id;
    END;
END;

PROCEDURE DeleteAuditTypeSurveys(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_keep_ia_type_survey_ids        IN    security_pkg.T_SID_IDS
)
AS
    v_keeper_id_tbl                security.T_SID_TABLE;
BEGIN
    IF NOT MultipleSurveysEnabled() THEN
        RETURN; -- rather than crash or corrupt data if they haven't bought the feature yet
    END IF;

    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage audit type surveys');
    END IF;

    -- we don't have to worry about the primary one here, because you're not allowed to delete it.
    IF in_keep_ia_type_survey_ids IS NULL OR (in_keep_ia_type_survey_ids.COUNT = 1 AND in_keep_ia_type_survey_ids(1) IS NULL) THEN
        -- all removed
        DELETE FROM internal_audit_type_survey
         WHERE internal_audit_type_id = in_internal_audit_type_id;
    ELSE
        BEGIN
            v_keeper_id_tbl := security_pkg.SidArrayToTable(in_keep_ia_type_survey_ids);
            DELETE FROM internal_audit_type_survey
             WHERE internal_audit_type_id = in_internal_audit_type_id
               AND internal_audit_type_survey_id NOT IN (
                SELECT column_value FROM TABLE(v_keeper_id_tbl)
               );
        EXCEPTION
            WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
                RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST,'Could not delete survey associated with audit id : '||in_internal_audit_type_id||' as there are existing survey responses associated with it.');
        END;
    END IF;
END;

PROCEDURE GetAuditTypeSurveyDefaultPerms(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_region_sid                    IN    security_pkg.T_SID_ID,
    in_auditee_user_sid                IN    security_pkg.T_SID_ID,
    in_auditor_user_sid                IN    security_pkg.T_SID_ID,
    in_auditor_company_sid            IN    security_pkg.T_SID_ID,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
    v_region_sid                    security_pkg.T_SID_ID := in_region_sid;
    v_ownership_rights                NUMBER := security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16); -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
BEGIN
    ApplyAuditTypeToRegionSid(v_region_sid, in_internal_audit_type_id, in_auditee_user_sid, v_region_sid);

    OPEN out_cur FOR
        SELECT t1.internal_audit_type_survey_id, t1.label, t2.permission_set survey_permission_set, t3.permission_set change_survey_permission_set
          FROM (
                SELECT PRIMARY_AUDIT_TYPE_SURVEY_ID internal_audit_type_survey_id, NULL label, NULL survey_capability_id, NULL change_survey_capability_id
                  FROM internal_audit_type
                 WHERE internal_audit_type_id = in_internal_audit_type_id
                   AND primary_survey_active = 1
                UNION
                SELECT iats.internal_audit_type_survey_id, iats.label, iatsg.survey_capability_id, iatsg.change_survey_capability_id
                  FROM internal_audit_type_survey iats
                  LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id AND iatsg.app_sid = iats.app_sid
                 WHERE iats.internal_audit_type_id = in_internal_audit_type_id
                   AND iats.active = 1
          ) t1 JOIN (
            SELECT fsrc.flow_capability_id,
                   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
                   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
              FROM internal_audit_type iat
              JOIN flow f ON iat.app_sid = f.app_sid AND iat.flow_sid = f.flow_sid
              JOIN flow_state_role_capability fsrc ON f.app_sid = fsrc.app_sid AND f.default_state_id = fsrc.flow_state_id
              LEFT JOIN region_role_member rrm ON iat.app_sid = rrm.app_sid
               AND rrm.region_sid = v_region_sid
               AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
               AND rrm.role_sid = fsrc.role_sid
              LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
               AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
             WHERE iat.internal_audit_type_id = in_internal_audit_type_id
               AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
               AND (in_auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
                OR in_auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
                OR (in_auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
               AND fsrc.flow_involvement_type_id = 2)       -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
                OR rrm.role_sid IS NOT NULL
                OR act.sid_id IS NOT NULL
                OR v_ownership_rights = 1)
             GROUP BY iat.app_sid, iat.internal_audit_type_id, fsrc.flow_capability_id
        ) t2 ON t2.flow_capability_id = NVL(t1.survey_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY) JOIN (
            -- keep this in sync with v$audit_capabilities
            SELECT fsrc.flow_capability_id,
                   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
                   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
              FROM internal_audit_type iat
              JOIN flow f ON iat.app_sid = f.app_sid AND iat.flow_sid = f.flow_sid
              JOIN flow_state_role_capability fsrc ON f.app_sid = fsrc.app_sid AND f.default_state_id = fsrc.flow_state_id
              LEFT JOIN region_role_member rrm ON iat.app_sid = rrm.app_sid
               AND rrm.region_sid = v_region_sid
               AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
               AND rrm.role_sid = fsrc.role_sid
              LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
               AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
             WHERE iat.internal_audit_type_id = in_internal_audit_type_id
               AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
               AND (in_auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
                OR in_auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
                OR (in_auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
               AND fsrc.flow_involvement_type_id = 2)       -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
                OR rrm.role_sid IS NOT NULL
                OR v_ownership_rights = 1)
             GROUP BY iat.app_sid, iat.internal_audit_type_id, fsrc.flow_capability_id
        ) t3 ON t3.flow_capability_id = NVL(t1.change_survey_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY);
END;

FUNCTION SQL_HasSurveyAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_ia_type_survey_id        IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_change_survey            IN    NUMBER
) RETURN BINARY_INTEGER
AS
BEGIN
    IF HasSurveyAccess(in_audit_sid, in_ia_type_survey_id, in_change_survey) THEN
        RETURN 1;
    END IF;

    RETURN 0;
END;

FUNCTION HasSurveyAccess(
    in_audit_sid                IN    security_pkg.T_SID_ID,
    in_ia_type_survey_id        IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_change_survey            IN    NUMBER
) RETURN BOOLEAN
AS
    v_active                        internal_audit_type_survey.active%TYPE;
    v_survey_capability_id            ia_type_survey_group.survey_capability_id%TYPE;
    v_change_survey_capability_id    ia_type_survey_group.change_survey_capability_id%TYPE;
BEGIN
    -- We don't let people write to inactive slots, regardless of flow state
    IF in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
        SELECT iat.primary_survey_active INTO v_active
          FROM internal_audit_type iat
          JOIN internal_audit ia ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
         WHERE ia.internal_audit_sid = in_audit_sid;
    ELSE
        SELECT iats.active INTO v_active
          FROM internal_audit_type_survey iats
         WHERE internal_audit_type_survey_id = in_ia_type_survey_id;
    END IF;

    IF v_active = 0 AND in_change_survey != 0 THEN
        RETURN FALSE;
    END IF;

    IF NOT IsFlowAudit(in_audit_sid) THEN
        RETURN HasReadAccess(in_audit_sid);
    END IF;

    BEGIN
        SELECT survey_capability_id, change_survey_capability_id
            INTO v_survey_capability_id, v_change_survey_capability_id
            FROM internal_audit_type_survey iats
            LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id AND iatsg.app_sid = iats.app_sid
            WHERE iats.internal_audit_type_survey_id = in_ia_type_survey_id;
    EXCEPTION
        WHEN no_data_found THEN
            v_survey_capability_id := NULL;
            v_change_survey_capability_id := NULL;
    END;

    IF NOT HasCapabilityAccess(in_audit_sid, NVL(v_survey_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY), security.security_pkg.PERMISSION_READ) THEN
        RETURN FALSE;
    END IF;

    IF in_change_survey != 0 THEN
        IF NOT HasCapabilityAccess(in_audit_sid, NVL(v_change_survey_capability_id, csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY), security.security_pkg.PERMISSION_WRITE) THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN TRUE;
END;

PROCEDURE GetAuditSurveys(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
    v_read_on_survey                NUMBER;
    v_has_perm_prim                    NUMBER;
    v_permissible_surv_t            security.T_SID_TABLE;
BEGIN
    IF NOT (HasReadAccess(in_internal_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_internal_audit_sid);
    END IF;

    v_has_perm_prim := SQL_HasSurveyAccess(in_internal_audit_sid, PRIMARY_AUDIT_TYPE_SURVEY_ID, 0);

    SELECT internal_audit_type_survey_id
      BULK COLLECT INTO v_permissible_surv_t
      FROM internal_audit_survey
     WHERE internal_audit_sid = in_internal_audit_sid
       AND SQL_HasSurveyAccess(in_internal_audit_sid, internal_audit_type_survey_id, 0) = 1;

    OPEN out_cur FOR
        SELECT t.internal_audit_sid, t.internal_audit_type_survey_id,
               qs.survey_sid, qs.label survey_label, qs.score_type_id, qs.score_format_mask,
               qsr.survey_response_id, qsr.submitted_dtm, qsr.survey_version,
               qsr.submitted_by_user_sid, cu.full_name submitted_by_user_name, cu.email submitted_by_user_email,
               qsr.overall_score, qsr.overall_max_score, qsr.score_threshold_id,
               st.description threshold_description, t.ia_type_survey_group_lkup_key
          FROM (
            SELECT ia.app_sid, ia.internal_audit_sid, PRIMARY_AUDIT_TYPE_SURVEY_ID internal_audit_type_survey_id, ia.survey_sid, ia.survey_response_id,
                   NULL ia_type_survey_group_lkup_key
              FROM v$audit ia
             WHERE ia.internal_audit_sid = in_internal_audit_sid
               AND v_has_perm_prim = 1
               AND ia.survey_sid IS NOT NULL
             UNION
            SELECT ias.app_sid, ias.internal_audit_sid, ias.internal_audit_type_survey_id, ias.survey_sid, ias.survey_response_id,
                   iatsg.lookup_key ia_type_survey_group_lkup_key
              FROM internal_audit_survey ias
              JOIN TABLE(v_permissible_surv_t) t_ias ON t_ias.column_value = ias.internal_audit_type_survey_id
              JOIN internal_audit_type_survey iats ON iats.internal_audit_type_survey_id = ias.internal_audit_type_survey_id AND iats.app_sid = ias.app_sid
              LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id AND iatsg.app_sid = iats.app_sid
             WHERE ias.internal_audit_sid = in_internal_audit_sid
          ) t
          LEFT JOIN v$quick_survey_response qsr ON qsr.survey_response_id = t.survey_response_id AND qsr.app_sid = t.app_sid
          LEFT JOIN score_threshold st ON qsr.score_threshold_id = st.score_threshold_id AND qsr.app_sid = st.app_sid
          LEFT JOIN csr_user cu ON cu.csr_user_sid = qsr.submitted_by_user_sid and cu.app_sid = qsr.app_sid
          LEFT JOIN v$quick_survey qs ON NVL(qsr.survey_sid, t.survey_sid) = qs.survey_sid AND qs.app_sid = t.app_sid
          ORDER BY internal_audit_type_survey_id;
END;

PROCEDURE AuditSurveyChange(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_old_survey_sid                IN    internal_audit_survey.survey_sid%TYPE,
    in_new_survey_sid                IN    internal_audit_survey.survey_sid%TYPE
)
AS
    v_type_label                    internal_audit_type_survey.label%TYPE;
    v_old_survey_label                v$quick_survey.label%TYPE;
    v_new_survey_label                v$quick_survey.label%TYPE;
BEGIN
    IF in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
        SELECT NVL(iat.primary_survey_label, 'Survey')
          INTO v_type_label
          FROM internal_audit_type iat
          JOIN internal_audit ia ON ia.internal_audit_type_id = iat.internal_audit_type_id AND ia.app_sid = iat.app_sid
         WHERE ia.internal_audit_sid = in_internal_audit_sid;
    ELSE
        SELECT label
          INTO v_type_label
          FROM internal_audit_type_survey iats
         WHERE iats.internal_audit_type_survey_id = in_ia_type_survey_id;
    END IF;

    IF in_old_survey_sid IS NULL THEN
        v_old_survey_label := NULL;
    ELSE
        SELECT label
          INTO v_old_survey_label
          FROM v$quick_survey
         WHERE survey_sid = in_old_survey_sid;
    END IF;

    IF in_new_survey_sid IS NULL THEN
        v_new_survey_label := NULL;
    ELSE
        SELECT label
          INTO v_new_survey_label
          FROM v$quick_survey
         WHERE survey_sid = in_new_survey_sid;
    END IF;

    csr_data_pkg.AuditValueDescChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'),
        in_internal_audit_sid, v_type_label, in_old_survey_sid, in_new_survey_sid, v_old_survey_label, v_new_survey_label);
END;

PROCEDURE SetAuditSurvey(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE,
    in_survey_sid                    IN    internal_audit_survey.survey_sid%TYPE
)
AS
    v_original_survey_sid            internal_audit_survey.survey_sid%TYPE;
    v_original_response_id            internal_audit_survey.survey_response_id%TYPE;
    v_default_survey_sid            internal_audit_survey.survey_sid%TYPE;
BEGIN
    IF NOT MultipleSurveysEnabled() THEN
        RETURN; -- rather than crash or corrupt data if they haven't bought the feature yet
    END IF;

    IF in_ia_type_survey_id = PRIMARY_AUDIT_TYPE_SURVEY_ID THEN
        SELECT survey_sid, survey_response_id
          INTO v_original_survey_sid, v_original_response_id
          FROM internal_audit
         WHERE internal_audit_sid = in_internal_audit_sid;
        
        IF null_pkg.ne(v_original_survey_sid, in_survey_sid) THEN
        
            SELECT iat.default_survey_sid
              INTO v_default_survey_sid
              FROM internal_audit_type iat
              JOIN internal_audit ia ON iat.internal_audit_type_id = ia.internal_audit_type_id
             WHERE ia.internal_audit_sid = in_internal_audit_sid;
               
            IF null_pkg.ne(v_default_survey_sid, in_survey_sid) OR v_original_survey_sid IS NOT NULL THEN
                IF NOT (HasWriteAccess(in_internal_audit_sid)) OR NOT HasSurveyAccess(in_internal_audit_sid, in_ia_type_survey_id, 1) THEN
                    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the audit with sid '||in_internal_audit_sid ||' for survey with id '||in_ia_type_survey_id);
                END IF;
            END IF;

            IF NVL(in_survey_sid, 0) != NVL(v_original_survey_sid, 0) AND v_original_response_id IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot change audit with sid '||in_internal_audit_sid ||' for started survey with id '||in_ia_type_survey_id);
            END IF;

            UPDATE internal_audit
               SET survey_sid = in_survey_sid
             WHERE internal_audit_sid = in_internal_audit_sid;
        END IF;
    ELSE
        BEGIN
            SELECT survey_sid, survey_response_id
              INTO v_original_survey_sid, v_original_response_id
              FROM internal_audit_survey
             WHERE internal_audit_sid = in_internal_audit_sid
               AND internal_audit_type_survey_id = in_ia_type_survey_id;
        EXCEPTION
            WHEN no_data_found THEN
                v_original_survey_sid := NULL;
                v_original_response_id := NULL;
        END;

        IF null_pkg.ne(v_original_survey_sid, in_survey_sid) THEN
        
            SELECT iats.default_survey_sid
              INTO v_default_survey_sid
              FROM internal_audit_type_survey iats
              JOIN internal_audit_type iat ON iats.internal_audit_type_id = iat.internal_audit_type_id
              JOIN internal_audit ia ON iat.internal_audit_type_id = ia.internal_audit_type_id
             WHERE ia.internal_audit_sid = in_internal_audit_sid
               AND iats.internal_audit_type_survey_id = in_ia_type_survey_id;
               
            IF null_pkg.ne(v_default_survey_sid, in_survey_sid) OR v_original_survey_sid IS NOT NULL THEN
                IF NOT (HasWriteAccess(in_internal_audit_sid)) OR NOT HasSurveyAccess(in_internal_audit_sid, in_ia_type_survey_id, 1) THEN
                    RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the audit with sid '||in_internal_audit_sid ||' for survey with id '||in_ia_type_survey_id);
                END IF;
            END IF;
        
            IF NVL(in_survey_sid, 0) != NVL(v_original_survey_sid, 0) AND v_original_response_id IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot change audit with sid '||in_internal_audit_sid ||' for started survey with id '||in_ia_type_survey_id);
            END IF;

            IF in_survey_sid IS NULL THEN
                DELETE FROM internal_audit_survey
                      WHERE internal_audit_sid = in_internal_audit_sid
                        AND internal_audit_type_survey_id = in_ia_type_survey_id;
            ELSE
                BEGIN
                    INSERT INTO internal_audit_survey (internal_audit_sid, internal_audit_type_survey_id, survey_sid)
                    VALUES (in_internal_audit_sid, in_ia_type_survey_id, in_survey_sid);
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        UPDATE internal_audit_survey
                           SET survey_sid = in_survey_sid
                         WHERE internal_audit_sid = in_internal_audit_sid
                           AND internal_audit_type_survey_id = in_ia_type_survey_id;
                END;
            END IF;
        END IF;
    END IF;

    AuditSurveyChange(in_internal_audit_sid, in_ia_type_survey_id, v_original_survey_sid, in_survey_sid);
END;

PROCEDURE DeleteAuditSurvey(
    in_internal_audit_sid            IN    internal_audit_survey.internal_audit_sid%TYPE,
    in_ia_type_survey_id            IN    internal_audit_survey.internal_audit_type_survey_id%TYPE
)
AS
BEGIN
    SetAuditSurvey(in_internal_audit_sid, in_ia_type_survey_id, NULL);
END;

PROCEDURE GetFixedSurveys(
    in_internal_audit_type_id    IN  audit_type_non_comp_default.internal_audit_type_id%TYPE,
    out_cur                        OUT SYS_REFCURSOR
)
AS
BEGIN
    -- base data, no security required.
    OPEN out_cur FOR
        SELECT default_survey_sid survey_sid
          FROM internal_audit_type
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND default_survey_sid IS NOT NULL
           AND primary_survey_fixed = 1
         UNION
        SELECT default_survey_sid survey_sid
          FROM internal_audit_type_survey
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND default_survey_sid IS NOT NULL
           AND survey_fixed = 1
           AND active = 1;
END;

PROCEDURE SetAuditTags (
    in_audit_sid                    IN    internal_audit.internal_audit_sid%TYPE,
    in_tag_ids                        IN    security.security_pkg.T_SID_IDS,
    in_copy_locked_tags_from_sid    IN    security.security_pkg.T_SID_ID DEFAULT NULL
)
AS
    v_tag_id_t                        security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_tag_ids);
    v_temp_tag_id_t                    security.T_SID_TABLE;
    v_locked_tags_t                    security.T_ORDERED_SID_TABLE; /*sid_id: tag_group_id, pos:tag_id*/
BEGIN
    IF NOT HasWriteAccess(in_audit_sid) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the audit with sid '||in_audit_sid);
    END IF;
    
    IF in_copy_locked_tags_from_sid > -1 THEN
        --store all locked tags + input tags that don't belong to any of the locked tag groups
        SELECT security.T_ORDERED_SID_ROW(sid_id => tag_group_id, pos => tag_id)
          BULK COLLECT INTO v_locked_tags_t
          FROM internal_audit_locked_tag
         WHERE internal_audit_sid = in_copy_locked_tags_from_sid;
           
        SELECT tag_id
          BULK COLLECT INTO v_temp_tag_id_t
          FROM( 
             SELECT pos tag_id
               FROM TABLE(v_locked_tags_t)
              WHERE pos IS NOT NULL
            UNION 
             SELECT t.column_value tag_id
               FROM TABLE(v_tag_id_t) t
              WHERE NOT EXISTS(
                SELECT 1
                  FROM TABLE(v_locked_tags_t) tl
                  JOIN tag_group_member tgm ON tgm.tag_group_id = tl.sid_id
                 WHERE tgm.tag_id = t.column_value
              )
          );
        
        v_tag_id_t := v_temp_tag_id_t;
    END IF;
    
    DELETE FROM internal_audit_tag
     WHERE app_sid = security_pkg.getApp
       AND internal_audit_sid = in_audit_sid
        AND tag_id NOT IN (
            SELECT column_value FROM TABLE(v_tag_id_t)
        )
       AND tag_id IN (
            SELECT tag_id
              FROM tag_group_member tgm
              JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id
             WHERE tg.applies_to_audits = 1
       );
    
    INSERT INTO internal_audit_tag
     SELECT security_pkg.getapp, in_audit_sid, column_value
       FROM TABLE(v_tag_id_t)
      WHERE column_value NOT IN (
            SELECT tag_id
              FROM internal_audit_tag
             WHERE internal_audit_sid = in_audit_sid
        );
    
    IF in_copy_locked_tags_from_sid > -1 THEN
        INSERT INTO internal_audit_locked_tag (internal_audit_sid, tag_group_id, tag_id)
        SELECT in_audit_sid, tl.sid_id, tl.pos
          FROM TABLE(v_locked_tags_t) tl;
    END IF;
END;

PROCEDURE FilterUsersByRoleGroupRegion(
    in_group_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,    
    in_role_sid                IN    security_pkg.T_SID_ID DEFAULT NULL,    
    in_region_sid            IN    security_pkg.T_SID_ID DEFAULT NULL,    
    in_filter_name            IN    csr_user.full_name%TYPE DEFAULT NULL,
    in_auditor_company_sid    IN    security_pkg.T_SID_ID DEFAULT NULL,
    out_cur                    OUT    SYS_REFCURSOR,
    out_total_num_users        OUT SYS_REFCURSOR
)
IS
    v_app_sid            security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
    v_group_members        security.T_SO_TABLE;
    v_users_t            security.T_SID_TABLE;
    v_filtered_t        T_USER_FILTER_TABLE;
    v_show_email        NUMBER;
    v_show_user_name    NUMBER;
    v_show_user_ref        NUMBER;
    v_show_admins        BOOLEAN;
BEGIN
    IF in_auditor_company_sid IS NOT NULL THEN
        chain.company_user_pkg.SearchCompanyUsers(
            in_company_sid        => in_auditor_company_sid,
            in_search_term        => in_filter_name,
            in_show_inactive    => 0,
            out_filtered_t        => v_filtered_t,
            out_show_admins        => v_show_admins
        );
    ELSE
        csr_user_pkg.FilterUsersToTable(
            in_filter => in_filter_name,
            in_include_inactive    => 0,
            out_table => v_filtered_t
        );
    END IF;
        
    -- Materialize list of group members
    IF in_group_sid IS NOT NULL THEN
        -- Note: asserts PERMISSION_READ on in_group_sid
        v_group_members := security.Group_Pkg.GetMembersAsTable(security_pkg.GetAct, in_group_sid);
        
        SELECT csr_user_sid
          BULK COLLECT INTO v_users_t
          FROM (SELECT csr_user_sid FROM TABLE(v_filtered_t) ORDER BY csr_user_sid) u
          JOIN (SELECT sid_id FROM TABLE(v_group_members) ORDER BY sid_id) t ON t.sid_id = u.csr_user_sid;
           
    ELSIF in_role_sid IS NOT NULL THEN
        SELECT csr_user_sid
          BULK COLLECT INTO v_users_t
          FROM (SELECT csr_user_sid FROM TABLE(v_filtered_t) ORDER BY csr_user_sid) u
         WHERE EXISTS(
                SELECT 1 
                  FROM csr.region_role_member rrm
                 WHERE rrm.user_sid = u.csr_user_sid
                   AND rrm.region_sid = in_region_sid
                   AND rrm.role_sid = in_role_sid
           );
    ELSE 
        SELECT csr_user_sid
          BULK COLLECT INTO v_users_t
          FROM TABLE(v_filtered_t);
    END IF;

    SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
           CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
           CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
      INTO v_show_email, v_show_user_name, v_show_user_ref
      FROM customer
     WHERE app_sid = v_app_sid;
     
    OPEN out_cur FOR
        SELECT csr_user_sid, csr_user_sid user_sid, csr_user_sid sid, full_name, email, user_name, user_ref, account_enabled,
            v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
          FROM (
            SELECT cu.csr_user_sid, 
                   cu.user_name,
                   cu.full_name,
                   cu.email,
                   cu.user_ref,
                   ut.account_enabled
              FROM csr.csr_user cu
              JOIN TABLE(v_users_t) t ON cu.csr_user_sid = t.column_value
              JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
             ORDER BY lower(cu.full_name)
        )
        WHERE rownum <= csr_user_pkg.MAX_USERS;
        
    OPEN out_total_num_users FOR
        SELECT COUNT(*) total_num_users, csr_user_pkg.MAX_USERS max_size
          FROM TABLE(v_users_t);
END;

FUNCTION GetPrimarySurveyScoreTypeIds
RETURN security.T_SID_TABLE
AS
    v_score_type_ids_t security.T_SID_TABLE;
BEGIN
    SELECT st.score_type_id
      BULK COLLECT INTO v_score_type_ids_t
      FROM score_type st
     WHERE EXISTS (
        SELECT 1
          FROM internal_audit_type iat
          JOIN quick_survey qs ON iat.default_survey_sid = qs.survey_sid
         WHERE iat.app_sid = security_pkg.getApp
           AND qs.score_type_id = st.score_type_id
     );
    
    RETURN v_score_type_ids_t;
END;

PROCEDURE GetPrimarySurveyScoreTypeIds(
    out_cur         OUT    SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT column_value score_type_id
          FROM TABLE(GetPrimarySurveyScoreTypeIds);
END;

PROCEDURE GetSurveyGroupScoreTypes(
    out_cur         OUT    SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT iats.ia_type_survey_group_id, qs.score_type_id
          FROM internal_audit_type_survey iats
          JOIN quick_survey qs ON iats.default_survey_sid = qs.survey_sid
         WHERE iats.app_sid = security_pkg.getApp
           AND qs.score_type_id IS NOT NULL
           AND iats.ia_type_survey_group_id IS NOT NULL
         ORDER BY iats.ia_type_survey_group_id, qs.score_type_id;
END;

PROCEDURE GetInternalAuditTypeReports(
    in_audit_type_id     IN  internal_audit_type.internal_audit_type_id%TYPE,
    out_cur             OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT internal_audit_type_id, internal_audit_type_report_id, report_filename, label, ia_type_report_group_id,
           use_merge_field_guid, guid_expiration_days
          FROM internal_audit_type_report
         WHERE (in_audit_type_id IS NULL OR internal_audit_type_id = in_audit_type_id)
           AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE SetAuditTypeReports(
    in_internal_audit_type_id        IN    internal_audit_type_survey.internal_audit_type_id%TYPE,
    in_keep_ia_type_report_ids        IN    security_pkg.T_SID_IDS
)
AS
    v_keeper_id_tbl                security.T_SID_TABLE;
BEGIN
    IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can manage audit type reports');
    END IF;

    IF in_keep_ia_type_report_ids IS NULL OR (in_keep_ia_type_report_ids.COUNT = 1 AND in_keep_ia_type_report_ids(1) IS NULL) THEN
        -- all removed
        DELETE FROM internal_audit_type_report
         WHERE internal_audit_type_id = in_internal_audit_type_id;
    ELSE
        v_keeper_id_tbl := security_pkg.SidArrayToTable(in_keep_ia_type_report_ids);
        DELETE FROM internal_audit_type_report
         WHERE internal_audit_type_id = in_internal_audit_type_id
           AND internal_audit_type_report_id NOT IN (
            SELECT column_value FROM TABLE(v_keeper_id_tbl)
           );
    END IF;
END;

PROCEDURE GetPublicReport (
    in_guid                            IN    internal_audit_report_guid.guid%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- Security check is that the correct GUID is provided
    OPEN out_cur FOR
        SELECT filename, doc_type, CASE WHEN expiry_dtm < SYSDATE THEN NULL ELSE document END document, expiry_dtm
          FROM internal_audit_report_guid
         WHERE guid = in_guid;
END;

PROCEDURE SavePublicReport (
    in_internal_audit_type_rpt_id    IN    internal_audit_type_report.internal_audit_type_report_id%TYPE,
    in_filename                     IN  internal_audit_report_guid.filename%TYPE,
    in_doc_type                     IN  internal_audit_report_guid.doc_type%TYPE,
    in_document                     IN  internal_audit_report_guid.document%TYPE,
    in_guid                         IN  internal_audit_report_guid.guid%TYPE
)
AS
BEGIN
    IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can save public audit reports');
    END IF;
    
    INSERT INTO internal_audit_report_guid (guid, expiry_dtm, filename, document, doc_type)
         SELECT in_guid, SYSDATE + guid_expiration_days, in_filename, in_document, in_doc_type
           FROM internal_audit_type_report
          WHERE internal_audit_type_report_id = in_internal_audit_type_rpt_id
            AND use_merge_field_guid = 1;
END;

PROCEDURE GetInternalAuditReportGroups (
    out_cur             OUT  SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ia_type_report_group_id, label
          FROM ia_type_report_group
         WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE SaveInternalAuditTypeReport (
    in_audit_type_report_id         IN  internal_audit_type_report.internal_audit_type_report_id%TYPE,
    in_internal_audit_type_id         IN  internal_audit.internal_audit_sid%TYPE,
    in_label                         IN  internal_audit_type_report.label%TYPE,
    in_cache_key                     IN  aspen2.filecache.cache_key%type,
    in_ia_type_report_group_id         IN  internal_audit_type_report.ia_type_report_group_id%TYPE,
    in_use_guid                        IN    internal_audit_type_report.use_merge_field_guid%TYPE,
    in_guid_expiration                IN    internal_audit_type_report.guid_expiration_days%TYPE DEFAULT NULL,
    out_internal_audit_report_id     OUT internal_audit_type_report.internal_audit_type_report_id%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
    v_word_doc                    internal_audit_type_report.word_doc%TYPE;
    v_filename                     internal_audit_type_report.report_filename%TYPE;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit type reports');
    END IF;

    IF in_cache_key IS NOT NULL AND in_audit_type_report_id IS NOT NULL THEN
        -- update word doc
        UPDATE internal_audit_type_report
           SET (word_doc, report_filename) = (
                SELECT object, filename
                  FROM aspen2.filecache
                 WHERE cache_key = in_cache_key
             ),
                   label = in_label,
                   ia_type_report_group_id = in_ia_type_report_group_id
         WHERE internal_audit_type_report_id = in_audit_type_report_id;
         out_internal_audit_report_id := in_audit_type_report_id;
    ELSIF in_cache_key IS NOT NULL AND in_audit_type_report_id IS NULL THEN
        -- create a new template
        SELECT object, filename
          INTO v_word_doc, v_filename
          FROM aspen2.filecache
         WHERE cache_key = in_cache_key;
        
        INSERT INTO internal_audit_type_report (internal_audit_type_id, internal_audit_type_report_id, word_doc,
            report_filename, label, ia_type_report_group_id, use_merge_field_guid, guid_expiration_days)
        VALUES (in_internal_audit_type_id, internal_audit_type_report_seq.nextval, v_word_doc, v_filename, in_label, 
            in_ia_type_report_group_id, in_use_guid, in_guid_expiration)
        RETURNING internal_audit_type_report_id INTO out_internal_audit_report_id;
    ELSE
        UPDATE internal_audit_type_report
           SET label = in_label,
               use_merge_field_guid = in_use_guid,
               guid_expiration_days = in_guid_expiration,
               ia_type_report_group_id = in_ia_type_report_group_id
         WHERE internal_audit_type_report_id = in_audit_type_report_id;
         out_internal_audit_report_id := in_audit_type_report_id;
    END IF;
END;

PROCEDURE SaveIATypeReportGroup (
    in_ia_type_report_group_id         IN  ia_type_report_group.ia_type_report_group_id%TYPE,
    in_label                         IN  ia_type_survey_group.label%TYPE,
    out_ia_type_report_group_id     OUT ia_type_report_group.ia_type_report_group_id%TYPE
)
AS
    v_audits_sid                security_pkg.T_SID_ID;
BEGIN
    v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit type report groups');
    END IF;

    IF in_ia_type_report_group_id IS NOT NULL THEN
        UPDATE ia_type_report_group
           SET label = in_label
         WHERE ia_type_report_group_id = in_ia_type_report_group_id;
         out_ia_type_report_group_id := in_ia_type_report_group_id;
    ELSE
        INSERT INTO ia_type_report_group (app_sid, ia_type_report_group_id, label)
             VALUES (security_pkg.GetApp, ia_type_report_group_id_seq.nextval, in_label)
          RETURNING ia_type_report_group_id INTO out_ia_type_report_group_id;
    END IF;
END;

PROCEDURE ProcessExpiredPublicReports
AS
BEGIN
    IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can process expired audit reports');
    END IF;
    
    -- Keep the row so we know there was a report that expired, but clear out
    -- the blobs
    UPDATE internal_audit_report_guid
       SET document = NULL
     WHERE expiry_dtm < SYSDATE
       AND document IS NOT NULL;
END;

PROCEDURE GetAuditScores(
    in_internal_audit_sid            IN    internal_audit.internal_audit_sid%TYPE,
    in_internal_audit_type_id        IN    internal_audit.internal_audit_type_id%TYPE,
    in_flow_item_id                    IN    internal_audit.flow_item_id%TYPE,
    out_cur                            OUT    security.security_pkg.T_OUTPUT_CUR
)
AS
    v_has_audit_score_access         NUMBER := SQL_HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_READ);
BEGIN    
    IF NOT (HasReadAccess(in_internal_audit_sid)) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the audit with sid '||in_internal_audit_sid);
    END IF;

    OPEN out_cur FOR
        SELECT in_internal_audit_sid, st.score_type_id, ias.score, ias.score_threshold_id,
               st.label score_type_label, st.format_mask score_type_format_mask, st.allow_manual_set, st.lookup_key score_type_lookup_key,
               sth.description score_threshold_description, 
               sth.text_colour, sth.background_colour, sth.bar_colour, 
               cast(sth.icon_image_sha1 as varchar2(40)) icon_image_sha1
          FROM score_type st
          LEFT JOIN internal_audit_score ias ON st.score_type_id = ias.score_type_id
           AND ias.internal_audit_sid = in_internal_audit_sid
          LEFT JOIN score_threshold sth ON ias.score_threshold_id = sth.score_threshold_id
         WHERE st.app_sid = SYS_CONTEXT('SECURITY', 'APP')
           AND st.applies_to_audits = 1
           AND (st.score_type_id IN (
               SELECT stat.score_type_id 
                 FROM score_type_audit_type stat
                WHERE stat.internal_audit_type_id = in_internal_audit_type_id
                )
            OR NOT EXISTS (
                SELECT 1
                  FROM score_type_audit_type stat
                 WHERE stat.score_type_id = st.score_type_id
            ))
           AND (in_flow_item_id IS NULL OR v_has_audit_score_access = 1)
          ORDER BY st.pos;
END;

PROCEDURE SetAuditScore(
    in_internal_audit_sid            IN    internal_audit_score.internal_audit_sid%TYPE,
    in_score_type_id                IN    internal_audit_score.score_type_id%TYPE,
    in_score                        IN    internal_audit_score.score%TYPE,
    in_score_threshold_id            IN    internal_audit_score.score_threshold_id%TYPE,
    in_override_system_threshold    IN    NUMBER DEFAULT 0
)
AS
    v_flow_item_id                    security.security_pkg.T_SID_ID;
BEGIN
    SELECT flow_item_id
      INTO v_flow_item_id
      FROM v$audit
     WHERE internal_audit_sid = in_internal_audit_sid;

    IF (v_flow_item_id IS NULL AND NOT HasWriteAccess(in_internal_audit_sid)) OR
       (v_flow_item_id IS NOT NULL AND NOT HasCapabilityAccess(in_internal_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_SCORE, security.security_pkg.PERMISSION_WRITE)) THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing scores to the audit with sid '||in_internal_audit_sid);
    END IF;

    UNSEC_SetAuditScore(
        in_internal_audit_sid            => in_internal_audit_sid,
        in_score_type_id                => in_score_type_id,
        in_score                        => in_score,
        in_score_threshold_id            => in_score_threshold_id,
        in_override_system_threshold    => in_override_system_threshold
    );
END;

PROCEDURE UNSEC_SetAuditScore(
    in_internal_audit_sid            IN    internal_audit_score.internal_audit_sid%TYPE,
    in_score_type_id                IN    internal_audit_score.score_type_id%TYPE,
    in_score                        IN    internal_audit_score.score%TYPE,
    in_score_threshold_id            IN    internal_audit_score.score_threshold_id%TYPE,
    in_override_system_threshold    IN    NUMBER
)
AS
    v_count                            NUMBER(10) := 0;
    v_score_threshold_id            NUMBER(10) := in_score_threshold_id;
    v_score_type_label                score_type.label%TYPE;
    v_score_threshold_desc            score_threshold.description%TYPE;
    v_internal_audit_type_id        internal_audit.internal_audit_type_id%TYPE;
BEGIN
    SELECT label
      INTO v_score_type_label
      FROM score_type
     WHERE score_type_id = in_score_type_id;

    SELECT internal_audit_type_id
      INTO v_internal_audit_type_id
      FROM internal_audit
     WHERE internal_audit_sid = in_internal_audit_sid;

    SELECT COUNT(*)
      INTO v_count
      FROM score_type st
      JOIN score_threshold sth ON st.score_type_id = sth.score_type_id
     WHERE st.score_type_id = in_score_type_id
       AND sth.score_threshold_id = v_score_threshold_id
       AND st.applies_to_audits = 1
       AND (st.score_type_id IN (
               SELECT stat.score_type_id 
                 FROM score_type_audit_type stat
                WHERE stat.internal_audit_type_id = v_internal_audit_type_id
                )
            OR NOT EXISTS (
                SELECT 1
                  FROM score_type_audit_type stat
                 WHERE stat.score_type_id = st.score_type_id
            )
        );

    IF v_count = 0 AND v_score_threshold_id IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Can only overwrite score threshold with a threshold from the score type associated with the audit.');
    END IF;

    IF in_override_system_threshold = 0 THEN
        v_score_threshold_id := quick_survey_pkg.GetThresholdFromScore(in_score_type_id, in_score);
    END IF;

    IF v_score_threshold_id IS NULL THEN
        v_score_threshold_desc := 'no threshold';
    ELSE
        SELECT description
          INTO v_score_threshold_desc
          FROM score_threshold
         WHERE score_threshold_id = v_score_threshold_id;
    END IF;

    BEGIN
        INSERT INTO internal_audit_score (
            internal_audit_sid, score_type_id, score, score_threshold_id
        ) VALUES (
            in_internal_audit_sid, in_score_type_id, in_score, v_score_threshold_id
        );
    EXCEPTION
        WHEN dup_val_on_index THEN
            UPDATE internal_audit_score
               SET score = in_score, 
                   score_threshold_id = v_score_threshold_id
             WHERE internal_audit_sid = in_internal_audit_sid
               AND score_type_id = in_score_type_id;
    END;

    csr_data_pkg.WriteAuditLogEntry(
        SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'), 
        in_internal_audit_sid, 'Set {0} to {1} ({2})', v_score_type_label, in_score, v_score_threshold_desc
    );
END;

PROCEDURE GetAuditsByInternalRef (
    in_internal_audit_ref        IN internal_audit.internal_audit_ref%TYPE,
    out_audits_cur                OUT    SYS_REFCURSOR
)
AS 
BEGIN
    OPEN out_audits_cur FOR
        SELECT internal_audit_sid
          FROM internal_audit
         WHERE internal_audit_ref = in_internal_audit_ref
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAuditsByExternalAuditRef (
    in_external_audit_ref        IN internal_audit.external_audit_ref%TYPE,
    out_audits_cur                OUT    SYS_REFCURSOR
)
AS 
BEGIN
    OPEN out_audits_cur FOR
        SELECT internal_audit_sid
          FROM internal_audit
         WHERE external_audit_ref = in_external_audit_ref
           AND deleted = 0
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAuditsByExternalParentRef (
    in_external_parent_ref        IN internal_audit.external_parent_ref%TYPE,
    out_audits_cur                OUT    SYS_REFCURSOR
)
AS 
BEGIN
    OPEN out_audits_cur FOR
        SELECT internal_audit_sid
          FROM internal_audit
         WHERE external_parent_ref = in_external_parent_ref
           AND deleted = 0
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAuditsByInternalAuditTypeAndCompanySid (
    in_internal_audit_type_id        IN internal_audit.internal_audit_type_id%TYPE,
    in_company_sid                    IN security_pkg.T_SID_ID,
    out_audits_cur                    OUT    SYS_REFCURSOR
)
AS 
BEGIN
    OPEN out_audits_cur FOR
        SELECT ia.internal_audit_sid, ia.internal_audit_type_id, s.company_sid
          FROM internal_audit ia
          JOIN csr.supplier s ON ia.region_sid = s.region_sid
         WHERE ia.internal_audit_type_id = in_internal_audit_type_id
           AND s.company_sid = in_company_sid
           AND ia.deleted = 0
           AND ia.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION GetAuditTypeByLookup (
    in_audit_type_lookup            IN  internal_audit_type.lookup_key%TYPE
) RETURN NUMBER
AS
    v_audit_type_id                    internal_audit_type.internal_audit_type_id%TYPE;
BEGIN
    BEGIN
    SELECT internal_audit_type_id
      INTO v_audit_type_id
      FROM internal_audit_type
     WHERE lookup_key = in_audit_type_lookup
       AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    EXCEPTION
        WHEN no_data_found THEN
            v_audit_type_id := -1;
    END;

    RETURN v_audit_type_id;
END;

PROCEDURE DeleteAuditsOfTypeFromRegion (
    in_act_sid                        IN  security_pkg.T_ACT_ID,
    in_audit_type_lookup            IN  internal_audit_type.lookup_key%TYPE,
    in_region_sid                    IN    internal_audit.region_sid%TYPE
)
AS
    v_audit_type_id                    NUMBER;            
BEGIN
    v_audit_type_id := GetAuditTypeByLookup(in_audit_type_lookup);
    
    FOR i in (SELECT internal_audit_sid
                FROM csr.internal_audit
               WHERE internal_audit_type_id = v_audit_type_id
                 AND region_sid = in_region_sid)
    LOOP
        DeleteObject(in_act_sid, i.internal_audit_sid); 
    END LOOP;
END;

END temp_audit_pkg;
/

sho err;

CREATE OR REPLACE PACKAGE csr.temp_tag_pkg
AS

PROCEDURE DeleteTagGroup(
    in_act_id            IN security_pkg.T_ACT_ID,
    in_tag_group_id        IN tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroup(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_app_sid                        IN    security_pkg.T_SID_ID,
    in_name                            IN  tag_group_description.name%TYPE,
    in_multi_select                    IN    tag_group.multi_select%TYPE,
    in_mandatory                    IN    tag_group.mandatory%TYPE,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroupByName(
    in_act_id                        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid                        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_name                            IN    tag_group_description.name%TYPE,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE,
    in_excel_import                    IN    NUMBER,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroup(
    in_act_id                        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid                        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_tag_group_id                    IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_name                            IN  tag_group_description.name%TYPE,
    in_multi_select                    IN    tag_group.multi_select%TYPE DEFAULT 0,
    in_mandatory                    IN    tag_group.mandatory%TYPE DEFAULT 0,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE DEFAULT 0,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE DEFAULT 0,
    in_applies_to_non_comp            IN    tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE DEFAULT 0,
    in_applies_to_chain                IN    tag_group.applies_to_chain%TYPE DEFAULT 0,
    in_applies_to_chain_activities    IN    tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
    in_applies_to_initiatives        IN    tag_group.applies_to_initiatives%TYPE DEFAULT 0,
    in_applies_to_chain_prod_types    IN    tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
    in_applies_to_chain_products    IN    tag_group.applies_to_chain_products%TYPE DEFAULT 0,
    in_applies_to_chain_prod_supps    IN    tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
    in_applies_to_quick_survey        IN    tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
    in_applies_to_audits            IN    tag_group.applies_to_audits%TYPE DEFAULT 0,
    in_applies_to_compliances        IN    tag_group.applies_to_compliances%TYPE DEFAULT 0,
    in_excel_import                    IN  NUMBER DEFAULT 0,
    in_lookup_key                    IN    tag_group.lookup_key%TYPE DEFAULT NULL,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
);

PROCEDURE CreateTagGroup(
    in_act_id                        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid                        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_name                            IN  tag_group_description.name%TYPE,
    in_multi_select                    IN    tag_group.multi_select%TYPE DEFAULT 0,
    in_mandatory                    IN    tag_group.mandatory%TYPE DEFAULT 0,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE DEFAULT 0,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE DEFAULT 0,
    in_applies_to_non_comp            IN    tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE DEFAULT 0,
    in_applies_to_chain                IN    tag_group.applies_to_chain%TYPE DEFAULT 0,
    in_applies_to_chain_activities    IN    tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
    in_applies_to_initiatives        IN    tag_group.applies_to_initiatives%TYPE DEFAULT 0,
    in_applies_to_chain_prod_types    IN    tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
    in_applies_to_chain_products    IN    tag_group.applies_to_chain_products%TYPE DEFAULT 0,
    in_applies_to_chain_prod_supps    IN    tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
    in_applies_to_quick_survey        IN    tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
    in_applies_to_audits            IN    tag_group.applies_to_audits%TYPE DEFAULT 0,
    in_applies_to_compliances        IN    tag_group.applies_to_compliances%TYPE DEFAULT 0,
    in_excel_import                    IN  NUMBER DEFAULT 0,
    in_lookup_key                    IN    tag_group.lookup_key%TYPE DEFAULT NULL,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroupRegionTypes(
    in_tag_group_id                    IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_region_type_ids                IN    security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupNCTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_nc_ids                IN    security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupIATypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_ia_ids                IN    security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupInitiativeTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_init_type_ids        IN    security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupCompanyTypes(
    in_tag_group_id                    IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_company_type_ids                IN    security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupDescription(
    in_tag_group_id                    IN    tag_group_description.tag_group_id%TYPE,
    in_langs                        IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_descriptions                    IN    security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetTagGroupDescription(
    in_tag_group_id                    IN    tag_group_description.tag_group_id%TYPE,
    in_lang                            IN    tag_group_description.lang%TYPE,
    in_description                    IN    tag_group_description.name%TYPE
);

-- update or insert tag 
/**
 * SetTag
 * 
 * @param in_act_id                Access token
 * @param in_tag_group_id        .
 * @param in_tag_id                .
 * @param in_tag                .
 * @param in_explanation        .
 * @param in_pos                .
 * @param in_parent_id            .
 * @param out_tag_id            .
 */
PROCEDURE SetTag(
    in_act_id                IN    security_pkg.T_ACT_ID                DEFAULT SYS_CONTEXT('SECURITY','ACT'),
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    in_tag_id                IN    tag.tag_id%TYPE                        DEFAULT NULL,
    in_tag                    IN    tag_description.tag%TYPE,
    in_explanation            IN    tag_description.explanation%TYPE    DEFAULT NULL,
    in_pos                    IN    tag_group_member.pos%TYPE            DEFAULT NULL,
    in_lookup_key            IN    tag.lookup_key%TYPE                    DEFAULT NULL,
    in_parent_id            IN    tag.parent_id%TYPE                    DEFAULT NULL,
    in_parent_lookup_key    IN    VARCHAR2                            DEFAULT NULL,
    out_tag_id                OUT    tag.tag_id%TYPE
);
PROCEDURE SetTag(
    in_act_id                IN    security_pkg.T_ACT_ID                DEFAULT SYS_CONTEXT('SECURITY','ACT'),
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    in_tag_id                IN    tag.tag_id%TYPE                        DEFAULT NULL,
    in_tag                    IN    tag_description.tag%TYPE,
    in_explanation            IN    tag_description.explanation%TYPE    DEFAULT NULL,
    in_pos                    IN    tag_group_member.pos%TYPE            DEFAULT NULL,
    in_lookup_key            IN    tag.lookup_key%TYPE                    DEFAULT NULL,
    in_active                IN    tag_group_member.active%TYPE,
    in_parent_id            IN    tag.parent_id%TYPE                    DEFAULT NULL,
    in_parent_lookup_key    IN    VARCHAR2                            DEFAULT NULL,
    out_tag_id                OUT    tag.tag_id%TYPE
);

PROCEDURE SetTagDescription(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_langs                        IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_descriptions                    IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_explanations                    IN    security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetTagDescription(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_lang                            IN    tag_description.lang%TYPE,
    in_description                    IN    tag_description.tag%TYPE,
    in_explanation                    IN    tag_description.explanation%TYPE,
    in_set_tag                        IN  NUMBER DEFAULT 1,
    in_set_explanation                IN  NUMBER DEFAULT 1
);

PROCEDURE SetTagDescriptionTag(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_lang                            IN    tag_description.lang%TYPE,
    in_description                    IN    tag_description.tag%TYPE
);

PROCEDURE SetTagDescriptionExplanation(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_lang                            IN    tag_description.lang%TYPE,
    in_description                    IN    tag_description.explanation%TYPE
);


/**
 * Useful for quickly importing things from Excel since it
 * takes names not ids, and will automatically create things
 * that don't exist.
 */
PROCEDURE SetIndicatorTag(
    in_ind_sid            IN    security_pkg.T_SID_ID,
    in_tag_group_name    IN    tag_group_description.name%TYPE,
    in_tag                IN    tag_description.tag%TYPE
);

PROCEDURE INTERNAL_AddCalcJobs(
    in_tag_id        tag.tag_id%TYPE
);

PROCEDURE SetRegionTag(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_group_name    IN    tag_group_description.name%TYPE,
    in_tag                IN    tag_description.tag%TYPE
);

PROCEDURE UNSEC_SetRegionTag(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_id            IN     tag.tag_id%TYPE
);

PROCEDURE SetNonComplianceTag(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_tag_group_name        IN    tag_group_description.name%TYPE,
    in_tag                    IN    tag_description.tag%TYPE
);

/**
 * Sort tag group members alphabetically - useful if you
 * import a load of things with SetIndicatorTag from Excel
 */
PROCEDURE SortTagGroupMembers(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_tag_group_id        IN    tag_group.tag_group_id%TYPE
);

/**
 * RemoveTagFromGroup
 * 
 * @param in_act_id                Access token
 * @param in_tag_group_id        .
 * @param in_tag_id                .
 */
PROCEDURE RemoveTagFromGroup(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    in_tag_id                IN    tag.tag_id%TYPE
);


PROCEDURE GetIndTags(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_ind_sid                        IN    security_pkg.T_SID_ID,
    out_cur                            OUT    SYS_REFCURSOR
);

PROCEDURE GetMultipleIndTags(
    in_ind_sids                        IN    security_pkg.T_SID_IDS,
    out_cur                            OUT    SYS_REFCURSOR
);

PROCEDURE SetIndTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_ind_sid        IN    security_pkg.T_SID_ID,
    in_set_tag_ids            IN    security_pkg.T_SID_IDS
);

PROCEDURE RemoveIndicatorTag(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_ind_sid            IN    security_pkg.T_SID_ID,
    in_tag_id            IN    NUMBER,
    out_rows_updated    OUT    NUMBER
);

PROCEDURE RemoveIndicatorTagGroup(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_ind_sid            IN    security_pkg.T_SID_ID,
    in_tag_group_id        IN    NUMBER,
    out_rows_updated    OUT    NUMBER
);


PROCEDURE GetRegionTags(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_region_sid                    IN    security_pkg.T_SID_ID,
    out_cur                            OUT    SYS_REFCURSOR
);

PROCEDURE GetMultipleRegionTags(
    in_region_sids                    IN    security_pkg.T_SID_IDS,
    out_cur                            OUT    SYS_REFCURSOR
);

PROCEDURE UNSEC_GetRegionTags(
    in_id_list                        IN  security.T_ORDERED_SID_TABLE,
    out_tags_cur                    OUT    SYS_REFCURSOR
);

/**
 * SetRegionTags
 * 
 * @param in_act_id            Access token
 * @param in_region_sid        The sid of the object
 * @param in_tag_ids        .
 */
PROCEDURE SetRegionTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    VARCHAR2
);


PROCEDURE SetRegionTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    security_pkg.T_SID_IDS -- they're not sids, but it'll do
);

PROCEDURE RemoveRegionTag(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_region_sid            IN    security_pkg.T_SID_ID,
    in_tag_id                IN    NUMBER,
    in_apply_dynamic_plans    IN    NUMBER DEFAULT 1,
    out_rows_updated        OUT    NUMBER
);

PROCEDURE RemoveRegionTagGroup(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_region_sid            IN    security_pkg.T_SID_ID,
    in_tag_group_id            IN    NUMBER,
    in_apply_dynamic_plans    IN    NUMBER DEFAULT 1,
    out_rows_updated        OUT    NUMBER
);

PROCEDURE GetNonComplianceTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetNonComplianceTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_tag_ids                IN    VARCHAR2
);


PROCEDURE SetNonComplianceTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_tag_ids                IN    security_pkg.T_SID_IDS -- they're not sids, but it'll do
);


-- returns the Projects and tag groups this user can see 
/**
 * GetTagGroups
 * 
 * @param in_act_id                Access token
 * @param in_app_sid            The sid of the Application/CSR object
 * @param out_cur                The rowset
 */
PROCEDURE GetTagGroups(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);
-- and the translations
/**
 * GetTagGroupDescriptions
 * 
 * @param in_act_id                Access token
 * @param in_app_sid            The sid of the Application/CSR object
 * @param in_tag_group_id        Optional filter
 * @param out_cur                The rowset
 */
PROCEDURE GetTagGroupDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetTagGroupDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);


/**
* Get recursive tag groups to support CDP
*/    
PROCEDURE GetAllTagGroups (
    out_tag_group_cur        OUT    SYS_REFCURSOR,
    out_tag_group_text_cur    OUT    SYS_REFCURSOR,
    out_tag_cur                OUT    SYS_REFCURSOR,
    out_tag_text_cur        OUT    SYS_REFCURSOR,
    out_region_types_cur    OUT    SYS_REFCURSOR,
    out_audit_types_cur        OUT    SYS_REFCURSOR,
    out_company_types_cur    OUT    SYS_REFCURSOR,
    out_non_compl_types_cur    OUT    SYS_REFCURSOR
);


PROCEDURE GetTagGroup(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_tag_name            IN    tag_group_description.name%TYPE,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
);

-- returns basic details of specified tag_group 
/**
 * GetTagGroup
 * 
 * @param in_act_id                Access token
 * @param in_tag_group_id        .
 * @param out_cur                The rowset
 */
PROCEDURE GetTagGroup(
    in_act_id                    IN    security_pkg.T_ACT_ID,
    in_tag_group_id                IN    tag_group.tag_group_id%TYPE,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);
    


/**
 * GetTagGroupMembers
 * 
 * @param in_act_id                Access token
 * @param in_tag_group_id        .
 * @param out_cur                The rowset
 */
PROCEDURE GetTagGroupMembers(
    in_act_id                    IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_tag_group_id                IN    security_pkg.T_SID_ID,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
);

/**
 * GetTagGroupMembersByGroupLookup
 * 
 * @param in_tag_group_lookup        Lookup key of a tag group
 * @param out_tg_members            The rowset of tag group members
 */
PROCEDURE GetTagGroupMembersByGroupLookup(
    in_tag_group_lookup            IN    tag_group.lookup_key%TYPE,
    out_tg_members                OUT    security_pkg.T_OUTPUT_CUR
);

-- and the translations
/**
 * GetTagGroupMemberDescriptions
 * 
 * @param in_act_id                Access token
 * @param in_app_sid            The sid of the Application/CSR object
 * @param in_tag_group_id        Optional filter
 * @param out_cur                The rowset
 */
PROCEDURE GetTagGroupMemberDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetTagGroupMemberDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);



/**
 * GetAllTagGroupsAndMembers
 * 
 * @param in_act_id                Access token
 * @param in_app_sid        The sid of the Application/CSR object
 * @param out_cur                The rowset
 */
PROCEDURE GetAllTagGroupsAndMembers(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_app_sid            IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetAllTagGroupsAndMembersInd(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_app_sid    IN    security_pkg.T_SID_ID,
    in_ind_sid        IN    security_pkg.T_SID_ID,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllTagGroupsAndMembersReg(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_app_sid                IN    security_pkg.T_SID_ID,
    in_region_sid            IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
);

/**
 * ConcatTagGroupMembers
 * 
 * @param in_tag_group_id        .
 * @param in_max_length            .
 * @return                         .
 */
FUNCTION ConcatTagGroupMembers(
    in_tag_group_id        IN    tag_group.tag_group_id%TYPE,
    in_max_length        IN     INTEGER
) RETURN VARCHAR2;


/**
 * GetTagGroupsSummary
 * 
 * @param in_act_id                Access token
 * @param in_app_sid            The sid of the Application/CSR object
 * @param out_cur                The rowset
 */
PROCEDURE GetTagGroupsSummary(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_app_sid        IN    security_pkg.T_SID_ID,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetTagGroupRegionMembers(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupIndMembers(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupNCMembers(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
);

/* for internal use only */
PROCEDURE INTERNAL_TryCreateTag(
    in_tag_group_name                IN    tag_group_description.name%TYPE,
    in_tag                            IN    tag_description.tag%TYPE,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE DEFAULT 0,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE DEFAULT 0,
    in_applies_to_non_comp            IN    tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE DEFAULT 0,
    in_applies_to_chain                IN    tag_group.applies_to_chain%TYPE DEFAULT 0,
    in_applies_to_chain_activities    IN    tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
    in_applies_to_initiatives        IN    tag_group.applies_to_initiatives%TYPE DEFAULT 0,
    in_applies_to_chain_prod_types    IN    tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
    in_applies_to_chain_products    IN    tag_group.applies_to_chain_products%TYPE DEFAULT 0,
    in_applies_to_chain_prod_supps    IN    tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
    in_applies_to_quick_survey        IN    tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
    in_applies_to_audits            IN    tag_group.applies_to_audits%TYPE DEFAULT 0,
    in_applies_to_compliances        IN    tag_group.applies_to_compliances%TYPE DEFAULT 0,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_id                        OUT    tag.tag_id%TYPE
);

PROCEDURE DeactivateTag(
    in_tag_id                IN    tag.tag_id%TYPE,
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE
);

PROCEDURE ActivateTag(
    in_tag_id                IN    tag.tag_id%TYPE,
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE
);

PROCEDURE SetRegionTagsFast(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    security_pkg.T_SID_IDS
);

PROCEDURE GetTag(
    in_tag_id                        IN    tag.tag_id%TYPE,
    out_tag_cur                        OUT    SYS_REFCURSOR
);

PROCEDURE GetTagGroupRegionTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetTagGroupInternalAuditTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetTagGroupNCTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetTagGroupCompanyTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetTagGroupInitiativeTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetAllCatTranslations(
    in_validation_lang        IN    tag_group_description.lang%TYPE,
    in_changed_since        IN    DATE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE ValidateCatTranslations(
    in_tag_group_ids        IN    security.security_pkg.T_SID_IDS,
    in_descriptions            IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_validation_lang        IN    tag_group_description.lang%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetAllTagTranslations(
    in_validation_lang        IN    tag_description.lang%TYPE,
    in_changed_since        IN    DATE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetAllTagExplTranslations(
    in_validation_lang        IN    tag_description.lang%TYPE,
    in_changed_since        IN    DATE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE ValidateTagTranslations(
    in_tag_ids                IN    security.security_pkg.T_SID_IDS,
    in_descriptions            IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_validation_lang        IN    tag_description.lang%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE ValidateTagExplTranslations(
    in_tag_ids                IN    security.security_pkg.T_SID_IDS,
    in_descriptions            IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_validation_lang        IN    tag_description.lang%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
);

PROCEDURE GetTagGroups(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_app_sid                        IN    security_pkg.T_SID_ID,
    out_tag_group_cur                OUT    SYS_REFCURSOR,
    out_tag_group_tr_cur            OUT    SYS_REFCURSOR,
    out_tag_cur                        OUT    SYS_REFCURSOR,
    out_tag_tr_cur                    OUT    SYS_REFCURSOR
);

END temp_tag_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_tag_pkg AS

PROCEDURE DeleteTagGroup(
    in_act_id            IN security_pkg.T_ACT_ID,
    in_tag_group_id        IN tag_group.tag_group_id%TYPE
) 
AS
    v_app_sid     security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid 
      INTO v_app_sid 
      FROM tag_group 
     WHERE tag_group_id = in_tag_group_id;
    
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
    END IF;

    -- First let's see if Tags of the Group are in use. If at least one of them is in use then the group itself is not allowed to be deleted.
    -- To see if each tag are being used just go ahead and try to delete them to see whether it throws an exception or not.
    --      (Note: first you have to delete the tag from the TAG_GROUP_MEMBER table)
    -- When all tags under the group have been deleted then the group itself can be deleted as well
    FOR r IN (
        SELECT DISTINCT tgm.tag_id
          FROM TAG_GROUP_MEMBER tgm
         WHERE tgm.tag_group_id = in_tag_group_id
    )
    LOOP
        RemoveTagFromGroup(in_act_id, in_tag_group_id, r.tag_id);
    END LOOP;
    
    DELETE FROM region_type_tag_group
     WHERE tag_group_Id = in_tag_group_id;
    
    DELETE FROM project_tag_group
     WHERE tag_group_Id = in_tag_group_id;

    DELETE FROM donations.region_filter_tag_group
     WHERE region_tag_group_Id = in_tag_group_id;
     
    DELETE FROM property_element_layout
     WHERE tag_group_id = in_tag_group_id;
     
    DELETE FROM property_character_layout
     WHERE tag_group_id = in_tag_group_id;
     
    DELETE FROM meter_element_layout
     WHERE tag_group_id = in_tag_group_id;
     
    DELETE FROM meter_header_element
     WHERE tag_group_id = in_tag_group_id;

    DELETE FROM internal_audit_type_tag_group
     WHERE tag_group_id = in_tag_group_id;
     
    DELETE FROM chain.company_type_tag_group
     WHERE tag_group_id = in_tag_group_id;
     
    DELETE FROM non_compliance_type_tag_group
     WHERE tag_group_id = in_tag_group_id;
     
    DELETE FROM benchmark_dashboard_char
     WHERE tag_group_id = in_tag_group_id;

    DELETE FROM tag_group_description
     WHERE tag_group_id = in_tag_group_id;

    DELETE FROM tag_group
     WHERE tag_group_id = in_tag_group_id;
END;

PROCEDURE SetTagGroup(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_app_sid                        IN    security_pkg.T_SID_ID,
    in_name                            IN  tag_group_description.name%TYPE,
    in_multi_select                    IN    tag_group.multi_select%TYPE,
    in_mandatory                    IN    tag_group.mandatory%TYPE,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
)
AS
BEGIN
    SetTagGroup(
        in_act_id => in_act_id, 
        in_app_sid => in_app_sid, 
        in_name => in_name, 
        in_multi_select => in_multi_select, 
        in_mandatory => in_mandatory, 
        in_applies_to_inds => in_applies_to_inds, 
        in_applies_to_regions => in_applies_to_regions, 
        in_applies_to_non_comp => 0,
        in_is_hierarchical => in_is_hierarchical,
        out_tag_group_id => out_tag_group_id
    );
END;

PROCEDURE SetTagGroupByName(
    in_act_id                        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid                        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_name                            IN    tag_group_description.name%TYPE,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE,
    in_excel_import                    IN    NUMBER,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
)
AS
    v_tag_group_id                    tag_group.tag_group_id%TYPE;
    v_multi_select                    tag_group.multi_select%TYPE;
    v_mandatory                        tag_group.mandatory%TYPE;
    v_applies_to_inds                tag_group.applies_to_inds%TYPE;
    v_applies_to_regions            tag_group.applies_to_regions%TYPE;
    v_applies_to_suppliers            tag_group.applies_to_suppliers%TYPE;
    v_applies_to_non_comp            tag_group.applies_to_non_compliances%TYPE;
    v_applies_to_chain                tag_group.applies_to_chain%TYPE;
    v_applies_to_chain_activities    tag_group.applies_to_chain_activities%TYPE;
    v_applies_to_initiatives        tag_group.applies_to_initiatives%TYPE;
    v_applies_to_chain_prod_types    tag_group.applies_to_chain_product_types%TYPE;
    v_applies_to_chain_products        tag_group.applies_to_chain_products%TYPE;
    v_applies_to_chain_prod_supps    tag_group.applies_to_chain_product_supps%TYPE;
    v_applies_to_quick_survey        tag_group.applies_to_quick_survey%TYPE;
    v_applies_to_audits                tag_group.applies_to_audits%TYPE;
    v_applies_to_compliances        tag_group.applies_to_compliances%TYPE;
    v_lookup_key                    tag_group.lookup_key%TYPE;
    v_is_hierarchical                tag_group.is_hierarchical%TYPE;
BEGIN
    BEGIN
        SELECT tag_group_id, multi_select, mandatory, NVL(in_applies_to_inds, applies_to_inds),
               NVL(in_applies_to_regions, applies_to_regions), NVL(in_applies_to_suppliers, applies_to_suppliers),
               applies_to_non_compliances, applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
               applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
               applies_to_quick_survey, applies_to_audits, applies_to_compliances, lookup_key, is_hierarchical
          INTO v_tag_group_id, v_multi_select, v_mandatory, v_applies_to_inds,
               v_applies_to_regions, v_applies_to_suppliers, 
               v_applies_to_non_comp, v_applies_to_chain, v_applies_to_chain_activities, v_applies_to_initiatives,
               v_applies_to_chain_prod_types, v_applies_to_chain_products, v_applies_to_chain_prod_supps,
               v_applies_to_quick_survey, v_applies_to_audits, v_applies_to_compliances, v_lookup_key, v_is_hierarchical
          FROM v$tag_group
         WHERE UPPER(name) = UPPER(in_name)
           AND app_sid = SYS_CONTEXT('SECURITY','APP');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            SetTagGroup(
                in_act_id                    => in_act_id,
                in_app_sid                    => in_app_sid,
                in_name                        => in_name,
                in_applies_to_inds            => in_applies_to_inds,
                in_applies_to_regions        => in_applies_to_regions,
                in_applies_to_suppliers        => in_applies_to_suppliers,
                in_excel_import                => in_excel_import,
                out_tag_group_id            => out_tag_group_id
            );
            RETURN;
    END;
    
    SetTagGroup(
        in_act_id                        => in_act_id,
        in_app_sid                        => in_app_sid,
        in_tag_group_id                    => v_tag_group_id,
        in_name                            => in_name,
        in_multi_select                    => v_multi_select,
        in_mandatory                    => v_mandatory,
        in_applies_to_inds                => v_applies_to_inds,
        in_applies_to_regions            => v_applies_to_regions,
        in_applies_to_suppliers            => v_applies_to_suppliers,
        in_excel_import                    => in_excel_import,
        in_applies_to_chain                => v_applies_to_chain,
        in_applies_to_chain_activities    => v_applies_to_chain_activities,
        in_applies_to_initiatives        => v_applies_to_initiatives,
        in_applies_to_chain_prod_types    => v_applies_to_chain_prod_types,
        in_applies_to_chain_products    => v_applies_to_chain_products,
        in_applies_to_chain_prod_supps    => v_applies_to_chain_prod_supps,
        in_applies_to_quick_survey        => v_applies_to_quick_survey,
        in_applies_to_audits            => v_applies_to_audits,
        in_applies_to_compliances        => v_applies_to_compliances,
        in_lookup_key                    => v_lookup_key,
        in_is_hierarchical                => v_is_hierarchical,
        out_tag_group_id                => out_tag_group_id
    );
END;

-- creates or amends a tag_group
PROCEDURE SetTagGroup(
    in_act_id                        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid                        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_tag_group_id                    IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_name                            IN  tag_group_description.name%TYPE,
    in_multi_select                    IN    tag_group.multi_select%TYPE DEFAULT 0,
    in_mandatory                    IN    tag_group.mandatory%TYPE DEFAULT 0,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE DEFAULT 0,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE DEFAULT 0,
    in_applies_to_non_comp            IN    tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE DEFAULT 0,
    in_applies_to_chain                IN    tag_group.applies_to_chain%TYPE DEFAULT 0,
    in_applies_to_chain_activities    IN    tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
    in_applies_to_initiatives        IN    tag_group.applies_to_initiatives%TYPE DEFAULT 0,
    in_applies_to_chain_prod_types    IN    tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
    in_applies_to_chain_products    IN    tag_group.applies_to_chain_products%TYPE DEFAULT 0,
    in_applies_to_chain_prod_supps    IN    tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
    in_applies_to_quick_survey        IN    tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
    in_applies_to_audits            IN    tag_group.applies_to_audits%TYPE DEFAULT 0,
    in_applies_to_compliances        IN    tag_group.applies_to_compliances%TYPE DEFAULT 0,
    in_excel_import                    IN  NUMBER DEFAULT 0,
    in_lookup_key                    IN    tag_group.lookup_key%TYPE DEFAULT NULL,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
)
AS
    v_applies_to_non_comp            tag_group.applies_to_non_compliances%TYPE;
    v_count_non_comp                NUMBER;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
    END IF;
    
    IF in_tag_group_id IS NULL THEN
        BEGIN
            CreateTagGroup(
                in_act_id                        =>    in_act_id,
                in_app_sid                        =>    in_app_sid,
                in_name                            =>    in_name,
                in_multi_select                    =>    in_multi_select,
                in_mandatory                    =>    CASE in_excel_import WHEN 1 THEN 0 ELSE in_mandatory END,
                in_applies_to_inds                =>    in_applies_to_inds,
                in_applies_to_regions            =>    in_applies_to_regions,
                in_applies_to_non_comp            =>    in_applies_to_non_comp,
                in_applies_to_suppliers            =>    in_applies_to_suppliers,
                in_applies_to_chain                =>    in_applies_to_chain,
                in_applies_to_chain_activities    =>    in_applies_to_chain_activities,
                in_applies_to_initiatives        =>    in_applies_to_initiatives,
                in_applies_to_chain_prod_types    =>    in_applies_to_chain_prod_types,
                in_applies_to_chain_products    =>    in_applies_to_chain_products,
                in_applies_to_chain_prod_supps    =>    in_applies_to_chain_prod_supps,
                in_applies_to_quick_survey        =>    in_applies_to_quick_survey,
                in_applies_to_audits            =>    in_applies_to_audits,
                in_applies_to_compliances        =>    in_applies_to_compliances,
                in_excel_import                    =>    in_excel_import,
                in_lookup_key                    =>    in_lookup_key,
                in_is_hierarchical                =>    in_is_hierarchical,
                out_tag_group_id                =>    out_tag_group_id
            );
        EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            BEGIN
                SELECT tag_group_id
                  INTO out_tag_group_id
                  FROM tag_group
                 WHERE app_sid = in_app_sid
                   AND UPPER(lookup_key) = UPPER(in_lookup_key);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    SELECT tag_group_id
                      INTO out_tag_group_id
                      FROM v$tag_group
                     WHERE app_sid = in_app_sid
                       AND UPPER(name) = UPPER(in_name);
            END;
        END;
    ELSE
        -- Force a NO_DATA_FOUND exception if the supplied id is not valid.
        SELECT applies_to_non_compliances
          INTO v_applies_to_non_comp
          FROM tag_group
         WHERE tag_group_id = in_tag_group_id;
        
        -- only check non-compliances atm, don't want to blindly apply to all applies to options, but raise a generic error, so it can be extended
        IF v_applies_to_non_comp = 1 AND in_applies_to_non_comp = 0 THEN
            SELECT COUNT(*)
              INTO v_count_non_comp
              FROM tag_group_ir_member nct
              JOIN audit_non_compliance anc ON anc.non_compliance_id = nct.non_compliance_id
             WHERE tag_group_id = in_tag_group_id;
             
            IF v_count_non_comp > 0 THEN
                RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_TAG_APPLIES_CHANGE, 'Cannot change what a Tag Group applies to after it has been used.');
            END IF;            
        END IF;
        
        UPDATE tag_group
           SET multi_select = in_multi_select,
             mandatory = CASE WHEN in_excel_import = 1 THEN mandatory ELSE in_mandatory END, 
             applies_to_inds = in_applies_to_inds,
             applies_to_regions = in_applies_to_regions,
             applies_to_non_compliances = in_applies_to_non_comp,
             applies_to_suppliers = in_applies_to_suppliers,
             applies_to_chain = in_applies_to_chain,
             applies_to_chain_activities = in_applies_to_chain_activities,
             applies_to_initiatives = in_applies_to_initiatives,
             applies_to_chain_product_types = in_applies_to_chain_prod_types,
             applies_to_chain_products = in_applies_to_chain_products,
             applies_to_chain_product_supps = in_applies_to_chain_prod_supps,
             applies_to_quick_survey = in_applies_to_quick_survey,
             applies_to_audits = in_applies_to_audits,
             applies_to_compliances = in_applies_to_compliances,
             lookup_key = in_lookup_key,
             is_hierarchical = in_is_hierarchical
         WHERE tag_group_id = in_tag_group_id
           AND app_sid = in_app_sid;
        
        BEGIN
            UPDATE tag_group_description
               SET name = NVL(in_name, 'Tag Group '||in_tag_group_id)
             WHERE tag_group_id = in_tag_group_id 
               AND lang = 'en'
               AND app_sid = in_app_sid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO tag_group_description
                    (app_sid, tag_group_id, lang, name)
                VALUES (in_app_sid, in_tag_group_id, 'en', NVL(in_name, 'Tag Group '||in_tag_group_id));
        END;

        out_tag_group_id := in_tag_group_id;
    END IF;
END;

-- creates a tag_group
PROCEDURE CreateTagGroup(
    in_act_id                        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid                        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_name                            IN    tag_group_description.name%TYPE,
    in_multi_select                    IN    tag_group.multi_select%TYPE DEFAULT 0,
    in_mandatory                    IN    tag_group.mandatory%TYPE DEFAULT 0,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE DEFAULT 0,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE DEFAULT 0,
    in_applies_to_non_comp            IN    tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE DEFAULT 0,
    in_applies_to_chain                IN    tag_group.applies_to_chain%TYPE DEFAULT 0,
    in_applies_to_chain_activities    IN    tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
    in_applies_to_initiatives        IN    tag_group.applies_to_initiatives%TYPE DEFAULT 0,
    in_applies_to_chain_prod_types    IN    tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
    in_applies_to_chain_products    IN    tag_group.applies_to_chain_products%TYPE DEFAULT 0,
    in_applies_to_chain_prod_supps    IN    tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
    in_applies_to_quick_survey        IN    tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
    in_applies_to_audits            IN    tag_group.applies_to_audits%TYPE DEFAULT 0,
    in_applies_to_compliances        IN    tag_group.applies_to_compliances%TYPE DEFAULT 0,
    in_excel_import                    IN    NUMBER DEFAULT 0,
    in_lookup_key                    IN    tag_group.lookup_key%TYPE DEFAULT NULL,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_group_id                OUT    tag_group.tag_group_id%TYPE
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
    END IF;
    
    INSERT INTO tag_group
        (app_sid, tag_group_id, multi_select, mandatory, 
        applies_to_inds, applies_to_regions, applies_to_non_compliances,
        applies_to_suppliers, applies_to_chain, applies_to_chain_activities, applies_to_initiatives, 
        applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
        applies_to_quick_survey, applies_to_audits, applies_to_compliances, lookup_key, is_hierarchical)
    VALUES (in_app_sid, tag_group_id_seq.nextval, in_multi_select, CASE in_excel_import WHEN 1 THEN 0 ELSE in_mandatory END,
        in_applies_to_inds, in_applies_to_regions, in_applies_to_non_comp,
        in_applies_to_suppliers, in_applies_to_chain, in_applies_to_chain_activities, in_applies_to_initiatives,
        in_applies_to_chain_prod_types, in_applies_to_chain_products, in_applies_to_chain_prod_supps,
        in_applies_to_quick_survey, in_applies_to_audits, in_applies_to_compliances, in_lookup_key, in_is_hierarchical)
    RETURNING tag_group_id INTO out_tag_group_id;

    INSERT INTO tag_group_description
        (app_sid, tag_group_id, lang, name)
    VALUES (in_app_sid, out_tag_group_id, 'en', NVL(in_name, 'Tag Group '||out_tag_group_id));
END;

PROCEDURE SetTagGroupRegionTypes(
    in_tag_group_id                    IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_region_type_ids                IN    security_pkg.T_SID_IDS
)
AS
    v_region_type_t    security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_region_type_ids);
BEGIN
    --clear old values and re-insert
    DELETE FROM region_type_tag_group
      WHERE tag_group_id = in_tag_group_id;
      
    INSERT INTO region_type_tag_group (region_type, tag_group_id)
    SELECT column_value, in_tag_group_id
      FROM TABLE(v_region_type_t);
END;

PROCEDURE SetTagGroupCompanyTypes(
    in_tag_group_id                    IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_company_type_ids                IN    security_pkg.T_SID_IDS
)
AS
    v_ct_type_t    security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_company_type_ids);
BEGIN
    --clear old values and re-insert
    DELETE FROM chain.company_type_tag_group
      WHERE tag_group_id = in_tag_group_id;
      
    INSERT INTO chain.company_type_tag_group (company_type_id, tag_group_id)
    SELECT column_value, in_tag_group_id
      FROM TABLE(v_ct_type_t);
END;

PROCEDURE SetTagGroupNCTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_nc_ids                IN    security_pkg.T_SID_IDS
)
AS
    v_nc_type_t    security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_nc_ids);
BEGIN
    --clear old values and re-insert
    DELETE FROM non_compliance_type_tag_group
      WHERE tag_group_id = in_tag_group_id;
      
    INSERT INTO non_compliance_type_tag_group (non_compliance_type_id, tag_group_id)
    SELECT column_value, in_tag_group_id
      FROM TABLE(v_nc_type_t);
END;

PROCEDURE SetTagGroupIATypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_ia_ids                IN    security_pkg.T_SID_IDS
)
AS
    v_ia_type_t    security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_ia_ids);
BEGIN
    --clear old values and re-insert
    DELETE FROM internal_audit_type_tag_group
      WHERE tag_group_id = in_tag_group_id;
      
    INSERT INTO internal_audit_type_tag_group (internal_audit_type_id, tag_group_id)
    SELECT column_value, in_tag_group_id
      FROM TABLE(v_ia_type_t);
END;

PROCEDURE SetTagGroupInitiativeTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE DEFAULT NULL,
    in_init_type_ids        IN    security_pkg.T_SID_IDS
)
AS
    v_init_type_t    security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_init_type_ids);
BEGIN
    --Clear old values and re-insert
    DELETE FROM project_tag_group
      WHERE tag_group_id = in_tag_group_id;
     
    INSERT INTO project_tag_group (project_sid, tag_group_id)
    SELECT column_value, in_tag_group_id
      FROM TABLE(v_init_type_t);
END;

PROCEDURE SetTagGroupDescription(
    in_tag_group_id                    IN    tag_group_description.tag_group_id%TYPE,
    in_langs                        IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_descriptions                    IN    security.security_pkg.T_VARCHAR2_ARRAY
)
AS
    v_app            security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act            security_pkg.T_ACT_ID := security_pkg.GetACT;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    IF in_langs.COUNT != in_descriptions.COUNT THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Data mismatch');
    END IF;

    FOR i IN 1..in_langs.COUNT
    LOOP
        SetTagGroupDescription(in_tag_group_id, in_langs(i), in_descriptions(i));
    END LOOP;
END;

PROCEDURE SetTagGroupDescription(
    in_tag_group_id                    IN    tag_group_description.tag_group_id%TYPE,
    in_lang                            IN    tag_group_description.lang%TYPE,
    in_description                    IN    tag_group_description.name%TYPE
)
AS
    v_app            security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act            security_pkg.T_ACT_ID := security_pkg.GetACT;
    v_description    region_description.description%TYPE;
    v_current_name    tag_group_description.name%TYPE;
    v_action        VARCHAR2(50);
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    BEGIN
        SELECT name
          INTO v_current_name
          FROM tag_group_description
         WHERE app_sid = v_app
           AND tag_group_id = in_tag_group_id
           AND lang = in_lang;

        IF in_description IS NULL THEN
            DELETE FROM tag_group_description
             WHERE app_sid = v_app
               AND tag_group_id = in_tag_group_id
               AND lang = in_lang;
            
            v_action := 'deleted';
        END IF;

        IF in_description IS NOT NULL AND v_current_name != in_description THEN
            UPDATE tag_group_description
               SET name = in_description, last_changed_dtm = SYSDATE
             WHERE app_sid = v_app
               AND tag_group_id = in_tag_group_id
               AND lang = in_lang;
            
            v_action := 'updated';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF in_description IS NOT NULL THEN
                INSERT INTO tag_group_description (app_sid, tag_group_id, lang, name, last_changed_dtm)
                VALUES (v_app, in_tag_group_id, in_lang, in_description, SYSDATE);
            
                v_action := 'created';
            END IF;
    END;
    
    IF v_action IS NOT NULL THEN
        csr_data_pkg.WriteAuditLogEntry(
            v_act,
            csr_data_pkg.AUDIT_TYPE_TAG_DESC_CHANGED,
            v_app,
            NULL,
            'Category Description '||v_action||' ('||in_tag_group_id||')',
            in_lang,
            v_current_name,
            in_description,
            in_tag_group_id
            );
    END IF;
END;

PROCEDURE INTERNAL_TryCreateTag(
    in_tag_group_name                IN    tag_group_description.name%TYPE,
    in_tag                            IN    tag_description.tag%TYPE,
    in_applies_to_inds                IN    tag_group.applies_to_inds%TYPE DEFAULT 0,
    in_applies_to_regions            IN    tag_group.applies_to_regions%TYPE DEFAULT 0,
    in_applies_to_non_comp            IN    tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
    in_applies_to_suppliers            IN    tag_group.applies_to_suppliers%TYPE DEFAULT 0,
    in_applies_to_chain                IN    tag_group.applies_to_chain%TYPE DEFAULT 0,
    in_applies_to_chain_activities    IN    tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
    in_applies_to_initiatives        IN    tag_group.applies_to_initiatives%TYPE DEFAULT 0,
    in_applies_to_chain_prod_types    IN    tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
    in_applies_to_chain_products    IN    tag_group.applies_to_chain_products%TYPE DEFAULT 0,
    in_applies_to_chain_prod_supps    IN    tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
    in_applies_to_quick_survey        IN    tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
    in_applies_to_audits            IN    tag_group.applies_to_audits%TYPE DEFAULT 0,
    in_applies_to_compliances        IN    tag_group.applies_to_compliances%TYPE DEFAULT 0,
    in_is_hierarchical                IN    tag_group.is_hierarchical%TYPE DEFAULT 0,
    out_tag_id                        OUT    tag.tag_id%TYPE
)
AS
    v_pos                tag_group_member.pos%TYPE;
    v_tag_group_id        tag_group.tag_group_id%TYPE;
BEGIN
    -- try read, or create tag_group
    BEGIN
        SELECT tag_group_id
          INTO v_tag_group_id
          FROM v$tag_group
         WHERE app_sid = security_pkg.getApp
           AND LOWER(name) = LOWER(in_tag_group_name)
           FOR UPDATE; -- lock
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO tag_group 
                (app_sid, tag_group_id, multi_select, mandatory, 
                applies_to_inds, applies_to_regions, applies_to_non_compliances, applies_to_suppliers, 
                applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
                applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
                applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical)
            VALUES 
                (security_pkg.getApp, tag_group_id_seq.nextval, 1, 0,
                in_applies_to_inds, in_applies_to_regions, in_applies_to_non_comp, in_applies_to_suppliers,
                in_applies_to_chain, in_applies_to_chain_activities, in_applies_to_initiatives, 
                in_applies_to_chain_prod_types, in_applies_to_chain_products, in_applies_to_chain_prod_supps,
                in_applies_to_quick_survey, in_applies_to_audits, in_applies_to_compliances, in_is_hierarchical)
            RETURNING tag_group_id INTO v_tag_group_id;
            
            INSERT INTO tag_group_description
                (tag_group_id, lang, name)
            VALUES (v_tag_group_id, 'en', NVL(in_tag_group_name, 'Tag Group '||v_tag_group_id));
    END;
    
    -- try read or create tag
    BEGIN
        SELECT t.tag_id
          INTO out_tag_id
          FROM v$tag t, tag_group_member tgm
         WHERE t.tag_id = tgm.tag_id
           AND LOWER(t.tag) = LOWER(in_tag)
           AND tgm.tag_group_id = v_tag_group_id
           AND UPPER(tag) = UPPER(in_tag)
           FOR UPDATE; -- lock
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO tag 
                (tag_id)
            VALUES
                (tag_id_seq.nextval)
            RETURNING tag_id INTO out_tag_id;
            
            INSERT INTO tag_description 
                (tag_id, lang, tag, explanation)
            VALUES
                (out_tag_id, 'en', NVL(in_tag, 'Tag '||out_tag_id), null);
            
            BEGIN
                SELECT NVL(MAX(pos),0)
                  INTO v_pos
                  FROM tag_group_member
                 WHERE tag_group_id = v_tag_group_id
                 GROUP BY tag_group_Id;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_pos := 0;
            END;
            INSERT INTO tag_group_member
                (tag_group_id, tag_id, pos)
            VALUES (v_tag_group_id, out_tag_id, v_pos+1);
    END;
END;

/**
 * Useful for quickly importing things from Excel since it
 * takes names not ids, and will automatically create things
 * that don't exist.
 */
PROCEDURE SetIndicatorTag(
    in_ind_sid            IN    security_pkg.T_SID_ID,
    in_tag_group_name    IN    tag_group_description.name%TYPE,
    in_tag                IN    tag_description.tag%TYPE
)
AS
    v_tag_id            tag.tag_id%TYPE;
    v_pos                tag_group_member.pos%TYPE;
    v_tag_group_id        tag_group.tag_group_id%TYPE;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_ind_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    INTERNAL_TryCreateTag(
        in_tag_group_name     => in_tag_group_name, 
        in_tag                => in_tag, 
        in_applies_to_inds    => 1,
        out_tag_id            => v_tag_id);
    
    -- assign tag to indicator
    BEGIN
        INSERT INTO IND_TAG (tag_id, ind_sid) VALUES (v_tag_id, in_ind_sid);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN    
            NULL;
    END;
END;

PROCEDURE INTERNAL_AddCalcJobs(
    in_tag_id        tag.tag_id%TYPE
)
AS
BEGIN
    FOR r IN (
        SELECT DISTINCT calc_ind_sid
          FROM calc_tag_dependency
         WHERE tag_id = in_tag_id
     ) LOOP
        calc_pkg.AddJobsForCalc(r.calc_ind_sid);
     END LOOP;
END;

PROCEDURE INTERNAL_RegionTagChangeAudit(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_id             IN    tag.tag_id%TYPE,
    in_log_msg            IN    VARCHAR2
)
AS
    v_tag_name            tag_description.tag%TYPE;
    v_tag_group_name    tag_group_description.name%TYPE;
BEGIN
    BEGIN
        SELECT tag, name
          INTO v_tag_name, v_tag_group_name
          FROM v$tag t, v$tag_group tg
         WHERE t.tag_id = in_tag_id 
           AND tag_group_id = (
                    SELECT tag_group_id
                      FROM tag_group_member
                     WHERE tag_id = in_tag_id);
                     
        csr_data_pkg.WriteAuditLogEntry(
            security_pkg.GetACT,
            csr_data_pkg.AUDIT_TYPE_REGION_TAG_CHANGED,
            security_pkg.GetAPP,
            in_region_sid,
            in_log_msg,
            v_tag_group_name,
            v_tag_name);
    EXCEPTION 
     WHEN NO_DATA_FOUND THEN
        NULL;
    END;
END;

/**
 * Useful for quickly importing things from Excel since it
 * takes names not ids, and will automatically create things
 * that don't exist.
 */
PROCEDURE SetRegionTag(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_group_name    IN    tag_group_description.name%TYPE,
    in_tag                IN    tag_description.tag%TYPE
)
AS
    v_tag_id            tag.tag_id%TYPE;
    v_plan_created        NUMBER;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_region_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    INTERNAL_TryCreateTag(
        in_tag_group_name         => in_tag_group_name, 
        in_tag                    => in_tag, 
        in_applies_to_regions    => 1,
        out_tag_id                => v_tag_id);
    
    -- assign tag to region
    BEGIN
        INSERT INTO region_tag (tag_id, region_sid) 
        VALUES (v_tag_id, in_region_sid);
        
        INTERNAL_RegionTagChangeAudit(in_region_sid, v_tag_id, 'Added "{1}" to category "{0}"');
            
        -- Update any dynamic delegation plans that depend on this region
        region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN    
            NULL;
    END;
    
    INTERNAL_AddCalcJobs(v_tag_id);
END;

PROCEDURE UNSEC_SetRegionTag(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_id            IN     tag.tag_id%TYPE
)
AS
BEGIN
    -- assign tag to region
    BEGIN
        INSERT INTO region_tag (tag_id, region_sid) 
        VALUES (in_tag_id, in_region_sid);
        
        INTERNAL_RegionTagChangeAudit(in_region_sid, in_tag_id, 'Added "{1}" to category "{0}"');
            
        -- Update any dynamic delegation plans that depend on this region
        region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN    
            NULL;
    END;
    
    INTERNAL_AddCalcJobs(in_tag_id);
END;

PROCEDURE SetNonComplianceTag(
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_tag_group_name        IN    tag_group_description.name%TYPE,
    in_tag                    IN    tag_description.tag%TYPE
)
AS
    v_tag_id            tag.tag_id%TYPE;
BEGIN
    audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denied setting tags to non-compliance with id: '||in_non_compliance_id);
    
    INTERNAL_TryCreateTag(
        in_tag_group_name         => in_tag_group_name, 
        in_tag                    => in_tag, 
        in_applies_to_non_comp    => 1,
        out_tag_id                => v_tag_id);
    
    -- assign tag to region
    BEGIN
        INSERT INTO NON_COMPLIANCE_TAG (tag_id, non_compliance_id) VALUES (v_tag_id, in_non_compliance_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN    
            NULL;
    END;
END;

/**
 * Sort tag group members alphabetically - useful if you
 * import a load of things with SetIndicatorTag from Excel
 */
PROCEDURE SortTagGroupMembers(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_tag_group_id        IN    tag_group.tag_group_id%TYPE
)
AS
    v_app_sid        security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    FOR r IN (
        SELECT rownum rn, x.*
             FROM (
            SELECT t.tag_id, tgm.tag_group_id 
              FROM tag_group_member tgm, v$tag t 
             WHERE tgm.tag_id = t.tag_id 
               AND tag_group_id IN (in_tag_group_Id) 
             ORDER BY tag
        )x
    )
    LOOP
        UPDATE tag_group_member SET pos = r.rn WHERE tag_id = r.tag_id AND tag_group_id = r.tag_group_id;
    END LOOP;
END;

-- update or insert tag 
PROCEDURE SetTag(
    in_act_id                IN    security_pkg.T_ACT_ID                DEFAULT SYS_CONTEXT('SECURITY','ACT'),
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    in_tag_id                IN    tag.tag_id%TYPE                        DEFAULT NULL,
    in_tag                    IN    tag_description.tag%TYPE,
    in_explanation            IN    tag_description.explanation%TYPE    DEFAULT NULL,
    in_pos                    IN    tag_group_member.pos%TYPE            DEFAULT NULL,
    in_lookup_key            IN    tag.lookup_key%TYPE                    DEFAULT NULL,
    in_parent_id            IN    tag.parent_id%TYPE                    DEFAULT NULL,
    in_parent_lookup_key    IN    VARCHAR2                            DEFAULT NULL,
    out_tag_id                OUT    tag.tag_id%TYPE
)
AS
BEGIN
    SetTag(
        in_act_id => in_act_id, 
        in_tag_group_id => in_tag_group_id,
        in_tag_id => in_tag_id,
        in_tag => in_tag,
        in_explanation => in_explanation,
        in_pos => in_pos,
        in_lookup_key => in_lookup_key,
        in_active => 1,
        in_parent_id => in_parent_id,
        in_parent_lookup_key => in_parent_lookup_key,
        out_tag_id => out_tag_id
    );
END;

-- update or insert tag 
PROCEDURE SetTag(
    in_act_id                IN    security_pkg.T_ACT_ID                DEFAULT SYS_CONTEXT('SECURITY','ACT'),
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    in_tag_id                IN    tag.tag_id%TYPE                        DEFAULT NULL,
    in_tag                    IN    tag_description.tag%TYPE,
    in_explanation            IN    tag_description.explanation%TYPE    DEFAULT NULL,
    in_pos                    IN    tag_group_member.pos%TYPE            DEFAULT NULL,
    in_lookup_key            IN    tag.lookup_key%TYPE                    DEFAULT NULL,
    in_active                IN    tag_group_member.active%TYPE,
    in_parent_id            IN    tag.parent_id%TYPE                    DEFAULT NULL,
    in_parent_lookup_key    IN    VARCHAR2                            DEFAULT NULL,
    out_tag_id                OUT    tag.tag_id%TYPE
)
AS
    v_app_sid            security_pkg.T_SID_ID;
    v_tag_id            tag.tag_id%TYPE;
    v_parent_id            tag.parent_id%TYPE;
    v_existing_tag_id    tag.tag_id%TYPE;
BEGIN
    SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    IF in_parent_lookup_key IS NOT NULL THEN
        SELECT tag_id
          INTO v_parent_id
          FROM tag
         WHERE lookup_key = in_parent_lookup_key;
    ELSE
        v_parent_id := in_parent_id;
    END IF;
    

    v_tag_id := in_tag_id;
    IF NVL(v_tag_id, -1) = -1 THEN
        BEGIN
            SELECT MIN(t.tag_id) INTO v_tag_id
              FROM v$tag t, tag_group_member tgm
             WHERE t.app_sid = v_app_sid
               AND t.tag_id = tgm.tag_id
               AND tgm.tag_group_id = in_tag_group_id
               AND t.tag = in_tag
             ORDER BY t.tag_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tag_id := NULL;
        END;
    ELSE -- v_tag_id is not NULL or -1
        BEGIN
            SELECT tag_id
              INTO v_tag_id
              FROM tag
             WHERE app_sid = v_app_sid
               AND tag_id = v_tag_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tag_id := NULL;
        END;
    END IF;
    
    IF v_tag_id IS NULL THEN
        -- If we have an orphaned tag record (i.e. has no tag membership) that is the same as the incoming one, reuse it.
        SELECT MIN(t.tag_id)
          INTO v_existing_tag_id
          FROM tag t
          LEFT JOIN tag_group_member tgm ON tgm.tag_id = t.tag_id AND tgm.tag_group_id = in_tag_group_id AND tgm.app_sid = v_app_sid
         WHERE t.lookup_key = in_lookup_key
           AND t.app_sid = v_app_sid
           AND tgm.tag_group_id IS NULL;
        
        IF v_existing_tag_id IS NOT NULL THEN
            v_tag_id := v_existing_tag_id;
            UPDATE tag_description
               SET tag = NVL(in_tag, 'Tag '||v_tag_id), explanation = in_explanation
             WHERE tag_id = v_tag_id
               AND lang = 'en';
        ELSE
            INSERT INTO tag (tag_id, lookup_key, parent_id)
            VALUES (tag_id_seq.nextval, in_lookup_key, v_parent_id)
            RETURNING tag_id into v_tag_id;
            
            INSERT INTO tag_description (tag_id, lang, tag, explanation)
            VALUES (v_tag_id, 'en', NVL(in_tag, 'Tag '||out_tag_id), in_explanation);
        END IF;

        INSERT INTO tag_group_member (tag_group_id, tag_id, pos, active)
        SELECT in_tag_group_id, v_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_active
          FROM tag_group_member;
        
        out_tag_id := v_tag_id;
    ELSE
        UPDATE tag
           SET lookup_key = in_lookup_key,
               parent_id = v_parent_id
         WHERE tag_id = v_tag_id;
        
        UPDATE tag_description
           SET tag = NVL(in_tag, 'Tag '||v_tag_id), explanation = in_explanation
         WHERE tag_id = v_tag_id
           AND lang = 'en';
        
        BEGIN
            SELECT tag_id INTO v_tag_id FROM tag_group_member
             WHERE tag_id = v_tag_id 
               AND tag_group_id = in_tag_group_id
            FOR UPDATE;
            
            UPDATE tag_group_member
               SET active = in_active
             WHERE tag_id = v_tag_id 
               AND tag_group_id = in_tag_group_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO tag_group_member
                    (tag_group_id, tag_id, pos, active)
                SELECT in_tag_group_id, v_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_active
                  FROM tag_group_member;
        END;
        
        IF in_pos IS NOT NULL THEN
            UPDATE tag_group_member
               SET pos = in_pos, active = in_active
             WHERE tag_id = v_tag_id 
               AND tag_group_id = in_tag_group_id;
        END IF;
        
        out_tag_id := v_tag_id;
    END IF;
END;

PROCEDURE SetTagDescription(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_langs                        IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_descriptions                    IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_explanations                    IN    security.security_pkg.T_VARCHAR2_ARRAY
)
AS
    v_app                security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act                security_pkg.T_ACT_ID := security_pkg.GetACT;
    v_current_tag        tag_description.tag%TYPE;
    v_current_expl        tag_description.explanation%TYPE;
    v_action            VARCHAR2(50);
    v_target1            VARCHAR2(50);
    v_target2            VARCHAR2(50);
    v_targetseparator    VARCHAR2(50);
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    IF in_langs.COUNT != in_descriptions.COUNT AND in_langs.COUNT != in_explanations.COUNT THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Data mismatch');
    END IF;

    FOR i IN 1..in_langs.COUNT
    LOOP
        SetTagDescription(in_tag_id, in_langs(i), in_descriptions(i), in_explanations(i));
    END LOOP;
END;

PROCEDURE SetTagDescription(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_lang                            IN    tag_description.lang%TYPE,
    in_description                    IN    tag_description.tag%TYPE,
    in_explanation                    IN    tag_description.explanation%TYPE,
    in_set_tag                        IN  NUMBER DEFAULT 1,
    in_set_explanation                IN  NUMBER DEFAULT 1
)
AS
    v_app                security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act                security_pkg.T_ACT_ID := security_pkg.GetACT;
    v_current_tag        tag_description.tag%TYPE;
    v_current_expl        tag_description.explanation%TYPE;
    v_action            VARCHAR2(50);
    v_target1            VARCHAR2(50);
    v_target2            VARCHAR2(50);
    v_targetseparator    VARCHAR2(50);
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(v_act, v_app, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    BEGIN
        SELECT tag, explanation
          INTO v_current_tag, v_current_expl
          FROM tag_description
         WHERE app_sid = v_app
           AND tag_id = in_tag_id
           AND lang = in_lang;

        IF in_set_tag = 1 AND 
           in_description IS NULL AND in_explanation IS NULL
        THEN
            DELETE FROM tag_description
             WHERE app_sid = v_app
               AND tag_id = in_tag_id
               AND lang = in_lang;
            
            v_action := 'deleted';
        END IF;
        
        IF in_set_tag = 1 AND
           in_description IS NOT NULL AND 
           (v_current_tag IS NULL OR v_current_tag != in_description)
        THEN
            UPDATE tag_description
               SET tag = in_description, last_changed_dtm = SYSDATE
             WHERE app_sid = v_app
               AND tag_id = in_tag_id
               AND lang = in_lang;
            
            v_action := 'updated';
            v_target1 := 'name ';
        END IF;

        IF in_set_explanation = 1 AND 
           in_explanation IS NOT NULL AND
           (v_current_expl IS NULL OR v_current_expl != in_explanation)
        THEN
            UPDATE tag_description
               SET explanation = in_explanation, last_changed_dtm = SYSDATE
             WHERE app_sid = v_app
               AND tag_id = in_tag_id
               AND lang = in_lang;
            v_action := 'updated';
            v_target2 := 'explanation ';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            IF in_description IS NOT NULL THEN
                INSERT INTO tag_description (app_sid, tag_id, lang, tag, explanation, last_changed_dtm)
                VALUES (v_app, in_tag_id, in_lang, in_description, in_explanation, SYSDATE);
            
                v_action := 'created';
                v_target1 := 'name ';
            END IF;
    END;

    IF v_action IS NOT NULL THEN
        IF v_target1 IS NOT NULL AND v_target2 IS NOT NULL THEN
            v_targetseparator := 'and ';
        END IF;
        
        csr_data_pkg.WriteAuditLogEntry(
            v_act,
            csr_data_pkg.AUDIT_TYPE_TAG_DESC_CHANGED,
            v_app,
            NULL,
            'Tag Description '||v_target1||v_targetseparator||v_target2||v_action||' ('||in_tag_id||')',
            in_lang,
            v_current_tag,
            in_description,
            in_tag_id
            );
    END IF;
END;

PROCEDURE SetTagDescriptionTag(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_lang                            IN    tag_description.lang%TYPE,
    in_description                    IN    tag_description.tag%TYPE
)
AS
BEGIN
    SetTagDescription(in_tag_id, in_lang, in_description, NULL, 1, 0);
END;

PROCEDURE SetTagDescriptionExplanation(
    in_tag_id                        IN    tag_description.tag_id%TYPE,
    in_lang                            IN    tag_description.lang%TYPE,
    in_description                    IN    tag_description.explanation%TYPE
)
AS
BEGIN
    SetTagDescription(in_tag_id, in_lang, NULL, in_description, 0, 1);
END;

PROCEDURE RemoveTagFromGroup(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    in_tag_id                IN    tag.tag_id%TYPE
)
AS
    v_in_use    NUMBER(10);
    v_app_sid    security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    FOR r IN (
        SELECT tag_id
          FROM tag
         WHERE parent_id = in_tag_id
    )
    LOOP
        RemoveTagFromGroup(
            in_act_id => in_act_id,
            in_tag_group_id => in_tag_group_id,
            in_tag_id => r.tag_id
        );
    END LOOP;

/*
    -- check to see if tag is in use for this tag_group_id
    SELECT COUNT(*) INTO v_in_use
      FROM TASK t, TASK_TAG tt, project_tag_group ptg
     WHERE tt.tag_id = in_tag_id    -- donations where tag is in use
       AND tt.task_sid = t.task_sid -- join to task
       AND t.project_sid = ptg.project_sid -- join to project_tag_group
       AND ptg.tag_group_id = in_tag_group_id; -- in our tag group
    
    IF v_in_use > 0 THEN 
        RAISE_APPLICATION_ERROR(project_pkg.ERR_TAG_IN_USE, 'Tag in use');
    END IF;
*/
    DELETE FROM tag_group_member
     WHERE tag_group_id = in_tag_group_id
       AND tag_id = in_tag_id;
    
    SELECT COUNT(tag_group_id)
      INTO v_in_use
      FROM tag_group_member
     WHERE tag_id = in_tag_id;
    
    IF v_in_use = 0 THEN
        DELETE FROM compliance_region_tag
         WHERE tag_id = in_tag_id;
    END IF;
    
    -- try deleting the tag and any descriptions.
    BEGIN
        DELETE FROM tag_description
         WHERE tag_id = in_tag_id;
         
        DELETE FROM tag
         WHERE tag_id = in_tag_id;
    EXCEPTION
        WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
            RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 'Tag id '||in_tag_id||' in use');
    END;
END;

PROCEDURE GetIndTags(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_ind_sid                        IN    security_pkg.T_SID_ID,
    out_cur                            OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on ind '||in_ind_sid);
    END IF;
    
    OPEN out_cur FOR
        SELECT tgir.tag_group_id, tgir.pos, tgir.tag_id, tgir.tag, tgir.region_sid,
               tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
          FROM tag_group_ir_member tgir, v$tag_group tg 
         WHERE tgir.ind_sid = in_ind_sid
           AND tgir.tag_group_id = tg.tag_group_id
         ORDER BY tgir.tag_group_id, tgir.pos, tgir.tag_id, LOWER(tg.name);
END;

PROCEDURE GetMultipleIndTags(
    in_ind_sids                        IN    security_pkg.T_SID_IDS,
    out_cur                            OUT    SYS_REFCURSOR
)
AS
    v_ind_sids                        security.T_SID_TABLE;
    v_total_sids                    NUMBER;
    v_readable_sids                    NUMBER;
BEGIN
    v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
    
    SELECT COUNT(DISTINCT column_value) total_sids
      INTO v_total_sids
      FROM TABLE(v_ind_sids);

    SELECT COUNT(DISTINCT sid_id) readable_sids
      INTO v_readable_sids
      FROM TABLE(securableobject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
                    v_ind_sids, security_pkg.PERMISSION_READ));

    IF v_total_sids != v_readable_sids THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on one or more indicators');
    END IF;

    OPEN out_cur FOR
        SELECT tgir.tag_group_id, tgir.pos, tgir.tag_id, tgir.tag, tgir.region_sid,
               tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
          FROM TABLE(v_ind_sids) i,
               tag_group_ir_member tgir, v$tag_group tg
         WHERE tgir.ind_sid = i.column_value
           AND tgir.tag_group_id = tg.tag_group_id
         ORDER BY tgir.tag_group_id, tgir.pos, tgir.tag_id, LOWER(tg.name);
END;

PROCEDURE Internal_AuditIndTag(
    in_ind_sid        IN    security_pkg.T_SID_ID,
    in_tag_id        IN    IND_TAG.tag_id%TYPE,
    in_audit_action    IN  CHAR
)
AS    
    v_tag_name            tag_description.tag%TYPE;
    v_tag_group_name    tag_group_description.name%TYPE;
BEGIN
    SELECT tag
      INTO v_tag_name
      FROM v$tag
     WHERE tag_id = in_tag_id;

    SELECT name
      INTO v_tag_group_name
      FROM v$tag_group
     WHERE tag_group_id = (
        SELECT tag_group_id
          FROM tag_group_member
         WHERE tag_id = in_tag_id
    );

    csr_data_pkg.WriteAuditLogEntry(
            security_pkg.GetACT,
            csr_data_pkg.AUDIT_TYPE_IND_TAG_CHANGED,
            security_pkg.GetAPP,
            in_ind_sid,
            CASE in_audit_action
                WHEN 'D' THEN 'Deleted {0} / {1}'
                WHEN 'I' THEN 'Added {0} / {1}'
            END,
            v_tag_group_name,
            v_tag_name
    );
END;

PROCEDURE SetIndTags(
    in_act_id    IN    security_pkg.T_ACT_ID,
    in_ind_sid    IN    security_pkg.T_SID_ID,
    in_set_tag_ids    IN    security_pkg.T_SID_IDS
)
AS
    v_app_sid    security_pkg.T_SID_ID;    
    v_current_tag_ids    security_pkg.T_SID_IDS;
BEGIN
    SELECT app_sid 
      INTO v_app_sid
      FROM ind
     WHERE ind_sid = in_ind_sid;

    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    --Add current tag_ids into an associative array
    FOR r IN (
        SELECT tag_id
          FROM IND_TAG
         WHERE IND_SID = in_ind_sid
    )    
    LOOP
        v_current_tag_ids(r.tag_id) := r.tag_id;--The v_current_tag_ids is going to be sparse when iterating
    END LOOP;    

    -- hack for ODP.NET which doesn't support empty arrays
    IF NOT (in_set_tag_ids.COUNT = 1 AND in_set_tag_ids(1) IS NULL) THEN
        IF in_set_tag_ids.COUNT>0 THEN
            FOR i IN in_set_tag_ids.FIRST..in_set_tag_ids.LAST     -- Go through each ID that we want to set
            LOOP
                IF  v_current_tag_ids.EXISTS(in_set_tag_ids(i)) THEN  --(this is a key exists, too pity that there is no check for value exists)
                    -- remove from current_ids so we don't try to delete
                    v_current_tag_ids.DELETE(in_set_tag_ids(i));                    
                ELSE
                    -- insert and audit 
                    INSERT INTO IND_TAG
                        (ind_sid, tag_id)
                    VALUES
                        (in_ind_sid, in_set_tag_ids(i));            
                    --log record        
                    Internal_AuditIndTag(in_ind_sid, in_set_tag_ids(i), 'I');                    
                END IF;
            END LOOP;
        END IF;
    END IF;    
    
    --Delete and audit, v_current_tag_ids contains records marked for deletion. I can't use FORALL because I want to call Internal_AuditIndTag too
    IF v_current_tag_ids.COUNT>0 THEN
        FOR i IN v_current_tag_ids.FIRST..v_current_tag_ids.LAST
        LOOP
            IF v_current_tag_ids.EXISTS(i) THEN --Remember the v_current_tag_ids is sparse
                DELETE FROM IND_TAG              
                 WHERE IND_SID = in_ind_sid
                   AND tag_id = v_current_tag_ids(i);            
                --log record
                Internal_AuditIndTag(in_ind_sid, v_current_tag_ids(i), 'D');
            END IF;
        END LOOP;
    END IF;
END;

PROCEDURE RemoveIndicatorTag(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_ind_sid            IN    security_pkg.T_SID_ID,
    in_tag_id            IN    NUMBER,
    out_rows_updated    OUT    NUMBER
)
AS
BEGIN
    DELETE FROM ind_tag
     WHERE ind_sid = in_ind_sid
       AND tag_id = in_tag_id
       AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    
    out_rows_updated := SQL%ROWCOUNT;
    
    IF out_rows_updated > 0 THEN
        Internal_AuditIndTag(in_ind_sid, in_tag_id, 'D');
    END IF;
    
END;

PROCEDURE RemoveIndicatorTagGroup(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_ind_sid            IN    security_pkg.T_SID_ID,
    in_tag_group_id        IN    NUMBER,
    out_rows_updated    OUT    NUMBER
)
AS
BEGIN
    FOR r IN (
        SELECT tag_id 
          FROM ind_tag
         WHERE ind_sid = in_ind_sid
           AND tag_id IN (
                SELECT tag_id 
                  FROM tag_group_member 
                 WHERE tag_group_id = in_tag_group_id
                   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
           )
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
    )
    LOOP
        Internal_AuditIndTag(in_ind_sid, r.tag_id, 'D');
    END LOOP;
    
    DELETE
      FROM ind_tag
     WHERE ind_sid = in_ind_sid
       AND tag_id IN (
            SELECT tag_id 
              FROM tag_group_member 
             WHERE tag_group_id = in_tag_group_id
               AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
       )
       AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    out_rows_updated := SQL%ROWCOUNT;
    
END;

--Its functionality plus auditing merged with the above one
/*
PROCEDURE SetIndTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_ind_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
    v_app_sid    security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid 
      INTO v_app_sid
      FROM ind
     WHERE ind_sid = in_ind_sid;
     
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    DELETE FROM IND_TAG
     WHERE IND_SID = in_ind_sid;
    
    -- crap hack for ODP.NET
    IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
            INSERT INTO IND_TAG
                (ind_sid, tag_id)
            VALUES
                (in_ind_sid, in_tag_ids(i));              
    END IF;         
END;
*/

PROCEDURE GetRegionTags(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_region_sid                    IN    security_pkg.T_SID_ID,
    out_cur                            OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_Pkg.PERMISSION_READ) THEN
        -- Leak no data but throw no error (return empty cursor)
        --     RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region ' || in_region_sid);
        OPEN out_cur FOR
            SELECT tgir.tag_group_id, tgir.tag_id, tgir.pos, tgir.tag, tgir.region_sid,
                   tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
              FROM tag_group_ir_member tgir, v$tag_group tg 
             WHERE 0 = 1;
    ELSE
        OPEN out_cur FOR
            SELECT tgir.tag_group_id, tgir.tag_id, tgir.pos, tgir.tag, tgir.region_sid,
                   tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name
              FROM tag_group_ir_member tgir, v$tag_group tg 
             WHERE tgir.region_sid = in_region_sid
               AND tgir.tag_group_id = tg.tag_group_id
             ORDER BY tgir.TAG_GROUP_ID;
    END IF;
END;

PROCEDURE GetMultipleRegionTags(
    in_region_sids                    IN    security_pkg.T_SID_IDS,
    out_cur                            OUT    SYS_REFCURSOR
)
AS
    v_region_sids                    security.T_SID_TABLE;
BEGIN
    v_region_sids := security_pkg.SidArrayToTable(in_region_sids);

    -- as for GetRegionTags -- return tags for regions, but only where read permission is granted
    -- if read permission is denied then no tag information is returned and no error is reported
    -- this seems a bit odd, but I'm keeping the existing behaviour for now
    OPEN out_cur FOR
        SELECT tgir.tag_group_id, tgir.pos, tgir.tag_id, tgir.tag, tgir.region_sid,
               tgir.ind_sid, tgir.non_compliance_id, tg.name tag_group_name, tg.lookup_key
          FROM TABLE(securableobject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
                        v_region_sids, security_pkg.PERMISSION_READ)) r,
               tag_group_ir_member tgir, v$tag_group tg
         WHERE tgir.region_sid = r.sid_id
           AND tgir.tag_group_id = tg.tag_group_id
         ORDER BY tgir.tag_group_id;
END;

PROCEDURE UNSEC_GetRegionTags(
    in_id_list                        IN  security.T_ORDERED_SID_TABLE,
    out_tags_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_tags_cur FOR
        SELECT rt.region_sid, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag, tgm.pos
          FROM TABLE(in_id_list) fil_list
          JOIN region_tag rt ON fil_list.sid_id = rt.region_sid
          JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
          JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
          JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
         WHERE tg.applies_to_regions = 1
         ORDER BY tgm.tag_group_id, tgm.pos;
END;

PROCEDURE INTERNAL_DeleteRegionTags(
    in_region_sid        IN    security_pkg.T_SID_ID
)
AS
    v_current_tags        NUMBER;
BEGIN
    DELETE FROM region_tag
     WHERE region_sid = in_region_sid;
END;

PROCEDURE INTERNAL_GetAuditRegTagChgs(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    VARCHAR2,
    out_added_tags        OUT    SYS_REFCURSOR,
    out_removed_tags    OUT    SYS_REFCURSOR
)
AS
    v_app_sid            security_pkg.T_SID_ID;
    v_current_tags      security.T_SID_TABLE := security.T_SID_TABLE();
    v_index             NUMBER;
    v_input_tags          security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
    SELECT app_sid 
      INTO v_app_sid
      FROM csr.region
     WHERE region_sid = in_region_sid;
     
    v_index := 1;
    FOR r IN (
        SELECT tag_id
          FROM csr.region_tag
         WHERE region_sid = in_region_sid
    ) LOOP
        v_current_tags.Extend(1);
        v_current_tags(v_index) := r.tag_id;
        v_index := v_index + 1;
    END LOOP;
   
    v_index := 1;
    FOR r IN (
        SELECT t.item tag_id
          FROM TABLE(csr.utils_pkg.splitstring(in_tag_ids,',')) t
    ) LOOP
        v_input_tags.Extend(1);
        v_input_tags(v_index) := r.tag_id;
        v_index := v_index + 1;
    END LOOP;
  
    OPEN out_added_tags FOR
        SELECT column_value tag_id from TABLE(v_input_tags) MINUS SELECT column_value from TABLE(v_current_tags);
    
    OPEN out_removed_tags FOR
        SELECT column_value tag_id from TABLE(v_current_tags) MINUS SELECT column_value from TABLE(v_input_tags);
END;

PROCEDURE INTERNAL_AuditRegionTagChanges(
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_added_tags        IN    SYS_REFCURSOR,
    in_removed_tags        IN    SYS_REFCURSOR
)
AS
    v_tag_id             NUMBER;
BEGIN
    LOOP
        FETCH in_added_tags INTO v_tag_id;
        EXIT WHEN in_added_tags%NOTFOUND;
        INTERNAL_RegionTagChangeAudit(in_region_sid, v_tag_id, 'Added "{1}" to category "{0}"');
    END LOOP;    
    
    LOOP
        FETCH in_removed_tags INTO v_tag_id;
        EXIT WHEN in_removed_tags%NOTFOUND;
        INTERNAL_RegionTagChangeAudit(in_region_sid, v_tag_id, 'Removed "{1}" from category "{0}"');
    END LOOP;    
END;


PROCEDURE SetRegionTags(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    VARCHAR2
)
AS
    v_app_sid            security_pkg.T_SID_ID;
    v_added_tags        SYS_REFCURSOR;
    v_removed_tags        SYS_REFCURSOR;
BEGIN
    SELECT app_sid 
      INTO v_app_sid
      FROM region
     WHERE region_sid = in_region_sid;
     
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) AND NOT csr_data_pkg.CheckCapability('Edit region categories') THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    INTERNAL_GetAuditRegTagChgs(in_region_sid, in_tag_ids, v_added_tags, v_removed_tags);
    
    INTERNAL_DeleteRegionTags(in_region_sid);
    
    INSERT INTO region_tag (region_sid, tag_id)
        SELECT in_region_sid, t.item
          FROM TABLE(csr.utils_pkg.splitstring(in_tag_ids,','))t;
      
    -- Update any dynamic delegation plans that depend on this region
    region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');

    
    FOR r IN (
        SELECT t.item tag_id
          FROM TABLE(csr.utils_pkg.splitstring(in_tag_ids,',')) t
    ) LOOP
        INTERNAL_AddCalcJobs(r.tag_id);
    END LOOP;
    
    INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
END;

FUNCTION INTERNAL_GetTagList(
    in_tag_ids            IN    security_pkg.T_SID_IDS
) RETURN VARCHAR2
AS
    v_tag_ids             VARCHAR2(2000);
BEGIN
    FOR i IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
        IF LENGTH(v_tag_ids) > 0 THEN
            v_tag_ids := v_tag_ids||',';
        END IF;
        v_tag_ids := v_tag_ids||in_tag_ids(i);
    END LOOP;
    RETURN v_tag_ids;
END;

PROCEDURE SetRegionTags(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
    v_app_sid            security_pkg.T_SID_ID;
    v_tag_ids             VARCHAR2(2000);
    v_added_tags        SYS_REFCURSOR;
    v_removed_tags        SYS_REFCURSOR;
BEGIN
    SELECT app_sid 
      INTO v_app_sid
      FROM region
     WHERE region_sid = in_region_sid;
     
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    v_tag_ids := INTERNAL_GetTagList(in_tag_ids);
    
    INTERNAL_GetAuditRegTagChgs(in_region_sid, v_tag_ids, v_added_tags, v_removed_tags);

    INTERNAL_DeleteRegionTags(in_region_sid);

    -- crap hack for ODP.NET
    IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        FOR i IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
            INSERT INTO region_TAG
                (region_sid, tag_id)
            VALUES
                (in_region_sid, in_tag_ids(i));
                
            INTERNAL_AddCalcJobs(in_tag_ids(i));
        END LOOP;
    END IF;         

    INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);

    region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
END;

-- Fast because it skips auditing when there is presence of prior auditing (?).
-- Currently used by Heineken (SPM), NetworkRail.
PROCEDURE SetRegionTagsFast(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_region_sid        IN    security_pkg.T_SID_ID,
    in_tag_ids            IN    security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
    v_app_sid            security_pkg.T_SID_ID;
    v_audit_logs        NUMBER;
    v_tag_ids             VARCHAR2(2000);
    v_added_tags        SYS_REFCURSOR;
    v_removed_tags        SYS_REFCURSOR;
BEGIN
    SELECT app_sid 
      INTO v_app_sid
      FROM region
     WHERE region_sid = in_region_sid;
     
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    SELECT COUNT(*)
      INTO v_audit_logs
      FROM audit_log
     WHERE object_sid = in_region_sid;

    --useful for testing
    --v_audit_logs:=1;
    
    IF v_audit_logs = 1 THEN
        v_tag_ids := INTERNAL_GetTagList(in_tag_ids);
        INTERNAL_GetAuditRegTagChgs(in_region_sid, v_tag_ids, v_added_tags, v_removed_tags);
    END IF;

    INTERNAL_DeleteRegionTags(in_region_sid);
    
    -- crap hack for ODP.NET
    IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        FOR i IN in_tag_ids.FIRST..in_tag_ids.LAST LOOP
            INSERT INTO region_TAG
                (region_sid, tag_id)
            VALUES
                (in_region_sid, in_tag_ids(i));
            
            INTERNAL_AddCalcJobs(in_tag_ids(i));
        END LOOP;
    END IF;

    IF v_audit_logs = 1 THEN
        INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
    END IF;
END;

PROCEDURE RemoveRegionTag(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_region_sid            IN    security_pkg.T_SID_ID,
    in_tag_id                IN    NUMBER,
    in_apply_dynamic_plans    IN    NUMBER DEFAULT 1,
    out_rows_updated        OUT    NUMBER
)
AS
    v_added_tags        SYS_REFCURSOR;
    v_removed_tags        SYS_REFCURSOR;
BEGIN

    -- Get an empty cursor for added tags, as we're not adding any.
    OPEN v_added_tags FOR
        SELECT NULL tag_id
          FROM DUAL
         WHERE 0 = 1;
    
    OPEN v_removed_tags FOR
        SELECT in_tag_id
          FROM region_tag
         WHERE tag_id = in_tag_id
           AND region_sid = in_region_sid
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    
    DELETE
      FROM region_tag
     WHERE region_sid = in_region_sid
       AND tag_id = in_tag_id
       AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    
    out_rows_updated := SQL%ROWCOUNT;

    IF in_apply_dynamic_plans = 1 THEN
        -- Update any dynamic delegation plans that depend on this region
        region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
    END IF;

    FOR r IN (
        SELECT tag_id
          FROM region_tag
         WHERE region_sid = in_region_sid
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
    ) LOOP
        INTERNAL_AddCalcJobs(r.tag_id);
    END LOOP;

    INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
END;

PROCEDURE RemoveRegionTagGroup(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_region_sid            IN    security_pkg.T_SID_ID,
    in_tag_group_id            IN    NUMBER,
    in_apply_dynamic_plans    IN    NUMBER DEFAULT 1,
    out_rows_updated        OUT    NUMBER
)
AS
    v_added_tags        SYS_REFCURSOR;
    v_removed_tags        SYS_REFCURSOR;
BEGIN
    
    -- Get an empty cursor for added tags, as we're not adding any.
    OPEN v_added_tags FOR
        SELECT NULL tag_id
          FROM DUAL
         WHERE 0 = 1;
    
    OPEN v_removed_tags FOR
        SELECT tag_id 
          FROM region_tag
         WHERE region_sid = in_region_sid
           AND tag_id IN (
                SELECT tag_id 
                  FROM tag_group_member 
                 WHERE tag_group_id = in_tag_group_id
                   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
           )
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    
    DELETE
      FROM region_tag
     WHERE region_sid = in_region_sid
       AND tag_id IN (
            SELECT tag_id 
              FROM tag_group_member 
             WHERE tag_group_id = in_tag_group_id
               AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
       )
       AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
    out_rows_updated := SQL%ROWCOUNT;

    IF in_apply_dynamic_plans = 1 THEN 
        -- Update any dynamic delegation plans that depend on this region
        region_pkg.ApplyDynamicPlans(in_region_sid, 'Region tags changed');
    END IF;

    FOR r IN (
        SELECT tag_id
          FROM region_tag
         WHERE region_sid = in_region_sid
           AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
    ) LOOP
        INTERNAL_AddCalcJobs(r.tag_id);
    END LOOP;

    INTERNAL_AuditRegionTagChanges(in_region_sid, v_added_tags, v_removed_tags);
END;

PROCEDURE GetNonComplianceTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_READ, 'Access denied reading tags on non-compliance with id: '||in_non_compliance_id);
    
    OPEN out_cur FOR
        SELECT tgir.*, tg.name tag_group_name
          FROM tag_group_ir_member tgir, v$tag_group tg 
         WHERE non_compliance_id = in_non_compliance_id
           AND tgir.tag_group_id = tg.tag_group_id
         ORDER BY tgir.tag_group_id;
END;

PROCEDURE SetNonComplianceTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_tag_ids                IN    VARCHAR2
)
AS
    v_app_sid            security_pkg.T_SID_ID;
BEGIN
    audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denied setting tags to non-compliance with id: '||in_non_compliance_id);
    
    /* check it's valid for non-compliances? */
    DELETE FROM non_compliance_tag
     WHERE non_compliance_id = in_non_compliance_id;
     
    INSERT INTO non_compliance_tag
        (non_compliance_id, tag_id)
    SELECT in_non_compliance_id, t.item
      FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_ids,','))t;
END;

PROCEDURE SetNonComplianceTags(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_non_compliance_id    IN    non_compliance.non_compliance_id%TYPE,
    in_tag_ids                IN    security_pkg.T_SID_IDS -- they're not sids, but it'll do
)
AS
    v_app_sid            security_pkg.T_SID_ID;
BEGIN
    audit_pkg.CheckNonComplianceAccess(in_non_compliance_id, security_pkg.PERMISSION_WRITE, 'Access denied setting tags to non-compliance with id: '||in_non_compliance_id);
    
    /* check it's valid for non-compliances? */
    DELETE FROM non_compliance_tag
     WHERE non_compliance_id = in_non_compliance_id;
    
    -- crap hack for ODP.NET
    IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
            INSERT INTO non_compliance_tag
                (non_compliance_id, tag_id)
            VALUES
                (in_non_compliance_id, in_tag_ids(i));
    END IF;
END;

-- returns the tag groups this user can see 
PROCEDURE GetTagGroups(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    OPEN out_cur FOR
        SELECT tg.tag_group_id, tg.name, tg.mandatory, tg.multi_select, tg.applies_to_inds,
                tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
                tg.applies_to_chain, tg.applies_to_chain_activities, tg.applies_to_initiatives,
                tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
                tg.applies_to_quick_survey, tg.applies_to_audits, 
                tg.applies_to_compliances, tg.lookup_key, tg.is_hierarchical
          FROM v$tag_group tg
         WHERE tg.app_sid = in_app_sid
         ORDER BY tg.name;
END;

-- returns the tag group descriptions
PROCEDURE GetTagGroupDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    GetTagGroupDescriptions(
        in_act_id => in_act_id,
        in_app_sid => in_app_sid,
        in_tag_group_id => NULL,
        out_cur => out_cur);
END;

PROCEDURE GetTagGroupDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    OPEN out_cur FOR
        SELECT tgd.tag_group_id, tgd.lang, tgd.name, tgd.last_changed_dtm
          FROM tag_group_description tgd
         WHERE tgd.app_sid = in_app_sid
           AND tgd.tag_group_id = NVL(in_tag_group_id, tgd.tag_group_id)
         ORDER BY tgd.tag_group_id, lang;
END;

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_tag_name            IN    tag_group_description.name%TYPE,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_tag_group_id        tag_group.tag_group_id%TYPE;
BEGIN
    SELECT tag_group_id
      INTO v_tag_group_id
      FROM v$tag_group
     WHERE name = in_tag_name;
    
    GetTagGroup(in_act_id, v_tag_group_id, out_cur);
END;

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
    in_act_id            IN    security_pkg.T_ACT_ID,
    in_tag_group_id        IN    tag_group.tag_group_id%TYPE,
    out_cur                OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_app_sid    security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;
    
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT tag_group_id, name, lookup_key, mandatory, multi_select,
                applies_to_inds, applies_to_regions, applies_to_non_compliances, applies_to_suppliers,
                applies_to_chain, applies_to_chain_activities, applies_to_initiatives,
                applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
                applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical
          FROM v$tag_group
         WHERE tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupMembers(
    in_act_id                    IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_tag_group_id                IN    security_pkg.T_SID_ID,
    out_cur                        OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_app_sid    security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT t.tag_id, t.tag, t.explanation, tgm.pos, t.lookup_key, t.exclude_from_dataview_grouping, tgm.active, tgm.tag_group_id, t.parent_id
          FROM tag_group_member tgm, v$tag t
         WHERE tgm.tag_id = t.tag_id
           AND tgm.tag_group_id = in_tag_group_id
         ORDER BY pos;
END;

PROCEDURE GetTagGroupMembersByGroupLookup(
    in_tag_group_lookup            IN    tag_group.lookup_key%TYPE,
    out_tg_members                OUT    security_pkg.T_OUTPUT_CUR
)
AS
    v_tag_group_id                tag_group.tag_group_id%TYPE;
BEGIN
    SELECT tag_group_id
      INTO v_tag_group_id
      FROM tag_group
     WHERE lookup_key = in_tag_group_lookup;
     
    GetTagGroupMembers(
        in_act_id => SYS_CONTEXT('SECURITY', 'ACT'),
        in_tag_group_id => v_tag_group_id,
        out_cur => out_tg_members
    );
END;

-- returns the tag descriptions
PROCEDURE GetTagGroupMemberDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    GetTagGroupMemberDescriptions(
        in_act_id => in_act_id,
        in_app_sid => in_app_sid,
        in_tag_group_id => NULL,
        out_cur => out_cur);
END;

PROCEDURE GetTagGroupMemberDescriptions(
    in_act_id        IN    security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
    in_app_sid        IN    security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT td.tag_id, td.lang, td.tag, td.explanation, td.last_changed_dtm
          FROM tag_group_member tgm
          LEFT JOIN tag_description td ON td.TAG_ID = tgm.TAG_ID
         WHERE td.app_sid = security.security_pkg.getapp
           AND tgm.tag_group_id = NVL(in_tag_group_id, tgm.tag_group_id)
         ORDER BY td.tag_id, lang;
END;

PROCEDURE GetAllTagGroupsAndMembers(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_app_sid            IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN    
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
           SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tgm.tag_Id, tgm.pos, t.tag, t.explanation, t.lookup_key
          FROM v$tag_group tg, tag_group_member tgm, v$tag t
         WHERE tg.tag_group_id = tgm.tag_group_id(+)
           AND tgm.tag_id = t.tag_id(+)
           AND tg.app_sid = in_app_sid 
         ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

PROCEDURE GetAllTagGroupsAndMembersInd(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_app_sid            IN    security_pkg.T_SID_ID,
    in_ind_sid                IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
           SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tgm.tag_Id, tgm.pos, t.tag, t.explanation, 
            CASE WHEN it.ind_sid IS NOT NULL THEN 1 ELSE 0 END selected
          FROM v$tag_group tg, tag_group_member tgm, v$tag t, ind_tag it
         WHERE tg.tag_group_id = tgm.tag_group_id
           AND tgm.tag_id = t.tag_id
           AND tg.applies_to_inds = 1
           AND tg.app_sid = in_app_sid
           AND it.tag_id(+) = tgm.tag_id
           AND it.ind_sid(+) = in_ind_sid
         ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

PROCEDURE GetAllTagGroupsAndMembersReg(
    in_act_id                IN    security_pkg.T_ACT_ID,
    in_app_sid            IN    security_pkg.T_SID_ID,
    in_region_sid            IN    security_pkg.T_SID_ID,
    out_cur                    OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
           SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tgm.tag_id, tgm.pos, t.tag, t.explanation, 
               CASE WHEN rt.region_sid IS NOT NULL THEN 1 ELSE 0 END selected
          FROM v$tag_group tg, tag_group_member tgm, v$tag t, region_tag rt
         WHERE tg.tag_group_id = tgm.tag_group_id
           AND tgm.tag_id = t.tag_id
           AND applies_to_regions = 1
           AND tg.app_sid = in_app_sid
           AND rt.tag_id(+) = tgm.tag_id
           AND rt.region_sid(+) = in_region_sid
           AND tgm.active = 1
         ORDER BY tg.tag_group_id, tgm.pos, NLSSORT(t.tag, 'NLS_SORT=generic_m');
END;

FUNCTION ConcatTagGroupMembers(
    in_tag_group_id        IN    tag_group.tag_group_id%TYPE,
    in_max_length            IN     INTEGER
) RETURN VARCHAR2
AS
    v_s    VARCHAR2(512);
    v_sep VARCHAR2(10);
BEGIN
    v_s := '';
    v_sep := '';

    FOR r IN (
        SELECT tag
          FROM tag_group_member tgm, v$tag t
         WHERE tgm.tag_id = t.tag_id
           AND tgm.tag_group_id = in_tag_group_id)
    LOOP
        IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
            v_s := v_s || '...';
            EXIT;
        END IF;
        v_s := v_s || v_sep || r.tag;
        v_sep := ', ';
    END LOOP;

    RETURN v_s;
END;

PROCEDURE GetTagGroupsSummary(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_app_sid        IN    security_pkg.T_SID_ID,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT tag_group_id, name,
            (SELECT count(*) FROM tag_group_member tgm WHERE tag_group_id = tg.tag_group_id) member_count,
            tag_pkg.ConcatTagGroupMembers(tg.tag_group_id, 30) MEMBERS
          FROM v$tag_group tg
         WHERE app_sid = in_app_sid;
END;

PROCEDURE GetTagGroupRegionMembers(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/ r.region_sid, r.name, r.description, r.parent_sid, r.pos, r.info_xml,
               r.active, r.link_to_region_sid, t.tag, t.tag_id
          FROM tag_group_member tgm, region_tag rt, v$tag t, v$region r 
         WHERE tgm.tag_group_id = in_tag_group_id AND tgm.tag_id = rt.tag_id AND tgm.tag_id = t.tag_id AND 
                rt.tag_id = t.tag_id AND rt.region_sid = r.region_sid
         ORDER BY r.region_sid, t.tag;
END;

PROCEDURE GetTagGroupIndMembers(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/ i.ind_sid, i.name, i.description, i.parent_sid, i.pos, i.active,
               t.tag, t.tag_id
          FROM tag_group_member tgm, ind_tag it, v$tag t, v$ind i 
         WHERE tgm.tag_group_id = in_tag_group_id AND tgm.tag_id = it.tag_id AND tgm.tag_id = t.tag_id AND
                it.tag_id = t.tag_id AND it.ind_sid = i.ind_sid
         ORDER BY i.ind_sid, t.tag;
END;

PROCEDURE GetTagGroupNCMembers(
    in_act_id        IN    security_pkg.T_ACT_ID,
    in_tag_group_id    IN    tag_group.tag_group_id%TYPE,
    out_cur            OUT    security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/ nc.non_compliance_id, nc.label, nc.detail,
               t.tag, t.tag_id
          FROM tag_group_member tgm, non_compliance_tag nct, v$tag t, non_compliance nc
         WHERE tgm.tag_group_id = in_tag_group_id AND tgm.tag_id = nct.tag_id AND tgm.tag_id = t.tag_id AND
                nct.tag_id = t.tag_id AND nct.non_compliance_id = nc.non_compliance_id
         ORDER BY nc.non_compliance_id, t.tag;
END;

PROCEDURE DeactivateTag(
    in_tag_id                IN    tag.tag_id%TYPE,
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE
)
AS
BEGIN
    -- XXX: no security!
    
    UPDATE tag_group_member
       SET active = 0
     WHERE tag_id = in_tag_id
       AND tag_group_id = in_tag_group_id;
END;

PROCEDURE ActivateTag(
    in_tag_id                IN    tag.tag_id%TYPE,
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE
)
AS
BEGIN
    -- XXX: no security!
    
    UPDATE tag_group_member
       SET active = 1
     WHERE tag_id = in_tag_id
       AND tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTag(
    in_tag_id                        IN    tag.tag_id%TYPE,
    out_tag_cur                        OUT    SYS_REFCURSOR
)
AS
BEGIN
    -- bit pointless?
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_tag_cur FOR
        SELECT t.tag, t.explanation, t.lookup_key, tgm.tag_group_id, t.parent_id
          FROM v$tag t
          JOIN tag_group_member tgm ON tgm.tag_id = t.tag_id
         WHERE t.tag_id = in_tag_id;
END;

PROCEDURE GetTagGroupRegionTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT rttg.tag_group_id, rttg.region_type, rt.label region_type_label
          FROM region_type_tag_group rttg
          JOIN region_type rt on rt.region_type = rttg.region_type
         WHERE rttg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupInternalAuditTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT iattg.tag_group_id, iattg.internal_audit_type_id, iat.label, iat.lookup_key, iat.flow_sid, iat.tab_sid, iat.active
          FROM internal_audit_type_tag_group iattg
          JOIN internal_audit_type iat on iattg.internal_audit_type_id = iat.internal_audit_type_id
         WHERE iattg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupNCTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT ncttg.tag_group_id, ncttg.non_compliance_type_id, nct.label, nct.lookup_key
          FROM non_compliance_type_tag_group ncttg
          JOIN non_compliance_type nct on nct.non_compliance_type_id = ncttg.non_compliance_type_id
         WHERE ncttg.tag_group_id = in_tag_group_id;
END;


PROCEDURE GetTagGroupCompanyTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT cttg.tag_group_id, cttg.company_type_id, ct.singular, ct.plural, ct.is_default, ct.is_top_company, ct.lookup_key
          FROM chain.company_type_tag_group cttg
          JOIN chain.company_type ct on ct.company_type_id = cttg.company_type_id
         WHERE cttg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetTagGroupInitiativeTypes(
    in_tag_group_id            IN    tag_group.tag_group_id%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
        SELECT pttg.tag_group_id, pttg.project_sid, ip.name
          FROM project_tag_group pttg
          JOIN initiative_project ip on pttg.project_sid = ip.project_sid
         WHERE pttg.tag_group_id = in_tag_group_id;
END;

PROCEDURE GetAllTagGroups (
    out_tag_group_cur        OUT    SYS_REFCURSOR,
    out_tag_group_text_cur    OUT    SYS_REFCURSOR,
    out_tag_cur                OUT    SYS_REFCURSOR,
    out_tag_text_cur        OUT    SYS_REFCURSOR,
    out_region_types_cur    OUT    SYS_REFCURSOR,
    out_audit_types_cur        OUT    SYS_REFCURSOR,
    out_company_types_cur    OUT    SYS_REFCURSOR,
    out_non_compl_types_cur    OUT    SYS_REFCURSOR
)
AS
    v_act_id                security_pkg.T_ACT_ID := security_pkg.GetAct;
    v_app_sid                security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
    
    OPEN out_tag_group_cur FOR
        SELECT tag_group_id, lookup_key, mandatory, multi_select, applies_to_inds,
               applies_to_regions, applies_to_non_compliances, applies_to_suppliers,
               applies_to_chain, applies_to_initiatives, applies_to_chain_activities,
               applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
               applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical
          FROM tag_group
         WHERE app_sid = v_app_sid;
    
    OPEN out_tag_group_text_cur FOR
        SELECT tag_group_id, 'default' AS lang, name
          FROM v$tag_group
         WHERE app_sid = v_app_sid;
    
    OPEN out_tag_cur FOR
        SELECT tgm.tag_group_id, tgm.tag_id, tgm.pos, tgm.active, t.lookup_key, t.parent_id
          FROM tag_group_member tgm
          JOIN tag t ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
         WHERE tgm.app_sid = v_app_sid;
    
    OPEN out_tag_text_cur FOR
        SELECT tag_id, 'default' AS lang, tag, explanation
          FROM v$tag
         WHERE app_sid = v_app_sid;
    
    OPEN out_region_types_cur FOR 
        SELECT tag_group_id, region_type
          FROM region_type_tag_group
         WHERE app_sid = v_app_sid;
    
    OPEN out_audit_types_cur FOR 
        SELECT tag_group_id, internal_audit_type_id
          FROM internal_audit_type_tag_group
         WHERE app_sid = v_app_sid;
    
    OPEN out_company_types_cur FOR 
        SELECT tag_group_id, company_type_id
          FROM chain.company_type_tag_group
         WHERE app_sid = v_app_sid;
    
    OPEN out_non_compl_types_cur FOR 
        SELECT tag_group_id, non_compliance_type_id
          FROM non_compliance_type_tag_group
         WHERE app_sid = v_app_sid;
END;

PROCEDURE GetAllCatTranslations(
    in_validation_lang        IN    tag_group_description.lang%TYPE,
    in_changed_since        IN    DATE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_app_sid                    security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
    OPEN out_cur FOR
        SELECT tgd.tag_group_id sid, tgd.name description, tgd.lang,
               CASE WHEN tgd.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
          FROM tag_group_description tgd
          JOIN aspen2.translation_set ts ON v_app_sid = ts.application_sid
         WHERE ts.lang = tgd.lang
         ORDER BY 
               CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
               LOWER(ts.lang);
END;

PROCEDURE ValidateCatTranslations(
    in_tag_group_ids        IN    security.security_pkg.T_SID_IDS,
    in_descriptions            IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_validation_lang        IN    tag_group_description.lang%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_app_sid                security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act                    security_pkg.T_ACT_ID := security_pkg.GetACT;
    v_tg_id_desc_tbl        T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
    IF in_tag_group_ids.COUNT != in_descriptions.COUNT THEN
        RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ids do not match number of descriptions.');
    END IF;
    
    IF in_tag_group_ids.COUNT = 0 THEN
        RETURN;
    END IF;

    v_tg_id_desc_tbl.EXTEND(in_tag_group_ids.COUNT);

    FOR i IN 1..in_tag_group_ids.COUNT
    LOOP
        v_tg_id_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_tag_group_ids(i), in_descriptions(i));
    END LOOP;

    OPEN out_cur FOR
        SELECT tgd.tag_group_id sid,
               CASE tgd.name WHEN tgt.description THEN 0 ELSE 1 END has_changed,
               security_pkg.SQL_IsAccessAllowedSID(v_act, v_app_sid, security_pkg.PERMISSION_WRITE) can_write
          FROM tag_group_description tgd
          JOIN TABLE(v_tg_id_desc_tbl) tgt ON tgd.tag_group_id = tgt.sid_id
         WHERE app_sid = v_app_sid
           AND lang = in_validation_lang;
END;

PROCEDURE GetAllTagTranslations(
    in_validation_lang        IN    tag_description.lang%TYPE,
    in_changed_since        IN    DATE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_app_sid                    security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
    OPEN out_cur FOR
        SELECT td.tag_id sid, td.tag description, td.lang,
               CASE WHEN td.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
          FROM tag_description td
          JOIN aspen2.translation_set ts ON v_app_sid = ts.application_sid
         WHERE ts.lang = td.lang
         ORDER BY 
               CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
               LOWER(ts.lang);
END;

PROCEDURE GetAllTagExplTranslations(
    in_validation_lang        IN    tag_description.lang%TYPE,
    in_changed_since        IN    DATE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_app_sid                    security.security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
    OPEN out_cur FOR
        SELECT td.tag_id sid, td.explanation description, td.lang,
               CASE WHEN td.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
          FROM tag_description td
          JOIN aspen2.translation_set ts ON v_app_sid = ts.application_sid
         WHERE ts.lang = td.lang
         ORDER BY 
               CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
               LOWER(ts.lang);
END;

PROCEDURE ValidateTagTranslations(
    in_tag_ids                IN    security.security_pkg.T_SID_IDS,
    in_descriptions            IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_validation_lang        IN    tag_description.lang%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_app_sid                security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act                    security_pkg.T_ACT_ID := security_pkg.GetACT;
    v_t_id_desc_tbl            T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
    IF in_tag_ids.COUNT != in_descriptions.COUNT THEN
        RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ids do not match number of descriptions.');
    END IF;
    
    IF in_tag_ids.COUNT = 0 THEN
        RETURN;
    END IF;

    v_t_id_desc_tbl.EXTEND(in_tag_ids.COUNT);

    FOR i IN 1..in_tag_ids.COUNT
    LOOP
        v_t_id_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_tag_ids(i), in_descriptions(i));
    END LOOP;

    OPEN out_cur FOR
        SELECT td.tag_id sid,
               CASE td.tag WHEN tgt.description THEN 0 ELSE 1 END has_changed,
               security_pkg.SQL_IsAccessAllowedSID(v_act, v_app_sid, security_pkg.PERMISSION_WRITE) can_write
          FROM tag_description td
          JOIN TABLE(v_t_id_desc_tbl) tgt ON td.tag_id = tgt.sid_id
         WHERE app_sid = v_app_sid
           AND lang = in_validation_lang;
END;

PROCEDURE ValidateTagExplTranslations(
    in_tag_ids                IN    security.security_pkg.T_SID_IDS,
    in_descriptions            IN    security.security_pkg.T_VARCHAR2_ARRAY,
    in_validation_lang        IN    tag_description.lang%TYPE,
    out_cur                    OUT    SYS_REFCURSOR
)
AS
    v_app_sid                security_pkg.T_SID_ID := security_pkg.GetApp;
    v_act                    security_pkg.T_ACT_ID := security_pkg.GetACT;
    v_t_id_desc_tbl            T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
    IF in_tag_ids.COUNT != in_descriptions.COUNT THEN
        RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ids do not match number of descriptions.');
    END IF;

    IF in_tag_ids.COUNT = 0 THEN
        RETURN;
    END IF;

    v_t_id_desc_tbl.EXTEND(in_tag_ids.COUNT);

    FOR i IN 1..in_tag_ids.COUNT
    LOOP
        v_t_id_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_tag_ids(i), NVL(in_descriptions(i), 'NULL'));
    END LOOP;

    OPEN out_cur FOR
        SELECT td.tag_id sid,
               CASE NVL(td.explanation, 'NULL') WHEN tgt.description THEN 0 ELSE 1 END has_changed,
               security_pkg.SQL_IsAccessAllowedSID(v_act, v_app_sid, security_pkg.PERMISSION_WRITE) can_write
          FROM tag_description td
          JOIN TABLE(v_t_id_desc_tbl) tgt ON td.tag_id = tgt.sid_id
         WHERE app_sid = v_app_sid
           AND lang = in_validation_lang;
END;

PROCEDURE GetTagGroups(
    in_act_id                        IN    security_pkg.T_ACT_ID,
    in_app_sid                        IN    security_pkg.T_SID_ID,
    out_tag_group_cur                OUT    SYS_REFCURSOR,
    out_tag_group_tr_cur            OUT    SYS_REFCURSOR,
    out_tag_cur                        OUT    SYS_REFCURSOR,
    out_tag_tr_cur                    OUT    SYS_REFCURSOR
)
AS
BEGIN
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_tag_group_cur FOR
        SELECT tag_group_id, multi_select, applies_to_audits, applies_to_chain, applies_to_chain_activities, applies_to_chain_product_supps,
               applies_to_chain_product_types, applies_to_chain_products, applies_to_compliances, applies_to_inds, applies_to_initiatives,
               applies_to_non_compliances, applies_to_quick_survey, applies_to_regions, applies_to_suppliers
          FROM tag_group
         WHERE app_sid = in_app_sid;

    OPEN out_tag_group_tr_cur FOR
        SELECT tag_group_id, lang, name
          FROM tag_group_description
         WHERE app_sid = in_app_sid;

    OPEN out_tag_cur FOR
        SELECT tag_group_id, tag_id, pos, active
          FROM tag_group_member
         WHERE app_sid = in_app_sid;

    OPEN out_tag_tr_cur FOR
        SELECT tag_id, lang, tag
          FROM tag_description
         WHERE app_sid = in_app_sid;
END;

END temp_tag_pkg;
/
