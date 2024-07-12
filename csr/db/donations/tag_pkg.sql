CREATE OR REPLACE PACKAGE  DONATIONS.tag_Pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_class_id						IN security_pkg.T_CLASS_ID,
	in_name							IN security_pkg.T_SO_NAME,
	in_parent_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_name						IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE CreateTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_name							IN  tag_group.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE,
	in_render_as					IN	tag_group.render_as%TYPE,
	in_render_in					IN	tag_group.render_in%TYPE,
	out_tag_group_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE AmendTagGroup (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	tag_group.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE,
	in_render_as					IN	tag_group.render_as%TYPE,
	in_render_in					IN	tag_group.render_in%TYPE
);

PROCEDURE AssociateTagGroupWithSchemes (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_scheme_sids					IN	tag_group.name%TYPE
);

PROCEDURE AssociateSchemeWithTagGroups (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_tag_group_sids				IN	VARCHAR2
);

PROCEDURE UpdateTag(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tag_id						IN	tag.tag_id%TYPE,
	in_tag							IN	tag.tag%TYPE,
	in_explanation					IN	tag.explanation%TYPE,
	in_pos							IN	tag_group_member.pos%TYPE,
	in_is_visible					IN	tag_group_member.is_visible%TYPE
);

PROCEDURE GetTagGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

-- add a new tag to a group
PROCEDURE AddNewTagToGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tag							IN	tag.tag%TYPE,
	in_explanation					IN	tag.explanation%TYPE,
	in_pos							IN	tag_group_member.pos%TYPE,
	in_is_visible					IN	tag_group_member.is_visible%TYPE,
	out_tag_id						OUT	tag.tag_id%TYPE
);

PROCEDURE RemoveTagFromGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tag_id						IN	tag.tag_id%TYPE
);

-- NOTE: the tag ids from in_tags_to_leave will REMAIN in DB, the others that belongs to same tag_group will be deleted
PROCEDURE RemoveTagsFromGroup(
    in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_tags_to_leave				IN	VARCHAR2
);

PROCEDURE SetDonationTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_id					IN	donation.donation_id%TYPE,
	in_tag_ids						IN	VARCHAR2
);

PROCEDURE SetRecipientTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_recipient_sid				IN	recipient.recipient_sid%TYPE,
	in_tag_ids						IN	VARCHAR2
);

-- returns the schemes and tag groups this user can see 
PROCEDURE GetTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForScheme(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForRecipient(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

-- return all tag groups and the Projects they are associated with for given app_sid
PROCEDURE GetAllTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

-- return tag groups and their members for this scheme
PROCEDURE GetVisibleTagGroupsForScheme(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_donation_Id					IN	donation.donation_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

-- return all tag groups and the schemes they are associated with for given app_sid
PROCEDURE GetTagGroupsForSetup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForSchemeSetup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupsForFcSetup(
	in_scheme_sid					IN	security_pkg.T_SID_ID,
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION ConcatTagGroupMembers(
	in_tag_group_sid				IN	security_pkg.T_SID_ID,
	in_max_length					IN 	INTEGER
) RETURN VARCHAR2;

PROCEDURE GetTagGroupsSummary(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagDonationTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_id					IN	donation.donation_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagRecipientTags(
	in_recipient_sid				IN security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagsForScheme(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_group_sid				IN  tag_group.tag_group_sid%TYPE,
	in_scheme_sid					IN	scheme.scheme_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTag(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag_id						IN	tag.tag_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionTagGroups(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRecipientTagGroups(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetTagGroupSidFromGroupName(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_name							IN	tag_group.name%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION GetTagIdFromName(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_tag							IN	tag.tag%TYPE,
	in_tag_group_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER;

END tag_Pkg;
/

