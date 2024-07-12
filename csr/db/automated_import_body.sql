CREATE OR REPLACE PACKAGE BODY csr.automated_import_pkg AS

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
		UPDATE automated_import_class
		   SET label = in_new_name
		 WHERE automated_import_class_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) 
AS
	v_inbox_sid				security_pkg.T_SID_ID;
	v_running				NUMBER;
BEGIN
	-- check it's not running
	SELECT COUNT(*)
	  INTO v_running
	  FROM csr.automated_import_class aec
	  JOIN csr.automated_import_instance aii ON aii.automated_import_class_sid = aec.automated_import_class_sid
	  JOIN csr.batch_job bj  				ON aii.batch_job_id = bj.batch_job_id
	  WHERE aec.automated_import_class_sid  = in_sid_id
	    AND bj.running_on IS NOT NULL;
	
	IF v_running > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_DELETE_CLASS_RUNNING, 'Cannot delete running import.');
	END IF;


	DELETE FROM auto_imp_mail_file
	 WHERE automated_import_instance_id IN (
	 	SELECT automated_import_instance_id 
	 	  FROM automated_import_instance
	 	 WHERE automated_import_class_sid = in_sid_id
	 );

	DELETE FROM auto_imp_mail_attach_filter
	 WHERE matched_import_class_sid = in_sid_id;

	UPDATE auto_imp_mailbox
	   SET matched_imp_class_sid_for_body = NULL
	 WHERE matched_imp_class_sid_for_body = in_sid_id;

	UPDATE user_profile
	   SET creation_instance_step_id = NULL
	 WHERE creation_instance_step_id IN (SELECT auto_import_instance_step_id FROM automated_import_instance_step WHERE automated_import_class_sid = in_sid_id);
	
	UPDATE user_profile
	   SET updated_instance_step_id = NULL
	 WHERE updated_instance_step_id IN (SELECT auto_import_instance_step_id FROM automated_import_instance_step WHERE automated_import_class_sid = in_sid_id);
	
	UPDATE user_profile_staged_record
	   SET instance_step_id = NULL
	 WHERE instance_step_id IN (SELECT auto_import_instance_step_id FROM automated_import_instance_step WHERE automated_import_class_sid = in_sid_id);

	UPDATE meter_raw_data_source
	   SET automated_import_class_sid = NULL
	 WHERE automated_import_class_sid = in_sid_id;
	
	DELETE FROM auto_imp_core_data_settings
	 WHERE automated_import_class_sid = in_sid_id;
	
	DELETE FROM auto_imp_user_imp_settings
	 WHERE automated_import_class_sid = in_sid_id;

	DELETE FROM auto_imp_zip_filter
	 WHERE matched_import_class_sid = in_sid_id;

	DELETE FROM auto_imp_zip_settings
	 WHERE automated_import_class_sid = in_sid_id;
	
	DELETE FROM auto_imp_indicator_map
	 WHERE automated_import_class_sid = in_sid_id;

	DELETE FROM auto_imp_region_map
	 WHERE automated_import_class_sid = in_sid_id;

	DELETE FROM auto_imp_unit_map
	 WHERE automated_import_class_sid = in_sid_id;

	DELETE FROM user_profile_default_group
	 WHERE automated_import_class_sid = in_sid_id;

	DELETE FROM automated_import_instance_step WHERE automated_import_class_sid = in_sid_id;
	DELETE FROM auto_imp_product_settings WHERE automated_import_class_sid = in_sid_id;
	DELETE FROM automated_import_manual_file WHERE automated_import_instance_id IN
		(SELECT automated_import_instance_id FROM automated_import_instance WHERE automated_import_class_sid = in_sid_id);
	DELETE FROM automated_import_instance WHERE automated_import_class_sid = in_sid_id;
	DELETE FROM auto_imp_importer_settings WHERE automated_import_class_sid = in_sid_id;
	FOR s IN (
		SELECT auto_imp_importer_cms_id, auto_imp_fileread_ftp_id, auto_imp_fileread_db_id
			FROM automated_import_class_step aics
			WHERE automated_import_class_sid = in_sid_id
	) LOOP
		DELETE FROM automated_import_class_step WHERE automated_import_class_sid = in_sid_id;
		DELETE FROM auto_imp_importer_cms WHERE auto_imp_importer_cms_id = s.auto_imp_importer_cms_id;
		DELETE FROM auto_imp_fileread_db WHERE auto_imp_fileread_db_id = s.auto_imp_fileread_db_id;
		DELETE FROM auto_imp_fileread_ftp WHERE auto_imp_fileread_ftp_id = s.auto_imp_fileread_ftp_id;		
	END LOOP;
	DELETE FROM automated_import_class WHERE automated_import_class_sid = in_sid_id;

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

FUNCTION EmptySidIds
RETURN security_pkg.T_SID_IDS
AS
	v security_pkg.T_SID_IDS;
BEGIN
	RETURN v;
END;

PROCEDURE DeleteClass(
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_sid_id);
END;

