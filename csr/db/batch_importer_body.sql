CREATE OR REPLACE PACKAGE BODY CSR.batch_importer_pkg
IS

PROCEDURE CreateBatchedImport (
	in_batch_job_type_id		IN	batch_job_type.batch_job_type_id%TYPE,
	in_settings_xml				IN	batch_job_batched_import.settings_xml%TYPE,
	in_blob						IN	BLOB,
	in_file_name				IN	batch_job_batched_import.file_name%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_desc						batch_job.description%TYPE;
BEGIN

	-- Get the label of the importer to use as the batch job description
	SELECT label
	  INTO v_desc
	  FROM batched_import_type
	 WHERE batch_job_type_id = in_batch_job_type_id;
	
	--Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => in_batch_job_type_id,
		in_description => v_desc,
		in_total_work => 1,
		out_batch_job_id => out_batch_job_id);
	
	--Write settings table entry
	INSERT INTO batch_job_batched_import
		(batch_job_id, settings_xml, file_blob, file_name)
	VALUES
		(out_batch_job_id, in_settings_xml, in_blob, in_file_name);

END;

PROCEDURE GetJobDetails (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT bjbi.batch_job_id, bjbi.settings_xml, bit.batch_job_type_id, bit.label type_label, bit.assembly, bjbi.file_name
		  FROM batch_job_batched_import bjbi
		  JOIN batch_job bj ON bj.batch_job_id = bjbi.batch_job_id
		  JOIN batched_import_type bit ON bj.batch_job_type_id = bit.batch_job_type_id
		 WHERE bjbi.batch_job_id = in_batch_job_id;

END;

PROCEDURE SetErrorFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	in_blob						IN 	BLOB,
	in_file_name				IN	batch_job_batched_import.file_name%TYPE
)
AS
BEGIN

	UPDATE batch_job_batched_import
	   SET error_file_blob = in_blob,
		   error_file_name = in_file_name
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

	IF batch_importer_pkg.SecCheckFile(in_batch_job_id) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing file');
	END IF;

	OPEN out_cur FOR
		SELECT file_blob, file_name
		  FROM batch_job_batched_import
		 WHERE batch_job_id = in_batch_job_id;

END;

PROCEDURE GetErrorFile (
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	IF batch_importer_pkg.SecCheckFile(in_batch_job_id) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing file');
	END IF;

	OPEN out_cur FOR
		SELECT error_file_blob file_blob, error_file_name file_name
		  FROM batch_job_batched_import
		 WHERE batch_job_id = in_batch_job_id;

END;

PROCEDURE ScheduledFileClearUp
AS
	v_expiry_date	batch_job.completed_dtm%TYPE;
BEGIN

	--Any batch job imports before this date will have their blob data cleared.
	v_expiry_date := sysdate - DAYS_TO_KEEP_FILES;

	FOR r IN (
		SELECT bj.batch_job_id bjid
		  FROM batch_job bj
		  JOIN batch_job_batched_import bjbi on bj.batch_job_id = bjbi.batch_job_id
		 WHERE bj.batch_job_type_id IN (
				SELECT batch_job_type_id
				  FROM batched_import_type
			)
		   AND bjbi.file_blob IS NOT NULL
		   AND bj.completed_dtm < v_expiry_date
	) 
	LOOP
		UPDATE batch_job_batched_import
		   SET file_blob = NULL,
		       error_file_blob = NULL
		 WHERE batch_job_id = r.bjid;
		 
		UPDATE batch_job
		   SET result     = 'Import expired', 
			   result_url = NULL
	     WHERE batch_job_id = r.bjid;
	END LOOP;

END;

END;
/