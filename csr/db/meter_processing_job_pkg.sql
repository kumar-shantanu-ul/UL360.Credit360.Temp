CREATE OR REPLACE PACKAGE CSR.meter_processing_job_pkg IS

METER_JOB_STATUS_PENDING		CONSTANT VARCHAR2(48) := 'Pending';
METER_JOB_STATUS_UPLOADING		CONSTANT VARCHAR2(48) := 'Uploading';
METER_JOB_STATUS_SUBMITTED		CONSTANT VARCHAR2(48) := 'Submitted';
METER_JOB_STATUS_RESULTS		CONSTANT VARCHAR2(48) := 'ResultsReady';
METER_JOB_STATUS_DOWNLOADING	CONSTANT VARCHAR2(48) := 'Downloading';
METER_JOB_STATUS_HAVEFILES		CONSTANT VARCHAR2(48) := 'HaveFiles';
METER_JOB_STATUS_UPDATING		CONSTANT VARCHAR2(48) := 'Updating';
METER_JOB_STATUS_COMPLETE		CONSTANT VARCHAR2(48) := 'Complete';
METER_JOB_STATUS_NOTFOUND		CONSTANT VARCHAR2(48) := 'NotFound';


PROCEDURE SetJob (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE,
	in_local_status			IN	meter_processing_job.local_status%TYPE,
	in_meter_raw_data_id	IN	meter_processing_job.meter_raw_data_id%TYPE			DEFAULT NULL,
	in_local_result_path	IN	meter_processing_job.local_result_path%TYPE		DEFAULT NULL,
	in_remote_status		IN	meter_processing_job.remote_status%TYPE			DEFAULT NULL,
	in_upload_uri			IN	meter_processing_job.upload_uri%TYPE			DEFAULT NULL,
	in_result_uri			IN	meter_processing_job.result_uri%TYPE			DEFAULT NULL,
	in_remote_result_path	IN	meter_processing_job.remote_result_path%TYPE	DEFAULT NULL,
	in_unhide				IN	NUMBER	DEFAULT 0
);

PROCEDURE SetJobAutonomous (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE,
	in_local_status			IN	meter_processing_job.local_status%TYPE,
	in_meter_raw_data_id	IN	meter_processing_job.meter_raw_data_id%TYPE			DEFAULT NULL,
	in_local_result_path	IN	meter_processing_job.local_result_path%TYPE		DEFAULT NULL,
	in_remote_status		IN	meter_processing_job.remote_status%TYPE			DEFAULT NULL,
	in_upload_uri			IN	meter_processing_job.upload_uri%TYPE			DEFAULT NULL,
	in_result_uri			IN	meter_processing_job.result_uri%TYPE			DEFAULT NULL,
	in_remote_result_path	IN	meter_processing_job.remote_result_path%TYPE	DEFAULT NULL,
	in_unhide				IN	NUMBER	DEFAULT 0
);

PROCEDURE SetJobInformation (
	in_container_id				IN	meter_processing_pipeline_info.container_id%TYPE,
	in_job_id					IN	meter_processing_pipeline_info.job_id%TYPE,
	in_pipeline_id				IN	meter_processing_pipeline_info.pipeline_id%TYPE,
	in_pipeline_status			IN	meter_processing_pipeline_info.pipeline_status%TYPE,
	in_pipeline_message			IN	meter_processing_pipeline_info.pipeline_message%TYPE,
	in_pipeline_run_start		IN	meter_processing_pipeline_info.pipeline_run_start%TYPE,
	in_pipeline_run_end			IN	meter_processing_pipeline_info.pipeline_run_end%TYPE,
	in_pipeline_last_updated	IN	meter_processing_pipeline_info.pipeline_last_updated%TYPE,
	in_pipeline_la_run_id		IN	meter_processing_pipeline_info.pipeline_la_run_id%TYPE,
	in_pipeline_la_name			IN	meter_processing_pipeline_info.pipeline_la_name%TYPE,
	in_pipeline_la_status		IN	meter_processing_pipeline_info.pipeline_la_status%TYPE,
	in_pipeline_la_errorcode	IN	meter_processing_pipeline_info.pipeline_la_errorcode%TYPE,
	in_pipeline_la_errormessage	IN	meter_processing_pipeline_info.pipeline_la_errormessage%TYPE,
	in_pipeline_la_errorlog		IN	meter_processing_pipeline_info.pipeline_la_errorlog%TYPE
);

PROCEDURE SetJobError (
	in_container_id				IN	meter_processing_job.container_id%TYPE,
	in_job_id					IN	meter_processing_job.job_id%TYPE,
	in_message					IN	meter_raw_data_error.message%TYPE
);

PROCEDURE GetJob (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllJobs (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetHideTime (
	in_timeout				IN	NUMBER		DEFAULT 60,
	in_timeout_unit			IN	VARCHAR2	DEFAULT 'SECOND',
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
);
PROCEDURE Int_SetHideTime (
	in_timeout				IN	NUMBER		DEFAULT 60,
	in_timeout_unit			IN	VARCHAR2	DEFAULT 'SECOND',
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
);

PROCEDURE ClearHideTime (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
);

PROCEDURE GetNextJob (
	in_status				IN	meter_processing_job.local_status%TYPE,
	in_timeout				IN	NUMBER		DEFAULT 60,
	in_timeout_unit			IN	VARCHAR2	DEFAULT 'SECOND',
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ExpireJobs
;

PROCEDURE MergeResults (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
);

END meter_processing_job_pkg;
/
