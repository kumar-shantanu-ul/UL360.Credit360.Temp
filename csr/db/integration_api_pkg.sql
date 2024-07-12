CREATE OR REPLACE PACKAGE csr.integration_api_pkg AS

-- Oracle SQLCODEs
ERR_DUP_VAL_ON_INDEX CONSTANT NUMBER := -1;
ERR_NO_DATA_FOUND CONSTANT NUMBER := 100;
ERR_INTEGRITY_CONSTRAINT CONSTANT NUMBER := -2291;

-- Bespoke errors
ERR_FAILED_VALIDATION CONSTANT NUMBER := -20901;
FAILED_VALIDATION EXCEPTION;
PRAGMA EXCEPTION_INIT(FAILED_VALIDATION, -20901);

-- LANGUAGE CONTROLLER

PROCEDURE GetApplicationLanguages(
	out_cur				OUT	SYS_REFCURSOR
);

-- END LANGUAGE CONTROLLER

-- COMPANY USER CONTROLLER

PROCEDURE GetCompanyUsers(
	in_company_sid				IN	NUMBER,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_user_companies_cur		OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCompanyUsers(
	in_company_sid				IN	NUMBER,
	in_user_sids				IN	security.T_SID_TABLE,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_user_companies_cur		OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetCompanyUser(
	in_user_sid					IN	NUMBER,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_user_companies_cur		OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR
);

PROCEDURE CreateCompanyUser(
	in_company_sid			IN	NUMBER,
	in_is_company_admin		IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER,
	out_new_user_sid		OUT	NUMBER
);

PROCEDURE CreateCompanyUser(
	in_company_sid			IN	NUMBER,
	in_is_company_admin		IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE,
	out_new_user_sid		OUT	NUMBER
);

PROCEDURE AddUserToCompany(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER,
	in_is_company_admin		IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS
);

PROCEDURE MakeUserCompanyAdmin(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER
);

FUNCTION TryRemoveUserFromCompanyAdmin(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER
)RETURN NUMBER;

/* Leaving it for compatibilty reasons/ until the api.integrations stops using it */
PROCEDURE RemoveUserFromCompanyAdmin(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER
);

PROCEDURE RemoveUserFromCompanyTypeRoles(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS
);

PROCEDURE AddUserToCompanyTypeRoles(
	in_user_sid				IN	NUMBER,
	in_company_sid			IN	NUMBER,
	in_company_type_roles	IN	security_pkg.T_SID_IDS
);

PROCEDURE UpdateCompanyUser(
	in_user_sid				IN	NUMBER,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER
);

PROCEDURE UpdateCompanyUser(
	in_user_sid				IN	NUMBER,
	in_full_name			IN	csr.csr_user.full_name%TYPE,
	in_friendly_name		IN	csr.csr_user.friendly_name%TYPE,
	in_email				IN	csr.csr_user.email%TYPE,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_phone_number			IN	csr.csr_user.phone_number%TYPE, 
	in_job_title			IN	csr.csr_user.job_title%TYPE,
	in_is_active			IN	NUMBER,
	in_send_alerts			IN	NUMBER,
	in_language				IN	security.user_table.language%TYPE,
	in_culture				IN	security.user_table.culture%TYPE,
	in_timezone				IN	security.user_table.timezone%TYPE
);

PROCEDURE RemoveUserFromCompanies(
	in_user_sid				IN	NUMBER,
	in_company_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteCompanyUser(
	in_user_sid				IN	NUMBER
);

-- END COMPANY USER CONTROLLER

-- COMPANY

PROCEDURE GetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_refs_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_scth_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanies(
	in_skip					IN	NUMBER	DEFAULT 0,
	in_take					IN	NUMBER	DEFAULT 20,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_refs_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_scth_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateSubCompany(
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	chain.company.name%TYPE,
	in_country_code			IN	chain.company.country_code%TYPE,
	in_company_type_id		IN	chain.company_type.company_type_id%TYPE,
	in_sector_id			IN  chain.company.sector_id%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE CreateUniqueCompany(
	in_name					IN  chain.company.name%TYPE,
	in_country_code			IN  chain.company.country_code%TYPE,
	in_company_type_id		IN  chain.company_type.company_type_id%TYPE,
	in_sector_id			IN  chain.company.sector_id%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_name					IN  chain.company.name%TYPE,
	in_country_code			IN  chain.company.country_code%TYPE,
	in_address_1			IN  chain.company.address_1%TYPE,
	in_address_2			IN  chain.company.address_2%TYPE,
	in_address_3			IN  chain.company.address_3%TYPE,
	in_address_4			IN  chain.company.address_4%TYPE,
	in_city					IN  chain.company.city%TYPE,
	in_state				IN  chain.company.state%TYPE,
	in_postcode				IN  chain.company.postcode%TYPE,
	in_latitude				IN  region.geo_latitude%TYPE,
	in_longitude			IN  region.geo_longitude%TYPE,
	in_phone				IN  chain.company.phone%TYPE,
	in_fax					IN  chain.company.fax%TYPE,
	in_website				IN  chain.company.website%TYPE,
	in_email				IN  chain.company.email%TYPE,
	in_sector_id			IN  chain.company.sector_id%TYPE,
	in_reference_ids		IN	security_pkg.T_SID_IDS,
	in_values				IN	chain.chain_pkg.T_STRINGS
);

PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetCompanyTags(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_tag_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetCompanyScoreThreshold(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	quick_survey_submission.score_threshold_id%TYPE
);

PROCEDURE DeleteCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE GetRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE StartRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship(
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID
);

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID;

-- END COMPANY

-- TAG GROUP
PROCEDURE GetTagGroups(
	in_skip					IN	NUMBER	DEFAULT 0,
	in_take					IN	NUMBER	DEFAULT 20,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_descriptions_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_tag_descriptions_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTagGroup(
	in_tag_group_id				IN	tag_group.tag_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_descriptions_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tag_descriptions_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpsertTagGroup(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_name							IN	tag_group_description.name%TYPE,
	in_mandatory					IN	tag_group.mandatory%TYPE DEFAULT 0,
	in_multi_select					IN	tag_group.multi_select%TYPE DEFAULT 0,
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
	in_lookup_key					IN	tag_group.lookup_key%TYPE DEFAULT NULL,
	out_tag_group_id				OUT	tag_group.tag_group_id%TYPE
);

PROCEDURE UpsertTagGroupDescription(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_name							IN	tag_group_description.name%TYPE,
	in_lang							IN	tag_group_description.lang%TYPE
);

PROCEDURE UpsertTag(
	in_tag_group_id				IN	tag_group_member.tag_group_id%TYPE,
	in_tag_id					IN	tag.tag_id%TYPE DEFAULT NULL,
	in_tag						IN	tag_description.tag%TYPE,
	in_explanation				IN	tag_description.explanation%TYPE DEFAULT NULL,
	in_lookup_key				IN	tag.lookup_key%TYPE DEFAULT NULL,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_active					IN	tag_group_member.active%TYPE DEFAULT 0,
	out_tag_id					OUT	tag.tag_id%TYPE
);

PROCEDURE UpsertTagDescription(
	in_tag_id					IN	tag.tag_id%TYPE,
	in_tag						IN	tag_description.tag%TYPE,
	in_explanation				IN	tag_description.explanation%TYPE DEFAULT NULL,
	in_lang						IN	tag_description.lang%TYPE
);



-- END TAG GROUP

END;
/
