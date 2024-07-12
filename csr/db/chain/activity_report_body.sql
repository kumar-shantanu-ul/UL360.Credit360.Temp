CREATE OR REPLACE PACKAGE BODY chain.activity_report_pkg
IS

-- private field filter units
PROCEDURE FilterActivityDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLastModifiedDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActivityTypeId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE CompanyFilter				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE CompanyFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterStatus				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLocationType		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOutcomeTypeId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLocation			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAssignedToSid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTargetUserSid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterIds (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
	v_name							VARCHAR2(256);
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, NVL(show_all, 0) show_all, group_by_index, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		IF r.name = 'ActivityDtm' THEN
			FilterActivityDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CreatedDtm' THEN
			FilterCreatedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'LastModifiedDtm' THEN
			FilterLastModifiedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ActivityTypeId' THEN
			FilterActivityTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CompanyFilter' THEN
			CompanyFilter(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'companyFilter_%' THEN
			v_name := substr(r.name, 15);
			CompanyFilterBreakdown(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Status' THEN
			FilterStatus(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Location' THEN
			FilterLocation(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'LocationType' THEN
			FilterLocationType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OutcomeTypeId' THEN
			FilterOutcomeTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AssignedToUserSid' THEN
			FilterAssignedToSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'TargetUserSid' THEN
			FilterTargetUserSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
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
	chain.filter_pkg.RunCompoundFilter('FilterIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT agg.column_value, l.object_id, filter_pkg.AFUNC_SUM,
			CASE agg.column_value
				WHEN AGG_TYPE_COUNT THEN COUNT(DISTINCT a.activity_id)
			END
	  FROM activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON a.activity_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) agg
	 GROUP BY l.object_id, agg.column_value;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE Search (
	in_search_term		IN  VARCHAR2,
	in_ids				IN  T_FILTERED_OBJECT_TABLE,
	out_ids				OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search_term);
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.activity_report_pkg.Search');

	SELECT T_FILTERED_OBJECT_ROW(activity_id, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT a.activity_id
		  FROM activity a
		  JOIN TABLE(in_ids) t ON a.activity_id = t.object_id
		 WHERE(in_search_term IS NULL 
			OR CONTAINS (a.description, v_sanitised_search) > 0
			OR CONTAINS (a.location, v_sanitised_search) > 0
			OR CONTAINS (a.outcome_reason, v_sanitised_search) > 0
			OR CAST(a.activity_id AS VARCHAR(10)) = in_search_term)
		 );
	
	filter_pkg.EndDebugLog(v_log_id);
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
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_has_regions					NUMBER;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_base_activity_ids				security.T_ORDERED_SID_TABLE;
	v_comps_can_manage				security.T_SID_TABLE;
	idx								PLS_INTEGER := 1;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.activity_report_pkg.GetFilteredIds', in_compound_filter_id);

	filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	SELECT security.T_ORDERED_SID_ROW(a.activity_id, NULL)
	  BULK COLLECT INTO v_base_activity_ids
	  FROM activity a
	 WHERE a.target_company_sid = NVL(in_parent_id, a.target_company_sid);

	BEGIN
		v_comps_can_manage := security.T_SID_TABLE();
		FOR activity_rec IN (
			SELECT DISTINCT a.target_company_sid
			  FROM activity a
			  JOIN TABLE(v_base_activity_ids) ba ON ba.sid_id = a.activity_id)
		LOOP
			-- Loop rather than query because of ORA-14551
			IF activity_pkg.SQL_CanManageActivities(activity_rec.target_company_sid) = 1 THEN
				v_comps_can_manage.extend(1);
				v_comps_can_manage(idx) := activity_rec.target_company_sid;
				idx := idx + 1;
			END IF;
		END LOOP;
	END;

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM activity a
	  JOIN TABLE(v_base_activity_ids) ba ON ba.sid_id = a.activity_id
	  LEFT JOIN TABLE(v_comps_can_manage) c ON c.column_value = a.target_company_sid
	  JOIN csr.supplier s ON a.target_company_sid = s.company_sid
	  LEFT JOIN csr.temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_SUPPLIER_REGION THEN s.region_sid END = tr.region_sid
	 WHERE (c.column_value IS NOT NULL
		OR a.activity_id IN (
			SELECT a.activity_id
			  FROM activity a
			  JOIN activity_involvement ai ON a.activity_id = ai.activity_id
		 LEFT JOIN csr.supplier s ON (a.target_company_sid = s.company_sid OR a.created_by_company_sid = s.company_sid)
		 LEFT JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
			   AND rrm.role_sid = ai.role_sid
			 WHERE ai.user_sid = security_pkg.GetSid
				OR rrm.user_sid = security_pkg.GetSid
		))
	   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	 GROUP BY a.activity_id;

	IF in_search IS NOT NULL THEN
		Search(in_search, v_id_list, v_id_list);
	END IF;

	filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
	
	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP
			IF r.search_text IS NOT NULL THEN
				Search(r.search_text, v_id_list, v_id_list);
			END IF;
		
			IF NVL(r.compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
				RunCompoundFilter(r.compound_filter_id, 0, NULL, v_id_list, v_id_list);
			END IF;
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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.ApplyBreadcrumb');

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
	in_id_list						IN	security.T_ORDERED_SID_TABLE,
	out_cur 						OUT	SYS_REFCURSOR,
	out_tags_cur 					OUT	SYS_REFCURSOR,
	out_log_cur 					OUT	SYS_REFCURSOR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.CollectSearchResults');

	OPEN out_cur FOR 
		SELECT a.activity_id, a.description, a.target_company_sid, a.created_by_company_sid, 
			   a.activity_type_id, a.activity_type_label, a.status,
			   a.assigned_to_user_sid, a.assigned_to_user_name, 
			   a.assigned_to_role_sid, a.assigned_to_role_name, 
			   a.target_user_sid, a.target_user_name,
			   a.target_role_sid, a.target_role_name,
			   a.assigned_to_name, a.target_name,
			   a.activity_dtm, a.original_activity_dtm, 
			   a.created_dtm, a.created_by_activity_id, a.created_by_sid, a.created_by_user_name,
			   a.outcome_type_id, a.outcome_type_label, a.is_success, a.is_failure,
			   a.outcome_reason, a.location, a.location_type, a.share_with_target,
			   activity_pkg.SQL_IsAssignedToUser(a.activity_id) is_assigned,
			   activity_pkg.SQL_IsTargetUser(a.activity_id) is_target,
			   a.target_company_name
		  FROM v$activity a
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = a.activity_id
		  ORDER BY fil_list.pos;

	OPEN out_tags_cur FOR
		SELECT at.activity_id, at.tag_id, tag.tag, tg.tag_group_id, tg.name tag_group_name
		  FROM activity_tag at
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = at.activity_id
		  JOIN csr.tag_group_member tgm ON at.tag_id = tgm.tag_id AND at.app_sid = tgm.app_sid
		  JOIN csr.v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		  JOIN csr.v$tag tag ON at.tag_id = tag.tag_id AND at.app_sid = tag.app_sid
		 WHERE tg.applies_to_chain_activities = 1;

	OPEN out_log_cur FOR
		SELECT al.activity_id, al.message, al.logged_dtm, al.logged_by_full_name, al.is_system_generated
		FROM v$activity_log al
		JOIN (
			SELECT activity_id, MAX(activity_log_id) max_activity_log_id 
			  FROM v$activity_log 
			 WHERE is_system_generated = 0 
			 GROUP BY activity_id
			 UNION
			select activity_id, MAX(activity_log_id) max_activity_log_id 
			  FROM v$activity_log 
			 GROUP BY activity_id
			) al2 ON al.activity_log_id = al2.max_activity_log_id;

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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.PageFilteredIds');

	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

	IF in_order_by = 'activityDtm' THEN
		SELECT security.T_ORDERED_SID_ROW(activity_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.activity_id, ROWNUM rn
			  FROM (
				SELECT a.activity_id
				  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list
				  JOIN activity a ON fil_list.object_id = a.activity_id
				  ORDER BY
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN a.activity_dtm END ASC,
						CASE WHEN in_order_dir='DESC' THEN a.activity_dtm END DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSIF INSTR(in_order_by, '~', 1) > 0 THEN
		filter_pkg.SortExtension(
			'activity', 
			in_id_list,
			in_start_row,
			in_end_row,
			in_order_by,
			in_order_dir,
			out_id_list);
	ELSIF in_order_by IN ('lastCommentBy', 'lastCommentDtm') THEN
		SELECT security.T_ORDERED_SID_ROW(activity_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.activity_id, ROWNUM rn
				  FROM (
					SELECT a.activity_id
					  FROM activity a
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = a.activity_id
					  LEFT JOIN (
						  SELECT al.activity_id, al.logged_dtm, al.logged_by_full_name FROM v$activity_log al
						  JOIN (
							SELECT activity_id, MAX(activity_log_id) max_activity_log_id 
							  FROM v$activity_log 
							 WHERE is_system_generated = 0 
							 GROUP BY activity_id
							) al2 ON al.activity_log_id = al2.max_activity_log_id
						) al ON al.activity_id = a.activity_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'lastCommentBy' THEN TO_CHAR(al.logged_by_full_name)
									WHEN 'lastCommentDtm' THEN TO_CHAR(al.logged_dtm, 'YYYY-MM-DD HH24:MI:SS')
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'lastCommentBy' THEN TO_CHAR(al.logged_by_full_name)
									WHEN 'lastCommentDtm' THEN TO_CHAR(al.logged_dtm, 'YYYY-MM-DD HH24:MI:SS')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN a.activity_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN a.activity_id END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;

	ELSIF in_order_by IN ('lastModifiedDtm') THEN
		SELECT security.T_ORDERED_SID_ROW(activity_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.activity_id, ROWNUM rn
				  FROM (
					SELECT a.activity_id
					  FROM activity a
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = a.activity_id
					  LEFT JOIN (
						  SELECT al.activity_id, al.logged_dtm FROM v$activity_log al
						  JOIN (
							SELECT activity_id, MAX(activity_log_id) max_activity_log_id 
							  FROM v$activity_log 
							 GROUP BY activity_id
							) al2 ON al.activity_log_id = al2.max_activity_log_id
						) al ON al.activity_id = a.activity_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'lastModifiedDtm' THEN TO_CHAR(NVL(al.logged_dtm, a.created_dtm), 'YYYY-MM-DD HH24:MI:SS')
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'lastModifiedDtm' THEN TO_CHAR(NVL(al.logged_dtm, a.created_dtm), 'YYYY-MM-DD HH24:MI:SS')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN a.activity_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN a.activity_id END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(activity_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.activity_id, ROWNUM rn
				  FROM (
					SELECT a.activity_id
					  FROM v$activity a
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = a.activity_id
					  LEFT JOIN (
						SELECT onct.activity_id, onct.tag_group_id, csr.stragg(onct.tag) tags
						  FROM (
							SELECT at.activity_id, tgm.tag_group_id, t.tag
							  FROM activity_tag at
							  JOIN csr.tag_group_member tgm ON at.tag_id = tgm.tag_id AND at.app_sid = tgm.app_sid
							  JOIN csr.v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) onct
						 GROUP BY onct.activity_id, onct.tag_group_id
						) atag ON a.activity_id = atag.activity_id
					  JOIN activity_type at ON at.activity_type_id = a.activity_type_id -- AND at.app_sid = a.app_sid
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'activityId' THEN LOWER(a.activity_id)
									WHEN 'status' THEN LOWER(a.status)
									WHEN 'activityTypeLabel' THEN LOWER(at.label)
									WHEN 'targetCompanyName' THEN LOWER(a.target_company_name)
									WHEN 'assignedToName' THEN LOWER(a.assigned_to_name)
									WHEN 'targetName' THEN LOWER(a.target_name)
									WHEN 'location' THEN LOWER(a.location)
									WHEN 'description' THEN LOWER(DBMS_LOB.SUBSTR(a.description, 1000, 1))
									WHEN 'outcomeTypeLabel' THEN LOWER(a.outcome_type_label)
									WHEN 'createdDtmFormatted' THEN TO_CHAR(a.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdByUserName' THEN LOWER(a.created_by_user_name)
									WHEN 'tagGroup' THEN LOWER(atag.tags)
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'activityId' THEN LOWER(a.activity_id)
									WHEN 'status' THEN LOWER(a.status)
									WHEN 'activityTypeLabel' THEN LOWER(at.label)
									WHEN 'targetCompanyName' THEN LOWER(a.target_company_name)
									WHEN 'assignedToName' THEN LOWER(a.assigned_to_name)
									WHEN 'targetName' THEN LOWER(a.target_name)
									WHEN 'location' THEN LOWER(a.location)
									WHEN 'description' THEN LOWER(DBMS_LOB.SUBSTR(a.description, 1000, 1))
									WHEN 'outcomeTypeLabel' THEN LOWER(a.outcome_type_label)
									WHEN 'createdDtmFormatted' THEN TO_CHAR(a.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdByUserName' THEN LOWER(a.created_by_user_name)
									WHEN 'tagGroup' THEN LOWER(atag.tags)
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN a.activity_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN a.activity_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	END IF;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_ActivityIdsToCoSids(
	in_ids					IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO temp_grid_extension_map gem (source_id, linked_type, linked_id)
		SELECT DISTINCT ids.sid_id, filter_pkg.FILTER_TYPE_COMPANIES, a.target_company_sid
		  FROM TABLE (in_ids) ids
		  JOIN activity a ON ids.sid_id = a.activity_id;
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_ACTIVITIES, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		IF v_extension_id = chain.filter_pkg.FILTER_TYPE_COMPANIES THEN
			INTERNAL_ActivityIdsToCoSids(in_id_page);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Activity -> '||v_name);
		END IF;

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
	out_cur 						OUT	SYS_REFCURSOR,
	out_tags_cur 					OUT	SYS_REFCURSOR,
	out_log_cur 					OUT	SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.GetList', in_compound_filter_id);

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

	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_tags_cur		=> out_tags_cur,
		out_log_cur			=> out_log_cur
	);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAggregateDetails (
	in_aggregation_types			IN	security.T_ORDERED_SID_TABLE,
	in_id_col_sid					IN	security_pkg.T_SID_ID,
	out_agg_types					OUT	chain.T_FILTER_AGG_TYPE_TABLE,
	out_aggregate_thresholds		OUT	chain.T_FILTER_AGG_TYPE_THRES_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_ACTIVITIES, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_ACTIVITIES
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
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.GetReportData', in_compound_filter_id);

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

	IF in_grp_by_compound_filter_id IS NOT NULL THEN
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;

	GetFilterObjectData(in_aggregation_types, v_id_list);

	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;

	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_ACTIVITIES, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
		SELECT 1 AS object_id
		  FROM DUAL
		 WHERE 1 = 0;
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
	out_cur							OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_log_cur 					OUT	SYS_REFCURSOR
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
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
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

	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_tags_cur		=> out_tags_cur, 
		out_log_cur			=> out_log_cur
	);
END;

PROCEDURE GetListAsExtension (
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR,
	out_log_cur 					OUT	SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('chain.activity_report_pkg.GetListAsExtension', in_compound_filter_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM chain.temp_grid_extension_map
		 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_ACTIVITIES
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
		out_log_cur					=> out_log_cur
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

PROCEDURE FilterActivityDtm (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(a.activity_dtm), MAX(a.activity_dtm)
		  INTO v_min_date, v_max_date
		  FROM activity a
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN tt_filter_date_range dr 
		ON a.activity_dtm >= NVL(dr.start_dtm, a.activity_dtm)
	   AND (dr.end_dtm IS NULL OR a.activity_dtm < dr.end_dtm)
	 WHERE a.activity_dtm IS NOT NULL;
END;

PROCEDURE FilterCreatedDtm (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(a.created_dtm), MAX(a.created_dtm)
		  INTO v_min_date, v_max_date
		  FROM activity a
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN tt_filter_date_range dr 
		ON a.created_dtm >= NVL(dr.start_dtm, a.created_dtm)
	   AND (dr.end_dtm IS NULL OR a.created_dtm < dr.end_dtm)
	 WHERE a.created_dtm IS NOT NULL;
	
END;

PROCEDURE FilterLastModifiedDtm (
	in_filter_id 					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(a.logged_dtm), MAX(a.logged_dtm)
		  INTO v_min_date, v_max_date
		  FROM activity_log a
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);	
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(al.activity_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT al.activity_id,al.logged_dtm
	  	  FROM v$activity_log al
		  JOIN (
			SELECT activity_id, MAX(activity_log_id) max_activity_log_id 
			  FROM v$activity_log 
			 GROUP BY activity_id
			) al2 ON al.activity_log_id = al2.max_activity_log_id
		 UNION
		SELECT activity_id,created_dtm logged_dtm
		  FROM activity
		 WHERE activity_id NOT IN (
			SELECT activity_id 
			  FROM v$activity_log)
		) al
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON al.activity_id = t.object_id
	  JOIN tt_filter_date_range dr 
		ON al.logged_dtm >= NVL(dr.start_dtm, al.logged_dtm)
	   AND (dr.end_dtm IS NULL OR al.logged_dtm < dr.end_dtm)
	 WHERE al.logged_dtm IS NOT NULL;
END;

PROCEDURE FilterActivityTypeId (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, at.activity_type_id, at.label
		  FROM activity_type at
		 WHERE at.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = at.activity_type_id
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(activity_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN filter_value fv ON a.activity_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterStatus (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, s.status_name, s.status_name
		  FROM (
			SELECT 'Overdue' status_name FROM dual
			UNION ALL SELECT 'Up-coming' FROM dual
			UNION ALL SELECT 'Completed' FROM dual
		  ) s
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = s.status_name
		 );
	END IF;

	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT s.pos new_pos, fv.pos old_pos, fv.filter_value_id
		  FROM filter_value fv
		  JOIN (
			SELECT 'Overdue' status_name, 1 pos FROM dual
			 UNION ALL SELECT 'Up-coming', 2 FROM dual
			 UNION ALL SELECT 'Completed', 3 FROM dual
		  ) s ON s.status_name = fv.str_value
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.pos, s.pos, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET pos = r.new_pos
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN filter_value fv ON a.status = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLocationType (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, lt.location_type, lt.location_type_label
		  FROM (
			SELECT 1 location_type, 'Supplier Site' location_type_label FROM dual
			--UNION ALL SELECT 2,'Base Location' FROM dual
			UNION ALL SELECT 3, 'Other' FROM dual
		  ) lt
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = lt.location_type
		 );
	END IF;

	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT lt.pos new_pos, fv.pos old_pos, fv.filter_value_id
		  FROM filter_value fv
		  JOIN (
			SELECT 1 location_type, 'Supplier Site' location_type_label, 1 pos FROM dual
			--UNION ALL SELECT 2, 'Base Location', 2 FROM dual
			UNION ALL SELECT 3, 'Other', 3 FROM dual
		  ) lt ON lt.location_type = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.pos, lt.pos, 1, 0) = 0
	) LOOP
		UPDATE filter_value
		   SET pos = r.new_pos
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN filter_value fv ON a.location_type = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLocation (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(activity_id, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN filter_value fv ON LOWER(a.location) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;


PROCEDURE FilterOutcomeTypeId (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, ot.outcome_type_id, ot.label
		  FROM outcome_type ot
		 WHERE ot.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = ot.outcome_type_id
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(activity_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM activity a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
	  JOIN filter_value fv ON a.outcome_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAssignedToSid (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- ensure the filter_value rows include all assigned to users for the current filter
		-- we don't remove values from old filters / drilldowns so it's possible to get 0 count
		-- filter values
		-- TODO: Should we remove values from filter_value that no longer match in_sids?
		INSERT INTO filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, a.assigned_to
		  FROM (
			SELECT DISTINCT NVL(assigned_to_user_sid, assigned_to_role_sid) assigned_to
			  FROM v$activity a
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
			  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = a.assigned_to
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM filter_value fv
	  JOIN (
		SELECT a.activity_id, a.assigned_to_user_sid, a.assigned_to_role_sid, s.region_sid
		  FROM v$activity a
		  JOIN csr.supplier s ON s.company_sid = a.target_company_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
		 WHERE rownum >= 0 -- fully materialize sub-query
		) a
		ON fv.user_sid = a.assigned_to_user_sid
		OR fv.user_sid = a.assigned_to_role_sid
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_ME AND a.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_MY_ROLES AND EXISTS(SELECT 1 FROM csr.region_role_member rrm WHERE rrm.role_sid = a.assigned_to_role_sid AND rrm.region_sid = a.region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')))
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr.csr_user u WHERE u.csr_user_sid = a.assigned_to_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterTargetUserSid (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- ensure the filter_value rows include all assigned to users for the current filter
		-- we don't remove values from old filters / drilldowns so it's possible to get 0 count
		-- filter values
		-- TODO: Should we remove values from filter_value that no longer match in_sids?
		INSERT INTO filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, a.target_to
		  FROM (
			SELECT DISTINCT NVL(target_user_sid, target_role_sid) target_to
			  FROM v$activity a
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
			  ) a
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = a.target_to
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM filter_value fv
	  JOIN (
		SELECT a.activity_id, a.target_user_sid, a.target_role_sid, s.region_sid
		  FROM v$activity a
		  JOIN csr.supplier s ON s.company_sid = a.target_company_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.activity_id = t.object_id
		 WHERE rownum >= 0 -- fully materialize sub-query
		) a
		ON fv.user_sid = a.target_user_sid
		OR fv.user_sid = a.target_role_sid
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_ME AND a.target_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_MY_ROLES AND EXISTS(SELECT 1 FROM csr.region_role_member rrm WHERE rrm.role_sid = a.target_role_sid AND rrm.region_sid = a.region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')))
		OR (in_show_all = 0 AND fv.user_sid = filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr.csr_user u WHERE u.csr_user_sid = a.target_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE CompanyFilter (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_company_sids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- get company sids from activity ids
		SELECT T_FILTERED_OBJECT_ROW(a.target_company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_sids
		  FROM activity a
		  JOIN TABLE(in_ids) t ON a.activity_id = t.object_id;

		-- filter audits
		company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_sids,
			out_id_list						=> v_company_sids
		);

		-- convert company sids from audits sids
		SELECT T_FILTERED_OBJECT_ROW(a.activity_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM activity a
		  JOIN TABLE(in_ids) ids ON ids.object_id = a.activity_id
		  JOIN TABLE(v_company_sids) t ON a.target_company_sid = t.object_id;
	END IF;
END;

PROCEDURE CompanyFilterBreakdown (
	in_name							IN	filter_field.name%TYPE,
	in_comparator					IN	filter_field.comparator%TYPE,
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_company_sids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(a.target_company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM activity a
	  JOIN TABLE(in_ids) t ON a.activity_id = t.object_id;

	company_filter_pkg.RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> NULL,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_sids						=> v_company_sids,
		out_sids					=> v_company_sids
	);
		  
	SELECT T_FILTERED_OBJECT_ROW(a.activity_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM activity a
	  JOIN TABLE(in_ids) ids ON ids.object_id = a.activity_id
	  JOIN TABLE(v_company_sids) t ON a.target_company_sid = t.object_id;
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_comparator					IN	chain.filter_field.comparator%TYPE, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_result_ids					T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	IF in_comparator = chain.filter_pkg.COMPARATOR_INTERSECT THEN
		v_result_ids := in_ids;

		IF in_group_by_index IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot group by intersected filters');
		END IF;

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM filter_value fv
			  JOIN saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> v_result_ids,
				out_id_list						=> v_result_ids
			);
		END LOOP;
		
		out_ids := v_result_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM filter_value fv
			  JOIN saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
			 WHERE fv.filter_field_id = in_filter_field_id
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> in_ids,
				out_id_list						=> v_result_ids
			);

			SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, r.filter_value_id)
			  BULK COLLECT INTO v_temp_ids
			  FROM TABLE(v_result_ids) t;

			out_ids := out_ids MULTISET UNION v_temp_ids;
		END LOOP;
	END IF;
END;

END activity_report_pkg;
/
