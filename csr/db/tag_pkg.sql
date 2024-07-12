CREATE OR REPLACE PACKAGE CSR.tag_Pkg
AS

PROCEDURE DeleteTagGroup(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_tag_group_id		IN tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_name							IN  tag_group_description.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroupByName(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_name							IN	tag_group_description.name%TYPE,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE,
	in_excel_import					IN	NUMBER,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_name							IN  tag_group_description.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE DEFAULT 0,
	in_mandatory					IN	tag_group.mandatory%TYPE DEFAULT 0,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_excel_import					IN  NUMBER DEFAULT 0,
	in_lookup_key					IN	tag_group.lookup_key%TYPE DEFAULT NULL,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
);

PROCEDURE CreateTagGroup(
	in_act_id						IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_name							IN  tag_group_description.name%TYPE,
	in_multi_select					IN	tag_group.multi_select%TYPE DEFAULT 0,
	in_mandatory					IN	tag_group.mandatory%TYPE DEFAULT 0,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_excel_import					IN  NUMBER DEFAULT 0,
	in_lookup_key					IN	tag_group.lookup_key%TYPE DEFAULT NULL,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
);

PROCEDURE SetTagGroupRegionTypes(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_region_type_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupNCTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_nc_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupIATypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_ia_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupInitiativeTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_init_type_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupCompanyTypes(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_company_type_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTagGroupDescription(
	in_tag_group_id					IN	tag_group_description.tag_group_id%TYPE,
	in_langs						IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_descriptions					IN	security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetTagGroupDescription(
	in_tag_group_id					IN	tag_group_description.tag_group_id%TYPE,
	in_lang							IN	tag_group_description.lang%TYPE,
	in_description					IN	tag_group_description.name%TYPE
);

-- update or insert tag 
/**
 * SetTag
 * 
 * @param in_act_id				Access token
 * @param in_tag_group_id		.
 * @param in_tag_id				.
 * @param in_tag				.
 * @param in_explanation		.
 * @param in_pos				.
 * @param in_parent_id			.
 * @param out_tag_id			.
 */
PROCEDURE SetTag(
	in_act_id				IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE						DEFAULT NULL,
	in_tag					IN	tag_description.tag%TYPE,
	in_explanation			IN	tag_description.explanation%TYPE	DEFAULT NULL,
	in_pos					IN	tag_group_member.pos%TYPE			DEFAULT NULL,
	in_lookup_key			IN	tag.lookup_key%TYPE					DEFAULT NULL,
	in_parent_id			IN	tag.parent_id%TYPE					DEFAULT NULL,
	in_parent_lookup_key	IN	VARCHAR2							DEFAULT NULL,
	out_tag_id				OUT	tag.tag_id%TYPE
);
PROCEDURE SetTag(
	in_act_id				IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE						DEFAULT NULL,
	in_tag					IN	tag_description.tag%TYPE,
	in_explanation			IN	tag_description.explanation%TYPE	DEFAULT NULL,
	in_pos					IN	tag_group_member.pos%TYPE			DEFAULT NULL,
	in_lookup_key			IN	tag.lookup_key%TYPE					DEFAULT NULL,
	in_active				IN	tag_group_member.active%TYPE,
	in_parent_id			IN	tag.parent_id%TYPE					DEFAULT NULL,
	in_parent_lookup_key	IN	VARCHAR2							DEFAULT NULL,
	out_tag_id				OUT	tag.tag_id%TYPE
);

PROCEDURE SetTagDescription(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_langs						IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_descriptions					IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_explanations					IN	security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetTagDescription(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_lang							IN	tag_description.lang%TYPE,
	in_description					IN	tag_description.tag%TYPE,
	in_explanation					IN	tag_description.explanation%TYPE,
	in_set_tag						IN  NUMBER DEFAULT 1,
	in_set_explanation				IN  NUMBER DEFAULT 1
);

PROCEDURE SetTagDescriptionTag(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_lang							IN	tag_description.lang%TYPE,
	in_description					IN	tag_description.tag%TYPE
);

PROCEDURE SetTagDescriptionExplanation(
	in_tag_id						IN	tag_description.tag_id%TYPE,
	in_lang							IN	tag_description.lang%TYPE,
	in_description					IN	tag_description.explanation%TYPE
);


/**
 * Useful for quickly importing things from Excel since it
 * takes names not ids, and will automatically create things
 * that don't exist.
 */
PROCEDURE SetIndicatorTag(
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_name	IN	tag_group_description.name%TYPE,
	in_tag				IN	tag_description.tag%TYPE
);

PROCEDURE INTERNAL_AddCalcJobs(
	in_tag_id		tag.tag_id%TYPE
);

PROCEDURE SetRegionTag(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_group_name	IN	tag_group_description.name%TYPE,
	in_tag				IN	tag_description.tag%TYPE
);

PROCEDURE UNSEC_SetRegionTag(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_id			IN 	tag.tag_id%TYPE
);

PROCEDURE SetNonComplianceTag(
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_group_name		IN	tag_group_description.name%TYPE,
	in_tag					IN	tag_description.tag%TYPE
);

/**
 * Sort tag group members alphabetically - useful if you
 * import a load of things with SetIndicatorTag from Excel
 */
PROCEDURE SortTagGroupMembers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE
);

/**
 * RemoveTagFromGroup
 * 
 * @param in_act_id				Access token
 * @param in_tag_group_id		.
 * @param in_tag_id				.
 */
PROCEDURE RemoveTagFromGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE
);


PROCEDURE GetIndTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMultipleIndTags(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetIndTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_set_tag_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE RemoveIndicatorTag(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tag_id			IN	NUMBER,
	out_rows_updated	OUT	NUMBER
);

PROCEDURE RemoveIndicatorTagGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id		IN	NUMBER,
	out_rows_updated	OUT	NUMBER
);


PROCEDURE GetRegionTags(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetMultipleRegionTags(
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetRegionTags(
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_tags_cur					OUT	SYS_REFCURSOR
);

/**
 * SetRegionTags
 * 
 * @param in_act_id			Access token
 * @param in_region_sid		The sid of the object
 * @param in_tag_ids		.
 */
PROCEDURE SetRegionTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	VARCHAR2
);


PROCEDURE SetRegionTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
);

PROCEDURE RemoveRegionTag(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_tag_id				IN	NUMBER,
	in_apply_dynamic_plans	IN	NUMBER DEFAULT 1,
	out_rows_updated		OUT	NUMBER
);

PROCEDURE RemoveRegionTagGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN	NUMBER,
	in_apply_dynamic_plans	IN	NUMBER DEFAULT 1,
	out_rows_updated		OUT	NUMBER
);

PROCEDURE GetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_ids				IN	VARCHAR2
);


PROCEDURE SetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_ids				IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
);

