CREATE OR REPLACE PACKAGE BODY chain.product_supplier_report_pkg AS

PARENT_TYPE_COMPANY					CONSTANT NUMBER := 1;
PARENT_TYPE_SUPPLYING_COMPANY		CONSTANT NUMBER := 2;
PARENT_TYPE_PURCHASING_COMPANY		CONSTANT NUMBER := 3;
PARENT_TYPE_PRODUCT					CONSTANT NUMBER := 4;

PROCEDURE FilterProductSupplierRef	(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActive				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSupplyingPeriod		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCurrentlySupplying	(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCertificationType	(in_cert_type_id IN certification_type.certification_type_id%TYPE, 
									 in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTagGroup			(in_tag_group_id IN	csr.tag_group.tag_group_id%TYPE, 
									 in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE FilterSavedFilter			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE PurchaserFilter			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE PurchaserFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE SupplierFilter			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE SupplierFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE ProductFilter				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE ProductFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);

PROCEDURE UNSEC_RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			compound_filter.compound_filter_id%TYPE;
	v_suffix_id						security_pkg.T_SID_ID;
	v_name							VARCHAR2(256);
BEGIN
	IF LOWER(in_name) = 'supplyingperiod' THEN
		FilterSupplyingPeriod(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'currentlysupplying' THEN
		FilterCurrentlySupplying(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'productsupplierref' THEN
		FilterProductSupplierRef(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'active' THEN
		FilterActive(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'certificationtype.%' THEN
		v_suffix_id :=  CAST(regexp_substr(in_name,'[0-9]+') AS NUMBER);
		FilterCertificationType(v_suffix_id, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'taggroup.%' THEN
		v_suffix_id :=  CAST(regexp_substr(in_name,'[0-9]+') AS NUMBER);
		FilterTagGroup(v_suffix_id, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'purchaserfilter' THEN
		PurchaserFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'purchaserfilter_%' THEN
		v_name := substr(in_name, 17);
		PurchaserFilterBreakdown(v_name, in_comparator, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'supplierfilter' THEN
		SupplierFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'supplierfilter_%' THEN
		v_name := substr(in_name, 16);
		SupplierFilterBreakdown(v_name, in_comparator, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'productfilter' THEN
		ProductFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'productfilter_%' THEN
		v_name := substr(in_name, 15);
		ProductFilterBreakdown(v_name, in_comparator, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'savedfilter' THEN
		FilterSavedFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_comparator, in_ids, out_ids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_name);
	END IF;
END;

PROCEDURE RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_comparator					IN	chain.filter_field.comparator%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	GetInitialIds(
		in_search					=> NULL,
		in_group_key				=> NULL,
		in_id_list					=> in_ids,
		out_id_list					=> v_ids
	);

	UNSEC_RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> in_column_sid,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_ids						=> v_ids,
		out_ids						=> out_ids
	);
END;

PROCEDURE FilterProductSupplierIds (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					T_FILTERED_OBJECT_TABLE;
	v_result_ids					T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_inner_log_id					debug_log.debug_log_id%TYPE;
	v_product_col_id				security_pkg.T_SID_ID;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.FilterProductSupplierIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.FilterProductSupplierIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		UNSEC_RunSingleUnit(
			in_name				=> r.name,
			in_comparator		=> r.comparator,
			in_column_sid		=> r.column_sid,
			in_filter_id		=> in_filter_id,
			in_filter_field_id	=> r.filter_field_id,
			in_group_by_index	=> r.group_by_index,
			in_show_all			=> r.show_all,
			in_ids				=> v_starting_ids,
			out_ids				=> v_result_ids
		);
		
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
	filter_pkg.RunCompoundFilter('FilterProductSupplierIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM tt_filter_object_data;
 
	INSERT INTO tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, filter_pkg.AFUNC_SUM,
			CASE a.column_value
				WHEN 1 THEN COUNT(DISTINCT ps.product_supplier_id)
			END
	  FROM product_supplier ps
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON ps.product_supplier_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	 GROUP BY l.object_id, a.column_value;

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE Search(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.Search');

	SELECT T_FILTERED_OBJECT_ROW(t.object_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM product_supplier ps
	  JOIN TABLE(in_id_list) t ON t.object_id = ps.product_supplier_id
	  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN company sc ON sc.company_sid = ps.supplier_company_sid  
	 WHERE (
			in_search IS NULL 
			OR CAST(ps.product_supplier_id AS VARCHAR2(20)) = TRIM(in_search)
			OR LOWER(ps.product_supplier_ref) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%'
			OR LOWER(pc.name) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%'
			OR CAST(pc.company_sid AS VARCHAR2(20)) = LTRIM(RTRIM(in_search))
			OR LOWER(sc.name) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%'
			OR CAST(sc.company_sid AS VARCHAR2(20)) = LTRIM(RTRIM(in_search))
	 );

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_visible_company_sids			security.T_SID_TABLE;
	v_products_as_suppliers			NUMBER := 0;
	v_read_own_products				NUMBER := 0;
	v_read_product					T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ);
	v_read_product_suppliers		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_read_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_READ);
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('csr.region_report_pkg.GetInitialIds');

	-- Three ways we can see a product_supplier, assuming we can see the companies in it
	-- We're the supplier, and we have PRODUCTS_AS_SUPPLIER
	-- We're the purchaser, and we have PRODUCT_SUPPLIERS
	-- We're neither, and we have PRODUCT_SUPPLIERS as a tertiary capability

	v_visible_company_sids := company_pkg.GetVisibleCompanySids;

	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
		v_read_own_products := 1;
	END IF;
	
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
		v_products_as_suppliers := 1;
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(ps.product_supplier_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM product_supplier ps
	  JOIN company_product cp ON cp.product_id = ps.product_id
	  JOIN company owner ON owner.company_sid = cp.company_sid
	  LEFT JOIN TABLE(v_read_product) read_prod ON read_prod.secondary_company_type_id = owner.company_type_id AND read_prod.tertiary_company_type_id IS NULL
	  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN TABLE(v_visible_company_sids) vp ON pc.company_sid = vp.column_value
	  JOIN company sc ON sc.company_sid = ps.supplier_company_sid  
	  JOIN TABLE(v_visible_company_sids) vs ON sc.company_sid = vs.column_value
	  LEFT JOIN TABLE(v_read_product_suppliers) read_sup ON read_sup.secondary_company_type_id = sc.company_type_id AND read_sup.tertiary_company_type_id IS NULL
	  LEFT JOIN TABLE(v_read_product_sup_of_sup) read_sos ON read_sos.secondary_company_type_id = pc.company_type_id AND read_sos.tertiary_company_type_id = sc.company_type_id
	 WHERE (
			in_parent_id IS NULL 
			OR (in_parent_type = PARENT_TYPE_PRODUCT AND ps.product_id = in_parent_id)
			OR (in_parent_type = PARENT_TYPE_COMPANY AND cp.company_sid = in_parent_id)
			OR (in_parent_type = PARENT_TYPE_SUPPLYING_COMPANY AND ps.supplier_company_sid = in_parent_id)
			OR (in_parent_type = PARENT_TYPE_PURCHASING_COMPANY AND ps.purchaser_company_sid = in_parent_id)
	 ) AND ( -- Check read permission on the product itself
			(v_company_sid = owner.company_sid AND v_read_own_products = 1)
			 OR read_prod.primary_company_type_id IS NOT NULL
			 OR (ps.supplier_company_sid = v_company_sid AND v_products_as_suppliers = 1)
	  
	 ) AND ( -- Check read permission on product_supplier
			(ps.supplier_company_sid = v_company_sid AND v_products_as_suppliers = 1)
			OR (ps.purchaser_company_sid = v_company_sid AND read_sup.primary_company_type_id IS NOT NULL)
			OR read_sos.primary_company_type_id IS NOT NULL
	 );

	IF in_search IS NOT NULL THEN
		Search(in_search, v_id_list, v_id_list);
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
				in_id_list						=> v_id_list,
				out_id_list						=> v_id_list
			);
		END LOOP;
	END IF;
	  
	out_id_list := v_id_list;
	
	filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
BEGIN	
	IF in_id_list_populated = 0 THEN
		-- Step 1, get initial set of ids
		GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_parent_type, in_parent_id, in_start_dtm, in_end_dtm, in_date_col_type, in_id_list, v_id_list);
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(id, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM tt_filter_id;
	END IF;
	
	-- If there's a filter, restrict the list of ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN
		RunCompoundFilter(in_compound_filter_id, 0, NULL, v_id_list, v_id_list);
	END IF;
	
	out_id_list := v_id_list;
END;

PROCEDURE ApplyBreadcrumb(
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_breadcrumb					IN	security_pkg.T_SID_IDS,
	in_aggregation_type				IN	NUMBER DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_breadcrumb_count				NUMBER;
	v_field_compound_filter_id		NUMBER;
	v_top_n_values					security.T_ORDERED_SID_TABLE; -- not sids, but this exists already
	v_aggregation_types				security.T_SID_TABLE;
	v_temp							T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.ApplyBreadcrumb');
	
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
	in_id_list						IN  security.T_ORDERED_SID_TABLE,
	out_cur 						OUT SYS_REFCURSOR,
	out_cert_reqs_cur 				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR
)
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_root_type_id					product_type.product_type_id%TYPE := product_type_pkg.GetRootProductType;
	v_products_as_suppliers			NUMBER := 0;
	v_write_product_suppliers		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS, security.security_pkg.PERMISSION_WRITE);
	v_add_product_suppliers			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.ADD_PRODUCT_SUPPLIER);
	v_add_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.ADD_PRODUCT_SUPPS_OF_SUPPS);
	v_read_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_READ);
	v_write_product_sup_of_sup		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIERS_OF_SUPPLIERS, security.security_pkg.PERMISSION_WRITE);
	v_read_prod_supp_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security.security_pkg.PERMISSION_READ);
	v_write_prod_supp_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security.security_pkg.PERMISSION_WRITE);
	v_read_prod_sup_of_sup_certs	T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security.security_pkg.PERMISSION_READ);
	v_write_prod_sup_of_sup_certs	T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security.security_pkg.PERMISSION_WRITE);
	v_read_prd_supp_mtrc_val		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL, security.security_pkg.PERMISSION_READ);
	v_write_prd_supp_mtrc_val		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL, security.security_pkg.PERMISSION_WRITE);
	v_read_prd_sos_mtrc_val			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_SUPP, security.security_pkg.PERMISSION_READ);
	v_write_prd_sos_mtrc_val		T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_SUPP, security.security_pkg.PERMISSION_WRITE);
	v_read_prd_sup_mtrc_as_supp		NUMBER := 0;
	v_write_prd_sup_mtrc_as_supp	NUMBER := 0;
	v_product_ids					security.T_SID_TABLE;
	v_cert_type_ids					security.T_SID_TABLE;
	v_product_company_sids			security.T_SID_TABLE;
	v_supplier_certs				T_OBJECT_CERTIFICATION_TABLE;
	v_filter_id_list				T_FILTERED_OBJECT_TABLE;
