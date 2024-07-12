CREATE OR REPLACE PACKAGE BODY chain.prdct_supp_mtrc_report_pkg
IS

-- private field filter units
PROCEDURE FilterIndSid				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDate				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterValue				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSourceType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE SupplierFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

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
	
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, NVL(show_all, 0) show_all, group_by_index, column_sid, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);		
		
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
		ELSIF LOWER(r.name) = 'supplierfilter' THEN
			SupplierFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.GetFilterObjectData');

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
			END, psmv.val_number
	  FROM product_supplier_metric_val psmv
	  JOIN TABLE(in_id_list) l ON psmv.supplier_product_metric_val_id = l.object_id
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

	SELECT T_FILTERED_OBJECT_ROW(supplier_product_metric_val_id, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT psmv.supplier_product_metric_val_id
		  FROM product_supplier_metric_val psmv
		  JOIN csr.v$ind i ON psmv.ind_sid = i.ind_sid
		  JOIN TABLE(in_ids) t ON psmv.supplier_product_metric_val_id = t.object_id
		 WHERE(v_sanitised_search IS NULL
			OR UPPER(i.description) LIKE '%'||UPPER(in_search_term)||'%')
		 );
	
	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_owner_company_sids			security.T_SID_TABLE;
	v_read_own_products				NUMBER := 0;
	v_products_as_suppliers			NUMBER := 0;
	v_prd_sup_mtrc_as_supp			NUMBER := 0;
	v_read_product					T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ);
	v_read_product_suppliers		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_read_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_read_prd_supp_mtrc_val		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL, security.security_pkg.PERMISSION_READ);
	v_read_prd_sos_mtrc_val			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_SUPP, security.security_pkg.PERMISSION_READ);
