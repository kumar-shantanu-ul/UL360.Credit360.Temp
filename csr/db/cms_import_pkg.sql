CREATE OR REPLACE PACKAGE CSR.CMS_IMPORT_PKG
AS

PROCEDURE SetBatchJob(
	in_file_name		IN	batch_job_cms_import.file_name%TYPE,
	in_file_data		IN	batch_job_cms_import.file_data%TYPE,
	in_table_name		IN	batch_job_cms_import.table_name%TYPE,
	in_region_sid		IN	batch_job_cms_import.region_sid%TYPE,
	in_flow_label		IN	batch_job_cms_import.flow_label%TYPE,
	in_settings_xml		IN	CLOB,
	in_user_sid			IN	batch_job_cms_import.user_sid%TYPE,
	out_batch_job_id	OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateBatchJob(
	in_batch_job_id		IN NUMBER,
	in_failed_data		IN batch_job_cms_import.failed_data%TYPE
);

PROCEDURE MarkBatchJobFinished(
	in_batch_job_id		IN NUMBER
);

PROCEDURE GetBatchJobFailedData(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END;
/