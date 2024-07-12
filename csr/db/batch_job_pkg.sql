CREATE OR REPLACE PACKAGE CSR.batch_job_pkg AS

-- retry a failed job after this long
JOB_RETRY_MINUTES					CONSTANT NUMBER := 10;

-- batch job types
JT_DELEGATION_SYNC					CONSTANT NUMBER := 1;
JT_EXCEL_MODEL_RUN					CONSTANT NUMBER := 2;
JT_AUTO_APPROVE						CONSTANT NUMBER := 3;
JT_STRUCTURE_IMPORT					CONSTANT NUMBER := 6;
JT_CMS_IMPORT						CONSTANT NUMBER := 7;
JT_TEMPLATED_REPORT					CONSTANT NUMBER := 8;
JT_ENERGY_STAR_SHARING_REQ			CONSTANT NUMBER := 9;
JT_METER_EXTRACT					CONSTANT NUMBER := 10;
JT_CHAIN_INVITATION					CONSTANT NUMBER := 11;
JT_HEINEKEN_YEAR_CLOSE				CONSTANT NUMBER := 12;
JT_AUTOMATED_IMPORT					CONSTANT NUMBER := 13;
JT_DELEGATION_COMPLETENESS			CONSTANT NUMBER := 14;
JT_APPROVAL_DASHBOARD				CONSTANT NUMBER := 15;
JT_AUTOMATED_EXPORT					CONSTANT NUMBER := 16;
JT_CASA_MODEL_IMPORT				CONSTANT NUMBER := 17;
-- 18 deleted. Was sheet completeness
JT_METER_PATCH						CONSTANT NUMBER := 19;
JT_HYATT_FORECASTING				CONSTANT NUMBER := 20;
JT_BATCH_PROP_GEOCODE				CONSTANT NUMBER := 21;
JT_R_REPORT							CONSTANT NUMBER := 22;
JT_METER_RECOMPUTE					CONSTANT NUMBER := 23;
JT_METER_TYPE_CHANGE				CONSTANT NUMBER := 24;
JT_LIKE_FOR_LIKE					CONSTANT NUMBER := 25;
--26 deleted. was JT_CHAIN_BSCI
-- 27 deleted. Was batched export.
--28 deleted. was JT_CHAIN_SINGLE_BSCI
-- 29 deleted. Was batched import.
JT_FULL_USER_EXPORT					CONSTANT NUMBER := 30;
JT_FILTERED_USER_EXPORT				CONSTANT NUMBER := 31;
JT_REGION_LIST_EXPORT				CONSTANT NUMBER := 32;
JT_INDICATOR_LIST_EXPORT			CONSTANT NUMBER := 33;
JT_DATA_EXPORT						CONSTANT NUMBER := 34;
JT_REGION_ROLE_MEMBERSHIP_EXP		CONSTANT NUMBER := 35;
JT_REGION_AND_METER_EXPORT			CONSTANT NUMBER := 36;
JT_MEASURE_LIST_EXPORT				CONSTANT NUMBER := 37;
JT_EMISSION_PROFILE_EXPORT			CONSTANT NUMBER := 38;
JT_FACTOR_SET_EXPORT				CONSTANT NUMBER := 39;
JT_INDICATOR_TRANSLATIONS			CONSTANT NUMBER := 40;
JT_REGION_TRANSLATIONS				CONSTANT NUMBER := 41;
JT_CMS_QUICK_CHART_EXPORTER			CONSTANT NUMBER := 42;
JT_CMS_EXPORTER						CONSTANT NUMBER := 43;
JT_FORECASTING_SLOT_EXPORT			CONSTANT NUMBER := 44;
JT_DELEGATION_TRANSLATIONS			CONSTANT NUMBER := 45;
JT_FILTER_LIST_EXPORT				CONSTANT NUMBER := 46;
JT_INDICATOR_TRANSLATIONS_IMP		CONSTANT NUMBER := 47;
JT_REGION_TRANSLATIONS_IMP			CONSTANT NUMBER := 48;
JT_DELEGATION_TRANSLATIONS_IM		CONSTANT NUMBER := 49;
JT_METER_READING_IMPORT				CONSTANT NUMBER := 50;
JT_FORECASTING_SLOT_IMPORT			CONSTANT NUMBER := 51;
JT_FACTOR_SET_IMPORT				CONSTANT NUMBER := 52;
JT_METER_IMPORT_REVERT				CONSTANT NUMBER := 53;
JT_EAT_RAM							CONSTANT NUMBER := 54;
JT_METER_MATCH						CONSTANT NUMBER := 55;
JT_METER_RAW_DATA					CONSTANT NUMBER := 56;
JT_METER_RECOMPUTE_BUCKETS			CONSTANT NUMBER := 57;
JT_DEDUPE_MANUAL_MERGE				CONSTANT NUMBER := 58;
JT_DEDUPE_PROCESS_RECORDS			CONSTANT NUMBER := 60;
JT_PENDING_COMP_PROC_RECS			CONSTANT NUMBER := 61;