PROCEDURE AssertPermissionOnImportClass(
	in_class_sid				IN	automated_import_class.automated_import_class_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('security','act'), in_class_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the automated import class with sid '||in_class_sid);
	END IF;
END;

PROCEDURE AssertWritePermOnImportClass(
	in_class_sid				IN	automated_import_class.automated_import_class_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('security','act'), in_class_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the automated import class with sid '||in_class_sid);
	END IF;
END;

/* No security check as internal only and checked by parent SPs */
PROCEDURE GetClassSteps(
	in_import_class_sid			IN	automated_import_class.automated_import_class_sid%TYPE,
	out_steps_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_steps_cur FOR
		SELECT aics.automated_import_class_sid, step_number, days_to_retain_payload, plugin custom_plugin, importer_plugin_id, aifp.fileread_assembly, fileread_plugin_id,aiip.importer_assembly, aics.on_completion_sp,
			   aics.on_failure_sp, aiip.label importer_label, aifp.label fileread_label, aics.ignore_file_not_found_excptn ignore_file_not_found_excptn, aics.enable_decryption, aiip.allow_manual manual_import_supported
		  FROM automated_import_class_step aics
		  JOIN auto_imp_importer_plugin aiip ON aiip.plugin_id = aics.importer_plugin_id
	 LEFT JOIN auto_imp_fileread_plugin aifp ON aifp.plugin_id = aics.fileread_plugin_id
		 WHERE aics.automated_import_class_sid = in_import_class_sid
		   AND aics.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY aics.step_number;

END;

PROCEDURE GetClass(
	in_import_class_sid			IN	automated_import_class.automated_import_class_sid%TYPE,
	out_job_cur					OUT	SYS_REFCURSOR,
	out_steps_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	AssertPermissionOnImportClass(in_import_class_sid);

	OPEN out_job_cur FOR
		SELECT automated_import_class_sid, lookup_key, label, contains_pii, schedule_xml, last_scheduled_dtm, abort_on_error, 
			   email_on_error, email_on_success, email_on_partial, on_completion_sp, import_plugin import_plugin_assembly, 
			   process_all_pending_files, pending_files_limit
		  FROM automated_import_class
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetClassSteps(in_import_class_sid, out_steps_cur);

END;

PROCEDURE GetClasses(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT automated_import_class_sid, lookup_key, label
		  FROM automated_import_class
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetJob(
	in_batch_job_id				IN	automated_import_instance.batch_job_id%TYPE,
	out_job_cur					OUT	SYS_REFCURSOR,
	out_steps_cur				OUT	SYS_REFCURSOR
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance
	 WHERE batch_job_id = in_batch_job_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	OPEN out_job_cur FOR
		SELECT aic.automated_import_class_sid, automated_import_instance_id, lookup_key, label, schedule_xml, last_scheduled_dtm, abort_on_error, email_on_error, email_on_success, email_on_partial,
			   on_completion_sp, import_plugin import_plugin_assembly, aii.is_manual, aii.is_from_bus, process_all_pending_files, aii.mailbox_sid, aii.mail_message_uid, pending_files_limit
		  FROM automated_import_class aic
		  JOIN automated_import_instance aii ON aii.automated_import_class_sid = aic.automated_import_class_sid
		 WHERE batch_job_id = in_batch_job_id
		   AND aic.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetClassSteps(v_import_class_sid, out_steps_cur);

END;

PROCEDURE GetInstance(
	in_instance_id				IN	automated_import_instance.batch_job_id%TYPE,
	out_instance_cur			OUT	SYS_REFCURSOR,
	out_steps_cur				OUT	SYS_REFCURSOR,
	out_message_cur				OUT	SYS_REFCURSOR
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance
	 WHERE automated_import_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	OPEN out_instance_cur FOR
		SELECT aii.automated_import_instance_id, bj.batch_job_id, bj.requested_dtm, bj.completed_dtm, case WHEN bj.completed_dtm IS NULL THEN 'Pending' ELSE nvl(bj.result, 'Unknown') END result_label, aic.automated_import_class_sid, lookup_key,
			   label, schedule_xml, last_scheduled_dtm, abort_on_error, email_on_error, email_on_success, email_on_partial, on_completion_sp, import_plugin, aii.is_manual, aii.is_from_bus, parent_instance_id,
			   aim.sender_address, aim.sender_name, aim.subject, aim.recieved_dtm, aibox.address mailbox_address, process_all_pending_files, pending_files_limit, aibf.source_description,
			   CASE WHEN debug_log_file IS NULL THEN 0 ELSE 1 END has_debug_log, CASE WHEN session_log_file IS NULL THEN 0 ELSE 1 END has_session_log
		  FROM automated_import_class aic
		  JOIN automated_import_instance aii	ON aii.automated_import_class_sid = aic.automated_import_class_sid
		  JOIN batch_job bj 					ON bj.batch_job_id = aii.batch_job_id
	 LEFT JOIN auto_imp_mail aim 				ON aim.mail_message_uid = aii.mail_message_uid AND aim.mailbox_sid = aii.mailbox_sid
	 LEFT JOIN auto_imp_mailbox aibox 			ON aim.mailbox_sid = aibox.mailbox_sid
	 LEFT JOIN automated_import_bus_file aibf	ON aii.automated_import_instance_id = aibf.automated_import_instance_id
		 WHERE aii.automated_import_instance_id = in_instance_id
		   AND aic.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_steps_cur FOR
		SELECT automated_import_class_sid, step_number, auto_import_instance_step_id instance_step_id, started_dtm, completed_dtm, result result_id,
			   CASE WHEN payload IS NULL THEN 0 ELSE 1 END has_payload,
			   CASE WHEN error_payload IS NULL THEN 0 ELSE 1 END has_error_payload,
			   payload_filename, error_filename, custom_url, custom_url_title
		  FROM automated_import_instance_step
		 WHERE automated_import_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY step_number ASC, started_dtm DESC;

	OPEN out_message_cur FOR
		SELECT import_instance_step_id, map.message_id, message, severity, msg_dtm message_dtm
		  FROM auto_import_message_map map
		  JOIN auto_impexp_instance_msg msg ON msg.message_id = map.message_id
		 WHERE import_instance_id = in_instance_id
		   AND (csr_user_pkg.IsSuperAdmin = 1 OR msg.severity != 'S')
		   AND msg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY msg_dtm, msg.message_id;

END;

PROCEDURE GetClassInstances(
	in_automated_import_class_sid	IN	security_pkg.T_SID_ID,
	in_start_row    				IN	NUMBER,
	in_end_row      				IN	NUMBER,
	out_cur         				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertPermissionOnImportClass(in_automated_import_class_sid);

	OPEN out_cur FOR
		SELECT x.*
		  FROM (
				SELECT f.*, ROWNUM rn
				  FROM (
						 SELECT ii.automated_import_instance_id instance_id,
								bj.requested_dtm,
								bj.started_dtm,
								bj.completed_dtm,
								ii.batch_job_id,
								ii.is_manual,
								ii.is_from_bus,
								NVL(bj.result, 'Unknown') result_label,
								COUNT(*) OVER () total_rows
						   FROM automated_import_instance ii
						   JOIN batch_job bj ON ii.batch_job_id = bj.batch_job_id
						  WHERE bj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
							AND ii.automated_import_class_sid = in_automated_import_class_sid
						  ORDER BY ii.automated_import_instance_id DESC
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
		SELECT c.automated_import_class_sid class_sid, c.label, c.schedule_xml, NVL(inst.number_of_imports + 0,0) number_of_attempts, inst.instance_id,
			   CASE WHEN bj2.running_on IS NULL THEN 0 ELSE 1 END running, bj2.completed_dtm, bj2.result, in_parent_sid parent_sid,
			   (
				SELECT COUNT(step_number)
				  FROM automated_import_class_step
				 WHERE automated_import_class_sid = c.automated_import_class_sid
				) number_of_steps
		  FROM automated_import_class c
		  LEFT JOIN (
				SELECT i.automated_import_class_sid,
				       COUNT(i.automated_import_instance_id) number_of_imports,
					   MAX(i.automated_import_instance_id) instance_id
				  FROM automated_import_instance i
				  JOIN batch_job bj ON bj.batch_job_id = i.batch_job_id
				 WHERE (bj.completed_dtm IS NOT NULL OR bj.running_on IS NOT NULL)
				 GROUP BY i.automated_import_class_sid
				) inst 								ON inst.automated_import_class_sid = c.automated_import_class_sid
		  LEFT JOIN automated_import_instance i2	ON inst.instance_id = i2.automated_import_instance_id
		  LEFT JOIN batch_job bj2 					ON i2.batch_job_id = bj2.batch_job_id
		  LEFT JOIN security.securable_object so 	ON c.automated_import_class_sid = so.sid_id
		 WHERE so.parent_sid_id = in_parent_sid
			AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, c.automated_import_class_sid, security.security_pkg.PERMISSION_READ) = 1
			AND c.app_sid = v_app_sid;

END;

PROCEDURE GetFtpSettings(
	in_automated_import_class_sid		IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT payload_path, file_mask, sort_by, sort_by_direction, move_to_path_on_success, move_to_path_on_error, delete_on_success, delete_on_error, fp.ftp_profile_id, fp.label, fp.host_name, fp.secure_credentials, fp.fingerprint, fp.username, fp.password, fp.port_number, 
		 fp.ftp_protocol_id, fp.preserve_timestamp, fp.enable_debug_log, fp.use_username_password_auth
		  FROM auto_imp_fileread_ftp aiff
		  JOIN automated_import_class_step aics ON aiff.auto_imp_fileread_ftp_id = aics.auto_imp_fileread_ftp_id
		  JOIN ftp_profile fp					ON fp.ftp_profile_id = aiff.ftp_profile_id
		 WHERE aics.automated_import_class_sid = in_automated_import_class_sid
		   AND step_number = in_step_number
		   AND aiff.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetDbReaderSettings(
	in_automated_import_class_sid		IN	automated_import_instance.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	out_cur								OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT filedata_sp
		  FROM auto_imp_fileread_db db
		  JOIN automated_import_class_step step ON db.auto_imp_fileread_db_id = step.auto_imp_fileread_db_id
		 WHERE automated_import_class_sid = in_automated_import_class_sid
		   AND step_number = in_step_number
		   AND db.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

FUNCTION GetPayloadRetentionByStep(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE
)
RETURN automated_import_class_step.days_to_retain_payload%TYPE
AS
	v_days_to_retain_payload	automated_import_class_step.days_to_retain_payload%TYPE;
BEGIN
	BEGIN
		SELECT aics.days_to_retain_payload
		  INTO v_days_to_retain_payload
		  FROM automated_import_instance_step aiis
		  JOIN automated_import_class_step aics ON aics.automated_import_class_sid = aiis.automated_import_class_sid AND aics.step_number = aiis.step_number
		 WHERE aiis.auto_import_instance_step_id = in_instance_step_id;
	EXCEPTION
		-- Return the default if anything weird happens, so we don't break the export.
		WHEN OTHERS THEN 
			SELECT data_default
			  INTO v_days_to_retain_payload
			  FROM all_tab_columns
			 WHERE table_name = 'AUTOMATED_IMPORT_CLASS_STEP'
			   AND column_name = 'DAYS_TO_RETAIN_PAYLOAD';
	END;
	RETURN v_days_to_retain_payload;
END;

FUNCTION GetPayloadRetentionByInstance(
	in_instance_id		IN	automated_import_instance.automated_import_instance_id%TYPE
)
RETURN automated_import_class_step.days_to_retain_payload%TYPE
AS
	v_days_to_retain_payload	automated_import_class_step.days_to_retain_payload%TYPE;
BEGIN
	BEGIN
		SELECT MIN(aics.days_to_retain_payload)
		  INTO v_days_to_retain_payload
		  FROM automated_import_instance aii
		  JOIN automated_import_class_step aics ON aics.automated_import_class_sid = aii.automated_import_class_sid
		 WHERE aii.automated_import_instance_id = in_instance_id;
	EXCEPTION
		-- Return the default if anything weird happens, so we don't break the export.
		WHEN OTHERS THEN 
			SELECT data_default
			  INTO v_days_to_retain_payload
			  FROM all_tab_columns
			 WHERE table_name = 'AUTOMATED_IMPORT_CLASS_STEP'
			   AND column_name = 'DAYS_TO_RETAIN_PAYLOAD';
	END;

	RETURN v_days_to_retain_payload;
END;

PROCEDURE WriteInstanceStepStart(
	in_class_sid				IN	automated_import_instance_step.automated_import_class_sid%TYPE,
	in_instance_id				IN	automated_import_instance_step.automated_import_instance_id%TYPE,
	in_step_number				IN	automated_import_instance_step.step_number%TYPE,
	out_instance_step_id		OUT	automated_import_instance_step.auto_import_instance_step_id%TYPE
)
AS
BEGIN

	SELECT auto_imp_instance_step_id_seq.nextval
	  INTO out_instance_step_id
	  FROM DUAL;

	INSERT INTO automated_import_instance_step
		(automated_import_class_sid, automated_import_instance_id, step_number, auto_import_instance_step_id, started_dtm)
	VALUES
		(in_class_sid, in_instance_id, in_step_number, out_instance_step_id, SYSDATE);

END;

PROCEDURE WriteInstanceStepResult(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_result				IN	automated_import_instance_step.result%TYPE
)
AS
BEGIN

	UPDATE automated_import_instance_step
	   SET result = in_result,
		   completed_dtm = SYSDATE
	 WHERE auto_import_instance_step_id = in_instance_step_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE WriteInstanceStepErrorResult(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_result				IN	automated_import_instance_step.result%TYPE,
	in_error_payload		IN	automated_import_instance_step.error_payload%TYPE,
	in_error_filename		IN	automated_import_instance_step.error_filename%TYPE
)
AS
	v_error_payload				automated_import_instance_step.error_payload%TYPE := in_error_payload;
	v_error_filename			automated_import_instance_step.error_filename%TYPE := in_error_filename;
BEGIN

	-- If retention is zero, don't store error payload.
	IF GetPayloadRetentionByStep(in_instance_step_id) <= 0 THEN
		v_error_payload := NULL;
		v_error_filename := NULL;
	END IF;

	UPDATE automated_import_instance_step
	   SET result = in_result,
		   completed_dtm = SYSDATE,
		   error_payload = v_error_payload,
		   error_filename = v_error_filename
	 WHERE auto_import_instance_step_id = in_instance_step_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE WritePayload(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_payload_blob			IN	automated_import_instance_step.payload%TYPE,
	in_filename				IN	automated_import_instance_step.payload_filename%TYPE
)
AS
BEGIN
	-- If retention is zero, don't store payload.
	IF GetPayloadRetentionByStep(in_instance_step_id) > 0 THEN
		UPDATE automated_import_instance_step
		   SET payload = in_payload_blob,
			   payload_filename = in_filename
		 WHERE auto_import_instance_step_id = in_instance_step_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE GetCmsImportSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT aiic.auto_imp_importer_cms_id, tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, NVL(dsv_quotes_as_literals, 0) dsv_quotes_as_literals,
				NVL(excel_worksheet_index, 0) excel_worksheet_index, NVL(header_row, 0) header_row, NVL(all_or_nothing, 0) all_or_nothing
		  FROM auto_imp_importer_cms aiic
		  JOIN automated_import_class_step aics ON aics.auto_imp_importer_cms_id = aiic.auto_imp_importer_cms_id
		 WHERE aics.automated_import_class_sid = in_class_sid
		   AND aics.step_number = in_step_number
		   AND aiic.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE GetGenericImporterSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT auto_imp_importer_settings_id, mapping_xml, automated_import_file_type_id, dsv_separator, NVL(dsv_quotes_as_literals, 0) dsv_quotes_as_literals,
				NVL(excel_worksheet_index, 0) excel_worksheet_index, NVL(all_or_nothing, 0) all_or_nothing
		  FROM auto_imp_importer_settings
		 WHERE automated_import_class_sid = in_class_sid
		   AND step_number = in_step_number
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE GetManualFile(
	in_sid							IN	NUMBER,
	in_instance_id					IN	NUMBER,
	in_step_number					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT file_blob data_file, file_name data_filename
		  FROM automated_import_manual_file
		 WHERE automated_import_instance_id = in_instance_id
		   AND step_number = in_step_number
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE UpdateInstanceStepFile(
	in_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	in_payload				IN	BLOB,
	in_payload_filename		IN	automated_import_instance_step.payload_filename%TYPE
)
AS
BEGIN
	-- If retention is zero, don't store payload.
	IF GetPayloadRetentionByStep(in_instance_step_id) > 0 THEN
		UPDATE automated_import_instance_step
		   SET payload = in_payload, payload_filename = in_payload_filename
		 WHERE auto_import_instance_step_id = in_instance_step_id;
	END IF;
END;

PROCEDURE GetInstancesByFileName(
	in_payload_filename				IN	automated_import_instance_step.payload_filename%TYPE,
	out_cur							OUT sys_refcursor
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	OPEN out_cur FOR
		SELECT automated_import_instance_id
		  FROM automated_import_instance_step
		 WHERE payload_filename = in_payload_filename
		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, automated_import_class_sid, security.security_pkg.PERMISSION_READ) = 1
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetFile(
	in_auto_imp_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	out_cur								OUT sys_refcursor
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT inst.automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance inst
	  JOIN automated_import_instance_step step on inst.automated_import_instance_id = step.automated_import_instance_id
	 WHERE auto_import_instance_step_id = in_auto_imp_instance_step_id
	   AND inst.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	OPEN out_cur FOR
		SELECT payload fileblob, payload_filename filename
		  FROM automated_import_instance_step
		 WHERE auto_import_instance_step_id = in_auto_imp_instance_step_id;

END;

PROCEDURE GetErrorFile(
	in_auto_imp_instance_step_id		IN	automated_import_instance_step.auto_import_instance_step_id%TYPE,
	out_cur								OUT sys_refcursor
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT inst.automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance inst
	  JOIN automated_import_instance_step step on inst.automated_import_instance_id = step.automated_import_instance_id
	 WHERE auto_import_instance_step_id = in_auto_imp_instance_step_id
	   AND inst.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	OPEN out_cur FOR
		SELECT error_payload fileblob, error_filename filename
		  FROM automated_import_instance_step
		 WHERE auto_import_instance_step_id = in_auto_imp_instance_step_id;

END;

PROCEDURE GetPayloadFileName(
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	in_step_number				IN	automated_import_instance_step.step_number%TYPE,
	out_filename				OUT varchar2
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT inst.automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance inst
	 WHERE automated_import_instance_id = in_instance_id
	   AND inst.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	SELECT payload_filename
	  INTO out_filename
	  FROM automated_import_instance_step
	 WHERE automated_import_instance_id = in_instance_id
	   AND step_number = in_step_number
	   AND app_sid = SYS_CONTEXT('security', 'app');

END;

PROCEDURE CreateManualInstance(
	in_class_sid			IN	automated_import_class_step.automated_import_class_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_number_of_steps		NUMBER;
BEGIN

	IF NOT csr_data_pkg.CheckCapability('Manually import automated import instances') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to perform manual imports.');
	END IF;
	AssertPermissionOnImportClass(in_class_sid);

	SELECT COUNT(step_number)
	  INTO v_number_of_steps
	  FROM automated_import_class_step
	 WHERE automated_import_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	CreateInstanceAndBatchJob(
		in_automated_import_class_sid => in_class_sid, 
		in_number_of_steps => v_number_of_steps, 
		in_is_manual => 1, 
		out_cur => out_cur);

END;

PROCEDURE SetManualFile(
	in_cms_instance_id		IN	NUMBER,
	in_step_number			IN	NUMBER,
	in_file_data			IN	BLOB,
	in_file_name			IN	VARCHAR2
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance
	 WHERE automated_import_instance_id = in_cms_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	INSERT INTO automated_import_manual_file
		(automated_import_instance_id, step_number, file_blob, file_name)
	VALUES
		(in_cms_instance_id, in_step_number, in_file_data, in_file_name);

END;

PROCEDURE CreateChildInstanceAndStep(
	in_class_sid			IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_parent_instance_id	IN	NUMBER,
	in_file_data			IN	BLOB,
	in_file_name			IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_new_instance_id			NUMBER;
	v_number_of_steps			NUMBER;
BEGIN

	AssertPermissionOnImportClass(in_class_sid);

	SELECT COUNT(step_number)
	  INTO v_number_of_steps
	  FROM automated_import_class_step
	 WHERE automated_import_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_number_of_steps > 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Class not supported; Has more than 1 step');
	END IF;

	CreateInstanceAndBatchJob(
		in_automated_import_class_sid => in_class_sid, 
		in_number_of_steps => 1, 
		in_is_manual => 1, 
		in_parent_instance_id => in_parent_instance_id,
		out_auto_import_instance_id => v_new_instance_id);
	

	INSERT INTO automated_import_manual_file
		(automated_import_instance_id, step_number, file_blob, file_name)
	VALUES
		(v_new_instance_id, 1, in_file_data, in_file_name);

	OPEN out_cur FOR
		SELECT batch_job_id, v_new_instance_id new_instance_id
		  FROM automated_import_instance
		 WHERE automated_import_instance_id = v_new_instance_id;
		
END;

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_number_of_steps				IN	BATCH_JOB.total_work%TYPE,
	in_is_manual					IN	automated_import_instance.is_manual%TYPE,
	in_is_from_bus					IN	automated_import_instance.is_from_bus%TYPE DEFAULT 0,
	in_parent_instance_id			IN	automated_import_instance.automated_import_instance_id%TYPE DEFAULT NULL,
	in_mailbox_sid					IN	automated_import_instance.mailbox_sid%TYPE DEFAULT NULL,
	in_mail_message_uid				IN	automated_import_instance.mail_message_uid%TYPE DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_automated_import_instance_id		automated_import_instance.automated_import_instance_id%TYPE;
BEGIN

	AssertPermissionOnImportClass(in_automated_import_class_sid);

	CreateInstanceAndBatchJob(
		in_automated_import_class_sid 	=> in_automated_import_class_sid, 
		in_number_of_steps 				=> in_number_of_steps, 
		in_is_manual 					=> in_is_manual,
		in_is_from_bus					=> in_is_from_bus,
		in_parent_instance_id			=> in_parent_instance_id,
		in_mailbox_sid					=> in_mailbox_sid,
		in_mail_message_uid				=> in_mail_message_uid,
		out_auto_import_instance_id 	=> v_automated_import_instance_id);

	OPEN out_cur FOR
		SELECT batch_job_id, v_automated_import_instance_id instance_id
		  FROM automated_import_instance
		 WHERE automated_import_instance_id = v_automated_import_instance_id;

END;

PROCEDURE CreateInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_number_of_steps				IN	BATCH_JOB.total_work%TYPE,
	in_is_manual					IN	automated_import_instance.is_manual%TYPE,
	in_is_from_bus					IN	automated_import_instance.is_from_bus%TYPE DEFAULT 0,
	in_parent_instance_id			IN	automated_import_instance.automated_import_instance_id%TYPE DEFAULT NULL,
	in_mailbox_sid					IN	automated_import_instance.mailbox_sid%TYPE DEFAULT NULL,
	in_mail_message_uid				IN	automated_import_instance.mail_message_uid%TYPE DEFAULT NULL,
	out_auto_import_instance_id		OUT	automated_import_instance.automated_import_instance_id%TYPE
)
AS
	v_batch_job_id					batch_job.batch_job_id%TYPE;
	v_class_name					automated_import_class.label%TYPE;
BEGIN

	AssertPermissionOnImportClass(in_automated_import_class_sid);

	SELECT label
	  INTO v_class_name
	  FROM automated_import_class
	 WHERE automated_import_class_sid = in_automated_import_class_sid;

	--Create the batch job
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_AUTOMATED_IMPORT,
		in_description => v_class_name,
		in_total_work => in_number_of_steps,
		out_batch_job_id => v_batch_job_id);

	SELECT auto_imp_instance_id_seq.NEXTVAL
	  INTO out_auto_import_instance_id
	  FROM DUAL;

	INSERT INTO automated_import_instance
		(automated_import_instance_id, automated_import_class_sid, is_manual, is_from_bus, batch_job_id, parent_instance_id, mailbox_sid, mail_message_uid)
	VALUES
		(out_auto_import_instance_id, in_automated_import_class_sid, in_is_manual, in_is_from_bus, v_batch_job_id, in_parent_instance_id, in_mailbox_sid, in_mail_message_uid);
END;

PROCEDURE TriggerInstance(
	in_class_sid				IN	automated_import_class.automated_import_class_sid%TYPE,
	in_parent_instance_id		IN	automated_import_instance.automated_import_instance_id%TYPE DEFAULT NULL,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_instance_id				automated_import_instance.automated_import_instance_id%TYPE;
	v_number_of_steps			BATCH_JOB.total_work%TYPE;
BEGIN

	IF NOT csr_data_pkg.CheckCapability('Can run additional automated import instances') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to run additional imports.');
	END IF;

	IF ValidateClass(in_class_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Class failed validation - cannot be triggered.');
	END IF;
	
	SELECT COUNT(step_number)
	  INTO v_number_of_steps
	  FROM automated_import_class_step
	 WHERE automated_import_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	CreateInstanceAndBatchJob(
		in_automated_import_class_sid	=> in_class_sid,
		in_number_of_steps				=> v_number_of_steps,
		in_is_manual					=> 0,
		in_parent_instance_id			=> in_parent_instance_id,
		out_auto_import_instance_id		=> v_instance_id
	);

	OPEN out_cur FOR
		SELECT batch_job_id, v_instance_id automated_import_instance_id
		  FROM automated_import_instance
		 WHERE automated_import_instance_id = v_instance_id;

END;

PROCEDURE CountPriorInstances(
	in_class_sid				IN	automated_import_class.automated_import_class_sid%TYPE,
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	out_result					OUT	NUMBER
)
AS
BEGIN

	SELECT COUNT(*)
	  INTO out_result
	  FROM automated_import_instance
	 WHERE automated_import_class_sid = in_class_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
   CONNECT BY PRIOR parent_instance_id = automated_import_instance_id
	 START WITH automated_import_instance_id = in_instance_id;

END;

PROCEDURE WriteDebugLogFile(
	in_instance_id	IN	NUMBER,
	in_file_blob	IN	BLOB
)
AS
BEGIN
	-- If retention is zero, don't store error payload.
	IF GetPayloadRetentionByInstance(in_instance_id) > 0 THEN
		UPDATE automated_import_instance
		   SET debug_log_file = in_file_blob
		 WHERE automated_import_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE WriteSessionLogFile(
	in_instance_id	IN	NUMBER,
	in_file_blob	IN	BLOB
)
AS
BEGIN

	UPDATE automated_import_instance
	   SET session_log_file = in_file_blob
	 WHERE automated_import_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetDebugLogFile(
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	out_cur						OUT sys_refcursor
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance
	 WHERE automated_import_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	OPEN out_cur FOR
		SELECT debug_log_file fileblob, 'debug_log.txt' filename
		  FROM automated_import_instance
		 WHERE automated_import_instance_id = in_instance_id;

END;

PROCEDURE GetSessionLogFile(
	in_instance_id				IN	automated_import_instance.automated_import_instance_id%TYPE,
	out_cur						OUT sys_refcursor
)
AS
	v_import_class_sid			automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_import_class_sid
	  INTO v_import_class_sid
	  FROM automated_import_instance
	 WHERE automated_import_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	AssertPermissionOnImportClass(v_import_class_sid);

	OPEN out_cur FOR
		SELECT session_log_file fileblob, 'session_log.txt' filename
		  FROM automated_import_instance
		 WHERE automated_import_instance_id = in_instance_id;

END;


/* SCHEDULE PROCEDURES */

PROCEDURE ScheduleRun
AS
BEGIN

	CheckForNewJobs();
	ClearupInstancePayloads();

END;

FUNCTION ValidateClass(
	in_class_sid		IN	NUMBER
) RETURN NUMBER
AS
	v_step_count		NUMBER;
BEGIN

	SELECT COUNT(step_number)
	  INTO v_step_count
	  FROM automated_import_class_step
	 WHERE automated_import_class_sid = in_class_sid;
	
	IF v_step_count = 0 THEN
		RETURN 0;
	END IF;

	RETURN 1;
	
END;

PROCEDURE CheckForNewJobs
AS
	v_instance_id	automated_import_instance.automated_import_instance_id%TYPE;
	v_schedule 		RECURRENCE_PATTERN;
BEGIN

	user_pkg.logonAdmin(timeout => 600);
	
	FOR r IN (
		SELECT *
		  FROM (
			SELECT cic.app_sid, cic.automated_import_class_sid, csr.automated_export_import_pkg.GetNextScheduledDtm(cic.schedule_xml, cic.last_scheduled_dtm) next_due,
					cic.schedule_xml,
					(SELECT COUNT(step_number) FROM automated_import_class_step where automated_import_class_sid = cic.automated_import_class_sid) number_of_steps
			  FROM automated_import_class cic
			  WHERE cic.schedule_xml IS NOT NULL
				AND cic.last_scheduled_dtm IS NOT NULL)
		 WHERE (next_due IS NOT NULL AND next_due <= SYSDATE)
		   AND ValidateClass(automated_import_class_sid) = 1
	)
	LOOP
		--Create the instance and batch job
		security_pkg.SetApp(r.app_sid);
		
		CreateInstanceAndBatchJob(
			in_automated_import_class_sid => r.automated_import_class_sid, 
			in_number_of_steps => NVL(r.number_of_steps, 0), 
			in_is_manual => 0, 
			out_auto_import_instance_id => v_instance_id);

		--Update the schedule
		v_schedule := RECURRENCE_PATTERN(r.schedule_xml);
		IF v_schedule.repeat_period = 'hourly' THEN
			UPDATE automated_import_class
			   SET last_scheduled_dtm = TO_DATE(TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24') ||':'|| TO_CHAR(last_scheduled_dtm, ' MI'), 'DD-MM-YYYY HH24:MI')
			 WHERE automated_import_class_sid = r.automated_import_class_sid;
		ELSE
			UPDATE automated_import_class
			   SET last_scheduled_dtm = TO_DATE(TO_CHAR(SYSDATE, 'DD-MM-YYYY') || TO_CHAR(last_scheduled_dtm, ' HH24:MI'), 'DD-MM-YYYY HH24:MI')
			 WHERE automated_import_class_sid = r.automated_import_class_sid;
		END IF;

	END LOOP;
	security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));

END;

PROCEDURE ClearupInstancePayloads
AS
BEGIN
	UPDATE automated_import_instance_step ciis
	   SET ciis.payload = NULL, ciis.payload_filename = NULL,
		   ciis.error_payload = NULL, ciis.error_filename = NULL
	 WHERE ciis.auto_import_instance_step_id IN (
		SELECT auto_import_instance_step_id
		  FROM automated_import_instance_step ciis
		  JOIN automated_import_class_step cics ON cics.automated_import_class_sid = ciis.automated_import_class_sid AND cics.step_number = ciis.step_number
		 WHERE (ciis.payload IS NOT NULL OR ciis.error_payload IS NOT NULL)
		   AND SYSDATE > (ciis.completed_dtm + cics.days_to_retain_payload));
END;

/* SETUP SCRIPTS */

PROCEDURE CreateClass(
	in_parent						IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	in_label						IN	automated_import_class.label%TYPE,
	in_lookup_key					IN	automated_import_class.lookup_key%TYPE,
	in_schedule_xml					IN	automated_import_class.schedule_xml%TYPE,
	in_abort_on_error				IN	automated_import_class.abort_on_error%TYPE,
	in_email_on_error				IN	automated_import_class.email_on_error%TYPE,
	in_email_on_partial				IN	automated_import_class.email_on_partial%TYPE,
	in_email_on_success				IN	automated_import_class.email_on_success%TYPE,
	in_on_completion_sp				IN	automated_import_class.on_completion_sp%TYPE,
	in_import_plugin				IN	automated_import_class.import_plugin%TYPE,
	in_process_all_pending_files	IN	automated_import_class.process_all_pending_files%TYPE DEFAULT 0,
	out_class_sid					OUT	automated_import_class.automated_import_class_sid%TYPE
)
AS
	v_exportimport_container_sid	security.security_pkg.T_SID_ID;
	v_import_container_sid			security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_is_under_tree					NUMBER(10);
	v_parent						security.security_pkg.T_SID_ID := in_parent;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	-- Find the imports container. If can't find, not enabled to bail
	BEGIN
		v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExportImport');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'AutomatedExportImport container not found - please enable Automated Export Import framework via the enable page first.');
	END;
	BEGIN
		v_import_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_exportimport_container_sid, 'AutomatedImports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_import_container_sid := v_exportimport_container_sid;
	END;

	IF v_parent IS NULL OR v_parent <= 0 THEN
		v_parent := v_import_container_sid;
	END IF;

	-- Check v_parent is a child of v_exportimport_container_sid
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
		security.securableobject_pkg.CreateSO(v_act_id, v_parent, class_pkg.getClassID('CSRAutomatedImport'), in_label, out_class_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An import with that name already exists.');
	END;

	
	BEGIN
		INSERT INTO automated_import_class
			(automated_import_class_sid, label, lookup_key, schedule_xml, last_scheduled_dtm, abort_on_error, email_on_error, email_on_partial,
			 email_on_success, on_completion_sp, import_plugin, process_all_pending_files)
		VALUES
			(out_class_sid, in_label, in_lookup_key, in_schedule_xml, CASE WHEN in_schedule_xml IS NULL THEN NULL ELSE SYSDATE-1 END, in_abort_on_error, in_email_on_error, in_email_on_partial,
			 in_email_on_success, in_on_completion_sp, in_import_plugin, in_process_all_pending_files);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An import class with that name or lookup key already exists.');
	END;
		
	automated_import_pkg.AuditMsg(out_class_sid, NULL, 'Created '||in_label);
		 
END;

PROCEDURE AddStepToClass(
	in_import_class_sid			IN	NUMBER,
	in_step_number				IN 	NUMBER,
	in_importer_plugin_id		IN	NUMBER,
	in_fileread_plugin_id		IN	NUMBER
)
AS
	v_auto_imp_fileread_ftp_id	NUMBER;
	v_auto_imp_importer_cms_id	NUMBER;
	v_auto_imp_fileread_db_id	NUMBER;
	v_ftp_profile_id			NUMBER;
	v_contains_pii				BOOLEAN;
	v_pii_payload_retention		NUMBER;
BEGIN

	-- SECURITY CHECK!!!
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	-- Create settings based on the importer and filereader selected
	IF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_CMS OR in_importer_plugin_id = IMPORT_PLUGIN_TYPE_XML_BULK THEN
		v_auto_imp_importer_cms_id := MakeCmsImporterSettings(
			in_tab_sid					=> NULL,
			in_mapping_xml				=> XMLTYPE('<mappings></mappings>'),
			in_cms_imp_file_type_id		=> 1,
			in_dsv_separator			=> 'COMMA',
			in_dsv_quotes_as_literals	=> 1,
			in_excel_worksheet_index	=> 0,
			in_all_or_nothing			=> 0
		);
	END IF; -- Other importers have to be created AFTER the step because of FKs
		
	IF in_fileread_plugin_id = FILEREADER_PLUGIN_FTP OR in_fileread_plugin_id = FILEREADER_PLUGIN_FTP_FOLDER THEN	-- FTP, FTP folder reader
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
		
		v_auto_imp_fileread_ftp_id := MakeFTPReaderSettings(
			in_ftp_profile_id				=> v_ftp_profile_id,
			in_payload_path					=> 'path',
			in_file_mask					=> '*',
			in_sort_by						=> 'FILENAME',
			in_sort_by_direction			=> 'ASC',
			in_move_to_path_on_success		=> '',
			in_move_to_path_on_error		=> '',
			in_delete_on_success			=> 0,
			in_delete_on_error				=> 0
		);
		
	ELSIF in_fileread_plugin_id = FILEREADER_PLUGIN_DATABASE THEN
		v_auto_imp_fileread_db_id := MakeDBReaderSettings(
			in_filedata_sp		=> 'my_usr.my_pkg.my_sp'
		);
	END IF;
	-- Filereader 3 = Manual (No settings needed)

	IF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_USER THEN	-- User
		v_contains_pii := TRUE;
		v_pii_payload_retention := 45;
	ELSE
		v_contains_pii := FALSE;
	END IF;

	
	INSERT INTO automated_import_class_step
		(automated_import_class_sid, step_number, on_completion_sp, on_failure_sp, plugin, fileread_plugin_id, importer_plugin_id, 
		 auto_imp_fileread_ftp_id, auto_imp_importer_cms_id, auto_imp_fileread_db_id)
	VALUES
		(in_import_class_sid, in_step_number, NULL, NULL, NULL, in_fileread_plugin_id, in_importer_plugin_id,
		 v_auto_imp_fileread_ftp_id, v_auto_imp_importer_cms_id, v_auto_imp_fileread_db_id);
	
	IF v_contains_pii = TRUE THEN
		-- Set the PII flag for the whole class and reduce the payload retention.
		-- This can be overridden by the user on edit, that's intentional.
		UPDATE automated_import_class
		   SET contains_pii = 1
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		UPDATE automated_import_class_step
		   SET days_to_retain_payload = v_pii_payload_retention
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND step_number = in_step_number
		   AND fileread_plugin_id = in_fileread_plugin_id
		   AND importer_plugin_id = in_importer_plugin_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	-- Create "late" settings - ie those where the step needs to be created first
	IF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_METER_RD THEN	-- Meter raw data importer
		SetGenericImporterSettings(
			in_import_class_sid				=> in_import_class_sid,
			in_step_number					=> in_step_number,
			in_mapping_xml					=> XMLTYPE('<mappings></mappings>'),
			in_imp_file_type_id				=> 1,
			in_dsv_separator				=> ',',
			in_dsv_quotes_as_literals		=> 1,
			in_excel_worksheet_index		=> 0,
			in_excel_row_index				=> 1,
			in_all_or_nothing				=> 0
		);
		UPDATE automated_import_class
		   SET pending_files_limit = 0
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	ELSIF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_CORE_DATA THEN	-- Core data
		SetCoreDataImporterSettings(
			in_import_class_sid				=> in_import_class_sid,
			in_step_number					=> in_step_number,
			in_mapping_xml					=> XMLTYPE('<mappings></mappings>'),
			in_imp_file_type_id				=> 1,
			in_dsv_separator				=> ',',
			in_dsv_quotes_as_literals		=> 1,
			in_excel_worksheet_index		=> 0,
			in_all_or_nothing				=> 0,
			in_has_headings					=> 1,
			in_ind_mapping_type_id			=> 0,
			in_region_mapping_type_id		=> 0,
			in_unit_mapping_type_id			=> 0,
			in_requires_validation_step		=> 0,
			in_date_format_type_id			=> 0,
			in_first_col_date_format_id		=> 0,
			in_second_col_date_format_id	=> 0,
			in_date_string_exact_pars_frmt	=> NULL,
			in_zero_indexed_month_indices	=> 0,
			in_financial_year_start_month	=> 1,
			in_overlap_action				=> 'ERROR'
		);

	ELSIF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_ZIP_EXTRC THEN	-- Zip
		SetZipImporterSettings(
			in_import_class_sid			=> in_import_class_sid,
			in_step_number				=> in_step_number,
			in_sort_by					=> 'FILENAME',
			in_sort_by_direction		=> 'ASC',
			in_remove_filters			=> 0
		);

	ELSIF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_USER THEN	-- User
		SetUserImporterSettings(
			in_import_class_sid					=> in_import_class_sid,
			in_step_number						=> in_step_number,
			in_mapping_xml						=> XMLTYPE('<mappings></mappings>'),
			in_imp_file_type_id					=> 1,
			in_dsv_separator					=> ',',
			in_dsv_quotes_as_literals			=> 1,
			in_excel_worksheet_index			=> 0,
			in_all_or_nothing					=> 0,
			in_has_headings						=> 1,
			in_concatenator						=> '_',
			in_active_status_method				=> 'ALWAYS_ACTIVE',
			in_use_loc_region_as_start_pt		=> 0,
			in_set_line_mngmnt_frm_mngr_ky		=> 0,
			in_region_mapping_type_id			=> 0,
			in_date_string_exact_pars_frmt		=> NULL
		);

	ELSIF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_PRODUCT THEN	-- Product
		SetProductImportSettings(
			in_import_class_sid					=> in_import_class_sid,
			in_step_number						=> in_step_number,
			in_mapping_xml						=> XMLTYPE('<mappings></mappings>'),
			in_imp_file_type_id					=> 2,
			in_dsv_separator					=> ',',
			in_dsv_quotes_as_literals			=> 1,
			in_excel_worksheet_index			=> 0,
			in_all_or_nothing					=> 0,
			in_header_row						=> 0, -- 0 based index
			in_concatenator						=> '_',
			in_default_company_sid				=> NULL,
			in_company_mapping_type_id			=> 3,	-- Default to map on Company Name 
			in_product_mapping_type_id			=> 0,	-- Default to map on Lookup key
			in_prod_type_mapping_type_id		=> 0,	-- Default to map on Lookup key
			in_cms_mapping_xml					=> NULL,
			in_tab_sid							=> NULL
		);

	END IF;
	
	automated_import_pkg.AuditMsg(in_import_class_sid, in_step_number, 'Added step to class');
	
END;

PROCEDURE AddFtpClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_ftp_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE
)
AS
BEGIN
	-- FTP reader is 1; select * from AUTO_IMP_FILEREAD_PLUGIN;
	AddClassStep (
		in_import_class_sid				=>	in_import_class_sid,
		in_step_number					=>	in_step_number,
		in_on_completion_sp				=>	in_on_completion_sp,
		in_on_failure_sp				=>	in_on_failure_sp,
		in_days_to_retain_payload		=>	in_days_to_retain_payload,
		in_plugin						=>	in_plugin,
		in_importer_plugin_id			=>	in_importer_plugin_id,
		in_fileread_plugin_id			=>	1,
		in_fileread_ftp_id				=>	in_ftp_settings_id);
END;

PROCEDURE AddDbClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_db_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_DB_ID%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE
)
AS
BEGIN
	-- DB reader is 2; select * from AUTO_IMP_FILEREAD_PLUGIN;
	AddClassStep (
		in_import_class_sid				=>	in_import_class_sid,
		in_step_number					=>	in_step_number,
		in_on_completion_sp				=>	in_on_completion_sp,
		in_on_failure_sp				=>	in_on_failure_sp,
		in_days_to_retain_payload		=>	in_days_to_retain_payload,
		in_plugin						=>	in_plugin,
		in_importer_plugin_id			=>	in_importer_plugin_id,
		in_fileread_plugin_id			=>	2,
		in_fileread_db_id				=>	in_db_settings_id);
END;

PROCEDURE AddManualClassStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE
)
AS
BEGIN
	-- MANUAL reader is 3; select * from AUTO_IMP_FILEREAD_PLUGIN;
	AddClassStep (
		in_import_class_sid				=>	in_import_class_sid,
		in_step_number					=>	in_step_number,
		in_on_completion_sp				=>	in_on_completion_sp,
		in_on_failure_sp				=>	in_on_failure_sp,
		in_days_to_retain_payload		=>	in_days_to_retain_payload,
		in_plugin						=>	in_plugin,
		in_importer_plugin_id			=>	in_importer_plugin_id,
		in_fileread_plugin_id			=>	3);
END;

PROCEDURE AddClassStep (
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_importer_plugin_id			IN	automated_import_class_step.IMPORTER_PLUGIN_ID%TYPE,
	in_fileread_plugin_id			IN	automated_import_class_step.FILEREAD_PLUGIN_ID%TYPE,
	in_fileread_db_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_DB_ID%TYPE DEFAULT NULL,
	in_fileread_ftp_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	INSERT INTO automated_import_class_step
		(automated_import_class_sid, step_number, on_completion_sp, on_failure_sp, days_to_retain_payload, plugin, fileread_plugin_id, importer_plugin_id, auto_imp_fileread_db_id, auto_imp_fileread_ftp_id)
	VALUES
		(in_import_class_sid, in_step_number, in_on_completion_sp, in_on_failure_sp, in_days_to_retain_payload, in_plugin, in_fileread_plugin_id, in_importer_plugin_id, in_fileread_db_id, in_fileread_ftp_id);

	IF in_importer_plugin_id = IMPORT_PLUGIN_TYPE_METER_RD THEN	-- Meter raw data importer
		UPDATE automated_import_class
		   SET pending_files_limit = 0
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;

END;

FUNCTION MakeFTPReaderSettings(
	in_ftp_profile_id				IN	auto_imp_fileread_ftp.ftp_profile_id%TYPE,
	in_payload_path					IN	auto_imp_fileread_ftp.payload_path%TYPE,
	in_file_mask					IN	auto_imp_fileread_ftp.file_mask%TYPE,
	in_sort_by						IN	auto_imp_fileread_ftp.sort_by%TYPE,
	in_sort_by_direction			IN	auto_imp_fileread_ftp.sort_by_direction%TYPE,
	in_move_to_path_on_success		IN	auto_imp_fileread_ftp.move_to_path_on_success%TYPE,
	in_move_to_path_on_error		IN	auto_imp_fileread_ftp.move_to_path_on_error%TYPE,
	in_delete_on_success			IN	auto_imp_fileread_ftp.delete_on_success%TYPE,
	in_delete_on_error				IN	auto_imp_fileread_ftp.delete_on_error%TYPE
)
RETURN NUMBER
AS
	v_settings_id						NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	INSERT INTO auto_imp_fileread_ftp 
		(auto_imp_fileread_ftp_id, ftp_profile_id, payload_path, file_mask, sort_by, sort_by_direction, 
			move_to_path_on_success, move_to_path_on_error, delete_on_success, delete_on_error)
	VALUES 
		(auto_imp_fileread_ftp_id_seq.nextval, in_ftp_profile_id, in_payload_path, in_file_mask, in_sort_by, in_sort_by_direction, 
			in_move_to_path_on_success, in_move_to_path_on_error, in_delete_on_success, in_delete_on_error)
	RETURNING auto_imp_fileread_ftp_id INTO v_settings_id;

	return v_settings_id;
END;


FUNCTION MakeDBReaderSettings(
	in_filedata_sp				IN	auto_imp_fileread_db.filedata_sp%TYPE
)
RETURN NUMBER
AS
	v_settings_id						NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	SELECT auto_imp_fileread_db_id_seq.nextval
	  INTO v_settings_id
	  FROM dual;

	INSERT INTO auto_imp_fileread_db
		(auto_imp_fileread_db_id, filedata_sp)
	VALUES
		(v_settings_id, in_filedata_sp);

	return v_settings_id;

END;

FUNCTION MakeCmsImporterSettings(
	in_tab_sid						IN	auto_imp_importer_cms.tab_sid%TYPE,
	in_mapping_xml					IN	auto_imp_importer_cms.mapping_xml%TYPE,
	in_cms_imp_file_type_id			IN	auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_cms.all_or_nothing%TYPE
)
RETURN NUMBER
AS
	v_settings_id					auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	SELECT AUTO_IMP_IMPORTER_CMS_ID_SEQ.nextval
	  INTO v_settings_id
	  FROM dual;

	INSERT INTO auto_imp_importer_cms
		(auto_imp_importer_cms_id, tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing)
	VALUES
		(v_settings_id, in_tab_sid, in_mapping_xml, in_cms_imp_file_type_id, in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, in_all_or_nothing);

	RETURN v_settings_id;

END;

PROCEDURE SetGenericImporterSettings(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_mapping_xml					IN	auto_imp_importer_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN	auto_imp_importer_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_excel_row_index				IN	auto_imp_importer_settings.excel_row_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_settings.all_or_nothing%TYPE
)
AS
	v_settings_id					auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE;
	v_mapping_xml					auto_imp_importer_cms.mapping_xml%TYPE;
	v_imp_file_type_id				auto_imp_importer_cms.cms_imp_file_type_id%TYPE;
	v_dsv_separator					auto_imp_importer_cms.dsv_separator%TYPE;
	v_dsv_quotes_as_literals		auto_imp_importer_cms.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index			auto_imp_importer_cms.excel_worksheet_index%TYPE;
	v_all_or_nothing				auto_imp_importer_cms.all_or_nothing%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	BEGIN
		INSERT INTO auto_imp_importer_settings 
			(auto_imp_importer_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, 
				dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, excel_row_index, all_or_nothing)
		VALUES 
			(auto_importer_settings_id_seq.nextval, in_import_class_sid, in_step_number, in_mapping_xml, in_imp_file_type_id, 
				in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, in_excel_row_index, in_all_or_nothing);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			
			SELECT mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing
			  INTO v_mapping_xml, v_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals, v_excel_worksheet_index, v_all_or_nothing			
			  FROM auto_imp_importer_settings
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			
			UPDATE auto_imp_importer_settings
			   SET mapping_xml = in_mapping_xml,
				   automated_import_file_type_id = in_imp_file_type_id,
				   dsv_separator = in_dsv_separator,
				   dsv_quotes_as_literals = in_dsv_quotes_as_literals,
				   excel_worksheet_index = in_excel_worksheet_index,
				   excel_row_index = in_excel_row_index,
				   all_or_nothing = in_all_or_nothing
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			 
			 automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'mapping xml', in_mapping_xml.getStringVal(), v_mapping_xml.getStringVal());
			 automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'file type id', in_imp_file_type_id, v_imp_file_type_id);
			 automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv separator', in_dsv_separator, v_dsv_separator);
			 automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv quotes as literals', in_dsv_quotes_as_literals, v_dsv_quotes_as_literals);
			 automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'Excel worksheet index', in_excel_worksheet_index, v_excel_worksheet_index);
			 automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'All or nothing', in_all_or_nothing, v_all_or_nothing);
	END;
END;

PROCEDURE AddCmsFtpStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_ftp_settings_id				IN	automated_import_class_step.AUTO_IMP_FILEREAD_FTP_ID%TYPE,
	in_tab_sid						IN	auto_imp_importer_cms.tab_sid%TYPE,
	in_mapping_xml					IN	auto_imp_importer_cms.mapping_xml%TYPE,
	in_cms_imp_file_type_id			IN	auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_cms.all_or_nothing%TYPE
)
AS
	v_settings_id					auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	-- Make the step, make the settings, update the step with the settings id

	-- CMS importer = 1; select * from AUTO_IMP_IMPORTER_PLUGIN;
	automated_import_pkg.AddFtpClassStep(in_import_class_sid, in_step_number, in_on_completion_sp, in_on_failure_sp, in_days_to_retain_payload, in_plugin, in_ftp_settings_id,  1);

	v_settings_id := MakeCmsImporterSettings(in_tab_sid, in_mapping_xml, in_cms_imp_file_type_id, in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, in_all_or_nothing);

	UPDATE automated_import_class_step
	   SET auto_imp_importer_cms_id = v_settings_id
	 WHERE automated_import_class_sid = in_import_class_sid
	   AND step_number = in_step_number
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE AddCmsManualStep(
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_on_completion_sp				IN	automated_import_class_step.ON_COMPLETION_SP%TYPE,
	in_on_failure_sp				IN	automated_import_class_step.ON_FAILURE_SP%TYPE DEFAULT NULL,
	in_days_to_retain_payload		IN	automated_import_class_step.DAYS_TO_RETAIN_PAYLOAD%TYPE,
	in_plugin						IN	automated_import_class_step.PLUGIN%TYPE,
	in_tab_sid						IN	auto_imp_importer_cms.tab_sid%TYPE,
	in_mapping_xml					IN	auto_imp_importer_cms.mapping_xml%TYPE,
	in_cms_imp_file_type_id			IN	auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_importer_cms.all_or_nothing%TYPE
)
AS
	v_settings_id					auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	-- Make the step, make the settings, update the step with the settings id
	-- CMS importer = 1; select * from AUTO_IMP_IMPORTER_PLUGIN;
	automated_import_pkg.AddManualClassStep(in_import_class_sid, in_step_number, in_on_completion_sp, in_on_failure_sp, in_days_to_retain_payload, in_plugin, 1);
	automated_import_pkg.AddManualClassStep(in_import_class_sid, in_step_number, in_on_completion_sp, in_on_failure_sp, in_days_to_retain_payload, in_plugin, 1);

	v_settings_id := MakeCmsImporterSettings(in_tab_sid, in_mapping_xml, in_cms_imp_file_type_id, in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, in_all_or_nothing);

	UPDATE automated_import_class_step
	   SET auto_imp_importer_cms_id = v_settings_id
	 WHERE automated_import_class_sid = in_import_class_sid
	   AND step_number = in_step_number
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetStepFtpAndCmsSettings (
	in_import_class_sid				IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number					IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_cms_settings_id				IN	auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE,
	in_ftp_settings_id				IN	auto_imp_fileread_ftp.auto_imp_fileread_ftp_id%TYPE
)
AS
BEGIN
	UPDATE automated_import_class_step
	   SET auto_imp_importer_cms_id = in_cms_settings_id,
	       auto_imp_fileread_ftp_id = in_ftp_settings_id
	 WHERE automated_import_class_sid = in_import_class_sid
	   AND step_number = in_step_number
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetImportClasses(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT automated_import_class_sid, lookup_key, label, schedule_xml, last_scheduled_dtm,
			   abort_on_error, email_on_error, email_on_success, on_completion_sp,
			   import_plugin, email_on_partial, process_all_pending_files
		  FROM csr.automated_import_class
	  ORDER BY automated_import_class_sid;
END;

PROCEDURE UpdateImportClass(
	in_automated_import_class_sid		IN	automated_import_class.automated_import_class_sid%TYPE,
	in_label							IN	automated_import_class.label%TYPE,
	in_contains_pii						IN	automated_import_class.contains_pii%TYPE,
	in_lookup_key						IN	automated_import_class.lookup_key%TYPE,
	in_schedule_xml						IN	VARCHAR2,
	in_last_scheduled_dtm				IN	automated_import_class.last_scheduled_dtm%TYPE,
	in_abort_on_error					IN	automated_import_class.abort_on_error%TYPE,
	in_email_on_error					IN	automated_import_class.email_on_error%TYPE,
	in_email_on_success					IN	automated_import_class.email_on_success%TYPE,
	in_email_on_partial					IN	automated_import_class.email_on_partial%TYPE,
	in_on_completion_sp					IN	automated_import_class.on_completion_sp%TYPE,
	in_import_plugin					IN	automated_import_class.import_plugin%TYPE,
	in_process_all_pending				IN	automated_import_class.process_all_pending_files%TYPE
)
AS
	v_label								automated_import_class.label%TYPE;
	v_contains_pii						automated_import_class.contains_pii%TYPE;
	v_lookup_key						automated_import_class.lookup_key%TYPE;
	v_schedule_xml						automated_import_class.schedule_xml%TYPE;
	v_last_scheduled_dtm				automated_import_class.last_scheduled_dtm%TYPE;
	v_abort_on_error					automated_import_class.abort_on_error%TYPE;
	v_email_on_error					automated_import_class.email_on_error%TYPE;
	v_email_on_success					automated_import_class.email_on_success%TYPE;
	v_email_on_partial					automated_import_class.email_on_partial%TYPE;
	v_on_completion_sp					automated_import_class.on_completion_sp%TYPE;
	v_import_plugin						automated_import_class.import_plugin%TYPE;
	v_process_all_pending				automated_import_class.process_all_pending_files%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	BEGIN
		SELECT label, contains_pii, lookup_key, schedule_xml, last_scheduled_dtm, abort_on_error, email_on_error, email_on_success, email_on_partial, on_completion_sp, import_plugin, process_all_pending_files
		  INTO v_label, v_contains_pii, v_lookup_key, v_schedule_xml, v_last_scheduled_dtm, v_abort_on_error, v_email_on_error, v_email_on_success, v_email_on_partial, v_on_completion_sp, v_import_plugin, v_process_all_pending
		  FROM automated_import_class
		 WHERE automated_import_class_sid = in_automated_import_class_sid;
		
		UPDATE csr.automated_import_class
		   SET label = in_label,
			   contains_pii = in_contains_pii,
			   lookup_key = in_lookup_key,
			   schedule_xml = SYS.XMLTYPE.CREATEXML(in_schedule_xml), 
			   last_scheduled_dtm = in_last_scheduled_dtm,
			   abort_on_error = in_abort_on_error,
			   email_on_error = in_email_on_error,
			   email_on_success = in_email_on_success,
			   email_on_partial = in_email_on_partial,
			   on_completion_sp = in_on_completion_sp,
			   import_plugin = in_import_plugin,
			   process_all_pending_files = in_process_all_pending
		 WHERE automated_import_class_sid = in_automated_import_class_sid;
		 
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'label', in_label, v_label);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'contains pii', in_contains_pii, v_contains_pii);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'lookup key', in_lookup_key, v_lookup_key);
		 automated_import_pkg.AuditXml(in_automated_import_class_sid, NULL, 'schedule XML', in_schedule_xml, v_schedule_xml);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'last scheduled dtm', in_last_scheduled_dtm, v_last_scheduled_dtm);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'abort on error', in_abort_on_error, v_abort_on_error);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'email on error', in_email_on_error, v_email_on_error);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'email on success', in_email_on_success, v_email_on_success);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'email on partial', in_email_on_partial, v_email_on_partial);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'on completion sp', in_on_completion_sp, v_on_completion_sp);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'import plugin', in_import_plugin, v_import_plugin);
		 automated_import_pkg.AuditValue(in_automated_import_class_sid, NULL, 'process all pending', in_process_all_pending, v_process_all_pending);
		 
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An import class with that name already exists.');
	END;
END;

PROCEDURE UpdateImportClassStep(
	in_automated_import_class_sid		IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	in_on_completion_sp					IN	automated_import_class_step.on_completion_sp%TYPE,
	in_on_failure_sp					IN	automated_import_class_step.on_failure_sp%TYPE DEFAULT NULL,
	in_days_to_retain_payload			IN	automated_import_class_step.days_to_retain_payload%TYPE,
	in_plugin							IN	automated_import_class_step.plugin%TYPE,
	in_ignore_file_not_found_xcptn		IN	automated_import_class_step.ignore_file_not_found_excptn%TYPE DEFAULT 0,
	in_fileread_plugin_id				IN	automated_import_class_step.fileread_plugin_id%TYPE DEFAULT NULL,
	in_fileread_ftp_id					IN	automated_import_class_step.auto_imp_fileread_ftp_id%TYPE DEFAULT NULL,
	in_fileread_db_id					IN	automated_import_class_step.auto_imp_fileread_db_id%TYPE DEFAULT NULL,
	in_enable_decryption				IN  automated_import_class_step.enable_decryption%TYPE DEFAULT 0
)
AS
	v_on_completion_sp					automated_import_class_step.on_completion_sp%TYPE;
	v_on_failure_sp						automated_import_class_step.on_failure_sp%TYPE DEFAULT NULL;
	v_days_to_retain_payload			automated_import_class_step.days_to_retain_payload%TYPE;
	v_plugin							automated_import_class_step.plugin%TYPE;
	v_ignore_file_not_found_excptn		automated_import_class_step.plugin%TYPE;
	v_fileread_plugin_id				automated_import_class_step.ignore_file_not_found_excptn%TYPE;
	v_fileread_ftp_id					automated_import_class_step.auto_imp_fileread_ftp_id%TYPE;
	v_fileread_db_id					automated_import_class_step.auto_imp_fileread_db_id%TYPE;
	v_enable_decryption					automated_import_class_step.enable_decryption%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	SELECT on_completion_sp, on_failure_sp, days_to_retain_payload, plugin, fileread_plugin_id, auto_imp_fileread_ftp_id, auto_imp_fileread_db_id, ignore_file_not_found_excptn, enable_decryption
	  INTO v_on_completion_sp, v_on_failure_sp, v_days_to_retain_payload, v_plugin, v_fileread_plugin_id, v_fileread_ftp_id, v_fileread_db_id, v_ignore_file_not_found_excptn, v_enable_decryption
	  FROM csr.automated_import_class_step
	 WHERE automated_import_class_sid = in_automated_import_class_sid
	   AND step_number = in_step_number;
	
	UPDATE csr.automated_import_class_step
	   SET on_completion_sp = in_on_completion_sp,
	       on_failure_sp = in_on_failure_sp,
	       days_to_retain_payload = in_days_to_retain_payload,
		   plugin = in_plugin,
		   ignore_file_not_found_excptn = in_ignore_file_not_found_xcptn,
		   enable_decryption = in_enable_decryption
	 WHERE automated_import_class_sid = in_automated_import_class_sid
	   AND step_number = in_step_number;

	-- Update in_fileread_plugin_id, in_fileread_ftp_id and in_fileread_db_id eparately  
	-- as it looks like we want to leave then asa-is if the caller passed NULL
	UPDATE csr.automated_import_class_step
	   SET fileread_plugin_id = NVL(in_fileread_plugin_id, fileread_plugin_id),
	       -- XXX: Yuck - allow passig -1 to clear down the fileread id. We can't just 
	       -- use null as calling code expects null passed in to meean "leave it alone"
	       auto_imp_fileread_ftp_id = DECODE(in_fileread_ftp_id, -1, NULL, NVL(in_fileread_ftp_id, auto_imp_fileread_ftp_id)),
	       auto_imp_fileread_db_id = DECODE(in_fileread_db_id, -1, NULL, NVL(in_fileread_db_id, auto_imp_fileread_db_id))
	 WHERE automated_import_class_sid = in_automated_import_class_sid
		   AND step_number = in_step_number;

	-- Audit changes
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'on completion SP', in_on_completion_sp, v_on_completion_sp);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'on failure SP', in_on_failure_sp, v_on_failure_sp);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'days to retain payload', in_days_to_retain_payload, v_days_to_retain_payload);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'plugin', in_plugin, v_plugin);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'Ignore file not found exception', in_ignore_file_not_found_xcptn, v_ignore_file_not_found_excptn);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'enable_decryption', in_enable_decryption, v_enable_decryption);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'file read plugin id', in_fileread_plugin_id, v_fileread_plugin_id);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'file read ftp id', in_fileread_ftp_id, v_fileread_ftp_id);
	automated_import_pkg.AuditValue(in_automated_import_class_sid, in_step_number, 'file read db id', in_fileread_db_id, v_fileread_db_id);

