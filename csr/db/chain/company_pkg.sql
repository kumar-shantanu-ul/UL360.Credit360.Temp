CREATE OR REPLACE PACKAGE  CHAIN.company_pkg
IS
-- this is used to override the capability checks in a few key place as it doesn't really fit in the normal capability structure (or it would be messy)
FUNCTION CanSeeCompanyAsChainTrnsprnt (
	in_company_sid			IN  company.company_sid%TYPE
) RETURN BOOLEAN;

/************************************************************
	SYS_CONTEXT handlers
************************************************************/

FUNCTION TrySetCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN number;

PROCEDURE SetCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE SetCompany(
	in_name						IN  security_pkg.T_SO_NAME
);

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID;

FUNCTION GetCompanyFilterSid
RETURN security_pkg.T_SID_ID;


/************************************************************
	Securable object handlers
************************************************************/
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

/************************************************************
	Company Management Handlers
************************************************************/
-- this can be used to trigger a verification of each company's so structure during updates
PROCEDURE VerifySOStructure;

PROCEDURE GetUniqueReferenceConflicts(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_country_code			IN	company.country_code%TYPE,
	in_company_type_id		IN	company_type.company_type_id%TYPE,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS,
	out_lookup_keys		   OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUniqueReferenceConflicts(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS,
	out_lookup_keys		   OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateCompanyNoLink(
	in_name					IN company.name%TYPE,	
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_lookup_keys			IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels
	in_is_pending			IN NUMBER DEFAULT 0,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE CreateCompany(	
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_company_type_id		IN  company_type.company_type_id%TYPE DEFAULT NULL,
	in_sector_id			IN  company.sector_id%TYPE DEFAULT NULL,
	in_lookup_keys			IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES,
	in_values				IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES,
	in_city 				IN  company.city%TYPE DEFAULT NULL,
	in_state 				IN  company.state%TYPE DEFAULT NULL,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE CreateNewCompany(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE DedupeNewCompany_Unsec(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID,
	out_matched_sids		OUT security_pkg.T_SID_IDS,
	out_can_create_unique	OUT NUMBER
);

PROCEDURE RequestNewCompany(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_sid			OUT security_pkg.T_SID_ID,
	out_pend_request_creatd OUT NUMBER,
	out_can_create_unique	OUT NUMBER,
	out_matched_sids		OUT	security_pkg.T_SID_IDS
);

/* Wrapper for c#*/
PROCEDURE RequestNewCompany(
	in_name					IN company.name%TYPE,
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE,
	in_address_1 			IN company.address_1%TYPE DEFAULT NULL,
	in_address_2 			IN company.address_2%TYPE DEFAULT NULL,
	in_address_3 			IN company.address_3%TYPE DEFAULT NULL,
	in_address_4 			IN company.address_4%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_postcode 			IN company.postcode%TYPE DEFAULT NULL,
	in_phone 				IN company.phone%TYPE DEFAULT NULL,
	in_fax 					IN company.fax%TYPE DEFAULT NULL,
	in_website				IN company.website%TYPE DEFAULT NULL,
	in_email				IN company.email%TYPE DEFAULT NULL,
	in_city 				IN company.city%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_reference_ids		IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_values				IN chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_tag_ids				IN security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_company_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_matched_comp_cur	OUT security_pkg.T_OUTPUT_CUR
);

/* Just preserved for backwards compatiibility as there are services depending on it */
PROCEDURE CreateUniqueCompany(
	in_name						IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	in_company_type_id			IN  company_type.company_type_id%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	in_lookup_keys				IN	chain_pkg.T_STRINGS,
	in_values					IN	chain_pkg.T_STRINGS,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE CreateSubCompany(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_name						IN	company.name%TYPE,
	in_country_code				IN	company.name%TYPE,
	in_company_type_id			IN	company_type.company_type_id%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	in_lookup_keys				IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels,
	in_values					IN	chain_pkg.T_STRINGS DEFAULT chain_pkg.EMPTY_VALUES, --reference labels,
	out_company_sid				OUT security_pkg.T_SID_ID
);



PROCEDURE DeleteCompanyFully(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UNSEC_DeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UndeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID, 
	in_name						IN  company.name%TYPE := chain_pkg.PRESERVE_STRING,
	in_country_code				IN  company.country_code%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_1				IN  company.address_1%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_2				IN  company.address_2%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_3				IN  company.address_3%TYPE := chain_pkg.PRESERVE_STRING,
	in_address_4				IN  company.address_4%TYPE := chain_pkg.PRESERVE_STRING,
	in_city						IN  company.city%TYPE := chain_pkg.PRESERVE_STRING,
	in_state					IN  company.state%TYPE := chain_pkg.PRESERVE_STRING,
	in_postcode					IN  company.postcode%TYPE := chain_pkg.PRESERVE_STRING,
	in_latitude					IN  csr.region.geo_latitude%TYPE := chain_pkg.PRESERVE_NUMBER,
	in_longitude				IN  csr.region.geo_longitude%TYPE := chain_pkg.PRESERVE_NUMBER,
	in_phone					IN  company.phone%TYPE := chain_pkg.PRESERVE_STRING,
	in_fax						IN  company.fax%TYPE := chain_pkg.PRESERVE_STRING,
	in_website					IN  company.website%TYPE := chain_pkg.PRESERVE_STRING,
	in_email					IN  company.email%TYPE := chain_pkg.PRESERVE_STRING,
	in_sector_id				IN  company.sector_id%TYPE := chain_pkg.PRESERVE_NUMBER,
	in_lookup_keys				IN	chain_pkg.T_STRINGS := chain_pkg.NullStringArray,
	in_values					IN	chain_pkg.T_STRINGS := chain_pkg.NullStringArray,
	in_trigger_link				IN  NUMBER := 1
);

PROCEDURE UpdateCompanyParentSid (
	in_company_sid				IN  security_pkg.T_SID_ID, 
	in_parent_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetBusinessUnits (
	in_company_sid				IN	security_pkg.T_SID_ID, 
	in_business_unit_ids			IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE SetTags (
	in_company_sid				IN	security_pkg.T_SID_ID, 
	in_tag_ids					IN	security_pkg.T_SID_IDS,
	in_add_calc_jobs			IN	NUMBER DEFAULT 0
);

FUNCTION GetCompanySidByLayout (
	in_name					IN company.name%TYPE,	
	in_country_code			IN company.country_code%TYPE,
	in_company_type_id		IN company_type.company_type_id%TYPE DEFAULT NULL,
	in_sector_id			IN company.sector_id%TYPE DEFAULT NULL,
	in_state 				IN company.state%TYPE DEFAULT NULL,
	in_city					IN company.city%TYPE DEFAULT NULL,
	in_swallow_not_found	IN NUMBER DEFAULT 0
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetPendingCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR,
	out_refs					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckCompanyAccess(
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE GetCompany (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR,
	out_refs					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR,
	out_refs					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_refs				OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_items			OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_trans			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_members		OUT	security_pkg.T_OUTPUT_CUR,
	out_alt_comp_names		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bu_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_refs				OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_items			OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_trans			OUT	security_pkg.T_OUTPUT_CUR,
	out_role_members		OUT	security_pkg.T_OUTPUT_CUR,
	out_alt_comp_names		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyUserLevelMessaging (
	out_user_level_messaging	OUT company.user_level_messaging%TYPE
);

PROCEDURE TransitionCompany (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_to_state_id			IN	csr.flow_state.flow_state_id%TYPE,
	in_comment_text			IN	csr.flow_state_log.comment_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY
);

FUNCTION GetCompanyName 
RETURN company.name%TYPE;

FUNCTION GetCompanyName (
	in_company_sid 				IN security_pkg.T_SID_ID
) RETURN company.name%TYPE;

PROCEDURE CanSeeAllCompanies (
	out_can_see					OUT	company.can_see_all_companies%TYPE
);

PROCEDURE SearchCompanies ( 
	in_search_term  			IN  varchar2,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanies ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchTeamroomCompanies(
	in_search_term	IN	VARCHAR2,
	out_cur			OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers ( 
	in_page   						IN  number,
	in_page_size    				IN  number,
	in_search_term  				IN  varchar2,
	in_only_active					IN  number,
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers ( 
	in_company_sid					IN security_pkg.T_SID_ID, 
	in_page   						IN  number,
	in_page_size    				IN  number,
	in_search_term  				IN  varchar2,
	in_only_active					IN  number,
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers ( 
	in_company_sid					IN security_pkg.T_SID_ID, 
	in_page   						IN  number,
	in_page_size    				IN  number,
	in_search_term  				IN  varchar2,
	in_only_active					IN  number, /*include active relationships */
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	in_search_for_pending			IN  NUMBER, /*include pending relationships */
	in_search_for_unrelated			IN  NUMBER, /*include no relationships */
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers ( 
	in_company_sid					IN security_pkg.T_SID_ID, 
	in_page   						IN  number,
	in_page_size    				IN  number,
	in_search_term  				IN  varchar2,
	in_only_active					IN  number, /*include active relationships */
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	in_search_for_pending			IN  NUMBER, /*include pending relationships */
	in_search_for_unrelated			IN  NUMBER, /*include no relationships */
	in_search_for_tags				IN  NUMBER, /*enable search with tag ids */
	in_tag_ids						IN security_pkg.T_SID_IDS,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers ( 
	in_company_sid					IN security_pkg.T_SID_ID, 
	in_page   						IN  number,
	in_page_size    				IN  number,
	in_search_term  				IN  varchar2,
	in_only_active					IN  number, /*include active relationships */
	in_wanted_supplier_cts			IN	helper_pkg.T_NUMBER_ARRAY,
	in_search_for_pending			IN  NUMBER, /*include pending relationships */
	in_search_for_unrelated			IN  NUMBER, /*include no relationships */
	in_search_for_tags				IN  NUMBER, /*enable search with tag ids */
	in_tag_ids						IN security_pkg.T_SID_IDS,
	in_unsec_for_not_related_sid	IN NUMBER, /* Searches for suppliers of a not related in_company_sid */
	in_only_active_companies		IN NUMBER := chain_pkg.INACTIVE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompaniesForReqQnrFrom(
	in_search_term 			IN  VARCHAR2,
	in_company_sid			IN	security_pkg.T_SID_ID, 
	in_exclude_sids			IN	security_pkg.T_SID_IDS,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompaniesToRelateWith(
	in_search_term  				IN  VARCHAR2,
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_company_function				IN  chain_pkg.T_COMPANY_FUNCTION,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchPotentialSuppliers(
	in_search_term  				IN  VARCHAR2,
	in_company_sid					IN	security_pkg.T_SID_ID, 
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	in_company_type_id				IN	company_type.company_type_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSubsidiaries(
	in_company_sid					IN	security_pkg.T_SID_ID,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchPurchasingSuppliers(
	in_search_term 					IN  VARCHAR2,
	in_page   						IN  NUMBER,
	in_page_size    				IN  NUMBER,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CompanyTypeRelationshipExists(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

/* Return relationships where in_company is purchaser when in_get_suppliers = 1,
   supplier when in_get_suppliers = 0 or either if it's null. */
PROCEDURE SearchCompanyRelationships(
	in_search_term		IN  VARCHAR2,
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_company_function	IN  chain_pkg.T_COMPANY_FUNCTION,
	in_page   			IN  NUMBER,
	in_page_size    	IN  NUMBER,
	out_count_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_scores_cur		OUT security_pkg.T_OUTPUT_CUR
);

/* collects a paged cursor of companies based on sids passed in as a T_SID_TABLE */
PROCEDURE CollectSearchResults (
	in_all_results			IN  security.T_SID_TABLE,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchFollowingSuppliers (
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_primary_only			IN  NUMBER,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFollowingSupplierSids (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_primary_only				IN  BOOLEAN,
	out_company_sids			OUT security.T_SID_TABLE
);

FUNCTION GetCompanySidBySupRelCode (
	in_supplier_code		IN  supplier_relationship.supp_rel_code%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetPurchaserNames (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchMyCompanies ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID, 
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE DEFAULT NULL,
	in_source_type				IN	chain_pkg.T_RELATIONSHIP_SOURCE DEFAULT chain_pkg.AUTO_REL_SRC,
	in_object_id				IN	supplier_relationship_source.object_id%TYPE DEFAULT NULL
);

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN,
	in_trigger_message			IN 	NUMBER DEFAULT 0
);

/* Establishes a relationship between two companies, by associating purchaser, supplier role based on permissible company type*/
PROCEDURE EstablishRelationship(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_set_as_primary			IN  NUMBER DEFAULT 0,
	in_source_type				IN	chain_pkg.T_RELATIONSHIP_SOURCE DEFAULT chain_pkg.AUTO_REL_SRC,
	in_object_id				IN	supplier_relationship_source.object_id%TYPE DEFAULT NULL
);

/* Deletes a relationship between two companies, by associating purchaser, supplier role based on permissible company type*/
PROCEDURE DeleteRelationship(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_trigger_message			IN 	NUMBER DEFAULT 0
);

PROCEDURE SetRelationshipAsPrimary(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

/* used when supplier accepts a request Qnnaire invitation */
PROCEDURE UNSEC_EstablishRelationship(
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID, 
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE DEFAULT NULL,
	in_trigger_message			IN 	NUMBER DEFAULT 0,
	in_source_type				IN	chain_pkg.T_RELATIONSHIP_SOURCE DEFAULT chain_pkg.AUTO_REL_SRC,
	in_object_id				IN	supplier_relationship_source.object_id%TYPE DEFAULT NULL
);

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE ActivateVirtualRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE DeactivateVirtualRelationship (
	in_key						IN  supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE DeleteSupplierRelationshipSrc(
	in_object_id				IN supplier_relationship_source.object_id%TYPE,
	in_source_type				IN chain_pkg.T_RELATIONSHIP_SOURCE
);

FUNCTION GetVisibleCompanySids RETURN security.T_SID_TABLE;

FUNCTION GetVisibleRelationships (
	in_include_inactive_rels	IN	NUMBER DEFAULT 0,
	in_include_hidden_rels		IN	NUMBER DEFAULT 0,
	in_allow_admin				IN	NUMBER DEFAULT 0
) RETURN chain.T_COMPANY_REL_SIDS_TABLE;

FUNCTION GetSuppRelCode (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN supplier_relationship.supp_rel_code%TYPE;

PROCEDURE UpdateSuppRelCode (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE
);

PROCEDURE UpdateSuppRelCode (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE
);

PROCEDURE AddPurchaserFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE AddSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE AddSupplierFollower_UNSEC (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

FUNCTION CanAddSupplierFollower(
	in_purchaser_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_type_id	IN company_type.company_type_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE RemoveSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

FUNCTION GetPurchaserFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION GetSupplierFollowersNoCheck (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION GetSupplierFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE UNSEC_ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UNSEC_DeactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UNSEC_ReactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE ReactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCompanies (
	in_user_sid					IN  security_pkg.T_SID_ID,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetStubSetupDetails (
	in_active					IN  company.allow_stub_registration%TYPE,
	in_approve					IN  company.approve_stub_registration%TYPE,
	in_stubs					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetStubSetupDetails (
	out_options_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStubEmailAddresses (
	in_company_sid			IN	security_pkg.T_SID_ID,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyFromStubGuid (
	in_guid						IN  company.stub_registration_guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ConfirmCompanyDetails (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE CheckSupplierExists (
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_company_type_id		IN	company.company_type_id%TYPE,
	in_name					IN	company.name%TYPE,
	in_country_code			IN	company.country_code%TYPE,
	in_lookup_keys			IN	chain_pkg.T_STRINGS,
	in_values				IN	chain_pkg.T_STRINGS,
	in_supp_rel_code		IN 	supplier_relationship.supp_rel_code%TYPE,
	in_sector_id			IN 	company.sector_id%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetSectorId (
	in_sector_name			IN  sector.description%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION GetCompanyGroupTypeId (
	in_group				IN  chain_pkg.T_GROUP
) RETURN NUMBER;

PROCEDURE GetCompanyGroupTypes (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE HasSupplierRelationships (
	out_result				OUT NUMBER
);

PROCEDURE UpdateCompanyReference (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_key			IN v$company_reference.lookup_key%TYPE,
	in_value				IN company_reference.value%TYPE
);

PROCEDURE UpdateCompanyReferences (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_keys			IN chain_pkg.T_STRINGS,
	in_values				IN chain_pkg.T_STRINGS,
	in_is_pending			IN NUMBER DEFAULT 0
);

FUNCTION TryGetCompanyReferenceValue(
	in_company_sid			IN security_pkg.T_SID_ID,
	in_lookup_key			IN v$company_reference.lookup_key%TYPE
) RETURN chain.company_reference.value%TYPE;

PROCEDURE GetCompanyRoleMembers(
	in_company_sid					IN  activity.target_company_sid%TYPE,
	in_role_sid						IN	activity.target_role_sid%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeactivateSupplierHelper(
    in_flow_sid                 IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  csr.flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE ActivateSupplierHelper(
    in_flow_sid                 IN  security.security_pkg.T_SID_ID,
    in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
    in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
    in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
    in_comment_text             IN  csr.flow_state_log.comment_text%TYPE,
    in_user_sid                 IN  security.security_pkg.T_SID_ID
);

FUNCTION GetConnectedRelationships(
	in_company_sid					IN security_pkg.T_SID_ID
) RETURN chain.T_COMPANY_REL_SIDS_TABLE;

PROCEDURE GetCompaniesGraph(
	in_company_sid					IN security_pkg.T_SID_ID DEFAULT NULL,
	out_companies_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_relationships_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_scores_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CheckPreserve_ (
	in_new_value			VARCHAR2,
	in_old_value			VARCHAR2
) RETURN VARCHAR2;

FUNCTION CheckPreserve_ (
	in_new_value			NUMBER,
	in_old_value			NUMBER
) RETURN NUMBER;

/* Used by structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetCompanies(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

/* Used by supplier follower structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetCompaniesAndUsersAndSuppRel(
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_users_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_supp_rel_cur		OUT	security_pkg.T_OUTPUT_CUR
);

/* Used by company relationship structured import - supported only for superadmins/built-in admins*/
PROCEDURE GetCompaniesSuppRelAndTypeRel(
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_supp_rel_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_type_rel_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveAltCompanyNames (
	in_alt_company_name_ids	IN security_pkg.T_SID_IDS,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_alt_company_names	IN chain_pkg.T_STRINGS
);

PROCEDURE SaveAltCompanyName (
	in_alt_company_name_id	IN  security_pkg.T_SID_ID DEFAULT -1,
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_name					IN  alt_company_name.name%TYPE
);

FUNCTION CheckAltCompNameExists(
	in_company_sid			IN security_pkg.T_SID_ID,
	in_name					IN alt_company_name.name%TYPE,
	in_alt_company_name_id	IN security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE GetSuppRelScores(
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	out_supp_rel_scores_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetSupplierRelationshipScore (
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.score_type.score_type_id%TYPE,
	in_threshold_id				IN	csr.score_threshold.score_threshold_id%TYPE,
	in_score					IN	supplier_relationship_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  supplier_relationship_score.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  supplier_relationship_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  supplier_relationship_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  supplier_relationship_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  supplier_relationship_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  supplier_relationship_score.comment_text%TYPE DEFAULT NULL
);

PROCEDURE SetSupplierRelationshipScore (
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.score_type.score_type_id%TYPE,
	in_thresh_lookup_key		IN	csr.score_threshold.lookup_key%TYPE,
	in_score					IN	supplier_relationship_score.score%TYPE DEFAULT NULL, 
	in_set_dtm					IN  supplier_relationship_score.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  supplier_relationship_score.valid_until_dtm%TYPE DEFAULT NULL,
	in_is_override				IN  supplier_relationship_score.is_override%TYPE DEFAULT 0,
	in_score_source_type		IN  supplier_relationship_score.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN  supplier_relationship_score.score_source_id%TYPE DEFAULT NULL,
	in_comment_text				IN  supplier_relationship_score.comment_text%TYPE DEFAULT NULL
);

PROCEDURE DeleteSupRelScore (
	in_purchaser_sid			IN	security_pkg.T_SID_ID,
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.score_type.score_type_id%TYPE,
	in_set_dtm					IN  supplier_relationship_score.set_dtm%TYPE,
	in_valid_until_dtm			IN  supplier_relationship_score.valid_until_dtm%TYPE,
	in_is_override				IN  supplier_relationship_score.is_override%TYPE DEFAULT 0
);

PROCEDURE PromotePendingCompany(
	in_pending_company_sid 		IN security_pkg.T_SID_ID
);

FUNCTION ProcessPendingRequest_UNSEC(
	in_pending_company_sid 		IN security_pkg.T_SID_ID
) RETURN BOOLEAN;


PROCEDURE GetCompanySidsToProcess(
	in_batch_job_id 			IN csr.batch_job.batch_job_id%TYPE,
	out_process_recs			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ProcessPendingCompRec(
	in_batch_job_id 			IN csr.batch_job.batch_job_id%TYPE,
	in_company_sid				IN security_pkg.T_SID_ID,
	out_success					OUT NUMBER
);

FUNCTION CreatePendingCompanyRequestJob
RETURN csr.batch_job.batch_job_id%TYPE;

PROCEDURE AddPendingCompRequestActions(
	in_company_sid				IN security_pkg.T_SID_ID,
	in_matched_company_sid		IN security_pkg.T_SID_ID,
	in_action 					IN security_pkg.T_SID_ID,
	in_batch_job_id 			IN csr.batch_job.batch_job_id%TYPE
);

PROCEDURE GetPrimaryPurchaserTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPrimaryPurchasersForCompany(
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPendingCompanyAlerts(
	out_cur 	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE MarkPendingCompanyAlertSent (
	in_app_sid 			security_pkg.T_SID_ID,
	in_company_sid 		security_pkg.T_SID_ID
);

PROCEDURE GetCompanyAddress(
	in_company_sid			security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetCompaniesToGeocode(
	in_batch_job_id		csr.batch_job.batch_job_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION CreateGeotagBatchJob(
	in_geotag_source	geotag_batch.source%TYPE
) RETURN geotag_batch.batch_job_id%TYPE;

PROCEDURE QueueCompanyInGeotagBatch(
	in_company_sid 		security_pkg.T_SID_ID,
	in_geotag_batch_id	geotag_batch.geotag_batch_id%TYPE
);

PROCEDURE MarkGeotagCompany(
	in_company_sid 			security_pkg.T_SID_ID,
	in_batch_job_id			geotag_batch.batch_job_id%TYPE,
	in_longitude			NUMBER DEFAULT NULL,
	in_latitude				NUMBER DEFAULT NULL
);

PROCEDURE UNSEC_GetCompanySidsByReference (
	in_comp_ref_val			IN  company_reference.value%TYPE,
	in_ref_lookup			IN  reference.lookup_key%TYPE,
	out_company_sids		OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCompanyRefs(
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION Unsec_GetCompanyTags(
	in_company_sid		IN security_pkg.T_SID_ID,
	in_lookup_key		IN csr.tag_group.lookup_key%TYPE
) RETURN csr.T_VARCHAR2_TABLE;

FUNCTION Unsec_GetSubsidiaries(
	in_parent_company_sid	IN security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE;

FUNCTION Unsec_GetParentSid(
	in_company_sid	IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

END company_pkg;
/

