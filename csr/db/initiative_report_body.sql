CREATE OR REPLACE PACKAGE BODY CSR.initiative_report_pkg
IS

-- private field filter units
PROCEDURE FilterFlowStateId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProjectSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRagStatusId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionRef			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProjectStartDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProjectEndDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInitiativeSid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_over_time_filter_field_id IN chain.filter_field.filter_field_id%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMetricOverTime		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterUserGroup			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionTag			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMetricNumber		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

FUNCTION GetOverTimeFilterFieldId (
	in_compound_filter_id			IN  chain.compound_filter.compound_filter_id%TYPE,
	in_max_group_by					IN  NUMBER
) RETURN chain.filter_field.filter_field_id%TYPE
AS
	v_over_time_filter_field_id		chain.filter_field.filter_field_id%TYPE;
BEGIN
	BEGIN
		SELECT filter_field_id
		  INTO v_over_time_filter_field_id
		  FROM chain.v$filter_field
		 WHERE compound_filter_id = in_compound_filter_id
		   AND name = 'MetricOverTime'
		   AND group_by_index <= in_max_group_by;
	EXCEPTION
		WHEN no_data_found THEN
			v_over_time_filter_field_id := NULL;
	END;
	
	RETURN v_over_time_filter_field_id;
END;