END;

PROCEDURE GetFtpFileReaderSettings(
	out_cur						 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT classes.automated_import_class_sid, payload_path, file_mask, sort_by,
			   sort_by_direction, move_to_path_on_success, move_to_path_on_error,
			   delete_on_success, delete_on_error, step_number, classes.label
		  FROM csr.automated_import_class_step steps
		  JOIN csr.auto_imp_fileread_ftp readers
			ON steps.auto_imp_fileread_ftp_id = readers.auto_imp_fileread_ftp_id
		  JOIN csr.automated_import_class classes
			ON steps.automated_import_class_sid = classes.automated_import_class_sid
	  ORDER BY automated_import_class_sid, step_number;
END;

PROCEDURE UpdateFtpFileReaderSettings(
	in_sid						  	IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				  	IN automated_import_class_step.step_number%TYPE,
	in_ftp_profile_id				IN auto_imp_fileread_ftp.ftp_profile_id%TYPE,
	in_payload_path				 	IN auto_imp_fileread_ftp.payload_path%TYPE,
	in_file_mask					IN auto_imp_fileread_ftp.file_mask%TYPE,
	in_sort_by					  	IN auto_imp_fileread_ftp.sort_by%TYPE,
	in_sort_by_dir				  	IN auto_imp_fileread_ftp.sort_by_direction%TYPE,
	in_move_to_path_on_success	  	IN auto_imp_fileread_ftp.move_to_path_on_success%TYPE,
	in_move_to_path_on_error		IN auto_imp_fileread_ftp.move_to_path_on_error%TYPE,
	in_delete_on_success			IN auto_imp_fileread_ftp.delete_on_success%TYPE,
	in_delete_on_error			  	IN auto_imp_fileread_ftp.delete_on_error%TYPE
)
AS
	v_fileread_ftp_id				auto_imp_fileread_ftp.auto_imp_fileread_ftp_id%TYPE;
	v_ftp_profile_id				auto_imp_fileread_ftp.ftp_profile_id%TYPE;
	v_payload_path				 	auto_imp_fileread_ftp.payload_path%TYPE;
	v_file_mask						auto_imp_fileread_ftp.file_mask%TYPE;
	v_sort_by					  	auto_imp_fileread_ftp.sort_by%TYPE;
	v_sort_by_dir				  	auto_imp_fileread_ftp.sort_by_direction%TYPE;
	v_move_to_path_on_success	  	auto_imp_fileread_ftp.move_to_path_on_success%TYPE;
	v_move_to_path_on_error			auto_imp_fileread_ftp.move_to_path_on_error%TYPE;
	v_delete_on_success				auto_imp_fileread_ftp.delete_on_success%TYPE;
	v_delete_on_error				auto_imp_fileread_ftp.delete_on_error%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	SELECT ftp.auto_imp_fileread_ftp_id, ftp_profile_id, payload_path, file_mask, sort_by, sort_by_direction, move_to_path_on_success, move_to_path_on_error, delete_on_success, delete_on_error
	  INTO v_fileread_ftp_id, v_ftp_profile_id, v_payload_path, v_file_mask, v_sort_by, v_sort_by_dir, v_move_to_path_on_success, v_move_to_path_on_error, v_delete_on_success, v_delete_on_error
	  FROM csr.automated_import_class_step step 
	  JOIN auto_imp_fileread_ftp ftp ON step.auto_imp_fileread_ftp_id = ftp.auto_imp_fileread_ftp_id
	 WHERE automated_import_class_sid = in_sid
	   AND step_number = in_step_number
	   AND ftp.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE auto_imp_fileread_ftp
	   SET ftp_profile_id = in_ftp_profile_id,
		   payload_path = in_payload_path,
		   file_mask = in_file_mask,
		   sort_by = in_sort_by,
		   sort_by_direction = in_sort_by_dir,
		   move_to_path_on_success = in_move_to_path_on_success,
		   move_to_path_on_error = in_move_to_path_on_error,
		   delete_on_success = in_delete_on_success,
		   delete_on_error = in_delete_on_error
	 WHERE auto_imp_fileread_ftp_id = v_fileread_ftp_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'FTP profile', in_ftp_profile_id, v_ftp_profile_id);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'payload path', in_payload_path, v_payload_path);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'file mask', in_file_mask, v_file_mask);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'sort by', in_sort_by, v_sort_by);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'sort by dir', in_sort_by_dir, v_sort_by_dir);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'move to path on success', in_move_to_path_on_success, v_move_to_path_on_success);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'move to path on error', in_move_to_path_on_error, v_move_to_path_on_error);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'delete on success', in_delete_on_success, v_delete_on_success);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'delete on error', in_delete_on_error, v_delete_on_error);

