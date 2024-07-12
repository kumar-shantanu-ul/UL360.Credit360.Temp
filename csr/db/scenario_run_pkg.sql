CREATE OR REPLACE PACKAGE CSR.scenario_run_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE SetValue(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_sid						IN	scenario_run_val.ind_sid%TYPE,
	in_region_sid					IN	scenario_run_val.region_sid%TYPE,
	in_period_start					IN	scenario_run_val.period_start_dtm%TYPE,
	in_period_end					IN	scenario_run_val.period_end_dtm%TYPE,
	in_val_number					IN	scenario_run_val.val_number%TYPE,
	in_source_type_id				IN	scenario_run_val.source_type_id%TYPE DEFAULT 0,
	in_error_code					IN	scenario_run_val.error_code%TYPE DEFAULT NULL
);

PROCEDURE CreateScenarioRun(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_description					IN	scenario_run.description%TYPE,
	out_scenario_run_sid			OUT	scenario_run.scenario_run_sid%TYPE
);

PROCEDURE GetDetails(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE RefreshData(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
);

PROCEDURE GetFeatureFlags(
	in_app_sid						IN	scenario_run.app_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioRunFile(
	in_app_sid						IN	scenario_run.app_sid%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,	
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE IsFileBased(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,
	out_file_based					OUT	scenario.file_based%TYPE
);

PROCEDURE GetFileBasedScenarioRuns(
	out_cur							OUT SYS_REFCURSOR
);

/**
 * GetAggregateDetails
 * 
 * @param in_scenario_run_sid	The scenario run to use
 * @param in_ind_sid			The indicator to fetch details for
 * @param in_region_sid		    The region to fetch data for
 * @param in_start_dtm		    The start date to fetch from
 * @param in_end_dtm			The start date to fetch to
 * @param out_val_cur			The values
 * @param out_child_cur		    Child region sids, and whether they are links
 */
PROCEDURE GetAggregateDetails(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_sid						IN	scenario_run_val.ind_sid%TYPE,
	in_region_sid					IN	scenario_run_val.region_sid%TYPE,
	in_start_dtm					IN	scenario_run_val.period_start_dtm%TYPE,
	in_end_dtm						IN	scenario_run_val.period_end_dtm%TYPE,
	out_val_cur						OUT	SYS_REFCURSOR,
	out_child_cur					OUT	SYS_REFCURSOR
);

/**
 * Get data from val filtered by ind/region/time
 * 
 * @param in_scenario_run_sid	The scenario run to use
 * @param in_ind_or_region			'ind' for filter by indicator, 'region' for filter by region
 * @param in_sid					ind/region tree root
 * @param in_from_dtm				Start date to filter by
 * @param in_to_dtm					End date to filter by
 * @param in_filter_by				ind/region to restrict to
 * @param in_get_aggregates			1 to fetch aggregates
 * @param in_get_stored_calc_values	1 to fetch stored calc values
 * @param out_cur					The filtered data
 */
PROCEDURE GetBaseDataFiltered(
	in_scenario_run_sid				IN	scenario_run_val.scenario_run_sid%TYPE,
	in_ind_or_region				IN	VARCHAR2,
	in_sid							IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by      				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetDelegationIndsAndRegions(
	in_app_sid						IN	sheet.app_sid%TYPE,
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSheetValues(
	in_app_sid						IN	sheet.app_sid%TYPE,
	in_sheet_ids					IN	security_pkg.T_SID_IDS,
	in_ind_sids						IN	security_pkg.T_SID_IDS,	
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_start_dtm					OUT	sheet.start_dtm%TYPE,
	out_end_dtm						OUT	sheet.end_dtm%TYPE,
    out_val_cur						OUT	SYS_REFCURSOR
);

END scenario_run_pkg;
/
