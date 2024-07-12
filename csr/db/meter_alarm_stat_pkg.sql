CREATE OR REPLACE PACKAGE CSR.meter_alarm_stat_pkg IS

PROCEDURE AddStatJobsForMeter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE
);

PROCEDURE GetAppsToCompute (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ComputeStatistics
;

PROCEDURE AssignStatistics (
	in_region_sid		security_pkg.T_SID_ID
);

PROCEDURE GetAppsToRun (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RunComparisons
;

-------------------------------------------------------------------------------

PROCEDURE ComputeDailyUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgDailyUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeSameDayAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeWeekdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgWeekdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeWeekendUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgWeekendUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeThisMonthDailyAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeLastMonthDailyAvg (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeMondayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);
	
PROCEDURE ComputeTuesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeWednesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeThursdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeFridayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeSaturdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeSundayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

PROCEDURE ComputeAvgMondayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgTuesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgWednesdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgThursdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgFridayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgSaturdayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

PROCEDURE ComputeAvgSundayUsage (
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_statistic_id		IN	meter_alarm_statistic.statistic_id%TYPE,
	in_meter_input_id	IN	meter_input.meter_input_id%TYPE,
	in_aggregator		IN	meter_aggregator.aggregator%TYPE,
	in_meter_bucket_id	IN	meter_bucket.meter_bucket_id%TYPE,
	in_start_dtm		IN	meter_alarm_statistic_job.start_dtm%TYPE,
	in_end_dtm			IN	meter_alarm_statistic_job.end_dtm%TYPE
);

-------------------------------------------------------------------------------

END meter_alarm_stat_pkg;
/
