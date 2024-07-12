CREATE OR REPLACE PACKAGE ACTIONS.initiative_pkg
IS

TYPE T_DATES IS TABLE OF DATE INDEX BY PLS_INTEGER;
TYPE T_VALUES IS TABLE OF csr.val.val_number%TYPE INDEX BY PLS_INTEGER;
	
TYPE T_TEAM_NAMES IS TABLE OF initiative_project_team.name%TYPE INDEX BY PLS_INTEGER;
TYPE T_TEAM_EMAILS IS TABLE OF initiative_project_team.email%TYPE INDEX BY PLS_INTEGER;

-- The user is not allowed to set an initiative to a given status
ERR_SET_STATUS_DENIED			CONSTANT NUMBER := -20751;
SET_STATUS_DENIED				EXCEPTION;
PRAGMA EXCEPTION_INIT(SET_STATUS_DENIED, -20751);

-- Mandatory fileds not filled in ans status is changing to non-draft
ERR_MANDATORY_FIELDS			CONSTANT NUMBER := -20752;
MANDATORY_FIELDS				EXCEPTION;
PRAGMA EXCEPTION_INIT(MANDATORY_FIELDS, -20752);


PROCEDURE Barclays_GenerateInitiativeRef(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_name					OUT	task.internal_ref%TYPE
);

PROCEDURE RBSENV_GenerateInitiativeName(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_name					OUT	task.internal_ref%TYPE
);



