CREATE OR REPLACE PACKAGE CSR.scenario_run_snapshot_pkg AS

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
	in_old_parent_sid_id			IN	security_pkg.T_SID_ID
);

PROCEDURE GetSnapshot(
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot.scenario_run_snapshot_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
);

PROCEDURE CreateScenarioRunSnapshot(
	in_scenario_run_sid				IN	scenario_run_snapshot.scenario_run_sid%TYPE,
	in_name							IN	security_pkg.T_SO_NAME,
	in_start_dtm					IN	scenario_run_snapshot.start_dtm%TYPE,
	in_end_dtm						IN	scenario_run_snapshot.end_dtm%TYPE,
	in_period_set_id				IN	scenario_run_snapshot.period_set_id%TYPE,
	in_period_interval_id			IN	scenario_run_snapshot.period_interval_id%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_scenario_run_snapshot_sid	OUT	scenario_run_snapshot.scenario_run_snapshot_sid%TYPE
);

PROCEDURE AddSnapshot(
	in_app_sid						IN	scenario_run_snapshot.app_sid%TYPE,
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot.scenario_run_snapshot_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetSnapshotFile(
	in_app_sid						IN	scenario_run_snapshot_file.app_sid%TYPE,
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot_file.scenario_run_snapshot_sid%TYPE,
	in_version						IN	scenario_run_snapshot_file.version%TYPE,
	in_file_path					IN	scenario_run_snapshot_file.file_path%TYPE,
	in_sha1							IN	scenario_run_snapshot_file.sha1%TYPE
);

PROCEDURE RefreshSnapshotInputs(
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot_file.scenario_run_snapshot_sid%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS
);

END scenario_run_snapshot_pkg;
/
