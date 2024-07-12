CREATE OR REPLACE PACKAGE BODY CSR.meter_list_pkg
IS

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMeterNumber			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterExternalMeterId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMeterType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMeterTypeGroup		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSourceType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDisposalDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAcquisitionDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNote				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActive				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

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

PROCEDURE FilterMeterIds (
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
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, comparator, column_sid
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MeterNumber' THEN
			FilterMeterNumber(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ExternalMeterId' THEN
			FilterExternalMeterId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MeterType' THEN
			FilterMeterType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MeterTypeGroup' THEN
			FilterMeterTypeGroup(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'SourceType' THEN
			FilterSourceType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'DisposalDtm' THEN
			FilterDisposalDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AcquisitionDtm' THEN
			FilterAcquisitionDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Note' THEN
			FilterNote(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Active' THEN
			FilterActive(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'TagGroup.%' THEN
			FilterTag(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);		
		ELSIF r.name LIKE 'RegionMetricText.%' THEN
			region_metric_pkg.FilterRegionMetricText(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricDate.%' THEN
			region_metric_pkg.FilterRegionMetricDate(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricCombo.%' THEN
			region_metric_pkg.FilterRegionMetricCombo(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricNumber.%' THEN
			region_metric_pkg.FilterRegionMetricNumber(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'FilterPageIndInterval%' THEN
			-- Other modules would have to convert id->region sid call this proc, and convert back at this point,
			-- but we don't need to as the ids are already region sids in the metering module
			chain.filter_pkg.FilterInd(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
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
	chain.filter_pkg.RunCompoundFilter('FilterMeterIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types	IN	security.T_SID_TABLE,
	in_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, 
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END,
			CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN l.object_id
				ELSE tfiv.val_number
			END
	  FROM all_meter am
	  JOIN TABLE(in_id_list) l ON am.region_sid = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	  LEFT JOIN chain.customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id
	  LEFT JOIN chain.tt_filter_ind_val tfiv ON cuat.filter_page_ind_interval_id = tfiv.filter_page_ind_interval_id AND am.region_sid = tfiv.region_sid;
	  
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_has_regions					NUMBER;
	v_user_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','SID');
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_root_region_sids				security.T_SID_TABLE;
	v_selected_region_sids			security.T_SID_TABLE;
	v_num_root_region_sids			NUMBER;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.GetInitialIds');
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	
	-- Get the root region sid for the list (also checks permissions)
	meter_pkg.GetAndCheckRootRegionSids(v_act_id, NULL, v_user_sid, v_root_region_sids, v_num_root_region_sids);
	
	SELECT region_sid
	  BULK COLLECT INTO v_selected_region_sids
	  FROM (
		SELECT region_sid
		  FROM region
			-- this block won't run if it's empty which is what we want
			START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_region_sids))
			CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		UNION 
		SELECT region_sid -- use roles if no region sid provided
		  FROM role r
		  JOIN region_role_member rrm ON r.role_sid = rrm.role_sid
		 WHERE r.is_metering = 1
		   -- only return this roles chunk if we're not doing 'meters under region sid'
		   AND v_num_root_region_sids = 0
		   AND rrm.user_sid = v_user_sid
	) WHERE region_sid NOT IN (
		SELECT linked_meter_sid 
		  FROM linked_meter
	);
	 
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM all_meter am
	  JOIN TABLE(v_selected_region_sids) sr ON am.region_sid = sr.column_value	 
	  JOIN v$region r ON am.app_sid = r.app_sid AND am.region_sid = r.region_sid
	  JOIN meter_source_type st ON st.meter_source_type_id = am.meter_source_type_id  
	  JOIN meter_type mt ON mt.meter_type_id = am.meter_type_id  
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN am.region_sid END = tr.region_sid
	 WHERE st.show_in_meter_list = 1
	   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_search IS NULL
			OR UPPER(r.description) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(am.reference) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(am.urjanet_meter_id) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(r.lookup_key) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(r.region_ref) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(mt.label) LIKE '%'||UPPER(in_search)||'%'
			OR TO_CHAR(r.region_sid) = UPPER(in_search)
		);

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
	 
	out_id_list := v_id_list;

	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
END;

PROCEDURE ConvertIdsToRegionSids(
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_region_sids					OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	out_region_sids := in_id_list;
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
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_id_list_populated = 0 THEN
		-- Step 1, get initial set of ids
		GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_region_sids, in_start_dtm, in_end_dtm,
			in_region_col_type, in_date_col_type, in_id_list, out_id_list);
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(id, NULL, NULL)
		  BULK COLLECT INTO out_id_list
		  FROM chain.tt_filter_id;
	END IF;
	
	-- Step 2, If there's a filter, restrict the list of ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, out_id_list, out_id_list);
	END IF;
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.ApplyBreadcrumb');
	
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
	out_cur							OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_metrics_cur					OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_consumption_input_id			meter_input.meter_input_id%TYPE;
	v_cost_input_id					meter_input.meter_input_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.CollectSearchResults');
	
	BEGIN
		SELECT meter_input_id
		  INTO v_consumption_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'CONSUMPTION';
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	BEGIN
		SELECT meter_input_id
		  INTO v_cost_input_id
		  FROM meter_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lookup_key = 'COST';
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ am.region_sid, am.reference, am.note, r.active, am.urjanet_meter_id external_meter_id, 
		       r.description, rt.class_name, r.geo_latitude latitude, r.geo_longitude longitude,
		       mt.label meter_type, r.lookup_key region_lookup, r.region_ref region_reference,
			   r.acquisition_dtm installation_dtm, r.disposal_dtm, 
			   st.description reading_type, am.manual_data_entry,
			   mlc.last_reading_dtm, mlcu.full_name last_read_by,
			   mlc.val_number last_consumption_value, NVL(primc.description, prim.description) consumption_uom,
			   mlc.cost_number last_cost_value, NVL(cstmc.description, cstm.description) cost_uom,
			   CASE WHEN pr.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN pr.region_sid ELSE NULL END space_sid,
			   CASE WHEN pr.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN pr.description ELSE NULL END parent_space_description,
			   CASE WHEN pro.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN pro.region_sid ELSE NULL END property_sid,
			   CASE WHEN pro.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN pro.description ELSE NULL END parent_property_description
		  FROM all_meter am
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = am.region_sid
		  JOIN v$region r ON am.region_sid = r.region_sid
		  JOIN meter_type mt ON am.meter_type_id = mt.meter_type_id
		  JOIN region_type rt ON r.region_type = rt.region_type
		  JOIN meter_source_type st ON st.meter_source_type_id = am.meter_source_type_id
		  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = am.region_sid
		  LEFT JOIN csr_user mlcu ON mlc.read_by_sid = mlcu.csr_user_sid
		  LEFT JOIN meter_input_aggr_ind miai ON am.region_sid = miai.region_sid AND miai.meter_input_id = v_consumption_input_id 
		        AND am.meter_type_id = miai.meter_type_id AND miai.aggregator = 'SUM'
		  LEFT JOIN measure prim ON miai.measure_sid = prim.measure_sid 
		  LEFT JOIN measure_conversion primc ON miai.measure_conversion_id = primc.measure_conversion_id
		  LEFT JOIN meter_input_aggr_ind cmiai ON am.region_sid = cmiai.region_sid AND cmiai.meter_input_id = v_cost_input_id 
		        AND am.meter_type_id = cmiai.meter_type_id AND cmiai.aggregator = 'SUM'
		  LEFT JOIN measure cstm ON cmiai.measure_sid = cstm.measure_sid 
		  LEFT JOIN measure_conversion cstmc ON cmiai.measure_conversion_id = cstmc.measure_conversion_id
		  LEFT JOIN v$region pr ON r.app_sid = pr.app_sid AND r.parent_sid = pr.region_sid 
		  LEFT JOIN (
				 SELECT region_sid, description, region_type, CONNECT_BY_ROOT region_sid meter_region_sid
				   FROM v$region 
				  WHERE CONNECT_BY_ISLEAF = 1
				  START WITH region_sid IN (SELECT sid_id FROM TABLE(in_id_list))
				CONNECT BY PRIOR parent_sid = region_sid
					AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
			) pro ON am.region_sid = pro.meter_region_sid
		 ORDER BY fil_list.pos;
		 
	tag_pkg.UNSEC_GetRegionTags(in_id_list, out_tags_cur);	
	region_metric_pkg.UNSEC_GetMetricsForRegions(in_id_list, out_metrics_cur);
			
	OPEN out_inds_cur FOR
		SELECT ti.filter_page_ind_interval_id, ti.ind_sid, ti.region_sid, ti.period_start_dtm, ti.period_end_dtm, ti.val_number, ti.error_code, ti.note
		  FROM chain.tt_filter_ind_val ti
		  JOIN TABLE(in_id_list) t ON ti.region_sid = t.sid_id;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE PageFilteredIds (
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS	
	v_order_by						VARCHAR2(255);
	v_order_by_id	 				NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.PageFilteredIds');

	IF in_order_by = 'lastReadingDtm' THEN
		-- default query when you hit the page, use quick version
		-- without joins
		SELECT security.T_ORDERED_SID_ROW(region_sid, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.region_sid, ROWNUM rn
			  FROM (
				SELECT am.region_sid
				  FROM all_meter am
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = am.region_sid
				  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = am.region_sid
				 ORDER BY 
					CASE WHEN in_order_dir='ASC' THEN NVL2(mlc.last_reading_dtm, TO_CHAR(mlc.last_reading_dtm, 'YYYY-MM-DD HH24:MI:SS'), ' ') END ASC,
					CASE WHEN in_order_dir='DESC' OR in_order_dir IS NULL THEN NVL2(mlc.last_reading_dtm, TO_CHAR(mlc.last_reading_dtm, 'YYYY-MM-DD HH24:MI:SS'), ' ') END DESC,
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN am.region_sid END DESC,
					CASE WHEN in_order_dir='DESC' THEN am.region_sid END ASC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSIF in_order_by = 'parentPropertyDescription' THEN
		-- keep this order by separate, as its going to be slow
		SELECT security.T_ORDERED_SID_ROW(region_sid, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.region_sid, ROWNUM rn
			  FROM (
				SELECT am.region_sid
				  FROM all_meter am
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = am.region_sid
				  LEFT JOIN (
						 SELECT region_sid, description, region_type, CONNECT_BY_ROOT region_sid meter_region_sid
						   FROM v$region 
						  WHERE CONNECT_BY_ISLEAF = 1
						  START WITH region_sid IN (SELECT object_id FROM TABLE(in_id_list))
						CONNECT BY PRIOR parent_sid = region_sid
							AND PRIOR region_type != csr_data_pkg.REGION_TYPE_PROPERTY
				  ) pro ON am.region_sid = pro.meter_region_sid
				 ORDER BY 
					CASE WHEN in_order_dir='ASC' THEN CASE WHEN pro.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN LOWER(pro.description) ELSE NULL END END ASC,
					CASE WHEN in_order_dir='DESC' OR in_order_dir IS NULL THEN CASE WHEN pro.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN LOWER(pro.description) ELSE NULL END END DESC,
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN am.region_sid END DESC,
					CASE WHEN in_order_dir='DESC' THEN am.region_sid END ASC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
		
		SELECT security.T_ORDERED_SID_ROW(region_sid, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.region_sid, ROWNUM rn
				  FROM (
					SELECT am.region_sid
					  FROM all_meter am
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = am.region_sid
					  JOIN v$region r ON am.region_sid = r.region_sid
					  JOIN meter_type mt ON am.meter_type_id = mt.meter_type_id
					  JOIN meter_source_type st ON st.meter_source_type_id = am.meter_source_type_id
					  LEFT JOIN meter_list_cache mlc ON mlc.region_sid = am.region_sid
					  LEFT JOIN csr_user mlcu ON mlc.read_by_sid = mlcu.csr_user_sid
					  LEFT JOIN v$region pr ON r.app_sid = pr.app_sid AND r.parent_sid = pr.region_sid 
					  LEFT JOIN (
						SELECT ort.region_sid, ort.tag_group_id, stragg(ort.tag) tags
						  FROM (
							SELECT rt.region_sid, tgm.tag_group_id, t.tag
							  FROM region_tag rt
							  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
							  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) ort
						 GROUP BY ort.region_sid, ort.tag_group_id
						) rts ON am.region_sid = rts.region_sid
					  LEFT JOIN (
						SELECT rmv.region_sid, NVL(TO_CHAR(rmv.val, '000000000000000000000000.0000000000'), LOWER(rmv.note)) str_val
						  FROM region_metric_val rmv
					      JOIN (
							SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
							  FROM region_metric_val crmv	-- Current
							 WHERE crmv.effective_dtm <= SYSDATE
							   AND crmv.ind_sid = v_order_by_id
							 GROUP BY crmv.region_sid, crmv.ind_sid
							) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
					  ) rm ON am.region_sid = rm.region_sid
					  LEFT JOIN (
						SELECT fiv.region_sid, NVL(TO_CHAR(fiv.val_number, '000000000000000000000000.0000000000'), LOWER(fiv.note)) str_val
						  FROM chain.tt_filter_ind_val fiv
						 WHERE fiv.filter_page_ind_interval_id = v_order_by_id
					  ) im ON am.region_sid = im.region_sid
					 ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'regionSid' THEN TO_CHAR(am.region_sid, '0000000000')
									WHEN 'description' THEN LOWER(r.description)
									WHEN 'meterType' THEN LOWER(mt.label)
									WHEN 'note' THEN LOWER(am.note)
									WHEN 'active' THEN TO_CHAR(r.active)
									WHEN 'reference' THEN LOWER(am.reference)
									WHEN 'urjanetMeterId' THEN LOWER(am.urjanet_meter_id)
									WHEN 'regionLookup' THEN LOWER(r.lookup_key)
									WHEN 'regionReference' THEN LOWER(r.region_ref)
									WHEN 'parentSpaceDescription' THEN CASE WHEN pr.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN LOWER(pr.description) ELSE NULL END
									WHEN 'lastConsumptionValue' THEN NVL2(mlc.val_number, TO_CHAR(mlc.val_number, '000000000000000.00000'), ' ')
									WHEN 'lastCostValue' THEN NVL2(mlc.cost_number, TO_CHAR(mlc.cost_number, '000000000000000.00000'), ' ')
									WHEN 'lastReadingDtm' THEN NVL2(mlc.last_reading_dtm, TO_CHAR(mlc.last_reading_dtm, 'YYYY-MM-DD HH24:MI:SS'), ' ')
									WHEN 'lastReadBy' THEN LOWER(mlcu.full_name)
									WHEN 'sourceType' THEN LOWER(st.description)
									WHEN 'disposalDtm' THEN TO_CHAR(r.disposal_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'installationDtm' THEN TO_CHAR(r.acquisition_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tagGroup' THEN TO_CHAR(rts.tags)
									WHEN 'metric' THEN NVL(rm.str_val, ' ') -- treat nulls as something less than zero
									WHEN 'ind' THEN NVL(im.str_val, ' ') -- treat nulls as something less than zero
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'regionSid' THEN TO_CHAR(am.region_sid, '0000000000')
									WHEN 'description' THEN LOWER(r.description)
									WHEN 'meterType' THEN LOWER(mt.label)
									WHEN 'note' THEN LOWER(am.note)
									WHEN 'active' THEN TO_CHAR(r.active)
									WHEN 'reference' THEN LOWER(am.reference)
									WHEN 'urjanetMeterId' THEN LOWER(am.urjanet_meter_id)
									WHEN 'regionLookup' THEN LOWER(r.lookup_key)
									WHEN 'regionReference' THEN LOWER(r.region_ref)
									WHEN 'parentSpaceDescription' THEN CASE WHEN pr.region_type = csr_data_pkg.REGION_TYPE_SPACE THEN LOWER(pr.description) ELSE NULL END
									WHEN 'lastConsumptionValue' THEN NVL2(mlc.val_number, TO_CHAR(mlc.val_number, '000000000000000.00000'), ' ')
									WHEN 'lastCostValue' THEN NVL2(mlc.cost_number, TO_CHAR(mlc.cost_number, '000000000000000.00000'), ' ')
									WHEN 'lastReadingDtm' THEN NVL2(mlc.last_reading_dtm, TO_CHAR(mlc.last_reading_dtm, 'YYYY-MM-DD HH24:MI:SS'), ' ')
									WHEN 'lastReadBy' THEN LOWER(mlcu.full_name)
									WHEN 'sourceType' THEN LOWER(st.description)
									WHEN 'disposalDtm' THEN TO_CHAR(r.disposal_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'installationDtm' THEN TO_CHAR(r.acquisition_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tagGroup' THEN TO_CHAR(rts.tags)
									WHEN 'metric' THEN NVL(rm.str_val, ' ') -- treat nulls as something less than zero
									WHEN 'ind' THEN NVL(im.str_val, ' ') -- treat nulls as something less than zero
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN am.region_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN am.region_sid END ASC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_METERS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Meter -> '||v_name);

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
	out_cur							OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_metrics_cur					OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
	v_geo_filtered_list				chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.GetMeterList', in_compound_filter_id);
	
	v_user_sid := security_pkg.GetSID;
	
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
	
	-- Filter by map bounds if appropriate
	IF in_bounds_north IS NOT NULL AND in_bounds_east IS NOT NULL AND in_bounds_south IS NOT NULL AND in_bounds_west IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, NULL, NULL)
		  BULK COLLECT INTO v_geo_filtered_list
		  FROM region r
		  JOIN TABLE(v_id_list) t ON r.region_sid = t.object_id
		 WHERE r.geo_longitude-in_bounds_west-360*FLOOR((r.geo_longitude-in_bounds_west)/360) BETWEEN 0 AND in_bounds_east-in_bounds_west
		   AND r.geo_latitude BETWEEN in_bounds_south AND in_bounds_north;

		v_id_list := v_geo_filtered_list;
	END IF;
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);
	
	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_tags_cur, out_metrics_cur, out_inds_cur);
	
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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_METERS, a.aggregate_type_id, a.description, a.format_mask,
		   a.filter_page_ind_interval_id, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM (
		SELECT at.aggregate_type_id, at.description, null format_mask, null filter_page_ind_interval_id, NVL(sat.pos, at.aggregate_type_id) pos
		  FROM chain.aggregate_type at
		  JOIN TABLE(in_aggregation_types) sat ON at.aggregate_type_id = sat.sid_id
		 WHERE at.card_group_id = chain.filter_pkg.FILTER_TYPE_METERS
		 UNION
		SELECT cuat.customer_aggregate_type_id, fi.description, NVL(fi.format_mask, fm.format_mask), fpii.filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN chain.filter_page_ind_interval fpii ON cuat.filter_page_ind_interval_id = fpii.filter_page_ind_interval_id
		  JOIN chain.filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id
		  JOIN v$ind fi ON fpi.app_sid = fi.app_sid AND fpi.ind_sid = fi.ind_sid
		  JOIN measure fm ON fi.measure_sid = fm.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_METERS
		) a
	 ORDER BY a.pos, a.description, a.filter_page_ind_interval_id;
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
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> in_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		in_id_list_populated	=> in_id_list_populated,
		out_id_list				=> v_id_list
	);
	
	IF in_grp_by_compound_filter_id IS NOT NULL THEN
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_METERS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
	chain.filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);
	
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
	out_cur							OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_metrics_cur					OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN	
	GetFilteredIds(
		in_search				=> in_search,
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
	
	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);

	INTERNAL_PopGridExtTempTable(v_id_page);
	
	CollectSearchResults(v_id_page, out_cur, out_tags_cur, out_metrics_cur, out_inds_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_metrics_cur					OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.meter_list_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_METERS
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
		out_cur 					=> out_cur,
		out_tags_cur				=> out_tags_cur,
		out_metrics_cur				=> out_metrics_cur,
		out_inds_cur				=> out_inds_cur
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetMeterAndReadingExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
	v_ids							security.T_SID_TABLE;
	v_ordererd_id_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN	

	GetFilteredIds(
		in_search				=> in_search,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_breadcrumb, NULL, v_id_list);
	
	SELECT object_id
	  BULK COLLECT INTO v_ids
	  FROM TABLE(v_id_list);
	  
	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_ordererd_id_list
	  FROM TABLE(v_id_list);
	
	meter_pkg.GetFullMeterListForExport(v_ids, out_cur);
	tag_pkg.UNSEC_GetRegionTags(v_ordererd_id_list, out_tags_cur);
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
			SELECT am.region_sid
			  FROM all_meter am
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
			 WHERE am.region_sid IS NOT NULL
			 GROUP BY am.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, am.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT am.region_sid, fv.filter_value_id
			  FROM all_meter am
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
			  JOIN chain.filter_value fv ON am.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) am;
	ELSE
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM all_meter am
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
		  JOIN (
				SELECT r.region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON am.region_sid = r.region_sid;				 
	END IF;	
END;

PROCEDURE FilterMeterNumber (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM all_meter am
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(am.reference) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterExternalMeterId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM all_meter am
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(am.urjanet_meter_id) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;	
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
	
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM all_meter am
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = am.meter_type_id AND fv.filter_Field_id = in_filter_field_id
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
	
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM all_meter am
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
	  JOIN meter_type mi ON mi.app_sid = am.app_sid AND mi.meter_type_id = am.meter_type_id
	  JOIN chain.filter_value fv ON fv.str_value = mi.group_key AND fv.filter_Field_id = in_filter_field_id
	 ;
END;

PROCEDURE FilterSourceType (
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
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.meter_source_type_id, dr.description
			  FROM (
			  	SELECT DISTINCT mst.meter_source_type_id, mst.description
				  FROM meter_source_type mst
				 WHERE mst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) dr
			WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = dr.meter_source_type_id
			);
	END IF;

	-- Always order by description
	INTERNAL_OrderFilterByDesc(in_filter_field_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM all_meter am
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
	  JOIN meter_source_type mst ON mst.app_sid = am.app_sid AND mst.meter_source_type_id = am.meter_source_type_id
	  JOIN chain.filter_value fv ON fv.num_value = mst.meter_source_type_id AND fv.filter_field_id = in_filter_field_id
	 ;
END;

PROCEDURE FilterDisposalDtm (
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
		SELECT MIN(r.disposal_dtm), MAX(r.disposal_dtm)
		  INTO v_min_date, v_max_date
		  FROM all_meter am
		  JOIN region r ON am.app_sid = r.app_sid AND am.region_sid = r.region_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			r.disposal_dtm  IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			r.disposal_dtm  IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			r.disposal_dtm  IS NOT NULL AND
			r.disposal_dtm  >= NVL(dr.start_dtm, r.disposal_dtm) AND 
			(dr.end_dtm IS NULL OR r.disposal_dtm  < dr.end_dtm));
END;

PROCEDURE FilterAcquisitionDtm (
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
		SELECT MIN(r.acquisition_dtm), MAX(r.acquisition_dtm)
		  INTO v_min_date, v_max_date
		  FROM all_meter am
		  JOIN region r ON am.app_sid = r.app_sid AND am.region_sid = r.region_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			r.acquisition_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			r.acquisition_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			r.acquisition_dtm IS NOT NULL AND
			r.acquisition_dtm >= NVL(dr.start_dtm, r.acquisition_dtm) AND 
			(dr.end_dtm IS NULL OR r.acquisition_dtm < dr.end_dtm));
END;

PROCEDURE FilterNote (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(am.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM all_meter am
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON am.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(am.note) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterActive (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.active, o.description
		  FROM (
			SELECT 1 active, 'Active' description FROM dual
			UNION ALL SELECT 0, 'Inactive' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.active
		 );
		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = num_value
	 WHERE filter_field_id = in_filter_field_id;

	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = r.active
	 WHERE fv.filter_field_id = in_filter_field_id;
	
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
	v_tag_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	IF in_show_all = 1 THEN
		chain.filter_pkg.ShowAllTags(in_filter_field_id, v_tag_group_id);
	END IF;

	WITH group_tags AS (
		SELECT rt.app_sid, rt.region_sid, rt.tag_id
		  FROM region_tag rt
		  JOIN tag_group_member tgm ON tgm.app_sid = rt.app_sid AND tgm.tag_id = rt.tag_id
		 WHERE tgm.tag_group_id = v_tag_group_id)
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(r.app_sid, r.region_sid) NOT IN (SELECT app_sid, region_sid FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(r.app_sid, r.region_sid) IN (
				SELECT app_sid, region_sid
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
END;

END meter_list_pkg;
/
