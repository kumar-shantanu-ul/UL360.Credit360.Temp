CREATE OR REPLACE PACKAGE csr.permit_pkg AS

FUNCTION IsModuleEnabled RETURN NUMBER;

FUNCTION GetFlowRegionSids(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE;

FUNCTION CreatePermitWorkflow RETURN security_pkg.T_SID_ID;

PROCEDURE GetActivityTypes(
	out_cur							OUT SYS_REFCURSOR,
	out_sub_typ_cur					OUT SYS_REFCURSOR
);

PROCEDURE SaveActivityType(
	in_activity_type_id				IN  compliance_activity_type.activity_type_id%TYPE,
	in_description					IN  compliance_activity_type.description%TYPE,
	in_pos							IN  compliance_activity_type.pos%TYPE,
	out_activity_type_id			OUT compliance_activity_type.activity_type_id%TYPE
);

PROCEDURE SaveActivitySubType(
	in_activity_type_id				IN  compliance_activity_sub_type.activity_type_id%TYPE,
	in_activity_sub_type_id			IN  compliance_activity_sub_type.activity_sub_type_id%TYPE,
	in_description					IN  compliance_activity_sub_type.description%TYPE,
	in_pos							IN  compliance_activity_sub_type.pos%TYPE,
	out_activity_sub_type_id		OUT compliance_activity_sub_type.activity_sub_type_id%TYPE
);

PROCEDURE SetActivitySubTypes(
	in_activity_type_id				IN  compliance_activity_sub_type.activity_type_id%TYPE,
	in_sub_type_ids_to_keep			IN  security_pkg.T_SID_IDS
);

PROCEDURE DeleteActivityType(
	in_activity_type_id				IN  compliance_activity_type.activity_type_id%TYPE
);

PROCEDURE GetApplicationTypes(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveApplicationType(
	in_application_type_id			IN  compliance_application_type.application_type_id%TYPE,
	in_description					IN  compliance_application_type.description%TYPE,
	in_pos							IN  compliance_application_type.pos%TYPE,
	out_application_type_id			OUT compliance_application_type.application_type_id%TYPE
);

PROCEDURE DeleteApplicationType(
	in_application_type_id			IN  compliance_application_type.application_type_id%TYPE
);

PROCEDURE GetConditionTypes(
	out_cur							OUT SYS_REFCURSOR,
	out_sub_typ_cur					OUT SYS_REFCURSOR
);

PROCEDURE SaveConditionType(
	in_condition_type_id			IN  compliance_condition_type.condition_type_id%TYPE,
	in_description					IN  compliance_condition_type.description%TYPE,
	in_pos							IN  compliance_condition_type.pos%TYPE,
	out_condition_type_id			OUT compliance_condition_type.condition_type_id%TYPE
);

PROCEDURE SaveConditionSubType(
	in_condition_type_id			IN  compliance_condition_sub_type.condition_type_id%TYPE,
	in_condition_sub_type_id		IN  compliance_condition_sub_type.condition_sub_type_id%TYPE,
	in_description					IN  compliance_condition_sub_type.description%TYPE,
	in_pos							IN  compliance_condition_sub_type.pos%TYPE,
	out_condition_sub_type_id		OUT compliance_condition_sub_type.condition_sub_type_id%TYPE
);

PROCEDURE SetConditionSubTypes(
	in_condition_type_id			IN  compliance_condition_sub_type.condition_type_id%TYPE,
	in_sub_type_ids_to_keep			IN  security_pkg.T_SID_IDS
);

PROCEDURE DeleteConditionType(
	in_condition_type_id			IN  compliance_condition_type.condition_type_id%TYPE
);

PROCEDURE GetPermitTypes(
	out_cur							OUT SYS_REFCURSOR,
	out_sub_typ_cur					OUT SYS_REFCURSOR
);

PROCEDURE SavePermitType(
	in_permit_type_id				IN  compliance_permit_type.permit_type_id%TYPE,
	in_description					IN  compliance_permit_type.description%TYPE,
	in_pos							IN  compliance_permit_type.pos%TYPE,
	out_permit_type_id				OUT compliance_permit_type.permit_type_id%TYPE
);

PROCEDURE SavePermitSubType(
	in_permit_type_id				IN  compliance_permit_sub_type.permit_type_id%TYPE,
	in_permit_sub_type_id			IN  compliance_permit_sub_type.permit_sub_type_id%TYPE,
	in_description					IN  compliance_permit_sub_type.description%TYPE,
	in_pos							IN  compliance_permit_sub_type.pos%TYPE,
	out_permit_sub_type_id			OUT compliance_permit_sub_type.permit_sub_type_id%TYPE
);

PROCEDURE SetPermitSubTypes(
	in_permit_type_id				IN  compliance_permit_sub_type.permit_type_id%TYPE,
	in_sub_type_ids_to_keep			IN  security_pkg.T_SID_IDS
);

PROCEDURE DeletePermitType(
	in_permit_type_id				IN  compliance_permit_type.permit_type_id%TYPE
);

PROCEDURE SavePermit(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	in_region_sid					IN	compliance_permit.region_sid%TYPE,
	in_title						IN	compliance_permit.title%TYPE,
	in_activity_type_id				IN	compliance_permit.activity_type_id%TYPE,
	in_activity_sub_type_id			IN	compliance_permit.activity_sub_type_id%TYPE,
	in_activity_start_dtm			IN	compliance_permit.activity_start_dtm%TYPE,
	in_activity_end_dtm				IN	compliance_permit.activity_end_dtm%TYPE,
	in_activity_details				IN	compliance_permit.activity_details%TYPE,
	in_permit_ref					IN	compliance_permit.permit_reference%TYPE,
	in_permit_type_id				IN	compliance_permit.permit_type_id%TYPE,
	in_permit_sub_type_id			IN	compliance_permit.permit_sub_type_id%TYPE,
	in_site_commissioning_required	IN	compliance_permit.site_commissioning_required%TYPE,
	in_site_commissioning_dtm 		IN	compliance_permit.site_commissioning_dtm%TYPE,
	in_permit_start_dtm				IN	compliance_permit.permit_start_dtm%TYPE,
	in_permit_end_dtm				IN	compliance_permit.permit_end_dtm%TYPE,
	in_is_major_change				IN	NUMBER,
	in_change_reason				IN  VARCHAR2,
	out_permit_id					OUT	compliance_permit.compliance_permit_id%TYPE
);

PROCEDURE GetPermit(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_predecessors				OUT SYS_REFCURSOR,
	out_successors					OUT SYS_REFCURSOR
);

PROCEDURE GetAllPermits(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPermitByRef(
	in_reference					IN	compliance_permit.permit_reference%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_predecessors				OUT SYS_REFCURSOR,
	out_successors					OUT SYS_REFCURSOR
);

PROCEDURE GetPermitTabs(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SavePermitTab(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_tab_label					IN	compliance_permit_tab.tab_label%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE DEFAULT NULL
);

PROCEDURE SavePermitTab(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_tab_label					IN	compliance_permit_tab.tab_label%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RemovePermitTab(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE
);

PROCEDURE GetPermitHeaders(
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SavePermitHeader(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE
);

PROCEDURE SavePermitHeader(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE,
	in_pos							IN	compliance_permit_tab.pos%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RemovePermitHeader(
	in_plugin_id					IN	compliance_permit_tab.plugin_id%TYPE
);

PROCEDURE SaveApplication(
	in_application_id				IN	compliance_permit_application.permit_application_id%TYPE,
	in_permit_id					IN	compliance_permit_application.permit_id%TYPE,
	in_application_reference		IN	compliance_permit_application.application_reference%TYPE,
	in_title						IN	compliance_permit_application.title%TYPE,
	in_application_type_id			IN	compliance_permit_application.application_type_id%TYPE,
	in_submission_dtm				IN	compliance_permit_application.submission_dtm%TYPE,
	in_duly_made_dtm				IN	compliance_permit_application.duly_made_dtm%TYPE,
	in_determined_dtm				IN	compliance_permit_application.determined_dtm%TYPE,
	in_notes						IN	compliance_permit_application.notes%TYPE,
	in_app_result_id				IN	compliance_permit_application.compl_permit_app_status_id%TYPE,
	in_paused_dtm					IN	compl_permit_application_pause.paused_dtm%TYPE DEFAULT NULL,
	in_resumed_dtm					IN	compl_permit_application_pause.resumed_dtm%TYPE DEFAULT NULL,
	out_application_id				OUT	compliance_permit_application.permit_application_id%TYPE
);

PROCEDURE GetApplication(
	in_application_id				IN	compliance_permit_application.permit_application_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_transitions					OUT SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
);

PROCEDURE GetApplications(
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_transitions					OUT SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
);

PROCEDURE GetApplicationByRef(
	in_reference					IN	compliance_permit_application.application_reference%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_transitions					OUT SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
);

FUNCTION IsPermitRefInUse(
	in_permit_id					IN  compliance_permit.compliance_permit_id%TYPE,
	in_reference					IN	compliance_permit_application.application_reference%TYPE
)
RETURN NUMBER;

FUNCTION IsApplicationRefInUse(
	in_application_id				IN  compliance_permit_application.permit_application_id%TYPE,
	in_reference					IN	compliance_permit_application.application_reference%TYPE
)
RETURN NUMBER;

PROCEDURE GetPermitFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPermitApplicationFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPermitConditionFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPredecessors(
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetSuccessors(
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPermits(
	in_linkable_to_permit_id		IN  compliance_permit.compliance_permit_id%TYPE DEFAULT NULL,
	in_search_phrase				IN  VARCHAR2,
	in_region_sid					IN	compliance_permit.region_sid%TYPE,
	in_sort_by						IN  VARCHAR2,
	in_sort_dir						IN  VARCHAR2,
	in_row_count					IN  NUMBER,
	in_start_row					IN  NUMBER,
	out_total_rows					OUT NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE LinkPermits(
	in_prev_permit_id				IN compliance_permit.compliance_permit_id%TYPE,
	in_next_permit_id				IN compliance_permit.compliance_permit_id%TYPE
);

PROCEDURE UnlinkPermits(
	in_prev_permit_id				IN compliance_permit.compliance_permit_id%TYPE,
	in_next_permit_id				IN compliance_permit.compliance_permit_id%TYPE
);

PROCEDURE GetPermitTransitions(
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RunFlowTransition(
	in_flow_item_id					IN  compliance_permit.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_cache_keys					IN	security_pkg.T_VARCHAR2_ARRAY,	
	out_still_has_access 			OUT NUMBER
);

PROCEDURE GetApplicationTransitions(
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RunApplicationFlowTransition(
	in_flow_item_id					IN  compliance_permit_application.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_cache_keys					IN	security_pkg.T_VARCHAR2_ARRAY,	
	out_still_has_access 			OUT NUMBER
);

FUNCTION GetPermitUrl(
	in_permit_id					IN  compliance_permit.compliance_permit_id%TYPE
)
RETURN VARCHAR2;

PROCEDURE GetIssueDueDtm(
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE,
	out_due_dtm						OUT	issue.due_dtm%TYPE
);

PROCEDURE GetAuditLogForItemPaged(
	in_flow_item_id					IN	security_pkg.T_SID_ID,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_start_date					IN	DATE,
	in_end_date						IN	DATE,
	in_search						IN	VARCHAR2,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE AddIssue(
	in_permit_id					IN  compliance_permit.compliance_permit_id%TYPE,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE,
	in_is_urgent					IN	NUMBER,
	in_region_sid					IN  region.region_sid%TYPE,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE,
	in_issue_due_offset_days		IN	issue.issue_due_offset_days%TYPE,
	in_issue_due_offset_months		IN	issue.issue_due_offset_months%TYPE,
	in_issue_due_offset_years		IN	issue.issue_due_offset_years%TYPE,
	in_is_critical					IN	issue.is_critical%TYPE,
	out_issue_id					OUT issue.issue_id%TYPE
);

PROCEDURE SearchPermits (
	in_search_term			VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION GetDocLibFolder (
	in_permit_id					IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

FUNCTION GetPermitDocLib
  RETURN security_pkg.T_SID_ID;
 
FUNCTION GetPermissibleDocumentFolders (
	in_doc_library_sid				IN  security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE;

FUNCTION CheckDocumentPermissions (
	in_permit_id					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN;

PROCEDURE DocSaved (
	in_permit_id 					IN  security_pkg.T_SID_ID,
	in_filename						IN  VARCHAR2
);

PROCEDURE DocDeleted (
	in_permit_id 					IN  security_pkg.T_SID_ID,
	in_filename						IN  VARCHAR2
);
 
PROCEDURE GetPermConditionRagThresholds (
	out_cur							OUT	SYS_REFCURSOR
);
 
PROCEDURE INT_UpdateTempCompLevels(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_search			IN	VARCHAR2
);

PROCEDURE GetAllSiteCompLevelsPaged(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CopyPermitItems(
	in_from_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_target_permit_id				IN	compliance_permit.compliance_permit_id%TYPE,
	in_clone_actions				IN	NUMBER,
	in_clone_scheduled_actions		IN	NUMBER,
	in_clone_conditions				IN	NUMBER,
	in_clone_cond_actions			IN	NUMBER,
	in_clone_cond_schduled_actions	IN	NUMBER,
	in_action_assignee_user_sid		IN	security_pkg.T_SID_ID
);
  
-- Start of issue type helper procedures
PROCEDURE OnScheduledTaskCreated (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_parent_id					IN  NUMBER
);

PROCEDURE OnScheduledTaskDeleted (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE
);  

PROCEDURE OnScheduledIssueCreated (
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_issue_id						IN  issue.issue_id%TYPE
);

PROCEDURE OnSetIssueCritical(
	in_issue_id						IN  issue.issue_id%TYPE,
	in_value						IN  issue.is_critical%TYPE,
	out_issue_changed				OUT	NUMBER
);

PROCEDURE GetScheduledIssues ( 
	in_compliance_permit_id			IN	compliance_permit.compliance_permit_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

-- End of issue type helper procedures

PROCEDURE GetActiveApplicationsForUser (
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_search						IN	VARCHAR2,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_pauses						OUT SYS_REFCURSOR
);

--For ApplicationSummaryPortlet
PROCEDURE GetApplicationSummaryForUser (
	out_cur							OUT	SYS_REFCURSOR	
);

--Permit score stuff
PROCEDURE SetPermitScore (
	in_permit_id				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	score_threshold.score_threshold_id%TYPE,
	in_score					IN	compliance_permit_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  compliance_permit_score.set_dtm%TYPE DEFAULT TRUNC(SYSDATE),
	in_valid_until_dtm			IN  compliance_permit_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  compliance_permit_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  compliance_permit_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  compliance_permit_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  compliance_permit_score.comment_text%TYPE DEFAULT NULL
);

PROCEDURE SetPermitScore (
	in_permit_id				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_thresh_lookup_key		IN	score_threshold.lookup_key%TYPE,
	in_score					IN	compliance_permit_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  compliance_permit_score.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  compliance_permit_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  compliance_permit_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  compliance_permit_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  compliance_permit_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  compliance_permit_score.comment_text%TYPE DEFAULT NULL
);

PROCEDURE DeletePermitScore (
	in_permit_id				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_set_dtm					IN  compliance_permit_score.set_dtm%TYPE,
	in_valid_until_dtm			IN  compliance_permit_score.valid_until_dtm%TYPE,
	in_is_override				IN  compliance_permit_score.is_override%TYPE DEFAULT 0
);

PROCEDURE GetPermitScores(
	in_permit_id				IN  security_pkg.T_SID_ID,
	out_permit_scores_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_DeletePermit(
	in_permit_id				IN  security_pkg.T_SID_ID
);

END permit_pkg;
/