END;

PROCEDURE GetCmsImportSettings(
	out_cur						 	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT classes.automated_import_class_sid, step_number, steps.auto_imp_importer_cms_id AS auto_imp_importer_cms_id,
			   tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals,
			   excel_worksheet_index, all_or_nothing, header_row, classes.label
		  FROM csr.automated_import_class_step steps
		  JOIN csr.auto_imp_importer_cms cms
			ON steps.auto_imp_importer_cms_id = cms.auto_imp_importer_cms_id
		  JOIN csr.automated_import_class classes
			ON steps.automated_import_class_sid = classes.automated_import_class_sid
	  ORDER BY automated_import_class_sid, step_number;
END;

PROCEDURE UpdateCmsImportSettings(
	in_sid						  	IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				  	IN automated_import_class_step.step_number%TYPE,
	in_tab_sid					  	IN auto_imp_importer_cms.tab_sid%TYPE DEFAULT NULL,
	in_mapping_xml				  	IN VARCHAR2,
	in_cms_imp_file_type_id		 	IN auto_imp_importer_cms.cms_imp_file_type_id%TYPE,
	in_dsv_separator				IN auto_imp_importer_cms.dsv_separator%TYPE,
	in_dsv_quotes_as_literals	   	IN auto_imp_importer_cms.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN auto_imp_importer_cms.excel_worksheet_index%TYPE,
	in_all_or_nothing			   	IN auto_imp_importer_cms.all_or_nothing%TYPE,
	in_header_row				   	IN auto_imp_importer_cms.header_row%TYPE
)
AS
	v_tab_sid						auto_imp_importer_cms.tab_sid%TYPE;
	v_settings_id					auto_imp_importer_cms.auto_imp_importer_cms_id%TYPE;
	v_old_tab_sid					auto_imp_importer_cms.tab_sid%TYPE;
	v_mapping_xml				  	auto_imp_importer_cms.mapping_xml%TYPE;
	v_cms_imp_file_type_id		 	auto_imp_importer_cms.cms_imp_file_type_id%TYPE;
	v_dsv_separator					auto_imp_importer_cms.dsv_separator%TYPE;
	v_dsv_quotes_as_literals	   	auto_imp_importer_cms.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index			auto_imp_importer_cms.excel_worksheet_index%TYPE;
	v_all_or_nothing			   	auto_imp_importer_cms.all_or_nothing%TYPE;
	v_header_row				   	auto_imp_importer_cms.header_row%TYPE;
	v_tab_exists					NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	IF in_tab_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_tab_exists
		  FROM cms.tab
		 WHERE tab_sid = in_tab_sid;
		 
		 IF v_tab_exists = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Not a valid tab sid.');
		 END IF;
	END IF;
	
	SELECT auto_imp_importer_cms_id
	  INTO v_settings_id
	  FROM automated_import_class_step
	 WHERE automated_import_class_sid = in_sid
	   AND step_number = in_step_number
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT NVL(in_tab_sid, tab_sid), tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing, header_row
	  INTO v_tab_sid, v_old_tab_sid, v_mapping_xml, v_cms_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals, v_excel_worksheet_index, v_all_or_nothing, v_header_row
	  FROM auto_imp_importer_cms
	 WHERE auto_imp_importer_cms_id = v_settings_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE auto_imp_importer_cms
	   SET tab_sid = v_tab_sid,
		   mapping_xml = in_mapping_xml,
	       cms_imp_file_type_id = in_cms_imp_file_type_id,
	       dsv_separator = in_dsv_separator,
	       dsv_quotes_as_literals = in_dsv_quotes_as_literals,
	       excel_worksheet_index = in_excel_worksheet_index,
	       all_or_nothing = in_all_or_nothing,
	       header_row = in_header_row
	 WHERE auto_imp_importer_cms_id = v_settings_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'tab sid', in_tab_sid, v_old_tab_sid);
	automated_import_pkg.AuditXml(in_sid, in_step_number, 'mapping xml', in_mapping_xml, v_mapping_xml);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'file type id', in_cms_imp_file_type_id, v_cms_imp_file_type_id);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'dsv separator', in_dsv_separator, v_dsv_separator);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'dsv quotes as literals', in_dsv_quotes_as_literals, v_dsv_quotes_as_literals);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'excel worksheet index', in_excel_worksheet_index, v_excel_worksheet_index);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'all or nothing', in_all_or_nothing, v_all_or_nothing);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'header row', in_header_row, v_header_row);

END;

PROCEDURE UpdateDbFileReaderSettings(
	in_sid						  	IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				  	IN automated_import_class_step.step_number%TYPE,
	in_filedata_sp					IN auto_imp_fileread_db.filedata_sp%TYPE
)
AS
	v_settings_id					auto_imp_fileread_db.auto_imp_fileread_db_id%TYPE;
	v_filedata_sp					auto_imp_fileread_db.filedata_sp%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	SELECT step.auto_imp_fileread_db_id, filedata_sp
	  INTO v_settings_id, v_filedata_sp
	  FROM automated_import_class_step step
	  JOIN auto_imp_fileread_db db on db.auto_imp_fileread_db_id = step.auto_imp_fileread_db_id
	 WHERE automated_import_class_sid = in_sid
	   AND step_number = in_step_number
	   AND step.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	  
	
	UPDATE auto_imp_fileread_db
	   SET filedata_sp = in_filedata_sp
	 WHERE auto_imp_fileread_db_id = v_settings_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'filedata SP', in_filedata_sp, v_filedata_sp);

END;

PROCEDURE UpdateMeterImportSettings(
	in_sid							IN automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number					IN automated_import_class_step.step_number%TYPE,
	in_mapping_xml					IN auto_imp_importer_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN auto_imp_importer_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN auto_imp_importer_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN auto_imp_importer_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN auto_imp_importer_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN auto_imp_importer_settings.all_or_nothing%TYPE
)
AS
	v_mapping_xml					auto_imp_importer_settings.mapping_xml%TYPE;
	v_imp_file_type_id				auto_imp_importer_settings.automated_import_file_type_id%TYPE;
	v_dsv_separator					auto_imp_importer_settings.dsv_separator%TYPE;
	v_dsv_quotes_as_literals		auto_imp_importer_settings.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index			auto_imp_importer_settings.excel_worksheet_index%TYPE;
	v_all_or_nothing				auto_imp_importer_settings.all_or_nothing%TYPE;
	v_tab_exists					NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	SELECT mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing
	  INTO v_mapping_xml, v_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals, v_excel_worksheet_index, v_all_or_nothing
	  FROM auto_imp_importer_settings
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = in_sid
	   AND step_number = in_step_number;
	
	UPDATE auto_imp_importer_settings
	   SET mapping_xml = in_mapping_xml,
	       automated_import_file_type_id = in_imp_file_type_id,
	       dsv_separator = in_dsv_separator,
	       dsv_quotes_as_literals = in_dsv_quotes_as_literals,
	       excel_worksheet_index = in_excel_worksheet_index,
	       all_or_nothing = in_all_or_nothing
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = in_sid
	   AND step_number = in_step_number;
	
	automated_import_pkg.AuditXml(in_sid, in_step_number, 'mapping xml', in_mapping_xml, v_mapping_xml);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'file type id', in_imp_file_type_id, v_imp_file_type_id);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'dsv separator', in_dsv_separator, v_dsv_separator);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'dsv quotes as literals', in_dsv_quotes_as_literals, v_dsv_quotes_as_literals);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'excel worksheet index', in_excel_worksheet_index, v_excel_worksheet_index);
	automated_import_pkg.AuditValue(in_sid, in_step_number, 'all or nothing', in_all_or_nothing, v_all_or_nothing);

END;