JT_COMPANY_GEOCODE					CONSTANT NUMBER := 81;
JT_SECONDARY_TREE_REFRESH			CONSTANT NUMBER := 84;

JT_DATA_BUCKET_AGG_IND				CONSTANT NUMBER := 93;
JT_ANONYMISE_USERS					CONSTANT NUMBER := 96;

/**
 * Queue a batch job for processing
 *
 * @param in_batch_job_type_id			The type of the job to queue
 * @param in_description				A description of the job (used in the view of submitted jobs)
 * @param in_email_on_completion		True to send a mail to the requesting user when the job is complete
 * @param in_total_work					Total work that the job will do
 * @in_requesting_user					The user requesting the job. Defaults to the logged on user.
 * @in_requesting_company				The chain company requesting the job. Defaults to the company of
 * 										the logged on user.
 * @param out_batch_job_id				Id of the queued job
 */
PROCEDURE Enqueue(
	in_batch_job_type_id			IN	batch_job.batch_job_type_id%TYPE,
	in_description					IN	batch_job.description%TYPE DEFAULT NULL,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE DEFAULT 0,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT 0,
	in_requesting_user				IN  batch_job.requested_by_user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_requesting_company			IN  batch_job.requested_by_company_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_in_order_group				IN	batch_job.in_order_group%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
);

/**
 * Called by the batch job processor to take the per host lock
 * This lock is used to detect if jobs that are being dispatched (passed
 * to a worker process) have been lost
 */
PROCEDURE StartDispatcher;

/**
 * Requeue a job
 *
 * This is for developer use -- you can abort failing jobs without losing history
 * by setting batch_job.completed_dtm to SYSDATE, then if desired resubmit the
 * job by calling this function.  DO NOT EXPOSE THIS DIRECTLY TO THE WEBSITE --
 * the function has no security checks.
 *
 * @param in_batch_job_type_id			The type of the job to queue
 */
PROCEDURE Requeue(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
);

/**
 * Set the progress of a batch job -- called from the batch code
 *
 * @param in_batch_job_id			The id of the job
 * @param in_work_done				The amount of work that has been done
 * @param in_total_work				The total amount of work to do
 */
PROCEDURE SetProgress(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_work_done					IN	batch_job.work_done%TYPE,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT NULL
);

/**
 * Get the progress of a job
 *
 * @param in_batch_job_id			The job id
 * @param out_cur					Progress details
 */
