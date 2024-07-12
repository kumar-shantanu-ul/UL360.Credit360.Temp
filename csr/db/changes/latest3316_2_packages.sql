------------ csr.temp_meter_monitor_pkg --------------------------

CREATE OR REPLACE PACKAGE csr.temp_meter_monitor_pkg IS

RAW_DATA_STATUS_RETRY			CONSTANT NUMBER(10) := 2;

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

END temp_meter_monitor_pkg;
/


CREATE OR REPLACE PACKAGE BODY csr.temp_meter_monitor_pkg IS

PROCEDURE Enqueue(
	in_batch_job_type_id			IN	batch_job.batch_job_type_id%TYPE,
	in_description					IN	batch_job.description%TYPE DEFAULT NULL,
	in_email_on_completion			IN	batch_job.email_on_completion%TYPE DEFAULT 0,
	in_total_work					IN	batch_job.total_work%TYPE DEFAULT 0,
	in_requesting_user				IN  batch_job.requested_by_user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID'),
	in_requesting_company			IN  batch_job.requested_by_company_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_in_order_group				IN	batch_job.in_order_group%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_priority						batch_job.priority%TYPE;
BEGIN
	SELECT NVL(bjtac.priority, bjt.priority) priority
	  INTO v_priority
	  FROM batch_job_type bjt
	  LEFT JOIN batch_job_type_app_cfg bjtac ON bjt.batch_job_type_id = bjtac.batch_job_type_id
	 WHERE bjt.batch_job_type_id = in_batch_job_type_id;

	-- no security: this is a utility function that other code should call, and that
	-- code should be doing the security checks
	INSERT INTO batch_job
		(batch_job_id, description, batch_job_type_id, email_on_completion, total_work,
		 requested_by_user_sid, requested_by_company_sid, priority, in_order_group)
	VALUES
		(batch_job_id_seq.nextval, in_description, in_batch_job_type_id, in_email_on_completion,
		 in_total_work, in_requesting_user, in_requesting_company, v_priority, in_in_order_group)
	RETURNING
		batch_job_id INTO out_batch_job_id;
END;

PROCEDURE AuditRawDataChange(
	in_meter_raw_data_id		IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_text						IN	meter_raw_data_log.log_text%TYPE,
	in_mime_type				IN	meter_raw_data_log.mime_type%TYPE,
	in_file_name				IN	meter_raw_data_log.file_name%TYPE,
	in_data						IN	meter_raw_data_log.data%TYPE
)
AS
BEGIN
	INSERT INTO meter_raw_data_log (meter_raw_data_id, log_id, log_text, data)
	VALUES (in_meter_raw_data_id, meter_raw_data_log_id_seq.NEXTVAL, in_text, in_data);
END;

PROCEDURE AuditRawDataChange(
	in_meter_raw_data_id		IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_text						IN	meter_raw_data_log.log_text%TYPE
)
AS
BEGIN
	AuditRawDataChange(
		in_meter_raw_data_id,
		in_text,
		NULL, NULL, NULL
	);
END;

PROCEDURE UpdateLatestFileData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_file_name					IN	meter_raw_data.file_name%TYPE,
	in_mime_type					IN	meter_raw_data.mime_type%TYPE,
	in_new_data						IN	meter_raw_data.data%TYPE
)
AS
BEGIN
	IF in_new_data IS NOT NULL THEN

		UPDATE meter_raw_data
		   SET original_mime_type = mime_type,
		       original_file_name = file_name,
		       original_data = data
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = in_meter_raw_data_id
  		   AND original_data IS NULL;

		UPDATE meter_raw_data
		   SET file_name = NVL(in_file_name, file_name),
		       mime_type = NVL(in_mime_type, mime_type),
		       data = in_new_data
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = in_meter_raw_data_id;

  		AuditRawDataChange(
			in_meter_raw_data_id,
			'Latest raw data file updated',
			in_mime_type,
			in_file_name,
			in_new_data
		);
  	END IF;
END;

