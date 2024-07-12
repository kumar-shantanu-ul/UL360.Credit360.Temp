CREATE OR REPLACE PACKAGE CSR.issue_Pkg
IS

FUNCTION IsAccessAllowed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_Id			IN	issue.issue_id%TYPE
) RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(IsAccessAllowed, WNDS, WNPS);

FUNCTION ArePrioritiesEnabled RETURN NUMBER;

FUNCTION HasRegionRootStartPoint RETURN NUMBER;

PROCEDURE CreateIssue(
	in_label						IN  issue.label%TYPE,
	in_description					IN  issue_log.message%TYPE 					DEFAULT NULL,
	in_source_label					IN	issue.source_label%TYPE 				DEFAULT NULL,
	in_issue_type_id				IN	issue.issue_type_id%TYPE,
	in_correspondent_id				IN  issue.correspondent_id%TYPE 			DEFAULT NULL,
	in_raised_by_user_sid			IN	issue.raised_by_user_sid%TYPE 			DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE			DEFAULT NULL,
	in_assigned_to_role_sid			IN	issue.assigned_to_role_sid%TYPE			DEFAULT NULL,
	in_priority_id					IN	issue.issue_priority_id%TYPE 			DEFAULT NULL,
	in_due_dtm						IN	issue.due_dtm%TYPE						DEFAULT NULL,
	in_source_url					IN  issue.source_url%TYPE					DEFAULT NULL,
	in_region_sid					IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_is_urgent					IN	NUMBER									DEFAULT NULL,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE			DEFAULT NULL,
	in_issue_due_offset_days		IN	issue.issue_due_offset_days%TYPE		DEFAULT NULL,
	in_issue_due_offset_months		IN	issue.issue_due_offset_months%TYPE		DEFAULT NULL,
	in_issue_due_offset_years		IN	issue.issue_due_offset_years%TYPE		DEFAULT NULL,
	in_is_critical					IN	issue.is_critical%TYPE					DEFAULT 0,
	in_default_comment				IN	issue_raise_alert.issue_comment%TYPE 	DEFAULT NULL,
	out_issue_id					OUT issue.issue_id%TYPE
);

FUNCTION CreateCorrespondent (
	in_full_name				IN  correspondent.full_name%TYPE,
	in_email					IN  correspondent.email%TYPE,
	in_phone					IN  correspondent.phone%TYPE,
	in_more_info_1				IN  correspondent.more_info_1%TYPE
) RETURN correspondent.correspondent_id%TYPE;