BEGIN
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_READ) THEN
		v_read_prd_sup_mtrc_as_supp := 1;
		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRD_SUPP_METRIC_VAL_AS_SUPP, security.security_pkg.PERMISSION_WRITE) THEN
			v_write_prd_sup_mtrc_as_supp := 1;
		END IF;
	END IF;

	OPEN out_cur FOR
	    WITH purchaser_counts AS (
				SELECT ps.purchaser_company_sid, count(*) num_suppliers, sum(is_active) num_active_suppliers
				  FROM product_supplier ps
				  JOIN TABLE(in_id_list) t ON t.sid_id = ps.product_supplier_id
				 GROUP BY purchaser_company_sid
		), supplier_counts AS (
				SELECT ps.supplier_company_sid, count(*) num_suppliers, sum(is_active) num_active_suppliers
				  FROM product_supplier ps
				  JOIN TABLE(in_id_list) t ON t.sid_id = ps.product_supplier_id
				 GROUP BY supplier_company_sid
		)

		-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
		SELECT ps.product_supplier_id, ps.product_supplier_ref,
			   cp.product_id, cp.product_name, cp.product_ref,
			   cp.company_sid product_company_sid, c.name product_company_name,
			   pt.product_type_id, NVL(pt_tree.tree_path, pt.description) product_type_name,
			   ps.purchaser_company_sid, pc.name purchaser_company_name,
			   ps.supplier_company_sid, sc.name supplier_company_name,
			   ps.start_dtm, ps.end_dtm, ps.is_active,
			   CASE WHEN
					(ps.supplier_company_sid = v_company_sid AND v_products_as_suppliers = 1)
					OR write_sup.primary_company_type_id IS NOT NULL
					OR write_sos.primary_company_type_id IS NOT NULL
			   THEN 0 ELSE 1 END read_only,
			   CASE WHEN 
					(
						add_sup.primary_company_type_id IS NOT NULL
						OR add_sos.primary_company_type_id IS NOT NULL
					)
					AND 
					(
						NVL(child_counts.num_suppliers, 0) = 0 
						OR NVL(spouse_counts.num_suppliers, 0) > 1
					)
				THEN 1 ELSE 0 END can_delete,
				CASE WHEN
					ps.is_active = 1
					AND
					(
						write_sup.primary_company_type_id IS NOT NULL
						OR write_sos.primary_company_type_id IS NOT NULL
					)
					AND 
					(
						NVL(child_counts.num_active_suppliers, 0) = 0 
						OR NVL(spouse_counts.num_active_suppliers, 0) > 1
					)
				THEN 1 ELSE 0 END can_deactivate,
				CASE WHEN
					ps.is_active = 0
					AND
					(
						write_sup.primary_company_type_id IS NOT NULL
						OR write_sos.primary_company_type_id IS NOT NULL
					)
					AND 
					(
						NVL(parent_counts.num_active_suppliers, 0) > 0 
						OR NVL(parent_counts.num_suppliers, 0) = 0
					)
				THEN 1 ELSE 0 END can_reactivate,
				CASE WHEN
						read_sup_certs.primary_company_type_id IS NOT NULL
						OR read_sos_certs.primary_company_type_id IS NOT NULL
				THEN 1 ELSE 0 END can_view_certifications,
				CASE WHEN
						write_sup_certs.primary_company_type_id IS NOT NULL
						OR write_sos_certs.primary_company_type_id IS NOT NULL
				THEN 1 ELSE 0 END can_add_certifications,
				CASE WHEN 
						(ps.supplier_company_sid = v_company_sid AND v_read_prd_sup_mtrc_as_supp = 1)
						OR (ps.purchaser_company_sid = v_company_sid AND read_mvsup.primary_company_type_id IS NOT NULL)
						OR read_mvsos.primary_company_type_id IS NOT NULL
				THEN 1 ELSE 0 END can_view_prd_supp_mtrc_vals,
				CASE WHEN 
						(ps.supplier_company_sid = v_company_sid AND v_write_prd_sup_mtrc_as_supp = 1)
						OR (ps.purchaser_company_sid = v_company_sid AND write_mvsup.primary_company_type_id IS NOT NULL)
						OR write_mvsos.primary_company_type_id IS NOT NULL
				THEN 1 ELSE 0 END can_set_prd_supp_mtrc_vals
		  FROM product_supplier ps
		  JOIN v$company_product cp ON cp.product_id = ps.product_id
		  JOIN chain.v$product_type pt ON pt.product_type_id = cp.product_type_id
		  LEFT JOIN (
				SELECT product_type_id, LEVEL tree_level, REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description, ''), ''), '', ' / ') tree_path
				  FROM chain.v$product_type
				 START WITH parent_product_type_id = v_root_type_id
			   CONNECT BY parent_product_type_id = PRIOR product_type_id
		  ) pt_tree ON pt_tree.product_type_id = pt.product_type_id
		  JOIN TABLE(in_id_list) t ON t.sid_id = ps.product_supplier_id
		  JOIN company c ON c.company_sid = cp.company_sid
		  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
		  JOIN company sc ON sc.company_sid = ps.supplier_company_sid
		  LEFT JOIN TABLE(v_write_product_suppliers) write_sup ON write_sup.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_add_product_suppliers) add_sup ON add_sup.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_read_prod_supp_certs) read_sup_certs ON read_sup_certs.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_write_prod_supp_certs) write_sup_certs ON write_sup_certs.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_write_product_sup_of_sup) write_sos ON write_sos.secondary_company_type_id = pc.company_type_id AND write_sos.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
		  LEFT JOIN TABLE(v_add_product_sup_of_sup) add_sos ON add_sos.secondary_company_type_id = pc.company_type_id AND add_sos.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
		  LEFT JOIN TABLE(v_read_prod_sup_of_sup_certs) read_sos_certs ON read_sos_certs.secondary_company_type_id = pc.company_type_id AND read_sos_certs.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
		  LEFT JOIN TABLE(v_write_prod_sup_of_sup_certs) write_sos_certs ON write_sos_certs.secondary_company_type_id = pc.company_type_id AND write_sos_certs.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
		  LEFT JOIN TABLE(v_read_prd_supp_mtrc_val) read_mvsup ON read_mvsup.secondary_company_type_id = sc.company_type_id AND read_mvsup.tertiary_company_type_id IS NULL
		  LEFT JOIN TABLE(v_write_prd_supp_mtrc_val) write_mvsup ON write_mvsup.secondary_company_type_id = sc.company_type_id AND write_mvsup.tertiary_company_type_id IS NULL
		  LEFT JOIN TABLE(v_read_prd_sos_mtrc_val) read_mvsos ON read_mvsos.secondary_company_type_id = pc.company_type_id AND read_mvsos.tertiary_company_type_id = sc.company_type_id
		  LEFT JOIN TABLE(v_write_prd_sos_mtrc_val) write_mvsos ON write_mvsos.secondary_company_type_id = pc.company_type_id AND write_mvsos.tertiary_company_type_id = sc.company_type_id
		  LEFT JOIN purchaser_counts child_counts ON child_counts.purchaser_company_sid = ps.supplier_company_sid
		  LEFT JOIN supplier_counts parent_counts ON parent_counts.supplier_company_sid = ps.purchaser_company_sid
		  LEFT JOIN supplier_counts spouse_counts ON spouse_counts.supplier_company_sid = ps.supplier_company_sid
		 ORDER BY t.pos;

	OPEN out_tags_cur FOR
		SELECT pst.product_supplier_id, pst.tag_group_id, pst.tag_id, t.tag
		  FROM product_supplier_tag pst
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = pst.product_supplier_id
		  JOIN csr.v$tag t ON t.tag_id = pst.tag_id
		  JOIN csr.tag_group_member tgm ON tgm.tag_group_id = pst.tag_group_id AND tgm.tag_id = pst.tag_id
		 ORDER BY tgm.pos, LOWER(t.tag);

	-- You can only view the certifications if you have that capability on the company in question.

	SELECT T_FILTERED_OBJECT_ROW(ps.product_supplier_id, NULL, NULL)
	  BULK COLLECT INTO v_filter_id_list
	  FROM product_supplier ps
	  JOIN TABLE(in_id_list) t ON t.sid_id = ps.product_supplier_id
	  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN company sc ON sc.company_sid = ps.supplier_company_sid
	  LEFT JOIN TABLE(v_read_prod_supp_certs) read_sup_certs ON read_sup_certs.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_prod_sup_of_sup_certs) read_sos_certs ON read_sos_certs.secondary_company_type_id = pc.company_type_id AND read_sos_certs.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
	 WHERE read_sup_certs.primary_company_type_id IS NOT NULL
	    OR read_sos_certs.primary_company_type_id IS NOT NULL;
	
	SELECT certification_type_id
	  BULK COLLECT INTO v_cert_type_ids
	  FROM certification_type;
	
	v_supplier_certs := company_product_pkg.GetReqdSupplierCerts(v_filter_id_list, v_cert_type_ids);

	OPEN out_cert_reqs_cur FOR
		SELECT ps.product_id, ps.product_supplier_id, 
			   ct.certification_type_id, ct.label certificate_type_label, 
			   NVL(t.is_certified, 0) is_certified
		  FROM product_supplier ps
		  JOIN TABLE(v_filter_id_list) fil_list ON fil_list.object_id = ps.product_supplier_id
		  JOIN company_product_required_cert cprc ON cprc.product_id = ps.product_id
		  JOIN certification_type ct ON ct.certification_type_id = cprc.certification_type_id
		  LEFT JOIN TABLE(v_supplier_certs) t ON t.object_id = ps.product_supplier_id AND t.certification_type_id = cprc.certification_type_id;
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
	v_order_by						VARCHAR2(255);
	v_order_by_id	 				NUMBER;
	v_product_ids					security.T_SID_TABLE;
	v_cert_type_ids					security.T_SID_TABLE;
	v_cert_reqs						T_OBJECT_CERTIFICATION_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_view_certifications			security.T_SID_TABLE;
	v_product_company_sids			security.T_SID_TABLE;
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_view_cert_types				T_PERMISSIBLE_TYPES_TABLE;
	v_root_type_id					product_type.product_type_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.PageFilteredIds');

	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
	
	IF v_order_by = 'certificationRequirement' THEN
		v_view_cert_types := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.VIEW_CERTIFICATIONS);
		SELECT certification_type_id
		  BULK COLLECT INTO v_cert_type_ids
		  FROM certification_type
		 WHERE certification_type_id = v_order_by_id;
	
		v_cert_reqs := company_product_pkg.GetReqdSupplierCerts(in_id_list, v_cert_type_ids);

		SELECT security.T_ORDERED_SID_ROW(product_supplier_id, rn)
			BULK COLLECT INTO out_id_list
				FROM (
				SELECT x.product_supplier_id, ROWNUM rn
					FROM (
					SELECT ps.product_supplier_id
						FROM product_supplier ps
						JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = ps.product_supplier_id
						LEFT JOIN company_product_required_cert cprc ON cprc.product_id = ps.product_id AND cprc.certification_type_id = v_order_by_id
						LEFT JOIN TABLE (v_cert_reqs) t ON t.object_id = ps.product_supplier_id
						ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN t.is_certified END ASC,
							CASE WHEN in_order_dir='DESC' THEN t.is_certified END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cprc.certification_type_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN cprc.certification_type_id END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN ps.product_supplier_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN ps.product_supplier_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
				WHERE rn > in_start_row;
	ELSIF v_order_by = 'productTypeName' THEN
		v_root_type_id := product_type_pkg.GetRootProductType;

		-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
		SELECT security.T_ORDERED_SID_ROW(product_supplier_id, rn)
			BULK COLLECT INTO out_id_list
				FROM (
				SELECT x.product_supplier_id, ROWNUM rn
					FROM (
					  SELECT ps.product_supplier_id
					    FROM product_supplier ps
					    JOIN v$company_product cp ON cp.product_id = ps.product_id
						JOIN v$product_type pt ON pt.product_type_id = cp.product_type_id
						LEFT JOIN (
							SELECT product_type_id, LEVEL tree_level, REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description, ''), ''), '', ' / ') tree_path
							  FROM chain.v$product_type
							 START WITH parent_product_type_id = v_root_type_id
						   CONNECT BY parent_product_type_id = PRIOR product_type_id
						) pt_tree ON pt_tree.product_type_id = pt.product_type_id
					    JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = ps.product_supplier_id
						ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN NVL(pt_tree.tree_path, pt.description) END ASC,
							CASE WHEN in_order_dir='DESC' THEN NVL(pt_tree.tree_path, pt.description) END DESC,
							-- If you're sorting by product type, you probably also want suppliers of the same product to go together
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cp.product_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN cp.product_id END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN ps.product_supplier_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN ps.product_supplier_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
				WHERE rn > in_start_row;
	ELSE
		SELECT security.T_ORDERED_SID_ROW(product_supplier_id, rn)
			BULK COLLECT INTO out_id_list
				FROM (
				SELECT x.product_supplier_id, ROWNUM rn
					FROM (
					SELECT ps.product_supplier_id
					  FROM product_supplier ps
					  JOIN v$company_product cp ON cp.product_id = ps.product_id
					  JOIN company c ON c.company_sid = cp.company_sid
					  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
					  JOIN company sc ON sc.company_sid = ps.supplier_company_sid
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = ps.product_supplier_id
					 ORDER BY
						-- To avoid dyanmic SQL, do many case statements
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
							CASE (v_order_by)
								WHEN 'productSupplierRef' THEN LOWER(ps.product_supplier_ref)
								WHEN 'productName' THEN LOWER(cp.product_name)
								WHEN 'productRef' THEN LOWER(cp.product_ref)
								WHEN 'productCompanyName' THEN LOWER(c.name)
								WHEN 'purchaserCompanyName' THEN LOWER(pc.name)
								WHEN 'supplierCompanyName' THEN LOWER(sc.name)
								WHEN 'startDtm' THEN LOWER(ps.start_dtm)
								WHEN 'endDtm' THEN LOWER(ps.end_dtm)
								WHEN 'isActive' THEN TO_CHAR(ps.is_active)
							END
						END ASC,
						CASE WHEN in_order_dir='DESC' THEN
							CASE (v_order_by)
								WHEN 'productSupplierRef' THEN LOWER(ps.product_supplier_ref)
								WHEN 'productName' THEN LOWER(cp.product_name)
								WHEN 'productRef' THEN LOWER(cp.product_ref)
								WHEN 'productCompanyName' THEN LOWER(c.name)
								WHEN 'purchaserCompanyName' THEN LOWER(pc.name)
								WHEN 'supplierCompanyName' THEN LOWER(sc.name)
								WHEN 'startDtm' THEN LOWER(ps.start_dtm)
								WHEN 'endDtm' THEN LOWER(ps.end_dtm)
								WHEN 'isActive' THEN TO_CHAR(ps.is_active)
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
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN ps.product_supplier_id END ASC,
						CASE WHEN in_order_dir='DESC' THEN ps.product_supplier_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
				WHERE rn > in_start_row;
	END IF;
	
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Product Supplier -> '||v_name);

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
	out_cur 						OUT SYS_REFCURSOR,
	out_cert_reqs_cur 				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.GetList', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_date_col_type		=> in_date_col_type,
		out_id_list				=> v_id_list
	);

	ApplyBreadcrumb(v_id_list, in_breadcrumb, in_aggregation_type, v_id_list);

	-- Get the total number of rows (to work out number of pages)

	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);

	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	CollectSearchResults(v_id_page, out_cur, out_cert_reqs_cur, out_tags_cur);

	filter_pkg.EndDebugLog(v_log_id);
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
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.GetReportData', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
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

	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_PROD_SUPPLIER, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
		SELECT 1 AS object_id
		  FROM DUAL
		 WHERE 1 = 0;
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
	out_cur 						OUT SYS_REFCURSOR,
	out_cert_reqs_cur				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_groups						security_pkg.T_OUTPUT_CUR;
BEGIN

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_compound_filter_id	=> in_compound_filter_id,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
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

	CollectSearchResults(v_id_page, out_cur, out_cert_reqs_cur, out_tags_cur);

END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN compound_filter.compound_filter_id%TYPE,
	out_cur 						OUT SYS_REFCURSOR,
	out_cert_reqs_cur				OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_supplier_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM temp_grid_extension_map
		 WHERE linked_type = filter_pkg.FILTER_TYPE_PROD_SUPPLIER
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
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_cert_reqs_cur	=> out_cert_reqs_cur,
		out_tags_cur		=> out_tags_cur
	);
	
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

