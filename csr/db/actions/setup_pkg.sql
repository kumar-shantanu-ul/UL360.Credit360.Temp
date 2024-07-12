CREATE OR REPLACE PACKAGE ACTIONS.setup_pkg
IS


PROCEDURE GetAllTaskStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllProjectTaskStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllTaskStatusesForProject(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllPeriodStatusesForProject(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllProjectPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetAllRoles(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

-- return all tag groups and the Projects they are associated with for given app_sid
PROCEDURE GetAllTagGroups(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetAllTagGroupProjects(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE RemoveAssociatedProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_id				IN	NUMBER,
	in_type			IN	VARCHAR2,
	in_sids			IN	VARCHAR2
);

PROCEDURE AddAssociatedProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_id				IN	NUMBER,
	in_type			IN	VARCHAR2,
	in_sids			IN	VARCHAR2
);

PROCEDURE DeleteTaskStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_id				IN	task_status.task_status_id%TYPE
);

PROCEDURE SetTaskStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_id				IN	task_status.task_status_id%TYPE,
	in_label		IN	task_status.label%TYPE,
	in_is_live	IN	task_status.is_live%TYPE,
	in_colour		IN	task_status.colour%TYPE,
	in_is_default	IN	task_Status.is_default%TYPE,
	out_id			OUT	task_status.task_status_id%TYPE
);

PROCEDURE DeleteTaskPeriodStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_id				IN	TASK_PERIOD_STATUS.TASK_PERIOD_STATUS_id%TYPE
);

PROCEDURE SetTaskPeriodStatus(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_id							IN	TASK_PERIOD_STATUS.TASK_PERIOD_STATUS_id%TYPE,
	in_label						IN	TASK_PERIOD_STATUS.label%TYPE,
	in_colour						IN	TASK_PERIOD_STATUS.colour%TYPE,
	in_special_meaning				IN	TASK_PERIOD_STATUS.special_meaning%TYPE,
	in_means_pct_complete			IN	TASK_PERIOD_STATUS.means_pct_complete%TYPE,
	out_id							OUT	TASK_PERIOD_STATUS.TASK_PERIOD_STATUS_id%TYPE
);



PROCEDURE DeleteRole(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_id				IN	ROLE.ROLE_id%TYPE
);

PROCEDURE SetRole(
	in_act_id									IN	security_pkg.T_ACT_ID,
	in_app_sid								IN	security_pkg.T_SID_ID,
	in_id											IN	ROLE.ROLE_id%TYPE,
	in_name										IN	ROLE.name%TYPE,
	in_show_in_filter						IN	ROLE.show_in_filter%TYPE,
	in_permission_set_on_task	IN	ROLE.permission_set_on_task%TYPE,
	out_id										OUT	ROLE.ROLE_id%TYPE
);

PROCEDURE DeleteTagGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_tag_group_id		IN tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	in_name					IN  tag_group.name%TYPE,
	in_label				IN  tag_group.label%TYPE,
	in_multi_select			IN	tag_group.multi_select%TYPE,
	in_mandatory			IN	tag_group.mandatory%TYPE,
	in_render_as			IN	tag_group.render_as%TYPE,
	in_show_in_filter		IN	tag_group.show_in_filter%TYPE,
	out_tag_group_id		OUT	tag_group.tag_group_id%TYPE
);

PROCEDURE GetAllRolesAndMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- USED BY ACTIONS IMPORT CODE (WHISTLER ONLY ATM)
PROCEDURE ImportSetTaskRoleMember(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_role_id				IN	ROLE.role_id%TYPE,
	in_user_or_group_name	IN	VARCHAR2,
	in_pref_is_group		IN 	NUMBER,
	out_user_sid			OUT	security_pkg.T_SID_ID
);


PROCEDURE ImportDone(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ImportSetTaskStatus(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_task_status_id		IN 	task_status.task_status_id%TYPE,
	in_comment_text			IN	task_status_history.comment_text%TYPE,
	in_user_or_group_sid		IN	security_pkg.T_SID_ID
);


PROCEDURE ImportAddComment(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment_text				IN	TASK_COMMENT.comment_text%TYPE,
	in_user_or_group_sid		IN	security_pkg.T_SID_ID
);
END setup_pkg;
/
