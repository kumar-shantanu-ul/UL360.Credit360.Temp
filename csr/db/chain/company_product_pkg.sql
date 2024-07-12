CREATE OR REPLACE PACKAGE CHAIN.company_product_pkg AS

PROCEDURE UNSEC_GetProductIdFromRef (
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
);

PROCEDURE SearchOwnerCompanies(
	in_search_term  				IN  varchar2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_TryGetIdFromProductRef (
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
);

PROCEDURE UNSEC_TryGetIdFromLookupKey(
	in_lookup_key	IN company_product.lookup_key%TYPE,
	in_company_sid	IN company_product.company_sid%TYPE,
	out_product_id	OUT company_product.product_id%TYPE
);

PROCEDURE UNSEC_TryGetIdFromDescription(
	in_description	IN company_product_tr.description%TYPE,
	in_company_sid	IN company_product.company_sid%TYPE,
	out_product_id	OUT company_product.product_id%TYPE
);

PROCEDURE UNSEC_SaveCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_type_id		IN	chain.company_product.product_type_id%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	in_lookup_key			IN	chain.company_product.lookup_key%TYPE,
	in_name					IN	chain.company_product_tr.description%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
);

PROCEDURE SaveCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_type_id		IN	chain.company_product.product_type_id%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	in_lookup_key			IN	chain.company_product.lookup_key%TYPE,
	in_name					IN	chain.company_product_tr.description%TYPE,
	out_product_id			OUT	chain.company_product.product_id%TYPE
);

PROCEDURE SaveCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_company_sid			IN	chain.company_product.company_sid%TYPE,
	in_product_type_id		IN	chain.company_product.product_type_id%TYPE,
	in_product_ref			IN	chain.company_product.product_ref%TYPE,
	in_lookup_key			IN	chain.company_product.lookup_key%TYPE,
	in_name					IN	chain.company_product_tr.description%TYPE,
	in_is_active			IN	chain.company_product.is_active%TYPE,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_desc_languages		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	out_product_id			OUT	chain.company_product.product_id%TYPE
);

PROCEDURE SaveCompanyProductTags(
	in_product_id			IN	chain.company_product.product_id%TYPE,
	in_tag_group_id			IN	csr.tag_group.tag_group_id%TYPE,
	in_tag_ids				IN	security.security_pkg.T_SID_IDS
);

PROCEDURE DeleteCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE
);

PROCEDURE DeactivateCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE
);

PROCEDURE ReactivateCompanyProduct(
	in_product_id			IN	chain.company_product.product_id%TYPE
);

PROCEDURE AddCertificationToProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_id			IN	chain.company_product_certification.certification_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveCertificationFromProduct(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_id			IN	chain.company_product_certification.certification_id%TYPE
);

PROCEDURE GetProductCertifications(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

/* SUPPLIED PRODUCT */

PROCEDURE SearchSupplierPurchasers(
	in_product_id					IN	chain.product_supplier.product_id%TYPE,
	in_search_term  				IN  varchar2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSupplierSuppliers(
	in_product_id					IN	chain.product_supplier.product_id%TYPE,
	in_purchaser_company_sid		IN	chain.product_supplier.purchaser_company_sid%TYPE,
	in_search_term  				IN  varchar2,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddSupplierToProduct(
	in_product_id					IN	chain.company_product.product_id%TYPE,
	in_purchaser_company_sid		IN	chain.product_supplier.purchaser_company_sid%TYPE,
	in_supplier_company_sid			IN	chain.product_supplier.supplier_company_sid%TYPE,
	in_start_dtm					IN	chain.product_supplier.start_dtm%TYPE,
	in_end_dtm						IN	chain.product_supplier.end_dtm%TYPE,
	in_product_supplier_ref			IN	chain.product_supplier.product_supplier_ref%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_cert_reqs_cur 				OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur	 				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateProductSupplier (
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE,
	in_start_dtm					IN	chain.product_supplier.start_dtm%TYPE,
	in_end_dtm						IN	chain.product_supplier.end_dtm%TYPE,
	in_product_supplier_ref			IN	chain.product_supplier.product_supplier_ref%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_cert_reqs_cur 				OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur	 				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveProductSupplierTags(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE,
	in_tag_group_id					IN	csr.tag_group.tag_group_id%TYPE,
	in_tag_ids						IN	security.security_pkg.T_SID_IDS
);

PROCEDURE DeactivateProductSupplier(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE
);

PROCEDURE ReactivateProductSupplier(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE
);

PROCEDURE RemoveSupplierFromProduct(
	in_product_supplier_id			IN	chain.product_supplier.product_supplier_id%TYPE
);

PROCEDURE SearchProducts (
	in_search_term			VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetProduct(
	in_product_id				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductsForMetricsImport(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetPrdSupplrsForMetricsImport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProducts(
	in_product_ids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR,
	out_tags_cur				OUT SYS_REFCURSOR
);

PROCEDURE AddCertToProductSupplier(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE,
	in_certification_id			IN	chain.product_supplier_certification.certification_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveCertFromProductSupplier(
	in_product_supplier_id		IN	chain.product_supplier.product_supplier_id%TYPE,
	in_certification_id			IN	chain.product_supplier_certification.certification_id%TYPE
);

PROCEDURE SaveProductCertRequirement(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_type_id	IN	chain.certification_type.certification_type_id%TYPE,
	in_from_dtm					IN	DATE,
	in_to_dtm					IN	DATE
);

PROCEDURE RemoveProductCertRequirement(
	in_product_id				IN	chain.company_product.product_id%TYPE,
	in_certification_type_id	IN	chain.certification_type.certification_type_id%TYPE
);

FUNCTION GetReqdSupplierCerts(
	in_product_supplier_ids		IN	T_FILTERED_OBJECT_TABLE,
	in_certification_type_ids	IN	security.T_SID_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE;

-- This function assumes you've already done the capability check on the product IDs,
-- though it will do its own capability check on suppliers and certifications.
FUNCTION INTERNAL_GetProductCertReqs(
	in_product_ids				IN	security.T_SID_TABLE,
	in_certification_type_ids	IN	security.T_SID_TABLE
) RETURN T_OBJECT_CERTIFICATION_TABLE;

PROCEDURE GetCertRequirementsForProduct(
	in_product_id			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllTranslations(
	in_validation_lang		IN	company_product_tr.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTranslations(
	in_product_ids			IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	company_product_tr.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetTranslation(
	in_product_id		IN	company_product.product_id%TYPE,
	in_lang				IN	company_product_tr.lang%TYPE,
	in_translated		IN	VARCHAR2
);

END company_product_pkg;
/
