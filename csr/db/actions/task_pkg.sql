CREATE OR REPLACE PACKAGE ACTIONS.task_pkg
IS

TYPE T_DATES IS TABLE OF DATE INDEX BY PLS_INTEGER;

-- task permissions
PERMISSION_ADD_COMMENT		    CONSTANT NUMBER(10) := 65536;
PERMISSION_UPDATE_PROGRESS	    CONSTANT NUMBER(10) := 131072;
PERMISSION_APPROVE_PROGRESS	    CONSTANT NUMBER(10) := 262144;
PERMISSION_CHANGE_STATUS	    CONSTANT NUMBER(10) := 524288;
PERMISSION_ASSIGN_USERS		    CONSTANT NUMBER(10) := 1048576;
PERMISSION_UPDATE_PROGRESS_XML	CONSTANT NUMBER(10) := 2097152;
/*
PERMISSION_FULL = 
	security_pkg.PERMISSION_STANDARD_ALL + 
	task_pkg.PERMISSION_ADD_COMMENT + 
	task_pkg.PERMISSION_UPDATE_PROGRESS +
	task_pkg.PERMISSION_APPROVE_PROGRESS + 
	task_pkg.PERMISSION_CHANGE_STATUS + 
	task_pkg.PERMISSION_ASSIGN_USERS + 
	task_pkg.PERMISSION_UPDATE_PROGRESS_TEXT
*/
PERMISSION_FULL 			CONSTANT NUMBER(10) := 4129791;


TYPE T_TASK_SIDS IS TABLE OF security_pkg.T_SID_ID INDEX BY PLS_INTEGER;
TYPE T_WEIGHTINGS IS TABLE OF task.weighting%TYPE INDEX BY PLS_INTEGER;

TYPE REC_SIMPLE_TASK_INFO IS RECORD (
	task_sid		security_pkg.T_SID_ID,
	name			task.name%TYPE, 
	internal_ref	task.internal_ref%TYPE
);

-- Parent key not found exception
PARENT_KEY_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(PARENT_KEY_NOT_FOUND, -02291);


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
	in_act					IN security_pkg.T_ACT_ID,
	in_task_sid				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_task_sid		IN security_pkg.T_SID_ID
);

PROCEDURE CreateTask(
	--in_act_id					IN	security_pkg.T_ACT_ID,
	in_project_sid			    IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_task_status_id		    IN 	task_status.task_status_id%TYPE,
	in_name						IN	TASK.name%TYPE,
	in_start_dtm				IN	TASK.start_dtm%TYPE,
	in_end_dtm					IN	TASK.end_dtm%TYPE,
	in_period_duration	        IN	TASK.period_duration%TYPE,
	in_fields_xml				IN	TASK.fields_xml%TYPE,
	in_is_container			    IN	TASK.is_container%TYPE,
	in_internal_Ref			    IN	TASK.internal_ref%TYPE,
	in_budget					IN	TASK.budget%TYPE,
	in_short_name				IN	TASK.short_name%TYPE,	
	in_input_ind_sid			IN	security_pkg.T_SID_ID,
	in_target_ind_sid			IN	security_pkg.T_SID_ID,
	in_weighting				IN	TASK.weighting%TYPE,
	in_action_type				IN	TASK.action_type%TYPE,
	in_entry_type				IN	TASK.entry_type%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE CreateOutputInd(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	task.name%TYPE,
	in_start_dtm		IN	TASK.start_dtm%TYPE,
	out_ind_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE UpdateWeightings(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_is_script_updated	IN	BOOLEAN	DEFAULT FALSE
);

PROCEDURE Internal_UpdateWeightings(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_is_script_updated	IN	BOOLEAN	DEFAULT FALSE
);

PROCEDURE ClearTaskPeriod(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	task_period.start_dtm%TYPE
);

PROCEDURE ClearTaskPeriod(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	task_period.start_dtm%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE SetTaskStatus(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_task_status_id		IN 	task_status.task_status_id%TYPE,
	in_comment_text			IN	task_status_history.comment_text%TYPE
);

PROCEDURE AppendTaskStatusHistory(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_task_status_id		IN 	task_status.task_status_id%TYPE,
	in_comment_text			IN	task_status_history.comment_text%TYPE
);

PROCEDURE AmendTask (
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	TASK.name%TYPE,
	in_start_dtm			IN	TASK.start_dtm%TYPE,
	in_end_dtm				IN	TASK.end_dtm%TYPE,
	in_period_duration		IN	TASK.period_duration%TYPE,
	in_fields_xml			IN	TASK.fields_xml%TYPE,
	in_is_container			IN	TASK.is_container%TYPE,
	in_internal_Ref			IN	TASK.internal_ref%TYPE,
	in_budget				IN	TASK.budget%TYPE,
	in_short_name			IN	TASK.short_name%TYPE,
	in_output_ind_sid		IN	security_pkg.T_SID_ID,
	in_input_ind_sid		IN	security_pkg.T_SID_ID,
	in_target_ind_sid		IN	security_pkg.T_SID_ID,
	in_weighting			IN	TASK.weighting%TYPE,
	in_action_type			IN	TASK.action_type%TYPE,
	in_entry_type			IN	TASK.entry_type%TYPE
);

PROCEDURE SetRelatedIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_indicator_sids		IN	VARCHAR2
);

PROCEDURE SetRelatedRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_region_sids			IN	VARCHAR2
);

PROCEDURE GetTaskRoleMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetTaskRoleMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_role_id			IN	ROLE.ROLE_ID%TYPE,
	in_sids					IN	VARCHAR2
);