PROCEDURE GetBaseRegions(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTypesForProject(
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetCountryList(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetPropertyList(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_query				IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSelectedRegions(
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSelectedProperties(
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetInitiativeDetails(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_details					OUT	SYS_REFCURSOR
);

PROCEDURE BulkGetInitiativeDetails(
	in_task_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetInitiativeOverview(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_details					OUT	SYS_REFCURSOR,
	out_properties				OUT	SYS_REFCURSOR,
	out_tags					OUT	SYS_REFCURSOR
);

PROCEDURE DeleteInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE AutoGenerateRef(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_name					OUT	task.name%TYPE
);

-- This version of CreateInitiaitce is used by the create page, 
-- it has a limited set of arguments as we're not interested in 
-- capturing many of the attributetes we can associate with an 
-- initiative/action.
PROCEDURE CreateInitiative(
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	in_task_status_id			IN	task_status.task_status_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

-- This version of Create inititiative is called from the importer,
-- as the importer can be used to capture initiatives or just plain 
-- old actions we are provide an interface that allows us to set any 
-- of the attributes assocuated with an action or an initiative, 
-- after all an initative is just an action wuth some extra metric 
-- data associated with it.
PROCEDURE CreateInitiative(
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_task_status_id			IN	task_status.task_status_id%TYPE,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_period_duration	        IN	TASK.period_duration%TYPE,
	in_budget					IN	TASK.budget%TYPE,
	in_short_name				IN	TASK.short_name%TYPE,
	in_input_ind_sid			IN	security_pkg.T_SID_ID,
	in_target_ind_sid			IN	security_pkg.T_SID_ID,
	in_weighting				IN	TASK.weighting%TYPE,
	in_action_type				IN	TASK.action_type%TYPE,
	in_entry_type				IN	TASK.entry_type%TYPE,
	in_one_off					IN	NUMBER,
	in_owner_sid				IN	security_pkg.T_SID_ID,
	in_created_dtm				IN	task.created_dtm%TYPE,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
);


-- As for CreateInitiative this version of AmendInitiative has cut-down arguments 
-- and is called from the create page (See notes for CreateInitiative procedure)
PROCEDURE AmendInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_tags_valid				IN	NUMBER,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_valid				IN	NUMBER,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_valid		IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_valid			IN	NUMBER,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_valid			IN	NUMBER,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_valid				IN	NUMBER,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
);

-- As for CreateInitiative this version of AmendInitiative is able to amend 
-- all the attributes of an initiative/action, this is called from the importer 
-- (See notes for CreateInitiative procedure).
PROCEDURE AmendInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_task_status_id			IN	task_status.task_status_id%TYPE,
	in_tags_valid				IN	NUMBER,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_valid				IN	NUMBER,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_period_duration	        IN	TASK.period_duration%TYPE,
	in_budget					IN	TASK.budget%TYPE,
	in_short_name				IN	TASK.short_name%TYPE,
	in_input_ind_sid			IN	security_pkg.T_SID_ID,
	in_target_ind_sid			IN	security_pkg.T_SID_ID,
	in_weighting				IN	TASK.weighting%TYPE,
	in_action_type				IN	TASK.action_type%TYPE,
	in_entry_type				IN	TASK.entry_type%TYPE,
	in_one_off					IN	NUMBER,
	in_owner_sid				IN	security_pkg.T_SID_ID,
	in_created_dtm				IN	task.created_dtm%TYPE,
	in_project_team_valid		IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_valid			IN	NUMBER,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_valid			IN	NUMBER,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_valid				IN	NUMBER,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetAllMetricColumnsForImport(
	out_static					OUT	SYS_REFCURSOR
);

PROCEDURE GetMetricsForProject(
	in_project_sid				IN	security_pkg.T_SID_ID,
	out_periodic				OUT	SYS_REFCURSOR,
	out_static					OUT	SYS_REFCURSOR,
	out_uom						OUT SYS_REFCURSOR
);


-- This code is not called from anywhere and is now out of date anyway
/*
PROCEDURE SetMetricForProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_pos					IN	project_ind_template.pos%TYPE,
	in_pos_group			IN	project_ind_template.pos_group%TYPE,
	in_mandatory			IN	project_ind_template.is_mandatory%TYPE,
	in_update_per_period	IN	project_ind_template.update_per_period%TYPE,
	in_default_val			IN	project_ind_template.default_value%TYPE,
	in_input_dp				IN	project_ind_template.input_dp%TYPE,
	in_saving_template_id	IN	project_ind_template.saving_template_id%TYPE
);
*/

PROCEDURE GetMetricsForTask(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_periodic				OUT	SYS_REFCURSOR,
	out_static					OUT	SYS_REFCURSOR,
	out_uom						OUT SYS_REFCURSOR
);

-- NOTE: ONLY CALLED BY DEPRECATED CODE - WILL BE REMOVED
/*
PROCEDURE GetMetricsForTaskMonth(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_month_dtm				IN	task.start_dtm%TYPE,
	out_progress				OUT	SYS_REFCURSOR,
	out_periodic				OUT	SYS_REFCURSOR,
	out_static					OUT	SYS_REFCURSOR,
	out_uom						OUT SYS_REFCURSOR
);
*/

PROCEDURE GetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_details					OUT	SYS_REFCURSOR,
	out_team					OUT	SYS_REFCURSOR,
	out_sponsors				OUT	SYS_REFCURSOR,
	out_mt_periodic				OUT	SYS_REFCURSOR,
	out_mt_static				OUT	SYS_REFCURSOR,
	out_mt_uom					OUT	SYS_REFCURSOR
);

PROCEDURE SetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_valid		IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_valid			IN	NUMBER,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_valid			IN	NUMBER,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_valid				IN	NUMBER,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetImplDates(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.end_dtm%TYPE
);

PROCEDURE SetImplTeamAndSponsor(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS
);

PROCEDURE SetImplMetricsForTask(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_periodic_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE GetAllowedStatuses(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAllowedStatusesFromStatus(
	in_from_status_id			IN	task_status.task_status_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAllowedStatusTransitions(
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SubmitForApproval(
	in_task_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE Approve(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment					IN	task_status_history.comment_text%TYPE
);

PROCEDURE Reject(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment					IN	task_status_history.comment_text%TYPE
);

PROCEDURE Stop(
	in_task_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE Restart(
	in_task_sid					IN	security_pkg.T_SID_ID
);


PROCEDURE SetStatus(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_to_task_status_id		IN	task_status.task_status_id%TYPE,
	in_comment					IN	task_status_history.comment_text%TYPE
);

PROCEDURE SetStatusFromLabel(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	task_status.label%TYPE,
	in_comment					IN	task_status_history.comment_text%TYPE
);

FUNCTION StatusIdFromLabel(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	task_status.label%TYPE
) RETURN task_status.task_status_id%TYPE;

FUNCTION GetTransitionId (
	in_from_task_status_id		IN	task_status.task_status_id%TYPE,
	in_to_task_status_id		IN	task_status.task_status_id%TYPE
) RETURN task_status_transition.task_status_transition_id%TYPE;


FUNCTION IsSetStatusAllowed(
	in_from_task_status_id		IN	task_status.task_status_id%TYPE,
	in_to_task_status_id		IN	task_status.task_status_id%TYPE
) RETURN BOOLEAN;

PROCEDURE GetMyInitiatives(
	in_start_row				IN	NUMBER,
	in_page_size				IN	NUMBER,
	out_total_rows				OUT	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetUsersCoordinatorDetails(
	in_user_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetLastTransition (
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAlertData (
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_alert_details			OUT	SYS_REFCURSOR,
	out_recipients				OUT	SYS_REFCURSOR,
	out_regions					OUT	SYS_REFCURSOR
);

PROCEDURE GetMonthsForInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_restrict_future			IN	NUMBER,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE SaveDataEntry(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_month_dtm				IN	task.start_dtm%TYPE,
	in_progress_pct				IN	csr.val.val_number%TYPE,
	in_ids						IN	security_pkg.T_SID_IDS,
	in_vals						IN	T_VALUES,
	in_uoms						IN	security_pkg.T_SID_IDS
);


PROCEDURE GetReminderAlerts (
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetNewInitiativeProps (
	out_cur				OUT SYS_REFCURSOR
);

-- NOTE: LEGACY EXPORT IS DEPRECATED AND WILL BE REMOVED
-- EXPORTS ARE NOW PERFORMED BY THE IMPORTER (WHICH CAN ALSO EXPORT)
/*
PROCEDURE GetInitiativesExport(
	out_project			OUT	SYS_REFCURSOR,
	out_cur				OUT	SYS_REFCURSOR,
	out_team			OUT	SYS_REFCURSOR,
	out_sponsors		OUT	SYS_REFCURSOR	
);
*/

PROCEDURE GetInitiativeStaticData (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_regons			OUT	SYS_REFCURSOR,
	out_static			OUT	SYS_REFCURSOR
);

PROCEDURE GetInitiativeProgressData (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_regons			OUT	SYS_REFCURSOR,
	out_static			OUT	SYS_REFCURSOR,
	out_periodic		OUT	SYS_REFCURSOR
	--,out_ongoing			OUT	SYS_REFCURSOR
);

PROCEDURE SaveProgressData(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_ind_sids			IN	security_pkg.T_SID_IDS,
	in_start_dtms		IN	T_DATES,
	in_vals				IN	T_VALUES
);

PROCEDURE GetMyInitiatives2(
	out_projects		OUT	SYS_REFCURSOR,
	out_statuses		OUT	SYS_REFCURSOR,
	out_initiatives		OUT	SYS_REFCURSOR,
	out_options			OUT	SYS_REFCURSOR
);

PROCEDURE GetMyInitiatives2(
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_projects		OUT	SYS_REFCURSOR,
	out_statuses		OUT	SYS_REFCURSOR,
	out_initiatives		OUT	SYS_REFCURSOR,
	out_options			OUT	SYS_REFCURSOR
);

PROCEDURE AddIssue (
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_label				IN  csr.issue.label%TYPE,
	out_issue_id			OUT csr.issue.issue_id%TYPE
);

-- THIS CODE IS NOT CALLED FROM ANYWHERE AND WILL BE REMOVED
/*
PROCEDURE GetStaticDataForProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_data				OUT	SYS_REFCURSOR
);
*/

PROCEDURE RegionSidsFromRefs (
	in_dummy		IN	NUMBER,
	in_refs			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE RegionSidsFromNames (
	in_dummy		IN	NUMBER,
	in_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SetTaskPeriods(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_start_dtms		IN	task_pkg.T_DATES,
	in_status_ids		IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SetMetricValues(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
);

PROCEDURE MoveEndDtm(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_new_end_dtm				IN	task.end_dtm%TYPE
);

PROCEDURE CompleteInitiative(
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE TerminateInitiative(
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CheckExtendInitiative(
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetInitiativeValExport(
	out_project					OUT	SYS_REFCURSOR,
	out_data					OUT	SYS_REFCURSOR,
	out_team					OUT	SYS_REFCURSOR,
	out_sponsors				OUT	SYS_REFCURSOR,
	out_tags					OUT	SYS_REFCURSOR
);

PROCEDURE GetProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetInitiativesAtLevel(
	in_project_sid		IN	security_pkg.T_SID_ID,
	in_level			IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE AddComment(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment_text				IN	task_comment.comment_text%TYPE
);

PROCEDURE GetHistroyAndComments (
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);


PROCEDURE BarclaysEnergyPayback (
	in_task_sid			security_pkg.T_SID_ID,
	in_template_id		ind_template.ind_template_id%TYPE
);

PROCEDURE BarclaysOtherPayback (
	in_task_sid			security_pkg.T_SID_ID,
	in_template_id		ind_template.ind_template_id%TYPE
);

PROCEDURE RenameInitiative (
	in_project_sid		IN	security_pkg.T_SID_ID,
	in_old_name			IN	task.name%TYPE,
	in_new_name			IN	task.name%TYPE
);

PROCEDURE RenameInitiative (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	task.name%TYPE
);

PROCEDURE GetProjectTeam (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetProjectSponsor (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

END initiative_pkg;
/