PROCEDURE FilterProductSupplierRef (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN product_supplier ps ON ps.product_supplier_id = t.object_id
	  JOIN filter_value fv ON LOWER(ps.product_supplier_ref) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterActive (
	in_filter_id					IN filter.filter_id%TYPE,
	in_filter_field_id				IN NUMBER,
	in_group_by_index				IN NUMBER,
	in_show_all						IN NUMBER,
	in_ids							IN T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, f.is_active, f.description
		  FROM (
			SELECT 1 is_active, 'Active' description FROM dual
			UNION ALL SELECT 0, 'Inactive' FROM dual
		  ) f
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = f.is_active
		 );		
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) t ON t.object_id = ps.product_supplier_id
	  JOIN filter_value fv ON fv.num_value = ps.is_active 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCurrentlySupplying (
	in_filter_id					IN filter.filter_id%TYPE,
	in_filter_field_id				IN NUMBER,
	in_group_by_index				IN NUMBER,
	in_show_all						IN NUMBER,
	in_ids							IN T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, in_group_by_index, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT ps.product_supplier_id
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) t ON t.object_id = ps.product_supplier_id
		 WHERE TRUNC(ps.start_dtm) <= TRUNC(SYSDATE)
		   AND (ps.end_dtm IS NULL OR TRUNC(ps.end_dtm) >= TRUNC(SYSDATE))
	);