PROCEDURE GetFileTypes(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT automated_import_file_type_id, label
		  FROM automated_import_file_type;

END;

PROCEDURE GetImporters(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT plugin_id, label
		  FROM auto_imp_importer_plugin
		 ORDER BY plugin_id ASC;

END;

PROCEDURE GetFileReaders(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT plugin_id, label
		  FROM auto_imp_fileread_plugin
		 ORDER BY plugin_id ASC;

END;

PROCEDURE GetFileFromPreviousStep(
	in_importclass_sid				IN	security.security_pkg.T_SID_ID,
	in_instance_id					IN	LONG,
	in_step_number					IN	LONG,
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid				security.security_pkg.T_SID_ID;
	v_check_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	-- Return a cursor with the data blob and file name as parameters named "data_file" and "data_filename"
	OPEN out_cur FOR
		SELECT payload data_file, payload_filename data_filename
		  FROM automated_import_instance_step 
		 WHERE app_sid = v_app_sid 
		   AND automated_import_instance_id = in_instance_id 
		   AND step_number = in_step_number -1;
END;

-- CORE DATA IMPORTER SPs

PROCEDURE GetIndSidFromDescription(
	in_description		IN	ind_description.description%TYPE,
	out_ind_sid			OUT	ind_description.ind_sid%TYPE
)
AS
	v_a 				security_pkg.T_VARCHAR2_ARRAY;
BEGIN

	BEGIN
		indicator_pkg.LookupIndicator(in_description, v_a, out_ind_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_ind_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_ind_sid := -1;
	END;	

END;

PROCEDURE GetIndSidFromLookupKey(
	in_text				IN	ind.lookup_key%TYPE,
	out_ind_sid			OUT	ind.ind_sid%TYPE
)
AS
BEGIN

	BEGIN
		SELECT ind_sid
		  INTO out_ind_sid
		  FROM ind
		 WHERE LOWER(lookup_key) = LOWER(in_text);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_ind_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_ind_sid := -1;
	END;	

END;

PROCEDURE GetIndSidFromMapTable(
	in_text				IN	ind.lookup_key%TYPE,
	in_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_step_number		IN	automated_import_class_step.step_number%TYPE,
	out_ind_sid			OUT	ind.ind_sid%TYPE
)
AS
BEGIN

	BEGIN
		SELECT NVL(ind_sid, -2)
		  INTO out_ind_sid
		  FROM auto_imp_indicator_map
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND source_text = in_text;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_ind_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_ind_sid := -1;
	END;

END;

PROCEDURE GetRegionSidFromDescription(
	in_description		IN	region_description.description%TYPE,
	out_region_sid		OUT	region_description.region_sid%TYPE
)
AS
	v_a 				security_pkg.T_VARCHAR2_ARRAY;
BEGIN

	BEGIN
		region_pkg.LookupRegion(in_description, v_a, out_region_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_region_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_region_sid := -1;
	END;	

END;

PROCEDURE GetRegionSidFromLookupKey(
	in_text				IN	region.lookup_key%TYPE,
	out_region_sid		OUT	region.region_sid%TYPE
)
AS
BEGIN

	BEGIN
		SELECT region_sid
		  INTO out_region_sid
		  FROM region
		 WHERE LOWER(lookup_key) = LOWER(in_text)
		    OR LOWER(region_ref) = LOWER(in_text);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_region_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_region_sid := -1;
	END;	

END;

PROCEDURE GetRegionSidFromMapTable(
	in_text				IN	region.lookup_key%TYPE,
	in_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_step_number		IN	automated_import_class_step.step_number%TYPE,
	out_region_sid		OUT	region.region_sid%TYPE
)
AS
BEGIN

	BEGIN
		SELECT NVL(region_sid, -2)
		  INTO out_region_sid
		  FROM auto_imp_region_map
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND source_text = in_text;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_region_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_region_sid := -1;
	END;

END;

PROCEDURE GetUnitSidFromDescription(
	in_description		IN	measure_conversion.description%TYPE,
	in_ind_sid			IN	ind.ind_sid%TYPE,
	out_conv_id			OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
BEGIN

	BEGIN
		SELECT measure_conversion_id 
		  INTO out_conv_id
		  FROM measure_conversion m
		  JOIN ind i ON i.measure_sid = m.measure_sid
		 WHERE LOWER(description) = LOWER(in_description)
		   AND i.ind_sid = in_ind_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_conv_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_conv_id := -1;
	END;

END;

PROCEDURE GetUnitSidFromLookupKey(
	in_text				IN	measure_conversion.lookup_key%TYPE,
	out_conv_id			OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT measure_conversion_id 
		  INTO out_conv_id
		  FROM measure_conversion 
		 WHERE LOWER(lookup_key) = LOWER(in_text);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_conv_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_conv_id := -1;
	END;
END;

PROCEDURE GetUnitSidFromMapTable(
	in_text				IN	measure_conversion.lookup_key%TYPE,
	in_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_step_number		IN	automated_import_class_step.step_number%TYPE,
	out_conv_id			OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT NVL(measure_conversion_id, -2)
		  INTO out_conv_id
		  FROM auto_imp_unit_map
		 WHERE automated_import_class_sid = in_import_class_sid
		   AND source_text = in_text;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_conv_id := -1;
		WHEN TOO_MANY_ROWS THEN
			out_conv_id := -1;
	END;
END;

PROCEDURE CheckConversionAgainstInd (
	in_conv_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_ind_sid			IN	ind.ind_sid%TYPE,
	out_result			OUT	NUMBER
)
AS
BEGIN

	BEGIN
		SELECT CASE mc.measure_sid WHEN i.measure_sid THEN 1 ELSE 0 END result
		  INTO out_result
		  FROM measure_conversion mc, ind i
		 WHERE measure_conversion_id = in_conv_id
		   AND ind_sid = in_ind_sid;
	EXCEPTION
		WHEN OTHERS THEN
			out_result := -1;
	END;

END;

PROCEDURE InsertCoreDataPoint(
	in_instance_id				IN	NUMBER,
	in_instance_step_id			IN	NUMBER,
	in_ind_sid					IN	NUMBER,
	in_region_sid				IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	in_val_number				IN	NUMBER,
	in_measure_conversion_id	IN	NUMBER,
	in_entry_val_number			IN	NUMBER,
	in_note						IN	CLOB,
	in_source_file_ref			IN	VARCHAR2,
	out_val_id					OUT NUMBER
)
AS
	v_val_number				NUMBER;
BEGIN

	-- Get the base val number; Use measure conversion if required. 
	IF in_val_number IS NULL THEN
		IF in_measure_conversion_id IS NOT NULL AND in_entry_val_number IS NOT NULL THEN
			v_val_number := measure_pkg.UNSEC_GetBaseValue(
				in_val_number				=> in_entry_val_number,
				in_conversion_id			=> in_measure_conversion_id,
				in_dtm						=> in_start_dtm
			);
		ELSE
			-- Just use the entry value
			v_val_number := in_entry_val_number;
		END IF;
	ELSE
		v_val_number := in_val_number;
	END IF;

	BEGIN
		INSERT INTO auto_imp_core_data_val
			(val_id, instance_id, instance_step_id, ind_sid, region_sid, start_dtm, end_dtm, val_number, measure_conversion_id, entry_val_number, note, source_file_ref)
		VALUES
			(auto_imp_core_data_val_id_seq.nextval, in_instance_id, in_instance_step_id, in_ind_sid, in_region_sid, in_start_dtm, in_end_dtm, v_val_number, in_measure_conversion_id, in_entry_val_number, in_note, in_source_file_ref)
		RETURNING val_id INTO out_val_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- This shouldn't be thrown in the usual order of things. We check on the C# side, but if the job is repeated before the data has been merged, it can cause dupes. Most recent wins
			-- so that ti matches with the most recent file we have stored
			SELECT val_id
			  INTO out_val_id
			  FROM auto_imp_core_data_val
			 WHERE ind_sid = in_ind_sid
			   AND region_sid = in_region_sid
			   AND start_dtm = in_start_dtm
			   AND end_dtm = in_end_dtm
			   AND instance_step_id = in_instance_step_id;
			
			UPDATE auto_imp_core_data_val
			   SET ind_sid = in_ind_sid,
			       region_sid = in_region_sid,
				   start_dtm = in_start_dtm,
				   end_dtm = in_end_dtm,
				   val_number = in_val_number,
				   measure_conversion_id = in_measure_conversion_id,
				   entry_val_number = in_entry_val_number,
				   note = in_note,
				   source_file_ref = in_source_file_ref
			 WHERE val_id = out_val_id;
	END;
END;

PROCEDURE WriteCoreDataFailedRow(
	in_instance_id				IN	NUMBER,
	in_instance_step_id			IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	in_entry_val_number			IN	NUMBER,
	in_note						IN	CLOB,
	in_source_file_ref			IN	VARCHAR2,
	in_ind_sid					IN	NUMBER,
	in_ind_text					IN	VARCHAR2,
	in_region_sid				IN	NUMBER,
	in_region_text				IN	VARCHAR2,
	in_measure_conversion_id	IN	NUMBER,
	in_measure_conversion_text	IN	VARCHAR2
)
AS
	v_val_number				NUMBER;
BEGIN

	INSERT INTO auto_imp_core_data_val_fail
		(val_id, instance_id, instance_step_id, start_dtm, end_dtm, val_number, note, source_file_ref, ind_sid, ind_text, region_sid,
		 region_text, measure_conversion_id, measure_text)
	VALUES
		(auto_imp_core_data_val_id_seq.nextval, in_instance_id, in_instance_step_id, in_start_dtm, in_end_dtm, in_entry_val_number, in_note, in_source_file_ref, in_ind_sid, in_ind_text, in_region_sid, 
		 in_region_text, in_measure_conversion_id, in_measure_conversion_text);
	-- TODO - This needs to move elsewhere.
	UPDATE automated_import_instance_step
	   SET custom_url = '/csr/site/automatedExportImport/coreDataMapping.acds?classSid='||automated_import_class_sid,
	       custom_url_title = 'Remap failed rows'
	 WHERE automated_import_instance_id = in_instance_id
	   AND auto_import_instance_step_id = in_instance_step_id;
END;

PROCEDURE GetFailedMappingsForClass(
	in_class_sid			IN	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT object_type, source_text, row_count, recent_instance_id, bj.started_dtm recent_instance_dtm
		  FROM (
			SELECT 'region' object_type, region_text source_text, COUNT(region_text) row_count, max(instance_id) recent_instance_id
			  FROM auto_imp_core_data_val_fail fail
			  JOIN automated_import_instance inst ON inst.automated_import_instance_id = fail.instance_id
			 WHERE region_sid IS NULL
			   AND inst.automated_import_class_sid = in_class_sid
			   AND NOT EXISTS
					(SELECT 1 FROM auto_imp_region_map airm WHERE airm.automated_import_class_sid = in_class_sid AND airm.source_text = region_text)
			 GROUP BY region_text
			UNION
			SELECT 'indicator' object_type, ind_text source_text, COUNT(ind_text) row_count, max(instance_id) recent_instance_id
			  FROM auto_imp_core_data_val_fail fail
			  JOIN automated_import_instance inst ON inst.automated_import_instance_id = fail.instance_id
			 WHERE ind_sid IS NULL
			   AND inst.automated_import_class_sid = in_class_sid
			   AND NOT EXISTS
					(SELECT 1 FROM auto_imp_indicator_map aiim WHERE aiim.automated_import_class_sid = in_class_sid AND aiim.source_text = ind_text)
			 GROUP BY ind_text
			UNION
			SELECT 'measure' object_type, measure_text source_text, COUNT(measure_text) row_count, max(instance_id) recent_instance_id
			  FROM auto_imp_core_data_val_fail fail
			  JOIN automated_import_instance inst ON inst.automated_import_instance_id = fail.instance_id
			 WHERE measure_conversion_id IS NULL
			   AND measure_text IS NOT NULL
			   AND inst.automated_import_class_sid = in_class_sid
			   AND NOT EXISTS
					(SELECT 1 FROM auto_imp_unit_map aium WHERE aium.automated_import_class_sid = in_class_sid AND aium.source_text = measure_text)
			 GROUP BY measure_text
		) f
		  JOIN automated_import_instance inst on f.recent_instance_id = inst.automated_import_instance_id
		  JOIN batch_job bj on bj.batch_job_id = inst.batch_job_id;

END;

PROCEDURE GetMappingsForClass(
	in_class_sid			IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_region_cur FOR
		SELECT source_text, region_sid sid, CASE WHEN region_sid IS NULL THEN 'Ignored' ELSE region_pkg.GetRegionPathStringFromStPt(region_sid) END description
		  FROM auto_imp_region_map
		 WHERE automated_import_class_sid = in_class_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	OPEN out_ind_cur FOR
		SELECT source_text, ind_sid sid, CASE WHEN ind_sid IS NULL THEN 'Ignored' ELSE indicator_pkg.INTERNAL_GetIndPathString(ind_sid) END description
		  FROM auto_imp_indicator_map
		 WHERE automated_import_class_sid = in_class_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	OPEN out_measure_cur FOR
		SELECT source_text, map.measure_conversion_id sid, CASE WHEN m.description IS NULL THEN 'ignored' ELSE m.description||': '||mc.description END description
		  FROM auto_imp_unit_map map
		  LEFT JOIN measure_conversion mc ON mc.measure_conversion_id = map.measure_conversion_id
		  LEFT JOIN measure m ON m.measure_sid = mc.measure_sid
		 WHERE automated_import_class_sid = in_class_sid
		   AND map.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE UpsertRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_region_map.source_text%TYPE,
	in_region_sid			IN	auto_imp_region_map.region_sid%TYPE,
	out_val_id				OUT NUMBER
)
AS
v_upsert_check				NUMBER(1);
v_old_mapping				VARCHAR2(4000);
v_new_mapping				VARCHAR2(4000);

BEGIN
	BEGIN
		SELECT source_text || ' - ' || region_sid old_mapping
		  INTO v_old_mapping
		  FROM auto_imp_region_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;

	SELECT COUNT(*) INTO out_val_id
	  FROM region
	 WHERE region_sid = in_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF out_val_id != 0 THEN --only upsert if we're given a valid in_region_sid
		SELECT COUNT(*) INTO v_upsert_check
		  FROM auto_imp_region_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;

		IF v_upsert_check = 0 THEN
			AddRegionMapping(
				in_class_sid	=>	in_class_sid,
				in_source_text	=>	in_source_text,
				in_region_sid	=>	in_region_sid);
		ELSE
			UPDATE auto_imp_region_map
			   SET region_sid = in_region_sid
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND automated_import_class_sid = in_class_sid
			   AND source_text = in_source_text;
		END IF;

		SELECT source_text || ' - ' || region_sid new_mapping
		  INTO v_new_mapping
		  FROM auto_imp_region_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;

		automated_import_pkg.AuditValue(
			in_class_sid	=>	in_class_sid,
			in_field		=>	'Region mapping changed',
			in_new_val		=>	v_new_mapping,
			in_old_val		=>	v_old_mapping);
	END IF;

END;

PROCEDURE GetRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur				 	OUT	sys_refcursor
)
AS

	v_search_query				  	VARCHAR2(102);

BEGIN

	v_search_query := '%' || LOWER(in_search_string) || '%';

	 OPEN out_cur FOR

		SELECT rn, total_rows, class_sid, source_text, sid, CASE WHEN sid IS NULL THEN 'Ignored' ELSE csr.region_pkg.GetRegionPathStringFromStPt(sid) END description
		  FROM (
				SELECT ROW_NUMBER() over (ORDER BY source_text) rn, COUNT(*) over () total_rows,  airm.automated_import_class_sid class_sid, airm.source_text, airm.region_sid sid
				  FROM csr.auto_imp_region_map airm
				  LEFT JOIN csr.region r ON airm.region_sid = r.region_sid
				  LEFT JOIN csr.v$region vr ON airm.region_sid = vr.region_sid
				 WHERE airm.app_sid = SYS_CONTEXT('security', 'app')
				   AND automated_import_class_sid = in_class_sid
				   AND (v_search_query IS NULL 
						OR LOWER(source_text) LIKE v_search_query 
						OR LOWER(airm.region_sid) LIKE v_search_query 
						OR LOWER(CASE WHEN airm.region_sid IS NULL THEN 'Ignored' ELSE vr.description end) like v_search_query   
						)
			   ) r
		 WHERE rn > in_start_row 
		   AND rn <= in_start_row + in_page_size;
end;

PROCEDURE GetIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur				 	OUT	sys_refcursor
)
AS

	v_search_query				  	VARCHAR2(102);

BEGIN

	v_search_query := '%' || LOWER(in_search_string) || '%';

	 OPEN out_cur FOR

		SELECT rn, total_rows, automated_import_class_sid, source_text, sid, description
		  FROM(
				SELECT ROW_NUMBER() over (ORDER BY source_text) rn, count(*) over () total_rows,  aiim.automated_import_class_sid, aiim.source_text, aiim.ind_sid sid, CASE WHEN aiim.ind_sid IS NULL THEN 'Ignored' ELSE indicator_pkg.INTERNAL_GetIndPathString(aiim.ind_sid) END description
				  FROM csr.auto_imp_indicator_map aiim
				  LEFT JOIN csr.ind i ON aiim.ind_sid = i.ind_sid
				  LEFT JOIN v$ind vi ON aiim.ind_sid = vi.ind_sid
				 WHERE aiim.app_sid = SYS_CONTEXT('security', 'app')
				   AND automated_import_class_sid = in_class_sid
				   AND (v_search_query IS NULL 
						OR LOWER(source_text) LIKE v_search_query 
						OR LOWER(aiim.ind_sid) LIKE v_search_query
						OR LOWER(CASE WHEN aiim.ind_sid IS NULL THEN 'Ignored' ELSE vi.description END ) LIKE v_search_query
						)
			   ) i
		 WHERE rn > in_start_row 
		   AND rn <= in_start_row + in_page_size
			 ;
END;

PROCEDURE GetMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur				 	OUT	sys_refcursor
)
AS

	v_search_query				  	VARCHAR2(102);

BEGIN

	v_search_query := '%' || LOWER(in_search_string) || '%';

	 OPEN out_cur FOR
	 
		SELECT rn, total_rows, automated_import_class_sid, source_text, sid, description
		  FROM(
				SELECT ROW_NUMBER() over (ORDER BY source_text) rn, COUNT(*) over () total_rows,  aium.automated_import_class_sid, aium.source_text, aium.measure_conversion_id sid, CASE WHEN aium.measure_conversion_id IS NULL THEN 'Ignored' ELSE m.description||': '||mc.description END description
				  FROM csr.auto_imp_unit_map aium
				  LEFT JOIN measure_conversion mc ON mc.measure_conversion_id = aium.measure_conversion_id
				  LEFT JOIN measure m ON m.measure_sid = mc.measure_sid
				 WHERE aium.app_sid = SYS_CONTEXT('security', 'app')
				   AND automated_import_class_sid = in_class_sid
				   AND (v_search_query IS NULL 
						OR LOWER(source_text) LIKE v_search_query 
						OR LOWER(aium.measure_conversion_id) LIKE v_search_query
						OR LOWER(CASE WHEN aium.measure_conversion_id IS NULL THEN 'Ignored' ELSE m.description||': '||mc.description END) LIKE v_search_query
						)
			   ) m
		 WHERE rn > in_start_row 
		   AND rn <= in_start_row + in_page_size
			 ;
END;

PROCEDURE GetFailureMapping(
	in_class_sid			IN	NUMBER,
	in_start_row			IN  NUMBER,
	in_page_size			IN  NUMBER,
	in_search_string		IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS

	v_search_query				  	VARCHAR2(102);

BEGIN

	v_search_query := '%' || LOWER(in_search_string) || '%';

	OPEN out_cur FOR
		SELECT * 
		  FROM (
				SELECT ROW_NUMBER() over (ORDER BY object_type, source_text) rn, COUNT(*) over () total_rows, object_type, source_text, recent_instance_id, bj.started_dtm recent_instance_dtm, row_count
				  FROM (
						SELECT 'region' object_type, region_text source_text, MAX(instance_id) recent_instance_id, COUNT(region_text) row_count
						  FROM csr.auto_imp_core_data_val_fail fail
						  JOIN csr.automated_import_instance inst ON inst.automated_import_instance_id = fail.instance_id
						 WHERE region_sid IS NULL
						   AND inst.automated_import_class_sid = IN_CLASS_SID
						   AND NOT EXISTS
							   (SELECT 1 FROM csr.auto_imp_region_map airm WHERE airm.automated_import_class_sid = IN_CLASS_SID AND airm.source_text = region_text)
						   AND (v_search_query IS NULL 
								OR LOWER(region_text) LIKE v_search_query)
						 GROUP BY 'region', region_text
						 UNION
						SELECT 'indicator' object_type, ind_text source_text, MAX(instance_id) recent_instance_id, COUNT(ind_text) row_count
						  FROM csr.auto_imp_core_data_val_fail fail
						  JOIN csr.automated_import_instance inst ON inst.automated_import_instance_id = fail.instance_id
						 WHERE ind_sid IS NULL
						   AND inst.automated_import_class_sid = IN_CLASS_SID
						   AND NOT EXISTS
							   (SELECT 1 FROM csr.auto_imp_indicator_map aiim WHERE aiim.automated_import_class_sid = IN_CLASS_SID AND aiim.source_text = ind_text)
						   AND (v_search_query IS NULL 
								OR LOWER(ind_text) LIKE v_search_query)
						 GROUP BY 'indicator', ind_text
						 UNION
						SELECT 'measure' object_type, measure_text source_text, MAX(instance_id) recent_instance_id, COUNT(measure_text) row_count
						  FROM csr.auto_imp_core_data_val_fail fail
						  JOIN csr.automated_import_instance inst ON inst.automated_import_instance_id = fail.instance_id
						 WHERE measure_conversion_id IS NULL
						   AND measure_text IS NOT NULL
						   AND inst.automated_import_class_sid = IN_CLASS_SID
						   AND NOT EXISTS
							   (SELECT 1 FROM csr.auto_imp_unit_map aium WHERE aium.automated_import_class_sid = IN_CLASS_SID AND aium.source_text = measure_text)
						   AND (v_search_query IS NULL 
							   OR LOWER(measure_text) LIKE v_search_query)
						 GROUP BY 'measure', measure_text
						) f
				  JOIN automated_import_instance inst ON f.recent_instance_id = inst.automated_import_instance_id
				  JOIN batch_job bj ON bj.batch_job_id = inst.batch_job_id
				)q
		WHERE rn > in_start_row 
		  AND rn <= in_start_row + in_page_size;

END;

PROCEDURE AddRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_region_map.source_text%TYPE,
	in_region_sid			IN	auto_imp_region_map.region_sid%TYPE
)
AS
BEGIN

	AssertWritePermOnImportClass(in_class_sid);

	BEGIN
		INSERT INTO auto_imp_region_map
			(automated_import_class_sid, source_text, region_sid)
		VALUES
			(in_class_sid, in_source_text, in_region_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A mapping with that source text already exists.');
	END;
	
	-- Update any failed rows for the class and then process them
	UPDATE auto_imp_core_data_val_fail
	   SET region_sid = in_region_sid
	 WHERE region_text = in_source_text
	   AND region_sid IS NULL
	   AND instance_id IN (
			SELECT automated_import_instance_id
			  FROM automated_import_instance
			 WHERE automated_import_class_sid = in_class_sid
	   )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	FOR r IN (
		SELECT val_id
		  FROM auto_imp_core_data_val_fail
		 WHERE region_text = in_source_text
		   AND region_sid IS NOT NULL
		   AND ind_sid IS NOT NULL
		   AND instance_id IN (
				SELECT automated_import_instance_id
				  FROM automated_import_instance
				 WHERE automated_import_class_sid = in_class_sid
		   )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY val_id ASC
	)
	LOOP
		ProcessFailedRow(r.val_id);
	END LOOP;
	
END;

PROCEDURE UpsertIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_indicator_map.source_text%TYPE,
	in_ind_sid				IN	auto_imp_indicator_map.ind_sid%TYPE,
	out_val_id				OUT NUMBER
)
AS
v_upsert_check				NUMBER(1);
v_old_mapping				VARCHAR2(4000);
v_new_mapping				VARCHAR2(4000);

BEGIN
	BEGIN
		SELECT source_text || ' - ' || ind_sid old_mapping
		  INTO v_old_mapping
		  FROM auto_imp_indicator_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;

	SELECT COUNT(*) INTO out_val_id
	  FROM ind
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF out_val_id != 0 THEN	--only upsert if we're given a valid in_ind_sid
		SELECT COUNT(*) INTO v_upsert_check
		  FROM auto_imp_indicator_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;

		IF v_upsert_check = 0 THEN
			AddIndicatorMapping(
				in_class_sid	=>	in_class_sid,
				in_source_text	=>	in_source_text,
				in_ind_sid		=>	in_ind_sid);
		ELSE
			UPDATE auto_imp_indicator_map
			   SET ind_sid = in_ind_sid
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND automated_import_class_sid = in_class_sid
			   AND source_text = in_source_text;
		END IF;
		
		SELECT source_text || ' - ' || ind_sid new_mapping
		  INTO v_new_mapping
		  FROM auto_imp_indicator_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;

		automated_import_pkg.AuditValue(
			in_class_sid	=>	in_class_sid,
			in_field		=>	'Indicator mapping changed',
			in_new_val		=>	v_new_mapping,
			in_old_val		=>	v_old_mapping);	
	END IF;
	
END;

PROCEDURE AddIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_indicator_map.source_text%TYPE,
	in_ind_sid				IN	auto_imp_indicator_map.ind_sid%TYPE
)
AS
BEGIN

	AssertWritePermOnImportClass(in_class_sid);

	BEGIN
		INSERT INTO auto_imp_indicator_map
			(automated_import_class_sid, source_text, ind_sid)
		VALUES
			(in_class_sid, in_source_text, in_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A mapping with that source text already exists.');
	END;
	
	-- Update any failed rows for the class and then process them
	FOR r IN (
		SELECT val_id 
		  FROM auto_imp_core_data_val_fail
		 WHERE ind_text = in_source_text
		   AND ind_sid IS NULL
		   AND instance_id IN (
			SELECT automated_import_instance_id
			  FROM automated_import_instance
			 WHERE automated_import_class_sid = in_class_sid
		   )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		UPDATE auto_imp_core_data_val_fail
		   SET ind_sid = in_ind_sid
		 WHERE val_id = r.val_id;
		 
		 ProcessFailedRow(r.val_id);
	END LOOP;
END;

PROCEDURE UpsertMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_unit_map.source_text%TYPE,
	in_measure_conv_id		IN	auto_imp_unit_map.measure_conversion_id%TYPE,
	out_val_id				OUT NUMBER
)
AS
v_upsert_check				NUMBER(1);
v_old_mapping				VARCHAR2(4000);
v_new_mapping				VARCHAR2(4000);

BEGIN
	BEGIN
		SELECT source_text || ' - ' || measure_conversion_id old_mapping
		  INTO v_old_mapping
		  FROM auto_imp_unit_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN NULL;
	END;

	SELECT COUNT(*) INTO out_val_id
	  FROM measure_conversion
	 WHERE measure_conversion_id = in_measure_conv_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF out_val_id != 0 THEN --only upsert if we're given a valid measure_conv_id
		SELECT COUNT(*) INTO v_upsert_check
		  FROM auto_imp_unit_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;

		IF v_upsert_check = 0 THEN
			AddMeasureMapping(
				in_class_sid		=>	in_class_sid,
				in_source_text		=>	in_source_text,
				in_measure_conv_id	=>	in_measure_conv_id);
		ELSE
			UPDATE auto_imp_unit_map
			   SET measure_conversion_id = in_measure_conv_id
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND automated_import_class_sid = in_class_sid
			   AND source_text = in_source_text;
		END IF;
		
		SELECT source_text || ' - ' || measure_conversion_id new_mapping
		  INTO v_new_mapping
		  FROM auto_imp_unit_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND source_text = in_source_text;
		
		automated_import_pkg.AuditValue(
			in_class_sid	=>	in_class_sid,
			in_field		=>	'Meaure mapping changed',
			in_new_val		=>	v_new_mapping,
			in_old_val		=>	v_old_mapping);
	END IF;

END;

PROCEDURE AddMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_unit_map.source_text%TYPE,
	in_measure_conv_id		IN	auto_imp_unit_map.measure_conversion_id%TYPE
)
AS
BEGIN

	AssertWritePermOnImportClass(in_class_sid);
	
	BEGIN
		INSERT INTO auto_imp_unit_map
			(automated_import_class_sid, source_text, measure_conversion_id)
		VALUES
			(in_class_sid, in_source_text, in_measure_conv_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A mapping with that source text already exists.');
	END;
	
	-- Update any failed rows for the class
	-- HOWEVER we don't process failed rows for unit because they can't cause the row to be complete;
	-- ie if it is a failed row, it must be missing region and/or ind sid, as a null conversion id is fine.
	FOR r IN (
		SELECT val_id 
		  FROM auto_imp_core_data_val_fail
		 WHERE measure_text = in_source_text
		   AND measure_conversion_id IS NULL
		   AND instance_id IN (
			SELECT automated_import_instance_id
			  FROM automated_import_instance
			 WHERE automated_import_class_sid = in_class_sid
		   )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		UPDATE auto_imp_core_data_val_fail
		   SET measure_conversion_id = in_measure_conv_id
		 WHERE val_id = r.val_id;
	END LOOP;
	
END;

PROCEDURE DeleteRegionMapping(
	in_class_sid			IN	auto_imp_region_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_region_map.source_text%TYPE
)
AS

v_old_mapping				VARCHAR2(4000);

BEGIN

	SELECT source_text || ' - ' || region_sid 
	  INTO v_old_mapping
	  FROM auto_imp_region_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = in_class_sid
	   AND source_text = in_source_text;

	AssertWritePermOnImportClass(in_class_sid);

	DELETE FROM auto_imp_region_map
	 WHERE automated_import_class_sid = in_class_sid
	   AND source_text = in_source_text
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	automated_import_pkg.AuditValue(
		in_class_sid	=>	in_class_sid,
		in_field		=>	'Region mapping deleted',
		in_new_val		=>	'deleted',
		in_old_val		=>	v_old_mapping);
	
END;

PROCEDURE DeleteIndicatorMapping(
	in_class_sid			IN	auto_imp_indicator_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_indicator_map.source_text%TYPE
)
AS

v_old_mapping				VARCHAR2(4000);

BEGIN

	SELECT source_text || ' - ' || ind_sid 
	  INTO v_old_mapping
	  FROM auto_imp_indicator_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = in_class_sid
	   AND source_text = in_source_text;

	AssertWritePermOnImportClass(in_class_sid);

	DELETE FROM auto_imp_indicator_map
	 WHERE automated_import_class_sid = in_class_sid
	   AND source_text = in_source_text
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	automated_import_pkg.AuditValue(
		in_class_sid	=>	in_class_sid,
		in_field		=>	'Indicator mapping deleted',
		in_new_val		=>	'deleted',
		in_old_val		=>	v_old_mapping);

END;

PROCEDURE DeleteMeasureMapping(
	in_class_sid			IN	auto_imp_unit_map.automated_import_class_sid%TYPE,
	in_source_text			IN	auto_imp_unit_map.source_text%TYPE
)
AS

v_old_mapping				VARCHAR2(4000);

BEGIN

	SELECT source_text || ' - ' || measure_conversion_id 
	  INTO v_old_mapping
	  FROM auto_imp_unit_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = in_class_sid
	   AND source_text = in_source_text;

	AssertWritePermOnImportClass(in_class_sid);

	DELETE FROM auto_imp_unit_map
	 WHERE automated_import_class_sid = in_class_sid
	   AND source_text = in_source_text
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	automated_import_pkg.AuditValue(
		in_class_sid	=>	in_class_sid,
		in_field		=>	'Measure mapping deleted',
		in_new_val		=>	'deleted',
		in_old_val		=>	v_old_mapping);
	
END;

PROCEDURE ProcessFailedRow(
	in_val_id					IN	NUMBER
)
AS
	v_new_val_id				NUMBER;
	v_instance_id				NUMBER;
	v_instance_step_id			NUMBER;
	v_start_dtm					auto_imp_core_data_val_fail.start_dtm%TYPE;
	v_end_dtm					auto_imp_core_data_val_fail.end_dtm%TYPE;
	v_region_sid				auto_imp_core_data_val_fail.region_sid%TYPE;
	v_ind_sid					auto_imp_core_data_val_fail.ind_sid%TYPE;
	v_measure_conv_id			auto_imp_core_data_val_fail.measure_conversion_id%TYPE;
	v_entry_val_number			auto_imp_core_data_val_fail.val_number%TYPE;
	v_note						auto_imp_core_data_val_fail.note%TYPE;
	v_source_file_ref			auto_imp_core_data_val_fail.source_file_ref%TYPE;
	v_requires_validation		NUMBER;
	v_val_table_val_id			NUMBER;
BEGIN

	SELECT instance_id, instance_step_id, start_dtm, end_dtm, region_sid, ind_sid, measure_conversion_id, val_number, note, source_file_ref
	  INTO v_instance_id, v_instance_step_id, v_start_dtm, v_end_dtm, v_region_sid, v_ind_sid, v_measure_conv_id, v_entry_val_number, v_note, v_source_file_ref
	  FROM auto_imp_core_data_val_fail
	 WHERE val_id = in_val_id;
	
	IF v_region_sid IS NULL OR v_ind_sid IS NULL THEN
		-- Can't process a row unless it has BOTH a region sid and an ind sid.
		-- But don't error. Just exit.
		RETURN;
	END IF;
	
	-- Create val entry 
	-- TODO - needs to be in an exception block, as this could fail on, eg, a dupe
	InsertCoreDataPoint(
		in_instance_id				=> v_instance_id,
		in_instance_step_id			=> v_instance_step_id,
		in_ind_sid					=> v_ind_sid,
		in_region_sid				=> v_region_sid,
		in_start_dtm				=> v_start_dtm,
		in_end_dtm					=> v_end_dtm,
		in_val_number				=> NULL,
		in_measure_conversion_id	=> v_measure_conv_id,
		in_entry_val_number			=> v_entry_val_number,
		in_note						=> v_note,
		in_source_file_ref			=> v_source_file_ref,
		out_val_id					=> v_new_val_id
	);
	
	-- Delete failed entry
	DELETE FROM auto_imp_core_data_val_fail
	 WHERE val_id = in_val_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- Merge if settings say merge
	SELECT aicds.requires_validation_step 
	  INTO v_requires_validation
	  FROM automated_import_instance_step aiis
	  JOIN auto_imp_core_data_settings aicds ON aicds.automated_import_class_sid = aiis.automated_import_class_sid 
											 AND aicds.step_number = aiis.step_number
	 WHERE aiis.auto_import_instance_step_id = v_instance_step_id;
	
	IF v_requires_validation != 1 THEN
		MergeCoreDataRow(
			in_val_id		=> v_new_val_id,
			out_new_val_id	=> v_val_table_val_id
		);
	END IF;

END;

PROCEDURE MergeCoreDataRow(
	in_val_id					IN	NUMBER,
	out_new_val_id				OUT	NUMBER
)
AS
	v_instance_id				NUMBER;
	v_ind_sid					NUMBER;
	v_region_sid				NUMBER;
	v_start_dtm					DATE;
	v_end_dtm					DATE;
	v_val_number				NUMBER;
	v_measure_conversion_id		NUMBER;
	v_entry_val_number			auto_imp_core_data_val.entry_val_number%TYPE;
	v_note						auto_imp_core_data_val.note%TYPE;
	v_source_file_ref			auto_imp_core_data_val.source_file_ref%TYPE;
	v_reason					VARCHAR2(1024);
BEGIN

	SELECT instance_id, ind_sid, region_sid, start_dtm, end_dtm, val_number, measure_conversion_id, entry_val_number, note, source_file_ref
	  INTO v_instance_id, v_ind_sid, v_region_sid, v_start_dtm, v_end_dtm, v_val_number, v_measure_conversion_id, v_entry_val_number, v_note, v_source_file_ref
	  FROM auto_imp_core_data_val
	 WHERE val_id = in_val_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	v_reason := SUBSTR('Automated import, automatically merged. Source file reference; ' || v_source_file_ref, 0, 1000);
	
	indicator_pkg.SetValueWithReason(
		in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_ind_sid				=> v_ind_sid,
		in_region_sid			=> v_region_sid,
		in_period_start			=> v_start_dtm,
		in_period_end			=> v_end_dtm,
		in_val_number			=> v_val_number,
		in_flags				=> 0,
		in_source_type_id		=> csr_data_pkg.SOURCE_TYPE_AUTO_IMPORT,
		in_source_id			=> v_instance_id,
		in_entry_conversion_id	=> v_measure_conversion_id,
		in_entry_val_number		=> v_entry_val_number,
		in_update_flags			=> 0,
		in_reason				=> v_reason,
		in_note					=> v_note,
		out_val_id				=> out_new_val_id
	);
	
	DELETE FROM auto_imp_core_data_val
	 WHERE val_id = in_val_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	 -- Could potentially improve this slightly. The SetValue.. SP above return -1 into val_id where it couldn't do anything. As such we could
	 -- capture those and either return in a cursor to update the error file, or just write an instance message.
	   
END;

PROCEDURE MergeCoreData(
	in_instance_id				NUMBER,
	in_instance_step_id			NUMBER
)
AS
	v_val_id				val.val_id%TYPE;
BEGIN

	FOR r IN (
		SELECT val_id
		  FROM auto_imp_core_data_val
		 WHERE instance_id = in_instance_id
		   AND instance_step_id = in_instance_step_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
	
		MergeCoreDataRow(
			in_val_id		=> r.val_id,
			out_new_val_id	=> v_val_id
		);
	
	END LOOP;	
	   
END;

PROCEDURE SetCoreDataImporterSettings(
	in_import_class_sid					IN	automated_import_class_step.AUTOMATED_IMPORT_CLASS_SID%TYPE,
	in_step_number						IN	automated_import_class_step.STEP_NUMBER%TYPE,
	in_mapping_xml						IN	auto_imp_core_data_settings.mapping_xml%TYPE,
	in_imp_file_type_id					IN	auto_imp_core_data_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator					IN	auto_imp_core_data_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals			IN	auto_imp_core_data_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index			IN	auto_imp_core_data_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing					IN	auto_imp_core_data_settings.all_or_nothing%TYPE,
	in_has_headings						IN	auto_imp_core_data_settings.has_headings%TYPE,
	in_ind_mapping_type_id				IN	auto_imp_core_data_settings.ind_mapping_type_id%TYPE,
	in_region_mapping_type_id			IN	auto_imp_core_data_settings.region_mapping_type_id%TYPE,
	in_unit_mapping_type_id				IN	auto_imp_core_data_settings.unit_mapping_type_id%TYPE,
	in_requires_validation_step			IN	auto_imp_core_data_settings.requires_validation_step%TYPE,
	in_date_format_type_id				IN	auto_imp_core_data_settings.date_format_type_id%TYPE,
	in_first_col_date_format_id			IN	auto_imp_core_data_settings.first_col_date_format_id%TYPE,
	in_second_col_date_format_id		IN	auto_imp_core_data_settings.second_col_date_format_id%TYPE,
	in_date_string_exact_pars_frmt		IN	auto_imp_core_data_settings.date_string_exact_parse_format%TYPE DEFAULT NULL,
	in_zero_indexed_month_indices		IN	auto_imp_core_data_settings.zero_indexed_month_indices%TYPE,
	in_financial_year_start_month		IN	auto_imp_core_data_settings.financial_year_start_month%TYPE,
	in_overlap_action					IN	auto_imp_core_data_settings.overlap_action%TYPE
)
AS
	v_settings_id						auto_imp_importer_cms.AUTO_IMP_IMPORTER_CMS_ID%TYPE;
	v_mapping_xml						auto_imp_core_data_settings.mapping_xml%TYPE;
	v_imp_file_type_id					auto_imp_core_data_settings.automated_import_file_type_id%TYPE;
	v_dsv_separator						auto_imp_core_data_settings.dsv_separator%TYPE;
	v_dsv_quotes_as_literals			auto_imp_core_data_settings.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index				auto_imp_core_data_settings.excel_worksheet_index%TYPE;
	v_all_or_nothing					auto_imp_core_data_settings.all_or_nothing%TYPE;
	v_has_headings						auto_imp_core_data_settings.has_headings%TYPE;
	v_ind_mapping_type_id				auto_imp_core_data_settings.ind_mapping_type_id%TYPE;
	v_region_mapping_type_id			auto_imp_core_data_settings.region_mapping_type_id%TYPE;
	v_unit_mapping_type_id				auto_imp_core_data_settings.unit_mapping_type_id%TYPE;
	v_requires_validation_step			auto_imp_core_data_settings.requires_validation_step%TYPE;
	v_date_format_type_id				auto_imp_core_data_settings.date_format_type_id%TYPE;
	v_first_col_date_format_id			auto_imp_core_data_settings.first_col_date_format_id%TYPE;
	v_second_col_date_format_id			auto_imp_core_data_settings.second_col_date_format_id%TYPE;
	v_date_string_exact_pars_frmt		auto_imp_core_data_settings.date_string_exact_parse_format%TYPE;
	v_zero_indexed_month_indices		auto_imp_core_data_settings.zero_indexed_month_indices%TYPE;
	v_financial_year_start_month		auto_imp_core_data_settings.financial_year_start_month%TYPE;
	v_overlap_action					auto_imp_core_data_settings.overlap_action%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	BEGIN
		INSERT INTO auto_imp_core_data_settings 
				(auto_imp_core_data_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, 
				 all_or_nothing, has_headings, ind_mapping_type_id, region_mapping_type_id, unit_mapping_type_id, requires_validation_step, date_format_type_id, first_col_date_format_id, 
				 second_col_date_format_id, date_string_exact_parse_format, zero_indexed_month_indices, financial_year_start_month, overlap_action)
			VALUES 
				(auto_imp_coredta_setngs_id_seq.nextval, in_import_class_sid, in_step_number, in_mapping_xml, in_imp_file_type_id, in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, 
				 in_all_or_nothing, in_has_headings, in_ind_mapping_type_id, in_region_mapping_type_id, in_unit_mapping_type_id, in_requires_validation_step, in_date_format_type_id, in_first_col_date_format_id, 
				 in_second_col_date_format_id, in_date_string_exact_pars_frmt, in_zero_indexed_month_indices, in_financial_year_start_month, in_overlap_action);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT auto_imp_core_data_settings_id, mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing, has_headings, ind_mapping_type_id, 
				   region_mapping_type_id, unit_mapping_type_id, requires_validation_step, date_format_type_id, first_col_date_format_id, second_col_date_format_id, date_string_exact_parse_format,
				   zero_indexed_month_indices, financial_year_start_month, overlap_action
			  INTO v_settings_id, v_mapping_xml, v_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals, v_excel_worksheet_index, v_all_or_nothing, v_has_headings, v_ind_mapping_type_id, 
				   v_region_mapping_type_id, v_unit_mapping_type_id, v_requires_validation_step, v_date_format_type_id, v_first_col_date_format_id, v_second_col_date_format_id, v_date_string_exact_pars_frmt,
				   v_zero_indexed_month_indices, v_financial_year_start_month, v_overlap_action
			  FROM auto_imp_core_data_settings
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number;

			UPDATE auto_imp_core_data_settings
			   SET mapping_xml 						= in_mapping_xml,
				   automated_import_file_type_id 	= in_imp_file_type_id,
				   dsv_separator 					= in_dsv_separator,
				   dsv_quotes_as_literals 			= in_dsv_quotes_as_literals,
				   excel_worksheet_index 			= in_excel_worksheet_index,
				   all_or_nothing 					= in_all_or_nothing,
				   has_headings						= in_has_headings,
				   ind_mapping_type_id 				= in_ind_mapping_type_id,
				   region_mapping_type_id 			= in_region_mapping_type_id,
				   unit_mapping_type_id 			= in_unit_mapping_type_id,
				   requires_validation_step 		= in_requires_validation_step,
				   date_format_type_id 				= in_date_format_type_id,
				   first_col_date_format_id 		= in_first_col_date_format_id,
				   second_col_date_format_id		= in_second_col_date_format_id,
				   date_string_exact_parse_format	= in_date_string_exact_pars_frmt,
				   zero_indexed_month_indices		= in_zero_indexed_month_indices,
				   financial_year_start_month		= in_financial_year_start_month,
				   overlap_action					= in_overlap_action
		 WHERE auto_imp_core_data_settings_id = v_settings_id;

			automated_import_pkg.AuditXml(in_import_class_sid, in_step_number, 'mapping xml', in_mapping_xml, v_mapping_xml);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'file type id', in_imp_file_type_id, v_imp_file_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv separator', in_dsv_separator, v_dsv_separator);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv quotes as literals', in_dsv_quotes_as_literals, v_dsv_quotes_as_literals);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'excel worksheet index', in_excel_worksheet_index, v_excel_worksheet_index);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'all or nothing', in_all_or_nothing, v_all_or_nothing);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'has headings', in_has_headings, v_has_headings);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'ind mapping type', in_ind_mapping_type_id, v_ind_mapping_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'region mapping type', in_region_mapping_type_id, v_region_mapping_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'unit mapping type', in_unit_mapping_type_id, v_unit_mapping_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'requires validation step', in_requires_validation_step, v_requires_validation_step);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'date format type', in_date_format_type_id, v_date_format_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'first col date format', in_first_col_date_format_id, v_first_col_date_format_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'second col dat format', in_second_col_date_format_id, v_second_col_date_format_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'date string exact parse format', in_date_string_exact_pars_frmt, v_date_string_exact_pars_frmt);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'zero indexed months', in_zero_indexed_month_indices, v_zero_indexed_month_indices);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'financial year start month', in_financial_year_start_month, v_financial_year_start_month);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'overlap_action', in_overlap_action, v_overlap_action);
	END;
