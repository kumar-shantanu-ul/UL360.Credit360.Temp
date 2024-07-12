CREATE OR REPLACE PACKAGE csr.compliance_pkg AS

COMPLIANCE_REQUIREMENT				CONSTANT NUMBER(2) := 0;
COMPLIANCE_REGULATION				CONSTANT NUMBER(2) := 1;
COMPLIANCE_CONDITION				CONSTANT NUMBER(2) := 2;

SOURCE_USER_DEFINED					CONSTANT NUMBER(2) := 0;
SOURCE_ENHESA						CONSTANT NUMBER(2) := 1;

COMPLIANCE_STATUS_DRAFT				CONSTANT NUMBER(2) := 1;
COMPLIANCE_STATUS_PUBLISHED			CONSTANT NUMBER(2) := 2;
COMPLIANCE_STATUS_RETIRED			CONSTANT NUMBER(2) := 3;

ROLLOUT_OPTION_DISABLED				CONSTANT NUMBER(2) := 0;
ROLLOUT_OPTION_ENABLED_SURVEY		CONSTANT NUMBER(2) := 1;
ROLLOUT_OPTION_ENABLED				CONSTANT NUMBER(2) := 2;

CHANGE_TYPE_MINOR					CONSTANT NUMBER(1) := 0;
CHANGE_TYPE_MAJOR					CONSTANT NUMBER(1) := 1;

USER_CHANGE_TYPE_NO_CHANGE			CONSTANT NUMBER(2) := 1;
USER_CHANGE_TYPE_RETIRED			CONSTANT NUMBER(2) := 8;

ROLLOUT_LEVEL_THIS_REG_ONLY			CONSTANT NUMBER(1) := 0;
ROLLOUT_LEVEL_ALL_REGS_OF_TYPE		CONSTANT NUMBER(1) := 1;
ROLLOUT_LEVEL_LOWEST				CONSTANT NUMBER(1) := 2;

TYPE flow_state_natures IS RECORD(
	new_item						flow_state_nature.flow_state_nature_id%TYPE,
	updated							flow_state_nature.flow_state_nature_id%TYPE,
	action_required					flow_state_nature.flow_state_nature_id%TYPE,
	compliant						flow_state_nature.flow_state_nature_id%TYPE,
	not_applicable					flow_state_nature.flow_state_nature_id%TYPE,
	retired							flow_state_nature.flow_state_nature_id%TYPE,
	not_created						flow_state_nature.flow_state_nature_id%TYPE,
	active							flow_state_nature.flow_state_nature_id%TYPE,
	inactive						flow_state_nature.flow_state_nature_id%TYPE
);

FUNCTION INTERNAL_GetFlowStateNatures(
	in_class						IN	flow.flow_alert_class%TYPE
)
RETURN flow_state_natures;

FUNCTION INTERNAL_FlowForComplianceItem(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE
)
RETURN security_pkg.T_SID_ID;

PROCEDURE INTERNAL_CreateComplianceItem(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_title						IN	compliance_item.title%TYPE,
	in_summary						IN	compliance_item.summary%TYPE,
	in_details						IN	compliance_item.details%TYPE,
	in_reference_code				IN	compliance_item.reference_code%TYPE,
	in_user_comment					IN	compliance_item.user_comment%TYPE,
	in_citation						IN	compliance_item.citation%TYPE,
	in_external_link				IN	compliance_item.external_link%TYPE,
	in_status_id 					IN	compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_change_type					IN	compliance_item_version_log.change_type%TYPE,
	in_major_version				IN	compliance_item.major_version%TYPE DEFAULT 1,
	in_minor_version				IN	compliance_item.major_version%TYPE DEFAULT 0,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
	in_is_first_publication			IN	NUMBER DEFAULT 0,
	in_source						IN	compliance_item.source%TYPE,
	in_compliance_item_type			IN	compliance_item.compliance_item_type%TYPE,
	in_lang_id						IN	compliance_language.lang_id%TYPE DEFAULT NULL
);

PROCEDURE AssertComplianceMgr;