PROCEDURE EmailCorrespondent (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE EmailUser (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE EmailRole (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR,
	out_custom_fields		OUT SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_due_dtm_sources		OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR,
	out_custom_fields		OUT SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueType(
	in_issue_type_id		IN	issue_custom_field.issue_type_id%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueType(
	in_lookup_key			IN	issue_type.lookup_key%TYPE,
	out_issue_type_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueTypes (
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueTypes (
	in_only_creatable			IN  NUMBER,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetRagOptions (
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE AllowCustomIssueTypes (
	out_allow_custom_issue_types		OUT customer.allow_custom_issue_types%TYPE
);

FUNCTION AllowCustomIssueTypes
RETURN BOOLEAN;

PROCEDURE SaveIssueType (
	in_issue_type_id				IN  issue_type.issue_type_id%TYPE,
	in_label						IN  issue_type.label%TYPE,
	in_lookup_key					IN	issue_type.lookup_key%TYPE,
	in_allow_children				IN  issue_type.allow_children%TYPE,
	in_require_priority				IN  issue_type.require_priority%TYPE,
	in_require_due_dtm_comment		IN	issue_type.require_due_dtm_comment%TYPE,
	in_can_set_public				IN	issue_type.can_set_public%TYPE,
	in_public_by_default			IN	issue_type.public_by_default%TYPE,
	in_email_involved_roles			IN	issue_type.email_involved_roles%TYPE,
	in_email_involved_users			IN	issue_type.email_involved_users%TYPE,
	in_restrict_users_to_region		IN	issue_type.restrict_users_to_region%TYPE,
	in_default_priority_id			IN  issue_type.default_issue_priority_id%TYPE,
	in_alert_pending_due_days		IN  issue_type.alert_pending_due_days%TYPE,
	in_alert_overdue_days			IN  issue_type.alert_overdue_days%TYPE,
	in_auto_close_days				IN  issue_type.auto_close_after_resolve_days%TYPE,
	in_deletable_by_owner   		IN  issue_type.deletable_by_owner%TYPE,
	in_deletable_by_raiser   		IN  issue_type.deletable_by_raiser%TYPE,
	in_deletable_by_administrator   IN  issue_type.deletable_by_administrator%TYPE,
	in_owner_can_be_changed			IN  issue_type.owner_can_be_changed%TYPE,
	in_show_forecast_dtm			IN  issue_type.show_forecast_dtm%TYPE,
	in_require_var_expl				IN  issue_type.require_var_expl%TYPE,
	in_enable_reject_action			IN  issue_type.enable_reject_action%TYPE,
	in_snd_alrt_on_issue_raised		IN  issue_type.send_alert_on_issue_raised%TYPE,
	in_show_one_issue_popup			IN  issue_type.show_one_issue_popup%TYPE,
	in_allow_owner_resolve_close	IN  issue_type.allow_owner_resolve_and_close%TYPE,
	in_is_region_editable			IN  issue_type.is_region_editable%TYPE,
	in_enable_manual_comp_date		IN  issue_type.enable_manual_comp_date%TYPE,
	in_comment_is_optional			IN	issue_type.comment_is_optional%TYPE,
	in_due_date_is_mandatory		IN	issue_type.due_date_is_mandatory%TYPE,
	in_allow_critical				IN	issue_type.allow_critical%TYPE,
	in_allow_urgent_alert			IN	issue_type.allow_urgent_alert%TYPE,
	in_region_is_mandatory			IN	issue_type.region_is_mandatory%TYPE,
	out_issue_type_id				OUT issue_type.issue_type_id%TYPE
);

PROCEDURE DeleteIssueType (
	in_issue_type_id			IN  issue_type.issue_type_id%TYPE
);

PROCEDURE SearchIssues(
	in_search_term				IN  VARCHAR2,
	in_all						IN	NUMBER,
	in_mine						IN	NUMBER,
	in_my_roles					IN	NUMBER,
	in_my_staff					IN	NUMBER,
	in_issue_type_id			IN	issue.issue_type_id%TYPE,
	in_last_issue_id			IN  issue.issue_id%TYPE,
	in_page_size				IN  NUMBER,
	in_overdue					IN  NUMBER,
	in_unresolved				IN  NUMBER,
	in_resolved					IN  NUMBER,
	in_closed					IN  NUMBER,
	in_rejected					IN  NUMBER,
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	in_children_for_issue_id	IN  security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetIssuesByDueDtm (
	in_start_dtm				IN	issue.due_dtm%TYPE,
	in_end_dtm					IN	issue.due_dtm%TYPE,
	in_issue_type_id			IN	issue.issue_type_id%TYPE,
	in_my_issues				IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetPriorities (
	out_cur				OUT	SYS_REFCURSOR
);

-- Get all assignable Roles for a region.
PROCEDURE GetAssignableRoles (
	in_region_sid		IN	region.region_sid%TYPE,
	in_filter			IN	VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
);

-- Gets all assignable users/roles, restricted by region.
PROCEDURE GetAssignableUsers (
	in_region_sid		IN	region.region_sid%TYPE,
	in_restrict_users	IN	issue_type.restrict_users_to_region%TYPE,
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
);

PROCEDURE GetIssueDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_issue_cur			OUT	SYS_REFCURSOR,
	out_users_cur			OUT	SYS_REFCURSOR,
	out_log_cur				OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT	SYS_REFCURSOR,
	out_custom_fields		OUT	SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_custom_field_vals	OUT	SYS_REFCURSOR,
	out_child_issues		OUT SYS_REFCURSOR,
	out_parent_issue		OUT SYS_REFCURSOR,
	out_roles_cur			OUT SYS_REFCURSOR,
	out_rag_options_cur		OUT SYS_REFCURSOR,
	out_companies_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetIssueDetailsByGuid(
	in_guid					IN  issue.guid%TYPE,
	out_issue_cur			OUT	SYS_REFCURSOR,
	out_users_cur			OUT	SYS_REFCURSOR,
	out_log_cur				OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT	SYS_REFCURSOR,
	out_custom_fields		OUT	SYS_REFCURSOR,
	out_custom_field_opts	OUT	SYS_REFCURSOR,
	out_custom_field_vals	OUT	SYS_REFCURSOR,
	out_child_issues		OUT SYS_REFCURSOR,
	out_parent_issue		OUT SYS_REFCURSOR,
	out_roles_cur			OUT SYS_REFCURSOR,
	out_rag_options_cur		OUT SYS_REFCURSOR,
	out_companies_cur		OUT SYS_REFCURSOR
);

PROCEDURE SetRagStatus(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_rag_status_id			IN  issue.rag_status_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
);

PROCEDURE SetRelativeDueDtm(
	in_act_id						IN  security_pkg.T_ACT_ID,
	in_issue_id						IN  issue.issue_id%TYPE,
	in_issue_due_source_id			IN	issue.issue_due_source_id%TYPE,
	in_issue_due_offset_days		IN	issue.issue_due_offset_days%TYPE,
	in_issue_due_offset_months		IN	issue.issue_due_offset_months%TYPE,
	in_issue_due_offset_years		IN	issue.issue_due_offset_years%TYPE,
	in_message						IN  issue_log.message%TYPE,
	out_due_cur						OUT	SYS_REFCURSOR,
	out_log_cur						OUT	SYS_REFCURSOR,
	out_action_cur					OUT SYS_REFCURSOR
);

PROCEDURE SetDueDtm(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_due_dtm					IN  issue.due_dtm%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_due_cur					OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
);

PROCEDURE SetForecastDtm(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_forecast_dtm					IN  issue.due_dtm%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_due_cur					OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SetPriority(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_issue_log_id				IN  issue_log.issue_log_id%TYPE, -- this is only used if in_message is null
	in_priority_id				IN  issue.issue_priority_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_due_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetLabel(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_label					IN  issue.label%TYPE,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SetDescription(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_description				IN  issue.description%TYPE,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SetDescription(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_description				IN  issue.description%TYPE,
	in_log_action				IN	BOOLEAN,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SetCritical(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_value					IN  issue.is_critical%TYPE,
	out_refresh_issue			OUT	NUMBER,
	out_issue_cur				OUT	SYS_REFCURSOR,
	out_action_log_cur			OUT	SYS_REFCURSOR
);

PROCEDURE AssignToUser(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_message					IN  issue_log.message%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE AssignToRole(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_role_sid					IN  security_pkg.T_SID_ID,
	in_message					IN  issue_log.message%TYPE,
	out_role_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE MarkAsResolved(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_var_expl					IN  issue.var_expl%TYPE,
	in_manual_completion_dtm	IN	issue.manual_completion_dtm%TYPE,
	in_manual_comp_dtm_set_dtm	IN	issue.manual_comp_dtm_set_dtm%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE MarkAsRejected(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SetOwnerUser (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_to_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetOwnerUserWithLogging (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_message					IN  issue_log.message%TYPE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
);

PROCEDURE SetOwnerRole (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_to_role_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE MarkAsClosed(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_manual_completion_dtm	IN	issue.manual_completion_dtm%TYPE,
	in_manual_comp_dtm_set_dtm	IN	issue.manual_comp_dtm_set_dtm%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE MarkAsUnresolved(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE NewEmailReceived (
	in_mail_address				IN  VARCHAR2,
	in_mail_name				IN  VARCHAR2,
	in_subject					IN	VARCHAR2,
	in_message					IN  issue_log.message%TYPE,
	out_issue_id				OUT issue.issue_id%TYPE,
	out_log_id					OUT issue_log.issue_log_id%TYPE
);

PROCEDURE EmailReceived (
	in_issue_id					IN  issue.issue_id%TYPE,
	in_mail_address				IN  VARCHAR2,
	in_mail_name				IN  VARCHAR2,
	in_message					IN  issue_log.message%TYPE,
	out_log_id					OUT issue_log.issue_log_id%TYPE
);

/*********************/
/*  Issue User stuff */
/*********************/

PROCEDURE AddUser(
	in_act_id				IN	SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AddUser(
	in_act_id				IN	SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_is_an_owner			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AddUser(
	in_act_id				IN	SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT	SYS_REFCURSOR
);

PROCEDURE AddUser(
	in_act_id				IN	SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_is_an_owner			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR,
	out_action_log_cur		OUT	SYS_REFCURSOR
);

PROCEDURE RemoveUser(
	in_act_id				IN	SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveUser(
	in_act_id				IN	SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_action_log_cur		OUT	SYS_REFCURSOR	
);

PROCEDURE GetIssueComments(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetIssueComments(
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_users_cur			OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetIssueUsers(
	in_issue_id				IN	security_pkg.T_SID_ID,
	out_users_cur			OUT	SYS_REFCURSOR
);

/*********************/
/*  Issue Role stuff */
/*********************/

PROCEDURE AddRole(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE RemoveRole(
	in_act_id				IN  SECURITY_PKG.T_ACT_ID,
	in_issue_id				IN  issue.issue_id%TYPE,
	in_role_sid				IN	security_pkg.T_SID_ID
);

/**************************/
/* Company stuff          */
/**************************/

PROCEDURE AddCompany(
	in_issue_id				IN  issue.issue_id%TYPE,
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE RemoveCompany(
	in_issue_id				IN  issue.issue_id%TYPE,
	in_company_sid			IN	security_pkg.T_SID_ID
);

/**************************/
/*  Issue Log table stuff */
/**************************/
PROCEDURE AddLogEntryFileFromCache(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_log_id		IN	issue_log.issue_log_id%TYPE,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE AddLogEntryFileFromCacheByGuid(
	in_guid				IN  issue.guid%TYPE,
	in_issue_log_id		IN	issue_log.issue_log_id%TYPE,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE GetLogEntryFiles(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_log_id			IN	issue_log_file.issue_log_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetLogEntryFile(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_log_file_id	IN	issue_log_file.issue_log_file_Id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetLogEntryFileByGuid(
	in_guid					IN  issue.guid%TYPE,
	in_issue_log_file_id	IN	issue_log_file.issue_log_file_Id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
);

PROCEDURE AddLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_is_system_generated		IN  issue_log.is_system_generated%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	in_prevent_reassign			IN  NUMBER,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
);

PROCEDURE AddCorrespondentLogEntry (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
);

PROCEDURE AddCorrespondentLogEntry (
	in_guid						IN  issue.guid%TYPE,
	in_message					IN  issue_log.message%TYPE,
	out_issue_log_id			OUT issue_log.issue_log_id%TYPE
);

PROCEDURE AddLogEntryReturnRow(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_id					IN  issue.issue_id%TYPE,
	in_message					IN  issue_log.message%TYPE,
	in_param_1					IN	issue_log.param_1%TYPE,
	in_param_2					IN	issue_log.param_2%TYPE,
	in_param_3					IN	issue_log.param_3%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT	SYS_REFCURSOR
);

PROCEDURE DeleteLogEntry(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_log_id				IN	issue_log.issue_log_id%TYPE
);

PROCEDURE MarkLogEntryAsRead(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_log_id				IN	issue_log.issue_log_id%TYPE
);

PROCEDURE ChangeRegion(
	in_issue_id					IN  issue.issue_id%TYPE,
	in_region_sid				IN	issue.region_sid%TYPE,
	out_log_cur					OUT	SYS_REFCURSOR,
	out_action_cur				OUT SYS_REFCURSOR
);

/******************************/
/*  deprecated Report queries */
/******************************/

PROCEDURE GetFilteredIssueCount(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_saved_filter_sid		IN	security_pkg.T_SID_ID,
	out_count				OUT	NUMBER
);


PROCEDURE GetIssuesByNonComplianceId(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetAllIssues(
	in_skip_count			IN NUMBER,
	in_take_count			IN NUMBER,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByRegionSid(
	in_parent_region_sid	IN	issue.region_sid%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByUserInvolved(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetReportInactiveUsers(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetReportInactiveUsersSummary(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetReportAuditIssues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_parent_region_sid	IN  security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

/****************************************/
/*  Specific pending value stored procs */
/****************************************/

PROCEDURE CreateIssuePV(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_approval_step_id			IN	security_pkg.T_SID_ID,
	in_pending_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id		IN	pending_period.pending_period_id%TYPE,
	in_label					IN  issue.label%TYPE,
	out_issue_id				OUT issue.issue_id%TYPE
);


PROCEDURE LogIssuePV(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_pending_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id		IN	pending_period.pending_period_id%TYPE,
	in_message					IN	issue_log.message%TYPE,
	out_issue_id				OUT issue.issue_id%TYPE
);

PROCEDURE AddIssueDeleg(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sheet_id					IN	sheet.sheet_id%TYPE,
	in_sheet_period_fmt			IN	VARCHAR2,
	in_ind_sid					IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	in_message					IN	issue_log.message%TYPE,
	in_description				IN	issue.description%TYPE,
	in_assign_to				IN	issue.assigned_to_user_sid%TYPE,
	in_due_date					IN	issue.due_dtm%TYPE,
	in_is_urgent				IN	NUMBER,
	in_is_critical				IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id				OUT issue.issue_id%TYPE
);

PROCEDURE GetIssuesDeleg(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sheet_id					IN	sheet.sheet_id%TYPE,
	in_ind_sid					IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	out_cur_issue				OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueLogPV(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_pending_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id		IN	pending_period.pending_period_id%TYPE,
	out_cur_issue				OUT	SYS_REFCURSOR,
	out_cur_log					OUT	SYS_REFCURSOR,
	out_cur_log_files			OUT	SYS_REFCURSOR
	
);

PROCEDURE GetMyOpenedIssueList(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetMyInvolvedIssueList(
	in_assigned_only	IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetScheduledTasks(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE SaveScheduledTask(
	in_issue_scheduled_task_id		IN	issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_label						IN	issue_scheduled_task.label%TYPE,
	in_schedule_xml					IN	issue_scheduled_task.schedule_xml%TYPE,
	in_period_xml					IN	issue_scheduled_task.period_xml%TYPE,
	in_raised_by_user_sid			IN	issue_scheduled_task.raised_by_user_sid%TYPE,
	in_assign_to_user_sid			IN	issue_scheduled_task.assign_to_user_sid%TYPE,
	in_next_run_dtm					IN	issue_scheduled_task.next_run_dtm%TYPE,
	in_due_dtm_relative				IN	issue_scheduled_task.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	issue_scheduled_task.due_dtm_relative_unit%TYPE,
	in_scheduled_on_due_date		IN  issue_scheduled_task.scheduled_on_due_date%TYPE,
	in_parent_id					IN  NUMBER DEFAULT NULL,
	in_issue_type_id				IN  issue_type.issue_type_id%TYPE DEFAULT NULL,
	in_create_critical				IN	issue_scheduled_task.create_critical%TYPE DEFAULT 0,
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_issue_scheduled_task_id		OUT	issue_scheduled_task.issue_scheduled_task_id%TYPE
);

PROCEDURE DeleteScheduledTask(
	in_issue_scheduled_task_id		IN	issue_scheduled_task.issue_scheduled_task_id%TYPE
);

PROCEDURE GetIssuesByAction(
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByMeter(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByMeterAlarm(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetIssuesByMeterRawData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

/**
 * Get data for the issues summary alert
 *
 * @param out_cr					The alert data
 */
PROCEDURE GetIssueAlertSummary(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueAlertSummaryApps(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueAlertSummaryLoggedOn(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetIssuesComingDue(
	in_days_backward				IN	NUMBER,
	in_days_forward					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksToRun(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE SetNextRunDtm(
	in_issue_scheduled_task_id		IN	issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_next_run_dtm					IN	issue_scheduled_task.next_run_dtm%TYPE
);

PROCEDURE CreateTaskIssue(
	in_issue_scheduled_task_id		IN  issue_scheduled_task.issue_scheduled_task_id%TYPE,
	in_issue_type_id				IN  issue.issue_type_id%TYPE DEFAULT NULL,
	in_label						IN	issue.label%TYPE,
	in_raised_by_user_sid			IN	issue.raised_by_user_sid%TYPE,
	in_assign_to_user_sid			IN	security_pkg.T_SID_ID,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_issue_id					OUT issue.issue_id%TYPE
);

PROCEDURE DeleteIssue(
	in_issue_id   	IN  issue.issue_id%TYPE
);

PROCEDURE UNSEC_DeleteIssue(
	in_issue_id		IN	issue.issue_id%TYPE
);

FUNCTION GetSheetUrl(
	in_editing_url					customer.editing_url%TYPE,
	in_ind_sid						ind.ind_sid%TYPE,
	in_region_sid					region.region_sid%TYPE,
	in_start_dtm					sheet.start_dtm%TYPE,
	in_end_dtm						sheet.end_dtm%TYPE,
	in_user_sid						csr_user.csr_user_sid%TYPE
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetSheetUrl, WNDS, WNPS);

PROCEDURE GetAlertDetails (
	in_issue_id						IN  issue.issue_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveCustomField (
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_issue_type_id			IN	issue_custom_field.issue_type_id%TYPE,
	in_field_type				IN	issue_custom_field.field_type%TYPE,
	in_label					IN	issue_custom_field.label%TYPE,
	in_pos						IN	issue_custom_field.pos%TYPE,
	in_is_mandatory				IN	issue_custom_field.is_mandatory%TYPE,
	in_restrict_to_group_sid	IN	issue_custom_field.restrict_to_group_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE UpdateCustomFieldPosition (
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_issue_type_id			IN	issue_custom_field.issue_type_id%TYPE,
	in_pos						IN	issue_custom_field.pos%TYPE
);

PROCEDURE DeleteCustomField (
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE
);

PROCEDURE GetCustomFields (
	in_issue_type_id			IN	issue_custom_field.issue_type_id%TYPE,
	in_only_creatable			IN  NUMBER,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SaveCustomFieldOption (
	in_option_id				IN	issue_custom_field_option.issue_custom_field_opt_id%TYPE,
	in_field_id					IN	issue_custom_field_option.issue_custom_field_id%TYPE,
	in_label					IN	issue_custom_field_option.label%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE DeleteCustomFieldOption (
	in_option_id				IN	issue_custom_field_option.issue_custom_field_opt_id%TYPE,
	in_field_id					IN	issue_custom_field_option.issue_custom_field_id%TYPE
);

PROCEDURE GetCustomFieldOptions (
	in_field_id					IN	issue_custom_field_option.issue_custom_field_id%TYPE,
	in_only_creatable			IN  NUMBER,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetCustomFieldsForIssues (
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE DEFAULT NULL,
	out_custom_fields				OUT	SYS_REFCURSOR,
	out_custom_field_options		OUT	SYS_REFCURSOR
);

PROCEDURE SetCustomFieldTextVal (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_str_val					IN	issue_custom_field_str_val.string_value%TYPE
);

PROCEDURE SetCustomFieldOptionSel (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_opt_sel					IN	issue_custom_field_opt_sel.issue_custom_field_opt_id%TYPE
);

PROCEDURE RemoveCustomFieldOptionSel (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_opt_sel					IN	issue_custom_field_opt_sel.issue_custom_field_opt_id%TYPE
);

PROCEDURE SetCustomFieldDateVal (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_date_val					IN	issue_custom_field_date_val.date_value%TYPE
);

PROCEDURE AddCustomFieldOptionSel (
	in_issue_id					IN	issue.issue_id%TYPE,
	in_field_id					IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_opt_sel					IN	issue_custom_field_opt_sel.issue_custom_field_opt_id%TYPE
);

PROCEDURE AddChildIssue (
	in_parent_issue_id			IN  issue.parent_id%TYPE,
	in_child_issue_id			IN  issue.issue_id%TYPE
);

PROCEDURE RemoveChildIssue (
	in_parent_issue_id			IN  issue.parent_id%TYPE,
	in_child_issue_id			IN  issue.issue_id%TYPE
);

PROCEDURE AutoCloseResolvedIssues;

PROCEDURE EscalateOverdueIssues;

FUNCTION GetEnquiryMailbox(
	in_mailbox_name				IN	VARCHAR2
) RETURN NUMBER;

PROCEDURE GetInboundIssueAccounts(
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE SetPublicIssue(
	in_issue_id		IN  issue.issue_id%TYPE,
	in_is_public	IN  issue.is_public%TYPE,
	out_issue_cur		OUT	SYS_REFCURSOR,
	out_action_log_cur	OUT	SYS_REFCURSOR
);

PROCEDURE SetAutoCloseIssue(
	in_issue_id		IN  issue.issue_id%TYPE,
	in_auto_close	IN	issue.allow_auto_close%TYPE
);

PROCEDURE RegisterAggregateIndGroup(
	in_issue_type_id			IN  issue_type_aggregate_ind_grp.issue_type_id%TYPE,
	in_aggregate_ind_group_id	IN  issue_type_aggregate_ind_grp.aggregate_ind_group_id%TYPE
);

PROCEDURE AcceptIssueAssignment (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	in_comment				IN	issue.label%TYPE,
	out_log_cur				OUT SYS_REFCURSOR,
	out_action_log_cur		OUT SYS_REFCURSOR
);

PROCEDURE ReturnIssueAssignment (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_id			IN	issue.issue_id%TYPE,
	in_reason			IN	issue.label%TYPE,
	out_user_cur		OUT SYS_REFCURSOR,
	out_log_cur			OUT SYS_REFCURSOR,
	out_action_log_cur	OUT SYS_REFCURSOR
);

FUNCTION GetIssueUrl(
	in_issue_id			IN  issue.issue_id%TYPE
) RETURN VARCHAR2;

PROCEDURE GetReminderAlertApps(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetReminderAlertsLoggedOn(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOverdueAlertsLoggedOn(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOverdueAlertApps(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RecordReminderSent(
	in_issue_id					IN	ISSUE.ISSUE_ID%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE RecordOverdueSent(
	in_issue_id					IN	ISSUE.ISSUE_ID%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE GetIssuesByMeterMissingData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

FUNCTION IssueIsPublic(
	in_issue_id					issue.issue_id%TYPE
) RETURN BOOLEAN;

FUNCTION GetPermissibleCustomFields (
	in_issue_type_id				IN issue_type.issue_type_id%TYPE DEFAULT NULL
) RETURN security.T_SID_TABLE;

PROCEDURE LinkIssueToNonCompliance(
	in_issue_id				issue.issue_id%TYPE,
	in_non_compliance_id	non_compliance.non_compliance_id%TYPE,
	in_force				NUMBER DEFAULT 0
);

PROCEDURE RefreshRelativeDueDtm(
	in_issue_id						IN	issue.issue_id%TYPE
);

PROCEDURE RefreshRelativeDueDtm(
	in_issue_id						IN	issue.issue_id%TYPE,
	in_issue_log_id					IN	issue_action_log.issue_action_log_id%TYPE
);

-- No security -- only used by Credit360.ScheduledTasks.Issues
PROCEDURE UNSEC_GetIssueRaiseAlerts(
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetIssueRaiseAlertAppSids(
	out_apps_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetIssueRaiseAlertsLoggedOn(
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
);

-- No security -- only used by Credit360.ScheduledTasks.Issues
PROCEDURE UNSEC_MarkIssueRaiseAlertSent(
	in_app_sid						IN	issue_raise_alert.app_sid%TYPE,
	in_issue_id						IN	issue_raise_alert.issue_id%TYPE
);

PROCEDURE UNSEC_SitesWithOverduePending(
	out_cur							OUT	SYS_REFCURSOR
);

-- No security -- only used by Credit360.ScheduledTasks.Issues
PROCEDURE UNSEC_CallIssueOverdueHelpers;

PROCEDURE FilterIssuesBy(
	in_issue_ids			IN	security.security_pkg.T_SID_IDS,
	in_filter_deleted		IN	NUMBER DEFAULT 0,
	in_filter_closed		IN	NUMBER DEFAULT 0,
	in_filter_resolved		IN	NUMBER DEFAULT 0,
	out_filtered_ids		OUT	security.security_pkg.T_SID_IDS
);

FUNCTION Sql_IsAccessAllowed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_issue_Id			IN	issue.issue_id%TYPE
) RETURN BINARY_INTEGER;
PRAGMA RESTRICT_REFERENCES(IsAccessAllowed, WNDS, WNPS);

PROCEDURE SetupStandaloneIssueType;

PROCEDURE UpdateIssues(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_issue_ids				IN	security.security_pkg.T_SID_IDS,
	in_assigned_to_sid			IN  issue.assigned_to_user_sid%TYPE,
	in_comment					IN  issue.label%TYPE,
	in_involved_users			IN  security.security_pkg.T_SID_IDS,
	in_uninvolved_users			IN  security.security_pkg.T_SID_IDS,
	in_set_due_dtm				IN	NUMBER DEFAULT 0,
	in_due_dtm					IN	issue.due_dtm%TYPE,
	out_error_cur				OUT	SYS_REFCURSOR
);

END issue_Pkg;
/
