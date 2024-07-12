CREATE OR REPLACE PACKAGE ACTIONS.gantt_pkg
IS

PROCEDURE FetchFilteredData(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_project_sids			IN	security_pkg.T_SID_IDS,
	in_status_ids			IN	security_pkg.T_SID_IDS,
	in_period_status_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm			IN	DATE						DEFAULT NULL,
	in_end_dtm				IN	DATE						DEFAULT NULL,
	out_task				OUT	security_pkg.T_OUTPUT_CUR,
	out_period				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTaskRegions(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMetricsForPeriod(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_month_dtm				IN	task.start_dtm%TYPE,
	out_month					OUT	security_pkg.T_OUTPUT_CUR,
	out_cumv					OUT	security_pkg.T_OUTPUT_CUR,
	out_uom						OUT security_pkg.T_OUTPUT_CUR
);

END gantt_pkg;
/
