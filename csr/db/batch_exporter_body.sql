CREATE OR REPLACE PACKAGE BODY CSR.batch_exporter_pkg
IS

PROCEDURE CreateBatchedExport (
	in_batch_job_type_id		IN	batch_job.batch_job_type_id%TYPE,
	in_settings_xml				IN	batch_job_batched_export.settings_xml%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_desc						batch_job.description%TYPE;
BEGIN

	-- Get the label of the exporter to use as the batch job description
	SELECT label
	  INTO v_desc
	  FROM batched_export_type
	 WHERE batch_job_type_id = in_batch_job_type_id;
	
	--Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => in_batch_job_type_id,
		in_description => v_desc,
		in_total_work => 1,
		out_batch_job_id => out_batch_job_id);
	
	--Write settings table entry
	INSERT INTO batch_job_batched_export
		(batch_job_id, settings_xml)
	VALUES
		(out_batch_job_id, in_settings_xml);

END;

PROCEDURE GetJobDetails (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT bjbe.batch_job_id, bjbe.settings_xml, bet.batch_job_type_id, bet.label type_label, bet.assembly
		  FROM batch_job_batched_export bjbe
		  JOIN batch_job bj ON bj.batch_job_id = bjbe.batch_job_id
		  JOIN batched_export_type bet ON bj.batch_job_type_id = bet.batch_job_type_id
		 WHERE bjbe.batch_job_id = in_batch_job_id;

END;

PROCEDURE GetJobForAutomatedClass (
	in_automated_class_sid		IN	NUMBER,
	in_batch_job_id				IN	NUMBER,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT in_batch_job_id, settings.settings_xml, bet.batch_job_type_id, bet.label type_label, bet.assembly, convert_to_dsv, primary_delimiter, secondary_delimiter, include_first_row, aec.include_headings
		  FROM auto_exp_batched_exp_settings settings
		  JOIN batched_export_type bet ON bet.batch_job_type_id = settings.batched_export_type_id
		  JOIN automated_export_class aec ON settings.automated_export_class_sid = aec.automated_export_class_sid
		 WHERE settings.automated_export_class_sid = in_automated_class_sid;
END;

PROCEDURE SetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	in_blob						IN 	BLOB,
	in_file_name				IN	batch_job_batched_export.file_name%TYPE
)
AS
BEGIN

	UPDATE batch_job_batched_export
	   SET file_blob = in_blob,
		   file_name = in_file_name
	 WHERE batch_job_id = in_batch_job_id;

END;

/*
	Only the requesting user or a super admin can download the file. Templated reports has an additonal
	capability to allow this, which can be added if needed (eg if site admins wanted to be able to download
	them all).
*/
FUNCTION SecCheckFile(
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE
) RETURN NUMBER
AS
	v_requested_by			batch_job.requested_by_user_sid%TYPE;
BEGIN

	IF csr_user_pkg.IsSuperAdmin = 1 THEN
		RETURN 1;
	END IF;
	
	SELECT requested_by_user_sid
	  INTO v_requested_by
	  FROM batch_job
	 WHERE batch_job_id = in_batch_job_id;
	
	IF v_requested_by = SYS_CONTEXT('SECURITY', 'SID') THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;

END;

PROCEDURE GetFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF batch_exporter_pkg.SecCheckFile(in_batch_job_id) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing file');
	END IF;

	OPEN out_cur FOR
		SELECT file_blob, file_name
		  FROM batch_job_batched_export
		 WHERE batch_job_id = in_batch_job_id;

END;

PROCEDURE ScheduledFileClearUp
AS
	v_expiry_date	batch_job.completed_dtm%TYPE;
BEGIN

	--Any batch job exports before this date will have their blob data cleared.
	v_expiry_date := sysdate - DAYS_TO_KEEP_FILES;

	FOR r IN (
		SELECT bj.batch_job_id bjid
		  FROM batch_job bj
		  JOIN batch_job_batched_export bjbe on bj.batch_job_id = bjbe.batch_job_id
		 WHERE bj.batch_job_type_id IN (
				SELECT batch_job_type_id
				  FROM batched_export_type
			)
		   AND bjbe.file_blob IS NOT NULL
		   AND bj.completed_dtm < v_expiry_date
    ) 
	LOOP
		UPDATE batch_job_batched_export
		   SET file_blob = NULL
	     WHERE batch_job_id = r.bjid;
		 
		UPDATE batch_job
		   SET result     = 'Export expired', 
			   result_url = NULL
	     WHERE batch_job_id = r.bjid;
	END LOOP;

END;

END;
/