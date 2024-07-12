CREATE OR REPLACE PACKAGE chain.activity_pkg
IS

FUNCTION SQL_CanManageActivities (
	in_target_company_sid			IN  activity.target_company_sid%TYPE
) RETURN NUMBER;

FUNCTION SQL_IsAssignedToUser (
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN NUMBER;

FUNCTION SQL_IsTargetUser (
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN NUMBER;

/*********************************************************************************/
/**********************   ACTIVITY   *********************************************/
/*********************************************************************************/
PROCEDURE GetMyOverdueActivities(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_page_number					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_activity_types				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN 	security_pkg.T_SID_IDS,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyUpcomingActivities(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_page_number					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_activity_types				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN 	security_pkg.T_SID_IDS,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTargetActivities(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActivitiesByDueDate(
	in_start_dtm					IN	activity.activity_dtm%TYPE,
	in_end_dtm						IN	activity.activity_dtm%TYPE,
	in_activity_type_id				IN	activity.activity_type_id%TYPE DEFAULT NULL,
	in_my_activities				IN	NUMBER,
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvolvedUsers (
	in_activity_id					IN  activity.activity_id%TYPE,
	out_inv_user_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateActivity(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_activity_type_id				IN  activity.activity_type_id%TYPE,
	in_description					IN  activity.description%TYPE,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_location_type				IN  activity.location_type%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0,
	in_created_by_activity_id		IN  activity.created_by_activity_id%TYPE DEFAULT NULL,
	in_defer_activity_created_call	IN  NUMBER DEFAULT 0,
	out_activity_id					OUT activity.activity_id%TYPE
);

-- Fires the activity created helper call. This is to let C# defer the call
-- until after it has finished adding tags.
PROCEDURE ActivityCreated(
	in_activity_id					IN  activity_tag.activity_id%TYPE
);

PROCEDURE UpdateActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_description					IN  activity.description%TYPE,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_location_type				IN  activity.location_type%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0,
	in_defer_activity_updated_call	IN  NUMBER DEFAULT 0,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR
);

-- Fires the activity updated helper call. This is to let C# defer the call
-- until after it has finished amending tags.
PROCEDURE ActivityUpdated(
	in_activity_id					IN  activity_tag.activity_id%TYPE
);

PROCEDURE SetActivityOutcome(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_outcome_type_id				IN  activity.outcome_type_id%TYPE,
	in_outcome_reason				IN  activity.outcome_reason%TYPE DEFAULT NULL,
	in_deferred_date				IN  activity.activity_dtm%TYPE DEFAULT NULL
);

PROCEDURE RescheduleActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_new_activity_dtm				IN  activity.activity_dtm%TYPE
);

PROCEDURE DeleteActivity(
	in_activity_id					IN  activity.activity_id%TYPE
);

/*********************************************************************************/
/**********************   ACTIVITY LOGS ******************************************/
/*********************************************************************************/
PROCEDURE GetActivityLogEntries(
	in_activity_id					IN  activity_log.activity_id%TYPE,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActivityLogEntry(
	in_activity_log_id				IN activity_log.activity_log_id%TYPE,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActivityLogReplies(
	in_activity_log_id				IN  activity_log.activity_log_id%TYPE,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActivityLogFile(
	in_activity_log_file_id			IN  activity_log_file.activity_log_file_id%TYPE,
	in_sha1							IN  VARCHAR2,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddUserLogEntry(
	in_activity_id					IN  activity_log.activity_id%TYPE,
	in_message						IN  activity_log.message%TYPE,
	in_reply_to_activity_log_id		IN  activity_log.reply_to_activity_log_id%TYPE DEFAULT NULL,
	in_is_visible_to_supplier		IN  activity_log.is_visible_to_supplier%TYPE DEFAULT 0,
	in_cache_key					IN  aspen2.filecache.cache_key%TYPE DEFAULT NULL,
	out_activity_log_id				OUT activity_log.activity_log_id%TYPE
);

PROCEDURE AddSystemLogEntry(
	in_activity_id					IN  activity_log.activity_id%TYPE,
	in_message						IN  activity_log.message%TYPE,
	in_param_1						IN  activity_log.param_1%TYPE DEFAULT NULL,
	in_param_2						IN  activity_log.param_2%TYPE DEFAULT NULL,
	in_param_3						IN  activity_log.param_3%TYPE DEFAULT NULL,
	in_is_visible_to_supplier		IN  activity_log.is_visible_to_supplier%TYPE DEFAULT 0,	
	out_activity_log_id				OUT activity_log.activity_log_id%TYPE
);	

PROCEDURE DeleteLogEntry(
	in_activity_log_id				IN  activity_log.activity_log_id%TYPE
);

PROCEDURE AddLogEntryFileFromCache (
	in_activity_log_id				IN activity_log.activity_log_id%TYPE,
	in_cache_key					IN  aspen2.filecache.cache_key%TYPE
);

PROCEDURE EmailReceived (
	in_activity_id					IN  activity_log.activity_id%TYPE,
	in_mail_address					IN  VARCHAR2,
	in_mail_name					IN  VARCHAR2,
	in_message						IN  activity_log.message%TYPE,
	out_activity_log_id				OUT activity_log.activity_log_id%TYPE
);

/*********************************************************************************/
/**********************   ACTIVITY TAGS  *****************************************/
/*********************************************************************************/
PROCEDURE AddActivityTag(
	in_activity_id					IN  activity_tag.activity_id%TYPE,
	in_tag_id						IN  activity_tag.tag_id%TYPE,
	in_tag_group_id					IN  activity_tag.tag_group_id%TYPE
);

PROCEDURE RemoveActivityTag(
	in_activity_id					IN  activity_tag.activity_id%TYPE,
	in_tag_id						IN  activity_tag.tag_id%TYPE,
	in_tag_group_id					IN  activity_tag.tag_group_id%TYPE
);

/*********************************************************************************/
/**********************   ACTIVITY TYPE   ****************************************/
/*********************************************************************************/
FUNCTION GetActivityTypeId (
	in_activity_type_lookup_key		IN  activity_type.lookup_key%TYPE
) RETURN NUMBER;

PROCEDURE GetActivityTypes(
	out_activity_types_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_tag_group_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_activity_type_action_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_alert_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_alert_roles_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_outcome_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_outcome_action_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetActivityType(
	in_activity_type_id				IN  activity_type.activity_type_id%TYPE,
	in_label						IN  activity_type.label%TYPE,
	in_css_class					IN  activity_type.css_class%TYPE,
	in_due_dtm_relative				IN  activity_type.due_dtm_relative%TYPE DEFAULT NULL,
	in_due_dtm_relative_unit		IN  activity_type.due_dtm_relative_unit%TYPE DEFAULT NULL,
	in_has_target_user				IN  activity_type.has_target_user%TYPE,
	in_has_location					IN  activity_type.has_location%TYPE,
	in_user_can_create				IN  activity_type.user_can_create%TYPE,
	in_lookup_key					IN  activity_type.lookup_key%TYPE DEFAULT NULL,
	in_title_template				IN  activity_type.title_template%TYPE DEFAULT NULL,
	in_can_share					IN  activity_type.can_share%TYPE DEFAULT 0,
	in_tag_group_ids				IN  helper_pkg.T_NUMBER_ARRAY,
	out_activity_type_id			OUT activity_type.activity_type_id%TYPE
);

PROCEDURE SetActivityTypeAction(
	in_activity_type_action_id		IN  activity_type_action.activity_type_action_id%TYPE,
	in_activity_type_id				IN  activity_type_action.activity_type_id%TYPE,
	in_generate_activity_type_id	IN  activity_type_action.generate_activity_type_id%TYPE,
	in_allow_user_interaction		IN  activity_type_action.allow_user_interaction%TYPE,
	in_default_description			IN  activity_type_action.default_description%TYPE DEFAULT NULL,
	in_def_assigned_to_role_sid		IN  activity_type_action.default_assigned_to_role_sid%TYPE DEFAULT NULL,
	in_default_target_role_sid		IN  activity_type_action.default_target_role_sid%TYPE DEFAULT NULL,
	in_default_act_date_relative	IN  activity_type_action.default_act_date_relative%TYPE DEFAULT NULL,
    in_default_act_date_rel_unit	IN  activity_type_action.default_act_date_relative_unit%TYPE DEFAULT 'd',
	in_default_share_with_target	IN  activity_type_action.default_share_with_target%TYPE DEFAULT 0,
	in_default_location				IN  activity_type_action.default_location%TYPE DEFAULT NULL,
	in_default_location_type		IN  activity_type_action.default_location_type%TYPE DEFAULT NULL,
	in_copy_tags					IN  activity_type_action.copy_tags%TYPE DEFAULT 0,
	in_copy_assigned_to				IN  activity_type_action.copy_assigned_to%TYPE DEFAULT 0,
	in_copy_target					IN  activity_type_action.copy_target%TYPE DEFAULT 0,
	out_activity_type_action_id		OUT activity_type_action.activity_type_action_id%TYPE
);

PROCEDURE DeleteOldActivityTypeActions(
	in_activity_type_id				IN  activity_type_action.activity_type_id%TYPE,
	in_act_type_action_ids_to_keep	IN  helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE SetActivityTypeAlert(
	in_customer_alert_type_id		IN  activity_type_alert.customer_alert_type_id%TYPE,
	in_activity_type_id				IN  activity_type_alert.activity_type_id%TYPE,
	in_label						IN  activity_type_alert.label%TYPE,
	in_use_supplier_company			IN  activity_type_alert.use_supplier_company%TYPE,
	in_allow_manual_editing			IN  activity_type_alert.allow_manual_editing%TYPE,
	in_send_to_target				IN  activity_type_alert.send_to_target%TYPE,
	in_send_to_assignee				IN  activity_type_alert.send_to_assignee%TYPE,
	in_subject						IN	csr.alert_template_body.subject%TYPE,
	in_body_html					IN	csr.alert_template_body.body_html%TYPE,
	out_customer_alert_type_id		OUT  activity_type_alert.customer_alert_type_id%TYPE
);

PROCEDURE DeleteOldActivityTypeAlerts(
	in_activity_type_id				IN  activity_type_action.activity_type_id%TYPE,
	in_alert_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE SetActivityTypeAlertRole(
	in_customer_alert_type_id		IN  activity_type_alert_role.customer_alert_type_id%TYPE,
	in_activity_type_id				IN  activity_type_alert_role.activity_type_id%TYPE,
	in_role_sid						IN  activity_type_alert_role.role_sid%TYPE
);

PROCEDURE DeleteOldActTypeAlertRoles(
	in_customer_alert_type_id		IN  activity_type_alert_role.customer_alert_type_id%TYPE,
	in_activity_type_id				IN  activity_type_alert_role.activity_type_id%TYPE,
	in_role_sids_to_keep			IN  helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE DeleteActivityType(
	in_activity_type_id				IN  activity_type.activity_type_id%TYPE
);

/*********************************************************************************/
/*********************  ACTIVITY OUTCOMES  ***************************************/
/*********************************************************************************/
PROCEDURE SetActivityOutcomeType(
	in_activity_type_id				IN  activity_outcome_type.activity_type_id%TYPE,
	in_outcome_type_id				IN  activity_outcome_type.outcome_type_id%TYPE
);

PROCEDURE DeleteOldActivityOutcomeTypes(
	in_activity_type_id				IN  activity_outcome_type.activity_type_id%TYPE,
	in_outcome_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE SetActivityOutcomeTypeAction(
	in_activity_oc_typ_action_id	IN  activity_outcome_type_action.activity_outcome_typ_action_id%TYPE DEFAULT NULL,
	in_activity_type_id				IN  activity_outcome_type_action.activity_type_id%TYPE,
	in_outcome_type_id				IN  activity_outcome_type_action.outcome_type_id%TYPE,
	in_generate_activity_type_id	IN  activity_outcome_type_action.generate_activity_type_id%TYPE,
	in_allow_user_interaction		IN  activity_outcome_type_action.allow_user_interaction%TYPE,
	in_default_description			IN  activity_outcome_type_action.default_description%TYPE DEFAULT NULL,
	in_def_assigned_to_role_sid		IN  activity_outcome_type_action.default_assigned_to_role_sid%TYPE DEFAULT NULL,
	in_default_target_role_sid		IN  activity_outcome_type_action.default_target_role_sid%TYPE DEFAULT NULL,
	in_default_act_date_relative	IN  activity_outcome_type_action.default_act_date_relative%TYPE DEFAULT NULL,
    in_default_act_date_rel_unit	IN  activity_outcome_type_action.default_act_date_relative_unit%TYPE DEFAULT 'd',
	in_default_share_with_target	IN  activity_outcome_type_action.default_share_with_target%TYPE DEFAULT 0,
	in_default_location				IN  activity_outcome_type_action.default_location%TYPE DEFAULT NULL,
	in_default_location_type		IN  activity_outcome_type_action.default_location_type%TYPE DEFAULT NULL,
	in_copy_tags					IN  activity_outcome_type_action.copy_tags%TYPE DEFAULT 0,
	in_copy_assigned_to				IN  activity_outcome_type_action.copy_assigned_to%TYPE DEFAULT 0,
	in_copy_target					IN  activity_outcome_type_action.copy_target%TYPE DEFAULT 0,
	out_activity_oc_typ_action_id	OUT activity_outcome_type_action.activity_outcome_typ_action_id%TYPE
);

PROCEDURE DeleteOldActOCTypeActions(
	in_activity_type_id				IN  activity_outcome_type_action.activity_type_id%TYPE,
	in_outcome_type_id				IN  activity_outcome_type_action.outcome_type_id%TYPE,
	in_act_oc_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
);

/*********************************************************************************/
/**********************   ACTIVITY OUTCOME  **************************************/
/*********************************************************************************/
PROCEDURE GetOutcomeTypes(
	out_outcome_cur					OUT security_pkg.T_OUTPUT_CUR
);                                      

PROCEDURE SetOutcomeType(
	in_outcome_type_id				IN  outcome_type.outcome_type_id%TYPE,
	in_label						IN  outcome_type.label%TYPE,
	in_is_success					IN  outcome_type.is_success%TYPE,
	in_is_failure					IN  outcome_type.is_failure%TYPE,
	in_is_deferred					IN  outcome_type.is_deferred%TYPE,
	in_require_reason				IN  outcome_type.require_reason%TYPE,
	in_lookup_key					IN  outcome_type.lookup_key%TYPE,
	out_outcome_type_id				OUT outcome_type.outcome_type_id%TYPE
);

PROCEDURE DeleteOutcomeType(
	in_outcome_type_id				IN  outcome_type.outcome_type_id%TYPE
);

PROCEDURE GetInboundActivityAccounts(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetInboundEmailAddress (
	out_email						OUT	mail.account.email_address%TYPE
);

END activity_pkg;
/		