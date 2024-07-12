CREATE OR REPLACE PACKAGE BODY chain.certification_report_pkg
IS

PARENT_TYPE_COMPANY_PRODUCT			CONSTANT NUMBER := 1;
PARENT_TYPE_PRODUCT_SUPPLIER		CONSTANT NUMBER := 2;

-- private field filter units
PROCEDURE FilterCertificationType		(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCertificationAuditType	(in_cert_type_id IN certification_type.certification_type_id%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCertificationValid		(in_cert_type_id IN certification_type.certification_type_id%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCertificationResult		(in_cert_type_id IN certification_type.certification_type_id%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompany					(in_cert_type_id IN certification_type.certification_type_id%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCompanyBreakdown		(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterCertifications (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
) 
AS
	v_starting_ids					T_FILTERED_OBJECT_TABLE;
	v_result_ids					T_FILTERED_OBJECT_TABLE;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_inner_log_id					debug_log.debug_log_id%TYPE;
	v_name							VARCHAR2(256);
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.FilterCertifications', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.FilterCertifications.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		IF LOWER(r.name) = 'type' THEN
			FilterCertificationAuditType(in_cert_type_id, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'cert-type' THEN
			FilterCertificationType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'valid' THEN
			FilterCertificationValid(in_cert_type_id, in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'result' THEN
			FilterCertificationResult(in_cert_type_id, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'certificationCompanyFilter' THEN
			FilterCompany(in_cert_type_id, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'certificationCompanyFilter_%' THEN
			v_name := substr(r.name, 28);
			FilterCompanyBreakdown(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || r.name);
		END IF;
		
		filter_pkg.EndDebugLog(v_inner_log_id);
		
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
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_sid_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_sid_list					OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS	
	v_starting_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('chain.certification_report_pkg.RunCompoundFilter');
	
	v_starting_sids := in_sid_list;

	IF in_parallel = 0 THEN
		out_sid_list := in_sid_list;
	ELSE
		out_sid_list := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	chain.filter_pkg.CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);	
	chain.filter_pkg.CheckCompoundFilterForCycles(in_compound_filter_id);
		
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM chain.filter f
		  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterCertifications(:filter_id, :certification_type_id, :parallel, :max_group_by, :input, :output);END;') 
		USING r.filter_id, in_cert_type_id, in_parallel, in_max_group_by, v_starting_sids, OUT v_result_sids;
		
		IF in_parallel = 0 THEN
			v_starting_sids := v_result_sids;
			out_sid_list := v_result_sids;
		ELSE
			out_sid_list := out_sid_list MULTISET UNION v_result_sids;
		END IF;
	END LOOP;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM tt_filter_object_data;
 
	INSERT INTO tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT agg.column_value, l.object_id, filter_pkg.AFUNC_SUM,
			CASE agg.column_value
				WHEN 1 THEN COUNT(DISTINCT sc.certification_id)
			END
	  FROM v$supplier_certification sc
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON sc.certification_id = l.object_id
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
	v_log_id := filter_pkg.StartDebugLog('csr.certification_report_pkg.Search');

	SELECT T_FILTERED_OBJECT_ROW(t.object_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM TABLE(in_id_list) t
	  JOIN v$supplier_certification sc ON sc.certification_id = t.object_id
	  JOIN company c ON c.company_sid = sc.company_sid
	  JOIN certification_type ct ON ct.certification_type_id = sc.certification_type_id
	 WHERE (
			in_search IS NULL 
			OR CAST(sc.certification_id AS VARCHAR2(20)) = TRIM(in_search)
			OR UPPER(c.name) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(ct.label) LIKE '%'||UPPER(in_search)||'%'
	 );

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetFilteredIds(
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE DEFAULT NULL,
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
	in_id_list						IN	T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','CHAIN_COMPANY');
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_temp_id_list					T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_log_id						debug_log.debug_log_id%TYPE;
	v_company_sids					security.T_SID_TABLE;
	v_capable_company_sids			security.T_SID_TABLE;
	v_read_product_certs			T_PERMISSIBLE_TYPES_TABLE;
	v_read_prod_supp_certs			T_PERMISSIBLE_TYPES_TABLE;
	v_read_prod_sup_of_sup_certs	T_PERMISSIBLE_TYPES_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.GetFilteredIds', in_compound_filter_id);

	IF in_id_list_populated = 0 THEN
		SELECT T_FILTERED_OBJECT_ROW(certification_id, NULL, NULL)
		  BULK COLLECT INTO v_id_list
		  FROM v$supplier_certification;
	ELSE
		v_id_list := in_id_list;
	END IF;

	IF in_cert_type_id IS NOT NULL THEN
		SELECT T_FILTERED_OBJECT_ROW(t.object_id, t.group_by_index, t.group_by_value)
		  BULK COLLECT INTO v_temp_id_list
		  FROM TABLE(v_id_list) t
		  JOIN v$supplier_certification sc ON sc.certification_id = t.object_id
		 WHERE sc.certification_type_id = in_cert_type_id;

		v_id_list := v_temp_id_list;
	END IF;
	
	SELECT company_sid
	  BULK COLLECT INTO v_company_sids
	  FROM (
		SELECT DISTINCT sc.company_sid
		  FROM TABLE(v_id_list) t
		  JOIN v$supplier_certification sc ON sc.certification_id = t.object_id
		 WHERE sc.company_sid <> v_company_sid
	);

	v_capable_company_sids := type_capability_pkg.FilterPermissibleCompanySids(v_company_sids, chain_pkg.VIEW_CERTIFICATIONS);
	IF type_capability_pkg.CheckCapability(chain_pkg.VIEW_CERTIFICATIONS) THEN
		v_capable_company_sids.EXTEND;
		v_capable_company_sids(v_capable_company_sids.COUNT) := v_company_sid;
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(t.object_id, t.group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_temp_id_list
	  FROM TABLE(v_id_list) t
	  JOIN v$supplier_certification sc ON sc.certification_id = t.object_id
	  JOIN TABLE(v_capable_company_sids) c ON c.column_value = sc.company_sid;

	v_id_list := v_temp_id_list;

	IF in_parent_type = PARENT_TYPE_COMPANY_PRODUCT THEN
		v_read_product_certs := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_CERTIFICATIONS, security.security_pkg.PERMISSION_READ);
		
		SELECT T_FILTERED_OBJECT_ROW(t.object_id, t.group_by_index, t.group_by_value)
		  BULK COLLECT INTO v_temp_id_list
		  FROM TABLE(v_id_list) t
		  JOIN company_product_certification cpc ON cpc.certification_id = t.object_id
		  JOIN company_product cp ON cp.product_id = cpc.product_id
		  JOIN company c ON c.company_sid = cp.company_sid
		  LEFT JOIN TABLE(v_read_product_certs) read_own_certs ON read_own_certs.secondary_company_type_id IS NULL AND c.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_read_product_certs) read_other_certs ON read_other_certs.secondary_company_type_id = c.company_type_id AND c.company_sid != v_company_sid
		 WHERE (
				read_own_certs.primary_company_type_id IS NOT NULL
				OR read_other_certs.primary_company_type_id IS NOT NULL
		 ) AND (
				cp.product_id = in_parent_id
		 );
		 
		v_id_list := v_temp_id_list;
	ELSIF in_parent_type = PARENT_TYPE_PRODUCT_SUPPLIER THEN
		v_read_prod_supp_certs := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPPLIER_CERTS, security.security_pkg.PERMISSION_READ);
		v_read_prod_sup_of_sup_certs := type_capability_pkg.GetPermissibleCompanyTypes(v_company_sid, chain_pkg.PRODUCT_SUPP_OF_SUPP_CERTS, security.security_pkg.PERMISSION_READ);
		
		SELECT T_FILTERED_OBJECT_ROW(t.object_id, t.group_by_index, t.group_by_value)
		  BULK COLLECT INTO v_temp_id_list
		  FROM TABLE(v_id_list) t
		  JOIN product_supplier_certification psc ON psc.certification_id = t.object_id
		  JOIN product_supplier ps ON ps.product_supplier_id = psc.product_supplier_id
		  JOIN company pc ON pc.company_sid = ps.purchaser_company_sid
		  JOIN company sc ON sc.company_sid = ps.supplier_company_sid
		  LEFT JOIN TABLE(v_read_prod_supp_certs) read_sup_certs ON read_sup_certs.secondary_company_type_id = sc.company_type_id AND pc.company_sid = v_company_sid
		  LEFT JOIN TABLE(v_read_prod_sup_of_sup_certs) read_sos_certs ON read_sos_certs.secondary_company_type_id = pc.company_type_id AND read_sos_certs.tertiary_company_type_id = sc.company_type_id AND pc.company_sid != v_company_sid
		 WHERE (
				read_sup_certs.primary_company_type_id IS NOT NULL
				OR read_sos_certs.primary_company_type_id IS NOT NULL
		 ) AND (
				ps.product_supplier_id = in_parent_id
		 );
		 
		v_id_list := v_temp_id_list;
	END IF;
	
	Search(in_search, v_id_list, v_id_list);

	filter_pkg.EndDebugLog(v_log_id);
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

	IF NVL(in_compound_filter_id, 0) > 0 THEN
		RunCompoundFilter(in_compound_filter_id, in_cert_type_id, 0, NULL, v_id_list, v_id_list);
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
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.ApplyBreadcrumb');

	out_id_list := in_id_list;

	v_breadcrumb_count := CASE WHEN in_breadcrumb IS NULL THEN 0 WHEN in_breadcrumb.COUNT = 1 AND in_breadcrumb(1) IS NULL THEN 0 ELSE in_breadcrumb.COUNT END;

	IF v_breadcrumb_count > 0 THEN
		v_field_compound_filter_id := filter_pkg.GetCompFilterIdFromBreadcrumb(in_breadcrumb);

		RunCompoundFilter(v_field_compound_filter_id, NULL, 1, v_breadcrumb_count, out_id_list, out_id_list);

		-- check if any breadcrumb elements are on "other". If not, we don't need to do a top N	
		IF in_breadcrumb(1) < 0 OR
			(v_breadcrumb_count > 1 AND in_breadcrumb(2) < 0) OR
			(v_breadcrumb_count > 2 AND in_breadcrumb(3) < 0) OR
			(v_breadcrumb_count > 3 AND in_breadcrumb(4) < 0)
		THEN
			-- Use the aggregation type for drilldowns on "other"
			-- If not supplied, use count
			SELECT NVL(in_aggregation_type, 1) BULK COLLECT INTO v_aggregation_types FROM dual;

			GetFilterObjectData(v_aggregation_types, out_id_list);

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
	out_cur 						OUT SYS_REFCURSOR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.CollectSearchResults');
	
	OPEN out_cur FOR
		SELECT sc.certification_id, c.name supplier_name, c.company_sid, ct.certification_type_id,
			ct.label certification_type_label, sc.valid_from_dtm, sc.expiry_dtm, act.label result
		  FROM v$supplier_certification sc
		  JOIN TABLE(in_id_list) ids ON ids.sid_id = sc.certification_id
		  JOIN company c ON c.company_sid = sc.company_sid
		  JOIN certification_type ct ON ct.certification_type_id = sc.certification_type_id
		  LEFT JOIN csr.audit_closure_type act ON act.audit_closure_type_id = sc.audit_closure_type_id;

	filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredIds(
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_order_by 					IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_id_list						OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_order_by						VARCHAR2(255);
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.PageFilteredIds');
	
	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	
	SELECT security.T_ORDERED_SID_ROW(certification_id, rn)
	  BULK COLLECT INTO out_id_list
	  FROM (
		SELECT certification_id, rownum rn
		  FROM (
			SELECT sc.certification_id
			  FROM v$supplier_certification sc
			  JOIN TABLE(in_id_list) ids ON ids.object_id = sc.certification_id
			  JOIN company c ON c.company_sid = sc.company_sid
			  JOIN certification_type ct ON ct.certification_type_id = sc.certification_type_id
			  LEFT JOIN csr.audit_closure_type act ON act.audit_closure_type_id = sc.audit_closure_type_id
			 ORDER BY
				CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
					CASE v_order_by
						WHEN 'supplierName' THEN c.name
						WHEN 'certificationTypeLabel' THEN ct.label
						WHEN 'result' THEN act.label
					END
				END ASC,
				CASE WHEN in_order_dir='DESC' THEN
					CASE v_order_by 
						WHEN 'supplierName' THEN c.name
						WHEN 'certificationTypeLabel' THEN ct.label
						WHEN 'result' THEN act.label
					END
				END DESC,
				CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
					CASE v_order_by
						WHEN 'validFromDtm' THEN sc.valid_from_dtm
						WHEN 'expiryDtm' THEN sc.expiry_dtm
					END
				END ASC,
				CASE WHEN in_order_dir='DESC' THEN
					CASE v_order_by 
						WHEN 'validFromDtm' THEN sc.valid_from_dtm
						WHEN 'expiryDtm' THEN sc.expiry_dtm
					END
				END DESC,
				CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN sc.certification_id END ASC,
				CASE WHEN in_order_dir='DESC' THEN sc.certification_id END DESC
			)
		)
	 WHERE rn > in_start_row AND rn <= in_end_row;

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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_CERTS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Certification -> '||v_name);

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
	out_cur 						OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.GetCertificationList');
	
	GetFilteredIds(
		in_search				=> in_search,
		in_cert_type_id			=> NULL,
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

	CollectSearchResults(v_id_page, out_cur);
	
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
	v_log_id := filter_pkg.StartDebugLog('csr.certification_report_pkg.GetReportData', in_compound_filter_id);

	GetFilteredIds(
		in_search				=> in_search,
		in_cert_type_id			=> NULL,
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
		RunCompoundFilter(in_grp_by_compound_filter_id, NULL, 1, in_max_group_by, v_id_list, v_id_list);
	END IF;

	GetFilterObjectData(in_aggregation_types, v_id_list);
	
	IF in_aggregation_types.COUNT > 0 THEN
		v_aggregation_type := in_aggregation_types(1);
	END IF;

	v_top_n_values := filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_CERTS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
	out_cur 						OUT SYS_REFCURSOR
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_groups						security_pkg.T_OUTPUT_CUR;
BEGIN
	GetFilteredIds(
		in_search				=> in_search,
		in_cert_type_id			=> NULL,
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

	CollectSearchResults(v_id_page, out_cur);
END;

PROCEDURE GetListAsExtension (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.certification_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM temp_grid_extension_map
		 WHERE linked_type = filter_pkg.FILTER_TYPE_CERTS
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

	CollectSearchResults(v_id_page, out_cur);
	
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





PROCEDURE FilterCertificationType	(
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
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, ctf.certification_type_id, ctf.label
			  FROM (
				SELECT ct.certification_type_id, ct.label
				  FROM certification_type ct
				  JOIN filter_field ff ON ff.filter_field_id = in_filter_field_id
				 GROUP BY ct.certification_type_id, ct.label
				) ctf
			 WHERE NOT EXISTS ( -- exclude any we may have already
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = ctf.certification_type_id
			 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(sc.certification_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$supplier_certification sc
	  JOIN TABLE(in_ids) t ON t.object_id = sc.certification_id
	  JOIN filter_field ff  ON ff.filter_id = in_filter_id 
	   AND ff.filter_field_id = in_filter_field_id
	  JOIN filter_value fv ON ff.filter_field_id = fv.filter_field_id
	   AND sc.certification_type_id = fv.num_value
	 WHERE LOWER(ff.name) = 'cert-type';
END;

PROCEDURE FilterCertificationAuditType (
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE,
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
			SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, c.internal_audit_type_id, c.label
			  FROM (
				SELECT iat.internal_audit_type_id, iat.label 
				  FROM cert_type_audit_type cat
				  JOIN csr.internal_audit_type iat 
				    ON iat.internal_audit_type_id = cat.internal_audit_type_id
				   AND (in_cert_type_id IS NULL OR cat.certification_type_id = in_cert_type_id)
				  JOIN filter_field ff ON ff.filter_field_id = in_filter_field_id
				 GROUP BY iat.internal_audit_type_id, iat.label
			   ) c
			 WHERE NOT EXISTS ( -- exclude any we may have already
				SELECT *
				  FROM filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = c.internal_audit_type_id
			 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(sc.certification_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$supplier_certification sc
	  JOIN TABLE(in_ids) t ON t.object_id = sc.certification_id
	  JOIN filter_field ff  ON ff.filter_id = in_filter_id 
	   AND ff.filter_field_id = in_filter_field_id
	  JOIN filter_value fv ON ff.filter_field_id = fv.filter_field_id
	   AND sc.internal_audit_type_id = fv.num_value
	 WHERE LOWER(ff.name) = 'type';
END;

PROCEDURE FilterCertificationValid (
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE,
	in_filter_id					IN  filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT T_FILTERED_OBJECT_ROW(certification_id, NULL, NULL)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT sc.certification_id
		  FROM v$supplier_certification sc
		  JOIN TABLE(in_ids) t ON t.object_id = sc.certification_id
		  JOIN filter_field ff  ON ff.filter_id = in_filter_id 
		   AND ff.filter_field_id = in_filter_field_id
		  JOIN filter_value fv ON ff.filter_field_id = fv.filter_field_id
		   AND sc.valid_from_dtm <= NVL(fv.end_dtm_value, sc.valid_from_dtm) 
		   AND NVL(sc.expiry_dtm, sc.valid_from_dtm)  >= NVL(fv.start_dtm_value, NVL(sc.expiry_dtm, sc.valid_from_dtm)) 
		 WHERE LOWER(ff.name) = 'valid'
	);
END;

PROCEDURE FilterCertificationResult (
	in_cert_type_id					IN	certification_type.certification_type_id%TYPE,
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
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, c.audit_closure_type_id, c.label
		  FROM (
			SELECT act.audit_closure_type_id, act.label 
			  FROM cert_type_audit_type cat
			  JOIN csr.internal_audit_type iat 
				ON iat.internal_audit_type_id = cat.internal_audit_type_id
			  JOIN csr.audit_type_closure_type atct
				ON atct.internal_audit_type_id = iat.internal_audit_type_id
			  JOIN csr.audit_closure_type act
				ON act.audit_closure_type_id  = atct.audit_closure_type_id
			  JOIN filter_field ff ON ff.filter_field_id = in_filter_field_id
			 WHERE (in_cert_type_id IS NULL OR cat.certification_type_id = in_cert_type_id)
			 GROUP BY act.audit_closure_type_id, act.label
		   ) c
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = c.audit_closure_type_id
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(sc.certification_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$supplier_certification sc
	  JOIN TABLE(in_ids) t ON t.object_id = sc.certification_id
	  JOIN filter_field ff  ON ff.filter_id = in_filter_id 
	   AND ff.filter_field_id = in_filter_field_id
	  JOIN filter_value fv ON ff.filter_field_id = fv.filter_field_id
	   AND sc.audit_closure_type_id = fv.num_value
	 WHERE LOWER(ff.name) = 'result';
END;

PROCEDURE FilterCompany (
	in_cert_type_id					IN certification_type.certification_type_id%TYPE,
	in_filter_id					IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER,
	in_group_by_index				IN NUMBER,
	in_show_all						IN NUMBER,
	in_ids							IN T_FILTERED_OBJECT_TABLE,
	out_ids							OUT T_FILTERED_OBJECT_TABLE)
AS
	v_compound_filter_id			filter.compound_filter_id%TYPE;
	v_company_sids					T_FILTERED_OBJECT_TABLE;
BEGIN
	v_compound_filter_id := filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT T_FILTERED_OBJECT_ROW(sr.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_sids
		  FROM v$supplier_certification sr
		  JOIN TABLE(in_ids) t ON sr.certification_id = t.object_id;

		company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_sids,
			out_id_list						=> v_company_sids
		);

		SELECT T_FILTERED_OBJECT_ROW(certification_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT certification_id
			  FROM v$supplier_certification sr
			  JOIN TABLE(in_ids) ids ON ids.object_id = sr.certification_id
			  JOIN TABLE(v_company_sids) t ON sr.company_sid = t.object_id
		  );
	END IF;
END;

PROCEDURE FilterCompanyBreakdown (
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
	SELECT T_FILTERED_OBJECT_ROW(sr.company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM v$supplier_certification sr
	  JOIN TABLE(in_ids) t ON sr.certification_id = t.object_id;
	
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
	
	SELECT chain.T_FILTERED_OBJECT_ROW(sr.certification_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM v$supplier_certification sr
	  JOIN TABLE(in_ids) ids ON ids.object_id = sr.certification_id
	  JOIN TABLE(v_company_sids) t ON sr.company_sid = t.object_id;
END;

END certification_report_pkg;
/
