CREATE OR REPLACE PACKAGE  ACTIONS.tag_Pkg
IS

TYPE T_TAG_IDS IS TABLE OF tag.tag_id%TYPE INDEX BY PLS_INTEGER;

-- update tag 
PROCEDURE SetTag(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	in_tag_id					IN	tag.tag_id%TYPE,
	in_tag						IN	tag.tag%TYPE,
	in_explanation		IN	tag.explanation%TYPE,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_is_visible			IN	tag_group_member.is_visible%TYPE,
	out_tag_id				OUT	tag.tag_id%TYPE
);

PROCEDURE RemoveTagFromTask(
	in_task_sid	IN	task.task_sid%TYPE,
	in_tag_id	IN	tag.tag_id%TYPE
);

PROCEDURE RemoveTagFromGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE
);

PROCEDURE SetTaskTag(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_tag_id			IN	tag.tag_id%TYPE
);

PROCEDURE SetTaskTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	VARCHAR2
);

-- returns the Projects and tag groups this user can see 
PROCEDURE GetTagGroups(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForProject(
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsAndMemebrsProject (
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- return tag groups and their members for this project
-- optioinal task_sid (null if not interested) which will return selected if
-- selected for given task
PROCEDURE GetVisibleTagGroupsForProject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_task_sid			IN	TASK.task_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupAndMembers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	out_group_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_members_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForProjectSetup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_project_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION ConcatTagGroupMembers(
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	in_max_length			IN 	INTEGER
) RETURN VARCHAR2;


PROCEDURE GetTagGroupsSummary(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END tag_Pkg;
/

