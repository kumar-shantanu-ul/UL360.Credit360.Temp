CREATE OR REPLACE PACKAGE CSR.region_api_pkg AS

PROCEDURE Unsec_GetRegionBySid(
	in_sid					IN	NUMBER,
	in_include_tags			IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionBySid(
	in_sid					IN	NUMBER,
	in_include_tags			IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionCountry(
	in_region_sid			IN security_pkg.T_SID_ID,
	out_country_code_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetRegions(
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsByDescription(
	in_description			IN	region_description.description%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsByGeoCity(
	in_geo_city_id			IN	region.geo_city_id%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsByGeoCountry(
	in_geo_country			IN	region.geo_country%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsByGeoRegion(
	in_geo_region			IN	region.geo_region%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_search_all_trees		IN	NUMBER DEFAULT 0,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsByPath(
	in_path					IN	VARCHAR2,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionsBySid(
	in_region_sids			IN	security_pkg.T_SID_IDS,
	in_raise_count_errors	IN	NUMBER DEFAULT 1,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionTags(
	in_region_sid			IN security_pkg.T_SID_ID,
	out_tag_ids_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetRegionTrees(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_tree_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

END;
/
