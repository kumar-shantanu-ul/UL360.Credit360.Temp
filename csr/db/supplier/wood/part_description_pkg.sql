create or replace package supplier.part_description_pkg
IS

PART_DESCRIPTION_CLASS_NAME			CONSTANT VARCHAR2(255) := 'PART_DESCRIPTION';
CERT_UNKNOWN						CONSTANT NUMBER(10) := 1;
COUNTRY_CODE_UNSPECIFIED			CONSTANT VARCHAR2(8) := 'UN';

PROCEDURE CreatePartDescription(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_product_id					IN product_part.product_id%TYPE,
	in_parent_part_id				IN product_part.parent_id%TYPE,
	in_description	 				IN wood_part_description.description%TYPE,
	in_number_in_product 			IN wood_part_description.number_in_product%TYPE,
	in_weight 						IN wood_part_description.weight%TYPE,
	in_weight_unit_id 				IN wood_part_description.weight_unit_id%TYPE,
	in_pct_post_recycled	   		IN wood_part_description.post_recycled_pct%TYPE,
	in_pct_pre_recycled 			IN wood_part_description.pre_recycled_pct%TYPE,
	in_post_recycled_doc_group_id 	IN wood_part_description.post_recycled_doc_group_id%TYPE,
	in_pre_recycled_doc_group_id	IN wood_part_description.pre_recycled_doc_group_id%TYPE,
	in_post_cert_scheme_id	   		IN wood_part_description.post_cert_scheme_id%TYPE,
	in_pre_cert_scheme_id 			IN wood_part_description.pre_cert_scheme_id%TYPE,
	in_post_recycled_country_code	IN wood_part_description.post_recycled_country_code%TYPE,
	in_pre_recycled_country_code 	IN wood_part_description.pre_recycled_country_code%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
);
 
PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
);
 
PROCEDURE UpdatePartDescription(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_part_id						IN product_part.product_part_id%TYPE,
	in_description	 				IN wood_part_description.description%TYPE,
	in_number_in_product 			IN wood_part_description.number_in_product%TYPE,
	in_weight 						IN wood_part_description.weight%TYPE,
	in_weight_unit_id 				IN wood_part_description.weight_unit_id%TYPE,
	in_post_recycled_pct	   		IN wood_part_description.post_recycled_pct%TYPE,
	in_pre_recycled_pct 			IN wood_part_description.pre_recycled_pct%TYPE,
	in_post_recycled_doc_group_id 	IN wood_part_description.post_recycled_doc_group_id%TYPE,
	in_pre_recycled_doc_group_id	IN wood_part_description.pre_recycled_doc_group_id%TYPE,
	in_post_cert_scheme_id	   		IN wood_part_description.post_cert_scheme_id%TYPE,
	in_pre_cert_scheme_id 			IN wood_part_description.pre_cert_scheme_id%TYPE,
	in_post_recycled_country_code	IN wood_part_description.post_recycled_country_code%TYPE,
	in_pre_recycled_country_code 	IN wood_part_description.pre_recycled_country_code%TYPE
);

PROCEDURE DeletePart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_part_id		IN product_part.product_part_id%TYPE
);


PROCEDURE GetCertSchemeList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCertSchemeList(
	in_forest_source_cat	IN	forest_source_cat.forest_source_cat_code%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
);

PROCEDURE GetProductParts(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product.product_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

END part_description_pkg;
/
