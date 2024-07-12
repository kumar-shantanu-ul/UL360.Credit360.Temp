CREATE OR REPLACE PACKAGE BODY csr.automated_export_pkg AS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	IF in_new_name IS NOT NULL THEN
		UPDATE automated_export_class 
		   SET label = in_new_name 
		 WHERE automated_export_class_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
	v_running	NUMBER;
BEGIN
	-- check it's not running
	SELECT COUNT(*)
	  INTO v_running
	  FROM csr.automated_export_class aec
	  JOIN csr.automated_export_instance aii ON aii.automated_export_class_sid = aec.automated_export_class_sid
	  JOIN csr.batch_job bj  				ON aii.batch_job_id = bj.batch_job_id
	  WHERE aec.automated_export_class_sid  = in_sid_id
	    AND bj.running_on IS NOT NULL;
	
	IF v_running > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_DELETE_CLASS_RUNNING, 'Cannot delete running export.');
	END IF;

	DELETE FROM automated_export_class WHERE automated_export_class_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

PROCEDURE DeleteClass(
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_sid_id);
END;

PROCEDURE AssertPermissionOnExportClass(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('security','act'), in_class_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the automated export class with sid '||in_class_sid);
	END IF;
END;

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_automated_export_inst_id		OUT	automated_export_instance.automated_export_instance_id%TYPE
)
AS
BEGIN

	CreateInstanceAndBatchJob(
		in_automated_export_class_sid		=> in_automated_export_class_sid,
		in_is_preview						=> 0,
		out_automated_export_inst_id		=> out_automated_export_inst_id
	);

END;

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_is_preview						IN	automated_export_instance.is_preview%TYPE,
	out_automated_export_inst_id		OUT	automated_export_instance.automated_export_instance_id%TYPE
)
AS
	v_batch_job_id						batch_job.batch_job_id%TYPE;
BEGIN
	AssertPermissionOnExportClass(in_automated_export_class_sid);

	--Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.jt_automated_export,
		in_description => 'Automated export',
		in_total_work => 1,
		out_batch_job_id => v_batch_job_id);

	SELECT aut_export_inst_id_seq.NEXTVAL
	  INTO out_automated_export_inst_id
	  FROM DUAL;

	INSERT INTO automated_export_instance
		(automated_export_instance_id, automated_export_class_sid, batch_job_id, is_preview)
	VALUES 
		(out_automated_export_inst_id, in_automated_export_class_sid, v_batch_job_id, in_is_preview);
END;

