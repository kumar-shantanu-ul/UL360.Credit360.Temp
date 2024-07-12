CREATE OR REPLACE PACKAGE BODY CSR.R_REPORT_PKG AS

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
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
BEGIN
	DELETE FROM r_report_file
	 WHERE r_report_sid = in_sid_id;

	DELETE FROM r_report
	 WHERE r_report_sid = in_sid_id;
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

PROCEDURE GetReportTypePlugins(
	out_available_cur		OUT	SYS_REFCURSOR,
	out_selected_cur		OUT	SYS_REFCURSOR,
	out_base_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	-- no security needed

	OPEN out_available_cur FOR
		SELECT p.plugin_type_id, p.plugin_id, p.description, p.details, p.preview_image_path,
			   p.cs_class, p.js_class, p.js_include, p.r_script_path
		  FROM plugin p
		 WHERE p.plugin_type_id = csr_data_pkg.PLUGIN_TYPE_R_REPORT
		   AND NVL(p.app_sid, v_app_sid) = v_app_sid
		 ORDER BY p.plugin_id;

	OPEN out_selected_cur FOR
		SELECT p.plugin_type_id, p.plugin_id, p.description, p.details, p.preview_image_path,
			   p.cs_class, p.js_class, p.js_include, p.r_script_path
		  FROM plugin p
		  JOIN r_report_type rt ON p.plugin_type_id = rt.plugin_type_id AND p.plugin_id = rt.plugin_id
		 WHERE p.plugin_type_id = csr_data_pkg.PLUGIN_TYPE_R_REPORT
		   AND NVL(p.app_sid, v_app_sid) = v_app_sid
		 ORDER BY p.plugin_id;

	OPEN out_base_cur FOR
		SELECT p.plugin_type_id, p.plugin_id, p.description, p.details, p.preview_image_path,
			   p.cs_class, p.js_class, p.js_include, p.r_script_path
		  FROM plugin p
		 WHERE p.plugin_type_id = csr_data_pkg.PLUGIN_TYPE_R_REPORT
		   AND p.app_sid IS NULL
		 ORDER BY p.plugin_id;
END;

PROCEDURE GetReportTypes(
	in_r_report_type_id		IN	r_report_type.r_report_type_id%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security needed

	OPEN out_cur FOR
		SELECT rt.r_report_type_id, rt.label, rt.plugin_type_id, rt.plugin_id,
			   p.cs_class, p.js_class, p.js_include, p.r_script_path
		  FROM r_report_type rt
		  JOIN plugin p ON p.plugin_type_id = rt.plugin_type_id AND p.plugin_id = rt.plugin_id
		 WHERE NVL(in_r_report_type_id, r_report_type_id) = r_report_type_id
		 ORDER BY rt.label;
END;

PROCEDURE SaveReportType(
	in_r_report_type_id		IN	r_report_type.r_report_type_id%TYPE,
	in_label				IN	r_report_type.label%TYPE,
	in_plugin_id			IN	r_report_type.plugin_id%TYPE,
	out_r_report_type_id	OUT	r_report_type.r_report_type_id%TYPE
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update R report types');
	END IF;

	IF in_r_report_type_id IS NULL THEN
		INSERT INTO r_report_type (r_report_type_id, label, plugin_type_id, plugin_id)
		VALUES (r_report_type_id_seq.NEXTVAL, in_label, csr_data_pkg.PLUGIN_TYPE_R_REPORT, in_plugin_id)
		RETURNING r_report_type_id INTO out_r_report_type_id;
	ELSE
		UPDATE r_report_type
		   SET label = in_label,
			   plugin_id = in_plugin_id
		 WHERE r_report_type_id = in_r_report_type_id;

		out_r_report_type_id := in_r_report_type_id;
	END IF;
END;

PROCEDURE DeleteReportType(
	in_r_report_type_id		IN	r_report_type.r_report_type_id%TYPE
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update R report types');
	END IF;
	
	DELETE FROM r_report_type WHERE r_report_type_id = in_r_report_type_id;
END;

PROCEDURE EnqueueReportJob(
	in_r_report_type_id		IN	r_report_job.r_report_type_id%TYPE,
	in_js_data				IN	r_report_job.js_data%TYPE,
	in_email_on_completion	IN	batch_job.email_on_completion%TYPE,
	out_batch_job_id		OUT	r_report_job.batch_job_id%TYPE
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create R reports');
	END IF;

	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_R_REPORT,
		in_email_on_completion => in_email_on_completion,
		out_batch_job_id => out_batch_job_id
	);

	INSERT INTO r_report_job (r_report_type_id, js_data, batch_job_id)
	VALUES (in_r_report_type_id, in_js_data, out_batch_job_id);
END;

PROCEDURE CancelReportJob(
	in_batch_job_id			IN	r_report_job.batch_job_id%TYPE
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
	v_user_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_requested_by_user_sid	security_pkg.T_SID_ID;
	v_result				batch_job.result%TYPE;
	v_email_on_completion	batch_job.email_on_completion%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create R reports');
	END IF;

	SELECT requested_by_user_sid, result
	  INTO v_requested_by_user_sid, v_result
	  FROM batch_job
	 WHERE batch_job_id = in_batch_job_id;

	IF v_result IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot cancel a processed R report');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		IF v_requested_by_user_sid != v_user_sid THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot cancel another user''s R report');
		END IF;
	END IF;

	DELETE FROM r_report_job
		  WHERE batch_job_id = in_batch_job_id;
	
	UPDATE batch_job
	   SET result = 'Cancelled',
		   result_url = NULL,
		   failed = 0,
		   completed_dtm = SYSDATE
	 WHERE batch_job_id = in_batch_job_id
	   AND completed_dtm IS NULL;
END;

PROCEDURE GetReportJobs(
	in_batch_job_id			IN	r_report_job.batch_job_id%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
	v_user_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot read R reports');
	END IF;

	IF security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		v_user_sid := NULL; -- Admins can see all jobs
	END IF;

	OPEN out_cur FOR
		SELECT rj.r_report_type_id, rj.batch_job_id, rj.js_data,
			   rt.label r_report_type_label,
			   bj.requested_dtm, bj.requested_by_user_sid, bj.started_dtm, bj.completed_dtm, bj.result, bj.result_url,
			   cu.email requested_by_user_email, cu.full_name requested_by_user_full_name
		  FROM r_report_job rj
		  JOIN r_report_type rt ON rt.r_report_type_id = rj.r_report_type_id
		  JOIN batch_job bj ON bj.batch_job_id = rj.batch_job_id
		  JOIN csr_user cu ON cu.csr_user_sid = bj.requested_by_user_sid
		 WHERE NVL(v_user_sid, bj.requested_by_user_sid) = bj.requested_by_user_sid
		   AND NVL(in_batch_job_id, rj.batch_job_id) = rj.batch_job_id
		 ORDER BY requested_dtm DESC;
END;

PROCEDURE SaveReport(
	in_r_report_type_id		IN	r_report.r_report_type_id%TYPE,
	in_js_data				IN	r_report.js_data%TYPE,
	in_req_by_user_sid		IN	r_report.requested_by_user_sid%TYPE,
	out_r_report_sid		OUT r_report.r_report_sid%TYPE
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_reports_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create R reports');
	END IF;
		
	SecurableObject_pkg.CreateSO(
		SYS_CONTEXT('SECURITY', 'ACT'),
		v_r_reports_sid,
		class_pkg.GetClassId('CSRRReport'),
		NULL, -- Don't make the name unique
		out_r_report_sid);

	INSERT INTO r_report (r_report_sid, r_report_type_id, js_data, requested_by_user_sid, prepared_dtm)
	VALUES (out_r_report_sid, in_r_report_type_id, in_js_data, in_req_by_user_sid, SYSDATE);
END;

PROCEDURE SaveReportFile(
	in_r_report_sid			IN	r_report_file.r_report_sid%TYPE,
	in_show_as_tab			IN	r_report_file.show_as_tab%TYPE,
	in_show_as_download		IN	r_report_file.show_as_download%TYPE,
	in_title				IN	r_report_file.title%TYPE,
	in_filename				IN	r_report_file.filename%TYPE,
	in_mime_type			IN	r_report_file.mime_type%TYPE,
	in_data					IN	r_report_file.data%TYPE,
	out_r_report_file_id	OUT r_report_file.r_report_file_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_r_report_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot write to the R report with sid ' || in_r_report_sid);
	END IF;

	INSERT INTO r_report_file(r_report_file_id, r_report_sid, show_as_tab, show_as_download, title, filename, mime_type, data)
	VALUES (r_report_file_id_seq.NEXTVAL, in_r_report_sid, in_show_as_tab, in_show_as_download, in_title, in_filename, in_mime_type, in_data)
	RETURNING r_report_file_id INTO out_r_report_file_id;
END;

PROCEDURE GetReports(
	in_r_report_sid			IN	r_report.r_report_sid%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_r_reports_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'R Reports');
	v_sids_table			security.T_SO_TABLE;
BEGIN
	IF in_r_report_sid IS NULL THEN
		v_sids_table := security.securableobject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_r_reports_sid, security_pkg.PERMISSION_READ);
	ELSE
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_r_report_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot read the R report with sid ' || in_r_report_sid);
		END IF;

		SELECT security.T_SO_ROW(in_r_report_sid, NULL, NULL, NULL, NULL, NULL, NULL)
		  BULK COLLECT into v_sids_table FROM dual;
	END IF;

	OPEN out_cur FOR
		SELECT r.r_report_sid, r.r_report_type_id, r.js_data, r.requested_by_user_sid, r.prepared_dtm,
			   rt.label r_report_type_label,
			   cu.email requested_by_user_email, cu.full_name requested_by_user_full_name
		  FROM r_report r
		  JOIN r_report_type rt ON rt.r_report_type_id = r.r_report_type_id
		  JOIN csr_user cu ON cu.csr_user_sid = r.requested_by_user_sid
		  JOIN TABLE(v_sids_table) t ON t.sid_id = r.r_report_sid
		 ORDER BY r.r_report_sid DESC;
END;

PROCEDURE GetReport(
	in_r_report_sid			IN	r_report.r_report_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- GetReports handles security
	GetReports(in_r_report_sid, out_cur);

	OPEN out_files_cur FOR
		SELECT r_report_file_id, show_as_tab, show_as_download, title, filename, mime_type
		  FROM r_report_file
		 WHERE r_report_sid = in_r_report_sid
		 ORDER BY r_report_file_id;
END;

PROCEDURE GetReportFile(
	in_r_report_file_id		IN r_report_file.r_report_file_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_r_report_sid			r_report_file.r_report_sid%TYPE;
BEGIN
	SELECT r_report_sid
	  INTO v_r_report_sid
	  FROM r_report_file
	 WHERE r_report_file_id = in_r_report_file_id;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_r_report_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot read the R report with sid ' || v_r_report_sid);
	END IF;

	OPEN out_cur FOR
		SELECT r_report_file_id, show_as_tab, show_as_download, title, filename, mime_type, data
		  FROM r_report_file
		 WHERE r_report_file_id = in_r_report_file_id;
END;

END R_REPORT_PKG;
/
