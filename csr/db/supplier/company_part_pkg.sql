CREATE OR REPLACE PACKAGE SUPPLIER.company_part_pkg
IS
	
	TYPE T_PART_IDS IS TABLE OF company_part.company_part_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE CreateCompanyPart(
	in_act_id							IN security_pkg.T_ACT_ID,
	in_part_type_id				IN company_part.part_type_id%TYPE,
	in_company_sid				IN company_part.company_sid%TYPE,
	in_parent_part_id			IN company_part.parent_id%TYPE,
	out_company_part_id		OUT company_part.company_part_id%TYPE
);

PROCEDURE DeleteCompanyPart(
	in_act_id				IN 		security_pkg.T_ACT_ID,
	in_company_part_id		IN company_part.company_part_id%TYPE
);

PROCEDURE GetHelperPackage(
	in_part_type_id			IN part_type.part_type_id%TYPE,
	out_helper_pkg			OUT part_type.package%TYPE
);

PROCEDURE DeleteAbsentParts(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_company_sid		IN company_part.company_sid%TYPE,
	in_parent_part_id	IN company_part.parent_id%TYPE,
	in_type_id				IN part_type.part_type_id%TYPE,
	in_part_ids				IN T_PART_IDS
);

FUNCTION IsPartAccessAllowed(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_part_id			IN 	company_part.company_part_id%TYPE,
	in_perms				IN 	security_pkg.T_PERMISSION
) RETURN BOOLEAN;

END company_part_pkg;
/
