CREATE OR REPLACE PACKAGE SUPPLIER.product_part_pkg
IS

TYPE T_PART_IDS IS TABLE OF product_part.product_part_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE CreateProductPart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_part_type_id			IN product_part.part_type_id%TYPE,
	in_product_id			IN product_part.product_id%TYPE,
	in_parent_part_id		IN product_part.parent_id%TYPE,
	out_product_part_id		OUT product_part.product_part_id%TYPE
);

PROCEDURE DeleteProductPart(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_part_id		IN product_part.product_part_id%TYPE
);

PROCEDURE GetHelperPackage(
	in_part_type_id			IN part_type.part_type_id%TYPE,
	out_helper_pkg			OUT part_type.package%TYPE
);

PROCEDURE GetHelperPackage(
	in_class_name			IN part_type.class_name%TYPE,
	out_helper_pkg			OUT part_type.package%TYPE
);

PROCEDURE DeleteAbsentParts(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_product_id			IN product_part.product_id%TYPE,
	in_parent_part_id		IN product_part.parent_id%TYPE,
	in_type_id				IN part_type.part_type_id%TYPE,
	in_part_ids				IN T_PART_IDS
);

FUNCTION IsPartAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_part_id				IN 	product_part.product_part_id%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
	
) RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(IsPartAccessAllowed, WNDS, WNPS);

END product_part_pkg;
/