PROCEDURE FilterRoleUsers(
	in_project_sid	 	IN  security_pkg.T_SID_ID,	 
	in_role_id	 		IN  ROLE.role_id%TYPE,
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

FUNCTION ConcatRoleIds(
	in_task_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatRoleIds, WNDS, WNPS);

FUNCTION ConcatTagIds(
	in_task_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(ConcatTagIds, WNDS, WNPS);

FUNCTION FormatPeriod(
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE
) RETURN VARCHAR2;


PROCEDURE AddComment(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment_text			IN	TASK_COMMENT.comment_text%TYPE,
	out_task_comment_id	OUT	task_comment.task_comment_id%TYPE
);

PROCEDURE GetStatusHistory(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetStatusHistoryInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCommentsInclChildren(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetTasks(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksAndRegionsForGrdExpt (
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskPeriods(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskPeriodsInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE Internal_UpsertTaskPeriodEntry(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	out_old_label        		OUT	TASK_PERIOD_STATUS.LABEL%TYPE
);

PROCEDURE Internal_UpsertAggrTaskPeriod(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE
);

PROCEDURE SetTaskPeriodFieldsXmlOnly(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_fields_xml				IN	task_period.fields_xml%TYPE
);

PROCEDURE SetTaskPeriodsFromUI(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_start_dtms		IN	T_DATES,
	in_status_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTaskPeriodFromUI(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER,
	in_override_reason			IN	task_period_override.reason%TYPE
);

PROCEDURE SetTaskPeriodUnlessOverridden(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
);

PROCEDURE SetTaskPeriod(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER
);

PROCEDURE SetAggrTaskPeriodUnlOverridden(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
);

PROCEDURE SetAggrTaskPeriod(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	aggr_task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	aggr_task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	aggr_task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER
);

PROCEDURE GetTaskRegions(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskRegionsAndParents(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetRelatedIndicators(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRelatedRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetComments(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetChartsInclChildren(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetInstancesInclChildren(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetCommentsForApp(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRoleMembersInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskFromRef(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_project_sid		IN	security_pkg.T_SID_ID,
	in_ref				IN	task.internal_ref%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetTask(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskChildrenAllPeriods(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAuditLog(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID, 
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetPeriodAuditLog(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID, 
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE RefreshTaskACL(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetVisibleInfoFields(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskAndChildren (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksAndPeriodsForRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksAndRegionsForPeriod(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_end_dtm			IN	task_period.end_dtm%TYPE,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
);

PROCEDURE GetAggrTasksAndPeriods(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
);

PROCEDURE GetAggrTaskPeriods(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksForRegionAndPeriod(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_end_dtm			IN	task_period.end_dtm%TYPE,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
);

PROCEDURE GetAggrTasksForRegionAndPeriod(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_end_dtm			IN	task_period.end_dtm%TYPE,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
);

PROCEDURE SetWeightings (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_sids				IN	T_TASK_SIDS,
	in_weightings		IN	T_WEIGHTINGS
);

PROCEDURE Internal_CompenasteWgtRndg(
	in_parent_task_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE GetTasksForAggregation(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);
	
PROCEDURE GetTaskForAggregation(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetTasksForRegionalAggregation(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetTaskForRegionalAggregation(
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE ClearAggregationFlags
;

PROCEDURE ClearAggregationFlagsForTask(
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetStatusIdFromPctValue(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_pct_complete		IN	task_period_status.means_pct_complete%TYPE,
	out_id				OUT	task_period_status.task_period_status_id%TYPE
);

FUNCTION GetStatusIdFromPctValueFn(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_pct_complete		IN	task_period_status.means_pct_complete%TYPE
) RETURN task_period_status.task_period_status_id%TYPE;

PROCEDURE SetStatusBasedOnPctComplete (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pct_complete		IN	task_period_status.means_pct_complete%TYPE
);

PROCEDURE SpreadWeightings(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_task_sid	IN	security_pkg.T_SID_ID,
	in_spread_weighting	IN	task.weighting%TYPE
);

PROCEDURE ClearTaskData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
);

FUNCTION LastTaskPeriod(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN task_period.start_dtm%TYPE;
PRAGMA RESTRICT_REFERENCES(LastTaskPeriod, WNDS, WNPS);

PROCEDURE SaveValueScript(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_script			IN	task.value_script%TYPE
);

PROCEDURE SaveAggrScript(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_script			IN	task.value_script%TYPE
);

PROCEDURE IsSuperAdmin(
	out_result			OUT	NUMBER
);

FUNCTION Internal_IsSuperAdmin
 RETURN NUMBER;

PROCEDURE GetTaskTreeRegions(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetMyTasks(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetCsrTaskRoleMembers (
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCsrTaskRoleMembers (
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE SetCsrTaskRoleMemebrs (
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_role_sids	IN	security_pkg.T_SID_IDS,
	in_user_sids	IN	security_pkg.T_SID_IDS
);

PROCEDURE SetCsrTaskRoleMemebrsFullName(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_role_sids		IN	security_pkg.T_SID_IDS,
	in_user_full_names	IN	security_pkg.T_VARCHAR2_ARRAY
);

END task_pkg;
/
