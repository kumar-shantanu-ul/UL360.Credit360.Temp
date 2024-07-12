CREATE OR REPLACE PACKAGE csr.Delegation_Pkg AS

DELEG_PERMISSION_READ				CONSTANT NUMBER := 1;
DELEG_PERMISSION_WRITE				CONSTANT NUMBER := 2;
DELEG_PERMISSION_DELETE				CONSTANT NUMBER := 4;
DELEG_PERMISSION_ALTER				CONSTANT NUMBER := 8;
DELEG_PERMISSION_OVERRIDE			CONSTANT NUMBER := 16;

DELEG_PERMISSION_DELEGEE			CONSTANT NUMBER := 3;
DELEG_PERMISSION_DELEGATOR			CONSTANT NUMBER := 11;

DELEG_ALERT_IGNORE_SHEETS_OLDER_THAN	CONSTANT NUMBER := 365;

-- used to be TABLE OF DELEGATION_REGION%ROWTYPE but this breaks if the table has columns
-- in a different order etc.
TYPE DELEGATION_REGION_REC IS RECORD (
    delegation_sid             delegation_region.delegation_sid%TYPE,
    region_sid                 delegation_region.region_sid%TYPE,
    mandatory                  delegation_region.mandatory%TYPE,
    pos                        delegation_region.pos%TYPE,
    aggregate_to_region_sid    delegation_region.aggregate_to_region_sid%TYPE,
    app_sid                    delegation_region.app_sid%TYPE,
    visibility				   delegation_region.visibility%TYPE
);
	
TYPE T_DELEGATION_REGION_TABLE IS
  TABLE OF DELEGATION_REGION_REC;

TYPE DELEG_REGION_DESC_REC IS RECORD (
    delegation_sid             delegation_region.delegation_sid%TYPE,
    region_sid                 delegation_region.region_sid%TYPE,
    lang					   delegation_region_description.lang%TYPE,
    description				   delegation_region_description.lang%TYPE
);

TYPE T_DELEG_REGION_DESC_TABLE IS
  TABLE OF DELEG_REGION_DESC_REC;

TYPE T_OVERLAP_DELEG_REC IS RECORD (
	delegation_sid						v$delegation.delegation_sid%TYPE,
	parent_sid							v$delegation.parent_sid%TYPE,
	name								v$delegation.name%TYPE,
	description							v$delegation.description%TYPE,
	allocate_users_to					v$delegation.allocate_users_to%TYPE,
	group_by							v$delegation.group_by%TYPE,
	reminder_offset						v$delegation.reminder_offset%TYPE,
	is_note_mandatory					v$delegation.is_note_mandatory%TYPE,
	is_flag_mandatory					v$delegation.is_flag_mandatory%TYPE,
	fully_delegated						v$delegation.fully_delegated%TYPE,
	start_dtm							v$delegation.start_dtm%TYPE,
	end_dtm								v$delegation.end_dtm%TYPE,
	period_set_id						v$delegation.period_set_id%TYPE,
	period_interval_id					v$delegation.period_interval_id%TYPE,
	schedule_xml						v$delegation.schedule_xml%TYPE,
	show_aggregate						v$delegation.show_aggregate%TYPE,
	delegation_policy					v$delegation.delegation_policy%TYPE,
	submission_offset					v$delegation.submission_offset%TYPE,
	tag_visibility_matrix_group_id		v$delegation.tag_visibility_matrix_group_id%TYPE,
	allow_multi_period					v$delegation.allow_multi_period%TYPE
);

TYPE T_OVERLAP_DELEG_CUR IS REF CURSOR RETURN T_OVERLAP_DELEG_REC;

TYPE T_OVERLAP_DELEG_INDS_REC IS RECORD (
	delegation_sid						v$delegation_ind.delegation_sid%TYPE,
	ind_sid								v$delegation_ind.ind_sid%TYPE,
	description							v$delegation_ind.description%TYPE,
	mandatory							v$delegation_ind.mandatory%TYPE,
	pos									v$delegation_ind.pos%TYPE,
	section_key							v$delegation_ind.section_key%TYPE,
	var_expl_group_id					v$delegation_ind.var_expl_group_id%TYPE,
	visibility							v$delegation_ind.visibility%TYPE,
	css_class							v$delegation_ind.css_class%TYPE
);

TYPE T_OVERLAP_DELEG_INDS_CUR IS REF CURSOR RETURN T_OVERLAP_DELEG_INDS_REC;

TYPE T_OVERLAP_DELEG_REGIONS_REC IS RECORD (
	delegation_sid						v$delegation_region.delegation_sid%TYPE,
	region_sid							v$delegation_region.region_sid%TYPE,
	description							v$delegation_region.description%TYPE,
	mandatory							v$delegation_region.mandatory%TYPE,
	pos									v$delegation_region.pos%TYPE,
	aggregate_to_region_sid				v$delegation_region.aggregate_to_region_sid%TYPE,
	visibility							v$delegation_region.visibility%TYPE
);

TYPE T_OVERLAP_DELEG_REGIONS_CUR IS REF CURSOR RETURN T_OVERLAP_DELEG_REGIONS_REC;

/**
 * CreateObject helper
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_class_id		The class Id of the object
 * @param in_name			The name
 * @param in_parent_sid_id	The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject helper
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);


/**
 * DeleteObject helper
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject helper
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);


/**
 * Called by val_pkg.setValue to allow us to unhook anything
 * e.g. if we keep a pointer to a val_id
 * 	
 * @param in_val_id				The Val Id being changed
 * @param in_imp_val_Id			The Imp Val Id
 */ 
PROCEDURE OnValChange(
	in_val_id		IN imp_val.set_val_id%TYPE,
	in_imp_val_id	IN imp_val.imp_val_id%TYPE
);

FUNCTION CheckDelegationPermission( 
	in_act_id						IN security_pkg.T_ACT_ID,
	in_delegation_sid				IN security_pkg.T_SID_ID,
	in_permission_set				IN delegation_user.deleg_permission_set%TYPE
) RETURN BOOLEAN;

FUNCTION SQL_CheckDelegationPermission( 
	in_act_id						IN security_pkg.T_ACT_ID,
	in_delegation_sid				IN security_pkg.T_SID_ID,
	in_permission_set				IN delegation_user.deleg_permission_set%TYPE
) RETURN BINARY_INTEGER;

FUNCTION GetRootDelegationSid(
	in_delegation_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER;

-- ============================
-- create and amend delegations
-- ============================

/**
 * CreateTopLevelDelegation
 * 
 * @param in_act_id					Access token
 * @param in_name					The name
 * @param in_date_from				Date the delegation runs from
 * @param in_date_to				Date the delegation runs to
 * @param in_period_set_id			The period set
 * @param in_period_interval_id		The period interval (m|q|h|y)
 * @param in_allocate_users_to		Allocate users to region|indicator
 * @param in_app_sid				The sid of the Application/CSR object
 * @param in_note					Note for delegation
 * @param in_group_by				Comma separated list to group by (region|indicator)
 * @param in_schedule_xml			Schedule Xml block (produced by NPSL.Recurrence)
 * @param in_submission_offset		Offset in days (for submission)
 * @param in_reminder_offset		Offset in days (for reminder)
 * @param in_note_mandatory			Are notes mandatory (i.e. are they methodologies?)
 * @param out_delegation_sid		New delegation sid
 */
PROCEDURE CreateTopLevelDelegation(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_name							IN	delegation.name%TYPE,
	in_date_from					IN	delegation.start_dtm%TYPE,
	in_date_to						IN	delegation.end_dtm%TYPE,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
	in_allocate_users_to			IN	delegation.allocate_users_to%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_note							IN	form.note%TYPE,
	in_group_by						IN	delegation.group_by%TYPE,
	in_schedule_xml					IN	delegation.schedule_xml%TYPE,			--this is submission_schedule.
	in_submission_offset			IN	delegation.submission_offset%TYPE,
	in_reminder_offset				IN	delegation.reminder_offset%TYPE,
	in_note_mandatory				IN	delegation.is_note_mandatory%TYPE,
	in_flag_mandatory				IN	delegation.is_flag_mandatory%TYPE,
	in_policy						IN	delegation_policy.submit_confirmation_text%TYPE DEFAULT NULL,
	in_vis_matrix_tag_group 		IN  DELEGATION.tag_visibility_matrix_group_id%TYPE DEFAULT NULL,
	in_allow_multi_period			IN	delegation.allow_multi_period%TYPE DEFAULT 0,
	out_delegation_sid				OUT	security_pkg.T_SID_ID
);

/**
 * AddDescriptionToDelegation
 * @param in_act_id					Access token
 * @param in_delegation_sid		    Delegation sid
 * @param in_lang					The language code
 * @param in_description			The description
 */
PROCEDURE AddDescriptionToDelegation(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_lang							IN	delegation_description.lang%TYPE,
	in_description					IN	delegation_description.description%TYPE
);

/**
 * AddIndicatorToTLD
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_sid_id					The sid of the object
 * @param in_description			The description
 * @param in_pos					Sequence number for indicator
 */                             	
PROCEDURE AddIndicatorToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_description					IN	delegation_ind_description.description%TYPE,
	in_pos							IN	delegation_ind.pos%TYPE
);

