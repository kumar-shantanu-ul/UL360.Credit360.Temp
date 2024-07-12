CREATE OR REPLACE PACKAGE CHAIN.product_pkg
IS

FUNCTION GetLastRevisionPseudoRootCmpId(
	in_product_id		product.product_id%TYPE
) RETURN product_revision.supplier_root_component_id%TYPE;

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE,
    in_notes				IN  product_revision.notes%TYPE,
	in_user_sid				security.security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
) RETURN NUMBER;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE PublishProduct (
	in_product_id		   IN product.product_id%TYPE,
	in_revision_no			IN product_revision.revision_num%TYPE DEFAULT NULL
);

PROCEDURE FinishValidation (
	in_product_id			IN product.product_id%TYPE,
	in_revision_no			IN product_revision.revision_num%TYPE,
	out_validation_status_id	OUT product_revision.validation_status_id%TYPE
);

PROCEDURE GetValidationStatuses(
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateNewProductRevision (
	in_product_id			IN product.product_id%TYPE
);

PROCEDURE EditProduct (
	in_product_id			IN product.product_id%TYPE,
	in_revision_no			IN product_revision.revision_num%TYPE DEFAULT NULL
);

PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	in_revision_no			IN	product_revision.revision_num%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductRevisions (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_only_show_empty_codes	IN  NUMBER,
	in_only_show_unpublished	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_code_label1					IN  product_code_type.code_label1%TYPE,
	in_code_label2					IN  product_code_type.code_label2%TYPE,
	in_code_label3					IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory				IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory				IN 	product_code_type.code3_mandatory%TYPE,
	out_products_with_empty_codes	OUT NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetNonEmptyProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
);

PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product_revision.active%TYPE
);

PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product_revision.need_review%TYPE
);

FUNCTION HasMappedUnpublishedProducts (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE CopyProdCompForValidation (
	in_product_id			IN product.product_id%TYPE,
	in_revision_no			IN product_revision.revision_num%TYPE,
	in_force_copy			IN NUMBER,
	out_new_component_id	OUT component.component_id%TYPE
);

PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
);

PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
);

--
-- Product Type procedures
--
PROCEDURE GetProductTypes (
	in_parent_product_type_id		IN  product_type.parent_product_type_id%TYPE DEFAULT NULL,
	in_fetch_depth					IN  NUMBER DEFAULT NULL,	out_product_type_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_product_tag_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductTypeList (
	in_parent_product_type_id		IN	product_type.parent_product_type_id%TYPE,
	in_search_phrase				IN	VARCHAR2 DEFAULT NULL,
	in_fetch_depth					IN	NUMBER DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductType (
	in_product_type_id				IN  product_type.product_type_id%TYPE DEFAULT NULL,
	in_parent_product_type_id		IN  product_type.parent_product_type_id%TYPE DEFAULT NULL,
	in_label						IN  product_type.label%TYPE,
	in_lookup_key					IN  product_type.lookup_key%TYPE DEFAULT NULL,
	in_tag_ids						IN  helper_pkg.T_NUMBER_ARRAY,
	out_product_type_id				OUT product_type.product_type_id%TYPE
);

PROCEDURE DeleteOldProductTypes (
	in_product_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetCompanyProductTypes (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	out_product_type_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_product_tag_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompanyProductTypes (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	in_product_type_ids				IN  helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE AddCompanyProductType (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	in_product_type_id				IN  product_type.product_type_id%TYPE
);

PROCEDURE RemoveCompanyProductType (
	in_company_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),	
	in_product_type_id				IN  product_type.product_type_id%TYPE
);

PROCEDURE FilterCompaniesByProdTypeTags (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterCompaniesByProductType (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE SupplySummary (
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);

END product_pkg;
/