END;

PROCEDURE FilterSupplyingPeriod (
	in_filter_id					IN filter.filter_id%TYPE,
	in_filter_field_id				IN NUMBER,
	in_group_by_index				IN NUMBER,
	in_show_all						IN NUMBER,
	in_ids							IN T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(ps.start_dtm), MAX(NVL(ps.end_dtm, SYSDATE))
		  INTO v_min_date, v_max_date
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) t ON t.object_id = ps.product_supplier_id;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);		
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, in_group_by_index, filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT ps.product_supplier_id, dr.filter_value_id
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) t ON t.object_id = ps.product_supplier_id
		  JOIN tt_filter_date_range dr
		    ON (TRUNC(ps.start_dtm) <= NVL(dr.end_dtm, TRUNC(ps.start_dtm))
		   AND (ps.end_dtm IS NULL OR TRUNC(ps.end_dtm) >= NVL(dr.start_dtm, TRUNC(ps.end_dtm))))
	);
END;

PROCEDURE FilterCertificationType(
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE,
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_cert_type_ids					security.T_SID_TABLE;
	v_read_prod_supp_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security.security_pkg.PERMISSION_READ);
	v_read_prod_sup_of_sup_certs	T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security.security_pkg.PERMISSION_READ);
	v_filter_id_list				T_FILTERED_OBJECT_TABLE;
	v_supplier_certs				T_OBJECT_CERTIFICATION_TABLE;
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.open_ncs, o.description
		  FROM (
			SELECT 1 open_ncs, 'Fully certified' description FROM dual
			UNION ALL SELECT 0, 'Not fully certified' FROM dual
			UNION ALL SELECT 2, 'No certification required' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.open_ncs
		 );
	END IF;

	UPDATE chain.filter_value
	   SET pos = 1
	 WHERE num_value = 1
	   AND (pos IS NULL OR pos != 1)
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET pos = 2
	 WHERE num_value = 0
	   AND (pos IS NULL OR pos != 2)
	   AND filter_field_id = in_filter_field_id;
	   
	UPDATE chain.filter_value
	   SET pos = 3
	 WHERE num_value = 2
	   AND (pos IS NULL OR pos != 3)
	   AND filter_field_id = in_filter_field_id;
	   
	-- GetReqdSupplierCerts will do this check again, but we do it here so that we can distinguish
	-- between is_certified being NULL because there's no certification requirement, and is_certified
	-- being NULL because we don't have permission to see product supplier certifications.

	SELECT T_FILTERED_OBJECT_ROW(ps.product_supplier_id, NULL, NULL)
	  BULK COLLECT INTO v_filter_id_list
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) t ON t.object_id = ps.product_supplier_id
	  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
	  JOIN company sc ON sc.company_sid = ps.supplier_company_sid
	  LEFT JOIN TABLE(v_read_prod_supp_certs) read_sup_certs ON read_sup_certs.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_prod_sup_of_sup_certs) read_sos_certs ON read_sos_certs.secondary_company_type_id = pc.company_type_id AND read_sos_certs.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
	 WHERE read_sup_certs.primary_company_type_id IS NOT NULL
	    OR read_sos_certs.primary_company_type_id IS NOT NULL;

	SELECT certification_type_id
	  BULK COLLECT INTO v_cert_type_ids
	  FROM certification_type
	 WHERE certification_type_id = in_cert_type_id;

	v_supplier_certs := company_product_pkg.GetReqdSupplierCerts(v_filter_id_list, v_cert_type_ids);

	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(v_filter_id_list)) t
	  LEFT JOIN company_product_required_cert cprc ON cprc.product_id = t.object_id AND cprc.certification_type_id = in_cert_type_id
	  LEFT JOIN TABLE(v_supplier_certs) reqs ON reqs.object_id = t.object_id AND reqs.certification_type_id = cprc.certification_type_id
	  JOIN chain.filter_value fv ON (
			(fv.num_value = 1 AND reqs.is_certified = 1) OR
			(fv.num_value = 0 AND reqs.is_certified IS NULL AND cprc.product_id IS NOT NULL) OR
			(fv.num_value = 2 AND reqs.is_certified IS NULL AND cprc.product_id IS NULL)
	   )
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterTagGroup (
	in_tag_group_id					IN  csr.tag_group.tag_group_id%TYPE,
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		chain.filter_pkg.ShowAllTags(in_filter_field_id, in_tag_group_id);
	END IF;

	WITH group_tags AS (
		SELECT pst.app_sid, pst.product_supplier_id, pst.tag_id
		  FROM product_supplier_tag pst
		  JOIN csr.tag_group_member tgm ON tgm.app_sid = pst.app_sid AND tgm.tag_id = pst.tag_id
		 WHERE tgm.tag_group_id = in_tag_group_id)
	SELECT chain.T_FILTERED_OBJECT_ROW(ps.product_supplier_id, ff.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier ps
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ps.product_supplier_id = t.object_id
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	  JOIN chain.filter_field ff ON ff.filter_field_id = fv.filter_field_id AND ff.app_sid = fv.app_sid
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(ps.app_sid, ps.product_supplier_id) NOT IN (SELECT app_sid, product_supplier_id FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(ps.app_sid, ps.product_supplier_id) IN (
				SELECT app_sid, product_supplier_id
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  filter.filter_id%TYPE,
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

PROCEDURE PurchaserFilter (
	in_filter_id IN filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_group_by_index IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN T_FILTERED_OBJECT_TABLE,
	out_ids OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_company_sids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(ps.purchaser_company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_sids
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) t ON ps.product_supplier_id = t.object_id;
		
		company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_sids,
			out_id_list						=> v_company_sids
		);
		
		SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT product_supplier_id
			  FROM product_supplier ps
			  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_supplier_id
			  JOIN TABLE(v_company_sids) t ON ps.purchaser_company_sid = t.object_id
		  );
	END IF;
END;

PROCEDURE PurchaserFilterBreakdown (
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
	SELECT T_FILTERED_OBJECT_ROW(ps.purchaser_company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) t ON ps.product_supplier_id = t.object_id;
	
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
		  
	SELECT T_FILTERED_OBJECT_ROW(ps.product_supplier_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_supplier_id
	  JOIN TABLE(v_company_sids) t ON ps.purchaser_company_sid = t.object_id;
END;

PROCEDURE SupplierFilter (
	in_filter_id IN filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_group_by_index IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN T_FILTERED_OBJECT_TABLE,
	out_ids OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_company_sids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(ps.supplier_company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_sids
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) t ON ps.product_supplier_id = t.object_id;
		
		company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_sids,
			out_id_list						=> v_company_sids
		);
		
		SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT product_supplier_id
			  FROM product_supplier ps
			  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_supplier_id
			  JOIN TABLE(v_company_sids) t ON ps.supplier_company_sid = t.object_id
		  );
	END IF;
END;

PROCEDURE SupplierFilterBreakdown (
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
	SELECT T_FILTERED_OBJECT_ROW(ps.supplier_company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) t ON ps.product_supplier_id = t.object_id;
	
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
		  
	SELECT T_FILTERED_OBJECT_ROW(ps.product_supplier_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_supplier_id
	  JOIN TABLE(v_company_sids) t ON ps.supplier_company_sid = t.object_id;
END;

PROCEDURE ProductFilter (
	in_filter_id IN filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_group_by_index IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN T_FILTERED_OBJECT_TABLE,
	out_ids OUT T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_product_ids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(ps.product_id, NULL, NULL)
		  BULK COLLECT INTO v_product_ids
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) t ON ps.product_supplier_id = t.object_id;
		
		product_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_product_ids,
			out_id_list						=> v_product_ids
		);
		
		SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT product_supplier_id
			  FROM product_supplier ps
			  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_supplier_id
			  JOIN TABLE(v_product_ids) t ON ps.product_id = t.object_id
		  );
	END IF;
END;

PROCEDURE ProductFilterBreakdown (
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
	v_product_ids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(ps.product_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_product_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) t ON ps.product_supplier_id = t.object_id;
	
	product_report_pkg.RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> NULL,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_ids						=> v_product_ids,
		out_ids						=> v_product_ids
	);
		  
	SELECT T_FILTERED_OBJECT_ROW(ps.product_supplier_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_supplier_id
	  JOIN TABLE(v_product_ids) t ON ps.product_id = t.object_id;
END;

END product_supplier_report_pkg;
/