PROCEDURE UNSEC_SetNonComplianceTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_non_compliance_id	IN	non_compliance.non_compliance_id%TYPE,
	in_tag_ids				IN	security_pkg.T_SID_IDS -- they're not sids, but it'll do
);

-- returns the Projects and tag groups this user can see 
/**
 * GetTagGroups
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetTagGroups(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);
-- and the translations
/**
 * GetTagGroupDescriptions
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_tag_group_id		Optional filter
 * @param out_cur				The rowset
 */
PROCEDURE GetTagGroupDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetTagGroupDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);


/**
* Get recursive tag groups to support CDP
*/	
PROCEDURE GetAllTagGroups (
	out_tag_group_cur		OUT	SYS_REFCURSOR,
	out_tag_group_text_cur	OUT	SYS_REFCURSOR,
	out_tag_cur				OUT	SYS_REFCURSOR,
	out_tag_text_cur		OUT	SYS_REFCURSOR,
	out_region_types_cur	OUT	SYS_REFCURSOR,
	out_audit_types_cur		OUT	SYS_REFCURSOR,
	out_company_types_cur	OUT	SYS_REFCURSOR,
	out_non_compl_types_cur	OUT	SYS_REFCURSOR
);


PROCEDURE GetTagGroup(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_name			IN	tag_group_description.name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

-- returns basic details of specified tag_group 
/**
 * GetTagGroup
 * 
 * @param in_act_id				Access token
 * @param in_tag_group_id		.
 * @param out_cur				The rowset
 */
PROCEDURE GetTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id				IN	tag_group.tag_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);
	


/**
 * GetTagGroupMembers
 * 
 * @param in_act_id				Access token
 * @param in_tag_group_id		.
 * @param out_cur				The rowset
 */
PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_tag_group_id				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * GetTagGroupMembersByGroupLookup
 * 
 * @param in_tag_group_lookup		Lookup key of a tag group
 * @param out_tg_members			The rowset of tag group members
 */
PROCEDURE GetTagGroupMembersByGroupLookup(
	in_tag_group_lookup			IN	tag_group.lookup_key%TYPE,
	out_tg_members				OUT	security_pkg.T_OUTPUT_CUR
);

-- and the translations
/**
 * GetTagGroupMemberDescriptions
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param in_tag_group_id		Optional filter
 * @param out_cur				The rowset
 */
