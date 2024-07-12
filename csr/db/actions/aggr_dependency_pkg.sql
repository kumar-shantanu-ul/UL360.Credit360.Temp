CREATE OR REPLACE PACKAGE  ACTIONS.aggr_dependency_pkg
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

PROCEDURE GetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDependentTaskPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	task_period.start_dtm%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetChildRegionStatusData(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_parent_region	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END aggr_dependency_pkg;
/
