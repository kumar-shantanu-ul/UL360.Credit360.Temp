CREATE OR REPLACE PACKAGE CSR.like_for_like_pkg AS

-- Like for like folder name
LIKE_FOR_LIKE_FOLDER CONSTANT VARCHAR(50) := 'Like for like datasets';

-- Rule Types
RULE_TYPE_FULL_PERIOD			CONSTANT NUMBER(1) := 0;
RULE_TYPE_PER_INTERVAL			CONSTANT NUMBER(1) := 1;

/* 
** SECURABLE OBJECT CALLBACKS
*/
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

/* 
** CREATION PROCEDURES
*/

PROCEDURE CreateSlot(
	in_parent_sid				IN	NUMBER,
	in_name						IN	like_for_like_slot.name%TYPE,
	in_ind_sid					IN	like_for_like_slot.ind_sid%TYPE,
	in_region_sid				IN	like_for_like_slot.region_sid%TYPE,
	in_include_inactive_regions	IN	like_for_like_slot.include_inactive_regions%TYPE,
	in_period_start_dtm			IN	like_for_like_slot.period_start_dtm%TYPE,
	in_period_end_dtm			IN	like_for_like_slot.period_end_dtm%TYPE,
	in_period_set_id			IN	like_for_like_slot.period_set_id%TYPE,
	in_period_interval_id		IN	like_for_like_slot.period_interval_id%TYPE,
	in_rule_type				IN	like_for_like_slot.rule_type%TYPE,
	out_like_for_like_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateSlot(
	in_name						IN	like_for_like_slot.name%TYPE,
	in_ind_sid					IN	like_for_like_slot.ind_sid%TYPE,
	in_region_sid				IN	like_for_like_slot.region_sid%TYPE,
	in_include_inactive_regions	IN	like_for_like_slot.include_inactive_regions%TYPE,
	in_period_start_dtm			IN	like_for_like_slot.period_start_dtm%TYPE,
	in_period_end_dtm			IN	like_for_like_slot.period_end_dtm%TYPE,
	in_period_set_id			IN	like_for_like_slot.period_set_id%TYPE,
	in_period_interval_id		IN	like_for_like_slot.period_interval_id%TYPE,
	in_rule_type				IN	like_for_like_slot.rule_type%TYPE,
	out_like_for_like_sid		OUT	security_pkg.T_SID_ID
);

/* 
** SCENARIO / CALC PROCEDURES
*/

PROCEDURE CreateScenario;

PROCEDURE CreateScenarioRun(
	in_name						IN	like_for_like_slot.name%TYPE,
	out_new_scenario_run_sid	OUT	security_pkg.T_SID_ID
);

PROCEDURE TriggerScenarioRecalc(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE OnCalcJobCompletion(
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE,
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_scenario_run_sid				IN	scenario_run.scenario_run_sid%TYPE
);

PROCEDURE GetPendingScenarioAlerts(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE MarkScenarioAlertSent(
	in_app_sid			IN	like_for_like_scenario_alert.app_sid%TYPE,
	in_calc_job_id		IN	like_for_like_scenario_alert.calc_job_id%TYPE,
	in_user_sid			IN	like_for_like_scenario_alert.csr_user_sid%TYPE
);

/* 
** PERMISSION PROCEDURES
*/

PROCEDURE AssertWritePermission(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
);

-- READ permission on the slot
FUNCTION CanViewSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

-- WRITE permission on the slot, read on the indicator and region
FUNCTION CanEditSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

-- WRITE permission on the slot, read on the indicator and region
FUNCTION CanRefreshSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION CanEditSlot_sql(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID,
	in_do_assert					IN	NUMBER DEFAULT 0
) RETURN BINARY_INTEGER;
/* 
** EDIT PROCEDURES
*/

PROCEDURE RenameSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID,
	in_new_name					IN	like_for_like_slot.name%TYPE
);

PROCEDURE RefreshSlot(
	in_like_for_like_sid		IN	security_pkg.T_SID_ID,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

/* 
** BATCH JOB PROCEDURES
*/

PROCEDURE CreateExcludedRegionsJob(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	out_batch_job_id					OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE OnExcludedRegionsCompletion(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	in_batch_job_id						IN	batch_job.batch_job_id%TYPE
);

PROCEDURE UNSEC_AddExcludedRegion(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	in_region_sid						IN	region.region_sid%TYPE,
	in_start_dtm						IN DATE,
	in_end_dtm							IN DATE
);

PROCEDURE ClearCurrentExclusions(
	in_like_for_like_sid				IN	security_pkg.T_SID_ID,
	in_region_sid						IN	region.region_sid%TYPE DEFAULT NULL
);

PROCEDURE GetSlotToProcess(
	in_batch_job_id		IN NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionSids(
	in_region_root_sid				IN	security_pkg.T_SID_ID,
	in_include_inactive_regions		IN	NUMBER DEFAULT 1,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScenarioData(
	in_start_dtm					IN  DATE,
	in_end_dtm						IN  DATE,
	in_scenario_run_sid				IN	csr.scenario_run.scenario_run_sid%TYPE,
	out_val_cur						OUT SYS_REFCURSOR
);

/* 
** AUX PROCEDURES
*/

PROCEDURE GetFolderPath(
	in_folder_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetChildSlots(
	in_parent_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetSlotList(
	out_cur						OUT	SYS_REFCURSOR
);

FUNCTION GetSlotCount
RETURN NUMBER;

PROCEDURE Subscribe(
	in_slot_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE Unsubscribe(
	in_slot_sid					IN	security_pkg.T_SID_ID
);

-- Exposed for testing only.
PROCEDURE GetFinalValues(
	in_like_for_like_object		IN	t_like_for_like,
	in_like_for_like_val		IN	t_like_for_like_val_table,
	out_val_cur					OUT SYS_REFCURSOR
);

END;
/
