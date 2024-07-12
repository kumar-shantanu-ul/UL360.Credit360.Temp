CREATE OR REPLACE PACKAGE CHAIN.task_pkg
IS

TASK_ACTION_REMOVE 		CONSTANT NUMBER := 1;
TASK_ACTION_ADD			CONSTANT NUMBER := 2;

--DUEDATE FRAGMENTS FOR TASK SUMMARY
TS_FRAGMENT_DUE_NOW			CONSTANT NUMBER := 1;
TS_FRAGMENT_OVERDUE			CONSTANT NUMBER := 2;
TS_FRAGMENT_REALLY_OVERDUE	CONSTANT NUMBER := 3;
TS_FRAGMENT_DUE_SOON		CONSTANT NUMBER := 4;
TS_FRAGMENT_DUE_LATER		CONSTANT NUMBER := 5;

FUNCTION GenerateChangeGroupId
RETURN task.change_group_id%TYPE;

PROCEDURE CollectTasks (
	in_change_group_id			IN  task.change_group_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RegisterScheme (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,	
	in_description				IN  task_scheme.description%TYPE,
	in_db_class					IN  task_scheme.db_class%TYPE
);

PROCEDURE RegisterTaskType (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_name						IN  task_type.name%TYPE,
	in_parent_name				IN  task_type.name%TYPE DEFAULT NULL,
	in_description				IN  task_type.description%TYPE,
	in_default_status			IN  chain_pkg.T_TASK_STATUS DEFAULT chain_pkg.TASK_HIDDEN,
	in_db_class					IN  task_type.db_class%TYPE DEFAULT NULL,
	in_due_in_days				IN  task_type.due_in_days%TYPE DEFAULT NULL,
	in_mandatory				IN  task_type.mandatory%TYPE DEFAULT chain_pkg.ACTIVE,
	in_due_date_editable		IN  task_type.due_date_editable%TYPE DEFAULT chain_pkg.ACTIVE,
	in_review_every_n_days		IN  task_type.review_every_n_days%TYPE DEFAULT NULL,
	in_card_id					IN  task_type.card_id%TYPE DEFAULT NULL,
	in_invert_actions			IN  BOOLEAN DEFAULT TRUE,
	in_on_action				IN  T_TASK_ACTION_LIST DEFAULT NULL
);

PROCEDURE SetChildTaskTypeOrder (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_parent_name				IN  task_type.name%TYPE,
	in_names_by_order			IN  T_STRING_LIST	
);

PROCEDURE SetParentTaskTypeOrder (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_names_by_order			IN  T_STRING_LIST	
);

PROCEDURE CopyTaskTypeBranch (
	in_from_scheme_id			IN  task_type.task_scheme_id%TYPE,	
	in_to_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_from_name				IN  task_type.name%TYPE
);

FUNCTION GetTaskTypeId (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task_type.task_type_id%TYPE;

FUNCTION GetParentTaskTypeId (
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_type_id%TYPE;

FUNCTION GetParentTaskId (
	in_task_id					IN  task.task_id%TYPE
) RETURN task.task_type_id%TYPE;

FUNCTION GetTaskId (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task.task_id%TYPE;

FUNCTION GetTaskId (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE	
) RETURN task.task_id%TYPE;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE	
) RETURN task.task_id%TYPE;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task.task_id%TYPE;

FUNCTION GetTaskName (
	in_task_id					IN  task.task_id%TYPE
) RETURN task_type.name%TYPE;

FUNCTION GetTaskEntryName (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task_type.name%TYPE;

FUNCTION AddSimpleTask (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_task_type_id				IN	task.task_type_id%TYPE,
	in_task_status				IN	task.task_status_id%TYPE
) RETURN task.task_id%TYPE;


PROCEDURE ProcessTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_questionnaire_class		IN	questionnaire_type.CLASS%TYPE
);

PROCEDURE ProcessTaskScheme (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id				IN	task_type.task_scheme_id%TYPE
);

-- ensures that all of the tasks that exist in this scheme have been created
PROCEDURE RefreshScheme (
	in_scheme_id				IN	task_type.task_scheme_id%TYPE
);

PROCEDURE StartScheme (
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_name			IN  task_type.name%TYPE DEFAULT NULL
);

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ChangeTaskStatus (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

/*** THIS PROCEDURE SHOULD ONLY BE USED WHEN YOU CAN AND WILL MANUALLY MANAGE THE CASCADE CHANGES MANUALL ***/
PROCEDURE ChangeTaskStatusNoCascade (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

FUNCTION GetTaskStatus (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE
) RETURN task.task_status_id%TYPE;

FUNCTION GetTaskStatus (
	in_task_id					IN	task.task_id%TYPE
) RETURN task.task_status_id%TYPE;

PROCEDURE SetTaskDueDate (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
);

PROCEDURE SetTaskDueDate (
	in_task_id					IN	task.task_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
);

PROCEDURE GetFlattenedTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateTask (
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_next_review_date			IN	date,
	in_due_date					IN	date
);

PROCEDURE GetTaskSummary (
	in_task_scheme_id	IN	task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	out_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_suppl_relationship_cur	OUT security_pkg.T_OUTPUT_CUR --returns a [company_sid, suppl_relationship_is_active] structure
);

PROCEDURE GetMyActiveCompaniesByTaskType (
	in_task_scheme_id			IN task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	in_task_type_id				IN task_type.task_type_id%TYPE,
	in_duedate_fragment			IN NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveTasksForUser (
	in_user_sid					IN 	security_pkg.T_SID_ID,
	in_task_scheme_ids			IN	helper_pkg.T_NUMBER_ARRAY,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_count					OUT	NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE
);

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE
);

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteTaskFile (
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION HasEntry (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name				IN  task_entry.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE,
	in_entry_name_three			IN  task_entry.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_names				IN  T_STRING_LIST
) RETURN BOOLEAN;

PROCEDURE ToggleSkipTask (
	in_task_id					IN  task.task_id%TYPE,
	in_change_group_id			IN	task.change_group_id%TYPE
);

PROCEDURE ToggleSkipTask (
	in_task_id					IN  task.task_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTaskCardManagerData (
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_manager_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_type_card_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE MapTaskInvitationQnrType (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_questionnaire_type_id	IN  questionnaire_type.questionnaire_type_id%TYPE,
	in_include_children			IN  NUMBER
);

PROCEDURE GetInvitationTaskCardData (
	in_task_id				IN  task.task_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateTasksForReview;

PROCEDURE GetTaskTypesForAdminPage(
	out_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_parent_actions_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_task_scheme_cur		OUT security_pkg.T_OUTPUT_CUR
);

END task_pkg;
/
