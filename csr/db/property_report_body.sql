CREATE OR REPLACE PACKAGE BODY CSR.property_report_pkg
IS

-- private field filter units
PROCEDURE FilterPropertyTypeId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPropertySubTypeId	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFlowStateId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFundId				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterMgmtCompanyId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPropertyActiveState	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAcquisitionDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPropertyPostcode	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPropertyCountry		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterScore				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterScoreThreshold		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIssues				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterPropertyIds (
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
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.FilterPropertyIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.FilterPropertyIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);		
		
		IF r.name LIKE 'CmsFilter.%' THEN
			v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, r.filter_field_id);
			cms.filter_pkg.FilterColumnIds(in_filter_id, r.filter_field_id, v_compound_filter_id, r.column_sid, v_starting_ids, v_result_ids);
		ELSIF r.column_sid IS NOT NULL THEN 
			v_property_col_sid := substr(r.name, 0, instr(r.name, '.') - 1);
			v_stripped_name := substr(r.name, length(v_property_col_sid) + 2);
			cms.filter_pkg.FilterEmbeddedField(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, r.comparator, v_property_col_sid, v_stripped_name, r.column_sid, v_starting_ids, v_result_ids);
		ELSIF r.name = 'PropertyTypeId' THEN
			FilterPropertyTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'PropertySubTypeId' THEN
			FilterPropertySubTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'FlowStateId' THEN
			FilterFlowStateId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'FundId' THEN
			FilterFundId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'MgmtCompanyId' THEN
			FilterMgmtCompanyId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'PropertyActiveState' THEN
			FilterPropertyActiveState(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AcquisitionDtm' THEN
			FilterAcquisitionDtm(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'TagGroup.%' THEN
			FilterTag(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'PropertyPostcode' THEN
			FilterPropertyPostcode(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'PropertyCountryCode' THEN
			FilterPropertyCountry(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricText.%' THEN
			region_metric_pkg.FilterRegionMetricText(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricDate.%' THEN
			region_metric_pkg.FilterRegionMetricDate(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricCombo.%' THEN
			region_metric_pkg.FilterRegionMetricCombo(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'RegionMetricNumber.%' THEN
			region_metric_pkg.FilterRegionMetricNumber(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'FilterPageIndInterval%' THEN
			-- Other modules would have to convert id->region sid call this proc, and convert back at this point,
			-- but we don't need to as the ids are already region sids in the property module
			chain.filter_pkg.FilterInd(in_filter_id, r.filter_field_id, r.name, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'ScoreTypeScore.%' THEN
			FilterScore(in_filter_id, r.filter_field_id, r.name, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'ScoreTypeThreshold.%' THEN
			FilterScoreThreshold(in_filter_id, r.filter_field_id, r.name,r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IssueFilter' THEN
			FilterIssues(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
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
	chain.filter_pkg.RunCompoundFilter('FilterPropertyIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, 
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END,
			CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN l.object_id
				ELSE NVL(tfiv.val_number, rmv.val)
			END
	  FROM property p
	  JOIN TABLE(in_id_list) l ON p.region_sid = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	  LEFT JOIN chain.customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id
	  LEFT JOIN chain.tt_filter_ind_val tfiv ON cuat.filter_page_ind_interval_id = tfiv.filter_page_ind_interval_id AND p.region_sid = tfiv.region_sid
	  LEFT JOIN (
			SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
			  FROM region_metric_val crmv	-- Current
			  JOIN TABLE(in_id_list) t ON crmv.region_sid = t.object_id
			 WHERE crmv.effective_dtm <= SYSDATE
			 GROUP BY crmv.region_sid, ind_sid
		) x ON p.region_sid = x.region_sid AND cuat.ind_sid = x.ind_sid
	  LEFT JOIN region_metric_val rmv ON p.app_sid = rmv.app_sid AND x.region_sid = rmv.region_sid AND x.ind_sid = rmv.ind_sid AND x.effective_dtm = rmv.effective_dtm
	;
	
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
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.GetInitialIds');
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	
	-- start with the list they have access to
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM region_role_member rrm
	  JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
	  JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
	  JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
	  JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
	  JOIN property p ON fi.flow_item_id = p.flow_Item_id AND rrm.region_sid = p.region_sid AND rrm.app_sid = p.app_sid
	  JOIN v$region rg ON p.region_sid = rg.region_sid AND p.app_Sid = rg.app_sid
	  LEFT JOIN postcode.country c ON c.country = rg.geo_country
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN p.region_sid END = tr.region_sid
	 WHERE (in_id_list IS NULL OR p.region_sid IN (SELECT DISTINCT object_id FROM TABLE(in_id_list)))
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   -- XXX Should probably switch to text indexes...
	   AND (v_sanitised_search IS NULL
				OR UPPER(rg.description) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(c.name) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(p.city) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(rg.region_ref) LIKE '%'||UPPER(in_search)||'%'
				OR TO_CHAR(p.region_sid) = UPPER(in_search)
		)
	   AND p.region_sid NOT IN (
								   SELECT region_sid
									 FROM csr.v$region
								  CONNECT BY PRIOR region_sid = parent_sid
									START WITH region_sid IN (SELECT region_sid FROM csr.trash JOIN csr.region ON trash_sid = region_sid)
							   )
	 GROUP BY p.region_sid;
	
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
		GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_region_sids, in_start_dtm, in_end_dtm,
			in_region_col_type, in_date_col_type, in_id_list, out_id_list);
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.ApplyBreadcrumb');
	
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
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_scores_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_period_name					reporting_period.name%TYPE;
	v_period_start_dtm				reporting_period.start_dtm%TYPE;
	v_period_end_dtm				reporting_period.end_dtm%TYPE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.CollectSearchResults');
	
	reporting_period_pkg.GetCurrentPeriod(SYS_CONTEXT('SECURITY', 'APP'), v_period_name, v_period_start_dtm, v_period_end_Dtm);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ p.region_sid, p.description, p.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, 
			p.postcode, p.country_code, p.country_name, p.country_currency, NVL(mc.name, p.mgmt_company_other) mgmt_company,
			p.property_type_id, p.property_type_label, p.property_sub_type_id, p.property_sub_type_label, 
			p.flow_item_id, p.current_state_id, p.current_state_label, p.current_state_colour, p.current_state_lookup_key, p.active, 
			p.acquisition_dtm, p.disposal_dtm, p.lng, p.lat,
			f.name fund, cc.name member_name, sheet_status.total_sheets, sheet_status.total_overdue_sheets,
			NVL(photo_counts.number_of_photos, 0) number_of_photos, p.energy_star_sync, p.energy_star_push, -- raw energy star option flags
			p.energy_star_sync is_energy_star, DECODE(p.energy_star_sync, 0, 0, p.energy_star_push) is_energy_star_push, -- takes into account the sync flag being set to zero
			mcc.name mgmt_company_contact_name, mcc.email mgmt_company_contact_email, mcc.phone mgmt_company_contact_phone,
			cir.pct_compliant comp_pct_compliant, cir.pct_compliant_colour comp_pct_compliant_colour, 
			pir.pct_compliant permit_pct_compliant, pir.pct_compliant_colour permit_pct_compliant_colour,
			pg.asset_id gresb_asset_id
		  FROM v$property p
		  LEFT JOIN fund f ON p.fund_id = f.fund_id
		  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id
		  LEFT JOIN mgmt_company_contact mcc ON p.mgmt_company_contact_id = mcc.mgmt_company_contact_id
		  LEFT JOIN property_gresb pg ON pg.region_sid = p.region_sid
		  LEFT JOIN chain.company cc ON p.company_sid = cc.company_sid AND p.app_sid = cc.app_sid
		  LEFT JOIN (
			-- Get total of sheets + overdue sheets for each region/property.
			SELECT COUNT(s.sheet_id) total_sheets, COUNT(CASE WHEN sla.status = 1 THEN 1 ELSE NULL END) total_overdue_sheets, dr.region_sid
			  FROM csr.sheet s
			  JOIN csr.delegation_region dr
				ON s.delegation_sid = dr.delegation_sid
			  JOIN csr.delegation d
				ON d.delegation_sid = dr.delegation_sid
			  JOIN csr.sheet_with_last_action sla
				ON sla.sheet_id = s.sheet_id
			 WHERE s.is_visible = 1
			   AND s.start_dtm <= v_period_end_dtm 
			   AND s.end_dtm > v_period_start_dtm
			 GROUP BY dr.region_sid
		  ) sheet_status ON p.region_sid = sheet_status.region_sid
		  LEFT JOIN (
			SELECT property_region_sid, COUNT(property_photo_id) number_of_photos
			  FROM property_photo
			 WHERE space_region_sid IS NULL
			 GROUP BY property_region_sid
		  ) photo_counts ON p.region_sid = photo_counts.property_region_sid
		  LEFT JOIN csr.v$compliance_item_rag cir ON cir.region_sid = p.region_sid
		  LEFT JOIN v$permit_item_rag pir ON pir.region_sid = p.region_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = p.region_sid
		 ORDER BY fil_list.pos;
		 
	tag_pkg.UNSEC_GetRegionTags(in_id_list, out_tags_cur);
	
	OPEN out_roles_cur FOR
		SELECT rrm.region_sid, rrm.role_sid, cu.full_name, cu.email, cu.csr_user_sid user_sid, r.name role_name,
			MIN(CASE WHEN rrm.inherited_from_sid != region_sid THEN 1 ELSE 0 END) is_inherited, cu.active is_active
		  FROM region_role_member rrm
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = rrm.region_sid
		  JOIN v$csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		  JOIN role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		 GROUP BY rrm.region_sid, rrm.role_sid, cu.full_name, cu.email, cu.csr_user_sid, r.name, cu.Active
		 ORDER BY rrm.region_sid, rrm.role_sid, MIN(CASE WHEN rrm.inherited_from_sid != region_sid THEN 1 ELSE 0 END) DESC, LOWER(cu.full_name);
		 
		 
	region_metric_pkg.UNSEC_GetMetricsForRegions(in_id_list, out_metrics_cur);
			
	OPEN out_inds_cur FOR
		SELECT ti.filter_page_ind_interval_id, ti.ind_sid, ti.region_sid, ti.period_start_dtm, ti.period_end_dtm, ti.val_number, ti.error_code, ti.note
		  FROM chain.tt_filter_ind_val ti
		  JOIN TABLE(in_id_list) t ON ti.region_sid = t.sid_id;
		  
	OPEN out_scores_cur FOR
		SELECT rs.region_sid, rs.score_type_id, rsl.score_threshold_id, rsl.score, st.label score_type_label, st.format_mask,
			   sth.description threshold_description, sth.text_colour, sth.background_colour
		  FROM region_score rs
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = rs.region_sid
		  JOIN region_score_log rsl ON rs.last_region_score_log_id = rsl.region_score_log_id
		  JOIN score_type st ON rsl.score_type_id = st.score_type_id
		  JOIN score_threshold sth ON rsl.score_threshold_id = sth.score_threshold_id
		 WHERE st.hidden = 0;
		 
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredPropertyIds (
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.PageFilteredPropertyIds');
	
	IF in_order_by = 'description' AND in_order_dir = 'ASC' THEN
		-- default query when you hit the page, use quick version
		-- without joins
		SELECT security.T_ORDERED_SID_ROW(region_sid, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.region_sid, ROWNUM rn
			  FROM (
				SELECT p.region_sid
				  FROM v$property p
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = p.region_sid
				 ORDER BY LOWER(p.description)
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
					SELECT p.region_sid
					  FROM v$property p
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = p.region_sid
					  LEFT JOIN fund f ON p.fund_id = f.fund_id
					  LEFT JOIN mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id 
					  LEFT JOIN mgmt_company_contact mcc ON p.mgmt_company_contact_id = mcc.mgmt_company_contact_id
					  LEFT JOIN (
						SELECT ort.region_sid, ort.tag_group_id, stragg(ort.tag) tags
						  FROM (
							SELECT rt.region_sid, tgm.tag_group_id, t.tag
							  FROM region_tag rt
							  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id AND rt.app_sid = tgm.app_sid
							  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) ort
						 GROUP BY ort.region_sid, ort.tag_group_id
						) rts ON p.region_sid = rts.region_sid
					  LEFT JOIN (
						SELECT rmv.region_sid, NVL(TO_CHAR(rmv.val, '000000000000000000000000.0000000000'), LOWER(rmv.note)) str_val
						  FROM region_metric_val rmv
						  JOIN (
							SELECT crmv.region_sid, crmv.ind_sid, MAX(crmv.effective_dtm) effective_dtm
							  FROM region_metric_val crmv	-- Current
							 WHERE crmv.effective_dtm <= SYSDATE
							   AND crmv.ind_sid = v_order_by_id
							 GROUP BY crmv.region_sid, crmv.ind_sid
							) x ON rmv.region_sid = x.region_sid AND rmv.ind_sid = x.ind_sid AND rmv.effective_dtm = x.effective_dtm
					  ) rm ON p.region_sid = rm.region_sid
					  LEFT JOIN (
						SELECT fiv.region_sid, NVL(TO_CHAR(fiv.val_number, '000000000000000000000000.0000000000'), LOWER(fiv.note)) str_val
						  FROM chain.tt_filter_ind_val fiv
						 WHERE fiv.filter_page_ind_interval_id = v_order_by_id
					  ) im ON p.region_sid = im.region_sid
					  LEFT JOIN (
						SELECT crs.region_sid, TO_CHAR(rsl.score, '000000000000000.00000') score, LOWER(st.description) threshold_description
						  FROM region_score crs
						  JOIN region_score_log rsl ON crs.last_region_score_log_id = rsl.region_score_log_id
						  LEFT JOIN score_threshold st ON rsl.score_threshold_id = st.score_threshold_id
						 WHERE crs.score_type_id = v_order_by_id
					  ) rs ON p.region_sid = rs.region_sid
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'regionSid' THEN TO_CHAR(p.region_sid, '0000000000')								
									WHEN 'description' THEN LOWER(p.description)
									WHEN 'streetAddr' THEN LOWER(p.street_addr_1)
									WHEN 'streetAddr2' THEN LOWER(p.street_addr_2)
									WHEN 'city' THEN LOWER(p.city)
									WHEN 'state' THEN LOWER(p.state)
									WHEN 'postcode' THEN LOWER(p.postcode)
									WHEN 'countryName' THEN LOWER(p.country_name)
									WHEN 'countryCode' THEN LOWER(p.country_code)
									WHEN 'countryCurrency' THEN LOWER(p.country_currency)
									WHEN 'propertyTypeLabel' THEN LOWER(p.property_type_label)
									WHEN 'currentStateLabel' THEN LOWER(p.current_state_label)
									WHEN 'propertySubTypeLabel' THEN LOWER(p.property_sub_type_label)
									WHEN 'fund' THEN LOWER(f.name)
									WHEN 'mgmtCompany' THEN LOWER(mc.name)
									WHEN 'managementCompanyContactName' THEN LOWER(mcc.name)
									WHEN 'managementCompanyContactPhone' THEN LOWER(mcc.phone)
									WHEN 'regionRef' THEN LOWER(p.region_ref)
									WHEN 'acquisitionDtm' THEN TO_CHAR(p.acquisition_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tagGroup' THEN TO_CHAR(rts.tags)
									WHEN 'metric' THEN NVL(rm.str_val, ' ') -- treat nulls as something less than zero
									WHEN 'ind' THEN NVL(im.str_val, ' ') -- treat nulls as something less than zero
									WHEN 'scoreTypeScore' THEN NVL(rs.score, ' ') -- treat nulls as something less than zero
									WHEN 'scoreTypeThreshold' THEN NVL(rs.threshold_description, ' ') -- treat nulls as something less than zero
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'regionSid' THEN TO_CHAR(p.region_sid, '0000000000')								
									WHEN 'description' THEN LOWER(p.description)
									WHEN 'streetAddr' THEN LOWER(p.street_addr_1)
									WHEN 'streetAddr2' THEN LOWER(p.street_addr_2)
									WHEN 'city' THEN LOWER(p.city)
									WHEN 'state' THEN LOWER(p.state)
									WHEN 'postcode' THEN LOWER(p.postcode)
									WHEN 'countryName' THEN LOWER(p.country_name)
									WHEN 'countryCode' THEN LOWER(p.country_code)
									WHEN 'countryCurrency' THEN LOWER(p.country_currency)
									WHEN 'propertyTypeLabel' THEN LOWER(p.property_type_label)
									WHEN 'currentStateLabel' THEN LOWER(p.current_state_label)
									WHEN 'propertySubTypeLabel' THEN LOWER(p.property_sub_type_label)
									WHEN 'fund' THEN LOWER(f.name)
									WHEN 'mgmtCompany' THEN LOWER(mc.name)
									WHEN 'managementCompanyContactName' THEN LOWER(mcc.name)
									WHEN 'managementCompanyContactPhone' THEN LOWER(mcc.phone)
									WHEN 'regionRef' THEN LOWER(p.region_ref)
									WHEN 'acquisitionDtm' THEN TO_CHAR(p.acquisition_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tagGroup' THEN TO_CHAR(rts.tags)
									WHEN 'metric' THEN NVL(rm.str_val, ' ') -- treat nulls as something less than zero
									WHEN 'ind' THEN NVL(im.str_val, ' ') -- treat nulls as something less than zero
									WHEN 'scoreTypeScore' THEN NVL(rs.score, ' ') -- treat nulls as something less than zero
									WHEN 'scoreTypeThreshold' THEN NVL(rs.threshold_description, ' ') -- treat nulls as something less than zero
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN p.region_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN p.region_sid END ASC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_PROPERTY, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Property -> '||v_name);

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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_scores_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_geo_filtered_list				chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.GetPropertyList', in_compound_filter_id);
	
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

	-- Filter by map bounds if appropriate
	IF in_bounds_north IS NOT NULL AND in_bounds_east IS NOT NULL AND in_bounds_south IS NOT NULL AND in_bounds_west IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, NULL, NULL)
		  BULK COLLECT INTO v_geo_filtered_list
		  FROM region r
		  JOIN TABLE(v_id_list) t ON r.region_sid = t.object_id
		 WHERE r.geo_longitude-in_bounds_west-360*FLOOR((r.geo_longitude-in_bounds_west)/360) BETWEEN 0 AND in_bounds_east-in_bounds_west
		   AND r.geo_latitude BETWEEN in_bounds_south AND in_bounds_north;

		v_id_list := v_geo_filtered_list;
	END IF;

	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);
	
	PageFilteredPropertyIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_tags_cur, out_roles_cur, out_metrics_cur, out_inds_cur, out_scores_cur);
	
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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_PROPERTY, a.aggregate_type_id, a.description, a.format_mask,
		   a.filter_page_ind_interval_id, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM (
		SELECT at.aggregate_type_id, at.description, null format_mask, null filter_page_ind_interval_id, NVL(sat.pos, at.aggregate_type_id) pos
		  FROM chain.aggregate_type at
		  JOIN TABLE(in_aggregation_types) sat ON at.aggregate_type_id = sat.sid_id
		 WHERE at.card_group_id = chain.filter_pkg.FILTER_TYPE_PROPERTY
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
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.GetReportData', in_compound_filter_id);
	
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
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_PROPERTY, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
		SELECT /*+ALL_ROWS*/ p.region_sid object_id, p.region_sid, p.description, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, 
				p.country_name, p.property_type_id, p.property_type_label, p.current_state_label, p.property_sub_type_label, p.lookup_key,
				'/property/'||p.region_sid property_link
		  FROM v$property p
		  JOIN TABLE(in_id_list) fil_list ON fil_list.object_id = p.region_sid;
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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_scores_cur					OUT security_pkg.T_OUTPUT_CUR
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
	
	CollectSearchResults(v_id_page, out_cur, out_tags_cur, out_roles_cur, out_metrics_cur, out_inds_cur, out_scores_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_inds_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_scores_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.property_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_PROPERTY
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
		out_roles_cur				=> out_roles_cur,
		out_metrics_cur				=> out_metrics_cur,
		out_inds_cur				=> out_inds_cur,
		out_scores_cur				=> out_scores_cur
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

PROCEDURE FilterPropertyTypeId (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pt.property_type_id, pt.label
		  FROM property_type pt
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = pt.property_type_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM property p
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON p.property_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPropertySubTypeId (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, pst.property_sub_type_id, pt.label||' - '||pst.label
		  FROM property_sub_type pst
		  JOIN property_type pt ON pst.property_type_id = pt.property_type_id
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = pst.property_sub_type_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM property p
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv 
		ON p.property_sub_type_id = fv.num_value 
		OR (p.property_sub_type_id IS NULL AND 
			fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterFlowStateId (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, fs.flow_state_id, fs.label
		  FROM flow_state fs
		 WHERE fs.flow_sid IN (
			SELECT property_flow_sid
			  FROM customer
		 )		 
		   AND fs.is_deleted = 0
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = fs.flow_state_id
		 );
	END IF;
	
	chain.filter_pkg.SortFlowStateValues(in_filter_field_id);
	chain.filter_pkg.SetFlowStateColours(in_filter_field_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM property p
	  JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON fi.current_state_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterFundId (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, f.fund_id, f.name
		  FROM fund f
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = f.fund_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM property p
	  LEFT JOIN property_fund pf ON p.region_sid = pf.region_sid AND p.app_sid = pf.app_sid
	  LEFT JOIN fund f ON pf.fund_id = f.fund_id AND p.app_sid = f.app_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON pf.fund_id = fv.num_value
		OR (pf.fund_id IS NULL AND fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterMgmtCompanyId (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, m.mgmt_company_id, m.name
		  FROM mgmt_company m
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = m.mgmt_company_id
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM property p
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON p.mgmt_company_id = fv.num_value
		OR (p.mgmt_company_id IS NULL AND fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;
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

	WITH group_tags AS (
		SELECT rt.app_sid, rt.region_sid, rt.tag_id
		  FROM region_tag rt
		  JOIN tag_group_member tgm ON tgm.app_sid = rt.app_sid AND tgm.tag_id = rt.tag_id
		 WHERE tgm.tag_group_id = v_tag_group_id)
	SELECT chain.T_FILTERED_OBJECT_ROW(r.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region r
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON r.region_sid = t.object_id
	  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
	 WHERE (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(r.app_sid, r.region_sid) NOT IN (SELECT app_sid, region_sid FROM group_tags))
		OR (fv.null_filter != chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			(r.app_sid, r.region_sid) IN (
				SELECT app_sid, region_sid
				  FROM group_tags gt
				 WHERE fv.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
					OR gt.tag_id = fv.num_value));
END;

PROCEDURE FilterPropertyActiveState (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
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

	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM property p
	  JOIN region r ON p.region_sid = r.region_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON r.active = fv.num_value
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
		SELECT MIN(p.acquisition_dtm), MAX(p.acquisition_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$property p
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 0
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$property p
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr 
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			p.acquisition_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			p.acquisition_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			p.acquisition_dtm IS NOT NULL AND
			p.acquisition_dtm >= NVL(dr.start_dtm, p.acquisition_dtm) AND 
			(dr.end_dtm IS NULL OR p.acquisition_dtm < dr.end_dtm));
END;

PROCEDURE FilterPropertyPostcode (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$property p
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(p.postcode) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPropertyCountry (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$property p
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
	  JOIN chain.filter_value fv ON LOWER(p.country_code) like '%'||LOWER(fv.str_value)||'%' 
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterScore (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_score_type_id					NUMBER;
BEGIN
	v_score_type_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, min_num_val, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, chain.filter_pkg.NUMBER_EQUAL, sts.score, sts.score
		  FROM (
			  SELECT DISTINCT rsl.score
				FROM region_score rs
				JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rs.region_sid = t.object_id
				JOIN region_score_log rsl ON rs.last_region_score_log_id = rsl.region_score_log_id
			   WHERE rs.score_type_id = v_score_type_id
		) sts
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND num_value = chain.filter_pkg.NUMBER_EQUAL
			   AND fv.min_num_val = sts.score
		 );
	END IF;
	
	chain.filter_pkg.SortNumberValues(in_filter_field_id);	
	
	SELECT chain.T_FILTERED_OBJECT_ROW(rs.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region_score rs
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rs.region_sid = t.object_id
	  JOIN region_score_log rsl ON rs.last_region_score_log_id = rsl.region_score_log_id
	  CROSS JOIN chain.filter_value fv
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND chain.filter_pkg.CheckNumberRange(rsl.score, fv.num_value, fv.min_num_val, fv.max_num_val) = 1;

END;

PROCEDURE FilterScoreThreshold (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_filter_field_name			IN chain.filter_field.name%TYPE,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_score_type_id					NUMBER;
BEGIN
	v_score_type_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, st.description
		  FROM score_threshold st
		 WHERE st.score_type_id = v_score_type_id
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = st.score_threshold_id
		 );
	END IF;	

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);

	chain.filter_pkg.SetThresholdColours(in_filter_field_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(rs.region_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM region_score rs
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rs.region_sid = t.object_id
	  JOIN region_score_log rsl ON rs.last_region_score_log_id = rsl.region_score_log_id
	  JOIN chain.filter_value fv ON rsl.score_threshold_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionSid (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT p.region_sid
			  FROM property p
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
			 WHERE p.region_sid IS NOT NULL
			 GROUP BY p.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, p.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT p.region_sid, fv.filter_value_id
			  FROM property p
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
			  JOIN chain.filter_value fv ON p.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) p;
	ELSE
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(p.region_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM property p
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON p.region_sid = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON p.region_sid = r.region_sid;				 
	END IF;	
END;

PROCEDURE FilterIssues (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_issue_ids						chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert property sids to issue ids
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
		  BULK COLLECT INTO v_issue_ids
		  FROM issue i
		  JOIN TABLE(in_ids) t ON i.region_sid = t.object_id
		 WHERE i.issue_type_id = csr_data_pkg.ISSUE_PROPERTY;
		  
		-- filter issues
		issue_report_pkg.GetFilteredIds(
			in_compound_filter_id	=> v_compound_filter_id,
			in_id_list				=> v_issue_ids,
			out_id_list				=> v_issue_ids
		);
		
		-- convert issue ids to property sids
		SELECT chain.T_FILTERED_OBJECT_ROW(i.region_sid, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN TABLE(v_issue_ids) t ON i.issue_id = t.object_id;
	END IF;
END;

END property_report_pkg;
/
