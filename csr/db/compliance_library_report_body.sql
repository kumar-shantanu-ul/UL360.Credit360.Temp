CREATE OR REPLACE PACKAGE BODY CSR.compliance_library_report_pkg
IS

-- private field filter units
PROCEDURE FilterType				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterStatus				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCountry				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCountryGroup		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterUpdatedDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTag					(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_filter_field_name IN chain.filter_field.name%TYPE, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSource				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAdoptedDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCountOfLegRegItems	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE RunSingleUnit (
	in_name							IN	chain.filter_field.name%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
) AS
BEGIN
	IF in_name = 'UpdatedDtm' THEN
		FilterUpdatedDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CreatedDtm' THEN
		FilterCreatedDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'AdoptedDtm' THEN
		FilterAdoptedDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name LIKE 'TagGroup.%' THEN
		FilterTag(in_filter_id, in_filter_field_id, in_name, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Source' THEN
		FilterSource(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Type' THEN
		FilterType(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'Status' THEN
		FilterStatus(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CountryCode' THEN
		FilterCountry(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CountryGroup' THEN
		FilterCountryGroup(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CountOfLegalRegisterItems' THEN
		FilterCountOfLegRegItems(in_filter_id, in_filter_field_id, in_group_by_index, in_sids, out_sids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_name);
	END IF;
END;

PROCEDURE FilterComplianceItemIds (
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

	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.FilterComplianceItemIds', in_filter_id);

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, comparator, column_sid
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.FilterComplianceItemIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		RunSingleUnit(r.name, r.column_sid, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);

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
	chain.filter_pkg.RunCompoundFilter('FilterComplianceItemIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id,
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END, l.object_id
	  FROM compliance_item ci
	  JOIN TABLE(in_id_list) l ON ci.compliance_item_id = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a;

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
	v_temp_id_list					chain.T_FILTERED_OBJECT_TABLE;
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseTextSearchForContains(in_search);
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_can_manage_compliances		BOOLEAN;
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
	v_language						security.user_table.language%TYPE := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.GetFilteredIds', in_compound_filter_id);

	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	v_can_manage_compliances := csr_data_pkg.CheckCapability('Manage compliance items');

	-- start with the list they have access to
	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM compliance_item ci
	  -- Base lang
	  JOIN aspen2.lang l_base ON l_base.lang = 'en'
	  LEFT JOIN compliance_language cl_base ON cl_base.app_sid = ci.app_sid AND cl_base.lang_id = l_base.lang_id
	  LEFT JOIN compliance_item_description cid_base ON ci.compliance_item_id = cid_base.compliance_item_id AND ci.app_sid = cid_base.app_sid AND cl_base.lang_id = cid_base.lang_id
	  -- User lang
	  JOIN aspen2.lang l_user ON l_user.lang = v_language
	  LEFT JOIN compliance_language cl_user ON cl_user.app_sid = ci.app_sid AND cl_user.lang_id = l_user.lang_id
	  LEFT JOIN compliance_item_description cid_user ON ci.compliance_item_id = cid_user.compliance_item_id AND ci.app_sid = cid_user.app_sid AND cl_user.lang_id = cid_user.lang_id
	  -- User parent lang
	  LEFT JOIN aspen2.lang l_user_parent ON l_user_parent.lang_id = l_user.parent_lang_id
	  LEFT JOIN compliance_language cl_user_parent ON cl_user_parent.app_sid = ci.app_sid AND cl_user_parent.lang_id = l_user_parent.lang_id
	  LEFT JOIN compliance_item_description cid_user_parent ON ci.compliance_item_id = cid_user_parent.compliance_item_id AND ci.app_sid = cid_user_parent.app_sid
		AND cl_user_parent.lang_id = cid_user_parent.lang_id
	  LEFT JOIN compliance_item_region cir ON ci.app_sid = cir.app_sid AND ci.compliance_item_id = cir.compliance_item_id
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN cir.region_sid END = tr.region_sid
	  LEFT JOIN compliance_permit_condition cpc ON ci.compliance_item_id = cpc.compliance_item_id
	 WHERE (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_search IS NULL
		-- Use CONTAINS on the potentially large text fields - will only support whole word matches.
		OR CONTAINS (cid_user.title, v_sanitised_search) > 0
		OR CONTAINS (cid_user.summary, v_sanitised_search) > 0
		OR CONTAINS (cid_user.details, v_sanitised_search) > 0
		OR CONTAINS (cid_user.citation, v_sanitised_search) > 0
		OR CONTAINS (cid_user_parent.title, v_sanitised_search) > 0
		OR CONTAINS (cid_user_parent.summary, v_sanitised_search) > 0
		OR CONTAINS (cid_user_parent.details, v_sanitised_search) > 0
		OR CONTAINS (cid_user_parent.citation, v_sanitised_search) > 0
		OR CONTAINS (cid_base.title, v_sanitised_search) > 0
		OR CONTAINS (cid_base.summary, v_sanitised_search) > 0
		OR CONTAINS (cid_base.details, v_sanitised_search) > 0
		OR CONTAINS (cid_base.citation, v_sanitised_search) > 0
		-- Use LIKE on the smaller text fields - will support partial word matches.
		OR UPPER(ci.reference_code) LIKE '%'||UPPER(in_search)||'%'
		OR UPPER(ci.user_comment) LIKE '%'||UPPER(in_search)||'%'
		)
	  AND (cpc.compliance_item_id IS NULL OR in_parent_type = PARENT_LEGAL_REGISTER)
	 GROUP BY ci.compliance_item_id;

	IF NOT v_can_manage_compliances THEN
		-- if they aren't a compliance manager, they can only access items if they have workflow
		-- access to a relevant compliance item
		SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, NULL, NULL)
		  BULK COLLECT INTO v_temp_id_list
		  FROM compliance_item ci
		  JOIN TABLE (v_id_list) search_ids ON ci.compliance_item_id = search_ids.object_id
		  JOIN compliance_item_region cir ON ci.app_sid = cir.app_sid AND ci.compliance_item_id = cir.compliance_item_id
		  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
		 WHERE (EXISTS (
					SELECT 1
					  FROM region_role_member rrm
					  JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
					 WHERE rrm.app_sid = cir.app_sid
					   AND rrm.region_sid = cir.region_sid
					   AND rrm.user_sid = v_user_sid
					   AND fsr.flow_state_id = fi.current_state_id
				)
				OR EXISTS (
					SELECT 1
					  FROM flow_state_role fsr
					  JOIN security.act act ON act.sid_id = fsr.group_sid 
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					   AND fsr.flow_state_id = fi.current_state_id
				))
		 GROUP BY ci.compliance_item_id;
		 
		v_id_list := v_temp_id_list;
	END IF;

	chain.filter_pkg.EndDebugLog(v_log_id);
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.ApplyBreadcrumb');

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

			GetFilterObjectData(v_aggregation_types, out_id_list);

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
	out_compliance_tags				OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_language						security.user_table.language%TYPE := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT ci.compliance_item_id,
			   COALESCE(cid_user.title, cid_user_parent.title, cid_base.title) title,
			   COALESCE(cid_user.summary, cid_user_parent.summary, cid_base.summary) summary,
			   COALESCE(cid_user.details, cid_user_parent.details, cid_base.details) details,
			   COALESCE(cid_user.citation, cid_user_parent.citation, cid_base.citation) citation,
			   NVL(cirl.countries, cirl.country_group_names) country,
			   NVL(cirl.regions, cirl.region_group_names) region,
			   reference_code, user_comment, external_link, created_dtm, updated_dtm, creg.adoption_dtm, cisrc.description source, cis.description status, crrs.rollout_regions,
			   NVL(cirfi.count_of_legal_register_items, 0) count_of_legal_register_items,
			   CASE
				WHEN creg.compliance_item_id IS NOT NULL AND creg.is_policy = 0 THEN 'Regulation'
				WHEN creg.compliance_item_id IS NOT NULL AND creg.is_policy = 1 THEN 'Policy'
				WHEN creq.compliance_item_id IS NOT NULL THEN 'Requirement'
			   END type
		  FROM compliance_item ci
		  -- Base lang
		  JOIN aspen2.lang l_base ON l_base.lang = 'en'
		  LEFT JOIN compliance_language cl_base ON cl_base.app_sid = ci.app_sid AND cl_base.lang_id = l_base.lang_id
		  LEFT JOIN compliance_item_description cid_base ON ci.compliance_item_id = cid_base.compliance_item_id AND ci.app_sid = cid_base.app_sid AND cl_base.lang_id = cid_base.lang_id
		  -- User lang
		  JOIN aspen2.lang l_user ON l_user.lang = v_language
		  LEFT JOIN compliance_language cl_user ON cl_user.app_sid = ci.app_sid AND cl_user.lang_id = l_user.lang_id
		  LEFT JOIN compliance_item_description cid_user ON ci.compliance_item_id = cid_user.compliance_item_id AND ci.app_sid = cid_user.app_sid AND cl_user.lang_id = cid_user.lang_id
		  -- User parent lang
		  LEFT JOIN aspen2.lang l_user_parent ON l_user_parent.lang_id = l_user.parent_lang_id
		  LEFT JOIN compliance_language cl_user_parent ON cl_user_parent.app_sid = ci.app_sid AND cl_user_parent.lang_id = l_user_parent.lang_id
		  LEFT JOIN compliance_item_description cid_user_parent ON ci.compliance_item_id = cid_user_parent.compliance_item_id AND ci.app_sid = cid_user_parent.app_sid
			AND cl_user_parent.lang_id = cid_user_parent.lang_id
		  JOIN compliance_item_status cis ON ci.compliance_item_status_id = cis.compliance_item_status_id
		  JOIN compliance_item_source cisrc ON ci.source = cisrc.compliance_item_source_id
		  LEFT JOIN compliance_regulation creg ON ci.compliance_item_id = creg.compliance_item_id
		  LEFT JOIN compliance_requirement creq ON ci.compliance_item_id = creq.compliance_item_id
		  JOIN v$comp_item_rollout_location cirl ON ci.compliance_item_id = cirl.compliance_item_id
		  LEFT JOIN (
			SELECT crs.compliance_item_id, listagg(r.description,', ') within group(order by crs.compliance_item_id)  as rollout_regions
			  FROM compliance_rollout_regions crs
			  JOIN v$region r ON r.region_sid = crs.REGION_SID
			 GROUP BY crs.compliance_item_id
				) crrs ON crrs.compliance_item_id = ci.compliance_item_id
		  LEFT JOIN (
			SELECT cir.compliance_item_id, COUNT(cir.flow_item_id) count_of_legal_register_items
			  FROM compliance_item_region cir
			 GROUP BY cir.compliance_item_id
			    ) cirfi ON cirfi.compliance_item_id = ci.compliance_item_id
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = ci.compliance_item_id
		 ORDER BY fil_list.pos;

	OPEN out_compliance_tags FOR
		SELECT cit.compliance_item_id, t.tag_id, t.tag, tgm.tag_group_id
		  FROM compliance_item_tag cit
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cit.compliance_item_id
		  JOIN tag_group_member tgm ON cit.tag_id = tgm.tag_id AND cit.app_sid = tgm.app_sid
		  JOIN v$tag t ON cit.tag_id = t.tag_id AND cit.app_sid = t.app_sid
		 ORDER BY tgm.tag_group_id, tgm.pos;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredComplianceItemIds (
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
	v_language						security.user_table.language%TYPE := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.PageFilteredComplianceItemIds');
	
	IF in_order_by = 'updatedDtm' AND in_order_dir = 'DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.object_id, ROWNUM rn
			  FROM (
				SELECT fil_list.object_id
				  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list
				  JOIN compliance_item ci ON fil_list.object_id = ci.compliance_item_id
				 ORDER BY ci.updated_dtm DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(compliance_item_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.compliance_item_id, ROWNUM rn
				  FROM (
					SELECT ci.compliance_item_id
					  FROM compliance_item ci
					  -- Base lang
					  JOIN aspen2.lang l_base ON l_base.lang = 'en'
					  LEFT JOIN compliance_language cl_base ON cl_base.app_sid = ci.app_sid AND cl_base.lang_id = l_base.lang_id
					  LEFT JOIN compliance_item_description cid_base ON ci.compliance_item_id = cid_base.compliance_item_id AND ci.app_sid = cid_base.app_sid AND cl_base.lang_id = cid_base.lang_id
					  -- User lang
					  JOIN aspen2.lang l_user ON l_user.lang = v_language
					  LEFT JOIN compliance_language cl_user ON cl_user.app_sid = ci.app_sid AND cl_user.lang_id = l_user.lang_id
					  LEFT JOIN compliance_item_description cid_user ON ci.compliance_item_id = cid_user.compliance_item_id AND ci.app_sid = cid_user.app_sid AND cl_user.lang_id = cid_user.lang_id
					  -- User parent lang
					  LEFT JOIN aspen2.lang l_user_parent ON l_user_parent.lang_id = l_user.parent_lang_id
					  LEFT JOIN compliance_language cl_user_parent ON cl_user_parent.app_sid = ci.app_sid AND cl_user_parent.lang_id = l_user_parent.lang_id
					  LEFT JOIN compliance_item_description cid_user_parent ON ci.compliance_item_id = cid_user_parent.compliance_item_id AND ci.app_sid = cid_user_parent.app_sid
						AND cl_user_parent.lang_id = cid_user_parent.lang_id
					  LEFT JOIN compliance_item_rollout cir ON ci.compliance_item_id = cir.compliance_item_id
					  LEFT JOIN compliance_regulation cr ON ci.compliance_item_id = cr.compliance_item_id
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = ci.compliance_item_id
					  LEFT JOIN (
						SELECT oit.compliance_item_id, oit.tag_group_id, stragg(oit.tag) tags
						  FROM (
							SELECT cit.compliance_item_id, tgm.tag_group_id, t.tag
							  FROM compliance_item_tag cit
							  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) frl ON frl.object_id = cit.compliance_item_id
							  JOIN tag_group_member tgm ON cit.tag_id = tgm.tag_id AND cit.app_sid = tgm.app_sid
							  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) oit
						 GROUP BY oit.compliance_item_id, oit.tag_group_id
						) cits ON ci.compliance_item_id = cits.compliance_item_id
					  LEFT JOIN (
						SELECT cir.compliance_item_id, TO_CHAR(COUNT(cir.flow_item_id)) count_of_legal_register_items
						  FROM compliance_item_region cir
						 GROUP BY cir.compliance_item_id
						) cirfi ON cirfi.compliance_item_id = ci.compliance_item_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'complianceItemId' THEN TO_CHAR(ci.compliance_item_id, '0000000000')
									WHEN 'title' THEN LOWER(NVL2(cid_user.title, cid_user.title, cid_base.title))
									WHEN 'status' THEN TO_CHAR(ci.compliance_item_status_id, '0000000000')
									WHEN 'source' THEN LOWER(ci.source)
									WHEN 'country' THEN LOWER(cir.country)
									WHEN 'region' THEN LOWER(NVL(cir.region, cir.region_group))
									WHEN 'referenceCode' THEN LOWER(ci.reference_code)
									WHEN 'userComment' THEN LOWER(ci.user_comment)
									WHEN 'citation' THEN LOWER(NVL2(cid_user.citation, cid_user.citation, cid_base.citation))
									WHEN 'externalLink' THEN LOWER(ci.external_link)
									WHEN 'createdDtm' THEN TO_CHAR(ci.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'updatedDtm' THEN TO_CHAR(ci.updated_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'adoptionDtm' THEN TO_CHAR(cr.adoption_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tags' THEN LOWER(cits.tags)
									WHEN 'countOfLegalRegisterItems' THEN TO_CHAR(NVL(cirfi.count_of_legal_register_items, 0), '0000000000')
									WHEN 'type' THEN 
										CASE
											WHEN cr.compliance_item_id IS NOT NULL AND cr.is_policy = 0 THEN 'Regulation'
											WHEN cr.compliance_item_id IS NOT NULL AND cr.is_policy = 1 THEN 'Policy'
											ELSE 'Requirement'
										END
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'complianceItemId' THEN TO_CHAR(ci.compliance_item_id, '0000000000')
									WHEN 'title' THEN LOWER(NVL2(cid_user.title, cid_user.title, cid_base.title))
									WHEN 'status' THEN TO_CHAR(ci.compliance_item_status_id, '0000000000')
									WHEN 'source' THEN LOWER(ci.source)
									WHEN 'country' THEN LOWER(cir.country)
									WHEN 'region' THEN LOWER(NVL(cir.region, cir.region_group))
									WHEN 'referenceCode' THEN LOWER(ci.reference_code)
									WHEN 'userComment' THEN LOWER(ci.user_comment)
									WHEN 'citation' THEN LOWER(NVL2(cid_user.citation, cid_user.citation, cid_base.citation))
									WHEN 'externalLink' THEN LOWER(ci.external_link)
									WHEN 'createdDtm' THEN TO_CHAR(ci.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'updatedDtm' THEN TO_CHAR(ci.updated_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'adoptionDtm' THEN TO_CHAR(cr.adoption_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tags' THEN LOWER(cits.tags)
									WHEN 'countOfLegalRegisterItems' THEN TO_CHAR(NVL(cirfi.count_of_legal_register_items, 0), '0000000000')
									WHEN 'type' THEN 
										CASE
											WHEN cr.compliance_item_id IS NOT NULL AND cr.is_policy = 0 THEN 'Regulation'
											WHEN cr.compliance_item_id IS NOT NULL AND cr.is_policy = 1 THEN 'Policy'
											ELSE 'Requirement'
										END
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN ci.compliance_item_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN ci.compliance_item_id END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Compliance Library -> '||v_name);

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
	out_cur 						OUT SYS_REFCURSOR,
	out_compliance_tags				OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.GetComplianceList', in_compound_filter_id);

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

	PageFilteredComplianceItemIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);

	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_compliance_tags);

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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB
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
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_top_n_values					security.T_ORDERED_SID_TABLE;
	v_aggregation_type				NUMBER := AGG_TYPE_COUNT;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.GetReportData', in_compound_filter_id);

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

	v_top_n_values := chain.filter_pkg.FindTopN(in_grp_by_compound_filter_id, v_aggregation_type, v_id_list, in_breadcrumb, in_max_group_by);

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
	out_compliance_tags				OUT SYS_REFCURSOR
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

	CollectSearchResults(v_id_page, out_cur, out_compliance_tags);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_compliance_tags				OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_library_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB
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
		out_compliance_tags			=> out_compliance_tags
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

PROCEDURE FilterCreatedDtm (
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
		SELECT MIN(ci.created_dtm), MAX(ci.created_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_item ci
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON ci.created_dtm >= NVL(dr.start_dtm, ci.created_dtm)
	   AND (dr.end_dtm IS NULL OR ci.created_dtm < dr.end_dtm)
	 WHERE ci.created_dtm IS NOT NULL;

END;

PROCEDURE FilterUpdatedDtm (
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
		SELECT MIN(ci.updated_dtm), MAX(ci.updated_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_item ci
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON ci.updated_dtm >= NVL(dr.start_dtm, ci.created_dtm)
	   AND (dr.end_dtm IS NULL OR ci.updated_dtm < dr.end_dtm)
	 WHERE ci.updated_dtm IS NOT NULL;

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
	v_is_hierarchical				NUMBER;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_require_null_filter_value_id	NUMBER;
	v_exclude_null_filter_value_id	NUMBER;
BEGIN
	v_tag_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);
	
	SELECT is_hierarchical
	  INTO v_is_hierarchical
	  FROM tag_group
	 WHERE tag_group_id = v_tag_group_id;

	IF v_is_hierarchical = 0 THEN
		IF in_show_all = 1 THEN
			chain.filter_pkg.ShowAllTags(in_filter_field_id, v_tag_group_id);
		END IF;

		SELECT chain.T_FILTERED_OBJECT_ROW(cit.compliance_item_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM compliance_item_tag cit	  
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cit.compliance_item_id = t.object_id
		  JOIN tag_group_member tgm ON tgm.app_sid = cit.app_sid AND tgm.tag_id = cit.tag_id
		  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id AND cit.tag_id = fv.num_value
		 WHERE tgm.tag_group_id = v_tag_group_id
		   AND fv.null_filter = chain.filter_pkg.NULL_FILTER_ALL;
	ELSE
		IF in_show_all = 1 THEN
			-- Ensure the filter_value rows include all options
			INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.tag_id, n.tag
			  FROM (
				SELECT cit.tag_id, t.tag
				  FROM compliance_item_tag cit
				  JOIN v$tag t on cit.tag_id = t.tag_id
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) i ON cit.compliance_item_id = i.object_id
				 GROUP BY cit.tag_id, t.tag
				 ) n
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = n.tag_id
			 );

			-- If show_all is on, we don't want to aggregate (otherwise the data is a mess)
			SELECT chain.T_FILTERED_OBJECT_ROW(cit.compliance_item_id, in_group_by_index, cit.filter_value_id)
			  BULK COLLECT INTO out_ids
			  FROM (
				SELECT DISTINCT cit.compliance_item_id, fv.filter_value_id
				  FROM compliance_item_tag cit
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cit.compliance_item_id = t.object_id
				  JOIN chain.filter_value fv ON cit.tag_id = fv.num_value
				 WHERE fv.filter_field_id = in_filter_field_id
			) cit;
		ELSE
			SELECT chain.T_FILTERED_OBJECT_ROW(cit.compliance_item_id, in_group_by_index, t.filter_value_id)
			  BULK COLLECT INTO out_ids
			  FROM compliance_item_tag cit
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) ft ON cit.compliance_item_id = ft.object_id
			  JOIN (
					SELECT t.tag_id, connect_by_root fv.filter_value_id filter_value_id
					  FROM tag t
					  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id
					 START WITH t.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND t.tag_id = fv.num_value
				   CONNECT BY PRIOR t.app_sid = t.app_sid
					   AND PRIOR t.tag_id = t.parent_id
					   AND PRIOR fv.filter_value_id = fv.filter_value_id
				 ) t ON cit.tag_id = t.tag_id;
		END IF;
	END IF;

	SELECT MAX(filter_value_id)
	  INTO v_require_null_filter_value_id
	  FROM chain.filter_value 
	 WHERE filter_field_id = in_filter_field_id
	   AND null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL;

	SELECT MAX(filter_value_id)
	  INTO v_exclude_null_filter_value_id
	  FROM chain.filter_value 
	 WHERE filter_field_id = in_filter_field_id
	   AND null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL;

	IF v_require_null_filter_value_id IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, v_require_null_filter_value_id)
		  BULK COLLECT INTO v_ids
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
		 WHERE NOT EXISTS (
			SELECT 1
			  FROM compliance_item_tag cit
			  JOIN tag_group_member tgm ON tgm.app_sid = cit.app_sid AND tgm.tag_id = cit.tag_id
			 WHERE tgm.tag_group_id = v_tag_group_id
			   AND cit.compliance_item_id = t.object_id
		 );
		
		out_ids := out_ids MULTISET UNION v_ids;
	END IF;
	
	IF v_exclude_null_filter_value_id IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, v_exclude_null_filter_value_id)
		  BULK COLLECT INTO v_ids
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
		 WHERE EXISTS (
			SELECT 1
			  FROM compliance_item_tag cit
			  JOIN tag_group_member tgm ON tgm.app_sid = cit.app_sid AND tgm.tag_id = cit.tag_id
			 WHERE tgm.tag_group_id = v_tag_group_id
			   AND cit.compliance_item_id = t.object_id
		 );

		out_ids := out_ids MULTISET UNION v_ids;
	END IF;

END;

PROCEDURE FilterSource (
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, s.compliance_item_source_id, s.description
			  FROM compliance_item_source s
			 WHERE EXISTS (
				SELECT *
				  FROM compliance_item ci
				 WHERE ci.source = s.compliance_item_source_id
			)
			  AND NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = s.compliance_item_source_id
			);
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  JOIN chain.filter_value fv ON fv.num_value = ci.source
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterType (
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, s.id, s.description
			  FROM (
				SELECT compliance_pkg.COMPLIANCE_REQUIREMENT id, 'Requirement' description FROM dual
				UNION ALL SELECT compliance_pkg.COMPLIANCE_REGULATION, 'Regulation' FROM dual
				UNION ALL SELECT compliance_pkg.COMPLIANCE_CONDITION, 'Permit condition' FROM dual
				UNION ALL SELECT COMPLIANCE_POLICY_FILTER_VALUE, 'Policy' FROM dual				

			) s
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = s.id
			);
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  LEFT JOIN compliance_regulation creg ON ci.compliance_item_id = creg.compliance_item_id
	  LEFT JOIN compliance_requirement creq ON ci.compliance_item_id = creq.compliance_item_id
	  LEFT JOIN compliance_permit_condition ccon ON ci.compliance_item_id = ccon.compliance_item_id
	  JOIN chain.filter_value fv
	    ON (fv.num_value = compliance_pkg.COMPLIANCE_REQUIREMENT AND creq.compliance_item_id IS NOT NULL)
		OR (fv.num_value = compliance_pkg.COMPLIANCE_REGULATION 
			AND creg.compliance_item_id IS NOT NULL 
			AND creg.is_policy = 0
		   )
		OR (fv.num_value = compliance_pkg.COMPLIANCE_CONDITION
			AND ccon.compliance_item_id IS NOT NULL 
		   )
		OR (fv.num_value = COMPLIANCE_POLICY_FILTER_VALUE
			AND creg.compliance_item_id IS NOT NULL 
			AND creg.is_policy = 1
		   )
	 WHERE fv.filter_field_id = in_filter_field_id;



END;

PROCEDURE FilterStatus (
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cis.compliance_item_status_id, cis.description
		  FROM compliance_item_status cis
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = cis.compliance_item_status_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = ci.compliance_item_status_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCountry (
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
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, c.country, co.name
		  FROM (SELECT DISTINCT country FROM compliance_item_rollout) c
		  JOIN postcode.country co ON c.country = co.country
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = c.country
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  LEFT JOIN compliance_item_rollout cir ON ci.app_sid = cir.app_sid AND ci.compliance_item_id = cir.compliance_item_id
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  JOIN chain.filter_value fv ON fv.str_value = cir.country
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCountryGroup (
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
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, c.country_group, cg.group_name
		  FROM (SELECT DISTINCT country_group FROM compliance_item_rollout) c
		  JOIN csr.country_group cg ON c.country_group = cg.country_group_id
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = c.country_group
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  LEFT JOIN compliance_item_rollout cir ON ci.app_sid = cir.app_sid AND ci.compliance_item_id = cir.compliance_item_id
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  JOIN chain.filter_value fv ON fv.str_value = cir.country_group
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAdoptedDtm (
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
		SELECT MIN(cr.adoption_dtm), MAX(cr.adoption_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_item ci
		  JOIN compliance_regulation cr ON ci.compliance_item_id = cr.compliance_item_id
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(ci.compliance_item_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item ci
	  JOIN compliance_regulation cr ON ci.compliance_item_id = cr.compliance_item_id
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ci.compliance_item_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cr.adoption_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cr.adoption_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			cr.adoption_dtm IS NOT NULL AND
			cr.adoption_dtm >= NVL(dr.start_dtm, cr.adoption_dtm) AND 
			(dr.end_dtm IS NULL OR cr.adoption_dtm < dr.end_dtm));
END;

PROCEDURE FilterCountOfLegRegItems (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	WITH flow_counts AS (
		SELECT compliance_item_id, COUNT(flow_item_id) count_of_legal_register_items
		  FROM compliance_item_region
		 GROUP BY compliance_item_id
	)
	SELECT chain.T_FILTERED_OBJECT_ROW(t.object_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (SELECT DISTINCT object_id FROM TABLE(in_ids)) t
	  LEFT JOIN flow_counts fc ON t.object_id = fc.compliance_item_id
	  JOIN chain.filter_value fv
	    ON chain.filter_pkg.CheckNumberRange(NVL(fc.count_of_legal_register_items, 0), fv.num_value, fv.min_num_val, fv.max_num_val) = 1
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

END compliance_library_report_pkg;
/