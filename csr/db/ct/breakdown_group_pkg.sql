CREATE OR REPLACE PACKAGE ct.breakdown_group_pkg AS

PROCEDURE GetBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBreakdownGroups(
	in_group_key				IN  breakdown_group.group_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGroupBreakdownRegions(
	in_breakdown_group_id		IN  breakdown_region_group.breakdown_group_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE,
	in_breakdown_type_id		IN  breakdown_group.breakdown_type_id%TYPE,
	in_is_default				IN  breakdown_group.is_default%TYPE,
	in_name						IN  breakdown_group.name%TYPE,
	in_group_key				IN  breakdown_group.group_key%TYPE,
	out_breakdown_group_id		OUT breakdown_group.breakdown_group_id%TYPE
);

PROCEDURE SetGroupBreakdownRegion(
	in_breakdown_group_id		IN  breakdown_region_group.breakdown_group_id%TYPE,
	in_breakdown_id				IN  breakdown_region_group.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_group.breakdown_id%TYPE
);

PROCEDURE DeleteBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE
);

PROCEDURE DeleteBreakdownGroup(
	in_breakdown_group_id		IN  breakdown_group.breakdown_group_id%TYPE,
	in_delete_fully				IN  NUMBER
);

PROCEDURE DeleteGroupBreakdownRegion(
	in_breakdown_group_id		IN  breakdown_region_group.breakdown_group_id%TYPE,
	in_breakdown_id				IN  breakdown_region_group.breakdown_id%TYPE,
	in_region_id				IN  breakdown_region_group.breakdown_id%TYPE
);

END breakdown_group_pkg;
/
