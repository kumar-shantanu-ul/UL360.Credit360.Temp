CREATE OR REPLACE PACKAGE CSR.initiative_metric_pkg
IS
	
TYPE T_METRIC_VALS IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

FUNCTION MetricValArrayToTable(
	in_vals						IN T_METRIC_VALS
) RETURN T_INITIATIVE_METRIC_VAL_TABLE DETERMINISTIC;
PRAGMA RESTRICT_REFERENCES(MetricValArrayToTable, RNDS, RNPS, WNDS, WNPS);

FUNCTION INIT_EmptyMetricVals
RETURN initiative_metric_pkg.T_METRIC_VALS;

PROCEDURE SetNullMetricVal(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_measured_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetMetricVals(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_ids						IN	security_pkg.T_SID_IDS,
	in_vals						IN	initiative_metric_pkg.T_METRIC_VALS,
	in_uoms						IN	security_pkg.T_SID_IDS
);

PROCEDURE RawSetMetricVal(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_id						IN	initiative_metric.initiative_metric_id%TYPE,
	in_val						IN	initiative_metric_val.entry_val%TYPE,
	in_uom						IN	initiative_metric_val.entry_measure_conversion_id%TYPE
);

PROCEDURE RawSetMetricVals(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_ids						IN	security_pkg.T_SID_IDS,
	in_vals						IN	initiative_metric_pkg.T_METRIC_VALS,
	in_uoms						IN	security_pkg.T_SID_IDS
);

PROCEDURE GetProjectMetrics(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeMetricVals(
	in_initiative_sid	IN 	security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE GetInitiativeMetrics(
	out_metrics				OUT	SYS_REFCURSOR
);

PROCEDURE GetInitiativeMetrics(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllMetrics(
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uom					OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE LookupIndSids (
	in_dummy					IN	security_pkg.T_SID_ID,
	in_metric_keys				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SyncFilterAggregateTypes;

PROCEDURE AddInitiativeMetric(
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_label					IN	initiative_metric.label%TYPE,
	in_is_during				IN	initiative_metric.is_during%TYPE,
	in_is_running				IN	initiative_metric.is_running%TYPE,
	in_is_rampable				IN	initiative_metric.is_rampable%TYPE,
	in_per_period_duration		IN	initiative_metric.per_period_duration%TYPE,
	in_one_off_period			IN	initiative_metric.one_off_period%TYPE,
	in_divisibility				IN	initiative_metric.divisibility%TYPE,
	in_lookup_key				IN	initiative_metric.lookup_key%TYPE,
	in_is_external				IN	initiative_metric.is_external%TYPE,
	out_initiative_metric_id	OUT	security_pkg.T_SID_ID
);

PROCEDURE SaveInitiativeMetric(
	in_initiative_metric_id		IN	security_pkg.T_SID_ID,
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_label					IN	initiative_metric.label%TYPE,
	in_is_during				IN	initiative_metric.is_during%TYPE,
	in_is_running				IN	initiative_metric.is_running%TYPE,
	in_is_rampable				IN	initiative_metric.is_rampable%TYPE,
	in_per_period_duration		IN	initiative_metric.per_period_duration%TYPE,
	in_one_off_period			IN	initiative_metric.one_off_period%TYPE,
	in_divisibility				IN	initiative_metric.divisibility%TYPE,
	in_lookup_key				IN	initiative_metric.lookup_key%TYPE,
	in_is_external				IN	initiative_metric.is_external%TYPE
);

PROCEDURE DeleteInitiativeMetric(
	in_initiative_metric_id		IN	security_pkg.T_SID_ID
);

-- 
-- INITIATIVE AGGREGATE TAG GROUPS
--

PROCEDURE GetAggrTagGroupsAndMembers (
	out_cur_tag_groups				OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_tags					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveAggregateTagGroup (
	in_aggr_tag_group_id			IN	aggr_tag_group.aggr_tag_group_id%TYPE,
	in_label						IN	aggr_tag_group.label%TYPE,
	in_lookup_key					IN	aggr_tag_group.lookup_key%TYPE,
	in_aggr_tag_group_members		IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteAggregateTagGroup (
	in_aggr_tag_group_id			IN	aggr_tag_group.aggr_tag_group_id%TYPE
);


--
-- INITIATIVE METRIC MAPPING
--

PROCEDURE GetInitiativeMetricMappingData (
	out_cur_metrics					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_flow_state_groups		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_aggr_tag_groups			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInitiativeMetricMapping (
	out_mappings				OUT	security_pkg.T_OUTPUT_CUR,
	out_agg_tag_groups			OUT	security_pkg.T_OUTPUT_CUR,
	out_flow_state_groups		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveInitiativeMetricMapping (
	in_metric_id				IN	initiative_metric.initiative_metric_id%TYPE,
	in_ind_sid					IN	initiative_metric_state_ind.ind_sid%TYPE,
	in_flow_state_group_ids		IN	security_pkg.T_SID_IDS,
	in_aggr_tag_group_ids		IN	security_pkg.T_SID_IDS	
);

PROCEDURE DeleteInitiativeMetricMapping (
	in_metric_id				IN	initiative_metric.initiative_metric_id%TYPE,
	in_ind_sid					IN	security_pkg.T_SID_ID
);

END initiative_metric_pkg;
/