FUNCTION IsModuleEnabled RETURN NUMBER;

FUNCTION GetComplianceItemUrl (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE
) RETURN VARCHAR2;

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

PROCEDURE OnCriticalIssueOverdue(
	in_issue_id						IN	issue.issue_id%TYPE
);

-- End of issue type helper procedures

PROCEDURE GetComplianceLanguages (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE AddComplianceLanguage (
	in_lang_id						IN	compliance_language.lang_id%TYPE
);

PROCEDURE AddComplianceLanguageByIso (
	in_lang							IN	VARCHAR2
);

PROCEDURE RemoveComplianceLanguages;

PROCEDURE SaveComplianceItemDesc (
	in_compliance_item_id		IN compliance_item_description.compliance_item_id%TYPE,
	in_lang						IN VARCHAR2,
	in_title					IN compliance_item_description.title%TYPE,
	in_details					IN compliance_item_description.details%TYPE,
	in_summary					IN compliance_item_description.summary%TYPE,
	in_citation					IN compliance_item_description.citation%TYPE,
	in_major_version			IN compliance_item_description.major_version%TYPE,
	in_minor_version			IN compliance_item_description.minor_version%TYPE
);

PROCEDURE RemoveComplianceItemDesc(
	in_compliance_item_id		IN compliance_item_description.compliance_item_id%TYPE,
	in_lang_id					IN compliance_item_description.lang_id%TYPE
);

PROCEDURE AddComplianceAuditLog (
	in_compliance_item_id		IN compliance_audit_log.compliance_item_id%TYPE,
	in_date_time				IN compliance_audit_log.date_time%TYPE DEFAULT SYSDATE,
	in_responsible_user			IN compliance_audit_log.responsible_user%TYPE,
	in_user_lang_id				IN compliance_audit_log.user_lang_id%TYPE,
	in_sys_lang_id				IN compliance_audit_log.sys_lang_id%TYPE,
	in_lang_id					IN compliance_audit_log.lang_id%TYPE,
	in_title					IN compliance_audit_log.title%TYPE,
	in_summary					IN compliance_audit_log.summary%TYPE,
	in_details					IN compliance_audit_log.details%TYPE,
	in_citation					IN compliance_audit_log.citation%TYPE
);

PROCEDURE GetComplianceAuditLog (
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	in_search			IN	VARCHAR2,
	in_lang_id			IN	compliance_audit_log.lang_id%TYPE,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetScheduledIssues (
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE CreateRolloutInfo(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	in_source						IN  compliance_item.source%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT 1,
	in_rollout_country				IN  compliance_item_rollout.country%TYPE,
	in_rollout_region				IN  compliance_item_rollout.region%TYPE,
	in_rollout_country_group		IN  compliance_item_rollout.country_group%TYPE,
	in_rollout_region_group			IN  compliance_item_rollout.region_group%TYPE,
	in_rollout_tags					IN  security_pkg.T_SID_IDS,
	in_rollout_regionsids			IN  security_pkg.T_SID_IDS,
	in_federal_req_code				IN  compliance_item_rollout.federal_requirement_code%TYPE DEFAULT NULL,
	in_is_federal_req				IN  compliance_item_rollout.is_federal_req%TYPE DEFAULT 0,
	in_compliance_item_rollout_id	IN	compliance_item_rollout.compliance_item_rollout_id%TYPE DEFAULT NULL,
	in_source_country				IN	compliance_item_rollout.source_country%TYPE DEFAULT NULL,
	in_source_region				IN	compliance_item_rollout.source_region%TYPE DEFAULT NULL,
	in_suppress_rollout				IN  compliance_item_rollout.suppress_rollout%TYPE DEFAULT 0
);

PROCEDURE CreateRequirement(
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT 1,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT 0,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	out_compliance_item_id			OUT compliance_item.compliance_item_id%TYPE
);

PROCEDURE CreateRegulation(
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_external_id					IN  csr.compliance_regulation.external_id%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT 1,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT 0,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE DEFAULT 0,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	in_is_policy					IN	csr.compliance_regulation.is_policy%TYPE DEFAULT 0,
	in_adoption_dtm					IN  csr.compliance_regulation.adoption_dtm%TYPE,
	out_compliance_item_id			OUT compliance_item.compliance_item_id%TYPE
);

PROCEDURE CreatePermitCondition(
	in_title						IN  compliance_item.title%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_permit_id					IN	compliance_permit_condition.compliance_permit_id%TYPE,
	in_condition_type_id			IN	compliance_permit_condition.condition_type_id%TYPE, 
	in_condition_sub_type_id		IN	compliance_permit_condition.condition_sub_type_id%TYPE,
	out_compliance_item_id			OUT compliance_item.compliance_item_id%TYPE
);

PROCEDURE CreatePermitConditionFlowItem (
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE,
	out_flow_item_id				OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE UpdateRequirement(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN  compliance_item_version_log	.description%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_is_first_publication			IN  NUMBER DEFAULT 0
);

PROCEDURE UpdateRegulation(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_summary						IN  compliance_item.summary%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_source						IN  compliance_item.source%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_user_comment					IN  compliance_item.user_comment%TYPE,
	in_citation						IN  compliance_item.citation%TYPE,
	in_external_link				IN  compliance_item.external_link%TYPE,
	in_adoption_dtm					IN  csr.compliance_regulation.adoption_dtm%TYPE,
	in_external_id					IN  csr.compliance_regulation.external_id%TYPE,
	in_status_id 					IN  compliance_item.compliance_item_status_id%TYPE,
	in_lookup_key					IN	compliance_item.lookup_key%TYPE,
	in_major_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_minor_version				IN  compliance_item.major_version%TYPE DEFAULT NULL,
	in_is_major_change				IN  compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN  compliance_item_version_log.description%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_is_first_publication			IN  NUMBER DEFAULT 0,
	in_is_policy					IN	csr.compliance_regulation.is_policy%TYPE DEFAULT 0
);

PROCEDURE UpdatePermitCondition(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_title						IN  compliance_item.title%TYPE,
	in_details						IN  compliance_item.details%TYPE,
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_change_type					IN  compliance_item_version_log.change_type%TYPE,
	in_condition_type_id			IN	compliance_permit_condition.condition_type_id%TYPE, 
	in_condition_sub_type_id		IN	compliance_permit_condition.condition_sub_type_id%TYPE,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN	compliance_item_version_log.description%TYPE,
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE
);

PROCEDURE GetComplianceItemHistory(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_compliance_lang				IN  VARCHAR2,
	in_sort_by						IN  VARCHAR2,
	in_sort_dir						IN  VARCHAR2,
	in_row_count					IN  NUMBER,
	in_start_row					IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR,
	out_total_rows					OUT NUMBER
);

--No security check. Only used by batch job import session.
PROCEDURE GetComplianceItemData(
	in_compliance_item_id		IN  compliance_item.compliance_item_id%TYPE,
	out_item_type				OUT NUMBER,
	out_compliance_item			OUT SYS_REFCURSOR
);

PROCEDURE GetComplianceItem(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_lang							IN	VARCHAR2,
	out_item_type					OUT NUMBER,
	out_compliance_item				OUT SYS_REFCURSOR,
	out_rollout_info				OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_child_items					OUT SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
);

PROCEDURE GetComplianceItemLangs(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	out_langs						OUT SYS_REFCURSOR
);

PROCEDURE GetPermitConditions(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE DEFAULT NULL,
	in_permit_id					IN	compliance_permit.compliance_permit_id%TYPE DEFAULT NULL,
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllPermitConditions(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetComplianceItemByRef(
	in_reference_code				IN  compliance_item.reference_code%TYPE,
	in_lang							IN	VARCHAR2 DEFAULT 'en',
	out_item_type					OUT NUMBER,
	out_compliance_item				OUT SYS_REFCURSOR,
	out_rollout_info				OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_child_items					OUT SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
);

PROCEDURE GetNonCompliantCondsForUser(
	in_search						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total						OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetNonCompliantItemsForUser(
	in_search						IN	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total						OUT	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetRegionComplianceItem(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_lang							IN	VARCHAR2,
	out_item_type					OUT NUMBER,
	out_compliance_region			OUT SYS_REFCURSOR,
	out_compliance_item				OUT SYS_REFCURSOR,
	out_rollout_info				OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR,
	out_child_items					OUT SYS_REFCURSOR,
	out_child_reqs					OUT SYS_REFCURSOR,
	out_parent_reg					OUT SYS_REFCURSOR,
	out_langs						OUT SYS_REFCURSOR
);

PROCEDURE GetComplianceItemTransitions(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RunFlowTransition(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_to_state_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	in_cache_keys					IN	security_pkg.T_VARCHAR2_ARRAY,	
	out_still_has_access 			OUT NUMBER
);

PROCEDURE UNSEC_RunOrForceTransToNature(
	in_flow_item_id					IN  compliance_item_region.flow_item_id%TYPE,
	in_to_nature_id					IN  flow_state.flow_state_id%TYPE,
	in_comment_text					IN	flow_state_log.comment_text%TYPE,
	out_still_has_access 			OUT NUMBER
);

PROCEDURE GetCountryGroups(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetCountryGroupCountries(
	in_group						IN  country_group.country_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetRegionGroups(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetRegionGroupsByCountry(
	in_country						IN  region_group_region.country%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetRegionGroupRegions(
	in_group						IN  country_group.country_group_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_SetExcludedTags(	in_response_id					IN quick_survey_response.survey_response_id%TYPE,
	in_add_exclusions				IN security_pkg.T_SID_IDS,
	in_remove_exclusions			IN security_pkg.T_SID_IDS
);

PROCEDURE SetEnabledFlow(
	in_enable_requirement_flow		IN NUMBER,
	in_enable_regulation_flow		IN NUMBER
);

FUNCTION CreateApplicationWorkflow	RETURN security_pkg.T_SID_ID;

FUNCTION CreateConditionWorkflow 	RETURN security_pkg.T_SID_ID;

PROCEDURE GetFlowAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE;

PROCEDURE GetRootRegions(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetEnhesaOptions(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_errors						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllEnhesaOptions(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComplianceOptions(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE AddEnhesaError(
	in_error_dtm					IN	enhesa_error_log.error_dtm%TYPE,
	in_error_msg					IN	enhesa_error_log.error_message%TYPE,
	in_stack_trace					IN	enhesa_error_log.stack_trace%TYPE
);

PROCEDURE SetRootRegions(
	in_regions						IN	security_pkg.T_SID_IDS,
	in_types						IN	security_pkg.T_SID_IDS,
	in_rollout_level				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetComplianceOptions(
	in_rollout_mode					IN compliance_options.rollout_option%TYPE,
	in_rollout_delay				IN	compliance_options.rollout_delay%TYPE,
	in_auto_involve_managers		IN	compliance_options.auto_involve_managers%TYPE
);

PROCEDURE SetEnhesaOptions(
	in_client_id					IN	enhesa_options.client_id%TYPE,
	in_next_run						IN	enhesa_options.next_run%TYPE,
	in_username						IN	enhesa_options.username%TYPE DEFAULT NULL,
	in_password						IN	enhesa_options.password%TYPE DEFAULT NULL,
	in_last_run						IN	enhesa_options.last_run%TYPE DEFAULT NULL,
	in_last_message					IN	enhesa_options.last_message%TYPE DEFAULT NULL,
	in_last_success					IN	enhesa_options.last_success%TYPE DEFAULT NULL,
	in_manual_run					IN	enhesa_options.manual_run%TYPE DEFAULT 0,
	in_packages_imported			IN	enhesa_options.packages_imported%TYPE DEFAULT 0,
	in_packages_total				IN	enhesa_options.packages_total%TYPE DEFAULT 0,
	in_items_imported				IN	enhesa_options.items_imported%TYPE DEFAULT 0,
	in_items_total					IN	enhesa_options.items_total%TYPE DEFAULT 0,
	in_links_created				IN	enhesa_options.links_created%TYPE DEFAULT 0,
	in_links_total					IN	enhesa_options.links_total%TYPE DEFAULT 0
);

PROCEDURE CreateFlowItem(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_region_sid					IN	region.region_sid%TYPE,
	out_flow_item_id				OUT	compliance_item_region.flow_item_id%TYPE
);

PROCEDURE GetSourceTypes(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetItemStates(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE RetireComplianceItem(
	in_compliance_item_id			IN compliance_item.compliance_item_id%TYPE
);

PROCEDURE PublishComplianceItem(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE,
	in_is_first_publication			IN NUMBER DEFAULT 0
);

PROCEDURE GetChangeTypes(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE LinkComplianceItems(
	in_regulation_id				IN  compliance_item.compliance_item_id%TYPE,
	in_requirement_id				IN  compliance_item.compliance_item_id%TYPE
);

PROCEDURE GetAppsPendingRollout(
	in_due_dtm						IN  DATE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RolloutComplianceItems(
	in_due_dtm						IN	DATE DEFAULT SYSDATE,
	out_updated						OUT	NUMBER
);

PROCEDURE RolloutComplianceItems(
	in_due_dtm						IN	DATE,
	in_max_items					IN	NUMBER,
	out_updated						OUT	NUMBER
);

PROCEDURE FilterRolloutItems(
	in_items_to_process				IN security.T_SID_TABLE,
	in_rollout_regions				IN security.T_SID_TABLE,
	out_filtered_rollout_items		OUT T_COMPLIANCE_ROLLOUT_TABLE
);

PROCEDURE UNSEC_LinkItemsByCode(
	in_reg_lookup_key				IN  compliance_item.lookup_key%TYPE,
	in_req_lookup_key				IN  compliance_item.lookup_key%TYPE
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

-- Transition (Retire):
-- Local item -> Retired
PROCEDURE OnLocalComplianceItemRetire(
	in_flow_sid						IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             	IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            	IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              	IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             	IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 	IN  security.security_pkg.T_SID_ID
);

PROCEDURE UpdateConditionsOnAcknowledged(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE UnlinkComplianceItems(
	in_regulation_id				IN  compliance_item.compliance_item_id%TYPE,
	in_requirement_id				IN  compliance_item.compliance_item_id%TYPE
);

PROCEDURE GetLinkableComplianceItems(
	in_compliance_item_id			IN  compliance_item.compliance_item_id%TYPE DEFAULT NULL,
	in_search_phrase				IN  VARCHAR2,
	in_sort_by						IN  VARCHAR2,
	in_sort_dir						IN  VARCHAR2,
	in_row_count					IN  NUMBER,
	in_start_row					IN  NUMBER,
	out_total_rows					OUT NUMBER,
	out_cur							OUT security_pkg.t_output_cur
);

PROCEDURE GetTagsFromHeadingCodes (
	in_heading_codes				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT SYS_REFCURSOR
);

FUNCTION GetIdByLookupKeyForEnhesa (
	in_key						IN  compliance_item.lookup_key%TYPE
) RETURN NUMBER;

PROCEDURE OnRegionMove(
	in_region_sid					IN	region.region_sid%TYPE
);

PROCEDURE OnRegionUpdate(
	in_region_sid					IN	region.region_sid%TYPE
);

PROCEDURE OnRegionCreate(
	in_region_sid					IN	region.region_sid%TYPE
);

PROCEDURE GetAllComplianceLevelsPaged(
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_search						IN	VARCHAR2,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION GetChangeTypeForEnhesa (
	in_enhesa_change_type			IN  NUMBER
) RETURN NUMBER;

PROCEDURE GetRegionDataFromSourceData (
	in_source						IN	compliance_region_map.compliance_item_source_id%TYPE,
	in_source_country_code			IN	compliance_region_map.source_country%TYPE,
	in_source_region_code			IN	compliance_region_map.source_region%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE AddIssue(
	in_flow_item_id					IN  issue_compliance_region.flow_item_id%TYPE,
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

PROCEDURE GetComplianceRagThresholds (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE INT_UpdateTempCompLevels(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_search			IN	VARCHAR2
);

PROCEDURE GetAllSiteCompLevelsPaged(
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_search						IN	VARCHAR2,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetEnhesaRolloutInfo(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetEnhesaRegionMappings(
	in_source_country				IN	VARCHAR2,
	in_source_region				IN	VARCHAR2,
	in_alert_sent					IN	NUMBER,
	out_map_cur						OUT SYS_REFCURSOR,
	out_item_cur					OUT SYS_REFCURSOR
);

PROCEDURE SaveEnhesaRegionMappings(
	in_source_country				IN	VARCHAR2,
	in_source_region				IN	VARCHAR2,
	in_alert_sent					IN  DATE,
	in_regions						IN	security_pkg.T_SID_IDS
);

PROCEDURE SaveEnhesaSiteType(
	in_site_type_id					IN	enhesa_site_type.site_type_id%TYPE,
	in_label						IN	enhesa_site_type.label%TYPE,
	out_site_type_cur				OUT	SYS_REFCURSOR
);

PROCEDURE DeleteEnhesaSiteType(
	in_site_type_id					IN	enhesa_site_type.site_type_id%TYPE
);

PROCEDURE SaveEnhesaSiteTypeMap(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	in_site_type_heading_id			IN	enhesa_site_type_heading.site_type_heading_id%TYPE,
	in_heading_code					IN	enhesa_site_type_heading.heading_code%TYPE
);

PROCEDURE SaveEnhesaSiteTypeMap(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	in_site_type_heading_id			IN	enhesa_site_type_heading.site_type_heading_id%TYPE,
	in_heading_code					IN	enhesa_site_type_heading.heading_code%TYPE,
	out_site_type_cur				OUT	SYS_REFCURSOR
);

PROCEDURE DeleteEnhesaSiteTypeMap(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	in_site_type_heading_id			IN	enhesa_site_type_heading.site_type_heading_id%TYPE
);

PROCEDURE GetEnhesaSiteTypeMappings(
	out_site_type_cur				OUT	SYS_REFCURSOR,
	out_headings_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetEnhesaSiteTypeMapping(
	in_site_type_id					IN	enhesa_site_type_heading.site_type_id%TYPE,
	out_site_type_cur				OUT	SYS_REFCURSOR,
	out_headings_cur				OUT	SYS_REFCURSOR
);

PROCEDURE PopulateSiteHeadingCodes;

PROCEDURE GetEhsManagersForSite(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE MarkComplianceAlertSent(
	in_csr_user_sid					IN	compliance_alert.csr_user_sid%TYPE
);

PROCEDURE GetFailedRollOutRegions(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE MarkUnmappedRegionSent(
	in_app_sid						IN	compliance_enhesa_map.app_sid%TYPE
);

PROCEDURE GetComplianceItems(
	out_cur							OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR
);

PROCEDURE GetComplianceItemVariants(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_AddComplianceItemHistory(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE,
	in_change_type					IN	compliance_item_version_log.change_type%TYPE,
	in_major_version				IN	compliance_item.major_version%TYPE,
	in_minor_version				IN	compliance_item.minor_version%TYPE,
	in_is_major_change				IN	compliance_item_version_log.is_major_change%TYPE,
	in_change_reason				IN	compliance_item_version_log.description%TYPE,
	in_lang							IN	VARCHAR2,
	in_change_dtm					IN	compliance_item_version_log.change_dtm%TYPE
);

PROCEDURE UNSEC_DeleteComplianceItemHistory(
	in_compliance_item_id			IN	compliance_item.compliance_item_id%TYPE
);

FUNCTION FeatureComplianceLanguages RETURN BOOLEAN;

FUNCTION GetCIIdForFlowItemId(
	in_flow_item_id					IN compliance_item_region.flow_item_id%TYPE
) RETURN NUMBER;

END compliance_pkg;
/