PROCEDURE GetTagGroupMemberDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetTagGroupMemberDescriptions(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT'),
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);



/**
 * GetAllTagGroupsAndMembers
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetAllTagGroupsAndMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetAllTagGroupsAndMembersInd(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllTagGroupsAndMembersReg(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * ConcatTagGroupMembers
 * 
 * @param in_tag_group_id		.
 * @param in_max_length			.
 * @return 						.
 */
FUNCTION ConcatTagGroupMembers(
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	in_max_length		IN 	INTEGER
) RETURN VARCHAR2;


/**
 * GetTagGroupsSummary
 * 
 * @param in_act_id				Access token
 * @param in_app_sid			The sid of the Application/CSR object
 * @param out_cur				The rowset
 */
PROCEDURE GetTagGroupsSummary(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetTagGroupRegionMembers(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupIndMembers(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroupNCMembers(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

/* for internal use only */
PROCEDURE INTERNAL_TryCreateTag(
	in_tag_group_name				IN	tag_group_description.name%TYPE,
	in_tag							IN	tag_description.tag%TYPE,
	in_applies_to_inds				IN	tag_group.applies_to_inds%TYPE DEFAULT 0,
	in_applies_to_regions			IN	tag_group.applies_to_regions%TYPE DEFAULT 0,
	in_applies_to_non_comp			IN	tag_group.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_suppliers			IN	tag_group.applies_to_suppliers%TYPE DEFAULT 0,
	in_applies_to_chain				IN	tag_group.applies_to_chain%TYPE DEFAULT 0,
	in_applies_to_chain_activities	IN	tag_group.applies_to_chain_activities%TYPE DEFAULT 0,
	in_applies_to_initiatives		IN	tag_group.applies_to_initiatives%TYPE DEFAULT 0,
	in_applies_to_chain_prod_types	IN	tag_group.applies_to_chain_product_types%TYPE DEFAULT 0,
	in_applies_to_chain_products	IN	tag_group.applies_to_chain_products%TYPE DEFAULT 0,
	in_applies_to_chain_prod_supps	IN	tag_group.applies_to_chain_product_supps%TYPE DEFAULT 0,
	in_applies_to_quick_survey		IN	tag_group.applies_to_quick_survey%TYPE DEFAULT 0,
	in_applies_to_audits			IN	tag_group.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_compliances		IN	tag_group.applies_to_compliances%TYPE DEFAULT 0,
	in_is_hierarchical				IN	tag_group.is_hierarchical%TYPE DEFAULT 0,
	out_tag_id						OUT	tag.tag_id%TYPE
);

PROCEDURE DeactivateTag(
	in_tag_id				IN	tag.tag_id%TYPE,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE
);

PROCEDURE ActivateTag(
	in_tag_id				IN	tag.tag_id%TYPE,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE
);

PROCEDURE SetRegionTagsFast(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetTag(
	in_tag_id						IN	tag.tag_id%TYPE,
	out_tag_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroupRegionTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroupInternalAuditTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroupNCTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroupCompanyTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroupInitiativeTypes(
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllCatTranslations(
	in_validation_lang		IN	tag_group_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateCatTranslations(
	in_tag_group_ids		IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	tag_group_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllTagTranslations(
	in_validation_lang		IN	tag_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllTagExplTranslations(
	in_validation_lang		IN	tag_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTagTranslations(
	in_tag_ids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	tag_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTagExplTranslations(
	in_tag_ids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	tag_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTagGroups(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_tag_group_cur				OUT	SYS_REFCURSOR,
	out_tag_group_tr_cur			OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_tag_tr_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetTagFromLookup(
	in_lookup_key		IN	csr.tag.lookup_key%TYPE,
	out_tag_id			OUT	csr.tag.tag_id%TYPE
);

PROCEDURE UNSEC_GetTagFromLookup(
	in_lookup_key		IN	csr.tag.lookup_key%TYPE,
	out_tag_id			OUT	csr.tag.tag_id%TYPE
);

PROCEDURE GetTagFromName(
	in_tag_name			IN	csr.tag_description.tag%TYPE,
	in_lang				IN	csr.tag_description.lang%TYPE := 'en',
	out_tag_id			OUT	csr.tag.tag_id%TYPE
);

PROCEDURE UNSEC_GetTagFromName(
	in_tag_name			IN	csr.tag_description.tag%TYPE,
	in_lang				IN	csr.tag_description.lang%TYPE := 'en',
	out_tag_id			OUT	csr.tag.tag_id%TYPE
);

END tag_Pkg;
/
