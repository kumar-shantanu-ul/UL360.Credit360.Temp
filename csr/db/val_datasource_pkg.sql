CREATE OR REPLACE PACKAGE CSR.val_datasource_pkg AS

PROCEDURE GetRegionTree(
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionTreeForSheets(
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRegions(
	out_cur							OUT SYS_REFCURSOR,
	out_tag_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetAllGasFactors(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAllIndDetails(
	out_cur							OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetIndAndReportCalcDetails(
	out_cur							OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_rep_calc_agg_child_cur		OUT	SYS_REFCURSOR
);

PROCEDURE InitDataSource;

PROCEDURE InitAggregateDataSource;

PROCEDURE GetIndDependencies(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAggregateIndDependencies(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAggregateChildren(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetRegionPctOwnership(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE INTERNAL_FetchResult(
	out_val_cur				OUT	SYS_REFCURSOR,
	out_file_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetStoredRecalcValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetScenarioRunValues(
	in_scenario_run_sid		IN	scenario_run.scenario_run_sid%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetSheetValues(	
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR,
    out_file_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetAllSheetValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetUserSheetValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetPendingValues(
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_val_cur				OUT	SYS_REFCURSOR,
    out_file_cur			OUT SYS_REFCURSOR
);

END;
/
