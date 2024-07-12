CREATE OR REPLACE PACKAGE csr.measure_api_pkg AS

PROCEDURE GetMeasuresBySids(
	in_sids				        IN	security.security_pkg.T_SID_IDS,
	out_measure_cur		        OUT	SYS_REFCURSOR,
	out_measure_conv_cur		OUT	SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetMeasures(
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_measure_cur				OUT SYS_REFCURSOR,
	out_measure_conv_cur		OUT SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMeasuresByLookupKey(
	in_lookup_keys				IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_measure_cur				OUT SYS_REFCURSOR,
	out_measure_conv_cur		OUT SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
);

END;
/

