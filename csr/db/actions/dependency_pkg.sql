CREATE OR REPLACE PACKAGE  ACTIONS.dependency_pkg
IS

PROCEDURE ClearDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE ClearIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE ClearTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE SetDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS,
	in_task_sids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
);

PROCEDURE AddIndDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveIndDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE AddTaskDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_dep_task_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE RemoveTaskDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_dep_task_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateJobsFromInd (
	--in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);

PROCEDURE CreateJobsFromTask (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);

PROCEDURE CreateJobForTask (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);

PROCEDURE GetJobs (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteJobs(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteJobs(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE GetDependentTaskPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTaskJobRegions(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTaskJobPeriods(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE Internal_AddTaskRecalcRegion (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE Internal_AddTaskRecalcPeriod (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_recalc_period.start_dtm%TYPE DEFAULT NULL
);

END dependency_pkg;
/

