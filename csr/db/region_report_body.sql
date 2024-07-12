CREATE OR REPLACE PACKAGE BODY csr.region_report_pkg AS

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionActive		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionRef			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterGeoCountry			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterGeoRegion			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAcquisitionDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLookupkey			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF LOWER(in_name) = 'regionsid' THEN
		FilterRegionSid(in_filter_id, in_filter_field_id, in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'active' THEN
		FilterRegionActive(in_filter_id, in_filter_field_id, in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'regionref' THEN
		FilterRegionRef(in_filter_id, in_filter_field_id,  in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'geocountry' THEN
		FilterGeoCountry(in_filter_id, in_filter_field_id,  in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'georegion' THEN
		FilterGeoRegion(in_filter_id, in_filter_field_id,  in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'acquisitiondtm' THEN
		FilterAcquisitionDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'regiontype' THEN
		FilterRegionType(in_filter_id, in_filter_field_id, in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) = 'lookupkey' THEN
		FilterLookupkey(in_filter_id, in_filter_field_id, in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) LIKE 'taggroup.%' THEN
		FilterTag(in_filter_id, in_filter_field_id, in_name, in_show_all, in_group_by_index, in_sids, out_sids);
	ELSIF LOWER(in_name) LIKE 'filterpageindinterval%' THEN
		chain.filter_pkg.FilterInd(in_filter_id, in_filter_field_id, in_name, in_show_all, in_sids, out_sids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_name);
	END IF;
END;

PROCEDURE FilterRegionSids (
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
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.FilterRegionSids', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.FilterRegionSids.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		RunSingleUnit(
			in_name				=> r.name,
			in_column_sid		=> r.column_sid,
			in_filter_id		=> in_filter_id,
			in_filter_field_id	=> r.filter_field_id,
			in_group_by_index	=> r.group_by_index,
			in_show_all			=> r.show_all,
			in_sids				=> v_starting_ids,
			out_sids			=> v_result_ids
		);
		
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
	chain.filter_pkg.RunCompoundFilter('FilterRegionSids', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;
 
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, chain.filter_pkg.AFUNC_SUM,
			CASE a.column_value
				WHEN 1 THEN COUNT(DISTINCT r.region_sid)
			END
	  FROM v$region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON r.region_sid = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	 GROUP BY l.object_id, a.column_value;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_region_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_start_dtm					IN	DATE DEFAULT NULL,
	in_end_dtm						IN	DATE DEFAULT NULL,
	in_region_col_type				IN	NUMBER DEFAULT NULL,
	in_date_col_type				IN	NUMBER DEFAULT NULL,
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_region_sids					security.T_SID_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.GetInitialIds');
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	-- start with the list they have access to
	SELECT r.region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM v$region r
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN r.region_sid END = tr.region_sid
	 WHERE (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_search IS NULL 
		OR LOWER(r.description) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.lookup_key) LIKE '%'||LOWER(in_search)||'%'
		OR LOWER(r.region_ref) LIKE '%'||LOWER(in_search)||'%'
		)
		AND r.region_sid NOT IN (
									SELECT region_sid
									  FROM csr.v$region
								   CONNECT BY PRIOR region_sid = parent_sid
									 START WITH region_sid IN (SELECT region_sid FROM csr.trash JOIN csr.region ON trash_sid = region_sid)
								);

	SELECT chain.T_FILTERED_OBJECT_ROW(sid_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM TABLE(securableobject_pkg.GetSIDsWithPermAsTable(security_pkg.GetAct, v_region_sids, 1));
	
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
	
	chain.filter_pkg.EndDebugLog(v_log_id);
	aspen2.request_queue_pkg.AssertRequestStillActive;
END;

PROCEDURE ConvertIdsToRegionSids(
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_region_sids					OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	out_region_sids := in_id_list;
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
		GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_region_sids, in_start_dtm, in_end_dtm, in_region_col_type, in_date_col_type, in_id_list, out_id_list);
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(id, NULL, NULL)
		  BULK COLLECT INTO out_id_list
		  FROM chain.tt_filter_id;
	END IF;
	
	-- If there's a filter, restrict the list of ids
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.ApplyBreadcrumb');
	
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
	out_cur 						OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.CollectSearchResults');
	
	OPEN out_cur FOR 
		SELECT region_sid, description, active, acquisition_dtm, pc.name geo_country, 
			   pr.name geo_region, region_type, lookup_key, info_xml, region_ref
		  FROM v$region r
		  LEFT JOIN postcode.country pc ON r.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON r.geo_country = pr.country AND r.geo_region = pr.region
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = r.region_sid
		 ORDER BY fil_list.pos;

	OPEN out_tags FOR
		SELECT fil_list.sid_id region_sid, t.tag_id, t.tag
		  FROM TABLE (in_id_list) fil_list
		  JOIN region_tag rt ON fil_list.sid_id = rt.region_sid
		  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id
		  JOIN v$tag t ON rt.tag_id = t.tag_id
		 ORDER BY tgm.tag_group_id, tgm.pos;
		 
	 OPEN out_inds_cur FOR
		SELECT ti.filter_page_ind_interval_id, ti.ind_sid, ti.region_sid, ti.period_start_dtm, ti.period_end_dtm, ti.val_number, ti.error_code, ti.note
		  FROM chain.tt_filter_ind_val ti
		  JOIN TABLE(in_id_list) t ON ti.region_sid = t.sid_id;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredRegionSids (
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.PageFilteredRegionSids');

	IF in_order_by = 'acquisitionDtm' AND in_order_dir = 'DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.object_id, ROWNUM rn
			  FROM (
				SELECT fil_list.object_id
				  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list
				  JOIN v$region r ON fil_list.object_id = r.region_sid
				 ORDER BY r.acquisition_dtm DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
				
		SELECT security.T_ORDERED_SID_ROW(region_sid, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.region_sid, ROWNUM rn
				  FROM (
					SELECT r.region_sid
					  FROM v$region r
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = r.region_sid
					  LEFT JOIN (
						SELECT fiv.region_sid, NVL(TO_CHAR(fiv.val_number, '000000000000000000000000.0000000000'), LOWER(fiv.note)) str_val
						  FROM chain.tt_filter_ind_val fiv
						 WHERE fiv.filter_page_ind_interval_id = v_order_by_id
					  ) im ON r.region_sid = im.region_sid
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'regionSid' THEN LOWER(r.region_sid)
									WHEN 'description' THEN LOWER(r.description)
									WHEN 'active' THEN LOWER(r.active)
									WHEN 'acquisitionDtm' THEN TO_CHAR(r.acquisition_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'regionType' THEN LOWER(r.region_type)
									WHEN 'lookupKey' THEN LOWER(r.lookup_key)
									WHEN 'geoCountry' THEN LOWER(r.geo_country)
									WHEN 'geoRegion' THEN LOWER(r.geo_region)
									WHEN 'regionRef' THEN LOWER(r.region_ref)
									WHEN 'ind' THEN NVL(im.str_val, ' ')
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'regionSid' THEN LOWER(r.region_sid)
									WHEN 'description' THEN LOWER(r.description)
									WHEN 'active' THEN LOWER(r.active)
									WHEN 'acquisitionDtm' THEN TO_CHAR(r.acquisition_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'regionType' THEN LOWER(r.region_type)
									WHEN 'lookupKey' THEN LOWER(r.lookup_key)
									WHEN 'geoCountry' THEN LOWER(r.geo_country)
									WHEN 'geoRegion' THEN LOWER(r.geo_region)
									WHEN 'regionRef' THEN LOWER(r.region_ref)
									WHEN 'ind' THEN NVL(im.str_val, ' ')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN r.region_sid END ASC,
							CASE WHEN in_order_dir='DESC' THEN r.region_sid END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_REGIONS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Region -> '||v_name);

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
	in_session_prefix				IN	chain.customer_filter_column.session_prefix%TYPE DEFAULT NULL,
	out_total_rows					OUT	NUMBER,
	out_cur 						OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.GetRegionList', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
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
	
	PageFilteredRegionSids(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_tags_cur, out_inds_cur);
	
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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_REGIONS, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM (
		SELECT at.aggregate_type_id, at.description, null format_mask, null filter_page_ind_interval_id, NVL(sat.pos, at.aggregate_type_id) pos
		  FROM chain.aggregate_type at
		  JOIN TABLE(in_aggregation_types) sat ON at.aggregate_type_id = sat.sid_id
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_REGIONS
		 UNION
		SELECT cuat.customer_aggregate_type_id, i.description, NVL(i.format_mask, m.format_mask), null filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN v$ind i ON cuat.app_sid = i.app_sid AND cuat.ind_sid = i.ind_sid
		  JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_PROPERTY
		 UNION
		SELECT cuat.customer_aggregate_type_id, fi.description, NVL(fi.format_mask, fm.format_mask), fpii.filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN chain.filter_page_ind_interval fpii ON cuat.filter_page_ind_interval_id = fpii.filter_page_ind_interval_id
		  JOIN chain.filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id
		  JOIN v$ind fi ON fpi.app_sid = fi.app_sid AND fpi.ind_sid = fi.ind_sid
		  JOIN measure fm ON fi.measure_sid = fm.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_PROPERTY
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
	in_id_list_populated			IN  NUMBER DEFAULT NULL,
	out_field_cur					OUT	SYS_REFCURSOR,
	out_data_cur					OUT	SYS_REFCURSOR,
	out_extra_series_cur			OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT_REG;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.GetReportData', in_compound_filter_id);
	
	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
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
	
	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_REGIONS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
	out_cur							OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN

	GetFilteredIds(
		in_search				=> in_search,
		in_pre_filter_sid		=> in_pre_filter_sid,
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
	
	CollectSearchResults(v_id_page, out_cur, out_tags, out_inds_cur);
	
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT SYS_REFCURSOR,
	out_tags						OUT SYS_REFCURSOR,
	out_inds_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.region_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_REGIONS
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
		out_tags					=> out_tags,
		out_inds_cur				=> out_inds_cur
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
PROCEDURE FilterRegionSid (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER, 
	in_show_all						IN  NUMBER, 
	in_group_by_index				IN  NUMBER, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT t.object_id region_sid
			  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
			 GROUP BY t.object_id
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(i.region_sid, in_group_by_index, i.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT t.object_id region_sid, fv.filter_value_id
			  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
			  JOIN chain.filter_value fv ON t.object_id = fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) i;
	ELSE
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t 
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON t.object_id = r.region_sid;				 
	END IF;	
END;

PROCEDURE FilterRegionActive (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER, 
	in_show_all						IN  NUMBER, 
	in_group_by_index				IN  NUMBER, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, num_value, description
		  FROM (
		  	SELECT 1 AS num_value, 'Yes' AS description FROM DUAL
			 UNION
			SELECT 0 AS num_value, 'No' AS description FROM DUAL
		 	) tmp
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = tmp.num_value
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON r.active = fv.num_value 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionRef (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_group_by_index				IN  NUMBER,  
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(r.region_ref) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionType (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER, 
	in_show_all						IN  NUMBER, 
	in_group_by_index				IN  NUMBER, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.region_type, i.label
		  FROM (
			SELECT DISTINCT crt.region_type, rt.label
			  FROM customer_region_type crt
			  JOIN region_type rt ON crt.region_type = rt.region_type
			 ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
				AND fv.num_value = i.region_type
		 );		
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON r.region_type = fv.num_value 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterGeoCountry (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_group_by_index				IN  NUMBER,  
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.geo_country, i.name
		  FROM (
			SELECT DISTINCT r.geo_country, c.name
			  FROM region r
			  JOIN TABLE(in_ids) t ON r.region_sid = t.object_id
			  JOIN postcode.country c ON r.geo_country = c.country
			 WHERE geo_country IS NOT NULL
			 ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
				AND fv.str_value = i.geo_country
		 );		
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(r.geo_country) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterGeoRegion (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_group_by_index				IN  NUMBER,  
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.geo_region, i.name
		  FROM (
			SELECT DISTINCT r.geo_region, pr.name
			  FROM region r
			  JOIN TABLE(in_ids) t ON r.region_sid = t.object_id
			  JOIN postcode.region pr ON r.geo_region = pr.region
			 WHERE geo_region IS NOT NULL
			 ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
				AND fv.str_value = i.geo_region
		 );		
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(r.geo_region) = LOWER(fv.str_value)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLookupkey (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id				IN  NUMBER, 
	in_show_all						IN  NUMBER, 
	in_group_by_index				IN  NUMBER, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_ids 						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(r.lookup_key) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAcquisitionDtm (
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
		SELECT MIN(r.acquisition_dtm), MAX(r.acquisition_dtm)
		  INTO v_min_date, v_max_date
		  FROM region r
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr 
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			r.acquisition_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			r.acquisition_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			r.acquisition_dtm IS NOT NULL AND
			r.acquisition_dtm >= NVL(dr.start_dtm, r.acquisition_dtm ) AND 
			(dr.end_dtm IS NULL OR r.acquisition_dtm < dr.end_dtm));
END;

PROCEDURE FilterTag (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN  chain.filter_field.name%TYPE,
	in_show_all						IN  NUMBER,
	in_group_by_index				IN  NUMBER, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_tag_group_id	 				NUMBER;
    v_empty_filter_exists           NUMBER;
    v_out_filter_null_id            chain.filter_value.filter_value_id%TYPE;	
BEGIN
	v_tag_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	IF in_show_all = 1 THEN
		chain.filter_pkg.ShowAllTags(in_filter_field_id, v_tag_group_id);
		
		SELECT COUNT(*)
		  INTO v_empty_filter_exists 
		  FROM chain.filter_value
		 WHERE filter_field_id = in_filter_field_id
		   AND num_value IS NULL
		   AND null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL;

		IF v_empty_filter_exists < 1 THEN
		  chain.filter_pkg.AddNumberValue(in_filter_field_id, NULL, 'Is empty', 1, v_out_filter_null_id);
		END IF;		
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  LEFT JOIN (
		SELECT rt.app_sid, rt.region_sid, rt.tag_id
		  FROM region_tag rt
		  JOIN tag_group_member tgm ON tgm.app_sid = rt.app_sid AND tgm.tag_id = rt.tag_id AND tgm.tag_group_id = v_tag_group_id
	  ) rt ON r.app_sid = rt.app_sid AND r.region_sid = rt.region_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) T ON r.region_sid = t.object_id 
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id AND ((fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND rt.region_sid IS NULL) OR fv.num_value = rt.tag_id);
END;

END region_report_pkg;
/