PROCEDURE INTERNAL_QueueRawDataImportJob(
	in_raw_data_source_id	IN	meter_raw_data_source.raw_data_source_id%TYPE DEFAULT NULL,
	in_meter_raw_data_id	IN	meter_raw_data_import_job.meter_raw_data_id%TYPE DEFAULT NULL,
	out_batch_job_id		OUT	meter_raw_data_import_job.batch_job_id%TYPE
)
AS
	v_raw_data_source_id	meter_raw_data_source.raw_data_source_id%TYPE := in_raw_data_source_id;
BEGIN
	IF v_raw_data_source_id IS NULL AND in_meter_raw_data_id IS NOT NULL THEN
		SELECT raw_data_source_id
		  INTO v_raw_data_source_id
		  FROM meter_raw_data
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = in_meter_raw_data_id;
	END IF;

	Enqueue(
		in_in_order_group => 'RAW_DATA_SOURCE_ID_' || v_raw_data_source_id,
		in_batch_job_type_id => csr.batch_job_pkg.JT_METER_RAW_DATA,
		out_batch_job_id => out_batch_job_id
	);

	IF in_raw_data_source_id IS NOT NULL OR in_meter_raw_data_id IS NOT NULL THEN
		INSERT INTO meter_raw_data_import_job (batch_job_id, raw_data_source_id, meter_raw_data_id)
		VALUES (out_batch_job_id, in_raw_data_source_id, in_meter_raw_data_id);
	END IF;
END;

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	in_file_name					IN	meter_raw_data.file_name%TYPE,
	in_mime_type					IN	meter_raw_data.mime_type%TYPE,
	in_new_data						IN	meter_raw_data.data%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_batch_job_id					batch_job.batch_job_id%TYPE;
	v_automated_import_instance_id	automated_import_instance.automated_import_instance_id%TYPE;
BEGIN
	-- Some sort of security check!
	IF NOT csr_data_pkg.CheckCapability('Manage meter readings') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'No manage meter readings capability');
	END IF;

	-- Is this a normal real-time meter resubmission or is it an automated import
	SELECT automated_import_instance_id
	  INTO v_automated_import_instance_id
	  FROM meter_raw_data
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_raw_data_id = in_meter_raw_data_id;

	AuditRawDataChange(
		in_meter_raw_data_id,
		'Raw data resubmitted'
	);

	-- Submint a new data file
	UpdateLatestFileData(
		in_meter_raw_data_id,
		in_file_name,
		in_mime_type,
		in_new_data
	);

	-- XXX: We no longer get urjanet data files (with duff regions) in the meter_raw_data table.
	UPDATE meter_raw_data
	   SET status_id = RAW_DATA_STATUS_RETRY
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = in_meter_raw_data_id;

		-- Clear down old errors here as we're reprocessing the file
		-- (there's no good place to clear them down just before rocessing starts)
		DELETE FROM meter_raw_data_error
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_raw_data_id = in_meter_raw_data_id;

  		-- Clear down old errors here as we're reprocessing the file
  		-- (there's no good place to clear them down just before processing starts)
  		DELETE FROM meter_raw_data_error
  		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
  		   AND meter_raw_data_id = in_meter_raw_data_id;

	AuditRawDataChange(
		in_meter_raw_data_id,
		'Status set to retry'
	);

	-- Create raw batch job to reprocess the raw data
	INTERNAL_QueueRawDataImportJob(
		in_meter_raw_data_id	=> in_meter_raw_data_id,
		out_batch_job_id		=> v_batch_job_id
	);

	OPEN out_cur FOR
		SELECT v_batch_job_id batch_job_id, 
			v_automated_import_instance_id automated_import_instance_id
		  FROM DUAL;
END;

PROCEDURE ResubmitRawData(
	in_meter_raw_data_id			IN	meter_raw_data.meter_raw_data_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	ResubmitRawData(
		in_meter_raw_data_id,
		NULL, NULL, NULL, -- No file update
		out_cur
	);
END;

END temp_meter_monitor_pkg;
/