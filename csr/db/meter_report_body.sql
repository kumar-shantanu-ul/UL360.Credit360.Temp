CREATE OR REPLACE PACKAGE BODY CSR.meter_report_pkg
IS

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterStartDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDaily				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInterDay			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInterWeek			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInterMonth			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInterYear			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMeterType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMeterTypeGroup		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterYear				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInterYearByDay		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterValue				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMeterDataPriority	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionMetricText	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionMetricDate	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionMetricCombo	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionMetricNumber	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);


PROCEDURE GetExtraSeries (
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE INTERNAL_OrderFilterByNumValue(
	in_filter_field_id				IN  NUMBER
)
AS
BEGIN
	UPDATE chain.filter_value
	   SET pos = num_value
	 WHERE filter_field_id = in_filter_field_id;
END;

PROCEDURE INTERNAL_OrderFilterByDesc(
	in_filter_field_id				IN  NUMBER
)
AS
BEGIN
	MERGE INTO chain.filter_value fv
	USING (
		SELECT ROWNUM rn, x.* 
		  FROM (
		  	SELECT filter_value_id, description
		  	  FROM chain.filter_value
		  	 WHERE filter_field_id = in_filter_field_id
		  	 ORDER BY LOWER(description)
		  ) x
	) ord
	ON (fv.filter_value_id = ord.filter_value_id)
	WHEN MATCHED THEN 
		UPDATE SET fv.pos = ord.rn;
END;

PROCEDURE FilterMeterDataIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_ids;
	
	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.FilterMeterDataIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.FilterMeterDataIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'StartDtm' THEN
			FilterStartDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Daily' THEN
			FilterDaily(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InterDay' THEN
			FilterInterDay(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InterWeek' THEN
			FilterInterWeek(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InterMonth' THEN
			FilterInterMonth(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InterYear' THEN
			FilterInterYear(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MeterType' THEN
			FilterMeterType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MeterTypeGroup' THEN
			FilterMeterTypeGroup(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Year' THEN
			FilterYear(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InterYearByDay' THEN
			FilterInterYearByDay(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'consumptionVal' THEN -- XXX: We seem to be passed the name with a lower case first letter (Credit360.Filters.NumberItem)
			FilterValue(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MeterDataPriority' THEN
			FilterMeterDataPriority(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'TagGroup.%' THEN
			FilterTag(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricText.%' THEN
			FilterRegionMetricText(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricDate.%' THEN
			FilterRegionMetricDate(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricCombo.%' THEN
			FilterRegionMetricCombo(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricNumber.%' THEN
			FilterRegionMetricNumber(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || r.name);
		END IF;
		
		chain.filter_pkg.EndDebugLog(v_inner_log_id);
		
		IF r.comparator = chain.filter_pkg.COMPARATOR_EXCLUDE THEN 
			chain.filter_pkg.InvertFilterSet(v_starting_ids, v_result_ids, v_result_ids);
		END IF;
		
		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_ids := v_result_ids;
		ELSE
			out_ids := out_ids MULTISET UNION v_result_ids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CopyFilter (
	in_from_filter_id				IN	chain.filter.filter_id%TYPE,
	in_to_filter_id					IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	chain.filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE RunCompoundFilter(
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	chain.filter_pkg.RunCompoundFilter('FilterMeterDataIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_consumption_input_id			meter_input.meter_input_id%TYPE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.GetFilterObjectData');
	
	BEGIN
		SELECT meter_input_id
		  INTO v_consumption_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'CONSUMPTION';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore
	END;

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT /*+ USE_NL(l mld) INDEX(mld UK_METER_DATA_ID)*/DISTINCT a.column_value, mld.meter_data_id, 
		   CASE a.column_value
				WHEN AGG_TYPE_SUM THEN chain.filter_pkg.AFUNC_SUM
				ELSE mat.analytic_function
			END,
			mld.consumption
	  FROM meter_live_data mld
	  JOIN TABLE(in_id_list) l ON  mld.meter_data_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	  LEFT JOIN chain.customer_aggregate_type cat ON a.column_value = cat.customer_aggregate_type_id
	  LEFT JOIN meter_aggregate_type mat ON cat.meter_aggregate_type_id = mat.meter_aggregate_type_id
	 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mld.meter_input_id = NVL(mat.meter_input_id, v_consumption_input_id)
	   AND mld.aggregator = NVL(mat.aggregator, 'SUM')
	;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_is_priority_filtered			NUMBER(1);
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.GetFilteredIds');
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	-- Pare down the region list to meters only
	DELETE FROM temp_region_sid tr
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = tr.region_sid
		   AND region_type IN (
			   	csr_data_pkg.REGION_TYPE_METER,
				csr_data_pkg.REGION_TYPE_RATE,
				csr_data_pkg.REGION_TYPE_REALTIME_METER
		   )
	 );

	-- Pare down the meter list based on a security check
	DELETE FROM temp_region_sid tr
	 WHERE security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), tr.region_sid, security_pkg.PERMISSION_READ) = 0;

	/*
		If we are "filtering" or "breaking down" by meter_data_priority, we show all values including system calculated output.
		Otherwise, we need to show the "calculated view" only (rn = 1 below) i.e. it will omit all values that don't contribute towards the total.
	*/
	SELECT DECODE(COUNT(filter_id), 0, 0, 1) 
	  INTO v_is_priority_filtered
	  FROM chain.v$filter_field
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND compound_filter_id IN (in_compound_filter_id, in_grp_by_compound_filter_id)
	   AND name = 'MeterDataPriority';
	
	-- Start with the list they have access to
	SELECT chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, mld.start_dtm, mld.priority, mld.meter_data_id,
			   ROW_NUMBER() OVER (PARTITION BY mld.app_sid, mld.region_sid, mld.meter_input_id, mld.aggregator, mld.meter_bucket_id, mld.start_dtm ORDER BY mld.priority DESC) rn
	      FROM meter_live_data mld
		  JOIN temp_region_sid tr ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.region_sid = tr.region_sid
		  JOIN meter_data_priority mdp ON mdp.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.priority = mdp.priority
		 WHERE (in_id_list IS NULL OR mld.meter_data_id IN (SELECT DISTINCT object_id FROM TABLE(in_id_list)))
		   AND (in_date_col_type IS NULL 
			OR ((in_start_dtm IS NULL OR TRUNC(in_start_dtm) <= mld.start_dtm )
		   AND (in_end_dtm IS NULL OR TRUNC(in_end_dtm) > mld.start_dtm)))
		   AND mld.meter_bucket_id = in_group_key -- the group key contains the selected bucket id
		   AND mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mld.consumption IS NOT NULL
	  ) mld
	 WHERE (mld.rn = 1 OR v_is_priority_filtered = 1)
	 ORDER BY region_sid, start_dtm, meter_input_id, priority;

	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;

	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_id_list,
				out_id_list						=> v_id_list
			);
		END LOOP;
	END IF;
	
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, v_id_list, v_id_list);
	END IF;

	out_id_list := v_id_list;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.ApplyBreadcrumb');

	out_id_list := in_id_list;
	
	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := chain.filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);		
		
		RunCompoundFilter(v_field_compound_filter_id, 1, v_breadcrumb_count, out_id_list, out_id_list);

		-- check if any breadcrumb elements are on "other". If not, we don't need to do a top N			
		IF in_breadcrumb(1) < 0 OR
			(v_breadcrumb_count > 1 AND in_breadcrumb(2) < 0) OR
			(v_breadcrumb_count > 2 AND in_breadcrumb(3) < 0) OR
			(v_breadcrumb_count > 3 AND in_breadcrumb(4) < 0)
		THEN
			-- Use the aggregation type for drilldowns on "other"
			-- If not supplied, use count
			SELECT NVL(in_aggregation_type, 1) BULK COLLECT INTO v_aggregation_types FROM dual;

			GetFilterObjectData (v_aggregation_types, out_id_list);
			
			-- apply top n
 			v_top_n_values := chain.filter_pkg.FindTopN(v_field_compound_filter_id, NVL(in_aggregation_type, 1), out_id_list, in_breadcrumb);  
			
			-- update any rows that aren't in top N to -group_by_index, indicating they're "other"
			SELECT chain.T_FILTERED_OBJECT_ROW (l.object_id, l.group_by_index, CASE WHEN t.pos IS NOT NULL THEN l.group_by_value ELSE -ff.filter_field_id END)
			  BULK COLLECT INTO v_temp
			  FROM TABLE(out_id_list) l
			  JOIN chain.v$filter_field ff ON l.group_by_index = ff.group_by_index AND ff.compound_filter_id = v_field_compound_filter_id
			  LEFT JOIN TABLE(v_top_n_values) t ON l.group_by_value = t.pos;
		ELSE
			v_temp := out_id_list;
		END IF;
		
		-- apply breadcrumb
		chain.filter_pkg.ApplyBreadcrumb(v_temp, in_breadcrumb, out_id_list);
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CollectSearchResults (
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_cur 						OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT /*+ USE_NL(ids mld) INDEX(mld UK_METER_DATA_ID) */mld.app_sid, mld.region_sid, mld.meter_bucket_id, mld.meter_input_id, 
		       mld.aggregator, mld.priority, mld.start_dtm, mld.meter_data_id,
		       mld.meter_raw_data_id, mld.end_dtm, mld.modified_dtm, mld.consumption, 
		       r.description region_description, mb.description meter_bucket_description,
			   mdp.label priority_description, mi.label meter_input_description,
			   ma.label aggregator_description, am.reference, am.urjanet_meter_id,
			   mdp.is_input, NVL(mc.description, m.description) unit
		  FROM meter_live_data mld
		  JOIN TABLE(in_id_list) ids ON mld.meter_data_id = ids.sid_id
		  JOIN v$region r ON mld.app_sid = r.app_sid AND mld.region_sid = r.region_sid
		  JOIN all_meter am ON mld.app_sid = am.app_sid AND mld.region_sid = am.region_sid
		  JOIN meter_bucket mb ON mld.app_sid = mb.app_sid AND mld.meter_bucket_id = mb.meter_bucket_id
		  JOIN meter_data_priority mdp ON mld.app_sid = mdp.app_sid AND mld.priority = mdp.priority
		  JOIN meter_input mi ON mld.app_sid = mi.app_sid AND mld.meter_input_id = mi.meter_input_id
		  JOIN meter_aggregator ma ON mld.aggregator = ma.aggregator
		  JOIN meter_input_aggr_ind miai ON miai.app_sid = mld.app_sid AND miai.region_sid = mld.region_sid AND miai.meter_input_id = mld.meter_input_id
		  LEFT JOIN measure_conversion mc ON miai.app_sid = mc.app_sid AND miai.measure_conversion_id = mc.measure_conversion_id
		  LEFT JOIN measure m ON miai.app_sid = m.app_sid AND miai.measure_sid = m.measure_sid
		 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		ORDER BY ids.pos;
		 
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredMeterIds (
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.PageFilteredMeterIds');	
	
	IF in_order_by = 'regionDescription' AND in_order_dir = 'ASC' THEN
		SELECT security.T_ORDERED_SID_ROW(meter_data_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.meter_data_id, ROWNUM rn
			  FROM (
				SELECT /*+ USE_NL(fil_list mld) INDEX(mld UK_METER_DATA_ID)*/mld.meter_data_id
				  FROM meter_live_data mld
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON mld.meter_data_id = fil_list.object_id
				  JOIN v$region r ON mld.app_sid = r.app_sid AND mld.region_sid = r.region_sid
				 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 ORDER BY r.description ASC, mld.start_dtm DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE		
		SELECT security.T_ORDERED_SID_ROW(meter_data_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.meter_data_id, ROWNUM rn
			  FROM (
				SELECT /*+ USE_NL(fil_list mld) INDEX(mld UK_METER_DATA_ID)*/mld.meter_data_id
				  FROM meter_live_data mld
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON mld.meter_data_id = fil_list.object_id
				  JOIN v$region r ON mld.app_sid = r.app_sid AND mld.region_sid = r.region_sid
				  JOIN all_meter am ON mld.app_sid = am.app_sid AND mld.region_sid = am.region_sid
				  JOIN meter_bucket mb ON mld.app_sid = mb.app_sid AND mld.meter_bucket_id = mb.meter_bucket_id
				  JOIN meter_data_priority mdp ON mld.app_sid = mdp.app_sid AND mld.priority = mdp.priority
				  JOIN meter_input mi ON mld.app_sid = mi.app_sid AND mld.meter_input_id = mi.meter_input_id
				  JOIN meter_aggregator ma ON mld.aggregator = ma.aggregator
				 WHERE mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				ORDER BY
					-- To avoid dyanmic SQL, do many case statements
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
						CASE (in_order_by)
							WHEN 'meterDataId' THEN TO_CHAR(mld.meter_data_id, '0000000000')
							WHEN 'regionSid' THEN TO_CHAR(mld.region_sid, '0000000000')
							WHEN 'reference' THEN LOWER(am.reference)
							WHEN 'urjanetMeterId' THEN LOWER(am.urjanet_meter_id)
							WHEN 'regionDescription' THEN LOWER(r.description)
							WHEN 'meterInputDescription' THEN LOWER(mi.label)
							WHEN 'priorityDescription' THEN LOWER(mdp.label)
							WHEN 'aggregatorDescription' THEN LOWER(ma.label)
							WHEN 'meterRawDataId' THEN TO_CHAR(NVL(mld.meter_raw_data_id, mdp.is_input))
							WHEN 'startDtm' THEN TO_CHAR(mld.start_dtm, 'YYYY-MM-DD HH24:MI:SS')
							WHEN 'endDtm' THEN TO_CHAR(mld.end_dtm, 'YYYY-MM-DD HH24:MI:SS')
							WHEN 'modifiedDtm' THEN TO_CHAR(mld.modified_dtm, 'YYYY-MM-DD HH24:MI:SS')
							WHEN 'consumption' THEN NVL2(mld.consumption, TO_CHAR(mld.consumption, '0000000000'), ' ')
						END
					END ASC,
					CASE WHEN in_order_dir='DESC' THEN
						CASE (in_order_by)
							WHEN 'meterDataId' THEN TO_CHAR(mld.meter_data_id, '0000000000')
							WHEN 'regionSid' THEN TO_CHAR(mld.region_sid, '0000000000')
							WHEN 'reference' THEN LOWER(am.reference)
							WHEN 'urjanetMeterId' THEN LOWER(am.urjanet_meter_id)
							WHEN 'regionDescription' THEN LOWER(r.description)
							WHEN 'meterInputDescription' THEN LOWER(mi.label)
							WHEN 'priorityDescription' THEN LOWER(mdp.label)
							WHEN 'aggregatorDescription' THEN LOWER(ma.label)
							WHEN 'meterRawDataId' THEN TO_CHAR(NVL(mld.meter_raw_data_id, mdp.is_input))
							WHEN 'startDtm' THEN TO_CHAR(mld.start_dtm, 'YYYY-MM-DD HH24:MI:SS')
							WHEN 'endDtm' THEN TO_CHAR(mld.end_dtm, 'YYYY-MM-DD HH24:MI:SS')
							WHEN 'modifiedDtm' THEN TO_CHAR(mld.modified_dtm, 'YYYY-MM-DD HH24:MI:SS')
							WHEN 'consumption' THEN NVL2(mld.consumption, TO_CHAR(mld.consumption, '0000000000'), ' ')
						END
					END DESC,
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN LOWER(r.description) END ASC,
					CASE WHEN in_order_dir='DESC' THEN LOWER(r.description) END DESC,
					mld.start_dtm DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_PopGridExtTempTable(
	in_id_page						IN security.T_ORDERED_SID_TABLE
)
AS 
	v_enabled_extensions			SYS_REFCURSOR;
	v_name							chain.grid_extension.record_name%TYPE;
	v_extension_id					chain.grid_extension.extension_card_group_id%TYPE;
BEGIN
	DELETE FROM chain.temp_grid_extension_map;

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_METER_DATA, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Meter Data -> '||v_name);

	END LOOP;
END;

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_bounds_north					IN	NUMBER,
	in_bounds_east					IN	NUMBER,
	in_bounds_south					IN	NUMBER,
	in_bounds_west					IN	NUMBER,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_session_prefix				IN	VARCHAR2 DEFAULT NULL,
	out_total_rows					OUT	NUMBER,
	out_cur 						OUT  SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.GetList', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		in_id_list_populated	=> in_id_list_populated,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);	

	PageFilteredMeterIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAggregateDetails (
	in_aggregation_types			IN  security.T_ORDERED_SID_TABLE,
	in_id_col_sid					IN  security_pkg.T_SID_ID,
	out_agg_types					OUT chain.T_FILTER_AGG_TYPE_TABLE,
	out_aggregate_thresholds		OUT chain.T_FILTER_AGG_TYPE_THRES_TABLE
)
AS
BEGIN
	WITH t AS (
		SELECT meter_input_id, DECODE(COUNT(meter_input_id), 1, MIN(measure_sid), NULL) measure_sid, DECODE(COUNT(meter_input_id), 1, MIN(description), NULL) description
		  FROM (
			SELECT miai.meter_input_id, miai.measure_sid, m.description
			  FROM csr.meter_input_aggr_ind miai
			  JOIN csr.temp_region_sid trs ON miai.region_sid = trs.region_sid
			  JOIN csr.measure m ON miai.measure_sid = m.measure_sid
			 GROUP BY miai.meter_input_id, miai.measure_sid, m.description
		) 
		 GROUP BY meter_input_id
	)
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_METER_DATA, a.aggregate_type_id, a.description, '#,##0.##', null, a.accumulative, a.aggregate_group, a.unit_of_measure, null)
	  BULK COLLECT INTO out_agg_types
		  FROM TABLE(in_aggregation_types) sat
		  JOIN (
			SELECT at.aggregate_type_id, at.description, 0 accumulative, t.measure_sid aggregate_group, t.description unit_of_measure
			  FROM chain.aggregate_type at
			  LEFT JOIN t t ON t.meter_input_id = at.aggregate_type_id
			 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_METER_DATA
			 UNION
			SELECT cat.customer_aggregate_type_id, mat.description, mat.accumulative, t.measure_sid aggregate_group, t.description unit_of_measure
			  FROM meter_aggregate_type mat
			  JOIN chain.customer_aggregate_type cat ON cat.card_group_id = chain.filter_pkg.FILTER_TYPE_METER_DATA AND cat.meter_aggregate_type_id  = mat.meter_aggregate_type_id
			  LEFT JOIN t t ON t.meter_input_id = mat.meter_input_id
			) a ON sat.sid_id = a.aggregate_type_id
		 ORDER BY sat.pos;
END;

PROCEDURE GetReportData(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_grp_by_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_aggregation_types			IN	security.T_SID_TABLE DEFAULT NULL,
	in_show_totals					IN	NUMBER DEFAULT NULL,
	in_breadcrumb					IN	security.T_SID_TABLE DEFAULT NULL,
	in_max_group_by					IN	NUMBER DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT NULL,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_SUM;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search						=> in_search,
		in_group_key					=> in_group_key,
		in_pre_filter_sid				=> in_pre_filter_sid,
		in_parent_type					=> in_parent_type,
		in_parent_id					=> in_parent_id,
		in_compound_filter_id			=> in_compound_filter_id,
		in_region_sids					=> in_region_sids,
		in_start_dtm					=> in_start_dtm,
		in_end_dtm						=> in_end_dtm,
		in_region_col_type				=> in_region_col_type,
		in_date_col_type				=> in_date_col_type,
		in_grp_by_compound_filter_id	=> in_grp_by_compound_filter_id,
		out_id_list						=> v_id_list
	);
			
	IF in_grp_by_compound_filter_id IS NOT NULL THEN	
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);
	
	chain.filter_pkg.GetAggregateData(
		chain.filter_pkg.FILTER_TYPE_METER_DATA, in_grp_by_compound_filter_id, in_aggregation_types, 
		in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, 
		out_data_cur
	);
	
	GetExtraSeries(in_group_key, in_grp_by_compound_filter_id, v_id_list, in_aggregation_types, in_breadcrumb, out_extra_series_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	OPEN out_cur FOR
		SELECT fil_list.object_id
		  FROM TABLE(in_id_list) fil_list;
END;

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_cur 						OUT  SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);
	
	-- Group by thing to ensure correct ordering on export
	SELECT security.T_ORDERED_SID_ROW(object_id, MAX(rn))
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT object_id, ROWNUM rn
		  FROM TABLE(v_id_list)
	)
	GROUP BY object_id;

	INTERNAL_PopGridExtTempTable(v_id_page);
	
	CollectSearchResults(v_id_page, out_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_METER_DATA
		);
	
	--security trim the list of ids
	GetFilteredIds (
		in_compound_filter_id	=> 0, 
		in_id_list				=> v_id_list,
		out_id_list				=> v_id_list
	);

	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);
	
	CollectSearchResults(
		in_id_list					=> v_id_page,
		out_cur 					=> out_cur
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInterDayAnalytics (
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	in_start_dtm_filter_field_id	IN  chain.filter_field.filter_field_id%TYPE,
	in_inter_day_filter_field_id	IN  chain.filter_field.filter_field_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_consumption_input_id			meter_input.meter_input_id%TYPE;
	v_past_months					NUMBER;
	v_include_current_month			NUMBER;
	v_breadcrumb_count				NUMBER;
	v_breadcrumb_1					NUMBER;
	v_current_month					DATE;
BEGIN
	BEGIN
		SELECT analytics_months, analytics_current_month
		  INTO v_past_months, v_include_current_month
		  FROM metering_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_past_months := 36;
			v_include_current_month := 1;
	END;

	BEGIN
		SELECT meter_input_id
		  INTO v_consumption_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'CONSUMPTION';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore
	END;
	
	DELETE FROM csr.temp_region_sid;
	INSERT INTO temp_region_sid (region_sid)
		 SELECT /*+ USE_NL(fil_list mld) INDEX(mld UK_METER_DATA_ID)*/DISTINCT region_sid
		   FROM meter_live_data mld
		   JOIN TABLE(in_id_list) fil_list ON mld.meter_data_id = fil_list.object_id;
		   
	SELECT /*+ USE_NL(fil_list mld) INDEX(mld UK_METER_DATA_ID)*/MIN(start_dtm)
	  INTO v_current_month
	  FROM meter_live_data mld
	  JOIN TABLE(in_id_list) fil_list ON mld.meter_data_id = fil_list.object_id;
	  
	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	IF v_breadcrumb_count > 0 THEN
		v_breadcrumb_1 := in_breadcrumb(1);
	END IF;
	
	OPEN out_cur FOR
		-- we could tune this with /*+ materialize */ ... though it is undocumented...
		WITH a AS ( 
			SELECT NVL(a.consumption, 0) consumption, ifv.pos, NVL(a.aggregate_type_id, ifv.aggregate_type_id) aggregate_type_id,
			       fv.filter_value_id, TO_CHAR(fv.start_dtm_value, 'D') day_of_week, ifv.num_value hour_of_day
			  FROM (
				SELECT ifv.filter_value_id, ifv.num_value, ifv.pos, at.column_value aggregate_type_id
				  FROM chain.filter_value ifv			  
				 CROSS JOIN TABLE (in_aggregation_types) at
				 WHERE ifv.filter_field_id = in_inter_day_filter_field_id
			  ) ifv  
			 CROSS JOIN chain.filter_value fv 
			  LEFT JOIN (
				  -- this gets us consumption per day of the week in the month we care about
				SELECT   
					CASE  
						WHEN mat.analytic_function = chain.filter_pkg.AFUNC_AVERAGE THEN ROUND(AVG(mld.consumption), 10)
						WHEN mat.analytic_function = chain.filter_pkg.AFUNC_MIN THEN ROUND(MIN(mld.consumption), 10)
						WHEN mat.analytic_function = chain.filter_pkg.AFUNC_MAX THEN ROUND(MAX(mld.consumption), 10)
						WHEN mat.analytic_function = chain.filter_pkg.AFUNC_STD_DEV THEN ROUND(STDDEV(mld.consumption), 10)
						ELSE SUM(mld.consumption)						
					END consumption,
					a.column_value aggregate_type_id,
					TO_CHAR(mld.start_dtm, 'D') day_of_week,
					TO_CHAR(mld.start_dtm, 'HH24') hour_of_day
				  FROM v$patched_meter_live_data mld
				  JOIN temp_region_sid tr ON mld.region_sid = tr.region_sid
				  CROSS JOIN TABLE (in_aggregation_types) a
				  LEFT JOIN chain.customer_aggregate_type cat ON a.column_value = cat.customer_aggregate_type_id
				  LEFT JOIN meter_aggregate_type mat ON cat.meter_aggregate_type_id = mat.meter_aggregate_type_id
				 WHERE mld.meter_input_id = NVL(mat.meter_input_id, v_consumption_input_id)
				   AND mld.aggregator = NVL(mat.aggregator, 'SUM')
				   AND mld.meter_bucket_id = in_group_key -- the group key contains the selected bucket id
				   AND mld.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND TO_CHAR(mld.start_dtm, 'MM') = TO_CHAR(v_current_month, 'MM')
				   -- Go back in time by v_past_months
				   AND (v_past_months IS NULL OR TRUNC(mld.start_dtm, 'MONTH') >= ADD_MONTHS(TRUNC(v_current_month, 'MONTH'), -v_past_months))
				   -- Include the current month or not based on option, but never go beyond v_current_month
				   AND TRUNC(mld.start_dtm, 'MONTH') < ADD_MONTHS(TRUNC(v_current_month, 'MONTH'), v_include_current_month/*always 0 or 1*/)
				 GROUP BY a.column_value, mld.start_dtm, mat.analytic_function
			  ) a ON a.hour_of_day = ifv.num_value AND a.aggregate_type_id = ifv.aggregate_type_id AND a.day_of_week = TO_CHAR(fv.start_dtm_value, 'D')
			 WHERE fv.filter_field_id = in_start_dtm_filter_field_id
			   AND fv.filter_value_id = NVL(v_breadcrumb_1, fv.filter_value_id)			 
		)
		SELECT ROUND(MAX(a.consumption), 2) val, 'Max' series_name, MIN(a.pos) pos, a.aggregate_type_id, a.filter_value_id parent_filter_value_id
		  FROM a
		 GROUP BY a.aggregate_type_id, a.filter_value_id, a.day_of_week, a.hour_of_day
		 UNION ALL
		SELECT ROUND(AVG(a.consumption), 2) val, 'Average' series_name, MIN(a.pos) pos, a.aggregate_type_id, a.filter_value_id parent_filter_value_id
		  FROM a
		 GROUP BY a.aggregate_type_id, a.filter_value_id, a.day_of_week, a.hour_of_day
		 UNION ALL
		SELECT ROUND(MIN(a.consumption), 2) val, 'Min' series_name, MIN(a.pos) pos, a.aggregate_type_id, a.filter_value_id parent_filter_value_id
		  FROM a
		 GROUP BY a.aggregate_type_id, a.filter_value_id, a.day_of_week, a.hour_of_day
		;
END;

PROCEDURE GetExtraSeries (
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_breadcrumb					IN	security.T_SID_TABLE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_start_dtm_filter_field_id		chain.filter_field.filter_field_id%TYPE;
	v_inter_day_filter_field_id		chain.filter_field.filter_field_id%TYPE;
BEGIN
	BEGIN
		-- If its a breakdown of StartDtm then InterDay and the data is within a month
		-- then get interday analytics
		SELECT ff1.filter_field_id, ff2.filter_field_id
		  INTO v_start_dtm_filter_field_id, v_inter_day_filter_field_id
		  FROM chain.compound_filter cf
		  JOIN chain.v$filter_field ff1 ON cf.compound_filter_id = ff1.compound_filter_id AND ff1.group_by_index = 1
		  JOIN chain.v$filter_field ff2 ON cf.compound_filter_id = ff2.compound_filter_id AND ff2.group_by_index = 2
		  LEFT JOIN chain.v$filter_field ff3 ON cf.compound_filter_id = ff3.compound_filter_id AND ff3.group_by_index = 3
		  LEFT JOIN metering_options mo ON cf.app_sid = mo.app_sid
		  JOIN (
			SELECT fv.filter_field_id, MAX(fv.start_dtm_value) max_dtm, MIN(fv.start_dtm_value) min_dtm
			  FROM chain.filter_value fv
			 GROUP BY fv.filter_field_id
		  ) fvc ON ff1.filter_field_id = fvc.filter_field_id
		 WHERE cf.compound_filter_id = in_compound_filter_id
		   AND ff1.name = 'StartDtm'
		   AND ff2.name = 'InterDay'
		   AND ff3.compound_filter_id IS NULL -- limit to charts with just these breakdowns for now
		   AND (mo.app_sid IS NULL OR mo.analytics_months IS NOT NULL)
		   AND TO_CHAR(fvc.max_dtm, 'MM-YYYY') = TO_CHAR(fvc.min_dtm, 'MM-YYYY'); -- make sure its got <= 1 months data
			
		GetInterDayAnalytics(in_group_key, in_compound_filter_id, in_id_list, in_aggregation_types, 
			in_breadcrumb, v_start_dtm_filter_field_id, v_inter_day_filter_field_id, out_cur);
	EXCEPTION
		WHEN no_data_found THEN
			chain.filter_pkg.GetEmptyExtraSeriesCur(out_cur);
	END;
END;

PROCEDURE PopulateTempMeterDataIdRegion (
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- Populate temp table with region sids/meter_data_id map
	-- For the meter's region sid, its parent space, and its parent property (if any)
	DELETE FROM temp_meter_data_id_region;
	INSERT INTO temp_meter_data_id_region (region_sid, meter_data_id)
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/mld.region_sid, mld.meter_data_id
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id;
		  
	-- Insert tags from parent objects
	INSERT INTO temp_meter_data_id_region (region_sid, meter_data_id)
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/x.region_sid, mld.meter_data_id
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
		  JOIN (
			SELECT region_sid, meter_region_sid
			  FROM (
				 SELECT region_sid, region_type, connect_by_root region_sid meter_region_sid
				   FROM region 
				  WHERE CONNECT_BY_ISLEAF = 1
				  START WITH region_sid IN (SELECT mld.region_sid FROM meter_live_data mld JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid =SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id)
				CONNECT BY PRIOR parent_sid = region_sid
					AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
			  )
			 WHERE region_type != csr_data_pkg.REGION_TYPE_ROOT
			UNION
			SELECT region_sid, meter_region_sid
			  FROM (
				 SELECT region_sid, region_type, connect_by_root region_sid meter_region_sid
				   FROM region 
				  WHERE CONNECT_BY_ISLEAF = 1
				  START WITH region_sid IN (SELECT mld.region_sid FROM meter_live_data mld JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid =SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id)
				CONNECT BY PRIOR parent_sid = region_sid
					AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
					AND PRIOR region_type != csr_data_pkg.REGION_TYPE_SPACE
			  )
			 WHERE region_type != csr_data_pkg.REGION_TYPE_ROOT
		) x ON mld.region_sid = x.meter_region_sid;
END;

/********************************************/
/*		Filter field units					*/
/********************************************/

/*  Each filter unit must:
 *   o  Filter the list of in_ids into the out_ids based on the user's selected values for the given in_filter_field_id
 *   o  Pre-populate all possible values if in_show_all = 1
 *   o  Preserve existing duplicate IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *  
 *  It's OK to return duplicate IDs if filter field values overlap. These duplicates are discounted for issue lists
 *  but required for charts to work correctly. Each filter field unit must preserve existing duplicate issue ids that are
 *  passed in.
 */
PROCEDURE FilterRegionSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/mld.region_sid
			  FROM meter_live_data mld
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
			 GROUP BY mld.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, mld.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/DISTINCT mld.meter_data_id, fv.filter_value_id
			  FROM meter_live_data mld
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
			  JOIN chain.filter_value fv ON mld.region_sid = fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) mld;
	ELSE
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON mld.region_sid = r.region_sid;
	END IF;	
END;

PROCEDURE FilterStartDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/MIN(mld.start_dtm), MAX(mld.start_dtm)
		  INTO v_min_date, v_max_date
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  -- Can't use BETWEEN as we're comparing withthe start date, not the start date and the end date
	  JOIN chain.tt_filter_date_range dr
	    ON mld.start_dtm >= NVL(dr.start_dtm, mld.start_dtm) 
	   AND mld.start_dtm  < NVL(dr.end_dtm, mld.start_dtm)
	;		
END;

PROCEDURE FilterDaily (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/MIN(mld.start_dtm), MAX(mld.start_dtm)
		  INTO v_min_date, v_max_date
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id;

		-- Create day data
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, pos, start_dtm_value, end_dtm_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pos, start_dtm, start_dtm + 1, TO_CHAR(start_dtm, 'DD-MM-YYYY')
			  FROM (
				SELECT LEVEL pos, MOD(LEVEL-1, 12) + 1 period_id, TRUNC(v_min_date, 'DD') + LEVEL - 1 start_dtm
				  FROM DUAL
				CONNECT BY LEVEL <= TRUNC(v_max_date, 'DD') - TRUNC(v_min_date, 'DD') + 1
			) x
			 WHERE NOT EXISTS (
				SELECT 1
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.start_dtm_value = x.start_dtm
				   AND fv.end_dtm_value = start_dtm + 1
			 );
	END IF;

	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.start_dtm = fv.start_dtm_value AND fv.filter_field_id = in_filter_field_id
	;
END;

PROCEDURE FilterInterDay (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.hour_enum, dr.description
			  FROM (
				SELECT 0 hour_enum, '00:00' description FROM dual
				UNION ALL SELECT 1, '01:00' FROM dual
				UNION ALL SELECT 2, '02:00' FROM dual
				UNION ALL SELECT 3, '03:00' FROM dual
				UNION ALL SELECT 4, '04:00' FROM dual
				UNION ALL SELECT 5, '05:00' FROM dual
				UNION ALL SELECT 6, '06:00' FROM dual
				UNION ALL SELECT 7, '07:00' FROM dual
				UNION ALL SELECT 8, '08:00' FROM dual
				UNION ALL SELECT 9, '09:00' FROM dual
				UNION ALL SELECT 10, '10:00' FROM dual
				UNION ALL SELECT 11, '11:00' FROM dual
				UNION ALL SELECT 12, '12:00' FROM dual
				UNION ALL SELECT 13, '13:00' FROM dual
				UNION ALL SELECT 14, '14:00' FROM dual
				UNION ALL SELECT 15, '15:00' FROM dual
				UNION ALL SELECT 16, '16:00' FROM dual
				UNION ALL SELECT 17, '17:00' FROM dual
				UNION ALL SELECT 18, '18:00' FROM dual
				UNION ALL SELECT 19, '19:00' FROM dual
				UNION ALL SELECT 20, '20:00' FROM dual
				UNION ALL SELECT 21, '21:00' FROM dual
				UNION ALL SELECT 22, '22:00' FROM dual
				UNION ALL SELECT 23, '23:00' FROM dual
			 ) dr
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.hour_enum
			);
	END IF;

	-- Always order
	INTERNAL_OrderFilterByNumValue(in_filter_field_id);
	
	-- Note: Use hourly bucket
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON TO_CHAR(mld.start_dtm, 'HH24') = fv.num_value AND fv.filter_Field_id = in_filter_field_id
	 ;
END;

PROCEDURE FilterInterWeek (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.day_enum, dr.description
			  FROM (
				SELECT 1 day_enum, 'Monday' description FROM dual
				UNION ALL SELECT 2, 'Tuesday' FROM dual
				UNION ALL SELECT 3, 'Wednesday' FROM dual
				UNION ALL SELECT 4, 'Thursday' FROM dual
				UNION ALL SELECT 5, 'Friday' FROM dual
				UNION ALL SELECT 6, 'Saturday' FROM dual
				UNION ALL SELECT 7, 'Sunday' FROM dual
			) dr
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.day_enum
			);
	END IF;

	-- Always order
	INTERNAL_OrderFilterByNumValue(in_filter_field_id);
	
	-- Note: Use daily bucket
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON TO_CHAR(mld.start_dtm, 'D') = fv.num_value AND fv.filter_Field_id = in_filter_field_id 
	 ;
END;

PROCEDURE FilterInterMonth (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.day_enum, dr.description
			  FROM (
				SELECT 1 day_enum, '1st' description FROM dual
				UNION ALL SELECT 2, '2nd' FROM dual
				UNION ALL SELECT 3, '3rd' FROM dual
				UNION ALL SELECT 4, '4th' FROM dual
				UNION ALL SELECT 5, '5th' FROM dual
				UNION ALL SELECT 6, '6th' FROM dual
				UNION ALL SELECT 7, '7th' FROM dual
				UNION ALL SELECT 8, '8th' FROM dual
				UNION ALL SELECT 9, '9th' FROM dual
				UNION ALL SELECT 10, '10th' FROM dual
				UNION ALL SELECT 11, '11th' FROM dual
				UNION ALL SELECT 12, '12th' FROM dual
				UNION ALL SELECT 13, '13th' FROM dual
				UNION ALL SELECT 14, '14th' FROM dual
				UNION ALL SELECT 15, '15th' FROM dual
				UNION ALL SELECT 16, '16th' FROM dual
				UNION ALL SELECT 17, '17th' FROM dual
				UNION ALL SELECT 18, '18th' FROM dual
				UNION ALL SELECT 19, '19th' FROM dual
				UNION ALL SELECT 20, '20th' FROM dual
				UNION ALL SELECT 21, '21st' FROM dual
				UNION ALL SELECT 22, '22nd' FROM dual
				UNION ALL SELECT 23, '23rd' FROM dual
				UNION ALL SELECT 24, '24th' FROM dual
				UNION ALL SELECT 25, '25th' FROM dual
				UNION ALL SELECT 26, '26th' FROM dual
				UNION ALL SELECT 27, '27th' FROM dual
				UNION ALL SELECT 28, '28th' FROM dual
				UNION ALL SELECT 29, '29th' FROM dual
				UNION ALL SELECT 30, '30th' FROM dual
				UNION ALL SELECT 31, '31st' FROM dual
			) dr
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.day_enum
			);
	END IF;

	-- Always order
	INTERNAL_OrderFilterByNumValue(in_filter_field_id);
	
	-- Note: Use daily bucket
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON TO_CHAR(mld.start_dtm, 'DD') = fv.num_value AND fv.filter_Field_id = in_filter_field_id 
	 ;
END;

PROCEDURE FilterInterYear (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.month_enum, dr.description
			  FROM (
				SELECT 1 month_enum, 'January' description FROM dual
				UNION ALL SELECT 2, 'February' FROM dual
				UNION ALL SELECT 3, 'March' FROM dual
				UNION ALL SELECT 4, 'April' FROM dual
				UNION ALL SELECT 5, 'May' FROM dual
				UNION ALL SELECT 6, 'June' FROM dual
				UNION ALL SELECT 7, 'July' FROM dual
				UNION ALL SELECT 8, 'August' FROM dual
				UNION ALL SELECT 9, 'September' FROM dual
				UNION ALL SELECT 10, 'October' FROM dual
				UNION ALL SELECT 11, 'November' FROM dual
				UNION ALL SELECT 12, 'December' FROM dual
			) dr
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.month_enum
			);
	END IF;

	-- Always order 
	INTERNAL_OrderFilterByNumValue(in_filter_field_id);
	
	-- Note: Use daily bucket
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON TO_CHAR(mld.start_dtm, 'MM') = fv.num_value AND fv.filter_Field_id = in_filter_field_id
	 ;
END;

PROCEDURE FilterMeterType (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.id, dr.description
			  FROM (
				SELECT meter_type_id id, label description
				  FROM meter_type
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) dr
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.id
			);
	END IF;

	-- Always order by description
	INTERNAL_OrderFilterByDesc(in_filter_field_id);
	
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  JOIN all_meter m ON m.app_sid = mld.app_sid AND m.region_sid = mld.region_sid
	  JOIN chain.filter_value fv ON fv.num_value = m.meter_type_id AND fv.filter_Field_id = in_filter_field_id
	 ;
END;

PROCEDURE FilterMeterTypeGroup (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.group_key, dr.description
			  FROM (
			  	SELECT DISTINCT mi.group_key, mi.group_key description
				  FROM meter_type mi
				 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) dr
			WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.str_value = dr.group_key
			);
	END IF;

	-- Always order by description
	INTERNAL_OrderFilterByDesc(in_filter_field_id);
	
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
	  JOIN all_meter m ON m.app_sid = mld.app_sid AND m.region_sid = mld.region_sid
	  JOIN meter_type mi ON mi.app_sid = m.app_sid AND mi.meter_type_id = m.meter_type_id
	  JOIN chain.filter_value fv ON fv.str_value = mi.group_key AND fv.filter_Field_id = in_filter_field_id
	 ;
END;

PROCEDURE FilterYear (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/MIN(mld.start_dtm), MAX(mld.start_dtm)
		  INTO v_min_date, v_max_date
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id;

		-- Create year data
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, pos, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pos, yr, yr
			  FROM (
				SELECT LEVEL pos, TO_CHAR(v_min_date, 'YYYY') + LEVEL - 1 yr
				  FROM DUAL
					CONNECT BY LEVEL <= TO_CHAR(GREATEST(SYSDATE, v_max_date), 'YYYY') - TO_CHAR(v_min_date, 'YYYY') + 1
			 ) x
			 WHERE NOT EXISTS (
				SELECT 1
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = x.yr
			 );
	END IF;

	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND fv.num_value = TO_CHAR(mld.start_dtm, 'YYYY') AND fv.filter_field_id = in_filter_field_id
	;
END;

PROCEDURE FilterInterYearByDay (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/MIN(mld.start_dtm), MAX(mld.start_dtm)
		  INTO v_min_date, v_max_date
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id;

		-- Create year data
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, pos, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pos, num_value, description
			  FROM (
			  	SELECT DISTINCT CAST (TO_CHAR(start_dtm, 'MMDD') AS NUMBER) pos, CAST (TO_CHAR(start_dtm, 'MMDD') AS NUMBER) num_value, 
						LOWER(TO_CHAR(start_dtm, 'fmDDTH')) || ' ' || INITCAP(TO_CHAR(start_dtm, 'MON')) description
				  FROM (
					SELECT TRUNC(v_min_date, 'DD') + LEVEL - 1 start_dtm
					  FROM DUAL
					  WHERE TO_CHAR(TRUNC(v_min_date, 'DD') + LEVEL - 1, 'MMDD') != '0229'
						CONNECT BY LEVEL <= TRUNC(v_max_date, 'YEAR') - TRUNC(v_min_date, 'YEAR')
					UNION
					SELECT TRUNC(v_min_date, 'DD') + LEVEL - 1 start_dtm
					  FROM DUAL
						CONNECT BY LEVEL <= TRUNC(v_max_date, 'DD') - TRUNC(v_min_date, 'DD')
				 )
			  ) x
			 WHERE NOT EXISTS (
				SELECT 1
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = x.num_value
			 );
	END IF;

	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND fv.num_value = CAST (TO_CHAR(start_dtm, 'MMDD') AS NUMBER) AND fv.filter_field_id = in_filter_field_id
	;
END;

PROCEDURE FilterTag (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_tag_group_id	 				NUMBER;
BEGIN

	-- Extract the tag goroup id!
	v_tag_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	-- Populate region/tag temp table:
	-- We gather tags from either
	--   * The first property AND space nodes found above the meter region
	--   * OR if no property or space nodes were found the parent region node
	DELETE FROM temp_meter_region_tag;
	FOR mr IN (
		SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/DISTINCT region_sid
		  FROM meter_live_data mld
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
	) LOOP
		-- Insert tags associated directly with the meter
		INSERT INTO temp_meter_region_tag(region_sid, tag_id)
			SELECT rt.region_sid, rt.tag_id
			  FROM region_tag rt 
			  WHERE rt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			    AND rt.region_sid = mr.region_sid;

		-- Insert tags from parent objects
		INSERT INTO temp_meter_region_tag(region_sid, tag_id)
			SELECT mr.region_sid, rt.tag_id
			  FROM (
				SELECT region_sid
				  FROM (
				    WITH pro AS (
				         SELECT region_sid, region_type
				           FROM region 
				          WHERE CONNECT_BY_ISLEAF = 1
				          START WITH region_sid = mr.region_sid
				        CONNECT BY PRIOR parent_sid = region_sid
				            AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
				     )
				    SELECT CASE 
				            WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.region_sid 
				            ELSE pr.region_sid -- just use parent
				           END region_sid
				      FROM pro
				        JOIN region r ON r.region_sid = mr.region_sid
				        JOIN region pr ON pr.region_sid = r.parent_sid
				)
				UNION
				SELECT region_sid
				  FROM (
				        WITH pro AS (
				         SELECT region_sid, region_type
				           FROM region 
				          WHERE CONNECT_BY_ISLEAF = 1
				          START WITH region_sid = mr.region_sid
				        CONNECT BY PRIOR parent_sid = region_sid
				            AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
				            AND PRIOR region_type != csr_data_pkg.REGION_TYPE_SPACE
				     )
				    SELECT CASE 
				            WHEN pro.region_type != csr_data_pkg.REGION_TYPE_ROOT THEN pro.region_sid 
				            ELSE pr.region_sid -- just use parent
				           END region_sid
				      FROM pro
				      JOIN region r ON r.region_sid = mr.region_sid
				      JOIN region pr ON pr.region_sid = r.parent_sid
				)
			) x
			JOIN region_tag rt ON rt.region_sid = x.region_sid;
	END LOOP;

	IF in_show_all = 1 THEN
		chain.filter_pkg.ShowAllTags(in_filter_field_id, v_tag_group_id);
	END IF;

	-- Order by tag description
	INTERNAL_OrderFilterByDesc(in_filter_field_id);

	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
	  JOIN temp_meter_region_tag tt ON mld.region_sid = tt.region_sid
	  JOIN chain.filter_value fv ON fv.num_value = tt.tag_id AND fv.filter_field_id = in_filter_field_id
	;
END;

PROCEDURE FilterRegionMetricText (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER, 
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ind_sid				NUMBER;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	PopulateTempMeterDataIdRegion(in_ids);

	SELECT chain.T_FILTERED_OBJECT_ROW(x.meter_data_id, in_group_by_index, x.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT tr.meter_data_id, fv.filter_value_id
		  FROM region_metric_val rmv
		  JOIN (
				SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
				  FROM region_metric_val crmv	-- Current
				  JOIN temp_meter_data_id_region tr ON crmv.region_sid = tr.region_sid
				 WHERE crmv.ind_sid = v_ind_sid
				   AND crmv.effective_dtm <= SYSDATE
				 GROUP BY crmv.region_sid, crmv.ind_sid
			) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
		  JOIN temp_meter_data_id_region tr ON rmv.region_sid = tr.region_sid
		  JOIN chain.filter_value fv ON LOWER(rmv.note) like '%'||LOWER(fv.str_value)||'%' 
		 WHERE fv.filter_field_id = in_filter_field_id
		) x;
END;

PROCEDURE FilterRegionMetricDate (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date				DATE;
	v_max_date				DATE;
	v_ind_sid				NUMBER;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	PopulateTempMeterDataIdRegion(in_ids);

	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(TO_DATE('30-12-1899', 'DD-MM-YYYY') + val), MAX(TO_DATE('30-12-1899', 'DD-MM-YYYY') + val)
		  INTO v_min_date, v_max_date
		  FROM region_metric_val rmv
		  JOIN temp_meter_data_id_region tr ON rmv.region_sid = tr.region_sid
		 WHERE rmv.ind_sid = v_ind_sid;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(x.meter_data_id, x.group_by_index, x.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT tr.meter_data_id, dr.group_by_index, dr.filter_value_id
		  FROM region_metric_val rmv
		  JOIN (
				SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
				  FROM region_metric_val crmv	-- Current
				  JOIN temp_meter_data_id_region tr ON crmv.region_sid = tr.region_sid
				 WHERE crmv.ind_sid = v_ind_sid
				   AND crmv.effective_dtm <= SYSDATE
				 GROUP BY crmv.region_sid, crmv.ind_sid
			) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
		  JOIN temp_meter_data_id_region tr ON rmv.region_sid = tr.region_sid
		  JOIN chain.tt_filter_date_range dr 
			ON (dr.start_dtm IS NULL OR TO_DATE('30-12-1899', 'DD-MM-YYYY') + val >= dr.start_dtm)
		   AND (dr.end_dtm IS NULL OR TO_DATE('30-12-1899', 'DD-MM-YYYY') + val < dr.end_dtm )
		 WHERE TO_DATE('30-12-1899', 'DD-MM-YYYY') + val IS NOT NULL
	  ) x;
END;

PROCEDURE FilterRegionMetricCombo (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name 	IN chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER, 
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ind_sid				NUMBER;
	v_custom_field			measure.custom_field%TYPE;
	t_custom_field			T_SPLIT_TABLE;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		SELECT custom_field
		  INTO v_custom_field
		  FROM ind i
		  JOIN measure m on i.measure_sid = m.measure_sid
		 WHERE i.ind_sid = v_ind_sid;
		
		-- If checkbox insert Yes/No as we're displaying it as a combo instead.
		IF v_custom_field = 'x' THEN
			INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.value, o.description
			  FROM (
				SELECT 1 value, 'Yes' description FROM dual
				UNION ALL SELECT 0, 'No' FROM dual
			  ) o
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = o.value
			 );
		ELSE
			t_custom_field := utils_pkg.SplitString(v_custom_field, CHR(13)||CHR(10));
			
			FOR r IN (
				SELECT t.item, t.pos
				  FROM TABLE(t_custom_field) t
				 WHERE NOT EXISTS (
					 SELECT *
					  FROM chain.filter_value fv
					 WHERE fv.filter_field_id = in_filter_field_id
					   AND fv.num_value = t.pos
				)
			)
			LOOP
				INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
				VALUES (chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, r.pos, r.item);
			END LOOP;
		END IF;
	END IF;
	
	PopulateTempMeterDataIdRegion(in_ids);

	SELECT chain.T_FILTERED_OBJECT_ROW(x.meter_data_id, in_group_by_index, x.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT tr.meter_data_id, fv.filter_value_id
		  FROM region_metric_val rmv
		  JOIN (
				SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
				  FROM region_metric_val crmv	-- Current
				  JOIN temp_meter_data_id_region tr ON crmv.region_sid = tr.region_sid
				 WHERE crmv.ind_sid = v_ind_sid
				   AND crmv.effective_dtm <= SYSDATE
				 GROUP BY crmv.region_sid, crmv.ind_sid
			) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
		  JOIN temp_meter_data_id_region tr ON rmv.region_sid = tr.region_sid
		  JOIN chain.filter_value fv ON rmv.val = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id
	  ) x;
END;

PROCEDURE FilterRegionMetricNumber (
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER, 
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ind_sid				NUMBER;
BEGIN
	v_ind_sid := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
		
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	
	
	PopulateTempMeterDataIdRegion(in_ids);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(x.meter_data_id, in_group_by_index, x.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT tr.meter_data_id, fv.filter_value_id
		  FROM region_metric_val rmv
		  JOIN (
				SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
				  FROM region_metric_val crmv	-- Current
				  JOIN temp_meter_data_id_region tr ON crmv.region_sid = tr.region_sid
				 WHERE crmv.ind_sid = v_ind_sid
				   AND crmv.effective_dtm <= SYSDATE
				 GROUP BY crmv.region_sid, crmv.ind_sid
			) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
		  JOIN temp_meter_data_id_region tr ON rmv.region_sid = tr.region_sid
		  CROSS JOIN chain.filter_value fv
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND chain.filter_pkg.CheckNumberRange(rmv.val, fv.num_value, fv.min_num_val, fv.max_num_val) = 1
	  ) x;
END;

PROCEDURE FilterValue (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, mld.consumption, mld.consumption
		  FROM (
			  SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/DISTINCT consumption
				FROM meter_live_data mld
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.meter_data_id = t.object_id
		) mld
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = mld.consumption
		 );
	END IF;
	
	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t 
	    ON mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv 
	    ON fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(mld.consumption, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterMeterDataPriority (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- For now lets just put all values in. The data selection contains the logic to derive the calculated values based on priority
		-- In future we may generate a fake Priority ID here to represent the calculated values
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.id, dr.description
			  FROM (
				SELECT priority id, label description
				  FROM meter_data_priority
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) dr
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.id
			);
	END IF;

	-- Always order by priority
	INTERNAL_OrderFilterByNumValue(in_filter_field_id);

	SELECT /*+ USE_NL(t mld) INDEX(mld UK_METER_DATA_ID)*/chain.T_FILTERED_OBJECT_ROW(mld.meter_data_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM meter_live_data mld
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND mld.meter_data_id = t.object_id
	  JOIN chain.filter_value fv ON mld.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND fv.num_value = priority AND fv.filter_field_id = in_filter_field_id
	;

END;

PROCEDURE GetAggregateTypes(
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- base data, no security check required
	OPEN out_cur FOR
		SELECT meter_aggregate_type_id, meter_input_id, aggregator, analytic_function, description, accumulative
		  FROM meter_aggregate_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END; 

PROCEDURE SaveAggregateType(
	in_meter_aggregate_type_id		IN	NUMBER,
	in_analytic_function_enum		IN	NUMBER,
	in_meter_input_id				IN	NUMBER,
	in_meter_aggregator				IN	VARCHAR2,
	in_description					IN	VARCHAR2,
	in_accumulative					IN	NUMBER,
	out_meter_aggregate_type_id 	OUT	NUMBER
)
AS
	v_customer_aggregate_type_id	NUMBER;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit aggregate types');
	END IF;
	
	IF in_meter_aggregate_type_id IS NULL THEN
		INSERT INTO meter_aggregate_type(meter_aggregate_type_id, meter_input_id, aggregator, analytic_function, description, accumulative)
		VALUES (meter_aggregate_type_id_seq.NEXTVAL, in_meter_input_id, in_meter_aggregator, in_analytic_function_enum, in_description, in_accumulative)
		RETURNING meter_aggregate_type_id INTO out_meter_aggregate_type_id;
		
		v_customer_aggregate_type_id := chain.filter_pkg.UNSEC_AddCustomerAggregateType(
			in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_METER_DATA,
			in_meter_aggregate_type_id	=> out_meter_aggregate_type_id
		);
	ELSE
		out_meter_aggregate_type_id := in_meter_aggregate_type_id;
		UPDATE meter_aggregate_type
		   SET meter_input_id = in_meter_input_id,
		       aggregator = in_meter_aggregator,
		       analytic_function = in_analytic_function_enum,
		       description = in_description,
			   accumulative = in_accumulative
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_aggregate_type_id = in_meter_aggregate_type_id;
	END IF;
END;

PROCEDURE DeleteAggregateType(
	in_meter_aggregate_type_id		IN	NUMBER
)
AS
	v_customer_aggregate_type_id	NUMBER;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit aggregate types');
	END IF;
	
	SELECT customer_aggregate_type_id
	  INTO v_customer_aggregate_type_id
	  FROM chain.customer_aggregate_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_aggregate_type_id = in_meter_aggregate_type_id;
	
	chain.filter_pkg.UNSEC_RemoveCustomerAggType(v_customer_aggregate_type_id);

	DELETE FROM meter_aggregate_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_aggregate_type_id = in_meter_aggregate_type_id;
END;

PROCEDURE GetAllMeterTypeGroups(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		-- Hmm, not sure about this
		SELECT DISTINCT mi.group_key id, mi.group_key description
		  FROM meter_type mi
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND TRIM(group_key) IS NOT NULL;
END;

PROCEDURE GetDataYears(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_min_date		DATE;
	v_max_date		DATE;
BEGIN
	BEGIN
		SELECT min_start_date, max_start_date
		  INTO v_min_date, v_max_date
		  FROM meter_param_cache
		 WHERE app_sid = security.security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Min/max will default to current year, when the materialised view is empty 
			-- (REALLY extreme case when the meter_live_data is empty and there is still a fetch request to that model)
			v_min_date := SYSDATE; 
			v_max_date := v_min_date; 
	END;

	OPEN out_cur FOR
		SELECT yr id, yr description
		  FROM (
			SELECT TO_CHAR(v_min_date, 'YYYY') + LEVEL - 1 yr
			  FROM DUAL
				CONNECT BY LEVEL <= TO_CHAR(GREATEST(SYSDATE, v_max_date), 'YYYY') - TO_CHAR(v_min_date, 'YYYY') + 1
		);
END;

PROCEDURE GetYearDays(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	-- Pick a leap year to generate the days for (the year doesn't matter)
	v_max_date				DATE := TO_DATE('2012-01-01', 'YYYY-MM-DD');
	v_min_date				DATE := TO_DATE('2013-01-01', 'YYYY-MM-DD');
BEGIN
	OPEN out_cur FOR
		SELECT CAST (TO_CHAR(start_dtm, 'MMDD') AS NUMBER) id, LOWER(TO_CHAR(start_dtm, 'fmDDTH')) || ' ' || INITCAP(TO_CHAR(start_dtm, 'MON')) description
		  FROM (	
			SELECT LEVEL pos, TRUNC(v_min_date, 'DD') + LEVEL - 1 start_dtm
			 FROM DUAL
			CONNECT BY LEVEL <= TRUNC(v_max_date, 'DD') - TRUNC(v_min_date, 'DD')
		);
END;

PROCEDURE GetMeterDataPriorities(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Base data so no security required. Used in quick chart filters.
	OPEN out_cur FOR
		SELECT priority id, label description
		  FROM meter_data_priority
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY priority;
END;

END meter_report_pkg;
/