/**
 * AddIndicatorToTLD
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_sid_id					The sid of the object
 * @param in_langs					Languages
 * @param in_translations			Translations in various languages
 * @param in_pos					Sequence number for indicator
 */                             	
PROCEDURE AddIndicatorToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_ind.pos%TYPE
);

/**
 * AddIndicatorsToTLD
 * 
 * @param in_delegation_sid			The sid of the object
 * @param in_ind_sids				The collection of indicator sids
 * @param in_tr_ind_sids			The collection of indicator sids that we have translation for
 * @param in_langs					Languages
 * @param in_translations			Translations in various languages
 * @param in_pos					Start sequence number for indicator (optional, default is zero)
 */ 
PROCEDURE AddIndicatorsToTLD(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_tr_ind_sids					IN	security_pkg.T_SID_IDS,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_ind.pos%TYPE DEFAULT 0
);

/**
 * AddRegionToTLD
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_sid_id					The sid of the object
 * @param in_description			The description
 * @param in_pos					Sequence number for region
 */                             	
PROCEDURE AddRegionToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_description					IN	delegation_region_description.description%TYPE,
	in_pos							IN	delegation_region.pos%TYPE
);

/**
 * AddRegionToTLD
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_sid_id					The sid of the object
 * @param in_langs					Languages
 * @param in_translations			Translations in various languages
 * @param in_pos					Sequence number for region
 */                             	
PROCEDURE AddRegionToTLD(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_region.pos%TYPE
);

/**
 * AddRegionsToTLD
 * 
 * @param in_delegation_sid			The sid of the object
 * @param in_region_sids			The collection of region sids
 * @param in_tr_region_sids			The collection of region sids that we have translation for
 * @param in_langs					Languages
 * @param in_translations			Translations in various languages
 * @param in_pos					Start sequence number for region (optional, default is zero)
 */  
PROCEDURE AddRegionsToTLD(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_tr_region_sids				IN	security_pkg.T_SID_IDS,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	delegation_region.pos%TYPE DEFAULT 0
);

/**
 * Create a non top level delegation
 * 
 * @param in_act_id					Access token
 * @param in_parent_sid				The sid of the parent delegation object
 * @param in_app_sid				The sid of the Application/CSR object
 * @param in_name					The name
 * @param in_indicators_list		Comma separated list of indicator sids (description comes from top level delegation)
 * @param in_regions_list			Comma separated list of region sids (description comes from top level delegation)
 * @param in_mandatory_list			Comma separated list of mandatory sids
 * @param in_user_sid_list			Comma separated list of user sids
 * @param in_period_set_id			The period set
 * @param in_period_interval_id		The period interval (m|q|h|y)
 * @param in_schedule_xml			Schedule Xml block (produced by NPSL.Recurrence)
 * @param in_submission_offset		Alternative to schedule xml -- days after sheet.end_dtm
 * @param in_note					Note on delegation form
 * @param out_delegation_sid		New delegation sid
 */
PROCEDURE CreateNonTopLevelDelegation(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_app_sid 						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_name							IN	delegation.name%TYPE,
	in_indicators_list				IN	VARCHAR2 DEFAULT NULL,
	in_regions_list					IN	VARCHAR2 DEFAULT NULL,
	in_mandatory_list				IN	VARCHAR2 DEFAULT NULL,
	in_user_sid_list				IN	VARCHAR2 DEFAULT NULL,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
	in_schedule_xml					IN	delegation.schedule_xml%TYPE,
	in_note							IN	delegation.note%TYPE,
	in_submission_offset			IN	delegation.submission_offset%TYPE DEFAULT NULL,
	in_part_of_deleg_plan			IN	NUMBER DEFAULT 0,
	in_show_aggregate				IN	delegation.show_aggregate%TYPE DEFAULT 0,
	out_delegation_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE INTERNAL_CopyRootDelegBits(
	in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_new_delegation_sid		IN security_pkg.T_SID_ID
);

PROCEDURE CopyDelegation(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_new_name					IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    out_new_delegation_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE CopyDelegationTemplate(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_new_delegation_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE CopyNonTopDelegation(
	in_act_id					IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid		IN  security_pkg.T_SID_ID,
    in_parent_sid				IN  security_pkg.T_SID_ID,
    in_new_name					IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    out_new_delegation_sid		OUT security_pkg.T_SID_ID
);

PROCEDURE CopyDelegationChangePeriod(
	in_act_id						IN  security_pkg.T_ACT_ID,
    in_copy_delegation_sid			IN  security_pkg.T_SID_ID,
    in_new_name						IN	delegation.name%TYPE, -- can be null (i.e. use that of deleg being copied)
    in_start_dtm					IN	delegation.start_dtm%TYPE,
    in_end_dtm						IN	delegation.end_dtm%TYPE,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
    out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SplitDelegation(
    in_act_id			    IN  security_pkg.T_ACT_ID,
    in_root_delegation_sid  IN  security_pkg.T_SID_ID,
    in_new_start_dtm        IN  delegation.start_dtm%TYPE,
    out_new_root_sid        OUT security_pkg.T_SID_ID
);

/**
 * Inserts a step into the delegation structure
 * It takes a copy of the delegation and inserts it higher up the tree
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param out_new_delegation_sid	The sid of the new delegation
 */
PROCEDURE InsertBefore(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_user_sid_list		IN	VARCHAR2,
	out_new_delegation_sid	OUT	security_pkg.T_SID_ID
);
/**
-- InsertAfter parent is different from InsertBefore child in cases where
-- 	*The child is being filled in for subsidiaries and the parent is not
--	*The parent is not fully delegated. 
 */
PROCEDURE InsertAfter(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_new_delegation_sid	OUT	security_pkg.T_SID_ID
);

/**
 * This deletes part of a delegation step.
 * 
 * This happends as below:
 * 
 *      a       TO       a
 *     / \              /|\
 *    X   d            b c d
 *   / \
 *  b   c
 *
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 */
PROCEDURE RemoveDelegationStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_select_after_sid	OUT	security_pkg.T_SID_ID -- typically we'll need to select something other than this one in the UI
);

/**
 * Terminate a delegation. The delegation won't be terminated
 * if it contains sheets with pending or approved values.
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 */
PROCEDURE Terminate(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_delegation_sid	IN 	security_pkg.T_SID_ID
);

/*  */
PROCEDURE TerminateForRegion(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	in_disposal_dtm		IN	DATE,
	in_inclusive		IN	number
);

/**
 * FindOverlaps (LEGACY -- 4 users left)
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_parent_sid			The sid of the parent object
 * @param in_start_dtm			The start date
 * @param in_end_dtm			The end date
 * @param in_indicators_list	.
 * @param in_regions_list		.
 * @param out_cur				The rowset
 */
PROCEDURE FindOverlaps(
	in_act_id		 				IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	DELEGATION.start_dtm%TYPE,
	in_end_dtm						IN	DELEGATION.end_dtm%TYPE,
	in_indicators_list				IN	VARCHAR2,
	in_regions_list					IN	VARCHAR2,
	out_cur							OUT	T_OVERLAP_DELEG_CUR
);

/**
 * Checks if delegation creation / modification would create overlaps
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the existing delegation (may be NULL for new delegations)
 * @param in_ignore_self			1 to exclude the passed in delegation from the overlap checking (for modification)
 * @param in_parent_sid				The sid of the parent delegation
 * @param in_start_dtm				The start date of the delegation
 * @param in_end_dtm				The end date of the delegations
 * @param in_indicators_list		Indicators that will be set in the delegation (defaulted to the current list if an empty array is passed)
 * @param in_regions_list			Regions that will be set in the delegation (defaulted to the current list if an empty array is passed)
 * @param out_deleg_cur				Details of any overlapping delegations
 * @param out_deleg_ind_cur			Indicators in overlapping delegations
 * @param out_deleg_regions_cur		Regions in overlapping delegations
 */
PROCEDURE ExFindOverlaps(
	in_act_id		 				IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_ignore_Self					IN	NUMBER,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	delegation.start_dtm%TYPE,
	in_end_dtm						IN	delegation.end_dtm%TYPE,
	in_indicators_list				IN	security_pkg.T_SID_IDS,
	in_regions_list					IN	security_pkg.T_SID_IDS,
	out_deleg_cur					OUT	T_OVERLAP_DELEG_CUR,
	out_deleg_inds_cur				OUT	T_OVERLAP_DELEG_INDS_CUR,
	out_deleg_regions_cur			OUT	T_OVERLAP_DELEG_REGIONS_CUR
);

PROCEDURE GetDelegationStructure(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur_deleg			OUT	SYS_REFCURSOR,
	out_cur_children		OUT	SYS_REFCURSOR,
	out_cur_inds			OUT	SYS_REFCURSOR,
	out_cur_ind_flags		OUT	SYS_REFCURSOR,
	out_cur_ind_tags		OUT SYS_REFCURSOR,
	out_cur_var_expl_groups	OUT	SYS_REFCURSOR,
	out_cur_var_expls		OUT	SYS_REFCURSOR,
	out_cur_valid_rules		OUT	SYS_REFCURSOR,
	out_cur_regions			OUT	SYS_REFCURSOR,
	out_cur_ind_depends		OUT	SYS_REFCURSOR,
	out_cur_sheet_ids		OUT	SYS_REFCURSOR
);

/**
 * Check if setting indicators/regions would leave any delegations empty
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_indicators_list	List of indicators
 * @param out_empty_delegs		Delegations that would be left empty
 * @praam out_split_delegs		Delegations/regions that would be removed from split delegations
 */
PROCEDURE CheckSetIndicationsAndRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_indicators_list	IN	VARCHAR2,
	in_regions_list		IN	VARCHAR2,
	out_empty_delegs	OUT	SYS_REFCURSOR,
	out_split_delegs	OUT	SYS_REFCURSOR
);

/**
 * Sets which indicators are used in this delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_indicators_list	.
 * @param in_mandatory_list		.
 */
PROCEDURE SetIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_indicators_list		IN	VARCHAR2,
	in_mandatory_list		IN	VARCHAR2,
	in_propagate_down		IN	NUMBER DEFAULT 1
);

/**
 * Sets which regions are used in this delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_regions_list		.
 * @param in_mandatory_list		.
 */
PROCEDURE SetRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_regions_list		IN	VARCHAR2,
	in_mandatory_list	IN	VARCHAR2
);

