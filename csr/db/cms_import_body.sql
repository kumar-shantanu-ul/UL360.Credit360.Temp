CREATE OR REPLACE PACKAGE BODY CSR.CMS_IMPORT_PKG
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
)
AS
BEGIN
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_CMS_IMPORT,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_cms_import
	  (batch_job_id, file_name, file_data, table_name, region_sid, flow_label, settings_xml, user_sid)
	  VALUES 
      (out_batch_job_id, in_file_name, in_file_data, in_table_name, in_region_sid, in_flow_label, in_settings_xml, in_user_sid);
END;

PROCEDURE GetBatchJob(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT batch_job_id, file_name, file_data, table_name, region_sid, flow_label, settings_xml, job_finished, CASE WHEN failed_data IS NULL THEN 0 ELSE 1 END failed_rows, user_sid
	  	  FROM batch_job_cms_import
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE UpdateBatchJob(
	in_batch_job_id		IN NUMBER,
	in_failed_data		IN batch_job_cms_import.failed_data%TYPE
)
AS
BEGIN
	UPDATE batch_job_cms_import
	   SET failed_data = in_failed_data
	 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE MarkBatchJobFinished(
	in_batch_job_id		IN NUMBER
)
AS
BEGIN
	UPDATE batch_job_cms_import
	   SET job_finished = 1
	 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE GetBatchJobFailedData(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT nvl(failed_data, file_data) failed_data, file_name
	  	  FROM batch_job_cms_import
		 WHERE batch_job_id = in_batch_job_id;
END;


END;
/