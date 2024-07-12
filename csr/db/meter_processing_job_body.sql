CREATE OR REPLACE PACKAGE BODY CSR.meter_processing_job_pkg IS

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
)
AS
BEGIN
	BEGIN
		INSERT INTO meter_processing_job (container_id, job_id, local_status, meter_raw_data_id,
			local_result_path, remote_status, upload_uri, result_uri, remote_result_path)
		VALUES (in_container_id, in_job_id, in_local_status, in_meter_raw_data_id, in_local_result_path, 
			in_remote_status, in_upload_uri, in_result_uri, in_remote_result_path);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE meter_processing_job
			   SET local_status = in_local_status,
				   meter_raw_data_id = NVL(in_meter_raw_data_id, meter_raw_data_id),
				   local_result_path = NVL(in_local_result_path, local_result_path),
				   remote_status = NVL(in_remote_status, remote_status),
				   upload_uri = NVL(in_upload_uri, upload_uri),
				   result_uri = NVL(in_result_uri, result_uri),
				   remote_result_path = NVL(in_remote_result_path, remote_result_path)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND container_id = in_container_id
			   AND job_id = in_job_id;
	END;

	IF in_unhide != 0 THEN
		UPDATE meter_processing_job
		   SET hide_until = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND container_id = in_container_id
		   AND job_id = in_job_id; 
	END IF;
END;

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
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	SetJob(
		in_container_id			=> in_container_id,
		in_job_id				=> in_job_id,
		in_meter_raw_data_id	=> in_meter_raw_data_id,
		in_local_status			=> in_local_status,
		in_local_result_path	=> in_local_result_path,
		in_remote_status		=> in_remote_status,
		in_upload_uri			=> in_upload_uri,
		in_result_uri			=> in_result_uri,
		in_remote_result_path	=> in_remote_result_path,
		in_unhide				=> in_unhide
	);

	COMMIT;
END;


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
)
AS
BEGIN
	BEGIN
		INSERT INTO meter_processing_pipeline_info (container_id, job_id, 
			pipeline_status, pipeline_message, pipeline_run_start, pipeline_run_end, pipeline_last_updated,
			pipeline_la_run_id, pipeline_la_name, pipeline_la_status, pipeline_la_errorcode, pipeline_la_errormessage, pipeline_la_errorlog)
		VALUES (in_container_id, in_job_id, in_pipeline_status, in_pipeline_message, in_pipeline_run_start, in_pipeline_run_end, in_pipeline_last_updated,
			in_pipeline_la_run_id, in_pipeline_la_name, in_pipeline_la_status, in_pipeline_la_errorcode, in_pipeline_la_errormessage, in_pipeline_la_errorlog);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE meter_processing_pipeline_info
			   SET pipeline_id = in_pipeline_id,
					pipeline_status = in_pipeline_status,
					pipeline_message = in_pipeline_message,
					pipeline_run_start = in_pipeline_run_start,
					pipeline_run_end = in_pipeline_run_end,
					pipeline_last_updated = in_pipeline_last_updated,
					pipeline_la_run_id = in_pipeline_la_run_id,
					pipeline_la_name = in_pipeline_la_name,
					pipeline_la_status = in_pipeline_la_status,
					pipeline_la_errorcode = in_pipeline_la_errorcode,
					pipeline_la_errormessage = in_pipeline_la_errormessage,
					pipeline_la_errorlog = in_pipeline_la_errorlog
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND container_id = in_container_id
			   AND job_id = in_job_id;
	END;
END;

PROCEDURE SetJobError (
	in_container_id				IN	meter_processing_job.container_id%TYPE,
	in_job_id					IN	meter_processing_job.job_id%TYPE,
	in_message					IN	meter_raw_data_error.message%TYPE
)
AS
	v_meter_raw_data_id			meter_raw_data_error.meter_raw_data_id%TYPE;
	out_error_id				meter_raw_data_error.error_id%TYPE;
BEGIN
	SELECT meter_raw_data_id
	  INTO v_meter_raw_data_id
	  FROM meter_processing_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_id = in_container_id
	   AND job_id = in_job_id;

  	meter_monitor_pkg.LogRawDataError(v_meter_raw_data_id, NULL, in_message, SYSDATE, out_error_id);