PROCEDURE FilterInitiativeIds (
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
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.FilterInitiativeIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.FilterInitiativeIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'FlowStateId' THEN
			FilterFlowStateId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ProjectSid' THEN
			FilterProjectSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RagStatusId' THEN
			FilterRagStatusId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RegionReference' THEN
			FilterRegionRef(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ProjectStartDtm' THEN
			FilterProjectStartDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ProjectEndDtm' THEN
			FilterProjectEndDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CreatedDtm' THEN
			FilterCreatedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InitiativeSid' THEN
			FilterInitiativeSid(in_filter_id, r.filter_field_id, GetOverTimeFilterFieldId(r.compound_filter_id, in_max_group_by), r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MetricOverTime' THEN
			FilterMetricOverTime(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'UserGroup.%' THEN
			FilterUserGroup(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'TagGroup.%' THEN
			FilterTag(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionTagGroup.%' THEN
			FilterRegionTag(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'MetricNumber.%' THEN
			FilterMetricNumber(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
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
	v_starting_sids		chain.T_FILTERED_OBJECT_TABLE;
	v_result_sids		chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.RunCompoundFilter');
	
	v_starting_sids := in_id_list;

	IF in_parallel = 0 THEN
		out_id_list := in_id_list;
	ELSE
		out_id_list := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	chain.filter_pkg.CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);	
	chain.filter_pkg.CheckCompoundFilterForCycles(in_compound_filter_id);
		
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM chain.filter f
		  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterInitiativeIds(:filter_id, :parallel, :max_group_by, :input, :output);END;') 
		USING r.filter_id, in_parallel, in_max_group_by, v_starting_sids, OUT v_result_sids;
		
		IF in_parallel = 0 THEN
			v_starting_sids := v_result_sids;
			out_id_list := v_result_sids;
		ELSE
			out_id_list := out_id_list MULTISET UNION v_result_sids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilterObjectData (
	in_over_time_filter_field_id	IN  chain.filter_field.filter_field_id%TYPE,
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	IF in_over_time_filter_field_id IS NOT NULL THEN	
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number, filter_value_id)
		SELECT a.column_value, l.object_id, chain.filter_pkg.AFUNC_SUM, SUM(o.val_number), fv.filter_value_id
		  FROM initiative i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON i.initiative_sid = l.object_id
		 CROSS JOIN TABLE(in_aggregation_types) a
		  LEFT JOIN chain.customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id
		  JOIN temp_initiative_aggr_val o ON l.object_id = o.initiative_sid AND o.initiative_metric_id = cuat.initiative_metric_id
		  JOIN chain.filter_value fv ON fv.start_dtm_value <= o.start_dtm  AND fv.end_dtm_value >= o.end_dtm
		 WHERE fv.filter_field_id = in_over_time_filter_field_id
		 GROUP BY a.column_value, l.object_id, chain.filter_pkg.AFUNC_SUM, fv.filter_value_id;
	ELSE
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT a.column_value, l.object_id, 
			   CASE a.column_value
					WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
					ELSE chain.filter_pkg.AFUNC_SUM
				END,
				CASE a.column_value
					WHEN AGG_TYPE_COUNT THEN l.object_id
					ELSE imv.val
				END
		  FROM initiative i
		  JOIN TABLE(in_id_list) l ON i.initiative_sid = l.object_id
		 CROSS JOIN TABLE(in_aggregation_types) a
		  LEFT JOIN chain.customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id
		  LEFT JOIN initiative_metric_val imv ON i.app_sid = imv.app_sid AND i.initiative_sid = imv.initiative_sid AND imv.initiative_metric_id = cuat.initiative_metric_id;
	END IF;
	
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
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.GetFilteredIds', in_compound_filter_id);
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	
	-- start with the list they have access to
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT if.app_sid, if.initiative_sid, if.project_sid, if.name, if.internal_ref, if.current_state_id
		  FROM (
			-- subquery to force oracle to pick a sane plan
			SELECT i.app_sid, i.initiative_sid, ir.region_sid, i.project_sid, i.name, i.internal_ref, fi.current_state_id
			  FROM initiative i 
			  JOIN initiative_region ir ON i.app_sid = ir.app_sid AND i.initiative_sid = ir.initiative_sid
			  JOIN flow_item fi ON i.app_sid = fi.app_sid AND i.flow_item_id = fi.flow_item_id
			 WHERE ROWNUM > 0 -- materialize sub-query
		  ) if
		  JOIN flow_state_role fsr ON if.app_sid = fsr.app_sid AND if.current_state_id = fsr.flow_state_id		
		  JOIN region_role_member rrm ON rrm.app_sid = if.app_sid AND (rrm.user_sid = SYS_CONTEXT('SECURITY','SID') OR SYS_CONTEXT('SECURITY', 'SID') = security_pkg.SID_BUILTIN_ADMINISTRATOR) AND rrm.region_sid = if.region_sid AND rrm.role_sid = fsr.role_sid
		 UNION ALL
		SELECT i.app_sid, i.initiative_sid, i.project_sid, i.name, i.internal_ref, fi.current_state_id
		  FROM initiative i 
		  JOIN initiative_user iu ON i.app_sid = iu.app_sid AND i.initiative_sid = iu.initiative_sid
		  JOIN flow_item fi ON i.app_sid = fi.app_sid AND i.flow_item_id = fi.flow_item_id
		  JOIN initiative_project_user_group ipug ON iu.initiative_user_group_id = ipug.initiative_user_group_id AND iu.project_sid = ipug.project_sid
		  JOIN initiative_group_flow_state igfs  ON ipug.initiative_user_group_id = igfs.initiative_user_group_id AND ipug.project_sid = igfs.project_sid AND fi.current_state_id = igfs.flow_state_id AND fi.flow_sid = igfs.flow_sid
   		 WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID') OR SYS_CONTEXT('SECURITY', 'SID') = security_pkg.SID_BUILTIN_ADMINISTRATOR		 
	    ) i
	  JOIN initiative_project ip ON i.app_sid = ip.app_sid AND i.project_sid = ip.project_sid
	  JOIN initiative_region ir ON i.app_sid = ir.app_sid AND i.initiative_sid = ir.initiative_sid
	  JOIN flow_state fs ON i.app_sid = fs.app_sid AND i.current_state_id = fs.flow_state_id
	  JOIN v$region r ON ir.app_sid = r.app_sid AND ir.region_sid = r.region_sid
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN ir.region_sid END = tr.region_sid
	 WHERE (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_search IS NULL 
		-- XXX Should probably switch to text indexes...
		OR UPPER(fs.label) LIKE '%'||UPPER(in_search)||'%'
		OR UPPER(i.name) LIKE '%'||UPPER(in_search)||'%'
		OR UPPER(i.internal_ref) LIKE '%'||UPPER(in_search)||'%'
		OR UPPER(ip.name) LIKE '%'||UPPER(in_search)||'%'
		OR TO_CHAR(i.initiative_sid) = UPPER(in_search)
		OR UPPER(r.description) LIKE '%'||UPPER(in_search)||'%'
		)
	 GROUP BY i.initiative_sid;

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
	v_over_time_filter_field_id		chain.filter_field.filter_field_id%TYPE;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.ApplyBreadcrumb');
	
	out_id_list := in_id_list;
	
	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;
	
	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := chain.filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);		
		v_over_time_filter_field_id := GetOverTimeFilterFieldId(v_field_compound_filter_id, v_breadcrumb_count);
		
		-- Use the aggregation type for drilldowns on "other"
		-- If not supplied, use count
		SELECT NVL(in_aggregation_type, 1) BULK COLLECT INTO v_aggregation_types FROM dual;
		
		-- setup temp aggregated data, used by initiative breakdown over time 
		IF v_over_time_filter_field_id IS NOT NULL THEN
			DELETE FROM temp_initiative_metric_ids;			
			INSERT INTO temp_initiative_metric_ids (initiative_metric_id)
			SELECT initiative_metric_id
			  FROM initiative_metric
			 WHERE is_running=1;
				   
			DELETE FROM temp_initiative_sids;				
			INSERT INTO temp_initiative_sids (initiative_sid)
			SELECT DISTINCT object_id FROM TABLE(in_id_list);

			initiative_aggr_pkg.INTERNAL_PrepAggrData;
		END IF;
	
		RunCompoundFilter(v_field_compound_filter_id, 1, v_breadcrumb_count, out_id_list, out_id_list);

		-- check if any breadcrumb elements are on "other". If not, we don't need to do a top N		
		IF in_breadcrumb(1) < 0 OR
			(v_breadcrumb_count > 1 AND in_breadcrumb(2) < 0) OR
			(v_breadcrumb_count > 2 AND in_breadcrumb(3) < 0) OR
			(v_breadcrumb_count > 3 AND in_breadcrumb(4) < 0)
		THEN			
			GetFilterObjectData (v_over_time_filter_field_id, v_aggregation_types, out_id_list);
			
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
	out_cur 						OUT  SYS_REFCURSOR,
	out_regions 					OUT  SYS_REFCURSOR,
	out_tags						OUT  SYS_REFCURSOR,
	out_users						OUT  SYS_REFCURSOR,
	out_metrics 					OUT  SYS_REFCURSOR,
	out_region_tags					OUT  SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.CollectSearchResults');
	
	INSERT INTO temp_initiative (initiative_sid, flow_state_id, flow_state_label, flow_state_lookup_key, 
	                             flow_state_colour, flow_state_pos, active, is_editable, pos)
		SELECT i.initiative_sid, fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key,
			   fs.state_colour flow_state_colour, fs.pos flow_state_pos, 0, 0, fil_list.pos
	      FROM initiative i 
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = i.initiative_sid
		  JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
		 GROUP BY i.initiative_sid, fs.flow_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos, fil_list.pos;
	
	csr.initiative_grid_pkg.INTERNAL_GetMyInitiatives(
		out_cur 		=> out_cur,
		out_regions 	=> out_regions,
		out_tags		=> out_tags,
		out_users		=> out_users,
		out_metrics 	=> out_metrics
	);
	
	OPEN out_region_tags FOR
		SELECT ti.initiative_sid, ir.region_sid, t.tag_id, t.tag
		  FROM temp_initiative ti
		  JOIN initiative_region ir ON ti.initiative_sid = ir.initiative_sid
		  JOIN region_tag rt ON ir.region_sid = rt.region_sid AND ir.app_sid = rt.app_sid
		  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
		  JOIN v$tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
		 ORDER BY tgm.tag_group_id, tgm.pos;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PrepExportViewFilter(
	in_search						IN	VARCHAR2,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_region_col_type				IN	NUMBER,
	in_date_col_type				IN	NUMBER
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
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
	
	DELETE FROM temp_initiative_sids;
	INSERT INTO temp_initiative_sids (initiative_sid)
		 SELECT object_id
		  FROM TABLE(v_id_list);
END;

PROCEDURE PageFilteredInitiativeIds (
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.PageFilteredInitiativeIds');	

	IF in_order_by = 'initiativeSid' AND in_order_by = 'DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.object_id, ROWNUM rn
			  FROM (
				SELECT fil_list.object_id
				  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list
				 ORDER BY fil_list.object_id DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
		
		SELECT security.T_ORDERED_SID_ROW(initiative_sid, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.initiative_sid, ROWNUM rn
				  FROM (
					SELECT i.initiative_sid
					  FROM initiative i
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = i.initiative_sid					  
					  JOIN initiative_project ip ON i.app_sid = ip.app_sid AND i.project_sid = ip.project_sid
					  JOIN flow_item fi ON i.app_sid = fi.app_sid AND i.flow_item_id = fi.flow_item_id
					  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
					  LEFT JOIN (
						SELECT oit.initiative_sid, oit.tag_group_id, stragg(oit.tag) tags
						  FROM (
							SELECT it.initiative_sid, tgm.tag_group_id, t.tag
							  FROM initiative_tag it
							  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) frl ON frl.object_id = it.initiative_sid	
							  JOIN tag_group_member tgm ON it.tag_id = tgm.tag_id AND it.app_sid = tgm.app_sid
							  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) oit
						 GROUP BY oit.initiative_sid, oit.tag_group_id
						) its ON i.initiative_sid = its.initiative_sid
					  LEFT JOIN (
						SELECT oirt.initiative_sid, oirt.tag_group_id, stragg(oirt.tag) tags
						  FROM (
							SELECT ir.initiative_sid, tgm.tag_group_id, t.tag
							  FROM initiative_region ir 
							  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) frl ON frl.object_id = ir.initiative_sid	
							  JOIN region_tag rt ON ir.region_sid = rt.region_sid AND ir.app_sid = rt.app_sid
							  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
							  JOIN v$tag t ON rt.tag_id = t.tag_id AND rt.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) oirt
						 GROUP BY oirt.initiative_sid, oirt.tag_group_id
						) irts ON i.initiative_sid = irts.initiative_sid
					  LEFT JOIN (
						SELECT oir.initiative_sid, stragg(oir.description) regions, stragg(oir.region_ref) region_refs
						  FROM (
							SELECT ir.initiative_sid, r.description, r.region_ref
							  FROM initiative_region ir
							  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) frl ON frl.object_id = ir.initiative_sid	
							  JOIN v$region r ON ir.app_sid = r.app_sid AND ir.region_sid = r.region_sid
							 ORDER BY ir.initiative_sid, r.description
						  ) oir
						 GROUP BY oir.initiative_sid
						) irs ON i.initiative_sid = irs.initiative_sid
					  LEFT JOIN initiative_metric_val im ON i.app_sid = im.app_sid AND i.initiative_sid = im.initiative_sid AND im.initiative_metric_id = v_order_by_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'name' THEN LOWER(i.name)
									WHEN 'projectName' THEN LOWER(ip.name)
									WHEN 'ragStatusLabel' THEN TO_CHAR(i.rag_status_id, '0000000000')
									WHEN 'tagGroup' THEN LOWER(its.tags)
									WHEN 'regionTagGroup' THEN LOWER(irts.tags)
									WHEN 'regions' THEN LOWER(irs.regions)
									WHEN 'regionReferences' THEN LOWER(irs.region_refs)
									WHEN 'internalRef' THEN LOWER(i.internal_ref)
									WHEN 'projectStartDtm' THEN TO_CHAR(i.project_start_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'projectEndDtm' THEN TO_CHAR(i.project_end_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdDtm' THEN TO_CHAR(i.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'flowStateLabel' THEN LOWER(fs.label)
									WHEN 'metric' THEN NVL2(im.val, TO_CHAR(im.val, '0000000000'), ' ') -- treat nulls as something less than zero
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'name' THEN LOWER(i.name)
									WHEN 'projectName' THEN LOWER(ip.name)
									WHEN 'ragStatusLabel' THEN TO_CHAR(i.rag_status_id, '0000000000')
									WHEN 'tagGroup' THEN LOWER(its.tags)
									WHEN 'regionTagGroup' THEN LOWER(irts.tags)
									WHEN 'regions' THEN LOWER(irs.regions)
									WHEN 'regionReferences' THEN LOWER(irs.region_refs)
									WHEN 'internalRef' THEN LOWER(i.internal_ref)
									WHEN 'projectStartDtm' THEN TO_CHAR(i.project_start_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'projectEndDtm' THEN TO_CHAR(i.project_end_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdDtm' THEN TO_CHAR(i.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'flowStateLabel' THEN LOWER(fs.label)
									WHEN 'metric' THEN NVL2(im.val, TO_CHAR(im.val, '0000000000'), ' ')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN i.initiative_sid END ASC,
							CASE WHEN in_order_dir='DESC' THEN i.initiative_sid END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_INITIATIVES, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Initiative -> '||v_name);

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
	out_cur 						OUT  SYS_REFCURSOR,
	out_regions 					OUT  SYS_REFCURSOR,
	out_tags						OUT  SYS_REFCURSOR,
	out_users						OUT  SYS_REFCURSOR,
	out_metrics 					OUT  SYS_REFCURSOR,
	out_region_tags					OUT  SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.GetInitiativeList', in_compound_filter_id);
	
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
	
	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);
	
	PageFilteredInitiativeIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_regions, out_tags, out_users, out_metrics, out_region_tags);
	
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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_INITIATIVES, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_INITIATIVES
		 UNION
		SELECT cuat.customer_aggregate_type_id, im.label
		  FROM chain.customer_aggregate_type cuat
		  JOIN initiative_metric im ON cuat.initiative_metric_id = im.initiative_metric_id
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
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_over_time_filter_field_id		chain.filter_field.filter_field_id%TYPE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.GetReportData', in_compound_filter_id);
	
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
		out_id_list				=> v_id_list
	);
		
	v_over_time_filter_field_id := GetOverTimeFilterFieldId(in_grp_by_compound_filter_id, in_max_group_by);
	
	IF in_grp_by_compound_filter_id IS NOT NULL THEN
		-- setup temp aggregated data, used by initiative breakdown over time 
		IF v_over_time_filter_field_id IS NOT NULL THEN
			DELETE FROM temp_initiative_metric_ids;			
			INSERT INTO temp_initiative_metric_ids (initiative_metric_id)
				 SELECT cuat.initiative_metric_id
				   FROM TABLE(in_aggregation_types) a
				   JOIN chain.customer_aggregate_type cuat on a.column_value = cuat.customer_aggregate_type_id;	
				   
			DELETE FROM temp_initiative_sids;				
			INSERT INTO temp_initiative_sids (initiative_sid)
			SELECT DISTINCT object_id FROM TABLE(v_id_list);

			initiative_aggr_pkg.INTERNAL_PrepAggrData;
		END IF;
	
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;
	
	GetFilterObjectData(v_over_time_filter_field_id, in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_INITIATIVES, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
	chain.filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_create_page_url				VARCHAR2(255) := initiative_pkg.GetCreatePageUrl;
	v_edit_page_url					VARCHAR2(280);
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	IF v_create_page_url LIKE '%?%' THEN
		v_edit_page_url := v_create_page_url||'&'||'initiativesid=';
	ELSE
		v_edit_page_url := v_create_page_url||'?initiativesid=';
	END IF;
	
	OPEN out_cur FOR
		SELECT i.initiative_sid object_id, i.initiative_sid, i.name, i.internal_ref ref, i.project_start_dtm, i.project_end_dtm,
			   i.running_start_dtm, i.running_end_dtm, ist.label saving_type, ir.regions, v_edit_page_url||i.initiative_sid initiative_link
		  FROM initiative i		  
		  JOIN TABLE(in_id_list) fil_list ON fil_list.object_id = i.initiative_sid
		  JOIN initiative_saving_type ist ON i.saving_type_id = ist.saving_type_id
		  LEFT JOIN (
			SELECT oir.initiative_sid, stragg(oir.description) regions
			  FROM (
				SELECT ir.initiative_sid, r.description
				  FROM initiative_region ir
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) frl ON frl.object_id = ir.initiative_sid	
				  JOIN v$region r ON ir.app_sid = r.app_sid AND ir.region_sid = r.region_sid
				 ORDER BY ir.initiative_sid, r.description
			  ) oir
			 GROUP BY oir.initiative_sid
			) ir ON i.initiative_sid = ir.initiative_sid;
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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_regions						OUT	security_pkg.T_OUTPUT_CUR,
	out_tags						OUT security_pkg.T_OUTPUT_CUR,
	out_users						OUT security_pkg.T_OUTPUT_CUR,
	out_metrics						OUT security_pkg.T_OUTPUT_CUR,
	out_region_tags					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	GetFilteredIds(
		in_search					=> in_search,
		in_pre_filter_sid			=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id		=> in_compound_filter_id,
		in_region_sids				=> v_region_sids,
		in_start_dtm				=> in_start_dtm,
		in_end_dtm					=> in_end_dtm,
		in_region_col_type			=> in_region_col_type,
		in_date_col_type			=> in_date_col_type,
		out_id_list					=> v_id_list
	);
	
	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);
	
	SELECT security.T_ORDERED_SID_ROW(object_id, rownum)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	);

	INTERNAL_PopGridExtTempTable(v_id_page);
	
	CollectSearchResults(
		in_id_list					=> v_id_page,
		out_cur 					=> out_cur,
		out_regions 				=> out_regions,
		out_tags					=> out_tags,
		out_users					=> out_users,
		out_metrics 				=> out_metrics,
		out_region_tags				=> out_region_tags
	);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_regions						OUT	security_pkg.T_OUTPUT_CUR,
	out_tags						OUT security_pkg.T_OUTPUT_CUR,
	out_users						OUT security_pkg.T_OUTPUT_CUR,
	out_metrics						OUT security_pkg.T_OUTPUT_CUR,
	out_region_tags					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.initiative_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_INITIATIVES
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
		out_regions 				=> out_regions,
		out_tags					=> out_tags,
		out_users					=> out_users,
		out_metrics 				=> out_metrics,
		out_region_tags				=> out_region_tags
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
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
PROCEDURE FilterFlowStateId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_flow_count					NUMBER;
BEGIN
	IF in_show_all = 1 THEN
		SELECT COUNT(DISTINCT flow_sid)
		  INTO v_flow_count
		  FROM initiative_project;
	
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, f.flow_state_id, 
		       CASE WHEN v_flow_count = 1 THEN f.label ELSE f.flow_label||' - '||f.label END
		  FROM (
			SELECT fs.flow_state_id, f.label flow_label, fs.label
			  FROM initiative_project ip
			  JOIN flow_state fs ON ip.flow_sid = fs.flow_sid
			  JOIN flow f ON ip.flow_sid = f.flow_sid
			 WHERE ip.app_sid = SYS_CONTEXT('SECURITY','APP')
			   AND fs.is_deleted = 0
			 GROUP BY fs.flow_state_id, f.label, fs.label
			) f
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = f.flow_state_id
		 );		
	END IF;
	
	chain.filter_pkg.SortFlowStateValues(in_filter_field_id);
	chain.filter_pkg.SetFlowStateColours(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id
	  JOIN chain.filter_value fv ON fi.current_state_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

PROCEDURE FilterProjectSid(
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, ip.project_sid, ip.name
		  FROM initiative_project ip
		 WHERE security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), ip.project_sid, security_pkg.PERMISSION_READ) = 1
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = ip.project_sid
		 );		
	END IF;
	
	FOR r IN (
		SELECT * FROM (
			SELECT filter_value_id, pos, ROWNUM rn
			  FROM (
				SELECT fv.filter_value_id, MIN(fv.pos) pos
				  FROM chain.filter_value fv
				  JOIN initiative_project ip ON fv.num_value = ip.project_sid
				 WHERE fv.filter_field_id = in_filter_field_id
				 GROUP BY fv.filter_value_id
				 ORDER BY MIN(ip.pos)
				)
			)
		 WHERE DECODE(pos, rn, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET pos = r.rn
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP; 

	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.filter_value fv ON i.project_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

PROCEDURE FilterRagStatusId(
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, r.rag_status_id, r.label
		  FROM (
			SELECT rs.rag_status_id, rs.label
			  FROM initiative_project_rag_status iprs
			  JOIN rag_status rs ON iprs.rag_status_id = rs.rag_status_id AND iprs.app_sid = rs.app_sid
			 GROUP BY rs.rag_status_id, rs.label
			) r
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = r.rag_status_id
		 );		
	END IF;
	
	FOR r IN (
		SELECT rs.colour, fv.filter_value_id
		  FROM chain.filter_value fv
		  JOIN rag_status rs ON fv.num_value = rs.rag_status_id
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.colour, rs.colour, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET colour = r.colour
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
	
	FOR r IN (
		SELECT * FROM (
			SELECT filter_value_id, pos, ROWNUM rn
			  FROM (
				SELECT fv.filter_value_id, MIN(fv.pos) pos
				  FROM chain.filter_value fv
				  JOIN initiative_project_rag_status r ON fv.num_value = r.rag_status_id
				 WHERE fv.filter_field_id = in_filter_field_id
				 GROUP BY fv.filter_value_id
				 ORDER BY MIN(r.pos)
				)
			)
		 WHERE DECODE(pos, rn, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET pos = r.rn
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP; 

	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.filter_value fv ON i.rag_status_id = fv.num_value
		OR (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND i.rag_status_id IS NULL)
		OR (fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND i.rag_status_id IS NOT NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

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
			SELECT i.region_sid
			  FROM initiative_region i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
			 GROUP BY i.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, i.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT i.initiative_sid, fv.filter_value_id
			  FROM initiative_region i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
			  JOIN chain.filter_value fv ON i.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) i;
	ELSE
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM initiative_region i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON i.region_sid = r.region_sid;				 
	END IF;	
END;

PROCEDURE FilterRegionRef (
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.region_ref, i.region_ref
		  FROM (
			SELECT DISTINCT r.region_ref
			  FROM initiative_region i
			  JOIN TABLE(in_ids) t ON i.initiative_sid = t.object_id
			  JOIN region r ON i.app_sid = r.app_sid AND i.region_sid = r.region_sid
			 WHERE region_ref IS NOT NULL
			 ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			    AND fv.str_value = i.region_ref
		 );		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative_region i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN region r ON i.app_sid = r.app_sid AND i.region_sid = r.region_sid
	  JOIN chain.filter_value fv ON LOWER(r.region_ref) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND r.region_ref IS NOT NULL;		
END;

PROCEDURE FilterProjectStartDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(i.project_start_dtm), MAX(i.project_start_dtm)
		  INTO v_min_date, v_max_date
		  FROM initiative i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			i.project_start_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			i.project_start_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			i.project_start_dtm IS NOT NULL AND
			i.project_start_dtm >= NVL(dr.start_dtm, i.project_start_dtm) AND 
			(dr.end_dtm IS NULL OR i.project_start_dtm < dr.end_dtm));
END;

PROCEDURE FilterProjectEndDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(i.project_end_dtm), MAX(i.project_end_dtm)
		  INTO v_min_date, v_max_date
		  FROM initiative i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr 
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			i.project_end_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			i.project_end_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			i.project_end_dtm IS NOT NULL AND
			i.project_end_dtm >= NVL(dr.start_dtm, i.project_end_dtm) AND 
			(dr.end_dtm IS NULL OR i.project_end_dtm < dr.end_dtm));
END;

PROCEDURE FilterCreatedDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(i.created_dtm), MAX(i.created_dtm)
		  INTO v_min_date, v_max_date
		  FROM initiative i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			i.created_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			i.created_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			i.created_dtm IS NOT NULL AND
			i.created_dtm >= NVL(dr.start_dtm, i.created_dtm) AND 
			(dr.end_dtm IS NULL OR i.created_dtm < dr.end_dtm));
END;

PROCEDURE FilterInitiativeSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_over_time_filter_field_id	IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.initiative_sid, name
		  FROM (
			SELECT DISTINCT i.initiative_sid, SUBSTRB(i.name, 1, 255) name
			  FROM initiative i
			  JOIN TABLE(in_ids) t ON i.initiative_sid = t.object_id
			 ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			    AND fv.num_value = i.initiative_sid
		 );		
	END IF;
	
	IF in_over_time_filter_field_id IS NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(i.object_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) i
		  JOIN chain.filter_value fv ON i.object_id = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id;
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM temp_initiative_aggr_val i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
		  JOIN chain.filter_value fv ON i.initiative_sid = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id;
	END IF;	
END;

PROCEDURE FilterMetricOverTime (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN	
		-- Get date range from our data
		SELECT MIN(i.start_dtm), MAX(i.end_dtm)
		  INTO v_min_date, v_max_date
		  FROM temp_initiative_aggr_val i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
		 WHERE val_number IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
		
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM temp_initiative_aggr_val i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr ON dr.start_dtm <= i.start_dtm AND dr.end_dtm >= i.end_dtm;
END;

PROCEDURE FilterUserGroup (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_user_group_id	 				NUMBER;
BEGIN
	v_user_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, iu.user_sid
		  FROM (
			SELECT DISTINCT user_sid
			  FROM initiative_user iu
			  JOIN TABLE(in_ids) t ON iu.initiative_sid = t.object_id
			 WHERE iu.initiative_user_group_id = v_user_group_id
			 ) iu
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			    AND fv.user_sid = iu.user_sid
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(iu.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative_user iu
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON iu.initiative_sid = t.object_id
	  JOIN chain.filter_value fv ON iu.user_sid = fv.user_sid
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND iu.initiative_user_group_id = v_user_group_id;
	
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
		SELECT it.app_sid, it.initiative_sid, it.tag_id
		  FROM initiative_tag it
		  JOIN tag_group_member tgm
			ON tgm.app_sid = it.app_sid 
		   AND tgm.tag_id = it.tag_id
		 WHERE tgm.tag_group_id = v_tag_group_id)
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(i.app_sid, i.initiative_sid) NOT IN (SELECT app_sid, initiative_sid FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(i.app_sid, i.initiative_sid) IN (
				SELECT app_sid, initiative_sid 
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
END;

PROCEDURE FilterRegionTag (
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
	SELECT chain.T_FILTERED_OBJECT_ROW(i.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.initiative_sid = t.object_id
	  LEFT JOIN initiative_region ir
		ON i.app_sid = ir.app_sid AND i.initiative_sid = ir.initiative_sid
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(ir.app_sid, ir.region_sid) NOT IN (SELECT app_sid, region_sid FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(ir.app_sid, ir.region_sid) IN (
				SELECT app_sid, region_sid
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
	
END;

PROCEDURE FilterMetricNumber (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_initiative_metric_id			NUMBER;
BEGIN
	v_initiative_metric_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, imv.val, imv.val
		  FROM (
			  SELECT DISTINCT val
				FROM initiative_metric_val imv
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON imv.initiative_sid = t.object_id
			   WHERE imv.initiative_metric_id = v_initiative_metric_id
		) imv -- numbers
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = imv.val
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(imv.initiative_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM initiative_metric_val imv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON imv.initiative_sid = t.object_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND imv.initiative_metric_id = v_initiative_metric_id
	   AND chain.filter_pkg.CheckNumberRange(imv.val, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;
END initiative_report_pkg;
/
