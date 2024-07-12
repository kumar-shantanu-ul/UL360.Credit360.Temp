CREATE OR REPLACE PACKAGE csr.aggregate_ind_pkg AS

PROCEDURE CreateGroup(
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_label					IN	aggregate_ind_group.label%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE, -- e.g. 'csr.audit_pkg.GetIndicatorValues'
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE DEFAULT 'vals',
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL,
	in_run_daily				IN	aggregate_ind_group.run_daily%TYPE DEFAULT 0,
	in_run_for_current_month	IN	aggregate_ind_group.run_for_current_month%TYPE DEFAULT 0,
	out_aggregate_ind_group_id	OUT	aggregate_ind_group.aggregate_ind_group_id%TYPE
);

PROCEDURE UpdateGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_label					IN	aggregate_ind_group.label%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE,
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE,
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL,
	in_run_daily				IN	aggregate_ind_group.run_daily%TYPE DEFAULT 0,
	in_run_for_current_month	IN	aggregate_ind_group.run_for_current_month%TYPE DEFAULT 0,
	in_data_bucket_sid			IN	aggregate_ind_group.data_bucket_sid%TYPE DEFAULT NULL,
	in_data_bucket_fetch_sp		IN	aggregate_ind_group.data_bucket_fetch_sp%TYPE DEFAULT NULL
);

FUNCTION SetGroup(
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE, -- e.g. 'csr.audit_pkg.GetIndicatorValues'
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE DEFAULT 'vals',
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL
) RETURN aggregate_ind_group.aggregate_ind_group_id%TYPE;

FUNCTION GetGroupId(
	in_aggr_group_name	IN	aggregate_ind_group.name%TYPE
) RETURN aggregate_ind_group.aggregate_ind_group_id%TYPE;

PROCEDURE RefreshAll;

PROCEDURE RefreshDailyGroups;

PROCEDURE RefreshGroup(
	in_aggregate_ind_group_id	IN		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_from_dtm					IN		DATE DEFAULT NULL,
	in_to_dtm					IN		DATE DEFAULT NULL
);

PROCEDURE RefreshGroup(
	in_aggregate_ind_group_name	IN		aggregate_ind_group.name%TYPE,
	in_from_dtm					IN		DATE DEFAULT NULL,
	in_to_dtm					IN		DATE DEFAULT NULL
);

PROCEDURE CreateAggregateInd (
	in_aggregate_ind_group_id	IN	aggregate_ind_group.name%TYPE,
	in_parent_ind_sid			IN	ind.parent_sid%TYPE,
	in_desc						IN	ind_description.description%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE DEFAULT NULL,
	in_name						IN  ind.name%TYPE,
	in_measure_sid				IN	ind.measure_sid%TYPE,
	in_divisibility				IN	ind.divisibility%TYPE DEFAULT NULL,
	in_info_definition			IN  VARCHAR2 DEFAULT NULL,
	in_aggregate				IN	ind.aggregate%TYPE DEFAULT 'SUM',
	out_ind_sid					OUT	ind.ind_sid%TYPE
);

PROCEDURE SetAggregateInd (
	in_aggr_group_name		IN	aggregate_ind_group.name%TYPE,
	in_parent				IN	ind.parent_sid%TYPE,
	in_desc					IN	ind_description.description%TYPE,
	in_lookup_key			IN	ind.lookup_key%TYPE,
	in_name					IN  ind.name%TYPE DEFAULT NULL,
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_divisibility			IN	ind.divisibility%TYPE DEFAULT NULL,
	in_info_definition		IN  VARCHAR2 DEFAULT NULL,
	in_aggregate			IN	ind.aggregate%TYPE DEFAULT 'SUM',
	out_ind_sid				OUT	ind.ind_sid%TYPE
);

PROCEDURE SetAggregateInd (
	in_aggregate_ind_group_id	IN	aggregate_ind_group.name%TYPE,
	in_parent					IN	ind.parent_sid%TYPE,
	in_desc						IN	ind_description.description%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE,
	in_name						IN  ind.name%TYPE DEFAULT NULL,
	in_measure_sid				IN	ind.measure_sid%TYPE,
	in_divisibility				IN	ind.divisibility%TYPE DEFAULT NULL,
	in_info_definition			IN  VARCHAR2 DEFAULT NULL,
	in_aggregate				IN	ind.aggregate%TYPE DEFAULT 'SUM',
	out_ind_sid					OUT	ind.ind_sid%TYPE
);

FUNCTION ConvertAggIndCursor(
	in_cur							IN	SYS_REFCURSOR
)
RETURN T_AGGREGATE_VAL_TABLE PIPELINED;

PROCEDURE GetAggregateIndGroups(
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetAggregateIndGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetIndicatorsInGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetIndParentDetails(
	in_ind_sid				IN	ind.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ReparentIndicator(
	in_ind_sid					IN	ind.ind_sid%TYPE,
	in_new_parent_sid			IN	ind.parent_sid%TYPE,
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE
);

PROCEDURE SetIndicatorLookupKey(
	in_ind_sid					IN	ind.ind_sid%TYPE,
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE
);

PROCEDURE GetAuditLogForGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE TriggerDataBucketJob(
	in_aggregate_ind_group_id	IN	batch_job_data_bucket_agg_ind.aggregate_ind_group_id%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetDataBucketJobDetails(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE BeginDataBucketJob(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE
);

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_scenario_run_sid				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT	SYS_REFCURSOR,
	out_source_detail_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_scenario_run_sid				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_source_detail_cur			OUT	SYS_REFCURSOR
);

PROCEDURE RemoveAggIndGroup(
	in_aggregate_ind_group_id	IN	NUMBER
);

END;
/
