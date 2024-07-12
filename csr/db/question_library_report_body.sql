CREATE OR REPLACE PACKAGE BODY csr.question_library_report_pkg
IS

-- private field filter units
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterQuestionType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER,                                                        in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);


PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_question_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, 
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
			END,
			CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN l.object_id
			END
	  FROM question q
	  JOIN TABLE(in_question_id_list) l ON q.question_id = l.object_id
	  CROSS JOIN TABLE(in_aggregation_types) a
	 GROUP BY a.column_value, l.object_id;
	
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
	in_question_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	out_question_id_list			OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.RunCompoundFilter');
	
	v_starting_ids := in_question_id_list;

	IF in_parallel = 0 THEN
		out_question_id_list := in_question_id_list;
	ELSE
		out_question_id_list := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	chain.filter_pkg.CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);
	chain.filter_pkg.CheckCompoundFilterForCycles(in_compound_filter_id);
		
	FOR r IN (
		SELECT filter_id, name, filter_field_id, show_all, group_by_index, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND compound_filter_id = in_compound_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.FilterQuestionIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'QuestionType' THEN
			FilterQuestionType	(r.filter_id, r.filter_field_id,		  r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'TagGroup.%' THEN
			FilterTag			(r.filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || r.name);
		END IF;
		
		chain.filter_pkg.EndDebugLog(v_inner_log_id);
		
		IF r.comparator = chain.filter_pkg.COMPARATOR_EXCLUDE THEN 
			chain.filter_pkg.InvertFilterSet(v_starting_ids, v_result_ids, v_result_ids);
		END IF;
		
		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_question_id_list := v_result_ids;
		ELSE
			out_question_id_list := out_question_id_list MULTISET UNION v_result_ids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.ApplyBreadcrumb');

	out_id_list := in_id_list;

	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;

	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := chain.filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);

		RunCompoundFilter(v_field_compound_filter_id, 1, v_breadcrumb_count, out_id_list, out_id_list);

		-- no topN so just apply breadcrumb
		chain.filter_pkg.ApplyBreadcrumb(out_id_list, in_breadcrumb, out_id_list);
	END IF;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CollectSearchResults (
	in_question_id_list				IN  security.T_ORDERED_SID_TABLE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS	
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.CollectSearchResults');
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ q.question_id, q.question_type, qv.label, q.lookup_key, qv.question_draft,
			   CASE WHEN pub.question_id IS NOT NULL THEN 1 ELSE 0 END question_is_published, qv.question_version
		  FROM TABLE(in_question_id_list) fil_list
		  JOIN question q ON fil_list.sid_id = q.question_id
		  JOIN question_version qv
		    ON q.app_sid = qv.app_sid 
		   AND q.question_id = qv.question_id
		   AND q.latest_question_version = qv.question_version
		   AND q.latest_question_draft = qv.question_draft
		  LEFT JOIN (
			SELECT DISTINCT question_id
			  FROM question_version
			 WHERE question_draft = 0
		  ) pub ON q.question_id = pub.question_id
		 ORDER BY fil_list.pos;
		 
	OPEN out_tags_cur FOR
		SELECT /*+ALL_ROWS*/ qt.question_id, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag, tgm.pos
		  FROM TABLE(in_question_id_list) fil_list
		  JOIN question q ON fil_list.sid_id = q.question_id
		  JOIN question_version qv
		    ON q.app_sid = qv.app_sid 
		   AND q.question_id = qv.question_id
		   AND q.latest_question_version = qv.question_version
		   AND q.latest_question_draft = qv.question_draft
		  JOIN question_tag qt ON qv.question_id = qt.question_id AND qv.question_version = qt.question_version AND qv.question_draft = qt.question_draft
		  JOIN tag_group_member tgm ON qt.tag_id = tgm.tag_id AND qt.app_sid = tgm.app_sid
		  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
		  JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		 WHERE tg.applies_to_quick_survey = 1
		 ORDER BY tgm.tag_group_id, tgm.pos;
		 
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredQuestionIds (
	in_question_id_list				IN	chain.T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2 DEFAULT 'questionId',
	in_order_dir					IN	VARCHAR2 DEFAULT 'DESC',
	out_question_id_list			OUT	security.T_ORDERED_SID_TABLE
)
AS	
	v_order_by						VARCHAR2(255);
	v_tag_group_id	 				NUMBER;
	v_has_id_prefix					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.PageFilteredQuestionIds');
	
	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_tag_group_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
	
	-- run the page fasted if sorting by the default, then split out any expensive joins, then sort by the rest
	IF in_order_by = 'questionId' AND in_order_dir='DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_question_id_list
			  FROM (
				SELECT x.object_id, ROWNUM rn
				  FROM (
					SELECT object_id
					  FROM (SELECT DISTINCT object_id FROM TABLE(in_question_id_list))
					 ORDER BY object_id DESC
					) x 
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		SELECT security.T_ORDERED_SID_ROW(question_id, rn)
		  BULK COLLECT INTO out_question_id_list
			  FROM (
				SELECT x.question_id, ROWNUM rn
				  FROM (
					SELECT qv.question_id
					  FROM TABLE(in_question_id_list) fil_list
					  JOIN question q
					    ON fil_list.object_id = q.question_id
					  JOIN question_version qv
					    ON q.app_sid = qv.app_sid 
					   AND q.question_id = qv.question_id
					   AND q.latest_question_version = qv.question_version
					   AND q.latest_question_draft = qv.question_draft
					 ORDER BY
						-- To avoid dyanmic SQL, do many case statements
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
							CASE (v_order_by)
								WHEN 'questionId' THEN TO_CHAR(qv.question_id, '0000000000')
								WHEN 'label' THEN LOWER(qv.label)
							END
						END ASC,
						CASE WHEN in_order_dir='DESC' THEN
							CASE (v_order_by)
								WHEN 'questionId' THEN TO_CHAR(qv.question_id, '0000000000')
								WHEN 'label' THEN LOWER(qv.label)
							END
						END DESC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
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
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions
	
	SELECT chain.T_FILTERED_OBJECT_ROW(q.question_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM question q
	 WHERE q.owned_by_survey_sid IS NULL;
	
	IF in_id_list IS NOT NULL AND in_id_list_populated = 1 THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(t1.object_id, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM TABLE(in_id_list) t1 
		  JOIN TABLE(out_id_list) t2 on t1.object_id = t2.object_id;
		
		out_id_list := v_id_list;
	END IF;
	
	IF in_search IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(l.object_id, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM TABLE(out_id_list) l
		  JOIN question q ON l.object_id = q.question_id
		  JOIN question_version qv
		    ON q.app_sid = qv.app_sid 
		   AND q.question_id = qv.question_id
		   AND q.latest_question_version = qv.question_version
		   AND q.latest_question_draft = qv.question_draft
		 WHERE (LOWER(qv.label) LIKE '%'||LOWER(in_search)||'%'
		    OR LOWER(q.lookup_key) = LOWER(in_search)
		    OR TO_CHAR(q.question_id) = in_search);
		
		out_id_list := v_id_list;
	END IF;
	
	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> out_id_list,
				out_id_list						=> out_id_list
			);
		END LOOP;
	END IF;
	
	-- If there's a filter, restrict the list of issue ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, out_id_list, out_id_list);
	END IF;
END;

PROCEDURE GetQuestionList(
	in_search						IN	VARCHAR2,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	--in_order_by 					IN	VARCHAR2,
	--in_order_dir					IN	VARCHAR2,
	--in_breadcrumb					IN	security_pkg.T_SID_IDS,
	--in_region_sids					IN	security_pkg.T_SID_IDS,
	--in_start_dtm					IN	DATE,
	--in_end_dtm						IN	DATE,
	--in_region_col_type				IN	NUMBER,
	--in_date_col_type				IN	NUMBER,
	out_total_rows_cur				OUT	SYS_REFCURSOR,
	out_cur 						OUT	SYS_REFCURSOR,
	out_tags_cur					OUT	SYS_REFCURSOR
)
AS
	v_question_id_list				chain.T_FILTERED_OBJECT_TABLE;
	v_question_id_page				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE;-- := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.GetQuestionList', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> v_region_sids,
		in_start_dtm			=> NULL,
		in_end_dtm				=> NULL,
		in_region_col_type		=> NULL,
		in_date_col_type		=> NULL,
		out_id_list				=> v_question_id_list
	);
	
	--ApplyBreadcrumb(v_question_id_list, in_breadcrumb, v_question_id_list);
	
	-- Get the total number of rows (to work out number of pages)
	OPEN out_total_rows_cur FOR
	SELECT COUNT(DISTINCT object_id) as total_rows
	  FROM TABLE(v_question_id_list);
	
	PageFilteredQuestionIds(
		in_question_id_list		=> v_question_id_list,
		in_start_row			=> in_start_row,
		in_end_row				=> in_end_row,
		--in_order_by				=> in_order_by,
		--in_order_dir			=> in_order_dir,
		out_question_id_list	=> v_question_id_page
	);
	
	-- Return a page of results
	CollectSearchResults(v_question_id_page, out_cur, out_tags_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
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
	v_question_id_list				chain.T_FILTERED_OBJECT_TABLE;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.question_library_report_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_group_key			=> in_group_key,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_region_sids			=> in_region_sids,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_region_col_type		=> in_region_col_type,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_question_id_list
	);

	IF in_grp_by_compound_filter_id IS NOT NULL THEN
		RunCompoundFilter(in_grp_by_compound_filter_id, 1, in_max_group_by, v_question_id_list, v_question_id_list);
	END IF;
	
	GetFilterObjectData(in_aggregation_types, v_question_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_question_id_list, in_breadcrumb);
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_QUESTION_LIBRARY, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_question_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
	chain.filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
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

	SELECT chain.T_FILTERED_OBJECT_ROW(qt.question_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM question_tag qt
	  JOIN question q
	    ON q.app_sid = qt.app_sid 
	   AND q.question_id = qt.question_id
	   AND q.latest_question_version = qt.question_version
	   AND q.latest_question_draft = qt.question_draft
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON qt.question_id = t.object_id
	  JOIN chain.filter_value fv ON qt.tag_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
	
END;

PROCEDURE FilterQuestionType (
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
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, qt.question_type, qt.label
		  FROM question_type qt
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = qt.question_type
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(q.question_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM question q
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON q.question_id = t.object_id
	  JOIN chain.filter_value fv ON q.question_type = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

END question_library_report_pkg;
/
