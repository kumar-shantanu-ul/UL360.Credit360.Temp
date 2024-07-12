CREATE OR REPLACE PACKAGE CSR.batch_exporter_pkg AS

DAYS_TO_KEEP_FILES					CONSTANT NUMBER := 90;

PROCEDURE CreateBatchedExport (
	in_batch_job_type_id		IN	batch_job.batch_job_type_id%TYPE,
	in_settings_xml				IN	batch_job_batched_export.settings_xml%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetJobDetails (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetJobForAutomatedClass (
	in_automated_class_sid		IN	NUMBER,
	in_batch_job_id				IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	in_blob						IN 	BLOB,
	in_file_name				IN	batch_job_batched_export.file_name%TYPE
);

PROCEDURE GetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE ScheduledFileClearUp;

END;
/