PROCEDURE GetProgress(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get the progress of multiple jobs
 *
 * @param in_batch_job_ids			The job ids
 * @param out_cur					Progress details
 */
PROCEDURE GetProgresses(
	in_batch_job_ids				IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get details of a job -- called by the batch code
 *
 * @param in_batch_job_id			The id of the job
 * @param out_cur					Job details
 */
PROCEDURE GetDetails(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Start processing a job -- called by the batch code worker process
 *
 * @in_running_by_worker_id			The worker id to use when locking the job
 * @in_running_by_pid				The worker process pid (for ease of killing)
 * @param in_batch_job_id			The id of the job
 * @param out_cur					Job details
 */
PROCEDURE StartProcessing(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_running_by_worker_id			IN	batch_job.running_by_worker_id%TYPE,
	in_running_by_pid				IN	batch_job.running_by_pid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Get all queued jobs ordered by most recent requested date
 *
 * @param in_all_jobs				Return all system jobs (requires the "Manage jobs" capability)
 * @param in_start_row				The first row to fetch
 * @param in_page_size				The size of a page
 * @param out_total_rows			Total jobs
 * @param out_cur					Job details
 */
PROCEDURE GetJobs(
	in_all_jobs						IN	NUMBER,
	in_filter_user_sid				IN	NUMBER,
	in_batch_job_type_id			IN	NUMBER DEFAULT -1,
	in_filter_date_start			IN	DATE,
	in_filter_date_end				IN	DATE,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

/**
 * Mark a job as running -- called by the batch code and the RunOne interactive batch processing
 */
PROCEDURE MarkRunning(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_running_by_worker_id			IN	batch_job.running_by_worker_id%TYPE,
	in_running_by_pid				IN	batch_job.running_by_pid%TYPE
);


/**
 * Mark a job as completed -- called by the batch code
 *
 * @param in_batch_job_id			The id of the job
 * @in_running_by_worker_id			The worker id to use when unlocking the job
 * @param in_result					The job result
 * @param in_result_url				The result url
 * @param in_failed					Whether the job failed (0, 1)
 * @param in_ram_usage				The memory used by the job
 * @param in_cpu_ms					CPU time used by the job
 * @param out_email_on_completion	1 if a completion e-mail should be sent, 0 if not
 */
PROCEDURE MarkCompleted(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_running_by_worker_id			IN	batch_job.running_by_worker_id%TYPE,
	in_result						IN	batch_job.result%TYPE DEFAULT NULL,
	in_result_url					IN	batch_job.result_url%TYPE DEFAULT NULL,
	in_failed						IN	batch_job.failed%TYPE DEFAULT 0,
	in_ram_usage					IN	batch_job.ram_usage%TYPE DEFAULT NULL,
	in_cpu_ms						IN	batch_job.cpu_ms%TYPE DEFAULT NULL,
	out_email_on_completion			OUT	batch_job.email_on_completion%TYPE
);

/**
 * Mark a job as killed due to excessive memory usage -- called by the batch code
 *
 * @param in_batch_job_id			The id of the job
 * @param in_ram_usage				The memory used by the job before it was killed
 * @param in_allow_retry			0 if the job went past the global RAM cap, 1 if not
 */
PROCEDURE MarkKilled(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_ram_usage					IN	batch_job.ram_usage%TYPE,
	in_allow_retry					IN	NUMBER
);

/**
 * Mark a job as killed due to timeout. Will not retry -- called by the batch code
 *
 * @param in_batch_job_id			The id of the job
 */
PROCEDURE MarkTimedOut(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
);

/**
 * Mark a job as failing -- sets the retry delay and unlocks the job
 * Called by the batch job runner
 *
 * @param in_batch_job_id			The id of the job
 */
PROCEDURE MarkFailing(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
);

/**
 * Mark a job as notified as failing -- called by the batch code
 *
 * @param in_batch_job_id			The id of the job
 */
PROCEDURE MarkNotified(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
);

/**
 * Mark failed jobs has having failed
 */
PROCEDURE MarkFailedJobs;

/**
 * Dequeue a job for processing -- called by the batch code
 *
 * @param in_min_priority			Minimum job priority to dequeue
 * @param in_max_priority			Maximum job priority to dequeue
 * @param in_max_ram				Maximum ram the job may use
 * @param in_host					Single host to dequeue jobs for
 * @param out_host					Host for the job to process
 * @param out_batch_job_id			Id of the job to process
 * @param out_ram_usage				Memory used by the last attempt to run the job
 * @param out_ram_estimate			Estimated memory used to run the batch job
 * @param out_timeout_mins			How many minutes the job can run for before timing out
 */
PROCEDURE Dequeue(
	in_min_priority					IN	batch_job.priority%TYPE DEFAULT NULL,
	in_max_priority					IN	batch_job.priority%TYPE DEFAULT NULL,
	in_max_ram						IN	batch_job.ram_usage%TYPE DEFAULT NULL,
	in_host							IN	customer.host%TYPE DEFAULT NULL,
	out_host						OUT	customer.host%TYPE,
	out_batch_job_id				OUT batch_job.batch_job_id%TYPE,
	out_ram_usage					OUT	batch_job.ram_usage%TYPE,
	out_ram_estimate				OUT	batch_job_type.ram_estimate%TYPE,
	out_timeout_mins				OUT batch_job_type.timeout_mins%TYPE
);

/**
 * Request an email on job completion -- called by the batch code
 *
 * @param in_batch_job_id			The id of the job
 * @param in_email_on_completion	1 to e-mail on completion, 0 not to
 * @param out_already_completed		1 if the job has already completed, 0 if not
 */
PROCEDURE SetEmailOnCompletion(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE,
	out_already_completed			OUT	NUMBER
);

/**
 * Get the store procedure to get the blob of output file or null.
 *
 * @param in_batch_job_id			The id of the job
 */
FUNCTION GetFileDataSp(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
)RETURN VARCHAR2;

PROCEDURE GetBatchJobTypesInUse(
	out_cur			OUT	SYS_REFCURSOR
);

-- No security, only called from a dbms_scheduler task to update per app per job stats
PROCEDURE ComputeJobStats;

PROCEDURE SetCustomerTimeoutForType (
	in_batch_job_type_id		NUMBER,
	in_timeout_mins				NUMBER
);

FUNCTION CanRetryJob (
	in_batch_job_id			IN	NUMBER
) 
RETURN NUMBER;

PROCEDURE RetryJob(
	in_batch_job_id			IN	NUMBER
);

FUNCTION CanAbortJob (
	in_batch_job_id			IN	NUMBER
) 
RETURN NUMBER;

PROCEDURE AbortJob(
	in_batch_job_id			IN	NUMBER
);

PROCEDURE GetExtraJobDetails (
	in_batch_job_id			IN	NUMBER,
	out_cur					OUT SYS_REFCURSOR
);

END;
/
