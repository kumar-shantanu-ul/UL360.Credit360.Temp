CREATE OR REPLACE PACKAGE CSR.region_metric_pkg AS

/**
 * Slightly specific helper procedure to quickly set measures, particularly
 * for pick-lists
 */
PROCEDURE SetMeasure(
	in_description  IN  measure.description%TYPE,
	out_measure_sid	OUT security_pkg.T_SID_ID
);

PROCEDURE MakeMetric(
	in_ind_parent_sid	IN  security_pkg.T_SID_ID,
	in_description		IN  ind_description.description%TYPE,
	in_measure 			IN  VARCHAR2,
	out_ind_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE SetMetric(
	in_ind_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE UnsetMetric(
	in_ind_sid				IN	security_pkg.T_SID_ID
);

FUNCTION AreIndsAllMetrics (
	in_ind_sids				IN  security_pkg.T_SID_IDS
) RETURN NUMBER;

PROCEDURE GetMetricsForType(
	in_region_type			IN	region_type_metric.region_type%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteMetricValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE GetMetricValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCurrentMetricVal (
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_lookup_key					IN  ind.lookup_key%TYPE
) RETURN NUMBER;

PROCEDURE BulkSetMetricValue (
	in_region_sid					 IN	security_pkg.T_SID_ID,
	in_ind_sid						 IN	security_pkg.T_SID_ID,
	in_effective_dtm				 IN	region_metric_val.effective_dtm%TYPE,
	in_val							 IN	region_metric_val.val%TYPE,
	in_note							 IN	region_metric_val.note%TYPE,
	in_replace_dtm					 IN	region_metric_val.effective_dtm%TYPE				DEFAULT NULL, -- Set this if the metric is to be replaced with a different dtm
	in_entry_measure_conversion_id	 IN	region_metric_val.entry_measure_conversion_id%TYPE	DEFAULT NULL,
	in_source_type_id				 IN	region_metric_val.source_type_id%TYPE				DEFAULT NULL,
	out_min_dtm						OUT	DATE,
	out_max_dtm						OUT DATE,
	out_region_metric_val_id		OUT region_metric_val.region_metric_val_id%TYPE
);

PROCEDURE SetMetricValue (
	in_region_sid					 IN	security_pkg.T_SID_ID,
	in_ind_sid						 IN	security_pkg.T_SID_ID,
	in_effective_dtm				 IN	region_metric_val.effective_dtm%TYPE,
	in_val							 IN	region_metric_val.val%TYPE,
	in_note							 IN	region_metric_val.note%TYPE,
	in_replace_dtm					 IN	region_metric_val.effective_dtm%TYPE				DEFAULT NULL, -- Set this if the metric is to be replaced with a different dtm
	in_entry_measure_conversion_id	 IN	region_metric_val.entry_measure_conversion_id%TYPE	DEFAULT NULL,
	in_source_type_id				 IN	region_metric_val.source_type_id%TYPE				DEFAULT NULL,
	out_region_metric_val_id		OUT region_metric_val.region_metric_val_id%TYPE
);

PROCEDURE SetMetricValue (
	in_region_metric_val_id			 IN region_metric_val.region_metric_val_id%TYPE,
	in_effective_dtm				 IN	region_metric_val.effective_dtm%TYPE,
	in_val							 IN	region_metric_val.val%TYPE,
	in_note							 IN	region_metric_val.note%TYPE,
	in_entry_measure_conversion_id	 IN	region_metric_val.entry_measure_conversion_id%TYPE	DEFAULT NULL,
	in_source_type_id				 IN	region_metric_val.source_type_id%TYPE				DEFAULT NULL
);

PROCEDURE DeleteMetricValue(
	in_region_metric_val_id	IN 	region_metric_val.region_metric_val_id%TYPE,
	in_audit_delete			IN	NUMBER DEFAULT 1
);

PROCEDURE SetSystemValues(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	region_metric_val.effective_dtm%TYPE,
	in_end_dtm				IN	region_metric_val.effective_dtm%TYPE
);

PROCEDURE UpdateSpaceTypeMetrics(
	in_space_type_id	in space_type_region_metric.space_type_id%type,
	in_ind_sids			in VARCHAR2
);

PROCEDURE GetRegionTypeLookup(
	out_cur		out		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllRegionMetrics(
	out_cur						out		security_pkg.T_OUTPUT_CUR,
	out_region_types_cur		out		security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveRegionMetric(
	in_ind_sid				IN	region_metric.ind_sid%TYPE,
	in_is_mandatory			IN	space_type.is_tenantable%TYPE,
	in_element_pos			IN	property_element_layout.pos%TYPE,
	in_region_types			IN	VARCHAR2,
	in_show_measure			IN	region_metric.show_measure%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_region_types_cur	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateRegionTypeMetrics(
	in_ind_sid			in region_type_metric.ind_sid%type,
	in_region_types		in VARCHAR2
);

PROCEDURE RefreshSystemValues;

-- filter procedures
PROCEDURE FilterRegionMetricText (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_group_by_index	IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterRegionMetricDate (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterRegionMetricCombo (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name 	IN chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterRegionMetricNumber (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE UNSEC_GetMetricsForRegions (
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_metrics_cur					OUT SYS_REFCURSOR
);

END region_metric_pkg;
/