END;

PROCEDURE GetCoreDataImporterSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT auto_imp_core_data_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, dsv_separator, NVL(dsv_quotes_as_literals, 0) dsv_quotes_as_literals, 
			   NVL(excel_worksheet_index, 0) excel_worksheet_index, NVL(all_or_nothing, 0) all_or_nothing, has_headings, ind_mapping_type_id, region_mapping_type_id, unit_mapping_type_id, 
			   requires_validation_step, date_format_type_id, first_col_date_format_id, second_col_date_format_id, zero_indexed_month_indices, financial_year_start_month, 
			   overlap_action overlap_action_txt, date_string_exact_parse_format
		  FROM auto_imp_core_data_settings
		 WHERE automated_import_class_sid = in_class_sid
		   AND step_number = in_step_number
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetMappingTypes(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mapping_type_id, name
		  FROM auto_imp_mapping_type;
END;

PROCEDURE GetDateFormatTypes(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT date_type_id, name
		  FROM auto_imp_date_type;
END;

PROCEDURE GetDateColumnTypes(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT date_col_type_id, name
		  FROM auto_imp_date_col_type;
END;

-- END CORE DATA IMPORTER

-- ZIP EXTRACT IMPORTER

PROCEDURE SetZipImporterSettings(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_sort_by						IN	csr.auto_imp_zip_settings.sort_by%TYPE,
	in_sort_by_direction			IN	csr.auto_imp_zip_settings.sort_by_direction%TYPE,
	in_remove_filters				IN	NUMBER DEFAULT 0
)
AS
	v_settings_id					auto_imp_zip_filter.auto_imp_zip_settings_id%TYPE;
	v_sort_by						csr.auto_imp_zip_settings.sort_by%TYPE;
	v_sort_by_direction				csr.auto_imp_zip_settings.sort_by_direction%TYPE;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	BEGIN
		SELECT auto_imp_zip_settings_id, sort_by, sort_by_direction
		  INTO v_settings_id, v_sort_by, v_sort_by_direction
		  FROM auto_imp_zip_settings
		 WHERE automated_import_class_sid	= in_import_class_sid
		   AND step_number 					= in_step_number
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		UPDATE auto_imp_zip_settings
		   SET sort_by 					= in_sort_by,
			   sort_by_direction		= in_sort_by_direction
		 WHERE auto_imp_zip_settings_id = v_settings_id;
		 
		automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'sort by', in_sort_by, v_sort_by);
		automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'sort by direction', in_sort_by_direction, v_sort_by_direction); 
		
		IF in_remove_filters = 1 THEN
			DELETE FROM auto_imp_zip_filter
			 WHERE auto_imp_zip_settings_id = v_settings_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			automated_import_pkg.AuditMsg(in_import_class_sid, in_step_number, 'Filters removed');
		END IF;

	EXCEPTION
		WHEN no_data_found THEN
			INSERT INTO auto_imp_zip_settings 
				(auto_imp_zip_settings_id, automated_import_class_sid, step_number, sort_by, sort_by_direction)
			VALUES 
				(auto_imp_zip_settings_id_seq.nextval, in_import_class_sid, in_step_number, in_sort_by, in_sort_by_direction);
	END;

END;

PROCEDURE SetZipFilter(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_pos							IN	csr.auto_imp_zip_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_zip_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_zip_filter.is_wildcard%TYPE,
	in_matched_class_sid			IN	csr.auto_imp_zip_filter.matched_import_class_sid%TYPE
)
AS
	v_settings_id					auto_imp_zip_filter.auto_imp_zip_settings_id%TYPE;
	v_pos							csr.auto_imp_zip_filter.pos%TYPE;
	v_filter_string					csr.auto_imp_zip_filter.filter_string%TYPE;
	v_is_wildcard					csr.auto_imp_zip_filter.is_wildcard%TYPE;
	v_matched_class_sid				csr.auto_imp_zip_filter.matched_import_class_sid%TYPE;
BEGIN

	SELECT auto_imp_zip_settings_id
	  INTO v_settings_id
	  FROM auto_imp_zip_settings
	 WHERE automated_import_class_sid	= in_import_class_sid
	   AND step_number 					= in_step_number;
	
	SELECT NVL(in_pos, NVL(MAX(pos), 1))
	  INTO v_pos
	  FROM auto_imp_zip_filter
	 WHERE auto_imp_zip_settings_id = v_settings_id;
	
	BEGIN
		INSERT INTO auto_imp_zip_filter
			(auto_imp_zip_settings_id, pos, filter_string, is_wildcard, matched_import_class_sid)
		VALUES
			(v_settings_id, v_pos, in_filter_string, in_is_wildcard, in_matched_class_sid);
		
		automated_import_pkg.AuditMsg(in_import_class_sid, in_step_number, 'Flter added. Pos '||in_pos||' filter '||in_filter_string||' is wildcard '||in_is_wildcard||' matched class'||in_matched_class_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			SELECT filter_string, is_wildcard, matched_import_class_sid
			  INTO v_filter_string, v_is_wildcard, v_matched_class_sid
			  FROM auto_imp_zip_filter
			 WHERE pos = v_pos
			   AND auto_imp_zip_settings_id = v_settings_id;
			  
			UPDATE auto_imp_zip_filter
			   SET filter_string			= in_filter_string,
			       is_wildcard 				= in_is_wildcard,
				   matched_import_class_sid	= in_matched_class_sid
			 WHERE pos = v_pos
			   AND auto_imp_zip_settings_id = v_settings_id;
			
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'filter string', in_filter_string, v_filter_string);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'is wildcard', in_is_wildcard, v_is_wildcard);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'matched_import_class_sid', in_matched_class_sid, v_matched_class_sid);
			
	END;

