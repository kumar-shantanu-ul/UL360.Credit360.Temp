CREATE OR REPLACE PACKAGE BODY chain.business_rel_report_pkg
IS

-- private field filter units
PROCEDURE FilterActive				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPeriodDtm			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTypeId				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE CompanyFilter				(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE CompanyFilterBreakdown	(in_name IN	filter_field.name%TYPE, in_comparator IN filter_field.comparator%TYPE, in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN T_FILTERED_OBJECT_TABLE, out_ids OUT T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterBusinessRelationshipIds (
	in_filter_id					IN	filter.filter_id%TYPE,
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
	
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.FilterBusinessRelationshipIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.FilterBusinessRelationshipIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		IF LOWER(r.name) = 'active' THEN
			FilterActive(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'perioddtm' THEN
			FilterPeriodDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'businessrelationshiptypeid' THEN
			FilterTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'companyfilter' THEN
			CompanyFilter(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) LIKE 'companyfilter_%' THEN
			v_name := substr(r.name, 15);
			CompanyFilterBreakdown(v_name, r.comparator, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
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
	in_parallel						IN	NUMBER,
	in_max_group_by					IN	NUMBER,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN	
	filter_pkg.RunCompoundFilter('FilterBusinessRelationshipIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM tt_filter_object_data;
 
	INSERT INTO tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT agg.column_value, l.object_id, filter_pkg.AFUNC_SUM,
			CASE agg.column_value
				WHEN AGG_TYPE_COUNT THEN COUNT(DISTINCT br.business_relationship_id)
			END
	  FROM business_relationship br
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON br.business_relationship_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) agg
	 GROUP BY l.object_id, agg.column_value;

	filter_pkg.EndDebugLog(v_log_id);
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
	in_id_list						IN	T_FILTERED_OBJECT_TABLE DEFAULT NULL,
	out_id_list						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_has_regions					NUMBER;
	v_log_id						debug_log.debug_log_id%TYPE;
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_visible_company_sids			security.T_SID_TABLE := company_pkg.GetVisibleCompanySids;
	v_viewable_company_sids			security.T_SID_TABLE := type_capability_pkg.GetCapableCompanySids(v_visible_company_sids, chain_pkg.VIEW_BUSINESS_RELATIONSHIPS, chain_pkg.VIEW_BUS_REL_REVERSED);
	v_reference_perms				T_REF_PERM_TABLE := helper_pkg.GetRefPermsByType;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.GetFilteredIds', in_compound_filter_id);

	filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	
	SELECT T_FILTERED_OBJECT_ROW(business_relationship_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT DISTINCT br.business_relationship_id
			  FROM business_relationship br
			  JOIN business_relationship_type brt ON brt.business_relationship_type_id = br.business_relationship_type_id
			  JOIN business_relationship_company pbrc ON pbrc.business_relationship_id = br.business_relationship_id 
			   AND pbrc.company_sid = NVL(in_parent_id, pbrc.company_sid)
			  JOIN TABLE(v_viewable_company_sids) pvis ON pvis.column_value = pbrc.company_sid
			  JOIN business_relationship_company brc ON brc.business_relationship_id = pbrc.business_relationship_id
			  JOIN TABLE(v_viewable_company_sids) vis ON vis.column_value = brc.company_sid
			  JOIN v$company c ON c.company_sid = brc.company_sid
			  JOIN csr.supplier s ON s.company_sid = c.company_sid
			  LEFT JOIN v$company_reference cr ON c.company_sid = cr.company_sid
			  LEFT JOIN TABLE(v_reference_perms) rp ON rp.reference_id = cr.reference_id AND ((
							c.company_sid = v_company_sid AND rp.primary_company_type_id = c.company_type_id AND rp.secondary_company_type_id IS NULL
						) OR (
							c.company_sid != v_company_sid AND rp.secondary_company_type_id = c.company_type_id
						))
			  LEFT JOIN csr.temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_SUPPLIER_REGION THEN s.region_sid END = tr.region_sid
			 WHERE (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
			   AND (
					CAST(brc.business_relationship_id AS VARCHAR2(20)) = LTRIM(RTRIM(in_search))
					OR LOWER(brt.label) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%'
					OR LOWER(c.name) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%'
					OR CAST(c.company_sid AS VARCHAR2(20)) = LTRIM(RTRIM(in_search))
					OR (rp.permission_set > 0 AND LOWER(cr.value) LIKE '%'||LOWER(LTRIM(RTRIM(in_search)))||'%')
			   )
	  );

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

	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
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
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.ApplyBreadcrumb');

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
	out_bus_rel_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.CollectSearchResults');

	business_relationship_pkg.GetBusinessRelationships(
		in_bus_rel_ids				=> in_id_list,
		out_bus_rel_cur				=> out_bus_rel_cur,
		out_bus_rel_period_cur		=> out_bus_rel_period_cur,
		out_bus_rel_comp_cur		=> out_bus_rel_comp_cur
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
	v_order_by						VARCHAR2(255);
	v_order_by_id	 				NUMBER;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.PageFilteredIds');

	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

	IF INSTR(in_order_by, '~', 1) > 0 THEN
		filter_pkg.SortExtension(
			'business_relationship', 
			in_id_list,
			in_start_row,
			in_end_row,
			in_order_by,
			in_order_dir,
			out_id_list);
	ELSIF in_order_by = 'companies' THEN
		SELECT security.T_ORDERED_SID_ROW(business_relationship_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.business_relationship_id, ROWNUM rn
				  FROM (
					SELECT business_relationship_id
					  FROM (
						SELECT br.business_relationship_id, LOWER(listagg(c.name, ',') WITHIN GROUP (order by brt.tier, brc.pos)) companies
						  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list
						  JOIN business_relationship br ON br.business_relationship_id = fil_list.object_id
						  JOIN business_relationship_company brc ON brc.business_relationship_id = br.business_relationship_id
						  JOIN business_relationship_tier brt ON brt.business_relationship_type_id = br.business_relationship_type_id
															 AND brt.business_relationship_tier_id = brc.business_relationship_tier_id
						  JOIN v$company c ON c.company_sid = brc.company_sid
						 GROUP BY br.business_relationship_id
					  ) brs
					 ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN companies END ASC,
							CASE WHEN in_order_dir='DESC' THEN companies END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN business_relationship_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN business_relationship_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSIF in_order_by = 'active' THEN
		SELECT security.T_ORDERED_SID_ROW(business_relationship_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.business_relationship_id, ROWNUM rn
				  FROM (
					SELECT br.business_relationship_id
					  FROM business_relationship br
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = br.business_relationship_id
					  JOIN business_relationship_type brt ON brt.business_relationship_type_id = br.business_relationship_type_id
					 ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE 
									WHEN EXISTS (
										SELECT NULL
										  FROM business_relationship_period brp
										 WHERE br.business_relationship_id = brp.business_relationship_id
										   AND brp.start_dtm <= SYSDATE
										   AND (brp.end_dtm IS NULL OR brp.end_dtm > SYSDATE)
								    ) THEN '0'
									ELSE '1'
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE 
									WHEN EXISTS (
										SELECT NULL
										  FROM business_relationship_period brp
										 WHERE br.business_relationship_id = brp.business_relationship_id
										   AND brp.start_dtm <= SYSDATE
										   AND (brp.end_dtm IS NULL OR brp.end_dtm > SYSDATE)
								    ) THEN '0'
									ELSE '1'
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN br.business_relationship_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN br.business_relationship_id END DESC
					) x
					WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(business_relationship_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.business_relationship_id, ROWNUM rn
				  FROM (
					SELECT br.business_relationship_id
					  FROM business_relationship br
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = br.business_relationship_id
					  JOIN business_relationship_type brt ON brt.business_relationship_type_id = br.business_relationship_type_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'businessRelationshipId' THEN TO_CHAR(br.business_relationship_id, '0000000000')
									WHEN 'businessRelationshipTypeLabel' THEN LOWER(brt.label)
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'businessRelationshipId' THEN TO_CHAR(br.business_relationship_id, '0000000000')
									WHEN 'businessRelationshipTypeLabel' THEN LOWER(brt.label)
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN br.business_relationship_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN br.business_relationship_id END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_BUS_RELS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Business Relationship -> '||v_name);

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
	out_bus_rel_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.GetList', in_compound_filter_id);

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

	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_bus_rel_cur, out_bus_rel_period_cur, out_bus_rel_comp_cur);

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
	SELECT T_FILTER_AGG_TYPE_ROW(filter_pkg.FILTER_TYPE_BUS_RELS, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM aggregate_type at
		 WHERE card_group_id = filter_pkg.FILTER_TYPE_BUS_RELS
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
	v_id_list						T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.GetReportData', in_compound_filter_id);

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

	v_top_n_values := filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	filter_pkg.GetAggregateData(filter_pkg.FILTER_TYPE_BUS_RELS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
		SELECT b.object_id, b.business_relationship_id, b.type_label, b.active,
			   listagg(c.name, ', ') WITHIN GROUP (order by brt.tier, brc.pos) companies,
			   -- it would be nice to translate these, but I don't see how we can.
			   listagg(TO_CHAR(brp.start_dtm) || ' - ' || NVL(TO_CHAR(brp.end_dtm), 'Present'), ', ') WITHIN GROUP (order by brt.tier, brc.pos) periods
		  FROM (
				SELECT t.object_id, br.business_relationship_id, 
					   brt.business_relationship_type_id, brt.label type_label,
					   CASE WHEN EXISTS (
							SELECT NULL
							  FROM business_relationship_period
							 WHERE business_relationship_id = br.business_relationship_id
							   AND start_dtm <= SYSDATE
							   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
					   ) THEN 'Active' ELSE 'Inactive' END active
				  FROM business_relationship br
				  JOIN TABLE(in_id_list) t ON br.business_relationship_id = t.object_id
				  JOIN business_relationship_type brt on brt.business_relationship_type_id = br.business_relationship_type_id
		  ) b
		  JOIN business_relationship_company brc ON brc.business_relationship_id = b.business_relationship_id
		  JOIN business_relationship_tier brt ON brt.business_relationship_type_id = b.business_relationship_type_id
											 AND brt.business_relationship_tier_id = brc.business_relationship_tier_id
		  JOIN business_relationship_period brp ON brp.business_relationship_id = b.business_relationship_id
		  JOIN v$company c ON c.company_sid = brc.company_sid
		 GROUP BY b.object_id, b.business_relationship_id, b.type_label, b.active;
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
	out_bus_rel_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur			OUT	security_pkg.T_OUTPUT_CUR
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

	CollectSearchResults(v_id_page, out_bus_rel_cur, out_bus_rel_period_cur, out_bus_rel_comp_cur);
END;

PROCEDURE GetListAsExtension (
	in_compound_filter_id			IN	compound_filter.compound_filter_id%TYPE,
	out_bus_rel_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						debug_log.debug_log_id%TYPE;
	v_id_list						T_FILTERED_OBJECT_TABLE := T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := filter_pkg.StartDebugLog('chain.business_rel_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
		SELECT linked_id
		  FROM temp_grid_extension_map
		 WHERE linked_type = filter_pkg.FILTER_TYPE_BUS_RELS
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

	CollectSearchResults(v_id_page, out_bus_rel_cur, out_bus_rel_period_cur, out_bus_rel_comp_cur);
	
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

PROCEDURE FilterActive (
	in_filter_id 					IN	filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
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
	
	SELECT T_FILTERED_OBJECT_ROW(bra.business_relationship_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		 SELECT br.business_relationship_id, CASE WHEN EXISTS (
					SELECT NULL
					  FROM business_relationship_period brp
					 WHERE brp.business_relationship_id = br.business_relationship_id
					   AND brp.start_dtm <= SYSDATE
					   AND (brp.end_dtm IS NULL OR brp.end_dtm > SYSDATE)
				) THEN 1 ELSE 0 END active
		   FROM business_relationship br
		   JOIN (
				SELECT DISTINCT object_id FROM TABLE(in_ids)
		   ) t ON t.object_id = br.business_relationship_id
	  ) bra
	  JOIN filter_value fv ON fv.num_value = bra.active
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPeriodDtm (
	in_filter_id 					IN	filter.filter_id%TYPE,
	in_filter_field_id 				IN	NUMBER,
	in_show_all 					IN	NUMBER,
	in_ids 							IN	T_FILTERED_OBJECT_TABLE,
	out_ids 						OUT	T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date						DATE;
	v_max_date						DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(brp.start_dtm), MAX(brp.end_dtm)
		  INTO v_min_date, v_max_date
		  FROM business_relationship_period brp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON brp.business_relationship_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;

	filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT T_FILTERED_OBJECT_ROW(brp.business_relationship_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM business_relationship_period brp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON brp.business_relationship_id = t.object_id
	  JOIN tt_filter_date_range dr 
		ON (brp.end_dtm IS NULL OR (brp.end_dtm >= NVL(dr.start_dtm, brp.end_dtm)))
	   AND (dr.end_dtm IS NULL OR (brp.start_dtm < dr.end_dtm));
END;

PROCEDURE FilterTypeId (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN	NUMBER,
	in_ids							IN	T_FILTERED_OBJECT_TABLE,
	out_ids							OUT	T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT filter_value_id_seq.NEXTVAL, in_filter_field_id, brt.business_relationship_type_id, brt.label
		  FROM business_relationship_type brt
		 WHERE brt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = brt.business_relationship_type_id
		 );
	END IF;

	SELECT T_FILTERED_OBJECT_ROW(business_relationship_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM business_relationship a
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON a.business_relationship_id = t.object_id
	  JOIN filter_value fv ON a.business_relationship_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE CompanyFilter (
	in_filter_id					IN	filter.filter_id%TYPE,
	in_filter_field_id				IN	NUMBER,
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
		SELECT T_FILTERED_OBJECT_ROW(brc.company_sid, NULL, NULL)
		  BULK COLLECT INTO v_company_sids
		  FROM business_relationship_company brc
		  JOIN TABLE(in_ids) t ON brc.business_relationship_id = t.object_id;

		company_filter_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_company_sids,
			out_id_list						=> v_company_sids
		);

		SELECT T_FILTERED_OBJECT_ROW(business_relationship_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT business_relationship_id
			  FROM business_relationship_company brc
			  JOIN TABLE(in_ids) ids ON ids.object_id = brc.business_relationship_id
			  JOIN TABLE(v_company_sids) t ON brc.company_sid = t.object_id
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
	SELECT T_FILTERED_OBJECT_ROW(brc.company_sid, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_company_sids
	  FROM business_relationship_company brc
	  JOIN TABLE(in_ids) t ON brc.business_relationship_id = t.object_id;

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
		  
	SELECT T_FILTERED_OBJECT_ROW(brc.business_relationship_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM business_relationship_company brc
	  JOIN TABLE(in_ids) ids ON ids.object_id = brc.business_relationship_id
	  JOIN TABLE(v_company_sids) t ON brc.company_sid = t.object_id;
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

END business_rel_report_pkg;
/