PROCEDURE TriggerInstance(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_instance_id				automated_export_instance.automated_export_instance_id%TYPE;
BEGIN

	IF NOT csr_data_pkg.CheckCapability('Can run additional automated export instances') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to run additional exports.');
	END IF;

	CreateInstanceAndBatchJob(
		in_automated_export_class_sid		=>	in_class_sid,
		in_is_preview						=> 0,
		out_automated_export_inst_id		=> v_instance_id
	);
	
	SELECT batch_job_id
	  INTO out_batch_job_id
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = v_instance_id;

END;

PROCEDURE CreatePreviewInstance(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_instance_id				automated_export_instance.automated_export_instance_id%TYPE;
BEGIN

	IF NOT csr_data_pkg.CheckCapability('Can preview automated exports') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to preview exports.');
	END IF;

	CreateInstanceAndBatchJob(
		in_automated_export_class_sid		=> in_class_sid,
		in_is_preview						=> 1,
		out_automated_export_inst_id		=> v_instance_id
	);
	
	SELECT batch_job_id
	  INTO out_batch_job_id
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = v_instance_id;

END;

PROCEDURE GetJob(
	in_batch_job_id				IN	automated_export_instance.batch_job_id%TYPE,
	out_job_cur					OUT	SYS_REFCURSOR
)
AS
	v_export_class_sid			automated_export_class.automated_export_class_sid%TYPE;
BEGIN

	SELECT automated_export_class_sid
	  INTO v_export_class_sid
	  FROM automated_export_instance
	 WHERE batch_job_id = in_batch_job_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnExportClass(v_export_class_sid);

	OPEN out_job_cur FOR
		SELECT aei.automated_export_instance_id, aec.automated_export_class_sid, aec.label, aec.file_mask, aec.file_mask_date_format, aec.schedule_xml, aec.email_on_error, aec.email_on_success, 
			   aec.output_empty_as, aec.include_headings, aeep.exporter_assembly exporter_plugin, aeep.outputter_assembly outputter_plugin, aefwp.assembly file_writer_plugin, aei.is_preview,
			   aec.enable_encryption, aec.auto_impexp_public_key_id public_key_id
		  FROM csr.automated_export_instance aei
		  JOIN csr.automated_export_class aec 			ON aei.automated_export_class_sid = aec.automated_export_class_sid
		  JOIN csr.auto_exp_exporter_plugin aeep		ON aec.exporter_plugin_id = aeep.plugin_id
		  JOIN csr.auto_exp_file_writer_plugin aefwp 	ON aec.file_writer_plugin_id = aefwp.plugin_id
		 WHERE aei.batch_job_id = in_batch_job_id
		   AND aei.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetInstance(
	in_instance_id				IN	automated_export_instance.batch_job_id%TYPE,
	out_instance_cur			OUT	SYS_REFCURSOR,
	out_message_cur				OUT	SYS_REFCURSOR
)
AS
	v_class_sid					automated_export_class.automated_export_class_sid%TYPE;
BEGIN

	SELECT automated_export_class_sid
	  INTO v_class_sid
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnExportClass(v_class_sid);
	   
	OPEN out_instance_cur FOR
		SELECT automated_export_instance_id, bj.batch_job_id, bj.requested_dtm, bj.completed_dtm, case WHEN bj.completed_dtm IS NULL THEN 'Pending' ELSE nvl(bj.result, 'Unknown') END result_label, aec.automated_export_class_sid, 
			   label, schedule_xml, CASE WHEN aei.payload IS NOT NULL THEN 1 ELSE 0 END has_payload, aei.payload_filename, 0 is_manual, '' lookup_key, is_preview,
			   CASE WHEN debug_log_file IS NULL THEN 0 ELSE 1 END has_debug_log, CASE WHEN session_log_file IS NULL THEN 0 ELSE 1 END has_session_log
		  FROM csr.automated_export_class aec
		  JOIN csr.automated_export_instance aei ON aei.automated_export_class_sid = aec.automated_export_class_sid
		  JOIN csr.batch_job bj ON bj.batch_job_id = aei.batch_job_id
		 WHERE automated_export_instance_id = in_instance_id
		   AND aec.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_message_cur FOR
		SELECT map.message_id, message, severity, msg_dtm message_dtm
		  FROM auto_export_message_map map
		  JOIN auto_impexp_instance_msg msg ON msg.message_id = map.message_id
		 WHERE export_instance_id = in_instance_id
		   AND msg.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
END;

PROCEDURE GetInstance(
	in_class_sid				IN	automated_export_instance.automated_export_class_sid%TYPE,
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_instance_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	AssertPermissionOnExportClass(in_class_sid);
	   
	OPEN out_instance_cur FOR
		 SELECT ei.automated_export_instance_id instance_id,
				ei.automated_export_class_sid class_sid,
				ei.file_generated,
				ei.payload_filename,
				nvl(dbms_lob.getlength(ei.payload), 0) file_bytes,
				ei.is_preview,
				bj.result_url,
				bj.completed_dtm,
				NVL(bj.result, 'Unknown') result_label
		   FROM automated_export_instance ei
		   JOIN batch_job bj ON ei.batch_job_id = bj.batch_job_id
		  WHERE bj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND ei.automated_export_class_sid = in_class_sid
			AND ei.automated_export_instance_id = in_instance_id;
END;

PROCEDURE GetClass(
	in_export_class_sid			IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR,
	out_keys_cur				OUT SYS_REFCURSOR
)
AS
BEGIN

	AssertPermissionOnExportClass(in_export_class_sid);

	OPEN out_cur FOR
		SELECT c.automated_export_class_sid, c.label, c.contains_pii, c.file_mask, c.Schedule_xml, c.last_scheduled_dtm, c.email_on_error, c.email_on_success, c.include_headings,
			   c.output_empty_as, c.file_mask_date_format, c.days_to_retain_payload,
			   c.exporter_plugin_id, ep.plugin_type_id exporter_plugin_type_id,
			   c.file_writer_plugin_id, NVL(ep.dsv_outputter, 0) dsv_outputter, fwp.plugin_type_id file_writer_plugin_type_id, c.enable_encryption, c.auto_impexp_public_key_id public_key_id, c.lookup_key
		  FROM automated_export_class c
		  LEFT JOIN auto_exp_exporter_plugin ep ON ep.plugin_id = c.exporter_plugin_id
		  LEFT JOIN auto_exp_file_writer_plugin fwp ON fwp.plugin_id = c.file_writer_plugin_id
		 WHERE c.automated_export_class_sid = in_export_class_sid
		   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	OPEN out_keys_cur FOR
		SELECT public_key_id, label
		  FROM auto_impexp_public_key
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE GetClassCountByLabel(
	in_label					IN	automated_export_class.label%TYPE,
	out_count					OUT NUMBER
)
AS
BEGIN
	 SELECT COUNT(*) INTO out_count
	   FROM automated_export_class c
	  WHERE c.label = in_label
		AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetClass(
	in_class_sid			IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	OPEN out_cur FOR
		SELECT c.automated_export_class_sid class_sid, c.label, c.schedule_xml schedule, 
		CASE WHEN last_scheduled_dtm IS NOT NULL THEN 
			automated_export_import_pkg.GetNextScheduledDtm(c.schedule_xml, last_scheduled_dtm)
		ELSE
			NULL
		END next_scheduled_run, 
		c.file_mask, c.enable_encryption encrypted, c.contains_pii, p.label exporter_type_label, c.lookup_key
		  FROM automated_export_class c
		  JOIN auto_exp_exporter_plugin p ON c.exporter_plugin_id = p.plugin_id
		 WHERE security_pkg.SQL_IsAccessAllowedSID(v_act_id, c.automated_export_class_sid, security.security_pkg.PERMISSION_READ) = 1
		   AND c.app_sid = v_app_sid
		   AND c.automated_export_class_sid = in_class_sid;
END;

PROCEDURE GetClasses(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	in_lookup_key			IN	automated_export_class.lookup_key%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	OPEN out_cur FOR
		SELECT x.*
		  FROM (
			SELECT c.automated_export_class_sid class_sid, c.label, c.schedule_xml schedule, 
			CASE WHEN last_scheduled_dtm IS NOT NULL THEN 
				automated_export_import_pkg.GetNextScheduledDtm(c.schedule_xml, last_scheduled_dtm)
			ELSE
				NULL
			END next_scheduled_run, 
			c.file_mask, c.enable_encryption encrypted, c.contains_pii, p.label exporter_type_label, c.lookup_key, rownum rn
			  FROM automated_export_class c
			  JOIN auto_exp_exporter_plugin p ON c.exporter_plugin_id = p.plugin_id
			 WHERE security_pkg.SQL_IsAccessAllowedSID(v_act_id, c.automated_export_class_sid, security.security_pkg.PERMISSION_READ) = 1
			   AND c.app_sid = v_app_sid
			   AND (c.lookup_key IS NULL AND in_lookup_key IS NULL 
					OR LOWER(c.lookup_key) = COALESCE(LOWER(in_lookup_key), LOWER(c.lookup_key)))
			   ORDER BY c.automated_export_class_sid
			)x 
		 WHERE x.rn > in_skip
		   AND x.rn < in_skip + in_take + 1;
END;

PROCEDURE GetClassInstances(
	in_automated_export_class_sid		IN	security_pkg.T_SID_ID,
	in_start_row    					IN	NUMBER,
	in_end_row      					IN	NUMBER,
	in_include_preview                  IN  NUMBER,
	in_include_failure                  IN  NUMBER,
	out_cur         					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertPermissionOnExportClass(in_automated_export_class_sid);

	OPEN out_cur FOR
		SELECT x.*
		  FROM (
				SELECT f.*, ROWNUM rn
				  FROM ( 
						 SELECT ei.automated_export_instance_id instance_id,
								ei.automated_export_class_sid class_sid,
								ei.file_generated,
								ei.payload_filename,
								nvl(dbms_lob.getlength(ei.payload), 0) file_bytes,
								ei.is_preview,
								bj.result_url,
								bj.requested_dtm,
								bj.started_dtm,
								bj.completed_dtm,
								ei.batch_job_id,
								0 is_manual, --Manual not implemented yet
								NVL(bj.result, 'Unknown') result_label,
								COUNT(*) OVER () total_rows
						   FROM automated_export_instance ei
						   JOIN batch_job bj ON ei.batch_job_id = bj.batch_job_id
						  WHERE bj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						    AND ei.automated_export_class_sid = in_automated_export_class_sid
							AND (in_include_preview IS NULL OR (in_include_preview = 0 AND ei.is_preview = 0) OR (in_include_preview = 1 AND ei.is_preview in (0,1)))
							AND (in_include_failure IS NULL OR (in_include_failure = 0 AND ei.file_generated = 1) OR (in_include_failure = 1 AND ei.file_generated in(0,1) ))
						  ORDER BY ei.automated_export_instance_id DESC
						) f
				) x
		 WHERE rn > in_start_row
		   AND rn <= in_end_row
		 ORDER BY instance_id DESC;
END;

PROCEDURE GetMostRecentInstances(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	OPEN out_cur FOR
		SELECT c.automated_export_class_sid class_sid, c.label, c.schedule_xml, NVL(inst.number_of_exports, 0) number_of_attempts, inst.instance_id,
			   CASE WHEN bj2.running_on IS NULL THEN 0 ELSE 1 END running, bj2.completed_dtm, bj2.result, in_parent_sid parent_sid
		  FROM automated_export_class c
		  LEFT JOIN (
				SELECT e.automated_export_class_sid,
				       COUNT(e.automated_export_instance_id) number_of_exports,
					   MAX(e.automated_export_instance_id) instance_id
				  FROM automated_export_instance e
				  JOIN batch_job bj ON bj.batch_job_id = e.batch_job_id
				 WHERE (bj.completed_dtm IS NOT NULL OR bj.running_on IS NOT NULL)
				 GROUP BY e.automated_export_class_sid
				) inst 								ON inst.automated_export_class_sid = c.automated_export_class_sid
		  LEFT JOIN security.securable_object so ON c.automated_export_class_sid = so.sid_id
		  LEFT JOIN automated_export_instance e2	ON inst.instance_id = e2.automated_export_instance_id
		  LEFT JOIN batch_job bj2 					ON e2.batch_job_id = bj2.batch_job_id
		 WHERE so.parent_sid_id = in_parent_sid
			AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, c.automated_export_class_sid, security.security_pkg.PERMISSION_READ) = 1
			AND c.app_sid = v_app_sid;

END;

PROCEDURE GetDbWriterSettings(
	in_automated_export_class_sid	IN	automated_export_instance.automated_export_class_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR

		SELECT ers.stored_procedure, ers.strip_underscores_from_headers
		  FROM auto_exp_retrieval_sp ers
		  JOIN automated_export_class aec ON ers.auto_exp_retrieval_sp_id = aec.auto_exp_retrieval_sp_id
		 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
		   AND ers.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetDsvSettings(
	in_auto_export_instance_id			IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	OPEN out_cur FOR
		SELECT aefd.delimiter_id, aefd.secondary_delimiter_id, aefd.encoding_name, aefd.encode_newline
		  FROM auto_exp_filecreate_dsv aefd
		  JOIN automated_export_class aec 		ON aefd.auto_exp_filecreate_dsv_id = aec.auto_exp_filecre_dsv_id
		  JOIN automated_export_instance aei 	ON aei.automated_export_class_sid = aec.automated_export_class_sid
		 WHERE aei.automated_export_instance_id = in_auto_export_instance_id
		   AND aec.app_sid = v_app_sid;

END;

PROCEDURE GetDsvSettingsByClass(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_aec_dsv_id 	automated_export_class.auto_exp_filecre_dsv_id%TYPE;
BEGIN
	SELECT auto_exp_filecre_dsv_id
	  INTO v_aec_dsv_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
	   AND aec.app_sid = v_app_sid;

	IF v_aec_dsv_id IS NULL THEN
		OPEN out_cur FOR
			SELECT NULL delimiter_id, NULL secondary_delimiter_id, NULL encoding_name, 0 encode_newline
			  FROM DUAL;
	ELSE
		OPEN out_cur FOR
			SELECT aefd.delimiter_id, aefd.secondary_delimiter_id, aefd.encoding_name, aefd.encode_newline
			  FROM auto_exp_filecreate_dsv aefd
			  JOIN automated_export_class aec 		ON aefd.auto_exp_filecreate_dsv_id = aec.auto_exp_filecre_dsv_id
			 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
			   AND aefd.app_sid = v_app_sid;
	END IF;
END;

PROCEDURE UpdateDsvSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_delimiter_id						IN	auto_exp_filecreate_dsv.delimiter_id%TYPE,
	in_secondary_delimiter_id			IN	auto_exp_filecreate_dsv.secondary_delimiter_id%TYPE,
	in_encoding_name					IN	auto_exp_filecreate_dsv.encoding_name%TYPE DEFAULT NULL,
	in_encode_newline					IN	auto_exp_filecreate_dsv.encode_newline%TYPE DEFAULT 0
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_aec_dsv_id 					automated_export_class.auto_exp_filecre_dsv_id%TYPE;
	v_delimiter_id					auto_exp_filecreate_dsv.delimiter_id%TYPE := NULL;
	v_secondary_delimiter_id		auto_exp_filecreate_dsv.secondary_delimiter_id%TYPE := NULL;
	v_encoding_name					auto_exp_filecreate_dsv.encoding_name%TYPE DEFAULT NULL;
	v_encode_newline				auto_exp_filecreate_dsv.encode_newline%TYPE DEFAULT 0;
	
BEGIN
	SELECT auto_exp_filecre_dsv_id
	  INTO v_aec_dsv_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
	   AND aec.app_sid = v_app_sid;

	IF v_aec_dsv_id IS NULL THEN
		SetDsvFileCreateOnClass(
			in_class_sid				=>	in_automated_export_class_sid,
			in_delimiter_id				=>	in_delimiter_id,
			in_secondary_delimiter_id	=>	in_secondary_delimiter_id,
			in_encoding_name			=>	in_encoding_name,
			in_encode_newline			=>	in_encode_newline
		);

		SELECT auto_exp_filecre_dsv_id
		  INTO v_aec_dsv_id
		  FROM automated_export_class
		  WHERE automated_export_class_sid = in_automated_export_class_sid;
	ELSE
	
	SELECT delimiter_id, secondary_delimiter_id, encoding_name, encode_newline
	  INTO v_delimiter_id, v_secondary_delimiter_id, v_encoding_name, v_encode_newline
	  FROM auto_exp_filecreate_dsv
	 WHERE auto_exp_filecreate_dsv_id = v_aec_dsv_id
	   AND app_sid = v_app_sid;
		
		UPDATE auto_exp_filecreate_dsv
		   SET delimiter_id = in_delimiter_id,
			   secondary_delimiter_id = in_secondary_delimiter_id,
			   encoding_name = in_encoding_name,
			   encode_newline = in_encode_newline
		 WHERE auto_exp_filecreate_dsv_id = v_aec_dsv_id
		   AND app_sid = v_app_sid;
	END IF;
	
	IF (in_delimiter_id != v_delimiter_id) OR (v_delimiter_id IS NULL AND in_delimiter_id IS NOT NULL) OR (in_delimiter_id IS NULL AND v_delimiter_id IS NOT NULL)THEN
		BEGIN
			automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Primary Delimiter',  in_delimiter_id, v_delimiter_id);
		END;
	END IF;
	
	IF (in_secondary_delimiter_id != v_secondary_delimiter_id) OR (v_secondary_delimiter_id IS NULL AND in_secondary_delimiter_id IS NOT NULL) OR (in_secondary_delimiter_id IS NULL AND v_secondary_delimiter_id IS NOT NULL) THEN
		BEGIN
			automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Secondary Delimiter',  in_secondary_delimiter_id, v_secondary_delimiter_id);
		END;
	END IF;
	
	IF (in_encoding_name != v_encoding_name) OR (v_encoding_name IS NULL AND in_encoding_name IS NOT NULL) OR (in_encoding_name IS NULL AND v_encoding_name IS NOT NULL) THEN
		BEGIN
			automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Encoding name',  in_encoding_name, v_encoding_name);
		END;
	END IF;
	
	IF (in_encode_newline != v_encode_newline) THEN
		BEGIN
			automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Encode newline',  in_encode_newline, v_encode_newline);
		END;
	END IF;
	
END;

PROCEDURE GetFtpSettings(
	in_auto_export_instance_id			IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT aeff.output_path, fp.ftp_profile_id, fp.label, fp.host_name, fp.secure_credentials, fp.fingerprint, fp.username, fp.password, fp.port_number, fp.ftp_protocol_id, fp.preserve_timestamp, fp.use_username_password_auth
		  FROM auto_exp_filewrite_ftp aeff
		  JOIN automated_export_class aec 		ON aeff.auto_exp_filewrite_ftp_id = aec.auto_exp_filewri_ftp_id
		  JOIN automated_export_instance aei 	ON aei.automated_export_class_sid = aec.automated_export_class_sid
		  JOIN ftp_profile fp					ON fp.ftp_profile_id = aeff.ftp_profile_id
		 WHERE aei.automated_export_instance_id = in_auto_export_instance_id
		   AND aec.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetFtpClassSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT aeff.output_path, aeff.ftp_profile_id
		  FROM auto_exp_filewrite_ftp aeff
		  JOIN automated_export_class aec 		ON aeff.auto_exp_filewrite_ftp_id = aec.auto_exp_filewri_ftp_id
		 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
		   AND aec.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetDataViewExporterSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_aec_dv_id 			automated_export_class.auto_exp_retrieval_dataview_id%TYPE;

	v_dataview_sid			security_pkg.T_SID_ID;
	v_parent_sid			security_pkg.T_SID_ID;

	v_shared_sid			security_pkg.T_SID_ID;
	v_private_root_sid		security_pkg.T_SID_ID;
	v_contexts_sid			security_pkg.T_SID_ID;
	v_root_sid				security_pkg.T_SID_ID;
BEGIN

	SELECT auto_exp_retrieval_dataview_id
	  INTO v_aec_dv_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
	   AND aec.app_sid = v_app_sid;

	IF v_aec_dv_id IS NULL THEN
		OPEN out_cur FOR
			SELECT NULL root_sid, NULL folder_sid, NULL dataview_sid, 0 ignore_null_values,
				   CASE WHEN aeep.outputter_assembly IN ('Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableDsvOutputter',
				   'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableExcelOutputter') THEN 
				   XMLTYPE('<mappings><column from="START_DATE" to="Start Date"/><column from="END_DATE" to="End Date"/><column from="REGION_DESCRIPTION" to="Region"/><column from="IND_DESCRIPTION" to="Indicator"/><column from="MEASURE_DESCRIPTION" to="Measure"/><column from="VALUE" to="Source Value"/></mappings>')
				   ELSE NULL END mapping_xml,
				   NULL period_span_pattern_id, 6 region_selection_type_id, null tag_id
			  FROM csr.automated_export_class aec
			  JOIN csr.auto_exp_exporter_plugin aeep ON aec.exporter_plugin_id = aeep.plugin_id
			 WHERE aec.automated_export_class_sid = in_automated_export_class_sid;
	ELSE

		SELECT dv.parent_sid, aerd.dataview_sid
		  INTO v_parent_sid, v_dataview_sid
			FROM auto_exp_retrieval_dataview aerd
			JOIN automated_export_class aec ON aerd.auto_exp_retrieval_dataview_id = aec.auto_exp_retrieval_dataview_id
			JOIN dataview dv ON dv.dataview_sid = aerd.dataview_sid
			WHERE aec.automated_export_class_sid = in_automated_export_class_sid
			AND aerd.app_sid = v_app_sid;


		v_shared_sid := chain.filter_pkg.GetSharedParentSid(NULL);

		-- If we are being called from the batch job, the user will be builtinadmin, and will not have a private charts folder.
		BEGIN
			v_private_root_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetSid, 'Charts');
		EXCEPTION
			WHEN OTHERS THEN NULL;
		END;
		BEGIN
			v_contexts_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Contexts');
		EXCEPTION
			WHEN OTHERS THEN NULL;
		END;
		
		BEGIN
			SELECT sid_id
			INTO v_root_sid
			FROM SECURITY.SECURABLE_OBJECT
			WHERE sid_id = v_shared_sid
			START WITH sid_id = v_dataview_sid
			CONNECT BY PRIOR parent_sid_id = sid_id;
		EXCEPTION
			WHEN no_data_found THEN NULL;
		END;

		IF v_root_sid IS NULL AND v_private_root_sid IS NOT NULL THEN
			BEGIN
				SELECT sid_id
				INTO v_root_sid
				FROM SECURITY.SECURABLE_OBJECT
				WHERE sid_id = v_private_root_sid
				START WITH sid_id = v_dataview_sid
				CONNECT BY PRIOR parent_sid_id = sid_id;
			EXCEPTION
				WHEN no_data_found THEN NULL;
			END;
		END IF;

		IF v_root_sid IS NULL AND v_contexts_sid IS NOT NULL THEN
			BEGIN
				SELECT sid_id
				INTO v_root_sid
				FROM SECURITY.SECURABLE_OBJECT
				WHERE sid_id = v_contexts_sid
				START WITH sid_id = v_dataview_sid
				CONNECT BY PRIOR parent_sid_id = sid_id;
			EXCEPTION
				WHEN no_data_found THEN NULL;
			END;
		END IF;

		OPEN out_cur FOR
			SELECT v_root_sid root_sid, v_parent_sid folder_sid, v_dataview_sid dataview_sid, aerd.ignore_null_values, aerd.mapping_xml, aerd.period_span_pattern_id, aerd.region_selection_type_id,
				aerd.tag_id, aerd.ind_selection_type_id
			  FROM auto_exp_retrieval_dataview aerd
			  JOIN automated_export_class aec ON aerd.auto_exp_retrieval_dataview_id = aec.auto_exp_retrieval_dataview_id
			  JOIN dataview dv ON dv.dataview_sid = aerd.dataview_sid
			 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
			   AND aerd.app_sid = v_app_sid;
	END IF;
	
END;

PROCEDURE UpdateDataViewExporterSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_dataview_sid						IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values				IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml						IN	VARCHAR2,
	in_region_selection_type_id			IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id							IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id			IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_aec_dv_id 						automated_export_class.auto_exp_retrieval_dataview_id%TYPE;
	v_mapping_xml						auto_exp_retrieval_dataview.mapping_xml%TYPE := NULL;
	v_ignore_nulls 						auto_exp_retrieval_dataview.ignore_null_values%TYPE :=0;
	v_dataview_sid						auto_exp_retrieval_dataview.dataview_sid%TYPE := NULL;
	v_region_selection_type_id			auto_exp_retrieval_dataview.region_selection_type_id%TYPE;
	v_tag_id							auto_exp_retrieval_dataview.tag_id%TYPE;
	v_ind_selection_type_id				auto_exp_retrieval_dataview.ind_selection_type_id%TYPE;
	
BEGIN
	SELECT auto_exp_retrieval_dataview_id
	  INTO v_aec_dv_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
	   AND aec.app_sid = v_app_sid;

	IF v_aec_dv_id IS NULL THEN
		CreateDataviewSettings(
			in_automated_export_class_sid	=>	in_automated_export_class_sid,
			in_dataview_sid					=>	in_dataview_sid,
			in_ignore_null_values			=>	in_ignore_null_values,
			in_mapping_xml					=>	XMLTYPE(in_mapping_xml),
			in_region_selection_type_id		=>	in_region_selection_type_id,
			in_tag_id						=>	in_tag_id,
			in_ind_selection_type_id		=> 	in_ind_selection_type_id
		);

		SELECT auto_exp_retrieval_dataview_id
		  INTO v_aec_dv_id
		  FROM automated_export_class
		  WHERE automated_export_class_sid = in_automated_export_class_sid;

	ELSE
		SELECT mapping_xml, ignore_null_values, dataview_sid, region_selection_type_id, tag_id, ind_selection_type_id
		  INTO v_mapping_xml, v_ignore_nulls, v_dataview_sid, v_region_selection_type_id, v_tag_id, v_ind_selection_type_id
		  FROM auto_exp_retrieval_dataview 
		 WHERE auto_exp_retrieval_dataview_id = v_aec_dv_id
		   AND app_sid = v_app_sid;
	
		UPDATE auto_exp_retrieval_dataview
		   SET dataview_sid = in_dataview_sid,
		       ignore_null_values = in_ignore_null_values,
			   mapping_xml = in_mapping_xml,
			   region_selection_type_id = in_region_selection_type_id,
			   tag_id = in_tag_id,
			   ind_selection_type_id = in_ind_selection_type_id
		 WHERE auto_exp_retrieval_dataview_id = v_aec_dv_id
		   AND app_sid = v_app_sid;

	END IF;

	IF in_mapping_xml IS NOT NULL AND v_mapping_xml IS NULL 
		OR in_mapping_xml != v_mapping_xml.getStringVal() THEN
		BEGIN
		automated_export_pkg.auditxml(in_automated_export_class_sid, 'mapping xml',  in_mapping_xml, v_mapping_xml);
		END;
	END IF;

	IF in_ignore_null_values != v_ignore_nulls THEN
		BEGIN
		automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Ignore nulls',  in_ignore_null_values, v_ignore_nulls);
		END;
	END IF;

	IF in_dataview_sid != v_dataview_sid THEN
		BEGIN
		automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Dataview',  in_dataview_sid, v_dataview_sid);
		END;
	END IF;
	
	IF in_region_selection_type_id != v_region_selection_type_id THEN
		automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Region Selection Type Id',  in_region_selection_type_id, v_region_selection_type_id);
	END IF;
	
	IF NVl(in_tag_id, -1) != NVL(v_tag_id, -1) THEN
		automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Tag Id',  in_tag_id, v_tag_id);
	END IF;
	
	IF in_ind_selection_type_id != v_ind_selection_type_id THEN
		automated_export_pkg.auditvalue(in_automated_export_class_sid, 'Ind Selection Type Id',  in_ind_selection_type_id, v_ind_selection_type_id);
	END IF;
END;

PROCEDURE GetQuickChartExporterSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_filter_sid			security_pkg.T_SID_ID;
	v_parent_sid			security_pkg.T_SID_ID;
	v_card_group_id			NUMBER; --chain.card_group.card_group_id%TYPE;
	v_encoding_name			auto_exp_class_qc_settings.encoding_name%TYPE;

	v_shared_sid			security_pkg.T_SID_ID;
	v_private_root_sid		security_pkg.T_SID_ID;
	v_root_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT s.saved_filter_sid, sf.parent_sid, sf.card_group_id, s.encoding_name
		  INTO v_filter_sid, v_parent_sid, v_card_group_id, v_encoding_name
		  FROM auto_exp_class_qc_settings s
		  JOIN chain.saved_filter sf ON s.saved_filter_sid = sf.saved_filter_sid
		 WHERE automated_export_class_sid = in_automated_export_class_sid;
	EXCEPTION
		WHEN no_data_found THEN NULL;
	END;

	-- If this is a chain site and we are being called from the batch job, the user will be builtinadmin, and will not have a private Filters folder.
	BEGIN
		v_shared_sid := chain.filter_pkg.GetSharedParentSid(v_card_group_id);
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;

	-- If we are being called from the batch job, the user will be builtinadmin, and will not have a private charts folder.
	BEGIN
		v_private_root_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetSid, 'Charts');
	EXCEPTION
		WHEN OTHERS THEN NULL;
	END;
	
	IF v_shared_sid IS NOT NULL THEN
		BEGIN
			SELECT sid_id
			  INTO v_root_sid
			  FROM SECURITY.SECURABLE_OBJECT
			 WHERE sid_id = v_shared_sid
			 START WITH sid_id = v_filter_sid
			CONNECT BY PRIOR parent_sid_id = sid_id;
		EXCEPTION
			WHEN no_data_found THEN NULL;
		END;
	END IF;

	IF v_root_sid IS NULL AND v_private_root_sid IS NOT NULL THEN
		BEGIN
			SELECT sid_id
			  INTO v_root_sid
			  FROM SECURITY.SECURABLE_OBJECT
			 WHERE sid_id = v_private_root_sid
			 START WITH sid_id = v_filter_sid
			CONNECT BY PRIOR parent_sid_id = sid_id;
		EXCEPTION
			WHEN no_data_found THEN NULL;
		END;
	END IF;

	OPEN out_cur FOR
		-- ensure it behaves the same as before when returning the cursor - selecting from dual behaves differently...?
		SELECT v_filter_sid saved_filter_sid, v_parent_sid parent_sid, v_card_group_id card_group_id, v_root_sid root_sid, v_encoding_name encoding_name
		FROM auto_exp_class_qc_settings s
		  JOIN chain.saved_filter sf ON s.saved_filter_sid = sf.saved_filter_sid
		 WHERE automated_export_class_sid = in_automated_export_class_sid;
END;

PROCEDURE UpdateQuickChartExporterSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_saved_filter_sid				IN	auto_exp_class_qc_settings.saved_filter_sid%TYPE,
	in_encoding_name				IN	auto_exp_class_qc_settings.encoding_name%TYPE
)
AS
BEGIN
	INSERT INTO auto_exp_class_qc_settings (automated_export_class_sid, saved_filter_sid, encoding_name)
	VALUES (in_automated_export_class_sid, in_saved_filter_sid, in_encoding_name);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE auto_exp_class_qc_settings
	 	   SET saved_filter_sid = in_saved_filter_sid, encoding_name = in_encoding_name
		WHERE automated_export_class_sid = in_automated_export_class_sid;
END;

PROCEDURE GetInUseQuickChartFilterSids(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT saved_filter_sid
		  FROM auto_exp_class_qc_settings;
END;

FUNCTION CreateStoredProcSettingsFn(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure				IN	auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs	IN	auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
) RETURN NUMBER
AS
	v_settings_id	NUMBER;
BEGIN

	SELECT auto_exp_rtrvl_sp_id_seq.nextval
	  INTO v_settings_id
	  FROM dual;
	
	INSERT INTO auto_exp_retrieval_sp
		(auto_exp_retrieval_sp_id, stored_procedure, strip_underscores_from_headers)
	VALUES
		(v_settings_id, in_stored_procedure, in_strip_underscores_from_hdrs);
		
	RETURN v_settings_id;

END;

PROCEDURE CreateStoredProcSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure				IN	auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs	IN	auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
)
AS
	v_settings_id		NUMBER;
BEGIN
	
	v_settings_id := CreateStoredProcSettingsFn(
		in_automated_export_class_sid	=>	in_automated_export_class_sid,
		in_stored_procedure				=>	in_stored_procedure,
		in_strip_underscores_from_hdrs	=>	in_strip_underscores_from_hdrs
		
	);

	UPDATE automated_export_class
	   SET auto_exp_retrieval_sp_id = v_settings_id
	 WHERE automated_export_class_sid = in_automated_export_class_sid;
END;

PROCEDURE GetStoredProcExpSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_aec_sp_id 	automated_export_class.auto_exp_retrieval_sp_id%TYPE;
BEGIN

	SELECT auto_exp_retrieval_sp_id
	  INTO v_aec_sp_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
	   AND aec.app_sid = v_app_sid;

	IF v_aec_sp_id IS NULL THEN
		OPEN out_cur FOR
			SELECT NULL stored_procedure, 0 strip_underscores_from_headers
			  FROM DUAL;
	ELSE
		OPEN out_cur FOR
			SELECT stored_procedure, strip_underscores_from_headers
			  FROM auto_exp_retrieval_sp
			 WHERE auto_exp_retrieval_sp_id = v_aec_sp_id
			   AND app_sid = v_app_sid;
	END IF;
END;

PROCEDURE UpdateStoredProcExpSettings(
	in_automated_export_class_sid		IN	automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure					IN	auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs		IN	auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_aec_sp_id 	automated_export_class.auto_exp_retrieval_sp_id%TYPE;
BEGIN
	SELECT auto_exp_retrieval_sp_id
	  INTO v_aec_sp_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_automated_export_class_sid
	   AND aec.app_sid = v_app_sid;

	IF v_aec_sp_id IS NULL THEN
		CreateStoredProcSettings(
			in_automated_export_class_sid	=>	in_automated_export_class_sid,
			in_stored_procedure				=>	in_stored_procedure,
			in_strip_underscores_from_hdrs	=>	in_strip_underscores_from_hdrs);
	ELSE
		UPDATE auto_exp_retrieval_sp
		   SET stored_procedure = in_stored_procedure, strip_underscores_from_headers = in_strip_underscores_from_hdrs
		 WHERE auto_exp_retrieval_sp_id = v_aec_sp_id
		   AND app_sid = v_app_sid;
	END IF;
END;

FUNCTION GetPayloadRetention(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE
)
RETURN automated_export_class.days_to_retain_payload%TYPE
AS
	v_days_to_retain_payload	automated_export_class.days_to_retain_payload%TYPE;
BEGIN
	BEGIN
		SELECT MIN(aec.days_to_retain_payload)
		  INTO v_days_to_retain_payload
		  FROM automated_export_instance aei
		  JOIN automated_export_class aec ON aec.automated_export_class_sid = aei.automated_export_class_sid
		 WHERE aei.automated_export_instance_id = in_instance_id;
	EXCEPTION
		-- Return the default if anything weird happens, so we don't break the export.
		WHEN OTHERS THEN
			SELECT data_default
			  INTO v_days_to_retain_payload
			  FROM all_tab_columns
			 WHERE table_name = 'AUTOMATED_EXPORT_CLASS'
			   AND column_name = 'DAYS_TO_RETAIN_PAYLOAD';
	END;
	RETURN v_days_to_retain_payload;
END;

PROCEDURE AppendToInstancePayload(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	in_payload_chunk			IN	BLOB,
	in_payload_filename			IN	automated_export_instance.payload_filename%TYPE
)
AS
	v_temp_payload BLOB;
BEGIN
	-- Read the existing payload or initialize empty_blob if NULL
	SELECT NVL(payload, empty_blob()) INTO v_temp_payload
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = in_instance_id
	   FOR UPDATE;

	-- Append the new data chunk
	DBMS_LOB.APPEND(v_temp_payload, in_payload_chunk);

	UPDATE automated_export_instance
	   SET payload = v_temp_payload,
		   payload_filename = in_payload_filename,
		   file_generated = 1
	 WHERE automated_export_instance_id = in_instance_id;
END;

PROCEDURE ResetInstancePayload(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	in_payload_filename			IN	automated_export_instance.payload_filename%TYPE
)
AS 
BEGIN
		UPDATE automated_export_instance
		   SET payload = null
		 WHERE automated_export_instance_id = in_instance_id
		   AND payload_filename = in_payload_filename;
END;

PROCEDURE GetPayloadFile(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur						OUT sys_refcursor
)
AS
	v_export_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_export_class_sid
	  INTO v_export_class_sid
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnExportClass(v_export_class_sid);

	OPEN out_cur FOR
		SELECT payload fileblob, payload_filename filename
		  FROM automated_export_instance
		 WHERE automated_export_instance_id = in_instance_id;

END;

PROCEDURE GetFileRequestCount(
	in_class_sid			IN automated_export_instance.automated_export_class_sid%TYPE,
	in_instance_id			IN automated_export_instance.automated_export_instance_id%TYPE,
	out_count				OUT NUMBER
)
AS
BEGIN

	SELECT CASE WHEN TO_CHAR(NVL(last_fetched_date, SYSDATE - 1), 'DD-MM-YYYY') = TO_CHAR(SYSDATE, 'DD-MM-YYYY') THEN fetched_count ELSE 0 END
      INTO out_count
	  FROM automated_export_instance
	 WHERE automated_export_class_sid = in_class_sid
	   AND automated_export_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE IncrementFileRequestCount(
	in_class_sid			IN	automated_export_instance.automated_export_class_sid%TYPE,
	in_instance_id			IN automated_export_instance.automated_export_instance_id%TYPE	
)
AS
BEGIN

	UPDATE automated_export_instance
	   SET fetched_count = CASE WHEN TO_CHAR(NVL(last_fetched_date, SYSDATE - 1), 'DD-MM-YYYY') = TO_CHAR(SYSDATE, 'DD-MM-YYYY') THEN fetched_count + 1 ELSE 1 END,
           last_fetched_date = SYSDATE
	 WHERE automated_export_class_sid = in_class_sid
	   AND automated_export_instance_id = in_instance_id; 	   

END;

PROCEDURE GetClassName(
	in_class_sid			IN	automated_export_class.automated_export_class_sid%TYPE,
	out_label				OUT	automated_export_class.label%TYPE
)
AS
BEGIN

	AssertPermissionOnExportClass(in_class_sid);

	SELECT label
	  INTO out_label
	  FROM automated_export_class
	 WHERE automated_export_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
END;

PROCEDURE WriteDebugLogFile(
	in_instance_id	IN	NUMBER,
	in_file_blob	IN	BLOB
)
AS
BEGIN
	-- If retention is zero, don't update logfile.
	IF GetPayloadRetention(in_instance_id) > 0 THEN
		UPDATE automated_export_instance
		   SET debug_log_file = in_file_blob
		 WHERE automated_export_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE WriteSessionLogFile(
	in_instance_id	IN	NUMBER,
	in_file_blob	IN	BLOB
)
AS
BEGIN

	UPDATE automated_export_instance
	   SET session_log_file = in_file_blob
	 WHERE automated_export_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetDebugLogFile(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur						OUT sys_refcursor
)
AS
	v_export_class_sid			automated_export_class.automated_export_class_sid%TYPE;
BEGIN

	SELECT automated_export_class_sid
	  INTO v_export_class_sid
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnExportClass(v_export_class_sid);

	OPEN out_cur FOR
		SELECT debug_log_file fileblob, 'debug_log.txt' filename
		  FROM automated_export_instance
		 WHERE automated_export_instance_id = in_instance_id;

END;

PROCEDURE GetSessionLogFile(
	in_instance_id				IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur						OUT sys_refcursor
)
AS
	v_export_class_sid			automated_export_class.automated_export_class_sid%TYPE;
BEGIN

	SELECT automated_export_class_sid
	  INTO v_export_class_sid
	  FROM automated_export_instance
	 WHERE automated_export_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnExportClass(v_export_class_sid);

	OPEN out_cur FOR
		SELECT session_log_file fileblob, 'session_log.txt' filename
		  FROM automated_export_instance
		 WHERE automated_export_instance_id = in_instance_id;

END;

/* SCHEDULE PROCEDURES */

PROCEDURE ScheduleRun
AS
BEGIN

	CheckForNewJobs();
	ClearupInstancePayloads();

END;

PROCEDURE CheckForNewJobs
AS
	v_instance_id	automated_export_instance.automated_export_instance_id%TYPE;
	v_schedule		RECURRENCE_PATTERN;
BEGIN
	user_pkg.logonAdmin();
	FOR r IN (
		SELECT * 
		  FROM (
			SELECT cls.automated_export_class_sid, csr.automated_export_import_pkg.GetNextScheduledDtm(cls.schedule_xml, cls.last_scheduled_dtm) next_due,
					c.host,
					cls.schedule_xml
			  FROM automated_export_class cls
			  JOIN CUSTOMER c ON cls.app_sid = c.app_sid
			  WHERE cls.schedule_xml IS NOT NULL
			    AND cls.last_scheduled_dtm IS NOT NULL)
		 WHERE (next_due IS NOT NULL AND next_due <= SYSDATE)
	)
	LOOP
		--Create the instance and batch job
		user_pkg.logonAdmin(r.host);
		CreateInstanceAndBatchJob(r.automated_export_class_sid, v_instance_id);

		--Update the schedule
		v_schedule := RECURRENCE_PATTERN(r.schedule_xml);
		IF v_schedule.repeat_period = 'hourly' THEN
			UPDATE automated_export_class
			   SET last_scheduled_dtm = TO_DATE(TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24') ||':'|| TO_CHAR(last_scheduled_dtm, ' MI'), 'DD-MM-YYYY HH24:MI')
			 WHERE automated_export_class_sid = r.automated_export_class_sid;
		ELSE
			UPDATE automated_export_class
			   SET last_scheduled_dtm = TO_DATE(TO_CHAR(SYSDATE, 'DD-MM-YYYY') || TO_CHAR(last_scheduled_dtm, ' HH24:MI'), 'DD-MM-YYYY HH24:MI')
			 WHERE automated_export_class_sid = r.automated_export_class_sid;
		END IF;

	END LOOP;
	security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
END;

PROCEDURE ClearupInstancePayloads
AS
BEGIN
	UPDATE automated_export_instance aei
	   SET aei.payload = NULL, debug_log_file = NULL
	 WHERE aei.automated_export_instance_id IN (
		SELECT automated_export_instance_id
		  FROM automated_export_instance aei
		  JOIN automated_export_class aec ON aec.automated_export_class_sid = aei.automated_export_class_sid
		  JOIN batch_job bj ON aei.batch_job_id = bj.batch_job_id
		 WHERE aei.payload IS NOT NULL
		   AND SYSDATE > (bj.completed_dtm + aec.days_to_retain_payload));
END;

/* SETUP SCRIPTS */

FUNCTION MakeFtpFileWriterSettings(
	in_ftp_profile_id			IN	auto_exp_filewrite_ftp.ftp_profile_id%TYPE,
	in_output_path				IN	auto_exp_filewrite_ftp.output_path%TYPE
) RETURN NUMBER
AS
	v_id		NUMBER(10);
BEGIN

	SELECT auto_exp_filecre_ftp_id_seq.nextval
	  INTO v_id
	  FROM dual;
	  
	INSERT INTO auto_exp_filewrite_ftp
		(auto_exp_filewrite_ftp_id, ftp_profile_id, output_path)
	VALUES
		(v_id, in_ftp_profile_id, in_output_path);
	
	RETURN v_id;
END;

PROCEDURE CreateClass(
	in_parent					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	in_label					IN	automated_export_class.label%TYPE,
	in_schedule_xml				IN	automated_export_class.schedule_xml%TYPE,
	in_file_mask				IN	automated_export_class.file_mask%TYPE,
	in_file_mask_date_format	IN	automated_export_class.file_mask_date_format%TYPE,
	in_email_on_error			IN	automated_export_class.email_on_error%TYPE,
	in_email_on_success			IN	automated_export_class.email_on_success%TYPE,
	in_exporter_plugin_id		IN	automated_export_class.exporter_plugin_id%TYPE,
	in_file_writer_plugin_id	IN	automated_export_class.file_writer_plugin_id%TYPE,
	in_include_headings			IN	automated_export_class.include_headings%TYPE,
	in_output_empty_as			IN	automated_export_class.output_empty_as%TYPE,
	in_lookup_key				IN	automated_export_class.lookup_key%TYPE,
	out_class_sid				OUT	automated_export_class.automated_export_class_sid%TYPE
)
AS
	v_exportimport_container_sid	security.security_pkg.T_SID_ID;
	v_export_container_sid			security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_num							NUMBER;
	v_ftp_settings_id				NUMBER;
	v_ftp_profile_id				NUMBER;
	v_auto_exp_filecre_dataview_id	NUMBER;
	v_is_under_tree					NUMBER(10);
	v_parent						security.security_pkg.T_SID_ID := in_parent;
BEGIN

	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- Find the exports container. If can't find, not enabled to bail
	BEGIN
		v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'AutomatedExportImport container not found - please enable Automated Export Import framework via the enable page first.');
	END;
	BEGIN
		v_export_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_exportimport_container_sid, 'AutomatedExports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_export_container_sid := v_exportimport_container_sid;
	END;

	IF v_parent IS NULL OR v_parent <= 0 THEN
		v_parent := v_export_container_sid;
	END IF;

	-- Check in_parent is a child of v_exportimport_container_sid
	SELECT COUNT(*)
	  INTO v_is_under_tree
	  FROM security.securable_object
	 WHERE application_sid_id = v_app_sid
	   AND sid_id = v_exportimport_container_sid
	 START WITH sid_id = v_parent
	CONNECT BY PRIOR parent_sid_id = sid_id;
	IF v_is_under_tree = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Invalid parent container.');
	END IF;

	-- Create the SO
	BEGIN
		security.securableobject_pkg.CreateSO(v_act_id, v_parent, class_pkg.getClassID('CSRAutomatedExport'), in_label, out_class_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			RAISE_APPLICATION_ERROR(-20001, 'An export with that name already exists.');
	END;
	
	IF in_file_writer_plugin_id IN (1, 7) THEN
		-- If there is already an FTP profile, use it. Otherwise Make a new one
		SELECT NVL(MIN(ftp_profile_id), 0)
		  INTO v_ftp_profile_id
		  FROM csr.ftp_profile
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		IF v_ftp_profile_id = 0 THEN
			BEGIN
				SELECT ftp_profile_id
				  INTO v_ftp_profile_id
				  FROM ftp_profile
				 WHERE host_name = automated_export_import_pkg.FTP_HOST;
			EXCEPTION
				WHEN no_data_found THEN
					v_ftp_profile_id := automated_export_import_pkg.CreateCr360FTPProfile;
			END;
		END IF;
		
		v_ftp_settings_id := MakeFtpFileWriterSettings(v_ftp_profile_id, '/');
	END IF;
	
	IF in_exporter_plugin_id IN (1, 2, 3, 4, 5, 16, 17) THEN --Dataviews
		SELECT MAX(dataview_sid)
		  INTO v_num
		  FROM dataview;
		IF v_num IS NOT NULl THEN
			v_auto_exp_filecre_dataview_id := CreateDataviewSettingsFn(
				in_automated_export_class_sid	=>	out_class_sid,
				in_dataview_sid					=>	v_num,
				in_ignore_null_values			=>	0,
				in_mapping_xml					=>	NULL,
				in_region_selection_type_id		=>	6,
				in_tag_id						=>	NULL,
				in_ind_selection_type_id		=>	0
			);
		END IF;
	END IF;
	
	INSERT INTO automated_export_class
		(automated_export_class_sid, label, lookup_key, file_mask, schedule_xml, last_scheduled_dtm, email_on_error, email_on_success, exporter_plugin_id, file_writer_plugin_id, 
		 include_headings, output_empty_as, file_mask_date_format, auto_exp_filewri_ftp_id, auto_exp_retrieval_dataview_id)
	VALUES
		(out_class_sid, in_label, in_lookup_key, in_file_mask, in_schedule_xml, CASE WHEN in_schedule_xml IS NULL THEN NULL ELSE SYSDATE-1 END, in_email_on_error, in_email_on_success, in_exporter_plugin_id, in_file_writer_plugin_id, 
		 in_include_headings, in_output_empty_as, in_file_mask_date_format, v_ftp_settings_id, v_auto_exp_filecre_dataview_id);
		 
	IF in_exporter_plugin_id IN (1, 2, 3, 4, 5, 16, 17) THEN --Dataviews
		-- Done early, ie above
		NULL;
	ELSIF in_exporter_plugin_id = 6 THEN --Groups and roles exporter (dsv)
		NULL;
	ELSIF in_exporter_plugin_id = 7 THEN --User exporter (dsv, Deutsche Bank)
		NULL;
	ELSIF in_exporter_plugin_id = 8 THEN --Groups and roles exporter (dsv, Deutsche Bank)
		NULL;
	ELSIF in_exporter_plugin_id = 13 THEN --Stored Procedure - Dsv
		NULL;
	ELSIF in_exporter_plugin_id = 14 THEN --ABInBev - Mean Scores (dsv) 
		NULL;
	ELSIF in_exporter_plugin_id = 15 THEN --ABInBev - Suep Mean Scores (dsv) 
		NULL;
	ELSIF in_exporter_plugin_id = 18 THEN --Heineken SPM - dataview export (excel)
		NULL;
	ELSIF in_exporter_plugin_id = 19 THEN --Batched exporter
		SELECT MIN(batch_job_type_id)
		  INTO v_num
		  FROM batched_export_type;
		
		SetBatchedExporterSettings(
			in_class_sid				=>	out_class_sid,
			in_batched_export_type_id	=>	v_num,
			in_settings_xml				=>	XMLTYPE('<?xml version = "1.0" encoding = "UTF-8"?><replaceMe/>'),
			in_convert_to_dsv			=>	0,
			in_primary_delimiter		=>	',',
			in_secondary_delimiter		=>	'|',
			in_include_first_row		=>	0
		);
	END IF;
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An export class with that name already exists.');
END;

FUNCTION CreateDataviewSettingsFn(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_dataview_sid					IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values			IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml					IN	auto_exp_retrieval_dataview.mapping_xml%TYPE,
	in_region_selection_type_id		IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id						IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id		IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE
) RETURN NUMBER
AS
	v_settings_id					NUMBER;
	v_period_span_pattern_id 		NUMBER;
BEGIN

	SELECT auto_exp_rtrvl_dataview_id_seq.nextval
	  INTO v_settings_id
	  FROM dual;

	-- Create a default period span pattern
	v_period_span_pattern_id := period_span_pattern_pkg.MakePeriodSpanPattern();

	INSERT INTO auto_exp_retrieval_dataview
		(auto_exp_retrieval_dataview_id, dataview_sid, ignore_null_values, mapping_xml, period_span_pattern_id, region_selection_type_id, tag_id, ind_selection_type_id)
	VALUES
		(v_settings_id, in_dataview_sid, in_ignore_null_values, in_mapping_xml, v_period_span_pattern_id, in_region_selection_type_id, in_tag_id, in_ind_selection_type_id);

	RETURN v_settings_id;

END;

PROCEDURE CreateDataviewSettings(
	in_automated_export_class_sid	IN	automated_export_class.automated_export_class_sid%TYPE,
	in_dataview_sid					IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values			IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml					IN	auto_exp_retrieval_dataview.mapping_xml%TYPE,
	in_region_selection_type_id		IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id						IN	auto_exp_retrieval_dataview.tag_id%TYPE,	
	in_ind_selection_type_id		IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE
)
AS
	v_settings_id		NUMBER;
BEGIN
	
	v_settings_id := CreateDataviewSettingsFn(
		in_automated_export_class_sid	=>	in_automated_export_class_sid,
		in_dataview_sid					=>	in_dataview_sid,
		in_ignore_null_values			=>	in_ignore_null_values,
		in_mapping_xml					=>	in_mapping_xml,
		in_region_selection_type_id		=>	in_region_selection_type_id,
		in_tag_id						=>	in_tag_id,
		in_ind_selection_type_id		=>	in_ind_selection_type_id
	);

	UPDATE automated_export_class
	   SET auto_exp_retrieval_dataview_id = v_settings_id
	 WHERE automated_export_class_sid = in_automated_export_class_sid;
END;

PROCEDURE CreateDataviewExporterClass(
	in_label					IN	automated_export_class.label%TYPE,
	in_schedule_xml				IN	automated_export_class.schedule_xml%TYPE,
	in_file_mask				IN	automated_export_class.file_mask%TYPE,
	in_file_mask_date_format	IN	automated_export_class.file_mask_date_format%TYPE,
	in_email_on_error			IN	automated_export_class.email_on_error%TYPE,
	in_email_on_success			IN	automated_export_class.email_on_success%TYPE,
	in_exporter_plugin_id		IN	automated_export_class.exporter_plugin_id%TYPE,
	in_file_writer_plugin_id	IN	automated_export_class.file_writer_plugin_id%TYPE,
	in_include_headings			IN	automated_export_class.include_headings%TYPE,
	in_output_empty_as			IN	automated_export_class.output_empty_as%TYPE,
	in_dataview_sid				IN	auto_exp_retrieval_dataview.dataview_sid%TYPE,
	in_ignore_null_values		IN	auto_exp_retrieval_dataview.ignore_null_values%TYPE,
	in_mapping_xml				IN	auto_exp_retrieval_dataview.mapping_xml%TYPE,
	in_region_selection_type_id	IN	auto_exp_retrieval_dataview.region_selection_type_id%TYPE,
	in_tag_id					IN	auto_exp_retrieval_dataview.tag_id%TYPE,
	in_ind_selection_type_id	IN	auto_exp_retrieval_dataview.ind_selection_type_id%TYPE,
	out_class_sid				OUT	automated_export_class.automated_export_class_sid%TYPE
)
AS
	v_parent					security.security_pkg.T_SID_ID;
BEGIN
	v_parent := security.securableobject_pkg.GetSidFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'AutomatedExportImport');

	automated_export_pkg.CreateClass(v_parent, in_label, in_schedule_xml, in_file_mask, in_file_mask_date_format, in_email_on_error, in_email_on_success, in_exporter_plugin_id, in_file_writer_plugin_id,
									 in_include_headings, in_output_empty_as, sys_guid(), out_class_sid);
	
	CreateDataviewSettings(
		in_automated_export_class_sid	=>	out_class_sid,
		in_dataview_sid					=>	in_dataview_sid,
		in_ignore_null_values			=>	in_ignore_null_values,
		in_mapping_xml					=>	in_mapping_xml,
		in_region_selection_type_id		=>	in_region_selection_type_id,
		in_tag_id						=>	in_tag_id,
		in_ind_selection_type_id		=>	in_ind_selection_type_id
	);
END;


PROCEDURE SetFtpFileWriterOnClass(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	in_ftp_profile_id			IN	auto_exp_filewrite_ftp.ftp_profile_id%TYPE,
	in_output_path				IN	auto_exp_filewrite_ftp.output_path%TYPE
)
AS
	v_settings_id		NUMBER;
BEGIN

	v_settings_id := MakeFtpFileWriterSettings(in_ftp_profile_id, in_output_path);
	
	UPDATE automated_export_class
	   SET auto_exp_filewri_ftp_id = v_settings_id
	 WHERE automated_export_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE SetDsvFileCreateOnClass(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	in_delimiter_id				IN	auto_exp_filecreate_dsv.delimiter_id%TYPE,
	in_secondary_delimiter_id	IN	auto_exp_filecreate_dsv.secondary_delimiter_id%TYPE,
	in_encoding_name			IN	auto_exp_filecreate_dsv.encoding_name%TYPE DEFAULT NULL,
	in_encode_newline			IN	auto_exp_filecreate_dsv.encode_newline%TYPE DEFAULT 0
)
AS
	v_settings_id		NUMBER;
BEGIN

	SELECT auto_exp_filecre_dsv_id_seq.nextval
	  INTO v_settings_id
	  FROM dual;
	  
	INSERT INTO auto_exp_filecreate_dsv
		(auto_exp_filecreate_dsv_id, delimiter_id, secondary_delimiter_id, encoding_name, encode_newline)
	VALUES
		(v_settings_id, in_delimiter_id, in_secondary_delimiter_id, in_encoding_name, in_encode_newline);
	
	UPDATE automated_export_class
	   SET auto_exp_filecre_dsv_id = v_settings_id
	 WHERE automated_export_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE UpdateExportClass(
	in_automated_export_class_sid   IN automated_export_class.automated_export_class_sid%TYPE,
	in_label						IN automated_export_class.label%TYPE,
	in_contains_pii					IN automated_export_class.contains_pii%TYPE,
	in_file_mask					IN automated_export_class.file_mask%TYPE,
	in_schedule_xml					IN VARCHAR2,
	in_last_scheduled_dtm			IN automated_export_class.last_scheduled_dtm%TYPE,
	in_email_on_error				IN automated_export_class.email_on_error%TYPE,
	in_email_on_success				IN automated_export_class.email_on_success%TYPE,
	in_include_headings				IN automated_export_class.include_headings%TYPE,
	in_output_empty_as			 	IN automated_export_class.output_empty_as%TYPE,
	in_file_mask_date_format		IN automated_export_class.file_mask_date_format%TYPE,
	in_days_to_retain_payload		IN automated_export_class.days_to_retain_payload%TYPE,
	in_enable_encryption			IN automated_export_class.enable_encryption%TYPE,
	in_public_key_id				IN automated_export_class.auto_impexp_public_key_id%TYPE,
	in_lookup_key					IN automated_export_class.lookup_key%TYPE
)
AS
	v_label						automated_export_class.label%TYPE;
	v_contains_pii				automated_export_class.contains_pii%TYPE;
	v_file_mask					automated_export_class.file_mask%TYPE;
	v_schedule_xml				automated_export_class.schedule_xml%TYPE;
	v_last_scheduled_dtm		automated_export_class.last_scheduled_dtm%TYPE;
	v_email_on_error			automated_export_class.email_on_error%TYPE;
	v_email_on_success			automated_export_class.email_on_success%TYPE;
	v_include_headings			automated_export_class.include_headings%TYPE;
	v_output_empty_as			automated_export_class.output_empty_as%TYPE;
	v_file_mask_date_format		automated_export_class.file_mask_date_format%TYPE;
	v_days_to_retain_payload	automated_export_class.days_to_retain_payload%TYPE;
	v_enable_encryption			automated_export_class.enable_encryption%TYPE;
	v_public_key_id				automated_export_class.auto_impexp_public_key_id%TYPE;
	v_lookup_key				automated_export_class.lookup_key%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	BEGIN
		SELECT label, contains_pii, file_mask, schedule_xml, last_scheduled_dtm, email_on_error, email_on_success, include_headings, output_empty_as,
			   file_mask_date_format, days_to_retain_payload, enable_encryption, auto_impexp_public_key_id, lookup_key
		  INTO v_label, v_contains_pii, v_file_mask, v_schedule_xml, v_last_scheduled_dtm, v_email_on_error, v_email_on_success, v_include_headings, v_output_empty_as,
			   v_file_mask_date_format, v_days_to_retain_payload, v_enable_encryption, v_public_key_id, v_lookup_key
		  FROM automated_export_class
		WHERE  automated_export_class_sid = in_automated_export_class_sid;
	
		UPDATE automated_export_class
		   SET label = in_label, contains_pii = in_contains_pii, file_mask = in_file_mask, schedule_xml = in_schedule_xml, last_scheduled_dtm = in_last_scheduled_dtm,
			   email_on_error = in_email_on_error, email_on_success = in_email_on_success, include_headings = in_include_headings,
			   output_empty_as = in_output_empty_as, file_mask_date_format = in_file_mask_date_format, days_to_retain_payload = in_days_to_retain_payload,
			   enable_encryption = in_enable_encryption, auto_impexp_public_key_id = in_public_key_id, lookup_key = in_lookup_key 
		 WHERE automated_export_class_sid = in_automated_export_class_sid;
		 
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'label', in_label, v_label);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'contains pii', in_contains_pii, v_contains_pii);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'file mask', in_file_mask, v_file_mask);
		 automated_export_pkg.AuditXml(in_automated_export_class_sid, 'schedule XML', in_schedule_xml, v_schedule_xml);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'last scheduled dtm', in_last_scheduled_dtm, v_last_scheduled_dtm);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'email on error', in_email_on_error, v_email_on_error);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'email on success', in_email_on_success, v_email_on_success);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'include headings', in_include_headings, v_include_headings);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'output empty as', in_output_empty_as, v_output_empty_as);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'file mask date format', in_file_mask_date_format, v_file_mask_date_format);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'days to retain payload', in_days_to_retain_payload, v_days_to_retain_payload);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'enable encryption', in_enable_encryption, v_enable_encryption);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'public key', in_public_key_id, v_public_key_id);
		 automated_export_pkg.AuditValue(in_automated_export_class_sid, 'lookup key', in_lookup_key, v_lookup_key);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An export class with that name already exists.');
	END;
