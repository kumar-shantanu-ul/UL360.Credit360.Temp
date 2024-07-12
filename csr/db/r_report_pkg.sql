CREATE OR REPLACE PACKAGE CSR.R_REPORT_PKG AS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE GetReportTypePlugins(
	out_available_cur		OUT	SYS_REFCURSOR,
	out_selected_cur		OUT	SYS_REFCURSOR,
	out_base_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetReportTypes(
	in_r_report_type_id		IN	r_report_type.r_report_type_id%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SaveReportType(
	in_r_report_type_id		IN	r_report_type.r_report_type_id%TYPE,
	in_label				IN	r_report_type.label%TYPE,
	in_plugin_id			IN	r_report_type.plugin_id%TYPE,
	out_r_report_type_id	OUT	r_report_type.r_report_type_id%TYPE
);

PROCEDURE DeleteReportType(
	in_r_report_type_id		IN	r_report_type.r_report_type_id%TYPE
);

PROCEDURE EnqueueReportJob(
	in_r_report_type_id		IN	r_report_job.r_report_type_id%TYPE,
	in_js_data				IN	r_report_job.js_data%TYPE,
	in_email_on_completion	IN	batch_job.email_on_completion%TYPE,
	out_batch_job_id		OUT	r_report_job.batch_job_id%TYPE
);

PROCEDURE CancelReportJob(
	in_batch_job_id			IN	r_report_job.batch_job_id%TYPE
);

PROCEDURE GetReportJobs(
	in_batch_job_id			IN	r_report_job.batch_job_id%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SaveReport(
	in_r_report_type_id		IN	r_report.r_report_type_id%TYPE,
	in_js_data				IN	r_report.js_data%TYPE,
	in_req_by_user_sid		IN	r_report.requested_by_user_sid%TYPE,
	out_r_report_sid		OUT r_report.r_report_sid%TYPE
);

PROCEDURE SaveReportFile(
	in_r_report_sid			IN	r_report_file.r_report_sid%TYPE,
	in_show_as_tab			IN	r_report_file.show_as_tab%TYPE,
	in_show_as_download		IN	r_report_file.show_as_download%TYPE,
	in_title				IN	r_report_file.title%TYPE,
	in_filename				IN	r_report_file.filename%TYPE,
	in_mime_type			IN	r_report_file.mime_type%TYPE,
	in_data					IN	r_report_file.data%TYPE,
	out_r_report_file_id	OUT r_report_file.r_report_file_id%TYPE
);

PROCEDURE GetReports(
	in_r_report_sid			IN	r_report.r_report_sid%TYPE DEFAULT NULL,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetReport(
	in_r_report_sid			IN	r_report.r_report_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetReportFile(
	in_r_report_file_id	IN r_report_file.r_report_file_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

END R_REPORT_PKG;
/
