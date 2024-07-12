CREATE OR REPLACE PACKAGE BODY chain.dedupe_proc_record_report_pkg
IS

-- private field filter units
PROCEDURE FilterDedupeAction		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterImportSource		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterBatchNum			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProcessedDtm		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMatchedDtm			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterDedupeIds (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids						T_FILTERED_OBJECT_TABLE;
	v_result_ids						T_FILTERED_OBJECT_TABLE;
	v_log_id							debug_log.debug_log_id%TYPE;
	v_inner_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := T_FILTERED_OBJECT_TABLE();
	END IF;

	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.FilterDedupeIds', in_filter_id);

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, comparator
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := filter_pkg.StartDebugLog('csr.dedupe_proc_record_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		IF r.name = 'DedupeAction' THEN
			FilterDedupeAction(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ImportSource' THEN
			FilterImportSource(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'BatchNum' THEN
			FilterBatchNum(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ProcessedDtm' THEN
			FilterProcessedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MatchedDtm' THEN
			FilterMatchedDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || r.name);
		END IF;

		filter_pkg.EndDebugLog(v_inner_log_id);

		IF r.comparator = filter_pkg.COMPARATOR_EXCLUDE THEN
			filter_pkg.InvertFilterSet(v_starting_ids, v_result_ids, v_result_ids);
		END IF;

		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_ids := v_result_ids;
		ELSE
			out_ids := out_ids MULTISET UNION v_result_ids;
		END IF;
	END LOOP;

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CopyFilter (
	in_from_filter_id				IN	filter.filter_id%TYPE,
	in_to_filter_id					IN	filter.filter_id%TYPE
)
AS
BEGIN
	filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE RunCompoundFilter(
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	filter_pkg.RunCompoundFilter('FilterDedupeIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM tt_filter_object_data;

	INSERT INTO tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id,
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN filter_pkg.AFUNC_COUNT
				ELSE filter_pkg.AFUNC_SUM
			END, l.object_id
	  FROM dedupe_processed_record dpr
	  JOIN TABLE(in_id_list) l ON dpr.dedupe_processed_record_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	  LEFT JOIN customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id;

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_sanitised_search					VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_has_regions						NUMBER;
	v_app_sid							security.security_pkg.T_SID_ID;
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.GetInitialIds');

	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	SELECT T_FILTERED_OBJECT_ROW(dpr.dedupe_processed_record_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM dedupe_processed_record dpr
	  LEFT JOIN company c ON c.company_sid = dpr.matched_to_company_sid
	  LEFT JOIN company cr ON cr.company_sid = dpr.created_company_sid
	 WHERE dpr.app_sid = v_app_sid
	   AND dpr.parent_processed_record_id IS NULL
	   AND (v_sanitised_search IS NULL
			OR UPPER(c.name) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(cr.name) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(dpr.reference) LIKE '%'||UPPER(in_search)||'%'
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
				in_id_list						=> out_id_list,
				out_id_list						=> out_id_list
			);
		END LOOP;
	END IF;

	filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN	NUMBER DEFAULT 0,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_id_list_populated = 0 THEN
		-- Step 1, get initial set of ids
		GetInitialIds(
			in_search				=> in_search,
			in_group_key			=> in_group_key,
			in_pre_filter_sid		=> in_pre_filter_sid,
			in_region_sids			=> in_region_sids,
			in_start_dtm			=> in_start_dtm,
			in_end_dtm				=> in_end_dtm,
			in_region_col_type		=> in_region_col_type,
			in_date_col_type		=> in_date_col_type,
			in_id_list				=> in_id_list,
			out_id_list				=> out_id_list
		);
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(id, NULL, NULL)
		  BULK COLLECT INTO out_id_list
		  FROM tt_filter_id;
	END IF;

	-- Step 2, If there's a filter, restrict the list of ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, out_id_list, out_id_list);
	END IF;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count					NUMBER;
	v_field_compound_filter_id			NUMBER;
	v_top_n_values						security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types					security.T_SID_TABLE;
	v_temp								T_FILTERED_OBJECT_TABLE;
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.ApplyBreadcrumb');

	out_id_list := in_id_list;

	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;

	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);

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
			v_top_n_values := filter_pkg.FindTopN(v_field_compound_filter_id, NVL(in_aggregation_type, 1), out_id_list, in_breadcrumb);

			-- update any rows that aren't in top N to -group_by_index, indicating they're "other"
			SELECT T_FILTERED_OBJECT_ROW (l.object_id, l.group_by_index, CASE WHEN t.pos IS NOT NULL THEN l.group_by_value ELSE -ff.filter_field_id END)
			  BULK COLLECT INTO v_temp
			  FROM TABLE(out_id_list) l
			  JOIN v$filter_field ff ON l.group_by_index = ff.group_by_index AND ff.compound_filter_id = v_field_compound_filter_id
			  LEFT JOIN TABLE(v_top_n_values) t ON l.group_by_value = t.pos;
		ELSE
			v_temp := out_id_list;
		END IF;

		-- apply breadcrumb
		filter_pkg.ApplyBreadcrumb(v_temp, in_breadcrumb, out_id_list);
	END IF;

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE CollectSearchResults (
	in_id_list						IN	security.T_ORDERED_SID_TABLE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_matches_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_staging_links_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('csr.dedupe_proc_record_report_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT dpr.dedupe_processed_record_id, dsl.dedupe_staging_link_id, dsl.description staging_link_description,
			   dpr.iteration_num, dpr.reference company_ref, dpr.processed_dtm, dpr.matched_to_company_sid, dpr.dedupe_action_type_id, dpr.matched_by_user_sid,
			   c.name matched_to_company_name, s.name import_source_name, cr.company_sid created_company_sid, cr.name created_company_name,
			   dpr.data_merged company_data_merged, dpr.batch_num, dpr.cms_record_id, dpr.imported_user_sid, cu.user_name imported_user_name,
			   dpr.merge_status_id merge_status, dpr.error_message, f.lookup_key form_lookup_key, dpr.dedupe_action,
			   CASE
					WHEN EXISTS (SELECT 1 FROM dedupe_merge_log WHERE error_message IS NOT NULL AND dedupe_processed_record_id = dpr.dedupe_processed_record_id) THEN 1 ELSE 0
			   END has_errors
		  FROM dedupe_processed_record dpr
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = dpr.dedupe_processed_record_id
		  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
		  JOIN import_source s ON s.import_source_id = dsl.import_source_id
		  LEFT JOIN company c ON c.company_sid = dpr.matched_to_company_sid
		  LEFT JOIN company cr ON cr.company_sid = dpr.created_company_sid
		  LEFT JOIN csr.csr_user cu ON cu.csr_user_sid = dpr.imported_user_sid
		  LEFT JOIN cms.v$form f ON f.lookup_key = s.lookup_key
		 ORDER BY fil_list.pos;

	OPEN out_matches_cur FOR
		SELECT m.dedupe_match_id, m.dedupe_processed_record_id, m.matched_to_company_sid, m.dedupe_rule_set_id,
			   c.name matched_company_name, x.mappings_short_descr
		  FROM (SELECT DISTINCT sid_id FROM TABLE(in_id_list)) fil_list
		  JOIN dedupe_match m ON fil_list.sid_id = m.dedupe_processed_record_id
		  JOIN company c ON c.company_sid = m.matched_to_company_sid
		  JOIN (
			SELECT dedupe_rule_set_id, listagg(COALESCE(f.description, r.label, tg.name), ' AND ') WITHIN GROUP (ORDER BY m2.dedupe_mapping_id) mappings_short_descr
			  FROM dedupe_rule dr
			  JOIN dedupe_mapping m2 ON m2.dedupe_mapping_id = dr.dedupe_mapping_id
			  LEFT JOIN dedupe_field f ON f.dedupe_field_id = m2.dedupe_field_id
			  LEFT JOIN reference r ON r.reference_id = m2.reference_id
			  LEFT JOIN csr.v$tag_group tg ON tg.tag_group_id = m2.tag_group_id
			 GROUP BY dedupe_rule_set_id
		  )x ON m.dedupe_rule_set_id = x.dedupe_rule_set_id;

	OPEN out_staging_links_cur FOR
		SELECT dsl.dedupe_staging_link_id, dsl.import_source_id, dsl.description, dsl.position, dsl.staging_tab_sid,
			   dsl.staging_id_col_sid, dsl.staging_batch_num_col_sid, dsl.parent_staging_link_id, dsl.destination_tab_sid,
			   nm.col_sid company_name_col_sid, cm.col_sid country_col_sid,
			   dsl.staging_source_lookup_col_sid, s.lookup_key import_source_lookup
		  FROM dedupe_staging_link dsl
		  JOIN import_source s ON dsl.import_source_id = s.import_source_id
		  LEFT JOIN dedupe_mapping nm /* company name mapping */
			ON nm.dedupe_staging_link_id = dsl.dedupe_staging_link_id
		   AND nm.dedupe_field_id = chain_pkg.FLD_COMPANY_NAME
		  LEFT JOIN dedupe_mapping cm /* company country mapping */
			ON cm.dedupe_staging_link_id = dsl.dedupe_staging_link_id
		   AND cm.dedupe_field_id = chain_pkg.FLD_COMPANY_COUNTRY
		 WHERE dsl.dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM dedupe_processed_record dpr
			 WHERE dedupe_processed_record_id IN (
				SELECT sid_id FROM TABLE(in_id_list)
			 )
		   );

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredIds (
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_order_by							VARCHAR2(255);
	v_order_by_id	 					NUMBER;
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.PageFilteredIds');

	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

	SELECT security.T_ORDERED_SID_ROW(dedupe_processed_record_id, rn)
	  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.dedupe_processed_record_id, ROWNUM rn
			  FROM (
				SELECT dpr.dedupe_processed_record_id
				  FROM dedupe_processed_record dpr
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = dpr.dedupe_processed_record_id
				  JOIN dedupe_staging_link dsl ON dpr.dedupe_staging_link_id = dsl.dedupe_staging_link_id
				  JOIN import_source isrc ON dsl.import_source_id = isrc.import_source_id
				 ORDER BY
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
							CASE (v_order_by)
								WHEN 'batchNum' THEN TO_CHAR(dpr.batch_num, '0000000000')
								WHEN 'importSourceName' THEN LOWER(isrc.name)
								WHEN 'companyRef' THEN LOWER(dpr.reference)
								WHEN 'processedDtm' THEN TO_CHAR(dpr.processed_dtm, 'YYYY-MM-DD HH24:MI:SS')
							END
						END ASC,
						CASE WHEN in_order_dir='DESC' THEN
							CASE (v_order_by)
								WHEN 'batchNum' THEN TO_CHAR(dpr.batch_num, '0000000000')
								WHEN 'importSourceName' THEN LOWER(isrc.name)
								WHEN 'companyRef' THEN LOWER(dpr.reference)
								WHEN 'processedDtm' THEN TO_CHAR(dpr.processed_dtm, 'YYYY-MM-DD HH24:MI:SS')
							END
						END DESC,
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN dpr.dedupe_processed_record_id END DESC,
						CASE WHEN in_order_dir='DESC' THEN dpr.dedupe_processed_record_id END ASC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;

	filter_pkg.EndDebugLog(v_log_id);
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Dedupe Processed Record -> '||v_name);

	END LOOP;
END;

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_matches_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_staging_links_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page							security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN

	IF NOT dedupe_admin_pkg.HasProcessedRecordAccess THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetProcessedRecords can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.GetList', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_compound_filter_id	=> in_compound_filter_id,
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
	CollectSearchResults(v_id_page, out_cur, out_matches_cur, out_staging_links_cur);

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAggregateDetails (
	in_aggregation_types			IN	security.T_ORDERED_SID_TABLE,
	in_id_col_sid					IN	security_pkg.T_SID_ID,
	out_agg_types					OUT	T_FILTER_AGG_TYPE_TABLE,
	out_aggregate_thresholds		OUT	T_FILTER_AGG_TYPE_THRES_TABLE
)
AS
BEGIN
	SELECT T_FILTER_AGG_TYPE_ROW(filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS, a.aggregate_type_id, a.description, a.format_mask,
		   a.filter_page_ind_interval_id, 0, NULL, NULL, NULL)
	  BULK COLLECT INTO out_agg_types
	  FROM (
		SELECT at.aggregate_type_id, at.description, NULL format_mask, NULL filter_page_ind_interval_id, NVL(sat.pos, at.aggregate_type_id) pos
		  FROM aggregate_type at
		  JOIN TABLE(in_aggregation_types) sat ON at.aggregate_type_id = sat.sid_id
		 WHERE at.card_group_id = filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS
		 UNION
		SELECT cuat.customer_aggregate_type_id, i.description, NVL(i.format_mask, m.format_mask), NULL filter_page_ind_interval_id, sat.pos
		  FROM customer_aggregate_type cuat
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN csr.v$ind i ON cuat.app_sid = i.app_sid AND cuat.ind_sid = i.ind_sid
		  JOIN csr.measure m ON i.measure_sid = m.measure_sid
		 WHERE cuat.card_group_id = filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS
		 UNION
		SELECT cuat.customer_aggregate_type_id, fi.description, NVL(fi.format_mask, fm.format_mask), fpii.filter_page_ind_interval_id, sat.pos
		  FROM customer_aggregate_type cuat
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN filter_page_ind_interval fpii ON cuat.filter_page_ind_interval_id = fpii.filter_page_ind_interval_id
		  JOIN filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id
		  JOIN csr.v$ind fi ON fpi.app_sid = fi.app_sid AND fpi.ind_sid = fi.ind_sid
		  JOIN csr.measure fm ON fi.measure_sid = fm.measure_sid
		 WHERE cuat.card_group_id = filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS
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
	in_id_list_populated			IN	NUMBER DEFAULT NULL,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_extra_series_cur			OUT	SYS_REFCURSOR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type					NUMBER := AGG_TYPE_COUNT;
	v_log_id							debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.GetReportData', in_compound_filter_id);

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

	v_top_n_values := filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

	filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	OPEN out_cur FOR
		SELECT fil_list.object_id, dpr.reference company_ref, c.name matched_to_company_name,
			   s.name import_source_name, cr.name created_company_name, dpr.batch_num
		  FROM dedupe_processed_record dpr
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = dpr.dedupe_processed_record_id
		  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
		  JOIN import_source s ON s.import_source_id = dsl.import_source_id
		  LEFT JOIN company c ON c.company_sid = dpr.matched_to_company_sid
		  LEFT JOIN company cr ON cr.company_sid = dpr.created_company_sid;
END;

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE DEFAULT NULL,
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
	out_matches_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_staging_links_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
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

	SELECT security.T_ORDERED_SID_ROW(object_id, object_id)
	  BULK COLLECT INTO v_id_page
	  FROM (
		SELECT DISTINCT object_id
		  FROM TABLE(v_id_list)
	  );

	INTERNAL_PopGridExtTempTable(v_id_page);

	CollectSearchResults(v_id_page, out_cur, out_matches_cur, out_staging_links_cur);
END;

PROCEDURE GetListAsExtension (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_matches_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_staging_links_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.dedupe_proc_record_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM temp_grid_extension_map
		 WHERE linked_type = filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS
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

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_matches_cur, out_staging_links_cur);
	
	filter_pkg.EndDebugLog(v_log_id);
END;

/********************************************/
/*		Filter field units					*/
/********************************************/

/*  Each filter unit must:
 *   o  Filter the list of in_ids into the out_ids based on the user's selected values for the given in_filter_field_id
 *   o  Pre-populate all possible values if in_show_all = 1
 *   o  Preserve existing duplicate issue IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *
 *  It's OK to return duplicate issue IDs if filter field values overlap. These duplicates are discounted for issue lists
 *  but required for charts to work correctly. Each filter field unit must preserve existing duplicate issue ids that are
 *  passed in.
 */

PROCEDURE FilterDedupeAction (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, b.val, b.description
		  FROM (
			SELECT 0 val, 'No action taken' description FROM dual
			UNION
			SELECT 1, 'Create' FROM dual
			UNION
			SELECT 2, 'Merge' FROM dual
			UNION
			SELECT 3, 'Ignore' FROM dual
		  ) b
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = b.val
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(dpr.dedupe_processed_record_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM dedupe_processed_record dpr
	  JOIN filter_value fv ON NVL(dpr.dedupe_action, 0) = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON dpr.dedupe_processed_record_id = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterImportSource (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, isrc.import_source_id, isrc.name
		  FROM import_source isrc
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = isrc.import_source_id
		 );
	END IF;

	SELECT DISTINCT T_FILTERED_OBJECT_ROW(dpr.dedupe_processed_record_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM dedupe_processed_record dpr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON dpr.dedupe_processed_record_id = t.object_id
	  JOIN dedupe_staging_link dsl ON dpr.dedupe_staging_link_id = dsl.dedupe_staging_link_id
	  JOIN filter_value fv ON dsl.import_source_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterBatchNum (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, dpr.batch_num, dpr.batch_num
		  FROM dedupe_processed_record dpr
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = dpr.batch_num
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(dpr.dedupe_processed_record_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM dedupe_processed_record dpr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON dpr.dedupe_processed_record_id = t.object_id
	  JOIN filter_value fv ON dpr.batch_num = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterProcessedDtm (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE)
AS
	v_min_date							DATE;
	v_max_date							DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(dpr.processed_dtm), MAX(dpr.processed_dtm)
		  INTO v_min_date, v_max_date
		  FROM dedupe_processed_record dpr;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);

	SELECT DISTINCT T_FILTERED_OBJECT_ROW(dpr.dedupe_processed_record_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM dedupe_processed_record dpr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON dpr.dedupe_processed_record_id = t.object_id
	  JOIN tt_filter_date_range dr ON (dr.end_dtm IS NULL OR dpr.processed_dtm < dr.end_dtm) AND (dpr.processed_dtm IS NULL OR dr.start_dtm IS NULL OR dpr.processed_dtm > dr.start_dtm);
END;

PROCEDURE FilterMatchedDtm (
	in_filter_id				IN	filter.filter_id%TYPE,
	in_filter_field_id			IN	NUMBER,
	in_show_all					IN	NUMBER,
	in_ids						IN	T_FILTERED_OBJECT_TABLE,
	out_ids						OUT	T_FILTERED_OBJECT_TABLE)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(dpr.matched_dtm), MAX(dpr.matched_dtm)
		  INTO v_min_date, v_max_date
		  FROM dedupe_processed_record dpr;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);

	SELECT DISTINCT T_FILTERED_OBJECT_ROW(dpr.dedupe_processed_record_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM dedupe_processed_record dpr
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON dpr.dedupe_processed_record_id = t.object_id
	  JOIN tt_filter_date_range dr ON (dr.end_dtm IS NULL OR dpr.matched_dtm < dr.end_dtm) AND (dpr.matched_dtm IS NULL OR dr.start_dtm IS NULL OR dpr.matched_dtm > dr.start_dtm);
END;

END dedupe_proc_record_report_pkg;
/
