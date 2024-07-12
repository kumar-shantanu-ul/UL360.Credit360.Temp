CREATE OR REPLACE PACKAGE CSR.DELEG_REPORT_PKG AS

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

PROCEDURE GetDelegReport(
	in_deleg_report_sid		IN	deleg_report.deleg_report_sid%TYPE,
	out_deleg_report_cur	OUT	SYS_REFCURSOR,
	out_deleg_plan_cur		OUT	SYS_REFCURSOR,
	out_region_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetDelegReportList(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SaveDelegReport(
	in_name					IN	deleg_report.name%TYPE,
	in_deleg_rpt_type_id	IN	deleg_report.deleg_report_type_id%TYPE,
	in_start_dtm			IN	deleg_report.start_dtm%TYPE,
	in_end_dtm				IN	deleg_report.end_dtm%TYPE,
	in_period_set_id		IN	deleg_report.period_set_id%TYPE,
	in_period_interval_id	IN	deleg_report.period_interval_id%TYPE,
	in_deleg_plan_sids		IN	security_pkg.T_SID_IDS,
	in_region_sids			IN	security_pkg.T_SID_IDS,
	in_overwrite			IN	NUMBER,
	out_deleg_rpt_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE UpdateDelegReport(
	in_deleg_report_sid		IN	security_pkg.T_SID_ID,
	in_name					IN	deleg_report.name%TYPE,
	in_deleg_rpt_type_id	IN	deleg_report.deleg_report_type_id%TYPE,
	in_start_dtm			IN	deleg_report.start_dtm%TYPE,
	in_end_dtm				IN	deleg_report.end_dtm%TYPE,
	in_period_set_id		IN	deleg_report.period_set_id%TYPE,
	in_period_interval_id	IN	deleg_report.period_interval_id%TYPE,
	in_deleg_plan_sids		IN	security_pkg.T_SID_IDS,
	in_region_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetStatusesByDelegPlan(
	in_start_dtm		IN deleg_report.start_dtm%TYPE,
	in_end_dtm			IN deleg_report.end_dtm%TYPE,
	in_root_region_sids	IN security_pkg.T_SID_IDS,
	in_deleg_plan_sids	IN security_pkg.T_SID_IDS,
	out_data_cur		OUT SYS_REFCURSOR,
	out_labels_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetStatusesByRegion(
	in_start_dtm		IN deleg_report.start_dtm%TYPE,
	in_end_dtm			IN deleg_report.end_dtm%TYPE,
	in_root_region_sids	IN security_pkg.T_SID_IDS,
	in_deleg_plan_sids	IN security_pkg.T_SID_IDS,
	out_data_cur		OUT SYS_REFCURSOR,
	out_labels_cur		OUT SYS_REFCURSOR
)
;

END;
/