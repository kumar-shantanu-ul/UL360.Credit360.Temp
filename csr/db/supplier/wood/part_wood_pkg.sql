create or replace package supplier.part_wood_pkg
IS

PART_WOOD_CLASS_NAME		CONSTANT VARCHAR2(255) := 'PART_WOOD';
CERT_UNKNOWN				CONSTANT NUMBER(10) := 1;
TYPE T_PART_WOOD_IDS        IS TABLE OF wood_part_wood.product_part_id%TYPE INDEX BY PLS_INTEGER;

FUNCTION GetForestSourceCatCode(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
) RETURN cert_scheme.verified_fscc%TYPE
;

PROCEDURE GetForestSourceCatCode(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_cert_scheme_id		IN cert_scheme.cert_scheme_id%TYPE,
	in_country_code			IN wood_part_wood.country_code%TYPE,
	in_species_code			IN wood_part_wood.species_code%TYPE, 
	out_fscc_desc			OUT VARCHAR2
);

PROCEDURE CreatePartWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product_part.product_id%TYPE,
	in_parent_part_id		IN product_part.parent_id%TYPE,
	in_species_code			IN wood_part_wood.species_code%TYPE,
	in_country_code			IN wood_part_wood.country_code%TYPE,
	in_region				IN wood_part_wood.region%TYPE,
	in_cert_doc_group_id	IN wood_part_wood.cert_doc_group_id%TYPE,
	in_bleaching_process_id	IN wood_part_wood.bleaching_process_id%TYPE,
	in_wrme_wood_type_id	IN wood_part_wood.wrme_wood_type_id%TYPE,
	in_cert_scheme_id		IN wood_part_wood.cert_scheme_id%TYPE,
	out_product_part_id		OUT product_part.product_part_id%TYPE
);

PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
);

PROCEDURE UpdatePartWood(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE,
	in_species_code			IN wood_part_wood.species_code%TYPE,
	in_country_code			IN wood_part_wood.country_code%TYPE,
	in_region				IN wood_part_wood.region%TYPE,
	in_cert_doc_group_id	IN wood_part_wood.cert_doc_group_id%TYPE,
	in_bleaching_process_id	IN wood_part_wood.bleaching_process_id%TYPE,
	in_wrme_wood_type_id	IN wood_part_wood.wrme_wood_type_id%TYPE,
	in_cert_scheme_id		IN wood_part_wood.cert_scheme_id%TYPE
);

PROCEDURE DeletePart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_part_id		IN product_part.product_part_id%TYPE
);

PROCEDURE GetGenusList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpeciesList(
	in_genus				IN	tree_species.genus%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCommonNameList(
	in_genus				IN	tree_species.genus%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetCertSchemeList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBleachingProcList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWrmeWoodTypeList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
);

END part_wood_pkg;
/

