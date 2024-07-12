CREATE OR REPLACE PACKAGE csr.indicator_api_pkg AS

PROCEDURE GetIndicators(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetAllIndicators(
	out_ind_cur					OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_measure_cur				OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndsByDescription(
	in_description			IN	ind_description.description%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndsByMeasureSid(
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndBySid(
	in_sid					IN	ind.ind_sid%TYPE,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorsBySid(
	in_ind_sids				IN	security_pkg.T_SID_IDS,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIndsByPath(
	in_path					IN	VARCHAR2,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorsByType(
	in_indicator_types		IN	security_pkg.T_SID_IDS,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

-- Used by the json exporter for moving data between sites.
PROCEDURE GetAllIndsHierarchical(
	in_parent_sid				IN	csr.ind.ind_sid%TYPE,
	out_inds_cur				OUT	SYS_REFCURSOR,
	out_ind_tags_cur			OUT	SYS_REFCURSOR,
	out_ind_descriptions_cur	OUT	SYS_REFCURSOR
);

END;
/
