CREATE OR REPLACE PACKAGE CSR.stored_calc_datasource_pkg AS

-- Progress phases
PHASE_IDLE							CONSTANT NUMBER := 0;
PHASE_GET_DATA						CONSTANT NUMBER := 1;
PHASE_AGGREGATE_UP					CONSTANT NUMBER := 2;
PHASE_AGGREGATE_DOWN				CONSTANT NUMBER := 3;
PHASE_CALCULATE						CONSTANT NUMBER := 4;
PHASE_WRITE_DATA					CONSTANT NUMBER := 5;
PHASE_MERGE_DATA					CONSTANT NUMBER := 6;
PHASE_FAILED						CONSTANT NUMBER := 7;

-- Recalculation trigger types
RECALC_TRIGGER_MERGED				CONSTANT NUMBER := 0;
RECALC_TRIGGER_UNMERGED				CONSTANT NUMBER := 1;
RECALC_TRIGGER_MANUAL				CONSTANT NUMBER := 2;

-- Calculation job types
CALC_JOB_TYPE_STANDARD				CONSTANT NUMBER := 0;
CALC_JOB_TYPE_PCT_OWNERSHIP			CONSTANT NUMBER := 1;
CALC_JOB_TYPE_SCENARIO				CONSTANT NUMBER := 2;

-- Data source types
DATA_SOURCE_MERGED					CONSTANT NUMBER := 0;
DATA_SOURCE_UNMERGED				CONSTANT NUMBER := 1;
DATA_SOURCE_CUSTOM_FETCH_SP			CONSTANT NUMBER := 2;
DATA_SOURCE_SCENARIO_RUN			CONSTANT NUMBER := 3;

/**
 * Disable calc job creation until re-enabled, or the session ends
 *
 * @param in_app_sid			Application SID
 */
PROCEDURE DisableJobCreation(
	in_app_sid						IN	calc_job.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

/**
 * Re-enable normal calc job creation
 *
 * @param in_app_sid			Application SID
 */
PROCEDURE EnableJobCreation(
	in_app_sid						IN	calc_job.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
);

/**
 * Add jobs to recalculate a scenario run
 *
 * @param in_app_sid			Application SID
 * @param in_scenario_run_sid	Scenario run
 */
PROCEDURE AddFullScenarioJob(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_scenario_run_sid				IN	calc_job.scenario_run_sid%TYPE,
	in_full_recompute				IN	calc_job.full_recompute%TYPE,
	in_delay_publish_scenario		IN	calc_job.delay_publish_scenario%TYPE
);

/**
 * Queue calculation jobs based on logged changes to val/sheet_val
 */
PROCEDURE QueueCalcJobs;

/**
 * Mark failed calculation jobs has having failed
 */
PROCEDURE MarkFailedJobs;

/**
 * Dequeue a single calc job
 *
 * @param in_calc_job_id			id of the calc job to dequeue
 */
PROCEDURE DequeueCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
);

/**
 * Dequeue a calc job
 *
 * @param in_min_priority			Minimum priority of jobs to fetch
 * @param in_max_priority			Maximum priority of jobs to fetch
 * @param in_queue_name				Name of the queue to dequeue from
 * @param in_host					Name of a single host to fetch jobs for
 * @param out_calc_job_id			id of the calc job to process
 */
PROCEDURE DequeueCalcJob(
	in_min_priority					IN	NUMBER,
	in_max_priority					IN	NUMBER,
	in_queue_name					IN	VARCHAR2,
	in_host							IN	customer.host%TYPE,
	out_calc_job_id					OUT	calc_job.calc_job_id%TYPE
);

/**
 * Get details of a calc job (merged, unmerged, scenario, dates, etc)
 *
 * @param in_calc_job_id			The job to operate on
 * @param out_cur					Job details
 */
PROCEDURE GetCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Mark a failing calc job has having sent a mail to the notification address
 *
 * @param in_calc_job_id			The job to operator on
 */
PROCEDURE MarkNotified(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
);

/**
 * Delete a calc job that has been processed.
 *
 * @param in_calc_job_id			id of the calc job to lock
 */
