CREATE OR REPLACE PACKAGE CSR.Region_Picker_Pkg AS

PROCEDURE CheckSecurity(
	in_parent_sids		IN	security.T_SID_TABLE
);

PROCEDURE GetRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	in_region_type		IN	region.region_type%TYPE DEFAULT NULL,
	in_geo_type			IN	region.geo_type%TYPE DEFAULT NULL,
	in_is_leaf			IN	NUMBER DEFAULT NULL,
	in_level			IN	NUMBER DEFAULT NULL,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionsByType(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	in_region_type		IN	region.region_type%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLeafRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCountryRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionsForTags(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	in_tag_ids			IN	security_pkg.T_SID_IDS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChildRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSelectedRegionDescriptions(
	in_sids				IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END Region_Picker_Pkg;
/
