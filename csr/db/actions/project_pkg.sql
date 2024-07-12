CREATE OR REPLACE PACKAGE ACTIONS.project_pkg
IS

-- errors
ERR_TAG_IN_USE			CONSTANT NUMBER := -20501; 
TAG_IN_USE EXCEPTION;
PRAGMA EXCEPTION_INIT(TAG_IN_USE, -20501);

ERR_DATES_OUT_OF_RANGE			CONSTANT NUMBER := -20502; 
DATES_OUT_OF_RANGE EXCEPTION;
PRAGMA EXCEPTION_INIT(DATES_OUT_OF_RANGE, -20502);

ERR_DATES_AFFECT_DATA			CONSTANT NUMBER := -20503; 
DATES_AFFECT_DATA EXCEPTION;
PRAGMA EXCEPTION_INIT(DATES_AFFECT_DATA, -20503);


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

PROCEDURE TrashObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_project_sid		IN security_pkg.T_SID_ID
);

PROCEDURE GetProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTaskStatuses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProjectTaskStatuses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProjectTaskPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateProject(
	in_act_id									IN security_pkg.T_ACT_ID,
	in_app_sid 								IN security_pkg.T_SID_ID,
	in_name										IN project.name%TYPE,
	in_start_dtm							IN project.start_dtm%TYPE,
	in_duration								IN NUMBER,
	in_max_period_duration		IN project.max_period_duration%TYPE,
	in_task_fields_xml				IN project.task_fields_xml%TYPE,
	in_task_period_fields_xml	IN project.task_period_fields_xml%TYPE,
	out_project_sid						OUT security_pkg.T_SID_ID
);

PROCEDURE AmendProject(
	in_act_id									IN security_pkg.T_ACT_ID,
	in_project_sid 						IN security_pkg.T_SID_ID,
	in_name										IN project.name%TYPE,
	in_start_dtm							IN project.start_dtm%TYPE,
	in_duration								IN NUMBER,
	in_max_period_duration		IN project.max_period_duration%TYPE,
	in_task_fields_xml				IN project.task_fields_xml%TYPE,
	in_task_period_fields_xml	IN project.task_period_fields_xml%TYPE
);

PROCEDURE GetProject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_project_sid 			IN security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetRoleMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_role_Id			IN	ROLE.role_id%TYPE,
	in_members_list	IN	VARCHAR2
);

PROCEDURE GetRolesAndMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProjectFromTask(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END project_pkg;
/
