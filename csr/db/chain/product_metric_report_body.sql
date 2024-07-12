CREATE OR REPLACE PACKAGE BODY chain.product_metric_report_pkg
IS

-- private field filter units
PROCEDURE FilterIndSid				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDate				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterValue				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSourceType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE ProductFilter				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_property_col_sid				security_pkg.T_SID_ID;
	v_compound_filter_id			chain.compound_filter.compound_filter_id%TYPE;
	v_stripped_name					VARCHAR2(256);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, NVL(show_all, 0) show_all, group_by_index, column_sid, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);		
		
		IF LOWER(r.name) = 'indsid' THEN
			FilterIndSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'date' THEN
			FilterDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'value' THEN
			FilterValue(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'sourcetype' THEN
			FilterSourceType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'productfilter' THEN
			ProductFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id,
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT_METRIC_VAL THEN chain.filter_pkg.AFUNC_COUNT
				WHEN AGG_TYPE_SUM_METRIC_VAL THEN chain.filter_pkg.AFUNC_SUM
				WHEN AGG_TYPE_AVG_METRIC_VAL THEN chain.filter_pkg.AFUNC_AVERAGE
				WHEN AGG_TYPE_MAX_METRIC_VAL THEN chain.filter_pkg.AFUNC_MAX
				WHEN AGG_TYPE_MIN_METRIC_VAL THEN chain.filter_pkg.AFUNC_MIN
				ELSE chain.filter_pkg.AFUNC_COUNT
			END, pmv.val_number
	  FROM product_metric_val pmv
	  JOIN TABLE(in_id_list) l ON pmv.product_metric_val_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	  LEFT JOIN chain.customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id;

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

	SELECT T_FILTERED_OBJECT_ROW(product_metric_val_id, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT pmv.product_metric_val_id
		  FROM product_metric_val pmv
		  JOIN product_metric pm ON pmv.ind_sid = pm.ind_sid
		  JOIN csr.v$ind i ON pm.ind_sid = i.ind_sid
		  JOIN TABLE(in_ids) t ON pmv.product_metric_val_id = t.object_id
		 WHERE(v_sanitised_search IS NULL
			OR UPPER(i.description) LIKE '%'||UPPER(in_search_term)||'%'
			)
		 );
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE, -- not used, seems that's only been added for matching the expected signature
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_app_sid							security.security_pkg.T_SID_ID;
	v_id_list							T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_log_id							chain.debug_log.debug_log_id%TYPE;
	v_company_sid						security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sids				security.T_SID_TABLE;
	v_product_metric_val_as_supp		NUMBER := 0;
	v_product_id_list					security.T_SID_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.GetInitialIds');

	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	v_owner_company_sids := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_READ);
	
	-- GetPermissibleCompanySids only got us the suppliers	
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL, security.security_pkg.PERMISSION_READ) THEN
		v_owner_company_sids.extend;
		v_owner_company_sids(v_owner_company_sids.COUNT) := v_company_sid;
	END IF;

	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCT_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_READ) THEN
		v_product_metric_val_as_supp := 1;
	END IF;

	SELECT DISTINCT cp.product_id
			BULK COLLECT INTO v_product_id_list
	  FROM company_product cp
	  LEFT JOIN TABLE(v_owner_company_sids) owner_perm ON owner_perm.column_value = cp.company_sid
	  LEFT JOIN product_supplier ps ON ps.product_id = cp.product_id
	 WHERE (
			owner_perm.column_value IS NOT NULL
			OR (v_product_metric_val_as_supp = 1 AND ps.supplier_company_sid = v_company_sid)
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(pmv.product_metric_val_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM product_metric_val pmv
	  JOIN product_metric pm ON pmv.ind_sid = pm.ind_sid
	  JOIN csr.v$ind i ON pm.ind_sid = i.ind_sid
	  JOIN TABLE(v_product_id_list) prod_list ON pmv.product_id = prod_list.column_value
	 WHERE pmv.app_sid = v_app_sid
	   AND pm.applies_to_product = 1
	   AND (in_parent_id IS NULL OR pmv.product_id = in_parent_id);

	IF in_search IS NOT NULL THEN
		Search(in_search, v_id_list, v_id_list);
	END IF;

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

	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;

	out_id_list := v_id_list;
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
		GetInitialIds(
			in_search			=> in_search,
			in_group_key		=> in_group_key,
			in_pre_filter_sid	=> in_pre_filter_sid,
			in_parent_id		=> in_parent_id,
			in_id_list			=> in_id_list,
			out_id_list			=> out_id_list
		);
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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.ApplyBreadcrumb');

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
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ pmv.product_metric_val_id, 
			   pmv.product_id, cp.product_name, cp.product_ref,
			   cp.company_sid, c.name company_name,
			   pmv.ind_sid, pmv.start_dtm, pmv.end_dtm, pmv.source_type,
			   i.description as product_metric, NVL(i.format_mask, m.format_mask) format_mask,
			   pmv.val_number, CASE WHEN pm.show_measure = 1 THEN m.description END measure, 
			   pmv.entered_as_val_number, CASE WHEN pm.show_measure = 1 THEN NVL(mc.description, m.description) END entered_as_measure 
		  FROM product_metric_val pmv
		  JOIN TABLE(in_id_list) fil_list ON pmv.product_metric_val_id = fil_list.sid_id
		  JOIN v$company_product cp ON cp.product_id = pmv.product_id
		  JOIN v$company c ON c.company_sid = cp.company_sid
		  JOIN product_metric pm ON pm.ind_sid = pmv.ind_sid
		  JOIN csr.v$ind i ON pm.ind_sid = i.ind_sid
		  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN csr.measure_conversion mc ON pmv.measure_conversion_id = mc.measure_conversion_id
		 WHERE pm.applies_to_product = 1;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE PageFilteredProductMetricIds (
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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.PageFilteredProductMetricIdsIds');

	IF in_order_by = 'startDtm' AND in_order_dir = 'DESC' THEN
		-- default query when you hit the page, use quick version
		-- without joins
		SELECT security.T_ORDERED_SID_ROW(product_metric_val_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.product_metric_val_id, ROWNUM rn
			  FROM (
				SELECT pmv.product_metric_val_id
				  FROM product_metric_val pmv
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = pmv.product_metric_val_id
				  JOIN csr.v$ind i ON pmv.ind_sid = i.ind_sid
				 ORDER BY pmv.start_dtm DESC, LOWER(i.description)
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(product_metric_val_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.product_metric_val_id, ROWNUM rn
			  FROM (
				SELECT pmv.product_metric_val_id
				  FROM product_metric_val pmv
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = pmv.product_metric_val_id
				  JOIN v$company_product cp ON cp.product_id = pmv.product_id
				  JOIN v$company c ON c.company_sid = cp.company_sid
				  JOIN product_metric pm ON pmv.ind_sid = pm.ind_sid
				  JOIN csr.v$ind i ON pm.ind_sid = i.ind_sid
				  JOIN csr.measure m on i.measure_sid = m.measure_sid
				  LEFT JOIN csr.measure_conversion mc on pmv.measure_conversion_id = mc.measure_conversion_id
				 ORDER BY
					-- To avoid dyanmic SQL, do many case statements
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
						CASE (v_order_by)
							WHEN 'productMetricValId' THEN TO_CHAR(pmv.product_metric_val_id, '0000000000')
							WHEN 'productId' THEN TO_CHAR(cp.product_id, '0000000000')
							WHEN 'productName' THEN LOWER(cp.product_name)
							WHEN 'productRef' THEN LOWER(cp.product_ref)
							WHEN 'companySid' THEN TO_CHAR(cp.company_sid, '0000000000')
							WHEN 'companyName' THEN LOWER(c.name)
							WHEN 'productMetric' THEN LOWER(i.description)
							WHEN 'startDtm' THEN TO_CHAR(pmv.start_dtm, 'YYYY-MM-DD')
							WHEN 'endDtm' THEN TO_CHAR(pmv.end_dtm, 'YYYY-MM-DD')
							WHEN 'valNumber' THEN TO_CHAR(pmv.val_number, '000000000000000000000000.0000000000')
							WHEN 'measure' THEN LOWER(m.description)
							WHEN 'enteredAsValNumber' THEN TO_CHAR(pmv.entered_as_val_number, '000000000000000000000000.0000000000')
							WHEN 'enteredAsMeasure' THEN LOWER(NVL(mc.description, m.description))
							WHEN 'sourceType' THEN TO_CHAR(pmv.source_type, '0000000000')
						END
					END ASC,
					CASE WHEN in_order_dir='DESC' THEN
						CASE (v_order_by)
							WHEN 'productMetricValId' THEN TO_CHAR(pmv.product_metric_val_id, '0000000000')
							WHEN 'productId' THEN TO_CHAR(cp.product_id, '0000000000')
							WHEN 'productName' THEN LOWER(cp.product_name)
							WHEN 'productRef' THEN LOWER(cp.product_ref)
							WHEN 'companySid' THEN TO_CHAR(cp.company_sid, '0000000000')
							WHEN 'companyName' THEN LOWER(c.name)
							WHEN 'productMetric' THEN LOWER(i.description)
							WHEN 'startDtm' THEN TO_CHAR(pmv.start_dtm, 'YYYY-MM-DD')
							WHEN 'endDtm' THEN TO_CHAR(pmv.end_dtm, 'YYYY-MM-DD')
							WHEN 'valNumber' THEN TO_CHAR(pmv.val_number, '000000000000000000000000.0000000000')
							WHEN 'measure' THEN LOWER(m.description)
							WHEN 'enteredAsValNumber' THEN TO_CHAR(pmv.entered_as_val_number, '000000000000000000000000.0000000000')
							WHEN 'enteredAsMeasure' THEN LOWER(NVL(mc.description, m.description))
							WHEN 'sourceType' THEN TO_CHAR(pmv.source_type, '0000000000')
						END
					END DESC,
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN pmv.start_dtm END DESC,
					CASE WHEN in_order_dir='DESC' THEN pmv.start_dtm END ASC,
					LOWER(i.description)
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Product Metric -> '||v_name);

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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.GetList', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		out_id_list				=> v_id_list
	);

	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);

	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);

	PageFilteredProductMetricIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur);

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
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT_METRIC_VAL;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.GetReportData', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
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
	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

	filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);

	filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed
	OPEN out_cur FOR
		SELECT NULL
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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN	
	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
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

	CollectSearchResults(v_id_page, out_cur);
END;

PROCEDURE GetListAsExtension (
	in_compound_filter_id			IN	chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('chain.product_metric_filter_pkg.GetListAsExtension', in_compound_filter_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM chain.temp_grid_extension_map
		 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL
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
 
PROCEDURE FilterIndSid (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pm.ind_sid, i.description
		  FROM product_metric pm
		  JOIN csr.v$ind i ON pm.ind_sid = i.ind_sid
		 WHERE pm.applies_to_product = 1
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = pm.ind_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(pmv.product_metric_val_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_metric_val pmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON pmv.product_metric_val_id = t.object_id
	  JOIN chain.filter_value fv ON pmv.ind_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterDate (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		SELECT MIN(pmv.start_dtm), MAX(pmv.start_dtm)
		  INTO v_min_date, v_max_date
		  FROM product_metric_val pmv
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON pmv.product_metric_val_id = t.object_id;
		
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(pmv.product_metric_val_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_metric_val pmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON pmv.product_metric_val_id = t.object_id
	  JOIN chain.tt_filter_date_range dr 
	    ON (dr.start_dtm IS NULL OR pmv.end_dtm > dr.start_dtm)
	   AND (dr.end_dtm IS NULL OR pmv.start_dtm < dr.end_dtm);
END;

PROCEDURE FilterValue (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, sts.val_number, sts.val_number
		  FROM (
			  SELECT DISTINCT pmv.val_number
				FROM product_metric_val pmv
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON pmv.product_metric_val_id = t.object_id
		) sts
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = sts.val_number
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	
	
	SELECT chain.T_FILTERED_OBJECT_ROW(pmv.product_metric_val_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_metric_val pmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON pmv.product_metric_val_id = t.object_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(pmv.val_number, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;
END;

PROCEDURE FilterSourceType (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, num_value, description
		 FROM (
			SELECT chain_pkg.METRIC_VAL_SOURCE_TYPE_USER num_value, 'User' description FROM dual
			UNION ALL SELECT chain_pkg.METRIC_VAL_SOURCE_TYPE_CALC, 'Calculation' FROM dual
		  ) o;
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(pmv.product_metric_val_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_metric_val pmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON pmv.product_metric_val_id = t.object_id
	  JOIN chain.filter_value fv ON pmv.source_type = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_comparator					IN	chain.filter_field.comparator%TYPE, 
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
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

PROCEDURE ProductFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_ids							T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(pmv.product_id, NULL, NULL)
		  BULK COLLECT INTO v_ids
		  FROM product_metric_val pmv
		  JOIN TABLE(in_ids) t ON pmv.product_metric_val_id = t.object_id;
		
		product_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_ids,
			out_id_list						=> v_ids
		);
		
		SELECT T_FILTERED_OBJECT_ROW(product_metric_val_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT product_metric_val_id
			  FROM product_metric_val pmv
			  JOIN TABLE(in_ids) ids ON ids.object_id = pmv.product_metric_val_id
			  JOIN TABLE(v_ids) t ON pmv.product_id = t.object_id
		  );
	END IF;
END;

END product_metric_report_pkg;
/