BEGIN
	-- Three ways we can see a product_supplier
	-- We're the supplier, and we have PRODUCTS_AS_SUPPLIER
	-- We're the purchaser, and we have PRODUCT_SUPPLIERS
	-- We're neither, and we have PRODUCT_SUPPLIERS as a tertiary capability
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.GetInitialIds');

	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
		v_read_own_products := 1;
	END IF;
	
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
		v_products_as_suppliers := 1;
	END IF;

	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_READ) THEN
		v_prd_sup_mtrc_as_supp := 1;
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(psmv.supplier_product_metric_val_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM product_supplier_metric_val  psmv
	  JOIN csr.v$ind i ON psmv.ind_sid = i.ind_sid
	  JOIN product_supplier ps ON ps.product_supplier_id = psmv.product_supplier_id
	  JOIN company_product cp ON cp.product_id = ps.product_id
	  JOIN company owner ON owner.company_sid = cp.company_sid
	  LEFT JOIN TABLE(v_read_product) read_prod ON read_prod.secondary_company_type_id = owner.company_type_id AND read_prod.tertiary_company_type_id IS NULL
	  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN company sc ON sc.company_sid = ps.supplier_company_sid  
	  LEFT JOIN TABLE(v_read_product_suppliers) read_sup ON read_sup.secondary_company_type_id = sc.company_type_id AND read_sup.tertiary_company_type_id IS NULL
	  LEFT JOIN TABLE(v_read_product_sup_of_sup) read_sos ON read_sos.secondary_company_type_id = pc.company_type_id AND read_sos.tertiary_company_type_id = sc.company_type_id
	  LEFT JOIN TABLE(v_read_prd_supp_mtrc_val) read_mvsup ON read_mvsup.secondary_company_type_id = sc.company_type_id AND read_mvsup.tertiary_company_type_id IS NULL
	  LEFT JOIN TABLE(v_read_prd_sos_mtrc_val) read_mvsos ON read_mvsos.secondary_company_type_id = pc.company_type_id AND read_mvsos.tertiary_company_type_id = sc.company_type_id
	 WHERE (in_parent_id IS NULL OR ps.product_supplier_id = in_parent_id)
	   -- Check read permission on the product itself
	   AND ((v_company_sid = owner.company_sid AND v_read_own_products = 1)
	     OR read_prod.primary_company_type_id IS NOT NULL
		 OR (ps.supplier_company_sid = v_company_sid AND v_products_as_suppliers = 1))
	   -- Check read permission on product_supplier
	   AND ((ps.supplier_company_sid = v_company_sid AND v_products_as_suppliers = 1)
	    OR (ps.purchaser_company_sid = v_company_sid AND read_sup.primary_company_type_id IS NOT NULL)
	    OR read_sos.primary_company_type_id IS NOT NULL)
	   -- Check read permission on product supplier metric
	   AND ((ps.supplier_company_sid = v_company_sid AND v_prd_sup_mtrc_as_supp = 1)
	    OR (ps.purchaser_company_sid = v_company_sid AND read_mvsup.primary_company_type_id IS NOT NULL)
	    OR read_mvsos.primary_company_type_id IS NOT NULL);

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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.ApplyBreadcrumb');

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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ psmv.supplier_product_metric_val_id product_supplier_metric_val_id, 
			   psmv.product_supplier_id, ps.product_supplier_ref,
			   ps.product_id, cp.product_name, cp.product_ref,
			   ps.purchaser_company_sid, pc.name purchaser_company_name,
			   ps.supplier_company_sid, sc.name supplier_company_name,
			   psmv.ind_sid, psmv.start_dtm, psmv.end_dtm, psmv.source_type,
			   i.description as product_metric, NVL(i.format_mask, m.format_mask) format_mask, 
			   psmv.val_number, CASE WHEN pm.show_measure = 1 THEN m.description END measure, 
			   psmv.entered_as_val_number, CASE WHEN pm.show_measure = 1 THEN NVL(mc.description, m.description) END entered_as_measure 
		  FROM product_supplier_metric_val psmv
		  JOIN TABLE(in_id_list) fil_list ON psmv.supplier_product_metric_val_id = fil_list.sid_id
		  JOIN product_supplier ps ON ps.product_supplier_id = psmv.product_supplier_id
		  JOIN v$company_product cp ON cp.product_id = ps.product_id
		  JOIN v$company pc ON pc.company_sid = ps.purchaser_company_sid
		  JOIN v$company sc ON sc.company_sid = ps.supplier_company_sid
		  JOIN product_metric pm ON psmv.ind_sid = pm.ind_sid
		  JOIN csr.v$ind i ON pm.ind_sid = i.ind_sid
		  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN csr.measure_conversion mc ON psmv.measure_conversion_id = mc.measure_conversion_id
		 WHERE pm.applies_to_prod_supplier = 1;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredPrdSuppMtrcIds (
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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.PageFilteredPrdSuppMtrcIds');

	IF in_order_by = 'startDtm' AND in_order_dir = 'DESC' THEN
		-- default query when you hit the page, use quick version
		-- without joins
		SELECT security.T_ORDERED_SID_ROW(supplier_product_metric_val_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.supplier_product_metric_val_id, ROWNUM rn
			  FROM (
				SELECT psmv.supplier_product_metric_val_id
				  FROM product_supplier_metric_val psmv
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = psmv.supplier_product_metric_val_id
				  JOIN csr.v$ind i ON psmv.ind_sid = i.ind_sid
				 ORDER BY psmv.start_dtm DESC, LOWER(i.description)
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(supplier_product_metric_val_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.supplier_product_metric_val_id, ROWNUM rn
			  FROM (
				SELECT psmv.supplier_product_metric_val_id
				  FROM product_supplier_metric_val psmv
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = psmv.supplier_product_metric_val_id
				  JOIN product_supplier ps ON ps.product_supplier_id = psmv.product_supplier_id
				  JOIN v$company_product cp ON cp.product_id = ps.product_id
				  JOIN v$company pc ON pc.company_sid = ps.purchaser_company_sid
				  JOIN v$company sc ON sc.company_sid = ps.supplier_company_sid
				  JOIN csr.v$ind i ON psmv.ind_sid = i.ind_sid
				  JOIN csr.measure m on i.measure_sid = m.measure_sid
				  LEFT JOIN csr.measure_conversion mc on psmv.measure_conversion_id = mc.measure_conversion_id
				 ORDER BY
					-- To avoid dyanmic SQL, do many case statements
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
						CASE (v_order_by)
							WHEN 'productSupplierMetricValId' THEN TO_CHAR(psmv.supplier_product_metric_val_id, '0000000000')
							WHEN 'productId' THEN TO_CHAR(cp.product_id, '0000000000')
							WHEN 'productName' THEN LOWER(cp.product_name)
							WHEN 'productRef' THEN LOWER(cp.product_ref)
							WHEN 'productSupplierId' THEN TO_CHAR(ps.product_supplier_id, '0000000000')
							WHEN 'productSupplierRef' THEN LOWER(ps.product_supplier_ref)
							WHEN 'purchaserCompanySid' THEN TO_CHAR(ps.purchaser_company_sid, '0000000000')
							WHEN 'purchaserCompanyName' THEN LOWER(pc.name)
							WHEN 'supplierCompanySid' THEN TO_CHAR(ps.supplier_company_sid, '0000000000')
							WHEN 'supplierCompanyName' THEN LOWER(sc.name)
							WHEN 'productMetric' THEN LOWER(i.description)
							WHEN 'startDtm' THEN TO_CHAR(psmv.start_dtm, 'YYYY-MM-DD')
							WHEN 'endDtm' THEN TO_CHAR(psmv.end_dtm, 'YYYY-MM-DD')
							WHEN 'valNumber' THEN TO_CHAR(psmv.val_number, '000000000000000000000000.0000000000')
							WHEN 'measure' THEN LOWER(m.description)
							WHEN 'enteredAsValNumber' THEN TO_CHAR(psmv.entered_as_val_number, '000000000000000000000000.0000000000')
							WHEN 'enteredAsMeasure' THEN LOWER(NVL(mc.description, m.description))
							WHEN 'sourceType' THEN TO_CHAR(psmv.source_type, '0000000000')
						END
					END ASC,
					CASE WHEN in_order_dir='DESC' THEN
						CASE (v_order_by)
							WHEN 'productSupplierMetricValId' THEN TO_CHAR(psmv.supplier_product_metric_val_id, '0000000000')
							WHEN 'productId' THEN TO_CHAR(cp.product_id, '0000000000')
							WHEN 'productName' THEN LOWER(cp.product_name)
							WHEN 'productRef' THEN LOWER(cp.product_ref)
							WHEN 'productSupplierId' THEN TO_CHAR(ps.product_supplier_id, '0000000000')
							WHEN 'productSupplierRef' THEN LOWER(ps.product_supplier_ref)
							WHEN 'purchaserCompanySid' THEN TO_CHAR(ps.purchaser_company_sid, '0000000000')
							WHEN 'purchaserCompanyName' THEN LOWER(pc.name)
							WHEN 'supplierCompanySid' THEN TO_CHAR(ps.supplier_company_sid, '0000000000')
							WHEN 'supplierCompanyName' THEN LOWER(sc.name)
							WHEN 'productMetric' THEN LOWER(i.description)
							WHEN 'startDtm' THEN TO_CHAR(psmv.start_dtm, 'YYYY-MM-DD')
							WHEN 'endDtm' THEN TO_CHAR(psmv.end_dtm, 'YYYY-MM-DD')
							WHEN 'valNumber' THEN TO_CHAR(psmv.val_number, '000000000000000000000000.0000000000')
							WHEN 'measure' THEN LOWER(m.description)
							WHEN 'enteredAsValNumber' THEN TO_CHAR(psmv.entered_as_val_number, '000000000000000000000000.0000000000')
							WHEN 'enteredAsMeasure' THEN LOWER(NVL(mc.description, m.description))
							WHEN 'sourceType' THEN TO_CHAR(psmv.source_type, '0000000000')
						END
					END DESC,
					-- if sorted by purchaser or supplier company name, sub-sort by the other one.
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
						CASE (v_order_by)
							WHEN 'purchaserCompanyName' THEN LOWER(sc.name)
							WHEN 'supplierCompanyName' THEN LOWER(pc.name)
						END
					END ASC,
					CASE WHEN in_order_dir='DESC' THEN
						CASE (v_order_by)
							WHEN 'purchaserCompanyName' THEN LOWER(sc.name)
							WHEN 'supplierCompanyName' THEN LOWER(pc.name)
						END
					END DESC,
					CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN psmv.start_dtm END DESC,
					CASE WHEN in_order_dir='DESC' THEN psmv.start_dtm END ASC,
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Product Supplier Metric -> '||v_name);

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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.GetList', in_compound_filter_id);

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

	PageFilteredPrdSuppMtrcIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

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
	v_log_id := filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.GetReportData', in_compound_filter_id);

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
	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
	v_log_id := chain.filter_pkg.StartDebugLog('chain.prdct_supp_mtrc_report_pkg.GetListAsExtension', in_compound_filter_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM chain.temp_grid_extension_map
		 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL
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
 *   o  Preserve existing duplicate IDs passed in (these are likely to have different group by values caused by overlapping values that need to be represented in charts)
 *  
 *  It's OK to return duplicate IDs if filter field values overlap. These duplicates are discounted for issue lists
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
		 WHERE pm.applies_to_prod_supplier = 1
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = pm.ind_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(psmv.supplier_product_metric_val_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier_metric_val psmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON psmv.supplier_product_metric_val_id = t.object_id
	  JOIN chain.filter_value fv ON psmv.ind_sid = fv.num_value
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
		SELECT MIN(psmv.start_dtm), MAX(psmv.start_dtm)
		  INTO v_min_date, v_max_date
		  FROM product_supplier_metric_val psmv
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON psmv.supplier_product_metric_val_id = t.object_id;
		
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(psmv.supplier_product_metric_val_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier_metric_val psmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON psmv.supplier_product_metric_val_id = t.object_id
	  JOIN chain.tt_filter_date_range dr 
	    ON (dr.start_dtm IS NULL OR psmv.end_dtm > dr.start_dtm)
	   AND (dr.end_dtm IS NULL OR psmv.start_dtm < dr.end_dtm);
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
			  SELECT DISTINCT psmv.val_number
				FROM product_supplier_metric_val psmv
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON psmv.supplier_product_metric_val_id = t.object_id
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
	
	SELECT chain.T_FILTERED_OBJECT_ROW(psmv.supplier_product_metric_val_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier_metric_val psmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON psmv.supplier_product_metric_val_id = t.object_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(psmv.val_number, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;

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
	
	SELECT chain.T_FILTERED_OBJECT_ROW(psmv.supplier_product_metric_val_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier_metric_val psmv
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON psmv.supplier_product_metric_val_id = t.object_id
	  JOIN chain.filter_value fv ON psmv.source_type = fv.num_value
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

PROCEDURE SupplierFilter (
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
		SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, NULL, NULL)
		  BULK COLLECT INTO v_ids
		  FROM product_supplier_metric_val psmv
		  JOIN TABLE(in_ids) ids ON ids.object_id = psmv.supplier_product_metric_val_id;

		product_supplier_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_ids,
			out_id_list						=> v_ids
		);

		SELECT T_FILTERED_OBJECT_ROW(supplier_product_metric_val_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT supplier_product_metric_val_id
			  FROM product_supplier_metric_val psmv
			  JOIN TABLE(in_ids) ids ON ids.object_id = psmv.supplier_product_metric_val_id
			  JOIN TABLE(v_ids) t ON psmv.product_supplier_id = t.object_id
		  );
	END IF;
END;

END prdct_supp_mtrc_report_pkg;
/