END;

PROCEDURE GetFtpFileWriterSettings(
	out_cur						 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT writers.auto_exp_filewrite_ftp_id, label, output_path
		  FROM csr.auto_exp_filewrite_ftp writers
		  JOIN csr.automated_export_class classes
			ON classes.auto_exp_filewri_ftp_id = writers.auto_exp_filewrite_ftp_id;
END;

PROCEDURE UpdateDbFileWriterSettings(
	in_sid								IN automated_export_class.automated_export_class_sid%TYPE,
	in_stored_procedure					IN auto_exp_retrieval_sp.stored_procedure%TYPE,
	in_strip_underscores_from_hdrs		IN auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE
)
AS
	v_auto_exp_sp_id					auto_exp_retrieval_sp.auto_exp_retrieval_sp_id%TYPE;
	v_stored_procedure					auto_exp_retrieval_sp.stored_procedure%TYPE;
	v_strip_underscores_from_hdrs		auto_exp_retrieval_sp.strip_underscores_from_headers%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;

	BEGIN
		SELECT db.auto_exp_retrieval_sp_id, stored_procedure, strip_underscores_from_headers
		INTO v_auto_exp_sp_id, v_stored_procedure, v_strip_underscores_from_hdrs
		FROM automated_export_class aec
		JOIN auto_exp_retrieval_sp db on aec.auto_exp_retrieval_sp_id = db.auto_exp_retrieval_sp_id
		WHERE aec.automated_export_class_sid = in_sid
		AND aec.app_sid = SYS_CONTEXT('SECURITY', 'APP');

		UPDATE auto_exp_retrieval_sp
		SET stored_procedure = in_stored_procedure, strip_underscores_from_headers = in_strip_underscores_from_hdrs
		WHERE auto_exp_retrieval_sp_id = v_auto_exp_sp_id
		AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			CreateStoredProcSettings(
				in_automated_export_class_sid => in_sid,
				in_stored_procedure => in_stored_procedure,
				in_strip_underscores_from_hdrs => in_strip_underscores_from_hdrs
			);
	END;

	UPDATE auto_exp_retrieval_sp
	   SET stored_procedure = in_stored_procedure, strip_underscores_from_headers = in_strip_underscores_from_hdrs
	 WHERE auto_exp_retrieval_sp_id = v_auto_exp_sp_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	automated_export_pkg.AuditValue(in_sid, 'stored_procedure', in_stored_procedure, v_stored_procedure);
	automated_export_pkg.AuditValue(in_sid, 'strip_underscores_from_headers', in_strip_underscores_from_hdrs, v_strip_underscores_from_hdrs);

END;

PROCEDURE UpdateFtpWriterClassSettings(
	in_auto_exp_filewrite_ftp_id		IN auto_exp_filewrite_ftp.auto_exp_filewrite_ftp_id%TYPE,
	in_output_path					IN auto_exp_filewrite_ftp.output_path%TYPE
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	UPDATE csr.auto_exp_filewrite_ftp
	   SET output_path = in_output_path
	 WHERE in_auto_exp_filewrite_ftp_id = auto_exp_filewrite_ftp_id;
END;

PROCEDURE UpdateFtpFileWriterSettings(
	in_class_sid					IN automated_export_class.automated_export_class_sid%TYPE,
	in_ftp_profile_id				IN auto_exp_filewrite_ftp.ftp_profile_id%TYPE,
	in_output_path					IN auto_exp_filewrite_ftp.output_path%TYPE
)
AS
	v_filewrite_ftp_id	auto_exp_filewrite_ftp.auto_exp_filewrite_ftp_id%TYPE;
	v_ftp_profile_id	auto_exp_filewrite_ftp.ftp_profile_id%TYPE;
	v_output_path		auto_exp_filewrite_ftp.output_path%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;

	SELECT ftp.auto_exp_filewrite_ftp_id, ftp_profile_id, output_path
	  INTO v_filewrite_ftp_id, v_ftp_profile_id, v_output_path
	  FROM automated_export_class aec
	  JOIN auto_exp_filewrite_ftp ftp ON aec.auto_exp_filewri_ftp_id = ftp.auto_exp_filewrite_ftp_id
	 WHERE aec.automated_export_class_sid = in_class_sid
	   AND ftp.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE auto_exp_filewrite_ftp
	   SET ftp_profile_id = in_ftp_profile_id,
		   output_path = in_output_path
	 WHERE auto_exp_filewrite_ftp_id = v_filewrite_ftp_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	automated_export_pkg.AuditValue(in_class_sid, 'FTP profile', in_ftp_profile_id, v_ftp_profile_id);
	automated_export_pkg.AuditValue(in_class_sid, 'output path', in_output_path, v_output_path);

END;

PROCEDURE GetExternalTargetSettings(
	in_auto_export_instance_id			IN	automated_export_instance.automated_export_instance_id%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT etp.label, etp.profile_type_id, etp.sharepoint_site, etp.sharepoint_folder, etp.credential_profile_id, etp.onedrive_folder, etp.storage_acc_name, etp.storage_acc_container
		  FROM automated_export_instance aei 
		  JOIN automated_export_class aec ON aei.automated_export_class_sid = aec.automated_export_class_sid
		  JOIN external_target_profile etp ON aec.auto_exp_extern_target_profile_id = etp.target_profile_id AND aec.app_sid = etp.app_sid
		 WHERE aei.automated_export_instance_id = in_auto_export_instance_id
		   AND aec.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetExternalTargetClassSettings(
	in_class_sid					IN	automated_export_class.automated_export_class_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT aec.auto_exp_extern_target_profile_id target_profile_id, etp.label
		  FROM automated_export_class aec
		  JOIN external_target_profile etp ON aec.auto_exp_extern_target_profile_id = etp.target_profile_id AND aec.app_sid = etp.app_sid
		 WHERE aec.automated_export_class_sid = in_class_sid
		   AND aec.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UpdateExternalTargetClassSettings(
	in_class_sid					IN automated_export_class.automated_export_class_sid%TYPE,
	in_target_profile_id			IN external_target_profile.target_profile_id%TYPE
)
AS
	v_target_profile_id				external_target_profile.target_profile_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;

	SELECT aec.auto_exp_extern_target_profile_id
	  INTO v_target_profile_id
	  FROM automated_export_class aec
	 WHERE aec.automated_export_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE automated_export_class
	   SET auto_exp_extern_target_profile_id = in_target_profile_id
	 WHERE automated_export_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	automated_export_pkg.AuditValue(in_class_sid, 'External Target profile id', in_target_profile_id, v_target_profile_id);
END;


-- AUDIT LOGGING

PROCEDURE AuditValue(
	in_class_sid		NUMBER,
	in_field			VARCHAR2,
	in_new_val			VARCHAR2,
	in_old_val			VARCHAR2
)
AS
	v_field_name		VARCHAR2(1024);
BEGIN

	v_field_name := in_field|| ' (class)';

	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_EXPIMP_AUTO_EXPORT, SYS_CONTEXT('SECURITY', 'APP'), in_class_sid, v_field_name, in_old_val, in_new_val);

END;

PROCEDURE AuditXml(
	in_class_sid		NUMBER,
	in_field			VARCHAR2,
	in_new_val			XMLTYPE,
	in_old_val			XMLTYPE
)
AS
	v_new_val			VARCHAR2(4000);
	v_old_val			VARCHAR2(4000);
BEGIN

	IF in_old_val IS NOT NULL THEN
		v_old_val := in_old_val.getStringVal();
	END IF;
	IF in_new_val IS NOT NULL THEN
		v_new_val := in_new_val.getStringVal();
	END IF;

	automated_export_pkg.AuditValue(in_class_sid, in_field, v_new_val, v_old_val);

END;

PROCEDURE AuditXml(
	in_class_sid		NUMBER,
	in_field			VARCHAR2,
	in_new_val			XMLTYPE,
	in_old_val			VARCHAR2
)
AS
	v_new_val			VARCHAR2(4000);
BEGIN

	IF in_new_val IS NOT NULL THEN
		v_new_val := in_new_val.getStringVal();
	END IF;

	automated_export_pkg.AuditValue(in_class_sid, in_field, v_new_val, in_old_val);

END;

PROCEDURE AuditXml(
	in_class_sid		NUMBER,
	in_field			VARCHAR2,
	in_new_val			VARCHAR2,
	in_old_val			XMLTYPE
)
AS
	v_old_val			VARCHAR2(4000);
BEGIN

	IF in_old_val IS NOT NULL THEN
		v_old_val := in_old_val.getStringVal();
	END IF;

	automated_export_pkg.AuditValue(in_class_sid, in_field, in_new_val, v_old_val);

END;

PROCEDURE AuditMsg(
	in_class_sid		NUMBER,
	in_msg				VARCHAR2
)
AS
	v_desc			VARCHAR2(1024);
BEGIN

	v_desc := in_msg|| ' (class)';

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_EXPIMP_AUTO_EXPORT,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid		=>	in_class_sid,
		in_description		=>	v_desc
	);

END;

-- END AUDIT LOGGING


PROCEDURE SetBatchedExporterSettings(
	in_class_sid				IN	automated_export_class.automated_export_class_sid%TYPE,
	in_batched_export_type_id	IN	auto_exp_batched_exp_settings.batched_export_type_id%TYPE,
	in_settings_xml				IN	auto_exp_batched_exp_settings.settings_xml%TYPE,
	in_convert_to_dsv			IN	auto_exp_batched_exp_settings.convert_to_dsv%TYPE,
	in_primary_delimiter		IN	auto_exp_batched_exp_settings.primary_delimiter%TYPE,
	in_secondary_delimiter		IN	auto_exp_batched_exp_settings.secondary_delimiter%TYPE,
	in_include_first_row		IN	auto_exp_batched_exp_settings.include_first_row%TYPE
)
AS
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;

	BEGIN
		INSERT INTO auto_exp_batched_exp_settings
			(automated_export_class_sid, batched_export_type_id, settings_xml, convert_to_dsv, primary_delimiter, secondary_delimiter, include_first_row)
		VALUES
			(in_class_sid, in_batched_export_type_id, in_settings_xml, in_convert_to_dsv, in_primary_delimiter, in_secondary_delimiter, in_include_first_row);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE auto_exp_batched_exp_settings
			   SET batched_export_type_id 		= in_batched_export_type_id,
			       settings_xml					= in_settings_xml,
				   convert_to_dsv				= in_convert_to_dsv,
				   primary_delimiter			= in_primary_delimiter,
				   secondary_delimiter			= in_secondary_delimiter,
				   include_first_row			= in_include_first_row
			 WHERE automated_export_class_sid = in_class_sid
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;

END;

PROCEDURE GetExporters(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT plugin_id, label
		  FROM auto_exp_exporter_plugin
		 ORDER BY label ASC;

END;

PROCEDURE GetFileWriters(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT plugin_id, label
		  FROM auto_exp_file_writer_plugin
		 ORDER BY label ASC;

END;

PROCEDURE GetBatchedExporters(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT batch_job_type_id, label
		  FROM batched_export_type
		 ORDER BY label ASC;
END;

END;
/
