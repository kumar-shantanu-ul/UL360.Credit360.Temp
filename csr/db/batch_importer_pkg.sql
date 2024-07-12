CREATE OR REPLACE PACKAGE CSR.batch_importer_pkg AS

DAYS_TO_KEEP_FILES					CONSTANT NUMBER := 90;

PROCEDURE CreateBatchedImport (
	in_batch_job_type_id		IN	batch_job_type.batch_job_type_id%TYPE,
	in_settings_xml				IN	batch_job_batched_import.settings_xml%TYPE,
	in_blob						IN	BLOB,
	in_file_name				IN	batch_job_batched_import.file_name%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetJobDetails (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SetErrorFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	in_blob						IN 	BLOB,
	in_file_name				IN	batch_job_batched_import.file_name%TYPE
);

PROCEDURE GetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetErrorFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE ScheduledFileClearUp;

END;
/