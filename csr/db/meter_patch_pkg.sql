CREATE OR REPLACE PACKAGE CSR.meter_patch_pkg IS

-- BEGIN TESTING ONLY

PROCEDURE INTERNAL_RmvRedntAutoPatches
;

PROCEDURE INTERNAL_FindDataGaps
;

-- Functions exposed for testing only
PROCEDURE INT_InsertConsumptionNoDup(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	security_pkg.T_SID_ID,
	in_this_priority		IN	meter_data_priority.priority%TYPE,
	in_last_priority		IN	meter_data_priority.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

-- END TESTING ONLY


PROCEDURE ProcessBatchJob(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_result_desc		OUT	batch_job.result%TYPE,
	out_result_url		OUT	batch_job.result_url%TYPE
);

PROCEDURE AddPatchDataBatch(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtms		IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_end_dtms			IN	meter_monitor_pkg.T_DATE_ARRAY,
	in_period_types		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals				IN	meter_monitor_pkg.T_VAL_ARRAY,
	in_notes			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddPatchDataBatch(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	in_period_type		IN	meter_patch_batch_data.period_type%TYPE,
	in_val				IN	meter_patch_data.consumption%TYPE,
	in_note				IN	audit_log.description%TYPE,
	out_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE AddPatchDataImmediate(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	in_val				IN	meter_patch_data.consumption%TYPE
);

PROCEDURE RemovePatchDataRangeImmediate(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE
);

PROCEDURE RemovePatchDataRangeBatch(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_priority			IN	meter_data_priority.priority%TYPE,
	in_start_dtm		IN	meter_patch_data.start_dtm%TYPE,
	in_end_dtm			IN	meter_patch_data.end_dtm%TYPE,
	out_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE ApplyDataPatches(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_min_dtm				IN	DATE,
	in_max_dtm				IN	DATE
);

PROCEDURE AddAutoPatchJobsForMeter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

PROCEDURE GetAppsToPatch(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindAndPatchDataGaps
;

PROCEDURE AutoCreatePatches(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

-------

PROCEDURE GenericGapFinder(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

PROCEDURE DayOfWeekPatcher(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

PROCEDURE DayOfWeekCostPatcher(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_priority				IN	meter_data_priority.priority%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

PROCEDURE PrepMeterPatchImportRow(
	in_source_row			IN	temp_meter_reading_rows.source_row%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_patch_level			IN	meter_patch_data.priority%TYPE,
	in_meter_input_id		IN	meter_input.meter_input_id%TYPE,
	in_start_dtm			IN	meter_reading.start_dtm%TYPE,
	in_end_dtm				IN	meter_reading.end_dtm%TYPE,
	in_val					IN	meter_reading.val_number%TYPE,
	in_note					IN	audit_log.description%TYPE
);

PROCEDURE ImportPatchRows(
	out_result				OUT	security_pkg.T_OUTPUT_CUR,
	out_jobs				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE INTERNAL_RecomputeMeterData(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE
);

END meter_patch_pkg;
/