END;


PROCEDURE INTERNAL_GetJob (
	in_app_sid				IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, container_id, job_id, meter_raw_data_id, job_dtm, fetch_count, expired_count, last_fetch_dtm, hide_until,
			local_status, local_result_path, remote_status, upload_uri, result_uri, remote_result_path,
			CASE 
				WHEN hide_until IS NULL THEN 0 
				WHEN hide_until < SYSDATE THEN 0 
				ELSE 1 
			END is_hidden
		  FROM meter_processing_job
		 WHERE app_sid = in_app_sid
		   AND container_id = in_container_id
		   AND job_id = in_job_id;
END;

PROCEDURE GetJob (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_GetJob(
		in_container_id	=> in_container_id,
		in_job_id		=> in_job_id,
		out_cur			=> out_cur
	);
END;

PROCEDURE GetAllJobs (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, container_id, job_id, meter_raw_data_id, job_dtm, fetch_count, expired_count, last_fetch_dtm, hide_until,
			local_status, local_result_path, remote_status, upload_uri, result_uri, remote_result_path,
			CASE 
				WHEN hide_until IS NULL THEN 0 
				WHEN hide_until < SYSDATE THEN 0 
				ELSE 1 
			END is_hidden
		  FROM meter_processing_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ORDER BY job_dtm;
END;

PROCEDURE SetHideTime (
	in_timeout				IN	NUMBER		DEFAULT 60,
	in_timeout_unit			IN	VARCHAR2	DEFAULT 'SECOND',
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	Int_SetHideTime(
		in_timeout				=> in_timeout,
		in_timeout_unit			=> in_timeout_unit,
		in_container_id			=> in_container_id,
		in_job_id				=> in_job_id
	);

	COMMIT;
END;

PROCEDURE Int_SetHideTime (
	in_timeout				IN	NUMBER		DEFAULT 60,
	in_timeout_unit			IN	VARCHAR2	DEFAULT 'SECOND',
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
)
AS
BEGIN
	UPDATE meter_processing_job
	   SET hide_until = SYSDATE + NUMTODSINTERVAL(in_timeout, in_timeout_unit)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_id = in_container_id
	   AND job_id = in_job_id;
END;

PROCEDURE ClearHideTime (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE meter_processing_job
	   SET hide_until = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_id = in_container_id
	   AND job_id = in_job_id;

	COMMIT;
END;

-- Get the next job, hiding it for a given time
PROCEDURE GetNextJob (
	in_status				IN	meter_processing_job.local_status%TYPE,
	in_timeout				IN	NUMBER		DEFAULT 60,
	in_timeout_unit			IN	VARCHAR2	DEFAULT 'SECOND',
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;

	v_app_sid				security_pkg.T_SID_ID;
	v_container_id			meter_processing_job.container_id%TYPE;
	v_job_id				meter_processing_job.job_id%TYPE;
BEGIN
	BEGIN
		-- Lopp until the first query throws a no data found exception
		LOOP 
			-- Find the next job the caller is interested in
			SELECT app_sid, container_id, job_id
			  INTO v_app_sid, v_container_id, v_job_id
			  FROM (
				SELECT app_sid, container_id, job_id
				  FROM meter_processing_job
				 WHERE local_status = in_status
				   AND ( hide_until IS NULL
				   	OR hide_until <= SYSDATE )
				  ORDER BY job_dtm
			  )
			  WHERE ROWNUM = 1;

			BEGIN
				-- Lock the row (checking the status again 
				-- as it might have changed in the meantime)
				SELECT container_id, job_id
				  INTO v_container_id, v_job_id
				  FROM meter_processing_job
				 WHERE app_sid = v_app_sid
				   AND container_id = v_container_id
				   AND job_id = v_job_id
				   AND local_status = in_status
				FOR UPDATE;

				-- Update job
				UPDATE meter_processing_job
				   SET fetch_count = fetch_count + 1,
				       last_fetch_dtm = SYSDATE,
				       hide_until = SYSDATE + NUMTODSINTERVAL(in_timeout, in_timeout_unit)
				 WHERE app_sid = v_app_sid
				   AND container_id = v_container_id
				   AND job_id = v_job_id;

				-- We got a job, exit the loop
				EXIT;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- There might be more jobs left, 
					-- we just failed to lock this one
					-- ...so we go round again
					v_app_sid := NULL;
					v_container_id := NULL;
					v_job_id := NULL;
			END;

		END LOOP;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- No jobs left
			v_app_sid := NULL;
			v_container_id := NULL;
			v_job_id := NULL;
	END;

	-- Call this even if no jobs are left so
	-- as to ensure a valid cursor is returned
	INTERNAL_GetJob(
		in_app_sid			=> v_app_sid,
		in_container_id		=> v_container_id,
		in_job_id			=> v_job_id,
		out_cur				=> out_cur
	);

	COMMIT;
END;


-- Called frequently from an oracle job
PROCEDURE ExpireJobs
AS
BEGIN
	FOR a IN (
		SELECT DISTINCT app_sid
		  FROM meter_processing_job
	) LOOP
		-- Jobs in either the 
		-- METER_JOB_STATUS_UPLOADING, 
		-- METER_JOB_STATUS_DOWNLOADING or 
		-- METER_JOB_STATUS_UPDATING 
		-- states should be considered expired if they are not hidden
		FOR r IN (
			SELECT container_id, job_id
			  FROM meter_processing_job
			 WHERE app_sid = a.app_sid
			   AND hide_until <= SYSDATE
			   AND local_status IN (
			   		METER_JOB_STATUS_UPLOADING,
			   		METER_JOB_STATUS_DOWNLOADING,
			   		METER_JOB_STATUS_UPDATING
			   )
			FOR UPDATE
		) LOOP
			UPDATE meter_processing_job
			   SET expired_count = expired_count + 1,
			       local_status = CASE local_status
			       		-- Revert job local status
			       		WHEN METER_JOB_STATUS_UPLOADING THEN METER_JOB_STATUS_PENDING
			       		WHEN METER_JOB_STATUS_DOWNLOADING THEN METER_JOB_STATUS_RESULTS
			       		WHEN METER_JOB_STATUS_UPDATING THEN METER_JOB_STATUS_HAVEFILES
			       		ELSE local_status
			       END
			 WHERE app_sid = a.app_sid
			   AND container_id = r.container_id
			   AND job_id = r.job_id;
		END LOOP;
	END LOOP;
END;

PROCEDURE MergeResults (
	in_container_id			IN	meter_processing_job.container_id%TYPE,
	in_job_id				IN	meter_processing_job.job_id%TYPE
)
AS
BEGIN
	-- Merge all serial IDs we can match to a region (matched via all_meter table)
	MERGE INTO meter_live_data mld
	USING (
		SELECT m.region_sid, b.meter_bucket_id, ip.meter_input_id, ag.aggregator, pr.priority, ex.start_dtm,
			CASE
				WHEN ex.uom IS NULL THEN ex.val
				WHEN DECODE(iai.measure_conversion_id, ex_conv.measure_conversion_id, 1, NULL) = 1 THEN ex.val
				WHEN iai.measure_conversion_id IS NULL AND ex_conv.measure_conversion_id IS NOT NULL THEN measure_pkg.UNSEC_GetBaseValue(ex.val, ex_conv.measure_conversion_id, ex.start_dtm)
				WHEN iai.measure_conversion_id IS NOT NULL AND ex_conv.measure_conversion_id IS NULL THEN measure_pkg.UNSEC_GetConvertedValue(ex.val, iai.measure_conversion_id, ex.start_dtm)
				ELSE measure_pkg.UNSEC_GetConvertedValue(measure_pkg.UNSEC_GetBaseValue(ex.val, ex_conv.measure_conversion_id, ex.start_dtm), iai.measure_conversion_id, ex.start_dtm)
			END val,
			CASE
				WHEN b.is_months != 0 THEN ADD_MONTHS(ex.start_dtm, b.duration)
				WHEN b.is_hours !=0 THEN ex.start_dtm + NUMTODSINTERVAL(b.duration, 'HOUR')
				WHEN b.is_minutes != 0 THEN ex.start_dtm + NUMTODSINTERVAL(b.duration, 'MINUTE')
				WHEN b.period_set_id IS NOT NULL THEN period_pkg.TruncToPeriodEnd(b.period_set_id, ex.start_dtm)
				ELSE NULL 
			END end_dtm
		  FROM ext_meter_data ex
		  JOIN all_meter m ON m.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND NVL(m.urjanet_meter_id, m.reference) = ex.serial_id
		  JOIN meter_bucket b ON b.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND LOWER(b.description) = LOWER(ex.bucket_name)
		  JOIN meter_input ip ON ip.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND LOWER(ip.lookup_key) = LOWER(ex.input_key)
		  JOIN meter_data_priority pr ON pr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND pr.lookup_key = 'HI_RES' -- For now
		  JOIN meter_input_aggregator ag ON ag.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ag.meter_input_id = ip.meter_input_id AND ag.aggregator = 'SUM' -- Decide how to deal with this in the processor
		  JOIN meter_input_aggr_ind iai ON iai.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND iai.region_sid = m.region_sid AND iai.meter_input_id = ag.meter_input_id AND iai.aggregator = ag.aggregator
		  LEFT JOIN measure ex_mes ON ex_mes.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ex_mes.measure_sid = iai.measure_sid AND LOWER(NVL(ex_mes.lookup_key, ex_mes.description)) = LOWER(ex.uom)
		  LEFT JOIN measure_conversion ex_conv ON ex_conv.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ex_conv.measure_sid = iai.measure_sid AND LOWER(NVL(ex_conv.lookup_key, ex_conv.description)) = LOWER(ex.uom)
		 WHERE ex.container_id = in_container_id
		   AND ex.job_id = in_job_id
	) x
	ON (
			mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND mld.region_sid = x.region_sid
		AND mld.meter_bucket_id = x.meter_bucket_id
		AND mld.meter_input_id = x.meter_input_id
		AND mld.aggregator = x.aggregator
		AND mld.priority = x.priority
		AND mld.start_dtm = x.start_dtm
	)
	 WHEN MATCHED THEN UPDATE
		SET end_dtm = x.end_dtm,
			consumption = x.val,
			modified_dtm = SYSDATE
	 WHEN NOT MATCHED THEN
	 	INSERT (region_sid, meter_bucket_id, meter_input_id, aggregator, priority, start_dtm, end_dtm, consumption, meter_data_id)
	 	VALUES (x.region_sid, x.meter_bucket_id, x.meter_input_id, x.aggregator, 
		 		x.priority, x.start_dtm, x.end_dtm, x.val, csr_data_pkg.JITNextVal('meter_data_id_seq'))
	;

	-- "export system values" (write indicator values) 
	-- for each serial ID we can match to a region
	FOR r IN (
		SELECT m.region_sid, MIN(x.start_dtm) min_dtm, MAX(x.end_dtm) max_dtm
		  FROM (
			SELECT ex.serial_id, ex.start_dtm, 
				CASE
					WHEN b.is_months != 0 THEN ADD_MONTHS(ex.start_dtm, b.duration)
					WHEN b.is_hours !=0 THEN ex.start_dtm + NUMTODSINTERVAL(b.duration, 'HOUR')
					WHEN b.is_minutes != 0 THEN ex.start_dtm + NUMTODSINTERVAL(b.duration, 'MINUTE')
					WHEN b.period_set_id IS NOT NULL THEN period_pkg.TruncToPeriodEnd(b.period_set_id, ex.start_dtm)
					ELSE NULL
				END end_dtm
			  FROM ext_meter_data ex
			  JOIN meter_bucket b ON b.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND b.description = ex.bucket_name
		  ) x
		  JOIN all_meter m ON m.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND NVL(m.urjanet_meter_id, m.reference) = x.serial_id
		  GROUP BY m.region_sid
	) LOOP
		meter_monitor_pkg.ExportSystemValues(
			in_region_sid	=> r.region_sid,
			in_start_dtm	=> r.min_dtm,
			in_end_dtm		=> r.max_dtm
		);
	END LOOP;

END;

END meter_processing_job_pkg;
/