PROCEDURE SetMandatory(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_mandatory_list		IN	VARCHAR2
);

/**
 * Push down indicator + regions used in parent sid onto child delegation.
 * Only used by delegation plan template synchronisation, where the "parent" sid is the template/master delegation's sid. 
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_child_sid		.
 * @param out_delegation_changed Has the deleg changed? 0 unchanged, >0 changed
 * @param out_has_overlaps If any delegation would have created overlaps and has therefore been skipped. 0 no overlaps, 1 overlaps found
 */
PROCEDURE SynchChildWithParent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_child_sid			IN	security_pkg.T_SID_ID, 
	out_delegation_changed	OUT	NUMBER,
	out_has_overlaps		OUT NUMBER,
	out_overlap_reg_cur		OUT	T_OVERLAP_DELEG_REGIONS_CUR
);


/**
 * Sets which users are dealing with a delegation (and updates
 * the group etc - each delegation is a group, so the membership
 * of the group is important since the DACL gives members 
 * permission to alter the delegation etc).
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_users_list			Comma separated list of user sids dealing with this delegation
 */
PROCEDURE SetUsers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_users_list		IN	VARCHAR2
);

PROCEDURE DeleteUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_user_sid			security_pkg.T_SID_ID
) ;

PROCEDURE UNSEC_AddUser(
	in_act_id						security_pkg.T_ACT_ID,
	in_delegation_sid				security_pkg.T_SID_ID,
	in_user_sid						security_pkg.T_SID_ID,
	in_permission_set				delegation_user.deleg_permission_set%TYPE DEFAULT DELEG_PERMISSION_DELEGEE
);

PROCEDURE SetRoles(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_roles_list		IN	VARCHAR2
);

PROCEDURE UNSEC_AddRole(
	in_act_id						security_pkg.T_ACT_ID,
	in_delegation_sid				security_pkg.T_SID_ID,
	in_role_sid						security_pkg.T_SID_ID,
	in_permission_set				delegation_role.deleg_permission_set%TYPE DEFAULT DELEG_PERMISSION_DELEGEE
);

/**
 * Update the description and position for the region 
 * in a delegation
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The delegation
 * @param in_region_sid				The region
 * @param in_langs					Languages for translations
 * @param in_translations			Translations into various languagesn
 * @param in_pos					The sequence number
 */
PROCEDURE UpdateRegion(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_region_sid					IN	VARCHAR2,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	VARCHAR2
);

/**
 * Update the description and position for the indicator
 * in a delegation
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The delegation
 * @param in_ind_sid				The indicator
 * @param in_langs					Languages for translations
 * @param in_translations			Translations into various languagesn
 * @param in_pos					The sequence number
 */
PROCEDURE UpdateIndicator(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid						IN	VARCHAR2,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_translations					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pos							IN	VARCHAR2
);

/**
 * Update the dates covered by the delegation. This may
 * raise ERR_SHEET_OVERLAPS or (a new SHEETS_EXIST) error.
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_start_dtm			The new start date
 * @param in_end_dtm			The new end date
 */
PROCEDURE UpdateDates(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE
);

/**
 * Update bits of a delegation
 * 
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_name					The delegation name
 * @param in_note					The delegation note
 * @param in_group_by				Comma separate delegation group by (region|indicator)
 * @param in_is_note_mandatory		Are notes mandatory?
 * @param in_is_flag_mandatory		Are flags mandatory?
 * @param in_show_aggregate			Show aggregates?
 */
PROCEDURE UpdateDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_name					IN DELEGATION.name%TYPE,
	in_note					IN DELEGATION.NOTE%TYPE,
	in_group_by				IN DELEGATION.GROUP_BY%TYPE,
	in_is_note_mandatory	IN DELEGATION.IS_NOTE_MANDATORY%TYPE,
	in_is_flag_mandatory	IN DELEGATION.IS_FLAG_MANDATORY%TYPE,
	in_show_aggregate		IN DELEGATION.SHOW_AGGREGATE%TYPE,
	in_vis_matrix_tag_group	IN DELEGATION.tag_visibility_matrix_group_id%TYPE DEFAULT NULL
);

/**
 * Update delegation policy
 * 
 * @param in_delegation_sid				The sid of the object
 * @param in_submit_confirmation_text	Delegation Policy text (null if not required).
 */
PROCEDURE UpdatePolicy(
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_submit_confirmation_text	IN DELEGATION_POLICY.SUBMIT_CONFIRMATION_TEXT%TYPE
);

/**
 * SetTranslation (Update delegation description)
 * 
 * @param in_delegation_sid			The sid of the object
 * @param in_lang					The delegation lang
 * @param in_description			The delegation description
 */
PROCEDURE SetTranslation(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_lang					IN DELEGATION_DESCRIPTION.LANG%TYPE,
	in_description			IN DELEGATION_DESCRIPTION.DESCRIPTION%TYPE
);

/**
 * SetSchedule (Update schedule settings)
 *
 * @param in_act_id					Access token
 * @param in_delegation_sid			The sid of the object
 * @param in_schedule_xml			The schedule xml
 * @param in_submission_offset		The submission offset
 * @param in_reminder_offset		The reminder offset
 */
PROCEDURE SetSchedule(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_delegation_sid		IN security_pkg.T_SID_ID,
	in_schedule_xml			IN DELEGATION.SCHEDULE_XML%TYPE,
	in_submission_offset	IN DELEGATION.SUBMISSION_OFFSET%TYPE,
	in_reminder_offset		IN DELEGATION.REMINDER_OFFSET%TYPE
); 

/*
 * UpdateSheetDatesForDelegation (Update sheet schedule settings for this deleg and all children)
 */
