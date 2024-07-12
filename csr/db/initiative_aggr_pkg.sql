CREATE OR REPLACE PACKAGE CSR.initiative_aggr_pkg
IS

PROCEDURE INTERNAL_PrepAggrData;

PROCEDURE GetIndicatorValues(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPeriodicMetricVals(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPeriodicMetricVals(
	in_initiative_sids			IN	security_pkg.T_SID_IDS,
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPeriodicMetricVals(
	in_initiative_sids			IN	security_pkg.T_SID_IDS,
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_conversion_ids			IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPeriodicMetricValsByKey(
	in_initiative_sids			IN	security_pkg.T_SID_IDS,
	in_metric_keys				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RefreshAggrVals(
	in_initiative_sid			IN	security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE RefreshAggrRegions(
	in_initiative_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CreateAggrRegion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_region_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE DeleteAggrRegion (
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE INTERNAL_UpdateAggrRegion (
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE UpdateAggrRegions (
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE UpdateAggrRegionsFast (
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CreateGroupInds(
	in_parent_ind_sid		security_pkg.T_SID_ID,
	in_state_group_id		flow_state_group.flow_State_group_id%TYPE,
	in_tag_group_id			aggr_tag_group.aggr_tag_group_id%TYPE DEFAULT NULL
);

PROCEDURE ClearReportDate
;

PROCEDURE SetReportDate(
	in_report_date		IN	initiatives_options.current_report_date%TYPE
);

PROCEDURE UNSEC_CopyIndRelationship(
	in_from_ind_sid		security_pkg.T_SID_ID,
	in_to_ind_sid		security_pkg.T_SID_ID,
	in_net_period		initiative_metric_state_ind.net_period%TYPE
);

PROCEDURE UNSEC_UpdateAggrGroup
;
END initiative_aggr_pkg;
/
