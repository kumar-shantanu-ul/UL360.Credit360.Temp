CREATE OR REPLACE PACKAGE CSR.meter_alarm_core_stat_pkg IS

PROCEDURE ComputeCoreDayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreSameDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreDayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreSameDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreWeekDayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreWeekendUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreWeekDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreWeekendAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreWeekDayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreWeekendUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreWeekDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreWeekendAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreMondayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreTuesdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreWednesdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreThursdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreFridayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreSaturdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreSundayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreMondayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreTuesdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreWednesdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreThursdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreFridayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreSaturdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreSundayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreMondayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreTuesdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreWednesdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreThursdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreFridayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreSaturdayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreSundayUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeNonCoreMondayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreTuesdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreWednesdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreThursdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreFridayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreSaturdayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreSundayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeCoreDayNormUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeCoreDayNormAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreDayNormUse (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeNonCoreDayNormAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

END meter_alarm_core_stat_pkg;
/