PROCEDURE UpdateSheetDatesForDelegation(
	in_delegation_sid		IN security_pkg.T_SID_ID,
	in_schedule_xml			IN delegation.schedule_xml%TYPE,
	in_submission_offset	IN delegation.submission_offset%TYPE,
	in_reminder_offset		IN delegation.reminder_offset%TYPE
);

PROCEDURE GetSheetSubmissionDtm(
	in_delegation_end_dtm	DATE,
	in_period_set_id		delegation.period_set_id%TYPE,
	in_period_interval_id	delegation.period_interval_id%TYPE,
	in_sheet_id				IN sheet.sheet_id%TYPE,
	in_schedule_xml			IN delegation.schedule_xml%TYPE,
	in_submission_offset	IN delegation.submission_offset%TYPE,
	out_dtm					OUT sheet.submission_dtm%TYPE
);

PROCEDURE GetDateFromScheduleXML(
	in_start_dtm			IN DATE,
	in_end_dtm				IN DATE,
	in_schedule_end_dtm		IN DATE,
	in_schedule_xml			IN delegation.schedule_xml%TYPE,
	in_period_set_id		IN delegation.period_set_id%TYPE,
	in_period_interval_id	IN delegation.period_interval_id%TYPE,
	out_dtm					OUT DATE
);

-- ==================================
-- get information about a delegation
-- ==================================

/**
 * Get basic bits of information about a specific delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetDelegation(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);


/**
 * Return all the info about the delegation in one shot
 * (region, ind, category, delegee, delegator)
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * GetDelegationDescriptions
 * @param in_act_id					Access token
 * @param in_delegation_sid		    Delegation sid
 * @param out_cur				The rowset
 */