END;

PROCEDURE SetZipWildcardFilter(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_pos							IN	csr.auto_imp_zip_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_zip_filter.filter_string%TYPE,
	in_matched_class_sid			IN	csr.auto_imp_zip_filter.matched_import_class_sid%TYPE
)
AS
BEGIN
	
	automated_import_pkg.SetZipFilter(
		in_import_class_sid		=>	in_import_class_sid,
		in_step_number			=>	in_step_number,
		in_pos					=>	in_pos,
		in_filter_string		=>	in_filter_string,
		in_is_wildcard			=>	1,
		in_matched_class_sid	=>	in_matched_class_sid
	);
	
END;

PROCEDURE SetZipRegexFilter(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	in_pos							IN	csr.auto_imp_zip_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_zip_filter.filter_string%TYPE,
	in_matched_class_sid			IN	csr.auto_imp_zip_filter.matched_import_class_sid%TYPE
)
AS
BEGIN

	automated_import_pkg.SetZipFilter(
		in_import_class_sid		=>	in_import_class_sid,
		in_step_number			=>	in_step_number,
		in_pos					=>	in_pos,
		in_filter_string		=>	in_filter_string,
		in_is_wildcard			=>	0,
		in_matched_class_sid	=>	in_matched_class_sid
	);

END;

PROCEDURE GetZipImporterSettings(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	csr.auto_imp_zip_settings.step_number%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_filter_cur					OUT SYS_REFCURSOR
)
AS
	v_settings_id					auto_imp_zip_filter.auto_imp_zip_settings_id%TYPE;
BEGIN

	SELECT auto_imp_zip_settings_id
	  INTO v_settings_id
	  FROM auto_imp_zip_settings
	 WHERE automated_import_class_sid	= in_import_class_sid
	   AND step_number 					= in_step_number;
	
	OPEN out_cur FOR
		SELECT sort_by, sort_by_direction
		  FROM auto_imp_zip_settings
		 WHERE auto_imp_zip_settings_id = v_settings_id;
	
	OPEN out_filter_cur FOR
		SELECT filter_string, is_wildcard, matched_import_class_sid
		  FROM auto_imp_zip_filter
		 WHERE auto_imp_zip_settings_id = v_settings_id
		 ORDER BY pos ASC;

END;

-- END ZIP EXTRACT IMPORTER

-- USER IMPORTER

PROCEDURE SetUserImporterSettings(
	in_import_class_sid					IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number						IN	automated_import_class_step.step_number%TYPE,
	in_mapping_xml						IN	auto_imp_user_imp_settings.mapping_xml%TYPE,
	in_imp_file_type_id					IN	auto_imp_user_imp_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator					IN	auto_imp_user_imp_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals			IN	auto_imp_user_imp_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index			IN	auto_imp_user_imp_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing					IN	auto_imp_user_imp_settings.all_or_nothing%TYPE,
	in_has_headings						IN	auto_imp_user_imp_settings.has_headings%TYPE,
	in_concatenator						IN	auto_imp_user_imp_settings.concatenator%TYPE,
	in_active_status_method				IN	auto_imp_user_imp_settings.active_status_method_txt%TYPE,
	in_use_loc_region_as_start_pt		IN	auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE,
	in_group_sids						IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_set_line_mngmnt_frm_mngr_ky		IN	auto_imp_user_imp_settings.set_line_mngmnt_frm_mngr_key%TYPE,
	in_region_mapping_type_id			IN	auto_imp_user_imp_settings.region_mapping_type_id%TYPE,
	in_role_sids						IN	security_pkg.T_SID_IDS DEFAULT EmptySidIds,
	in_date_string_exact_pars_frmt		IN	auto_imp_user_imp_settings.date_string_exact_parse_format%TYPE DEFAULT NULL
)
AS
	v_settings_id						auto_imp_importer_cms.auto_imp_importer_cms_id%TYPE;
	v_mapping_xml						auto_imp_user_imp_settings.mapping_xml%TYPE;
	v_imp_file_type_id					auto_imp_user_imp_settings.automated_import_file_type_id%TYPE;
	v_dsv_separator						auto_imp_user_imp_settings.dsv_separator%TYPE;
	v_dsv_quotes_as_literals			auto_imp_user_imp_settings.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index				auto_imp_user_imp_settings.excel_worksheet_index%TYPE;
	v_all_or_nothing					auto_imp_user_imp_settings.all_or_nothing%TYPE;
	v_has_headings						auto_imp_user_imp_settings.has_headings%TYPE;
	v_concatenator						auto_imp_user_imp_settings.concatenator%TYPE;
	v_active_status_method				auto_imp_user_imp_settings.active_status_method_txt%TYPE;
	v_use_loc_region_as_start_pt		auto_imp_user_imp_settings.use_loc_region_as_start_pt%TYPE;
	v_groups							security.T_SID_TABLE;
	v_set_line_mngmnt_frm_mngr_key		auto_imp_user_imp_settings.set_line_mngmnt_frm_mngr_key%TYPE;
	v_roles								security.T_SID_TABLE;
	v_region_mapping_type_id			auto_imp_user_imp_settings.region_mapping_type_id%TYPE;
	v_date_string_exact_pars_frmt		auto_imp_user_imp_settings.date_string_exact_parse_format%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	v_groups := security_pkg.SidArrayToTable(in_group_sids);
	
	v_roles := security_pkg.SidArrayToTable(in_role_sids);
	
	BEGIN
		INSERT INTO auto_imp_user_imp_settings 
				(auto_imp_user_imp_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, 
				 all_or_nothing, has_headings, concatenator, active_status_method_txt, use_loc_region_as_start_pt, set_line_mngmnt_frm_mngr_key, region_mapping_type_id,
				 date_string_exact_parse_format)
			VALUES 
				(auto_imp_user_setngs_id_seq.nextval, in_import_class_sid, in_step_number, in_mapping_xml, in_imp_file_type_id, in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, 
				 in_all_or_nothing, in_has_headings, in_concatenator, in_active_status_method, in_use_loc_region_as_start_pt, in_set_line_mngmnt_frm_mngr_ky, in_region_mapping_type_id,
				 in_date_string_exact_pars_frmt);
		
		INSERT INTO user_profile_default_group
			(group_sid, automated_import_class_sid, step_number)
		SELECT column_value, in_import_class_sid, in_step_number
		  FROM TABLE(v_groups);

		INSERT INTO user_profile_default_role
			(role_sid, automated_import_class_sid, step_number)
		SELECT column_value, in_import_class_sid, in_step_number
		  FROM TABLE(v_roles);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT auto_imp_user_imp_settings_id, mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing, has_headings, 
				   concatenator, active_status_method_txt, use_loc_region_as_start_pt, set_line_mngmnt_frm_mngr_key,
				   region_mapping_type_id, date_string_exact_parse_format
			  INTO v_settings_id, v_mapping_xml, v_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals, v_excel_worksheet_index, v_all_or_nothing, v_has_headings, 
				   v_concatenator, v_active_status_method, v_use_loc_region_as_start_pt, v_set_line_mngmnt_frm_mngr_key,
				   v_region_mapping_type_id, v_date_string_exact_pars_frmt
			  FROM auto_imp_user_imp_settings
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number;

			UPDATE auto_imp_user_imp_settings
			   SET mapping_xml 						= in_mapping_xml,
				   automated_import_file_type_id 	= in_imp_file_type_id,
				   dsv_separator 					= in_dsv_separator,
				   dsv_quotes_as_literals 			= in_dsv_quotes_as_literals,
				   excel_worksheet_index 			= in_excel_worksheet_index,
				   all_or_nothing 					= in_all_or_nothing,
				   has_headings						= in_has_headings,
				   concatenator						= in_concatenator,
				   active_status_method_txt			= in_active_status_method,
				   use_loc_region_as_start_pt		= in_use_loc_region_as_start_pt,
				   set_line_mngmnt_frm_mngr_key		= in_set_line_mngmnt_frm_mngr_ky,
				   region_mapping_type_id			= in_region_mapping_type_id,
				   date_string_exact_parse_format	= in_date_string_exact_pars_frmt
			 WHERE auto_imp_user_imp_settings_id = v_settings_id;
			
			DELETE FROM user_profile_default_group
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number;
			 
			INSERT INTO user_profile_default_group
				(group_sid, automated_import_class_sid, step_number)
			SELECT column_value, in_import_class_sid, in_step_number
			  FROM TABLE(v_groups);
			  
			DELETE FROM user_profile_default_role
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number;
			 
			INSERT INTO user_profile_default_role
				(role_sid, automated_import_class_sid, step_number)
			SELECT column_value, in_import_class_sid, in_step_number
			  FROM TABLE(v_roles);

			automated_import_pkg.AuditXml(in_import_class_sid, in_step_number, 'mapping xml', in_mapping_xml, v_mapping_xml);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'file type id', in_imp_file_type_id, v_imp_file_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv separator', in_dsv_separator, v_dsv_separator);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv quotes as literals', in_dsv_quotes_as_literals, v_dsv_quotes_as_literals);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'excel worksheet index', in_excel_worksheet_index, v_excel_worksheet_index);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'all or nothing', in_all_or_nothing, v_all_or_nothing);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'has headings', in_has_headings, v_has_headings);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'concatenator', in_concatenator, v_concatenator);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'Active status method', in_active_status_method, v_active_status_method);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'Use location region as start point', in_use_loc_region_as_start_pt, v_use_loc_region_as_start_pt);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'Set line management from manager key', in_set_line_mngmnt_frm_mngr_ky, v_set_line_mngmnt_frm_mngr_key);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'region mapping type', in_region_mapping_type_id, v_region_mapping_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'date string exact parse format', in_date_string_exact_pars_frmt, v_date_string_exact_pars_frmt);
	END;
END;

