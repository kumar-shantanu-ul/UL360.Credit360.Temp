CREATE OR REPLACE PACKAGE BODY CHAIN.product_report_pkg AS

PARENT_TYPE_COMPANY					CONSTANT NUMBER := 1;
PARENT_TYPE_SUPPLYING_COMPANY		CONSTANT NUMBER := 2;
PARENT_TYPE_PURCHASING_COMPANY		CONSTANT NUMBER := 3;

PROCEDURE FilterProductType			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProductName			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterProductRef			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActive				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE FilterCertificationType	(in_cert_type_id IN	certification_type.certification_type_id%TYPE, 
									 in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE FilterTagGroup			(in_tag_group_id IN	csr.tag_group.tag_group_id%TYPE, 
									 in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE); 
PROCEDURE CompanyFilter				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE CompanyFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE SupplierFilter			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE SupplierFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);

PROCEDURE UNSEC_RunSingleUnit (
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
	v_compound_filter_id			compound_filter.compound_filter_id%TYPE;
	v_suffix_id						security_pkg.T_SID_ID;
	v_name							VARCHAR2(256);
BEGIN
	IF in_name LIKE 'CmsFilter.%' THEN
		v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
		cms.filter_pkg.FilterColumnIds(in_filter_id, in_filter_field_id, v_compound_filter_id, in_column_sid, in_ids, out_ids);
	ELSIF in_name = 'ProductName' THEN
		FilterProductName(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF in_name = 'ProductRef' THEN
		FilterProductRef(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF in_name = 'ProductType' THEN
		FilterProductType(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'active' THEN
		FilterActive(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'certificationtype.%' THEN
		v_suffix_id :=  CAST(regexp_substr(in_name,'[0-9]+') AS NUMBER);
		FilterCertificationType(v_suffix_id, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'taggroup.%' THEN
		v_suffix_id :=  CAST(regexp_substr(in_name,'[0-9]+') AS NUMBER);
		FilterTagGroup(v_suffix_id, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'companyfilter' THEN
		CompanyFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'companyfilter_%' THEN
		v_name := substr(in_name, 15);
		CompanyFilterBreakdown(v_name, in_comparator, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) = 'supplierfilter' THEN
		SupplierFilter(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
	ELSIF LOWER(in_name) LIKE 'supplierfilter_%' THEN
		v_name := substr(in_name, 16);
		SupplierFilterBreakdown(v_name, in_comparator, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_ids, out_ids);
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

PROCEDURE FilterIds (
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
	
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

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
	filter_pkg.RunCompoundFilter('FilterIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM tt_filter_object_data;
 
	INSERT INTO tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT agg.column_value, l.object_id, filter_pkg.AFUNC_SUM,
			CASE agg.column_value
				WHEN AGG_TYPE_COUNT THEN COUNT(DISTINCT cp.product_id)
			END
	  FROM v$company_product cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON cp.product_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) agg
	 GROUP BY l.object_id, agg.column_value;

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
	v_log_id := filter_pkg.StartDebugLog('csr.region_report_pkg.Search');

	SELECT T_FILTERED_OBJECT_ROW(t.object_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM TABLE(in_id_list) t
	  JOIN v$company_product cp ON cp.product_id = t.object_id
	  JOIN v$product_type pt ON pt.product_type_id = cp.product_type_id
	  JOIN v$company c ON cp.company_sid = c.company_sid
	 WHERE (
			in_search IS NULL 
			OR CAST(cp.product_id AS VARCHAR2(20)) = TRIM(in_search)
			OR LOWER(cp.product_name) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(cp.product_ref) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(pt.description) LIKE '%'||LOWER(in_search)||'%'
			OR LOWER(c.name) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%'
			OR CAST(c.company_sid AS VARCHAR2(20)) = LTRIM(RTRIM(in_search))
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
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_has_products					NUMBER;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_products_as_supplier			NUMBER := 0;
	v_owner_company_sids			security.T_SID_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.GetInitialIds');
	
	v_owner_company_sids := type_capability_pkg.GetPermissibleCompanySids(chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ);
	
	-- GetPermissibleCompanySids only got us the suppliers	
	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
		v_owner_company_sids.extend;
		v_owner_company_sids(v_owner_company_sids.COUNT) := v_company_sid;
	END IF;

	IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS_AS_SUPPLIER) THEN
		v_products_as_supplier := 1;
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(product_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		  SELECT DISTINCT cp.product_id
		  FROM company_product cp
		  LEFT JOIN TABLE(v_owner_company_sids) owner_perm ON owner_perm.column_value = cp.company_sid
		  LEFT JOIN product_supplier ps ON ps.product_id = cp.product_id
		  WHERE (
				owner_perm.column_value IS NOT NULL
				OR (v_products_as_supplier = 1 AND ps.supplier_company_sid = v_company_sid)
		  ) AND (
				in_parent_type IS NULL
				OR (in_parent_type = PARENT_TYPE_COMPANY AND cp.company_sid = in_parent_id)
				OR (in_parent_type = PARENT_TYPE_SUPPLYING_COMPANY AND ps.supplier_company_sid = in_parent_id)
				OR (in_parent_type = PARENT_TYPE_PURCHASING_COMPANY AND ps.purchaser_company_sid = in_parent_id)
		  )
	  );

	IF NVL(in_pre_filter_sid, 0) > 0 THEN -- XPJ passes round zero for some reason?
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM saved_filter sf
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

	IF in_search IS NOT NULL THEN
		Search(in_search, v_id_list, v_id_list);
	END IF;
	  
	out_id_list := v_id_list;
	
	filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
END;

PROCEDURE INTERNAL_GetFilteredIds(
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
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_log_id						debug_log.debug_log_id%TYPE;
	v_has_products					NUMBER;
	v_product_ids					security.T_SID_TABLE;
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
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, v_id_list, v_id_list);
	END IF;
	
	out_id_list := v_id_list;
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
	in_id_list_populated			IN  NUMBER DEFAULT 0,
	in_id_list						IN  T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	INTERNAL_GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
		in_parent_type			=> in_parent_type,
		in_parent_id			=> in_parent_id,
		in_group_key			=> in_group_key,
		in_compound_filter_id	=> in_compound_filter_id,
		in_start_dtm			=> in_start_dtm,
		in_end_dtm				=> in_end_dtm,
		in_date_col_type		=> in_date_col_type,
		in_id_list_populated	=> in_id_list_populated,
		in_id_list				=> in_id_list,
		out_id_list				=> out_id_list
	);
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
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.ApplyBreadcrumb');
	
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
	out_cert_reqs_cur				OUT SYS_REFCURSOR,
	out_tags_cur 					OUT SYS_REFCURSOR
)
AS
	v_company_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_log_id						debug_log.debug_log_id%TYPE;
	v_visible_company_sids			security.T_SID_TABLE;
	v_root_type_id					product_type.product_type_id%TYPE := product_type_pkg.GetRootProductType;
	v_product_ids					security.T_SID_TABLE;
	v_cert_type_ids					security.T_SID_TABLE;
	v_cert_reqs						T_OBJECT_CERTIFICATION_TABLE;
	v_read_product_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ);
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.CollectSearchResults');
	
	v_visible_company_sids := company_pkg.GetVisibleCompanySids;

	-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
	OPEN out_cur FOR 
		SELECT cp.product_id, cp.product_name, cp.product_ref, cp.lookup_key, cp.is_active,
			   c.company_sid, c.name company_name,
			   pt.product_type_id, NVL(pt_tree.tree_path, pt.description) product_type_name,
			   0 weight_val, NULL weight_measure_conv_id, 'kg' weight_unit, NULL weight_measure_sid,
			   0 volume_val, NULL volume_measure_conv_id, 'm3' volume_unit, NULL volume_measure_sid
		  FROM v$company_product cp
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cp.product_id
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE(v_visible_company_sids)) c_cap ON c_cap.column_value = cp.company_sid
		  LEFT JOIN v$company c ON c.company_sid = c_cap.column_value
		  JOIN chain.v$product_type pt ON pt.product_type_id = cp.product_type_id
		  LEFT JOIN (
				SELECT product_type_id, LEVEL tree_level, REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description, ''), ''), '', ' / ') tree_path
				  FROM chain.v$product_type
				 START WITH parent_product_type_id = v_root_type_id
			   CONNECT BY parent_product_type_id = PRIOR product_type_id
		  ) pt_tree ON pt_tree.product_type_id = pt.product_type_id
		 ORDER BY fil_list.pos;

	OPEN out_tags_cur FOR
		SELECT cpt.product_id, cpt.tag_group_id, cpt.tag_id, t.tag
		  FROM company_product_tag cpt
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cpt.product_id
		  JOIN csr.v$tag t ON t.tag_id = cpt.tag_id
		  JOIN csr.tag_group_member tgm ON tgm.tag_group_id = cpt.tag_group_id AND tgm.tag_id = cpt.tag_id
		 ORDER BY tgm.pos, LOWER(t.tag);

	SELECT DISTINCT cp.product_id
	  BULK COLLECT INTO v_product_ids
	  FROM company_product cp
	  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cp.product_id
	  JOIN company c ON c.company_sid = cp.company_sid
	  LEFT JOIN TABLE(v_read_product_certs) read_own_certs ON read_own_certs.secondary_company_type_id IS NULL AND c.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_product_certs) read_other_certs ON read_other_certs.secondary_company_type_id = c.company_type_id AND c.company_sid != v_company_sid
	 WHERE read_own_certs.primary_company_type_id IS NOT NULL
	    OR read_other_certs.primary_company_type_id IS NOT NULL;

	SELECT certification_type_id
	  BULK COLLECT INTO v_cert_type_ids
	  FROM certification_type;

	v_cert_reqs := company_product_pkg.INTERNAL_GetProductCertReqs(v_product_ids, v_cert_type_ids);

	OPEN out_cert_reqs_cur FOR
		SELECT cprc.product_id, ct.certification_type_id, ct.label certification_type_label, NVL(t.is_certified, 0) is_certified
		  FROM company_product_required_cert cprc
		  JOIN TABLE (v_product_ids) pids ON pids.column_value = cprc.product_id
		  JOIN certification_type ct ON ct.certification_type_id = cprc.certification_type_id
		  LEFT JOIN TABLE(v_cert_reqs) t ON t.object_id = cprc.product_id AND t.certification_type_id = cprc.certification_type_id;

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
	v_order_by						VARCHAR2(255);
	v_order_by_id	 				NUMBER;
	v_product_ids					security.T_SID_TABLE;
	v_cert_type_ids					security.T_SID_TABLE;
	v_cert_reqs						T_OBJECT_CERTIFICATION_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_root_type_id					product_type.product_type_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.PageFilteredProductIds');

	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
	
	IF v_order_by = 'certificationRequirement' THEN
		SELECT DISTINCT object_id
		  BULK COLLECT INTO v_product_ids
		  FROM TABLE(in_id_list);

		SELECT certification_type_id
		  BULK COLLECT INTO v_cert_type_ids
		  FROM certification_type
		 WHERE certification_type_id = v_order_by_id;

		v_cert_reqs := company_product_pkg.INTERNAL_GetProductCertReqs(v_product_ids, v_cert_type_ids);

		SELECT security.T_ORDERED_SID_ROW(product_id, rn)
			BULK COLLECT INTO out_id_list
				FROM (
				SELECT x.product_id, ROWNUM rn
					FROM (
					SELECT cp.product_id
						FROM company_product cp
						JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cp.product_id
						LEFT JOIN TABLE (v_cert_reqs) t ON t.object_id = cp.product_id
						ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN t.is_certified END ASC,
							CASE WHEN in_order_dir='DESC' THEN t.is_certified END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cp.product_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN cp.product_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
				WHERE rn > in_start_row;
	ELSIF v_order_by = 'productTypeName' THEN
		v_root_type_id := product_type_pkg.GetRootProductType;

		-- ************* N.B. that's a literal 0x1 character in sys_connect_by_path, not a space **************
		SELECT security.T_ORDERED_SID_ROW(product_id, rn)
			BULK COLLECT INTO out_id_list
				FROM (
				SELECT x.product_id, ROWNUM rn
					FROM (
					SELECT cp.product_id
						FROM v$company_product cp
						JOIN v$product_type pt ON pt.product_type_id = cp.product_type_id
						LEFT JOIN (
							SELECT product_type_id, LEVEL tree_level, REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description, ''), ''), '', ' / ') tree_path
							  FROM chain.v$product_type
							 START WITH parent_product_type_id = v_root_type_id
						   CONNECT BY parent_product_type_id = PRIOR product_type_id
						) pt_tree ON pt_tree.product_type_id = pt.product_type_id
						JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cp.product_id
						ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN NVL(pt_tree.tree_path, pt.description) END ASC,
							CASE WHEN in_order_dir='DESC' THEN NVL(pt_tree.tree_path, pt.description) END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cp.product_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN cp.product_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
				WHERE rn > in_start_row;
	ELSE
		SELECT security.T_ORDERED_SID_ROW(product_id, rn)
			BULK COLLECT INTO out_id_list
				FROM (
				SELECT x.product_id, ROWNUM rn
					FROM (
					SELECT cp.product_id
						FROM v$company_product cp
						JOIN v$product_type pt ON pt.product_type_id = cp.product_type_id
						JOIN v$company c ON c.company_sid = cp.company_sid
						JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cp.product_id
						ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'productId' THEN LOWER(cp.product_id)
									WHEN 'productName' THEN LOWER(cp.product_name)
									WHEN 'companyName' THEN LOWER(c.name)
									WHEN 'productRef' THEN LOWER(cp.product_ref)
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'productId' THEN LOWER(cp.product_id)
									WHEN 'productName' THEN LOWER(cp.product_name)
									WHEN 'companyName' THEN LOWER(c.name)
									WHEN 'productRef' THEN LOWER(cp.product_ref)
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cp.product_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN cp.product_id END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_PRODUCT, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Product -> '||v_name);

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
	out_tags_cur 					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.GetList', in_compound_filter_id);

	INTERNAL_GetFilteredIds(
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

	-- Return a page of results
	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_cert_reqs_cur	=> out_cert_reqs_cur,
		out_tags_cur		=> out_tags_cur
	);

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
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.GetReportData', in_compound_filter_id);

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

	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_PRODUCT, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

	filter_pkg.GetEmptyExtraSeriesCur(out_extra_series_cur);

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetAlertData (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - should only be called by filter_pkg with an already security-trimmed list of ids
	OPEN out_cur FOR
		SELECT fil_list.object_id, p.product_id, p.product_type_id, p.is_active,
			   p.product_name, p.company_sid, p.product_ref, p.lookup_key,
			   pt.description product_type,
			   c.name company
		  FROM v$company_product p
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = p.product_id
		  JOIN v$product_type pt ON pt.product_type_id = p.product_type_id
		  JOIN company c ON c.company_sid = p.company_sid;
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
	out_tags_cur 					OUT SYS_REFCURSOR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
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

	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_cert_reqs_cur	=> out_cert_reqs_cur,
		out_tags_cur		=> out_tags_cur
	);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN compound_filter.compound_filter_id%TYPE,
	out_cur 						OUT SYS_REFCURSOR,
	out_cert_reqs_cur				OUT SYS_REFCURSOR,
	out_tags_cur 					OUT SYS_REFCURSOR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.product_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM temp_grid_extension_map
		 WHERE linked_type = filter_pkg.FILTER_TYPE_PRODUCT
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

PROCEDURE FilterProductName (
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
	  JOIN v$company_product cp ON cp.product_id = t.object_id
	  JOIN filter_value fv ON LOWER(cp.product_name) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterProductRef (
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
	  JOIN company_product cp ON cp.product_id = t.object_id
	  JOIN filter_value fv ON LOWER(cp.product_ref) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterProductType (
	in_filter_id 					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, pt.product_type_id, pt.description
		  FROM v$product_type pt
		 WHERE product_type_id IN (SELECT product_type_id FROM v$company_product)
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = pt.product_type_id
		 );

		SELECT T_FILTERED_OBJECT_ROW(cp.product_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM company_product cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.product_id = t.object_id
		  JOIN filter_value fv ON LOWER(cp.product_type_id) = fv.num_value
		 WHERE fv.filter_field_id = in_filter_field_id;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(cp.product_id, in_group_by_index, pt_t.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM company_product cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.product_id = t.object_id
		  JOIN (
				SELECT pt.product_type_id, fv.filter_value_id
				  FROM product_type pt
				  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
				 START WITH pt.product_type_id = fv.num_value
			   CONNECT BY pt.parent_product_type_id = PRIOR pt.product_type_id
				   AND fv.filter_value_id = PRIOR fv.filter_value_id
		  ) pt_t ON pt_t.product_type_id = cp.product_type_id;
	END IF;
END;

PROCEDURE FilterActive (
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, f.following, f.description
		  FROM (
			SELECT 1 following, 'Active' description FROM dual
			UNION ALL SELECT 0, 'Inactive' FROM dual
		  ) f
		 WHERE NOT EXISTS (
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = f.following
		 );		
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  JOIN company_product cp ON cp.product_id = t.object_id
	  JOIN filter_value fv ON fv.num_value = cp.is_active 
	 WHERE fv.filter_field_id = in_filter_field_id;
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
	v_product_ids					security.T_SID_TABLE;
	v_cert_type_ids					security.T_SID_TABLE;
	v_cert_reqs						T_OBJECT_CERTIFICATION_TABLE;
	v_read_product_certs			T_PERMISSIBLE_TYPES_TABLE := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ);
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

	-- INTERNAL_GetProductCertReqs will do this check again, but we do it here so that we can 
	-- distinguish between is_certified being NULL because there's no certification requirement,
	-- and is_certified being NULL because we don't have permission to see product certifications.

	SELECT DISTINCT object_id
	  BULK COLLECT INTO v_product_ids
	  FROM company_product cp
	  JOIN TABLE (in_ids) fil_list ON fil_list.object_id = cp.product_id
	  JOIN company c ON c.company_sid = cp.company_sid
	  LEFT JOIN TABLE(v_read_product_certs) read_own_certs ON read_own_certs.secondary_company_type_id IS NULL AND c.company_sid = v_company_sid
	  LEFT JOIN TABLE(v_read_product_certs) read_other_certs ON read_other_certs.secondary_company_type_id = c.company_type_id AND c.company_sid != v_company_sid
	 WHERE read_own_certs.primary_company_type_id IS NOT NULL
	    OR read_other_certs.primary_company_type_id IS NOT NULL;

	SELECT certification_type_id
	  BULK COLLECT INTO v_cert_type_ids
	  FROM certification_type
	 WHERE certification_type_id = in_cert_type_id;

	v_cert_reqs := company_product_pkg.INTERNAL_GetProductCertReqs(v_product_ids, v_cert_type_ids);

	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  LEFT JOIN TABLE(v_cert_reqs) reqs ON reqs.object_id = t.object_id AND reqs.certification_type_id = in_cert_type_id
	  JOIN chain.filter_value fv ON (
			(fv.num_value = 1 AND reqs.is_certified = 1) OR
			(fv.num_value = 0 AND reqs.is_certified = 0) OR
			(fv.num_value = 2 AND reqs.is_certified IS NULL)
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
		SELECT cpt.app_sid, cpt.product_id, cpt.tag_id
		  FROM company_product_tag cpt
		  JOIN csr.tag_group_member tgm ON tgm.app_sid = cpt.app_sid AND tgm.tag_id = cpt.tag_id
		 WHERE tgm.tag_group_id = in_tag_group_id)
	SELECT chain.T_FILTERED_OBJECT_ROW(cp.product_id, ff.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM company_product cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.product_id = t.object_id
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	  JOIN chain.filter_field ff ON ff.filter_field_id = fv.filter_field_id AND ff.app_sid = fv.app_sid
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(cp.app_sid, cp.product_id) NOT IN (SELECT app_sid, product_id FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(cp.app_sid, cp.product_id) IN (
				SELECT app_sid, product_id
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
END;

PROCEDURE CompanyFilter (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_company_sids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(cp.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_sids
		  FROM company_product cp
		  JOIN TABLE(in_ids) t ON cp.product_id = t.object_id;

		company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_sids,
			out_id_list						=> v_company_sids
		);

		SELECT T_FILTERED_OBJECT_ROW(product_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT product_id
			  FROM company_product cp
			  JOIN TABLE(in_ids) ids ON ids.object_id = cp.product_id
			  JOIN TABLE(v_company_sids) t ON cp.company_sid = t.object_id
		  );
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
	SELECT T_FILTERED_OBJECT_ROW(cp.company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM company_product cp
	  JOIN TABLE(in_ids) t ON cp.product_id = t.object_id;

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
		  
	SELECT T_FILTERED_OBJECT_ROW(cp.product_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM company_product cp
	  JOIN TABLE(in_ids) ids ON ids.object_id = cp.product_id
	  JOIN TABLE(v_company_sids) t ON cp.company_sid = t.object_id;
END;

PROCEDURE SupplierFilter (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_product_supplier_ids			T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, NULL, NULL)
		  BULK COLLECT INTO v_product_supplier_ids
		  FROM product_supplier ps
		  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_id;

		product_supplier_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_product_supplier_ids,
			out_id_list						=> v_product_supplier_ids
		);

		SELECT T_FILTERED_OBJECT_ROW(product_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT product_id
			  FROM product_supplier ps
			  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_id
			  JOIN TABLE(v_product_supplier_ids) t ON ps.product_supplier_id = t.object_id
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
	v_product_supplier_ids			T_FILTERED_OBJECT_TABLE;
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(product_supplier_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_product_supplier_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) t ON t.object_id = ps.product_id;

	product_supplier_report_pkg.RunSingleUnit(
		in_name						=> in_name,
		in_comparator				=> in_comparator,
		in_column_sid				=> NULL,
		in_filter_id				=> in_filter_id,
		in_filter_field_id			=> in_filter_field_id,
		in_group_by_index			=> in_group_by_index,
		in_show_all					=> in_show_all,
		in_ids						=> v_product_supplier_ids,
		out_ids						=> v_product_supplier_ids
	);
		  
	SELECT T_FILTERED_OBJECT_ROW(ps.product_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM product_supplier ps
	  JOIN TABLE(in_ids) ids ON ids.object_id = ps.product_id
	  JOIN TABLE(v_product_supplier_ids) t ON ps.product_supplier_id = t.object_id;
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

END product_report_pkg;
/
