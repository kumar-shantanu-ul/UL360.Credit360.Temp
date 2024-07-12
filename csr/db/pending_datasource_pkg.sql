CREATE OR REPLACE PACKAGE CSR.pending_datasource_pkg AS

PROCEDURE InitForValueChange(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	in_include_stored_calcs	IN	NUMBER,
	out_inds_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_aggr_children_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_depends_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_values_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_dates_cur			OUT	security_pkg.T_OUTPUT_CUR, -- we use a cursor as it's easier to call from C#
	out_pending_inds_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_pending_val_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_variance_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_req_period_span_cur	OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE InitDataSource(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	in_pending_ind_ids		IN	security_pkg.T_SID_IDS,
	in_pending_region_ids	IN	security_pkg.T_SID_IDS,
	in_start_dtm			IN	pending_period.start_dtm%TYPE,
	in_end_dtm				IN	pending_period.end_dtm%TYPE,
	in_interval_months		IN	NUMBER, -- number of months in the interval (3 = quarterly)
	in_include_stored_calcs	IN	NUMBER,
	out_inds_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_aggr_children_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_depends_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_values_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_dates_cur			OUT	security_pkg.T_OUTPUT_CUR, -- we use a cursor as it's easier to call from C#
	out_pending_inds_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_pending_val_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_variance_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetPendingValCacheValue(
	in_pending_ind_id		IN	pending_val_cache.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val_cache.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val_cache.pending_period_id%TYPE,
	in_val_number			IN	pending_val_cache.val_number%TYPE,
	in_write_aggr_job		IN	NUMBER
);


PROCEDURE AggregatePendingDataset(
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	in_log_changes			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AggregateAllPendingDatasets;

END pending_datasource_Pkg;
/
