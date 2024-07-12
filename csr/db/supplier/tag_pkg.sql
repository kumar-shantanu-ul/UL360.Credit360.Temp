CREATE OR REPLACE PACKAGE SUPPLIER.tag_pkg 
IS

TYPE T_TAG_IDS IS TABLE OF tag.tag_id%TYPE INDEX BY PLS_INTEGER;

ERR_TAG_IN_USE			CONSTANT NUMBER := -20501; 
TAG_IN_USE EXCEPTION;
PRAGMA EXCEPTION_INIT(TAG_IN_USE, -20501);

-- Securable object callbacks for tag group
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
);

-- create a tag_group
PROCEDURE CreateTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name						IN  tag_group.name%TYPE,
	in_multi_select				IN	tag_group.multi_select%TYPE,
	in_mandatory				IN	tag_group.mandatory%TYPE,
	in_render_as				IN	tag_group.render_as%TYPE,
	in_render_in				IN	tag_group.render_in%TYPE,
	out_tag_group_sid			OUT	security_pkg.T_SID_ID
);

-- AmendTagGroup
PROCEDURE AmendTagGroup (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_name		  				IN	tag_group.name%TYPE,
	in_multi_select				IN	tag_group.multi_select%TYPE,
	in_mandatory				IN	tag_group.mandatory%TYPE,
	in_render_as				IN	tag_group.render_as%TYPE,
	in_render_in				IN	tag_group.render_in%TYPE
);

-- update tag 
PROCEDURE UpdateTag(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_tag_id					IN	tag.tag_id%TYPE,
	in_tag						IN	tag.tag%TYPE,
	in_explanation				IN	tag.explanation%TYPE,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_is_visible				IN	tag_group_member.is_visible%TYPE
);

-- add a new tag to a group
PROCEDURE AddNewTagToGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_tag						IN	tag.tag%TYPE,
	in_explanation				IN	tag.explanation%TYPE,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_is_visible				IN	tag_group_member.is_visible%TYPE,
	out_tag_id					OUT	tag.tag_id%TYPE
);

PROCEDURE RemoveTagFromGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_tag_id					IN	tag.tag_id%TYPE
);

-- returns the schemes and tag groups this user can see 
PROCEDURE GetTagGroups(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);
	
-- return all tag groups and the products they are associated with for given app_sid
PROCEDURE GetAllTagGroups(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_name			IN	tag_group.name%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION ConcatTagGroupMembers(
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_max_length				IN 	INTEGER
) RETURN VARCHAR2;

PROCEDURE GetTagGroupsSummary(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTag(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_id					IN	tag.tag_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagAttributes(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_id					IN	tag.tag_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END tag_Pkg;
/

