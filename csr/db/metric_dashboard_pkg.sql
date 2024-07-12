CREATE OR REPLACE PACKAGE CSR.metric_dashboard_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
);

FUNCTION IsSetup
RETURN NUMBER;

PROCEDURE CreateDashboard(
	in_name							IN	metric_dashboard.name%TYPE,
	in_start_dtm					IN	metric_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	metric_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	metric_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	metric_dashboard.period_interval_id%TYPE,
	out_dashboard_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE SaveDashboard(
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	metric_dashboard.name%TYPE,
	in_start_dtm					IN	metric_dashboard.start_dtm%TYPE,
	in_end_dtm						IN	metric_dashboard.end_dtm%TYPE,
	in_period_set_id				IN	metric_dashboard.period_set_id%TYPE,
	in_period_interval_id			IN	metric_dashboard.period_interval_id%TYPE,
	in_lookup_key					IN	metric_dashboard.lookup_key%TYPE,
	out_dashboard_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE TrashDashboard(
	in_dashboard_sid				IN security_pkg.T_SID_ID
);

PROCEDURE SaveDashboardInd(
	in_dashboard_sid				IN security_pkg.T_SID_ID,
	in_ind_sid						IN security_pkg.T_SID_ID,
	in_pos							IN metric_dashboard_ind.pos%TYPE, 
	in_block_title					IN metric_dashboard_ind.block_title%TYPE, 
	in_block_css_class				IN metric_dashboard_ind.block_css_class%TYPE, 
	in_floor_area_ind_sid			IN security_pkg.T_SID_ID
);

PROCEDURE DeleteDashboardInd(
	in_dashboard_sid				IN security_pkg.T_SID_ID,
	in_ind_sid						IN security_pkg.T_SID_ID
);

PROCEDURE GetDashboard(
	in_dashboard_sid				IN  metric_dashboard.metric_dashboard_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR
);

PROCEDURE GetDashboardByLookupKey(
	in_lookup_key		IN  metric_dashboard.lookup_key%TYPE, 
	out_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_cur_inds		OUT security_pkg.T_OUTPUT_CUR,
	out_cur_plugins		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDashboards(
	out_cur							OUT SYS_REFCURSOR,
	out_cur_inds					OUT SYS_REFCURSOR,
	out_cur_plugins					OUT SYS_REFCURSOR
);

END;
/