PROCEDURE GetUserImporterSettings(
	in_class_sid				IN	automated_import_class_step.automated_import_class_sid%TYPE,
	in_step_number				IN	automated_import_class_step.step_number%TYPE,
	out_settings_cur			OUT	SYS_REFCURSOR,
	out_groups_cur				OUT	SYS_REFCURSOR,
	out_roles_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_settings_cur FOR
		SELECT auto_imp_user_imp_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, dsv_separator, NVL(dsv_quotes_as_literals, 0) dsv_quotes_as_literals, 
			   NVL(excel_worksheet_index, 0) excel_worksheet_index, NVL(all_or_nothing, 0) all_or_nothing, has_headings, concatenator, active_status_method_txt, use_loc_region_as_start_pt, set_line_mngmnt_frm_mngr_key,
			   region_mapping_type_id, date_string_exact_parse_format
		  FROM auto_imp_user_imp_settings
		 WHERE automated_import_class_sid = in_class_sid
		   AND step_number = in_step_number
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_groups_cur FOR
		SELECT group_sid
		  FROM user_profile_default_group
		 WHERE automated_import_class_sid IS NULL
		    OR (automated_import_class_sid = in_class_sid AND step_number = in_step_number)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_roles_cur FOR
		SELECT role_sid
		  FROM user_profile_default_role
		 WHERE automated_import_class_sid IS NULL
		    OR (automated_import_class_sid = in_class_sid AND step_number = in_step_number)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

-- END USER IMPORTER

-- START PRODUCT IMPORTER

PROCEDURE GetProductImportSettings(
	in_class_sid				IN	auto_imp_product_settings.automated_import_class_sid%TYPE,
	in_step_number				IN	auto_imp_product_settings.step_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT auto_imp_product_settings_id, automated_import_class_sid, step_number, mapping_xml, 
			   automated_import_file_type_id, dsv_separator, NVL(dsv_quotes_as_literals, 0) dsv_quotes_as_literals, 
			   NVL(excel_worksheet_index, 0) excel_worksheet_index, NVL(all_or_nothing, 0) all_or_nothing, header_row,
			   default_company_sid, company_mapping_type_id, product_mapping_type_id, product_type_mapping_type_id,
			   t.base_lang, cms_mapping_xml, tab_sid
		  FROM auto_imp_product_settings s
		  JOIN aspen2.translation_application t ON s.app_sid = t.application_sid
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND automated_import_class_sid = in_class_sid
		   AND step_number = in_step_number;
END;

PROCEDURE SetProductImportSettings(
	in_import_class_sid				IN	auto_imp_product_settings.automated_import_class_sid%TYPE,
	in_step_number					IN	auto_imp_product_settings.step_number%TYPE,
	in_mapping_xml					IN	auto_imp_product_settings.mapping_xml%TYPE,
	in_imp_file_type_id				IN	auto_imp_product_settings.automated_import_file_type_id%TYPE,
	in_dsv_separator				IN	auto_imp_product_settings.dsv_separator%TYPE,
	in_dsv_quotes_as_literals		IN	auto_imp_product_settings.dsv_quotes_as_literals%TYPE,
	in_excel_worksheet_index		IN	auto_imp_product_settings.excel_worksheet_index%TYPE,
	in_all_or_nothing				IN	auto_imp_product_settings.all_or_nothing%TYPE,
	in_header_row					IN	auto_imp_product_settings.header_row%TYPE,
	in_concatenator					IN	auto_imp_product_settings.concatenator%TYPE,
	in_default_company_sid			IN	auto_imp_product_settings.default_company_sid%TYPE,
	in_company_mapping_type_id		IN	auto_imp_product_settings.company_mapping_type_id%TYPE,
	in_product_mapping_type_id		IN	auto_imp_product_settings.product_mapping_type_id%TYPE,
	in_prod_type_mapping_type_id	IN	auto_imp_product_settings.product_type_mapping_type_id%TYPE,
	in_cms_mapping_xml				IN	auto_imp_product_settings.cms_mapping_xml%TYPE,
	in_tab_sid						IN	auto_imp_product_settings.tab_sid%TYPE
)
AS
	v_upsert_check					NUMBER(1);
	v_cms_mapping_xml				auto_imp_product_settings.cms_mapping_xml%TYPE;
	v_settings_id					auto_imp_product_settings.auto_imp_product_settings_id%TYPE;
	v_mapping_xml					auto_imp_product_settings.mapping_xml%TYPE;
	v_imp_file_type_id				auto_imp_product_settings.automated_import_file_type_id%TYPE;
	v_dsv_separator					auto_imp_product_settings.dsv_separator%TYPE;
	v_dsv_quotes_as_literals		auto_imp_product_settings.dsv_quotes_as_literals%TYPE;
	v_excel_worksheet_index			auto_imp_product_settings.excel_worksheet_index%TYPE;
	v_all_or_nothing				auto_imp_product_settings.all_or_nothing%TYPE;
	v_header_row					auto_imp_product_settings.header_row%TYPE;
	v_concatenator					auto_imp_product_settings.concatenator%TYPE;
	v_default_company_sid			auto_imp_product_settings.default_company_sid%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring importers, only BuiltinAdministrator or super admins can run this.');
	END IF;

	SELECT COUNT(step_number) INTO v_upsert_check
	  FROM auto_imp_product_settings
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND automated_import_class_sid = in_import_class_sid
	   AND step_number = in_step_number;

	IF v_upsert_check = 0 THEN
		INSERT INTO auto_imp_product_settings 
				(auto_imp_product_settings_id, automated_import_class_sid, step_number, mapping_xml, automated_import_file_type_id, 
				dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing, header_row, concatenator,
				default_company_sid, company_mapping_type_id, product_mapping_type_id, product_type_mapping_type_id,
				cms_mapping_xml, tab_sid)
			VALUES 
				(auto_imp_product_settings_seq.NEXTVAL, in_import_class_sid, in_step_number, in_mapping_xml, in_imp_file_type_id,
				in_dsv_separator, in_dsv_quotes_as_literals, in_excel_worksheet_index, in_all_or_nothing, in_header_row, in_concatenator,
				in_default_company_sid, in_company_mapping_type_id, in_product_mapping_type_id, in_prod_type_mapping_type_id,
				in_cms_mapping_xml, in_tab_sid);

	ELSE
			SELECT auto_imp_product_settings_id, mapping_xml, automated_import_file_type_id, dsv_separator, dsv_quotes_as_literals, 
				   excel_worksheet_index, all_or_nothing, header_row, concatenator, default_company_sid
			  INTO v_settings_id, v_mapping_xml, v_imp_file_type_id, v_dsv_separator, v_dsv_quotes_as_literals,
				   v_excel_worksheet_index, v_all_or_nothing, v_header_row, v_concatenator, v_default_company_sid
			  FROM auto_imp_product_settings
			 WHERE automated_import_class_sid = in_import_class_sid
			   AND step_number = in_step_number;

			UPDATE auto_imp_product_settings
			   SET mapping_xml 						= in_mapping_xml,
				   automated_import_file_type_id 	= in_imp_file_type_id,
				   dsv_separator 					= in_dsv_separator,
				   dsv_quotes_as_literals 			= in_dsv_quotes_as_literals,
				   excel_worksheet_index 			= in_excel_worksheet_index,
				   all_or_nothing 					= in_all_or_nothing,
				   header_row						= in_header_row,
				   concatenator						= in_concatenator,
				   default_company_sid				= in_default_company_sid,
				   company_mapping_type_id			= in_company_mapping_type_id,
				   product_mapping_type_id			= in_product_mapping_type_id,
				   product_type_mapping_type_id		= in_prod_type_mapping_type_id,
				   cms_mapping_xml					= in_cms_mapping_xml,
				   tab_sid							= in_tab_sid
			 WHERE auto_imp_product_settings_id = v_settings_id;

			automated_import_pkg.AuditXml(in_import_class_sid, in_step_number, 'mapping xml', in_mapping_xml, v_mapping_xml);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'file type id', in_imp_file_type_id, v_imp_file_type_id);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv separator', in_dsv_separator, v_dsv_separator);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'dsv quotes as literals', in_dsv_quotes_as_literals, v_dsv_quotes_as_literals);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'excel worksheet index', in_excel_worksheet_index, v_excel_worksheet_index);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'all or nothing', in_all_or_nothing, v_all_or_nothing);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'heading row index', in_header_row, v_header_row);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'concatenator', in_concatenator, v_concatenator);
			automated_import_pkg.AuditValue(in_import_class_sid, in_step_number, 'default Company SID', in_default_company_sid, v_default_company_sid);
	END IF;
END;

PROCEDURE GetCompanySidFromName(
	in_name				IN	chain.company.name%TYPE,
	out_company_sid		OUT	chain.company.company_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT company_sid
		  INTO out_company_sid
		  FROM chain.company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(name) = LOWER(in_name);
		
		chain.company_pkg.CheckCompanyAccess(out_company_sid);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_company_sid := -1;
		WHEN TOO_MANY_ROWS THEN
			out_company_sid := -1;
	END;
END;

PROCEDURE CheckCompanySid(
	in_company_sid		IN	chain.company.company_sid%TYPE,
	out_company_sid		OUT	chain.company.company_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT company_sid
		  INTO out_company_sid
		  FROM chain.company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;

		chain.company_pkg.CheckCompanyAccess(in_company_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_company_sid := -1;
	END;
END;

-- END PRODUCT IMPORTER

-- MAIL

PROCEDURE CreateMailbox(
	in_email_address				IN	csr.auto_imp_mailbox.address%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_new_sid						OUT	security_pkg.T_SID_ID
)
AS
BEGIN

	-- Only builtin admin can create mailboxes as they live outside the apps. 
	IF NVL(SYS_CONTEXT('SECURITY', 'SID'),-1) <> security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Must be the BuiltIn admin to create mailboxes.');
	END IF;

	csr.mailbox_pkg.CreateCsrMailbox(
		in_email_address		=> in_email_address,
		out_new_sid				=> out_new_sid
	);
	
	INSERT INTO csr.auto_imp_mailbox
		(address, mailbox_sid, body_validator_plugin, use_full_mail_logging, matched_imp_class_sid_for_body)
	VALUES
		(in_email_address, out_new_sid, in_body_plugin, in_use_full_logging, in_matched_class_sid_for_body);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id						=> in_user_sid,
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_EXPIMP_MAILBOX,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> out_new_sid,
		in_description					=> 'Automated import mailbox "{0}" created',
		in_param_1						=> in_email_address
	);
		
END;

PROCEDURE SetMailbox(
	in_email_address				IN	csr.auto_imp_mailbox.address%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_user_sid						IN	security_pkg.T_SID_ID,
	out_sid							OUT	security_pkg.T_SID_ID
)
AS
	v_inbox_sid						security_pkg.T_SID_ID;
BEGIN
	-- Note that if create mailbox is called later on in theo pprocedure  
	-- then the security requirements are that you must be builtin admin
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring mailbox, only BuiltinAdministrator or super admins can do this.');
	END IF;

	BEGIN
		-- The mail package gives us a way to get the inbox sid from the address
		v_inbox_sid := mail.mail_pkg.getInboxSIDFromEmail(in_email_address);

		-- but we want the root mailbox sid
		SELECT root_mailbox_sid
		  INTO out_sid
		  FROM mail.account
		 WHERE inbox_sid = v_inbox_sid;

		-- Associate the mailbox with the auto imp class sid 
		BEGIN
			INSERT INTO auto_imp_mailbox (address, mailbox_sid, body_validator_plugin, use_full_mail_logging, matched_imp_class_sid_for_body)
			VALUES (in_email_address, out_sid, in_body_plugin, 1, in_matched_class_sid_for_body);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE auto_imp_mailbox
				   SET body_validator_plugin = in_body_plugin,
					   matched_imp_class_sid_for_body = in_matched_class_sid_for_body
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND mailbox_sid = out_sid;
		END;

	EXCEPTION
		WHEN mail.mail_pkg.MAILBOX_NOT_FOUND THEN
			-- Mailbox not found, create a new one
			automated_import_pkg.CreateMailbox(
				in_email_address				=> in_email_address,
				in_body_plugin					=> in_body_plugin,
				in_use_full_logging				=> 1,
				in_matched_class_sid_for_body	=> in_matched_class_sid_for_body,
				in_user_sid						=> security_pkg.GetSID,
				out_new_sid						=> out_sid
			);
	END;
END;

PROCEDURE ClearMailboxClassAssociation(
	in_import_class_sid				IN	csr.auto_imp_zip_settings.automated_import_class_sid%TYPE
)
AS
	v_inbox_sid						csr.auto_imp_mailbox.mailbox_sid%TYPE;
BEGIN	
	FOR r IN (
		SELECT aim.mailbox_sid
		  INTO v_inbox_sid
		  FROM csr.auto_imp_mailbox aim
		  JOIN csr.auto_imp_mail_attach_filter aimaf ON aim.mailbox_sid = aimaf.mailbox_sid AND aim.app_sid = aimaf.app_sid
		 WHERE aimaf.matched_import_class_sid = in_import_class_sid
		   AND aim.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		UpdateMailbox(
			in_mailbox_sid					=>	r.mailbox_sid,
			in_body_plugin					=>	NULL,
			in_use_full_logging				=>	1,
			in_matched_class_sid_for_body	=>	NULL,
			in_clear_filters				=>	1
		);
	END LOOP;
END;

PROCEDURE UpdateMailbox(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_body_plugin					IN	csr.auto_imp_mailbox.body_validator_plugin%TYPE,
	in_use_full_logging				IN	csr.auto_imp_mailbox.use_full_mail_logging%TYPE,
	in_matched_class_sid_for_body	IN	csr.auto_imp_mailbox.matched_imp_class_sid_for_body%TYPE,
	in_clear_filters				IN	NUMBER
)
AS
	v_address							csr.auto_imp_mailbox.address%TYPE;
BEGIN

	UPDATE csr.auto_imp_mailbox
	   SET body_validator_plugin = in_body_plugin, 
		   use_full_mail_logging = in_use_full_logging, 
		   matched_imp_class_sid_for_body = in_matched_class_sid_for_body
	 WHERE mailbox_sid = in_mailbox_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
 RETURNING address
	  INTO v_address;
	
	IF in_clear_filters = 1 THEN
		DELETE FROM auto_imp_mail_sender_filter
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		DELETE FROM auto_imp_mail_subject_filter
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		DELETE FROM auto_imp_mail_attach_filter
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_EXPIMP_MAILBOX,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> in_mailbox_sid,
		in_description					=> 'Automated import mailbox "{0}" edited',
		in_param_1          			=> v_address
	);
END;

PROCEDURE AddSenderFilter(
	in_mailbox_sid			IN	mail.mailbox.mailbox_sid%TYPE,
	in_filter_string		IN	csr.auto_imp_mail_sender_filter.filter_string%TYPE,
	in_is_wildcard			IN	csr.auto_imp_mail_sender_filter.is_wildcard%TYPE
)
AS
BEGIN
	INSERT INTO auto_imp_mail_sender_filter
		(mailbox_sid, filter_string, is_wildcard)
	VALUES
		(in_mailbox_sid, in_filter_string, in_is_wildcard);
END;

PROCEDURE AddSubjectFilter(
	in_mailbox_sid			IN	mail.mailbox.mailbox_sid%TYPE,
	in_filter_string		IN	csr.auto_imp_mail_subject_filter.filter_string%TYPE,
	in_is_wildcard			IN	csr.auto_imp_mail_subject_filter.is_wildcard%TYPE
)
AS
BEGIN
	INSERT INTO auto_imp_mail_subject_filter
		(mailbox_sid, filter_string, is_wildcard)
	VALUES
		(in_mailbox_sid, in_filter_string, in_is_wildcard);
END;

PROCEDURE AddAttachmentFilter(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_pos							IN	csr.auto_imp_mail_attach_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_mail_attach_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_mail_attach_filter.is_wildcard%TYPE,
	in_matched_import_class_sid		IN	csr.auto_imp_mail_attach_filter.matched_import_class_sid%TYPE,
	in_required_mimetype			IN	csr.auto_imp_mail_attach_filter.required_mimetype%TYPE,
	in_attachment_validator_plugin	IN	csr.auto_imp_mail_attach_filter.attachment_validator_plugin%TYPE
)
AS
BEGIN
	INSERT INTO auto_imp_mail_attach_filter
		(mailbox_sid, pos, filter_string, is_wildcard, matched_import_class_sid, required_mimetype, attachment_validator_plugin)
	VALUES
		(in_mailbox_sid, in_pos, in_filter_string, in_is_wildcard, in_matched_import_class_sid, in_required_mimetype, in_attachment_validator_plugin);
END;

PROCEDURE SetAttachmentFilter(
	in_mailbox_sid					IN	mail.mailbox.mailbox_sid%TYPE,
	in_pos							IN	csr.auto_imp_mail_attach_filter.pos%TYPE,
	in_filter_string				IN	csr.auto_imp_mail_attach_filter.filter_string%TYPE,
	in_is_wildcard					IN	csr.auto_imp_mail_attach_filter.is_wildcard%TYPE,
	in_matched_import_class_sid		IN	csr.auto_imp_mail_attach_filter.matched_import_class_sid%TYPE,
	in_required_mimetype			IN	csr.auto_imp_mail_attach_filter.required_mimetype%TYPE,
	in_attachment_validator_plugin	IN	csr.auto_imp_mail_attach_filter.attachment_validator_plugin%TYPE
)
AS
BEGIN
	BEGIN
		AddAttachmentFilter(
			in_mailbox_sid,
			in_pos,
			in_filter_string,
			in_is_wildcard,
			in_matched_import_class_sid,
			in_required_mimetype,
			in_attachment_validator_plugin
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE auto_imp_mail_attach_filter
			   SET filter_string = in_filter_string,
			       is_wildcard = in_is_wildcard,
			       matched_import_class_sid = in_matched_import_class_sid,
			       required_mimetype = in_required_mimetype,
			       attachment_validator_plugin = in_attachment_validator_plugin
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mailbox_sid = in_mailbox_sid
			   AND pos = in_pos;
	END;
END;

PROCEDURE LogEmail(
	in_mailbox_sid			IN	csr.auto_imp_mail.mailbox_sid%TYPE,
	in_mail_message_uid		IN	csr.auto_imp_mail.mail_message_uid%TYPE,
	in_subject				IN	csr.auto_imp_mail.subject%TYPE,
	in_recieved_dtm			IN	csr.auto_imp_mail.recieved_dtm%TYPE,
	in_sender_address		IN	csr.auto_imp_mail.sender_address%TYPE,
	in_sender_name			IN	csr.auto_imp_mail.sender_name%TYPE,
	in_number_attachments	IN	csr.auto_imp_mail.number_attachments%TYPE
)
AS
BEGIN

	BEGIN
		INSERT INTO auto_imp_mail
			(mailbox_sid, mail_message_uid, subject, recieved_dtm, sender_address, sender_name, number_attachments)
		VALUES
			(in_mailbox_sid, in_mail_message_uid, in_subject, in_recieved_dtm, in_sender_address, in_sender_name, in_number_attachments);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE auto_imp_mail
			   SET subject = in_subject,
			       recieved_dtm = in_recieved_dtm,
				   sender_address = in_sender_address,
				   sender_name = in_sender_name,
				   number_attachments = in_number_attachments
			 WHERE mailbox_sid = in_mailbox_sid
			   AND mail_message_uid = in_mail_message_uid;
	END;
END;

PROCEDURE LogEmailMessage(
	in_mailbox_sid			IN	csr.auto_imp_mail.mailbox_sid%TYPE,
	in_mail_message_uid		IN	csr.auto_imp_mail.mail_message_uid%TYPE,
	in_message				IN	csr.auto_imp_mail_msg.message%TYPE
)
AS
	v_pos						csr.auto_imp_mail_msg.pos%TYPE;
BEGIN

	SELECT NVL(MAX(pos) + 1, 0)
	  INTO v_pos
	  FROM auto_imp_mail_msg
	 WHERE mailbox_sid = in_mailbox_sid
	   AND mail_message_uid = in_mail_message_uid;

	INSERT INTO auto_imp_mail_msg
		(mailbox_sid, mail_message_uid, message, pos)
	VALUES
		(in_mailbox_sid, in_mail_message_uid, in_message, v_pos);
	   
END;

PROCEDURE CreateEmailInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_mailbox_sid					IN	auto_imp_mail_file.mailbox_sid%TYPE,
	in_mail_message_uid				IN	mail.message.message_id%TYPE,
	in_file_blob					IN	BLOB,
	in_file_name					IN	auto_imp_mail_file.file_name%TYPE,
	in_made_from_body				IN	auto_imp_mail_file.made_from_body%TYPE,
	out_new_instance_id				OUT	auto_imp_mail_file.automated_import_instance_id%TYPE
)
AS
BEGIN

	--Create an instance
	CreateInstanceAndBatchJob(
		in_automated_import_class_sid	=> in_automated_import_class_sid,
		in_number_of_steps				=> 1,
		in_is_manual					=> 0,
		in_mailbox_sid					=> in_mailbox_sid,
		in_mail_message_uid				=> in_mail_message_uid,
		out_auto_import_instance_id		=> out_new_instance_id
	);
	--Insert into auto_imp_mail_file
	INSERT INTO auto_imp_mail_file
		(mailbox_sid, mail_message_uid, file_blob, file_name, made_from_body, automated_import_instance_id)
	VALUES
		(in_mailbox_sid, in_mail_message_uid, in_file_blob, in_file_name, in_made_from_body, out_new_instance_id);

END;

PROCEDURE GetEmailFile(
	in_instance_id					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT file_blob data_file, file_name data_filename
		  FROM auto_imp_mail_file
		 WHERE automated_import_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetAllAppMailboxes(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT aim.app_sid, address, mailbox_sid, body_validator_plugin, use_full_mail_logging, matched_imp_class_sid_for_body, c.host, c.app_sid, a.inbox_sid inbox_sid
		  FROM auto_imp_mailbox aim
		  JOIN customer c on c.app_sid = aim.app_sid
		  JOIN mail.account a on a.root_mailbox_sid = aim.mailbox_sid
		 WHERE deactivated_dtm IS NULL;

END;

PROCEDURE GetMailboxes(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT mailbox_sid, address, use_full_mail_logging full_logging, deactivated_dtm, CASE WHEN deactivated_dtm IS NULL THEN 0 ELSE 1 END is_deactivated,
			   (SELECT MAX(recieved_dtm) FROM auto_imp_mail WHERE mailbox_sid = mb.mailbox_sid GROUP BY mailbox_sid) last_email_dtm
		  FROM auto_imp_mailbox mb
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetMailbox(
	in_mailbox_sid				IN	auto_imp_mailbox.mailbox_sid%TYPE,
	out_box_cur					OUT	SYS_REFCURSOR,
	out_sender_filters_cur		OUT	SYS_REFCURSOR,
	out_subject_filters_cur		OUT	SYS_REFCURSOR,
	out_attachment_filters_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN

	automated_import_pkg.GetMailbox(
		in_app_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_mailbox_sid				=> in_mailbox_sid,
		out_box_cur					=> out_box_cur,
		out_sender_filters_cur		=> out_sender_filters_cur,
		out_subject_filters_cur		=> out_subject_filters_cur,
		out_attachment_filters_cur	=> out_attachment_filters_cur
	);

END;

PROCEDURE GetMailbox(
	in_app_sid					IN	customer.app_sid%TYPE,
	in_mailbox_sid				IN	auto_imp_mailbox.mailbox_sid%TYPE,
	out_box_cur					OUT	SYS_REFCURSOR,
	out_sender_filters_cur		OUT	SYS_REFCURSOR,
	out_subject_filters_cur		OUT	SYS_REFCURSOR,
	out_attachment_filters_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_box_cur FOR
		SELECT app_sid, address, mailbox_sid, body_validator_plugin, use_full_mail_logging, matched_imp_class_sid_for_body, deactivated_dtm, CASE WHEN deactivated_dtm IS NULL THEN 1 ELSE 0 END is_deactivated
		  FROM auto_imp_mailbox
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = in_app_sid;
	
	OPEN out_sender_filters_cur FOR
		SELECT filter_string, is_wildcard
		  FROM auto_imp_mail_sender_filter
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = in_app_sid;

	OPEN out_subject_filters_cur FOR
		SELECT filter_string, is_wildcard
		  FROM auto_imp_mail_subject_filter
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = in_app_sid;
	
	OPEN out_attachment_filters_cur FOR
		SELECT filter_string, is_wildcard, matched_import_class_sid, required_mimetype, attachment_validator_plugin
		  FROM auto_imp_mail_attach_filter
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = in_app_sid
		 ORDER BY pos ASC;

END;

PROCEDURE DeactivateMailbox(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE
)
AS
	v_address					auto_imp_mailbox.address%TYPE;
BEGIN

	UPDATE auto_imp_mailbox
	   SET deactivated_dtm = SYSDATE
	 WHERE mailbox_sid = in_mailbox_sid
	   AND deactivated_dtm IS NULL	-- Don't change the date if already deactivated
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
 RETURNING address
	  INTO v_address;
	
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_EXPIMP_MAILBOX,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> in_mailbox_sid,
		in_description					=> 'Automated import mailbox "{0}" deactivated',
		in_param_1          			=> v_address
	);

END;

PROCEDURE ReactivateMailbox(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE
)
AS
	v_address					auto_imp_mailbox.address%TYPE;
BEGIN

	UPDATE auto_imp_mailbox
	   SET deactivated_dtm = NULL
	 WHERE mailbox_sid = in_mailbox_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
 RETURNING address
	  INTO v_address;
	
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id						=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id				=> csr_data_pkg.AUDIT_TYPE_EXPIMP_MAILBOX,
		in_app_sid						=> SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid					=> in_mailbox_sid,
		in_description					=> 'Automated import mailbox "{0}" deactivated',
		in_param_1          			=> v_address
	);

END;

PROCEDURE GetMailLog(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT mailbox_sid, mail_message_uid, subject, recieved_dtm, sender_address, sender_name, number_attachments, 
			(SELECT COUNT(*) FROM automated_import_instance WHERE mail_message_uid = aim.mail_message_uid AND mailbox_sid = in_mailbox_sid) instances_created
		  FROM auto_imp_mail aim
		 WHERE mailbox_sid = in_mailbox_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY recieved_dtm desc;
END;

PROCEDURE GetMailDetails(
	in_mailbox_sid			IN	auto_imp_mailbox.mailbox_sid%TYPE,
	in_mail_message_uid		IN	automated_import_instance.mail_message_uid%TYPE,
	out_cur					OUT	SYS_REFCURSOR,
	out_msg_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT aii.automated_import_instance_id instance_id, aic.label, NVL(bj.result, 'Pending') result, bj.completed_dtm
		  FROM automated_import_instance aii
		  JOIN automated_import_class aic 	ON aii.automated_import_class_sid = aic.automated_import_class_sid
	 LEFT JOIN batch_job bj					ON aii.batch_job_id = bj.batch_job_id
		 WHERE mail_message_uid = in_mail_message_uid 
		   AND mailbox_sid = in_mailbox_sid
		   AND aii.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY aii.automated_import_instance_id DESC;
		 
	OPEN out_msg_cur FOR
		SELECT message, pos
		  FROM auto_imp_mail_msg
		 WHERE mail_message_uid = in_mail_message_uid 
		   AND mailbox_sid = in_mailbox_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY pos ASC;

END;

-- END MAIL

-- MESSAGE BUS

PROCEDURE CreateBusInstanceAndBatchJob(
	in_lookup_key					IN	automated_import_class.lookup_key%TYPE,
	in_file_blob					IN	BLOB,
	in_source_description			IN	automated_import_bus_file.source_description%TYPE,
	out_new_instance_id				OUT	automated_import_bus_file.automated_import_instance_id%TYPE
)
AS
	v_class_sid						automated_import_class.automated_import_class_sid%TYPE;
BEGIN

	SELECT automated_import_class_sid
	  INTO v_class_sid
	  FROM automated_import_class
	 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_class_sid IS NOT NULL THEN
		CreateBusInstanceAndBatchJob(
			in_automated_import_class_sid	=> v_class_sid,
			in_source_description			=> in_source_description,
			in_file_blob					=> in_file_blob,
			out_new_instance_id				=> out_new_instance_id
		);
	END IF;
END;

PROCEDURE CreateBusInstanceAndBatchJob(
	in_automated_import_class_sid	IN	automated_import_class.automated_import_class_sid%TYPE,
	in_file_blob					IN	BLOB,
	in_source_description			IN	automated_import_bus_file.source_description%TYPE,
	out_new_instance_id				OUT	automated_import_bus_file.automated_import_instance_id%TYPE
)
AS
BEGIN

	--Create an instance
	CreateInstanceAndBatchJob(
		in_automated_import_class_sid	=> in_automated_import_class_sid,
		in_number_of_steps				=> 1,
		in_is_manual					=> 0,
		in_is_from_bus					=> 1,
		out_auto_import_instance_id		=> out_new_instance_id
	);
	
	INSERT INTO automated_import_bus_file
		(file_blob, automated_import_instance_id, message_received_dtm, source_description)
	VALUES
		(in_file_blob, out_new_instance_id, SYSDATE, in_source_description);

END;

PROCEDURE GetMessageBusFile(
	in_instance_id					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT file_blob data_file, 'messageBus.txt' data_filename
		  FROM automated_import_bus_file
		 WHERE automated_import_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

-- END MESSAGE BUS

-- AUDIT LOGGING

PROCEDURE AuditValue(
	in_class_sid			NUMBER,
	in_step_number			NUMBER DEFAULT NULL,
	in_field				VARCHAR2,
	in_new_val				VARCHAR2,
	in_old_val				VARCHAR2
)
AS
	v_field_name			VARCHAR2(1024);
BEGIN

	IF in_step_number IS NOT NULL THEN
		v_field_name := in_field||' (step '||in_step_number||')';
	ELSE
		v_field_name := in_field|| ' (class)';
	END IF;
	
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_EXPIMP_AUTO_IMPORT, SYS_CONTEXT('SECURITY', 'APP'), in_class_sid, v_field_name, in_old_val, in_new_val);

END;

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_field				VARCHAR2,
	in_new_val				XMLTYPE,
	in_old_val				XMLTYPE
)
AS
	v_new_val				VARCHAR2(4000);
	v_old_val				VARCHAR2(4000);
BEGIN

	IF in_old_val IS NOT NULL THEN
		v_old_val := in_old_val.getStringVal();
	END IF;
	IF in_new_val IS NOT NULL THEN
		v_new_val := in_new_val.getStringVal();
	END IF;

	automated_import_pkg.AuditValue(in_class_sid, in_step_number, in_field, v_new_val, v_old_val);
	
END;

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_field				VARCHAR2,
	in_new_val				XMLTYPE,
	in_old_val				VARCHAR2
)
AS
	v_new_val				VARCHAR2(4000);
BEGIN

	IF in_new_val IS NOT NULL THEN
		v_new_val := in_new_val.getStringVal();
	END IF;

	automated_import_pkg.AuditValue(in_class_sid, in_step_number, in_field, v_new_val, in_old_val);
	
END;

PROCEDURE AuditXml(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_field				VARCHAR2,
	in_new_val				VARCHAR2,
	in_old_val				XMLTYPE
)
AS
	v_old_val				VARCHAR2(4000);
BEGIN

	IF in_old_val IS NOT NULL THEN
		v_old_val := in_old_val.getStringVal();
	END IF;

	automated_import_pkg.AuditValue(in_class_sid, in_step_number, in_field, in_new_val, v_old_val);
	
END;

PROCEDURE AuditMsg(
	in_class_sid			NUMBER,
	in_step_number			NUMBER,
	in_msg					VARCHAR2
)
AS
	v_desc					VARCHAR2(1024);
BEGIN

	IF in_step_number IS NOT NULL THEN
		v_desc := in_msg||' (step '||in_step_number||')';
	ELSE
		v_desc := in_msg|| ' (class)';
	END IF;
	
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id					=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id			=>	csr_data_pkg.AUDIT_TYPE_EXPIMP_AUTO_IMPORT,
		in_app_sid					=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid				=>	in_class_sid,
		in_description				=>	v_desc
	);
	
END;

-- END AUDIT LOGGING

END;
/
