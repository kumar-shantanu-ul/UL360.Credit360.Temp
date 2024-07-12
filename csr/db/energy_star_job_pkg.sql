CREATE OR REPLACE PACKAGE CSR.energy_star_job_pkg IS

-- job types
JOB_TYPE_CONNECT					CONSTANT NUMBER := 0;
JOB_TYPE_SHARE						CONSTANT NUMBER := 1;
JOB_TYPE_PROPERTY					CONSTANT NUMBER := 2;
JOB_TYPE_SPACE						CONSTANT NUMBER := 3;
JOB_TYPE_METER						CONSTANT NUMBER := 4;
JOB_TYPE_REGION						CONSTANT NUMBER := 5;
JOB_TYPE_READONLY_METRICS			CONSTANT NUMBER := 6;

-- job states
JOB_STATE_IDLE						CONSTANT NUMBER := 0;
JOB_STATE_FAILED					CONSTANT NUMBER := 1;
JOB_STATE_RUN						CONSTANT NUMBER := 2;

CANNOT_INSERT_NULL_EXCEPTION	EXCEPTION;
PRAGMA EXCEPTION_INIT(CANNOT_INSERT_NULL_EXCEPTION, -1400);


FUNCTION INTERNAL_GetPropertySid(
    in_region_sid				IN	security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID;

PROCEDURE QueueJobs;

PROCEDURE QueueJobs(
	in_app_sid						IN	security_pkg.T_SID_ID
);

PROCEDURE QueueSingleJob(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_job_type_id					IN	est_job.est_job_type_id%TYPE,
	in_est_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id				IN	est_job.pm_customer_id%TYPE			DEFAULT NULL,
	in_pm_building_id				IN	est_job.pm_building_id%TYPE			DEFAULT NULL,
	in_pm_space_id					IN	est_job.pm_space_id%TYPE			DEFAULT NULL,
	in_pm_meter_id					IN	est_job.pm_meter_id%TYPE			DEFAULT NULL,
	in_region_sid					IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_update_pm_object				IN	est_job.update_pm_object%TYPE		DEFAULT 1,
	out_job_id						OUT	est_job.est_job_id%TYPE
);

PROCEDURE DequeueJob(
	in_host							IN	customer.host%TYPE,
	out_job_id						OUT	est_job.est_job_id%TYPE
);

PROCEDURE GetJob(
	in_job_id						IN	est_job.est_job_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MarkNotified(
	in_est_job_id					IN	est_job.est_job_id%TYPE
);

PROCEDURE DeleteProcessedJob(
	in_job_id						IN	est_job.est_job_id%TYPE
);

PROCEDURE OnRegionChange(
	in_region_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE OnRegionRemoved(
	in_region_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE OnRegionMove(
	in_region_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE OnMeterReadingChange(
	in_meter_sid					IN	security_pkg.T_SID_ID,
	in_meter_reading_id				IN	meter_reading.meter_reading_id%TYPE
);

PROCEDURE OnRegionMetricChange(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_region_metric_val_id			IN	region_metric_val.region_metric_val_id%TYPE
);

PROCEDURE CreateJobsForChildren(
	in_region_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE CreateJobsForChildren(
	in_est_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id				IN	est_job.pm_customer_id%TYPE,
	in_pm_building_id				IN	est_job.pm_building_id%TYPE
);

PROCEDURE DeleteChangeLogs(
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE DeleteChangeLogs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_job.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_job.pm_building_id%TYPE,
	in_pm_space_id				IN	est_job.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_job.pm_meter_id%TYPE		DEFAULT NULL
);

PROCEDURE CreateManualJobs(
	in_prop_region_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetJobs(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteJob(
	in_est_job_id				est_job.est_job_id%TYPE
);

END;
/
