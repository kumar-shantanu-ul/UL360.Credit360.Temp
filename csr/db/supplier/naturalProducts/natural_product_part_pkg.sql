create or replace package supplier.natural_product_part_pkg
IS

PART_DESCRIPTION_CLS			CONSTANT VARCHAR2(255) := 'NP_PART_DESCRIPTION';


PROCEDURE CreatePart(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	product_part.product_id%TYPE,
	in_description			IN	np_part_description.description%TYPE,
	in_part_code			IN	np_part_description.part_code%TYPE,
	in_natural_claim		IN	np_part_description.natural_claim%TYPE,
	out_product_part_id		OUT	product_part.product_part_id%TYPE
);

PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
);

PROCEDURE UpdatePart(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_part_id				IN	product_part.product_part_id%TYPE,
	in_description			IN	np_part_description.description%TYPE,
	in_part_code			IN	np_part_description.part_code%TYPE,
	in_natural_claim		IN	np_part_description.natural_claim%TYPE
);

PROCEDURE DeletePart(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
);

PROCEDURE GetProductParts(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_product_id			IN	all_product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
);

END natural_product_part_pkg;
/