PROCEDURE DeleteProcessedCalcJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
);

PROCEDURE BeginFileJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_files_cur					OUT	SYS_REFCURSOR
);

PROCEDURE AddScenarioRunVersion(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_scenario_run_sid			OUT	scenario_run.scenario_run_sid%TYPE,
	out_version						OUT	scenario_run.version%TYPE
);

PROCEDURE AddScenarioRunFile(
	in_scenario_run_sid				IN	scenario_run_version_file.scenario_run_sid%TYPE,
	in_version						IN	scenario_run_version_file.version%TYPE,
	in_file_path					IN	scenario_run_version_file.file_path%TYPE
);

PROCEDURE SetScenarioRunFileSHA1(
	in_scenario_run_sid				IN	scenario_run_version_file.scenario_run_sid%TYPE,
	in_version						IN	scenario_run_version_file.version%TYPE,
	in_sha1							IN	scenario_run_version_file.sha1%TYPE
);

PROCEDURE SetScenarioRunVersion(
	in_scenario_run_sid				IN	scenario_run_version_file.scenario_run_sid%TYPE,
	in_version						IN	scenario_run_version_file.version%TYPE
);

PROCEDURE GetCurrentScenarios(
	out_scn_cur						OUT	SYS_REFCURSOR,
	out_snap_cur					OUT	SYS_REFCURSOR
);

PROCEDURE RerunFileJob(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
);

PROCEDURE GetRecalcDates(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_min_date					OUT	DATE,
	out_max_date					OUT	DATE,
	out_min_adj						OUT	NUMBER,
	out_max_adj						OUT	NUMBER
);

