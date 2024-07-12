CREATE OR REPLACE PACKAGE DONATIONS.region_group_pkg
IS

PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE CreateRegionGroup (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_description			IN	region_group.description%TYPE,
	/*in_currency_code		IN	currency.currency_code%TYPE,*/
	out_region_group_sid	OUT security_pkg.T_SID_ID
);

PROCEDURE AmendRegionGroup (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_description			IN	region_group.description%TYPE/*,
	in_currency_code		IN	currency.currency_code%TYPE*/
);

PROCEDURE GetRegionGroups(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
);


PROCEDURE GetRegionGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetRegionGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR	
);


PROCEDURE GetMyRegions(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	            IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetRegionFromGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_group_sid			IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);


PROCEDURE SetRegionGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	in_members					IN	VARCHAR2
);


FUNCTION ConcatRegionGroupMembers(
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	in_max_length				IN 	INTEGER
) RETURN VARCHAR2;

PROCEDURE GetRegionGroupsSummary(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionGroupsForRecipient(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetAllRegionGroupsAndRegions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

END region_group_pkg;
/