PROCEDURE GetDelegationDescriptions(
--	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

/**
 * Return all the files associated with a delegation and/or children
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetAllFiles(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_cur_postit			OUT SYS_REFCURSOR
);

/**
 * Get measure conversion details for all indicators in
 * this delegation.
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_start_dtm			The start date
 * @param out_cur				The rowset
 */
PROCEDURE GetMeasureConversions(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_delegation_sid	 	IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	out_cur					OUT SYS_REFCURSOR
);

/**
 * GetIndicators
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_section_key		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * GetIndicatorFlags
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_section_key		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicatorFlags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * GetIndicatorDataSources
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_section_key		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicatorDataSources(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_section_key			IN	delegation_ind.section_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Get users associated with this delegation.
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Get regions associated with this delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Get lowest level regions that this delegation was
 * delegated to
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetLowestLevelRegions(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_root_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);


/**
 * Return the regions and indicators that belong to child delegations
 * also shows if we are the delgator to the region and if the granularity
 * differs. This is all very specific to displaying sheets.
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param out_cur			The rowset
 */
PROCEDURE GetChildDelegations(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_start_dtm					IN DATE,
	in_end_dtm						IN DATE,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Simply returns all child delegations for the delegation sid passed in
 * that overlap the date range passed in
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param out_cur			The rowset
 */
PROCEDURE GetAllChildDelegations(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,
	in_start_dtm		IN DATE,
	in_end_dtm			IN DATE,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * Returns summary information about child delegations appropriate
 * for showing in a web page
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param out_cur			The rowset
 */
PROCEDURE GetChildDelegationOverview(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR,
	out_user_cur		OUT	SYS_REFCURSOR
);

/**
 * Determine which regions the given delegation could contain
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetPossibleRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * Determine which indicators the given delegation could contain
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetPossibleIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * GetPossibleChildDelItems
 * 
 * @param in_act_id						Access token
 * @param in_parent_delegation_sid		Parent delegation sid
 * @param out_cur						The rowset
 */
PROCEDURE GetPossibleChildDelItems(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT SYS_REFCURSOR
);






-- ==================================
-- get delegations based on specific 
-- criteria (e.g. by region, ind etc)
-- ==================================
PROCEDURE GetDelegsForRegionTerm(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_inactive_dtm	IN	DATE,
	out_delegs_cur	OUT	SYS_REFCURSOR
);
 
/**
 * Get the delegation sheets in the given time period which
 * belong to the supplied region sid or its children.
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param out_cur			The rowset
 */
PROCEDURE GetSheetStatsForPortletGauge(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetSheetStatsForPortletGauge_Legacy(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * Get the delegations in the given time period which
 * match the supplied filter
 * 
 * @param in_act_id			Access token
 * @param in_ind_sid		An indicator the delegation must include (may be null)
 * @param in_region_sid		A region the delegation must include (may be null)
 * @param in_user_sid		A user the delegation must include (may be null)
 * @param in_filter_ind		An indicator tree root to filter the delegations by (may be null for no filter)
 * @param in_filter_region 	An indicator tree root to filter the delegations by (may be null for no filter)
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param out_deleg_cur		Delegation details
 * @param out_sheet_cur		Sheet details
 * @param out_users_cur		Delegation user details
 */
PROCEDURE GetDelegations(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_filter_ind					IN	security_pkg.T_SID_ID,
	in_filter_region				IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_sheet_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
);

/**
 * Get delegations filtered by various criteria for the sheet editor.
 * Only returns delegations the user has write permission on
 */
PROCEDURE GetDelegationsForSheetEditor(
	in_start_dtm					IN	delegation.start_dtm%TYPE,
	in_end_dtm						IN	delegation.end_dtm%TYPE,
	in_from_level					IN	NUMBER,
	in_to_level						IN	NUMBER,
	in_delegation_name_match		IN	VARCHAR2,
	in_delegation_name				IN	delegation.name%TYPE,
	in_delegation_user_sid			IN	delegation_user.user_sid%TYPE,
	in_root_region_sid				IN	delegation_region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_regions_cur					OUT	SYS_REFCURSOR
);

/**
 * Get a list of sheet start/end dates for the given delegations
 */
PROCEDURE GetSheetsForSheetEditor(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Set dates for sheets matching the level, start and end date for
 * the given delegations
 */
PROCEDURE SetSheetDates(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_reminder_dtm					IN	sheet.reminder_dtm%TYPE,
	in_submission_dtm				IN	sheet.submission_dtm%TYPE,
	out_affected					OUT	NUMBER	
);

/**
 * Get a list of delegations which the user needs to do
 * things for (i.e. not old ones that haven't been touched within
 * the last week and the due date was over 60 days ago, and the
 * state is accepted)
 * 
 * @param out_sheets				Sheet details
 * @param out_users					User details
 * @param out_deleg_regions			Region details (restricted by in_region_sid)
*/

PROCEDURE GetMyDelegations(
	out_sheets				OUT	SYS_REFCURSOR,
	out_users				OUT	SYS_REFCURSOR,
	out_deleg_regions		OUT	SYS_REFCURSOR
);

PROCEDURE GetMyDelegations(
	in_days					IN	NUMBER,
	out_sheets				OUT	SYS_REFCURSOR,
	out_users				OUT	SYS_REFCURSOR,
	out_deleg_regions		OUT	SYS_REFCURSOR
);

PROCEDURE GetMyDelegations(
	in_region_sid			IN	NUMBER,
	in_days					IN	NUMBER,
	out_sheets				OUT	SYS_REFCURSOR,
	out_users				OUT	SYS_REFCURSOR,
	out_deleg_regions		OUT	SYS_REFCURSOR
);

/**
 * Get variance counts on my delegations (useful to help approvers investigate further)
 * Call GetMyDelegations before calling this to populate temp_delegation_detail.
 */
-- Looks like it's only used by GreenPrint client code, which is all redundant (client no longer exists).
PROCEDURE GetMyVarianceCounts(
	out_variance_counts		OUT	SYS_REFCURSOR
);

/**
 * Get information about specific indicators (delegations can 
 * rename indicators)
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_indicator_list		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_indicator_list	IN	VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Get information about specific regions (delegations can 
 * rename regions)
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_region_list		.
 * @param out_cur				The rowset
 */
PROCEDURE GetRegionsForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_region_list	IN	VARCHAR2,
	out_cur			OUT	SYS_REFCURSOR
);


/**
 * GetSheets
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetSheets(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	csr_data_pkg.T_SHEET_ID,
	out_cur					OUT	SYS_REFCURSOR
);

/**
 * GetSheetsForTree
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetSheetsForTree(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * GetSheetIds
 * 
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetSheetIds(
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * GetSheetIds
 * 
 * @param in_delegation_sid		The sid of the object
 * @param in_year				The year to match sheets on
 * @param out_cur				The rowset
 */
PROCEDURE GetSheetIds(
	in_delegation_sid	IN 	security_pkg.T_SID_ID,
	in_year				IN  number,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Creates sheets for a delegation, respecting customer.create_sheets_at_period_end
 * and always creating at least one sheet.
 *
 * @param in_delegation_sid			The delegation to create sheets for
 */
PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_send_alerts					IN	NUMBER DEFAULT 1
);

/**
 * Creates sheets for a delegation, respecting customer.create_sheets_at_period_end
 * and always creating at least one sheet.
 *
 * @param in_delegation_sid			The delegation to create sheets for
 */
PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_send_alerts					IN	NUMBER DEFAULT 1,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Creates sheets for a delegation, respecting customer.create_sheets_at_period_end
 * and always creating at least one sheet.
 *
 * @param in_delegation_sid			The delegation to create sheets for
 * @param in_at_least_one			Passing 1 will create a sheet regardless of whether the period has started
 * @param out_cur					Details of the created sheets
 */
PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_at_least_one					IN	NUMBER DEFAULT 0,
	in_send_alerts					IN	NUMBER DEFAULT 1,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Creates sheets for a delegation, respecting customer.create_sheets_at_period_end
 * and always creating at least one sheet.
 *
 * @param in_delegation_sid			The delegation to create sheets for
 * @param in_at_least_one			Passing 1 will create a sheet regardless of whether the period has started
 * @param in_date_to				The date up to which sheets are created (normally SYSDATE)
 * @param out_cur					Details of the created sheets
 */
PROCEDURE CreateSheetsForDelegation(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_at_least_one					IN	NUMBER DEFAULT 0,
	in_date_to						IN  DATE DEFAULT SYSDATE,
	in_send_alerts					IN	NUMBER DEFAULT 1,
	out_cur							OUT	SYS_REFCURSOR
);

-- Called from a scheduled job to roll forward each month and create sheets
PROCEDURE CreateNewSheets;

PROCEDURE GetDelegationSummaryReport(
	in_start_dtm	IN	delegation.start_dtm%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * Get things that are blocking the submission of this delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetDelegationBlockers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);


/**
 * Get indicators and regions in a delegation that have been trashed
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param out_cur				The rowset
 */
PROCEDURE GetTrashedItems(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);



-- =========================
-- general utility functions
-- =========================

/**
 * Check if an indicator is used in a delegation
 * Used in indicator_pkg.IsIndicatorUsed
 *
 * @param in_ind_sid				The sid of the indicator to check
 * @return							true if the indicator is used in a delegation
 */ 
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)
RETURN BOOLEAN;

 
/**
 * Returns whether the delegation has all
 * indicators and regions delegated
 * 
 * @param in_delegation_sid		The sid of the object
 * @return 						1|0 (true or false)
 */
FUNCTION IsFullyDelegated(
	in_delegation_sid	IN security_pkg.T_SID_ID
) RETURN NUMBER;



/**
 * Returns a comma separated string of region descriptions
 * 
 * @param in_delegation_sid		The sid of the object
 * @return 						String of region descriptions
 */
FUNCTION ConcatDelegationRegions(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_regions			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

/**
 * Returns a comma separated translated regions based on user's language
 * @param in_delegation_sid		The delegation sid
 * @param in_csr_user_sid		The csr_user sid
 * @param in_max_regions		Max number of region descriptions returned
 * @return 						String of region descriptions
 */
FUNCTION ConcatDelegRegionsByUserLang(
	in_delegation_sid	IN security_pkg.T_SID_ID,
	in_csr_user_sid		IN security_pkg.T_SID_ID,
	in_max_regions		IN  NUMBER DEFAULT 10
) RETURN VARCHAR2;

/**
 * Returns a comma separated string of indicator descriptions
 * 
 * @param in_delegation_sid		The sid of the object
 * @return 						String of indicator descriptions
 */
FUNCTION ConcatDelegationIndicators(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_inds				IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

/**
 * Returns a comma separated string of delegees
 * 
 * @param in_delegation_sid		The sid of the object
 * @return 						String of delegees names
 */
FUNCTION ConcatDelegationUsers(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

/**
 * Returns a comma separated string of delegees sids
 *
 * This is very handy when using in conjuction with 
 * SYS_CONNECT_BY_PATH(delegation_pkg.ConcatDelegationUserSids(delegation_sid), '/')
 * which outputs /123456+123457/123450/123453 etc
 * 
 * @param in_delegation_sid		The sid of the object
 * @return 						String of delegees names
 */
FUNCTION ConcatDelegationUserSids(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

/**
 * Returns a comma separated string of delegators
 * 
 * @param in_delegation_sid		The sid of the object
 * @return 						String of delegator names
 */
FUNCTION ConcatDelegationDelegators(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_delegators		IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

-- Used by heinekenspm and socgen.
FUNCTION ConcatDelegationUserAndEmail(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

FUNCTION ConcatDelegProviders(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

FUNCTION ConcatDelegApprovers(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2;

PROCEDURE ApplyChainToRegion(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_start_delegation_sid		IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_user_list				IN	VARCHAR2,
	in_replace_users_in_start	IN	NUMBER DEFAULT 1,
	out_cur						OUT	SYS_REFCURSOR
);

-- =======================
-- Regional sub delegation
-- =======================

/**
 * GetRegionalSubdelegState
 * 
 * @param in_delegation_sid		The sid of the object
 * @param out_result			0: not split and can't be split; 1: can be split; 2: already split
 */
PROCEDURE GetRegionalSubdelegState(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	out_result						OUT NUMBER
);

/**
 * Combine split regions in a subdelegation
 *
 * @param in_act_id				Access token
 * @param in_delegation_sid		The delegation to recombine regions in
 */
PROCEDURE CombineSubdelegation(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID
);

/**
 * DoRegionalSubdelegation
 * 
 * @param in_act_id						Access token
 * @param in_delegation_sid				The sid of the object
 * @param in_regions_list				.
 * @param in_aggregate_to_region_sid	.
 */
PROCEDURE DoRegionalSubdelegation(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_regions_list				IN	VARCHAR2,
	in_aggregate_to_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL
);




























-- ==================
-- ING specific stuff
-- ==================


/**
 * SetSectionKey
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_indicators_list	.
 * @param in_section_key		.
 */
PROCEDURE SetSectionKey(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_indicators_list		IN	VARCHAR2,
	in_section_key			IN	delegation_ind.section_key%TYPE
);

/**
 * SetSectionXML
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_section_xml		.
 */
PROCEDURE SetSectionXML(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_section_xml		IN	delegation.section_xml%TYPE
);

-- =================================================================
-- specific things for adminDeleg page (dropdown list/list contents)
-- =================================================================

-- DO NOT USE
-- Only used by C:\cvs\csr\web\site\delegation\adminDeleg.aspx.cs -- which should be phased out
/**
 * GetFullDelegationPeriods
 * 
 * @param in_act_id					Access token
 * @param in_app_sid				The sid of the Application/CSR object
 * @param out_cur					The rowset
 */
PROCEDURE GetFullDelegationPeriods(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

-- DO NOT USE
-- Only used by C:\cvs\csr\web\site\delegation\adminDeleg.aspx.cs -- which should be phased out
/**
 * GetFullDelegations
 * 
 * @param in_act_id					Access token
 * @param in_app_sid				The sid of the Application/CSR object
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param out_cur					The rowset
 */
PROCEDURE GetFullDelegations(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	sheet.end_dtm%TYPE,
	in_end_dtm						IN	sheet.start_dtm%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

-- =================================================================
-- specific things for old audit page (which we want to remove)
-- =================================================================

/**
 * AuditDelegTrail
 * 
 * @param in_act_id				Access token
 * @param in_date_from			.
 * @param in_date_to			.
 * @param in_delegation_sid		The sid of the object
 * @param in_user_from_sid		.
 * @param in_user_to_sid		.
 * @param in_sheet_action_id	.
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_top_level			.
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE AuditDelegTrail(
	in_date_from					IN	sheet.start_dtm%TYPE,
	in_date_to						IN	sheet.end_dtm%TYPE,
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_user_from_sid				IN	security_pkg.T_SID_ID,
	in_user_to_sid					IN	security_pkg.T_SID_ID,
	in_sheet_action_id				IN	sheet_action.SHEET_ACTION_ID%TYPE,
	in_top_level					IN	NUMBER,
	in_order_by 					IN 	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * AuditSheetTrail
 * 
 * @param in_act_id				Access token
 * @param in_date_from			.
 * @param in_date_to			.
 * @param in_sheet_id			.
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE AuditSheetTrail(
	in_date_from					IN	sheet.start_dtm%TYPE,
	in_date_to						IN	sheet.end_dtm%TYPE,
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_include_children				IN	NUMBER,
	in_order_by 					IN 	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * GetAllDelegationNames
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetAllDelegationNames(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);



/**
 * GetAllStatusDescription
 * 
 * @param in_act_id		Access token
 * @param out_cur		The rowset
 */
PROCEDURE GetAllStatusDescription(
	in_act_id				IN	security_pkg.T_ACT_ID,
	out_cur					OUT	SYS_REFCURSOR
);













-- *****************************************************************************************
-- LEGACY STUFF NOT YET MOVED INTO SHEET_PKG (OR WHERE NEW CODE ALREADY EXISTS IN SHEET_PKG)
-- *****************************************************************************************


/**
 * SaveAmendedValue
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				.
 * @param in_ind_sid				The sid of the object
 * @param in_region_sid				The sid of the object
 * @param in_val_number				.
 * @param in_entry_conversion_id	.
 * @param in_entry_val_number		.
 * @param in_note					.
 * @param in_reason					.
 * @param in_file_upload_sid		.
 * @param in_flag					.
 * @param out_val_id				.
 */
PROCEDURE SaveAmendedValue(
	in_act_id								IN 	security_pkg.T_ACT_ID,
	in_sheet_id							IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid							IN 	security_pkg.T_SID_ID,
	in_region_sid						IN 	security_pkg.T_SID_ID,
	in_val_number						IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number			IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note									IN	SHEET_VALUE.NOTE%TYPE,
	in_reason								IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_file_count							IN	NUMBER,
	in_flag									IN	SHEET_VALUE.FLAG%TYPE,
	out_val_id							OUT sheet_value.sheet_Value_id%TYPE
);

/**
 * Save a sheet value.  If no reason is provided and the value is not new, then
 * a rowset will be returned describing the changes to the value that require
 * explanation.
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The sheet id
 * @param in_ind_sid				The indicator
 * @param in_region_sid				The region
 * @param in_val_number				The number to save
 * @param in_entry_conversion_id	The measure conversion used
 * @param in_entry_val_number		The entered value without the measure conversion applied
 * @param in_note					The entered note
 * @param in_reason					A reason for the change
 * @param in_status					The status of the value
 * @param in_file_count				A count of file uploads
 * @param in_flag					The stupid flag thing
 * @param in_write_history			1 to write history, 0 to avoid
 * @param out_cur					A rowset containing the change details (only returned if a reason was needed but not provided)
 * @param out_val_id				The sheet_value_id of the created value
 */
PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
);

/**
 * Save a sheet value unconditionally
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The sheet id
 * @param in_ind_sid				The indicator
 * @param in_region_sid				The region
 * @param in_val_number				The number to save
 * @param in_entry_conversion_id	The measure conversion used
 * @param in_entry_val_number		The entered value without the measure conversion applied
 * @param in_note					The entered note
 * @param in_reason					A reason for the change
 * @param in_status					The status of the value
 * @param in_file_count				A count of file uploads
 * @param in_flag					The stupid flag thing
 * @param in_write_history			1 to write history, 0 to avoid (set to 1 unless you have a very good reason)
 * @param out_val_id				The sheet_value_id of the created value
 */
PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
);

/**
 * Save a sheet value unconditionally
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The sheet id
 * @param in_ind_sid				The indicator
 * @param in_region_sid				The region
 * @param in_val_number				The number to save
 * @param in_entry_conversion_id	The measure conversion used
 * @param in_entry_val_number		The entered value without the measure conversion applied
 * @param in_note					The entered note
 * @param in_reason					A reason for the change
 * @param in_status					The status of the value
 * @param in_file_count				A count of file uploads
 * @param in_flag					The stupid flag thing
 * @param in_write_history			1 to write history, 0 to avoid (set to 1 unless you have a very good reason)
 * @param in_is_na					1 if requested data is not applicable to data provider else 0
 * @param out_val_id				The sheet_value_id of the created value
 */
PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	in_is_na				IN	sheet_value.is_na%TYPE,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
);

/**
 * Save a sheet value.
 * 
 * @param in_act_id					Access token
 * @param in_sheet_id				The sheet id
 * @param in_ind_sid				The indicator
 * @param in_region_sid				The region
 * @param in_val_number				The number to save
 * @param in_entry_conversion_id	The measure conversion used
 * @param in_entry_val_number		The entered value without the measure conversion applied
 * @param in_note					The entered note
 * @param in_reason					A reason for the change
 * @param in_status					The status of the value
 * @param in_file_count				A count of file uploads
 * @param in_flag					The stupid flag thing
 * @param in_force_change_readon	Write reason
 * @param in_write_history			1 to write history, 0 to avoid
 * @param out_cur					A rowset containing the change details (only returned if a reason was needed but not provided)
 * @param out_val_id				The sheet_value_id of the created value
 */
 
PROCEDURE SaveValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_val_number			IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id	IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number		IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note					IN	SHEET_VALUE.NOTE%TYPE,
	in_reason				IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status				IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count			IN	NUMBER,
	in_flag					IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history		IN	NUMBER,
	in_force_change_reason	IN	NUMBER,
	in_no_check_permission	IN	NUMBER,
	in_is_na				IN	sheet_value.is_na%TYPE,
	out_cur					OUT	SYS_REFCURSOR,
	out_val_id				OUT	sheet_value.sheet_value_id%TYPE
);

PROCEDURE SaveValue(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_sheet_id					IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid					IN 	security_pkg.T_SID_ID,
	in_region_sid				IN 	security_pkg.T_SID_ID,
	in_val_number				IN 	SHEET_VALUE.val_number%TYPE,
	in_entry_conversion_id		IN 	SHEET_VALUE.entry_measure_conversion_id%TYPE,
	in_entry_val_number			IN 	SHEET_VALUE.entry_val_number%TYPE,
	in_note						IN	SHEET_VALUE.NOTE%TYPE,
	in_reason					IN 	SHEET_VALUE_CHANGE.REASON%TYPE,
	in_status					IN	SHEET_VALUE.STATUS%TYPE DEFAULT csr_data_pkg.SHEET_VALUE_ENTERED,
	in_file_count				IN	NUMBER,
	in_flag						IN	SHEET_VALUE.FLAG%TYPE,
	in_write_history			IN	NUMBER,
	in_force_change_reason		IN	NUMBER,
	in_no_check_permission		IN	NUMBER,
	in_is_na					IN	sheet_value.is_na%TYPE,
	in_apply_percent_ownership	IN	NUMBER DEFAULT 1,
	out_cur						OUT	SYS_REFCURSOR,
	out_val_id					OUT	sheet_value.sheet_value_id%TYPE
);

PROCEDURE SaveValue2(
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_ind_sid						IN 	ind.ind_sid%TYPE,
	in_region_sid					IN 	region.region_sid%TYPE,
	in_entry_val_number				IN 	sheet_value.entry_val_number%TYPE,
	in_entry_conversion_id			IN 	sheet_value.entry_measure_conversion_id%TYPE,
	in_note							IN	sheet_value.note%TYPE,
	in_flag							IN	sheet_value.flag%TYPE,
	in_is_na						IN	sheet_value.is_na%TYPE,
	in_var_expl_ids					IN	security_pkg.T_SID_IDS,
	in_var_expl_note				IN	sheet_value.var_expl_note%TYPE,
	out_changed_inds_cur			OUT	SYS_REFCURSOR
);

-- i can't think of a good name for this one as it's such an odd
-- collection of stuff to fetch
PROCEDURE UNSEC_GetSheetHelperInfo(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_ind_validation_rule_cur		OUT	SYS_REFCURSOR
);

PROCEDURE HideValue(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID
);

PROCEDURE UnhideValue(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR,
	out_cur_files			OUT SYS_REFCURSOR
);

-- utility procedure (do not call from your code!) which fixes up the
-- sheet_inherited_value table for a given root delegation
PROCEDURE FixSheetInheritedValues(
	in_delegation_sid	IN	security_pkg.T_SID_ID
);

-- would this value trigger any alerts?
/**
 * UpdateAlerts
 * 
 * @param in_ind_sid		The sid of the object
 * @param in_region_sid		The sid of the object
 * @param in_val_number		.
 * @param in_sheet_id		.
 */
PROCEDURE UpdateAlerts(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_val_number	IN 	VAL.val_number%TYPE,
	in_sheet_id		IN	SHEET.SHEET_ID%TYPE
);

/**
 * Get data for report on who is blocking final submissions
 * 
 * @param out_cur 			The rowset
 */
PROCEDURE GetReportDelegationBlockers(
	in_overdue_only	IN	NUMBER,
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
);

/**
 * Get data for report on Submission Promptness
 * 
 * @param out_cur 			The rowset
 */
PROCEDURE 	GetReportSubmissionPromptness(
	in_sheet_start_date			IN	DATE,
	in_sheet_end_date			IN	DATE,
	out_cur						OUT SYS_REFCURSOR
);

/**
 * Return the grid_xml for a delegation
 * TODO: Moved from inline SQL, no security
 *
 * @param in_delegation_sid	The delegation
 * @param out_cur			A rowset containing the grid_xml column
 */
PROCEDURE GetGridXML(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);



/**
*
* Search notes and attachments for a specific delegation sid
* that match the input phrase
*
* @param in_delegation_sid	The delegation
* @param in_phrase	        The phrase to search
* @param out_cur			A rowset containing the results
*/
PROCEDURE SearchAttachments(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_phrase           IN  VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
);

/**
*
* This procedure is coupled with 'SearchAttachments' to enable search and
* download file attachments of a delegation. Therefore anyone who
* has permission to search attachments has also the permission
* to download them.
*
* @param in_file_upload_sid		The file sid
* @param out_cur				A rowset containing the results
 */
PROCEDURE GetDownloadData(
	in_file_upload_sid	IN	file_upload.file_upload_sid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Check permission on the delegation, then return the details of the
 * given ind/region (and check that the delegation contains the ind/region)
 *
 * This is because we don't want to check permissions on the ind/region
 * objects themselves -- the user can be delegated inds/regions that
 * they do not have permission on.
 *
 * @param in_delegation_sid			The delegation
 * @param in_ind_sid				The indicator to fetch
 * @param in_region_sid				The region to fetch
 * @param out_ind_cur				Indicator details
 * @param out_region_cur			Region details
 */
PROCEDURE GetQuickChartIndRegionDetail(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_ind_sid						IN	delegation_ind.ind_sid%TYPE,
	in_region_sid					IN	delegation_region.region_sid%TYPE,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMergedValueCount(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_merged				OUT	NUMBER
);


PROCEDURE TerminateAndDelete(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
);


PROCEDURE Flip(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
);

/**
 * Fetch alerts to send for terminated delegations
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetTerminatedAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record that a terminated delegation alert has been sent
 *
 * @param in_deleg_terminated_alert_id	The alert details
 */
PROCEDURE RecordTerminatedAlertSent(
	in_deleg_terminated_alert_id	IN delegation_terminated_alert.deleg_terminated_alert_id%TYPE
);

/**
 * Fetch alerts to send for new delegations
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetNewAlerts(
	out_cur							OUT	SYS_REFCURSOR
);
PROCEDURE GetNewAlerts(
	in_alert_pivot_dtm				IN DATE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record that a new delegation alert has been sent
 *
 * @param in_new_delegation_alert_id	The alert details
 */
PROCEDURE RecordNewAlertSent(
	in_alert_id		IN	new_delegation_alert.new_delegation_alert_id%TYPE
);

/**
 * Fetch alerts to send for new planned delegations
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetNewPlannedAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record that a new planned delegation alert has been sent
 *
 * @param in_new_delegation_alert_id	The alert details
 */
PROCEDURE RecordNewPlannedAlertSent(
	in_alert_id		IN	new_planned_deleg_alert.new_planned_deleg_alert_id%TYPE
);

/**
 * Fetch alerts to send for updated delegations
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetUpdatedPlannedAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record that an updated planned delegation alert has been sent
 *
 * @param in_updated_deleg_alert_id	The alert details
 */
PROCEDURE RecordUpdatedPlannedAlertSent(
	in_alert_id		IN	updated_planned_deleg_alert.updated_planned_deleg_alert_id%TYPE
);

/**
 * Fetch alerts to send for changed delegations
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetStateChangeAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Fetch alerts to send for changed delegations using the batched alert
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetStateChangeAlertsBatched(
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Record that a delegation state change alert has been sent
 *
 * @param in_delegation_change_alert_id	The alert details
 */
PROCEDURE RecordStateChangeAlertSent(
	in_delegation_change_alert_id	IN	delegation_change_alert.delegation_change_alert_id%TYPE
);

/**
 * Fetch alerts to send for data changed delegations by other than deleg user
 *
 * @param out_cur					The alert details
 */
PROCEDURE GetDataChangeAlerts(
	out_cur							OUT	SYS_REFCURSOR
);

/** 
 *  Aggregates translated region descriptions into a delimited string.
 *  @param  in_delegation_sid       The sid of the delegation to get region descriptions for.
 *  @param  in_separator            The separator to use. If ommited, region names are delimited by 
 *                                  commas.
 *  @param  in_list_threshold       The maximum number of regions names to attempt to aggregate. If 
 *                                  the region count exceeds this value a null value is returned. 
 *                                  For consistent results the default value should match the C# constant
 *                                  Credit360.ScheduledTasks.Delegations.ProcessJobs.MaxRegionNames
 */
FUNCTION FormatRegionNames(
	in_delegation_sid           delegation.delegation_sid%TYPE,
    in_separator                VARCHAR2 DEFAULT ', ',
    in_list_threshold           NUMBER DEFAULT 10
) RETURN VARCHAR2;

/**
 * Record that a data changed alert has been sent
 *
 * @param in_delegation_change_alert_id	The alert details
 */
PROCEDURE RecordDataChangeAlertSent(
	in_deleg_data_change_alert_id	IN	deleg_data_change_alert.deleg_data_change_alert_id%TYPE,
	out_deleted_count				OUT number
);

PROCEDURE GetSheetChangeReqAlerts(
	out_cur							OUT	SYS_REFCURSOR
);
PROCEDURE GetSheetChangeReqApprAlerts(
	out_cur							OUT	SYS_REFCURSOR
);
PROCEDURE GetSheetChangeReqRejAlerts(
	out_cur							OUT	SYS_REFCURSOR
);
PROCEDURE RecordSheetChangeReqAlertSent(
	in_sheet_change_req_alert_id	IN	sheet_change_req_alert.sheet_change_req_alert_id%TYPE,
	out_deleted_count				OUT number
);

/**
 * Create an indicator that represents a CMS form, or make an existing indicator
 * into one
 * 
 * @param in_name					The SO name of the indicator
 * @param in_description			The indicator description
 * @param in_path					The path to the grid xml
 * @param in_aggregation_xml		XML to aggregate the grid into normal indicators
 * @param in_variance_validation_sp	Logging for variance validation stored procedure to use
 */
PROCEDURE CreateGridIndicator(
	in_name							IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_path							IN	VARCHAR2,
	in_aggregation_xml				IN	delegation_grid.aggregation_xml%TYPE DEFAULT NULL,
	in_variance_validation_sp		IN	delegation_grid.variance_validation_sp%TYPE DEFAULT NULL
);

/**
 * Create an indicator that represents a CMS form, or make an existing indicator
 * into one
 * 
 * @param in_name					The SO name of the indicator
 * @param in_description			The indicator description
 * @param in_path					The path to the grid xml
 * @param in_form_sid				The form sid of an uploaded form
 * @param in_aggregation_xml		XML to aggregate the grid into normal indicators
 * @param in_variance_validation_sp	Logging for variance validation stored procedure to use
 */
PROCEDURE CreateGridIndicator(
	in_name							IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_path							IN	VARCHAR2,
	in_form_sid						IN	NUMBER,
	in_aggregation_xml				IN	delegation_grid.aggregation_xml%TYPE DEFAULT NULL,
	in_variance_validation_sp		IN	delegation_grid.variance_validation_sp%TYPE DEFAULT NULL
);

/**
 * Set the aggregation xml for an indicator that represents a CMS form
 * 
 * @param in_ind_sid				The indicator to set the aggregation xml for
 * @param in_aggregation_xml		XML to aggregate the grid into normal indicators
 */
PROCEDURE SetGridIndAggregationXml(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_aggregation_xml				IN	VARCHAR2
);

/**
 * Set the aggregation xml for an indicator that represents a CMS form
 * 
 * @param in_ind_sid				The indicator to set the aggregation xml for
 * @param in_aggregation_xml		XML to aggregate the grid into normal indicators
 */
PROCEDURE SetGridIndAggregationXml(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_aggregation_xml				IN	delegation_grid.aggregation_xml%TYPE DEFAULT NULL
);

/**
 * Create an indicator that represents a plugin for other modules, or make an existing indicator
 * into one
 * 
 * @param in_name					The SO name of the indicator
 * @param in_description			The indicator description
 * @param in_js_class_type			The type of javascript object to use
 * @param in_js_include				The path of the javascript file which contains the object
 */
PROCEDURE CreatePluginIndicator(
	in_name							IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_js_class_type				IN	VARCHAR2,
	in_js_include					IN	VARCHAR2
);

PROCEDURE GetCoverage(
	out_cur		OUT		SYS_REFCURSOR
);

FUNCTION HasIncompleteChild(
	in_sheet_id			IN	sheet.sheet_id%TYPE
) RETURN NUMBER;

/**
 * Get indicator translations for the given delegation
 *
 * @param in_delegation_sid			The delegation
 * @param out_cur					Translations of the delegation indicators
 */
PROCEDURE GetIndicatorTranslations(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get region translations for the given delegation
 *
 * @param in_delegation_sid			The delegation
 * @param out_cur					Translations of the delegation regions
 */
PROCEDURE GetRegionTranslations(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE ReplaceDelegationInds(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_old_ind_sids		IN	security_pkg.T_SID_IDS,
	in_new_ind_sids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SetSheetVisibility(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_is_visible					IN  NUMBER,
	out_affected					OUT	NUMBER
);

PROCEDURE SetSheetReadOnly(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_is_read_only					IN  NUMBER,
	out_affected					OUT	NUMBER
);

PROCEDURE SetSheetResendAlerts(
	in_delegation_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_level						IN	NUMBER,
	in_resend_reminder				IN	NUMBER DEFAULT 0,
	in_resend_overdue				IN	NUMBER DEFAULT 0,
	out_affected					OUT	NUMBER
);

PROCEDURE GetSubdelegChainUsers(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_user_cur					OUT	SYS_REFCURSOR
);

/**
 * Sets which indicators are used in this delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_indicators_list	.
 * @param in_mandatory_list		.
 * @param in_propagate_down		.
 * @param in_allowed_na_list	Comma separated list of indicators allowed to be n/a
 */
PROCEDURE SetIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_indicators_list		IN	VARCHAR2,
	in_mandatory_list		IN	VARCHAR2,
	in_propagate_down		IN	NUMBER DEFAULT 1,
	in_allowed_na_list		IN	VARCHAR2
);

/**
 * Sets which regions are used in this delegation
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_regions_list		.
 * @param in_mandatory_list		.
 * @param in_allowed_na_list	Comma separated list of regions allowed to be n/a
 */
PROCEDURE SetRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_regions_list		IN	VARCHAR2,
	in_mandatory_list	IN	VARCHAR2,
	in_allowed_na_list	IN	VARCHAR2
);

/**
 * Get information about specific indicators (delegations can 
 * rename indicators)
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_indicator_list		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_indicator_list	IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Get information about specific regions (delegations can 
 * rename regions)
 * 
 * @param in_act_id				Access token
 * @param in_delegation_sid		The sid of the object
 * @param in_region_list		.
 * @param out_cur				The rowset
 */
PROCEDURE GetRegionsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_region_list		IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION GetChildrenCount(
	in_delegation_sid	IN	security.security_pkg.T_SID_ID
) RETURN NUMBER;

/*
	FB39329: counts the number of data items that were merged
	from the specified delegation or any of its sub-delegations.
	in_item_sids is a comma-separated list of SIDs to filter the
	data items of interest - these should represent indicator SIDs
	if in_use_ind = 1 or region SIDs if in_use_ind = 0.
*/ 
FUNCTION CountMergedDataValues(
	in_top_level_del_sid		IN	delegation.delegation_sid%TYPE,
	in_item_sids				IN	VARCHAR2,
	in_use_ind					IN	NUMBER
) RETURN NUMBER;

-- Get indicators with pending explanations for region.
PROCEDURE GetGridVarianceInds(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetPendingVariances(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,	-- <- used just for permissions check...
	in_root_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_region_sid			IN	region.region_sid%TYPE,
	in_start_dtm			IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm				IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid			IN	ind.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetVariances(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,		-- <- used for permissions check.
	in_root_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_region_sid			IN	region.region_sid%TYPE,
	in_start_dtm			IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm				IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid			IN	ind.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

-- This basically:
-- Runs grid variance validation SP (delegation_grid.variance_validation_sp),
-- inserts rows returned into deleg_grid_variance, updates any that already
-- exist and marks existing rows (in deleg_grid_variance) as inactive if they
-- weren't returned in the variance validation SP.
PROCEDURE UpsertVariances(
	in_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_root_deleg_sid	IN	deleg_grid_variance.root_delegation_sid%TYPE,
	in_region_sid		IN	deleg_grid_variance.region_sid%TYPE,
	in_start_dtm		IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm			IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid		IN	ind.ind_sid%TYPE
);

PROCEDURE SaveVarianceExplanation(
	in_id				IN	deleg_grid_variance.id%TYPE,
	in_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_root_deleg_sid	IN	deleg_grid_variance.root_delegation_sid%TYPE,
	in_region_sid		IN	region.region_sid%TYPE,
	in_start_dtm		IN	deleg_grid_variance.start_dtm%TYPE,
	in_end_dtm			IN	deleg_grid_variance.end_dtm%TYPE,
	in_grid_ind_sid		IN	ind.ind_sid%TYPE,
	in_explanation		IN	deleg_grid_variance.explanation%TYPE
);

PROCEDURE CreateLayoutTemplate(
    in_xml              IN	delegation_layout.layout_xhtml%TYPE,
    in_name             IN  delegation_layout.name%TYPE DEFAULT NULL,
    out_id				OUT	delegation_layout.layout_id%TYPE
);

PROCEDURE UpdateLayoutTemplate(
    in_id				IN	delegation_layout.layout_id%TYPE,
    in_xml              IN	delegation_layout.layout_xhtml%TYPE,
    in_name             IN  delegation_layout.name%TYPE DEFAULT NULL,
	in_valid			IN	delegation_layout.valid%TYPE DEFAULT 0
);

PROCEDURE GetLayoutTemplate(
    in_id				IN	delegation_layout.layout_id%TYPE,
    out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE SetLayoutTemplate(
	in_delegation_sid	IN	delegation.delegation_sid%TYPE,
	in_layout_id		IN	delegation_layout.layout_id%TYPE
);

PROCEDURE GetLayoutDelegationSids(
	in_layout_id		IN	delegation_layout.layout_id%TYPE,
    out_cur 			OUT SYS_REFCURSOR
);

-- Procedures for creating and reading batch jobs for
-- calculating delegation completeness

-- This creates a new Delegation Completeness calculation batch job, and puts it on the queue.
PROCEDURE SetBatchJob(
	in_delegation_sid	IN	batch_job_delegation_comp.delegation_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
);

-- This gets a Delegation Completeness calculation batch job by id.
PROCEDURE GetBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

-- Indicates whether the Delegation Completeness data is currently up-to-date
-- i.e. no calculations pending or in-progress
PROCEDURE IsCompletenessUpToDate(
	in_delegation_sids	IN	VARCHAR2,
	out_up_to_date		OUT	NUMBER
);

-- return the roles that a user is in for regions in the given delegation
PROCEDURE GetUserRolesForDelegRegions(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetIndRegionMatrixTags(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION IsCellVisibleInTagMatrix(
	in_sheet_id			IN	NUMBER,
	in_region_sid		IN	NUMBER,
	in_ind_sid			IN 	NUMBER
) RETURN NUMBER;

PROCEDURE GetDelegsForGridReg (
	in_region_sid			IN	region.region_sid%TYPE,
	in_grid_ind_sid			IN	delegation_grid.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllTranslations(
	in_region_sids			IN 	security_pkg.T_SID_IDS,
	in_ind_sids				IN 	security_pkg.T_SID_IDS,
	in_validation_lang		IN	delegation_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTranslations(
	in_delegation_sids		IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	delegation_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SheetsWithSkippedAlerts(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	out_num_sheets_skipped_alerts	OUT	NUMBER
);

PROCEDURE GetGridIndSidFromPath(
	in_path				IN	csr.delegation_grid.path%TYPE,
	out_ind_sid			OUT	csr.delegation_grid.ind_sid%TYPE
);

PROCEDURE GetObjectCountsForSheet(
	in_sheet_id				IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

END;
/