PROCEDURE GetTags(
	out_tag_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetLookupTables(
	out_lookup_table_cur			OUT SYS_REFCURSOR,
	out_lookup_table_entry_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetPropertyMetadata(
	out_property_type_cur			OUT	SYS_REFCURSOR,
	out_property_sub_type_cur		OUT	SYS_REFCURSOR,
	out_space_cur					OUT	SYS_REFCURSOR,
	out_meter_ind_cur				OUT	SYS_REFCURSOR,
	out_mgmt_company_cur			OUT	SYS_REFCURSOR,
	out_fund_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetStoredCalcRegionTrees(
	out_tree_cur					OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR,
	out_region_fund_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetStoredCalcValues(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetNormalValues(
	in_start_dtm                    IN  DATE,
    in_end_dtm                      IN  DATE,
	in_scenario_run_sid				IN	SCENARIO_RUN.scenario_run_sid%type,
    out_val_cur                     OUT SYS_REFCURSOR,
    out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR,
	out_var_expl_id_cur				OUT	SYS_REFCURSOR,
    out_var_expl_cur				OUT	SYS_REFCURSOR
);

PROCEDURE INTERNAL_GetUnmergedValues(
	in_unmerged_start_dtm			IN	DATE,
	in_unmerged_end_dtm				IN	DATE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_val_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetUnmergedValues(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetUnmergedNormalValues(
	in_start_dtm                    IN  DATE,
    in_end_dtm                      IN  DATE,
	in_scenario_run_sid				IN	SCENARIO_RUN.scenario_run_sid%type,
    out_val_cur                     OUT SYS_REFCURSOR,
    out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR,
    out_var_expl_id_cur				OUT	SYS_REFCURSOR,
    out_var_expl_cur				OUT	SYS_REFCURSOR    
);

PROCEDURE GetUnmergedLastPeriodValues(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_val_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetUnmergedLPNormalValues(
	in_start_dtm                    IN  DATE,
    in_end_dtm                      IN  DATE,
	in_scenario_run_sid				IN	SCENARIO_RUN.scenario_run_sid%type,
    out_val_cur                     OUT SYS_REFCURSOR,
    out_note_cur					OUT SYS_REFCURSOR,
    out_file_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllIndDetails(
	in_all_inds						IN	NUMBER,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_tag_cur					OUT	SYS_REFCURSOR,
	out_recompute_ind_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIndDependencies(
	in_all_inds						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAggregateChildren(
	in_all_inds						IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetAllGasFactors(
	in_all_inds						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionPctOwnership(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAggregateIndHelperProcs(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAggregateInds(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

-- UNUSED?
-- PROCEDURE GetScenarioValues(
	-- in_start_dtm					IN	DATE,
	-- in_end_dtm						IN	DATE,
    -- out_val_cur						OUT	SYS_REFCURSOR
-- );

PROCEDURE GetOldScenarioValues(
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
    out_val_cur						OUT	SYS_REFCURSOR
);
   
PROCEDURE MergeScenarioValues(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
);

/**
 * Merge values in temp_new_val into the database
 *
 * @param in_max_val_change_id		The maximum value change id to delete up to (for null values)
 */
PROCEDURE MergeValues(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_max_val_changed_dtm			IN	val.changed_dtm%TYPE
);

PROCEDURE RecordProgress(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_phase						IN	calc_job.phase%TYPE,
	in_work_done					IN	calc_job.work_done%TYPE,
	in_total_work					IN	calc_job.total_work%TYPE
);

PROCEDURE RecordProgress(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_work_done					IN	calc_job.work_done%TYPE
);

/**
 * Upserts a calc job for the given data source
 */
PROCEDURE GetOrCreateCalcJob(
	in_app_sid						IN	calc_job.app_sid%TYPE,
	in_calc_job_type				IN	calc_job.calc_job_type%TYPE,
	in_scenario_run_sid				IN	calc_job.scenario_run_sid%TYPE,
	in_start_dtm					IN	calc_job.start_dtm%TYPE,
	in_end_dtm						IN	calc_job.end_dtm%TYPE,
	in_full_recompute				IN	calc_job.full_recompute%TYPE,
	in_delay_publish_scenario		IN	calc_job.delay_publish_scenario%TYPE,
	out_calc_job_id					OUT	calc_job.calc_job_id%TYPE
);

PROCEDURE OnJobCompletion(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
);

PROCEDURE SetCalcJobStats(
	in_calc_job_id					IN	calc_job_stat.calc_job_id%TYPE,
	in_version						IN	calc_job_stat.version%TYPE,
	in_scenario_file_size			IN	calc_job_stat.scenario_file_size%TYPE,
	in_heap_allocated				IN	calc_job_stat.heap_allocated%TYPE,
	in_total_time					IN	calc_job_stat.total_time%TYPE,
	in_fetch_time					IN	calc_job_stat.fetch_time%TYPE,
	in_calc_time					IN	calc_job_stat.calc_time%TYPE,
	in_load_file_time				IN	calc_job_stat.load_file_time%TYPE,
	in_load_metadata_time			IN	calc_job_stat.load_metadata_time%TYPE,
	in_load_values_time				IN	calc_job_stat.load_values_time%TYPE,
	in_load_aggregates_time			IN	calc_job_stat.load_aggregates_time%TYPE,	
	in_scenario_rules_time			IN	calc_job_stat.scenario_rules_time%TYPE,
	in_save_file_time				IN	calc_job_stat.save_file_time%TYPE,
	in_total_values					IN	calc_job_stat.total_values%TYPE,
	in_aggregate_values				IN	calc_job_stat.aggregate_values%TYPE,
	in_calc_values					IN	calc_job_stat.calc_values%TYPE,
	in_normal_values				IN	calc_job_stat.normal_values%TYPE,
	in_external_aggregate_values	IN	calc_job_stat.external_aggregate_values%TYPE,
	in_calcs_run					IN	calc_job_stat.calcs_run%TYPE,
	in_inds							IN	calc_job_stat.inds%TYPE,
	in_regions						IN	calc_job_stat.regions%TYPE
);

PROCEDURE SetCalcJobFetchStat(
	in_calc_job_id					IN	calc_job_fetch_stat.calc_job_id%TYPE,
	in_fetch_sp						IN	calc_job_fetch_stat.fetch_sp%TYPE,
	in_fetch_time					IN	calc_job_fetch_stat.fetch_time%TYPE
);

PROCEDURE TriggerPoll;

PROCEDURE GetAppSettings(
	out_cur							OUT	SYS_REFCURSOR
);

END stored_calc_datasource_pkg;
/
