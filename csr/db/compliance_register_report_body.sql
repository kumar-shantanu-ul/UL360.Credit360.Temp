CREATE OR REPLACE PACKAGE BODY CSR.compliance_register_report_pkg
IS

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFlowStateLabel		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOutOfScope			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOpenActions			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOpenRequirements	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterComplianceItem		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegion				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIssues				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterEmbeddedComplianceItem (in_name IN chain.filter_field.name%TYPE, in_column_sid IN security_pkg.T_SID_ID, in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN chain.filter_field.filter_field_id%TYPE, in_group_by_index IN chain.filter_field.group_by_index%TYPE, in_show_all IN chain.filter_field.show_all%TYPE, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterComplianceItemId	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterComplianceFlowItemIds (
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
	v_name							chain.filter_field.name%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.FilterComplianceFlowItemIds', in_filter_id);

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.FilterComplianceFlowItemIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		IF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'FlowStateLabel' THEN
			FilterFlowStateLabel(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OutOfScope' THEN
			FilterOutOfScope(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OpenActions' THEN
			FilterOpenActions(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OpenRequirements' THEN
			FilterOpenRequirements(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ComplianceLibraryFilter' THEN
			FilterComplianceItem(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'ComplianceLibrary%' OR r.name LIKE 'complianceLibrary%' THEN
			v_name := SUBSTR(r.name, 18);
			FilterEmbeddedComplianceItem(v_name, r.column_sid, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IssueFilter' THEN
			FilterIssues(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
			NULL;
		ELSIF r.name = 'RegionFilter' THEN
			FilterRegion(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ComplianceItemId' THEN
			FilterComplianceItemId(in_filter_id, r.filter_field_id, r.group_by_index, v_starting_ids, v_result_ids);
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
	chain.filter_pkg.RunCompoundFilter('FilterComplianceFlowItemIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	IF AGG_TYPE_COUNT MEMBER OF in_aggregation_types THEN
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT AGG_TYPE_COUNT, l.object_id, chain.filter_pkg.AFUNC_COUNT, l.object_id
		  FROM TABLE(in_id_list) l;
	END IF;
	
	-- Run core aggregate types but only if requested
	FOR chk IN (
		SELECT *
		  FROM dual
		 WHERE EXISTS(SELECT * FROM TABLE(in_aggregation_types) WHERE column_value BETWEEN 2 AND 9999)
	) LOOP
		INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
		SELECT DISTINCT a.column_value, l.object_id,
				CASE a.column_value
					WHEN AGG_TYPE_COUNT_REG THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OPEN_REG THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_REQ THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OPEN_REQ THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OPEN_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_OVRD_ISSUES THEN chain.filter_pkg.AFUNC_SUM
					WHEN AGG_TYPE_COUNT_CLOSED_ISSUES THEN chain.filter_pkg.AFUNC_SUM
				END,
				CASE a.column_value
					WHEN AGG_TYPE_COUNT_REG THEN COUNT(DISTINCT creg.compliance_item_id)
					WHEN AGG_TYPE_COUNT_OPEN_REG THEN 
						COUNT(DISTINCT CASE WHEN NOT (
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REGULATION_NA OR 
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REGULATION_COMPLIANT OR 
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REGULATION_RETIRED
						) THEN creg.compliance_item_id END)
					WHEN AGG_TYPE_COUNT_REQ THEN COUNT(DISTINCT creq.compliance_item_id)
					WHEN AGG_TYPE_COUNT_OPEN_REQ THEN 
						COUNT(DISTINCT CASE WHEN NOT (
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_NA OR 
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT OR 
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_RETIRED
						) THEN creq.compliance_item_id END)
					WHEN AGG_TYPE_COUNT_ISSUES THEN COUNT(DISTINCT i.issue_id)
					WHEN AGG_TYPE_COUNT_OPEN_ISSUES THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_OVRD_ISSUES THEN COUNT(DISTINCT CASE WHEN i.due_dtm<TRUNC(SYSDATE) AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id END)
					WHEN AGG_TYPE_COUNT_CLOSED_ISSUES THEN COUNT(DISTINCT CASE WHEN i.resolved_dtm IS NOT NULL THEN i.issue_id END)
				END
		  FROM compliance_item_region cir
		  JOIN TABLE(in_id_list) l ON cir.flow_item_id = l.object_id
		 CROSS JOIN TABLE(in_aggregation_types) a
		  LEFT JOIN compliance_regulation creg ON cir.compliance_item_id = creg.compliance_item_id
		  LEFT JOIN compliance_requirement creq ON cir.compliance_item_id = creq.compliance_item_id
		  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
		  LEFT JOIN issue_compliance_region icr ON cir.app_sid = icr.app_sid AND cir.flow_item_id = icr.flow_item_id
		  LEFT JOIN issue i ON icr.app_sid = i.app_sid AND icr.issue_compliance_region_id = i.issue_compliance_region_id AND i.deleted = 0
		 WHERE a.column_value > 1
		 GROUP BY a.column_value, l.object_id;
	END LOOP;

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
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseTextSearchForContains(in_search);
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
	v_language						security.user_table.language%TYPE := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.GetFilteredIds', in_compound_filter_id);

	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	-- start with the list they have access to
	SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM compliance_item_region cir
	  JOIN compliance_item ci ON ci.app_sid = cir.app_sid AND ci.compliance_item_id = cir.compliance_item_id
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
	  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
	  JOIN region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid AND r.active = 1
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN cir.region_sid END = tr.region_sid
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
	   AND (in_parent_type IS NULL OR
		(in_parent_type = PARENT_TYPE_PROPERTY AND cir.region_sid = in_parent_id))
	  AND (EXISTS (
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
	 GROUP BY cir.flow_item_id;

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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.ApplyBreadcrumb');

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
	v_compliance_ids				security.T_SID_TABLE;
	v_language						security.user_table.language%TYPE := NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.CollectSearchResults');
	
	OPEN out_cur FOR
		SELECT cir.flow_item_id, cir.region_sid, r.description region_description,
			   fs.flow_sid, fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key,
			   fs.state_colour flow_state_colour, fs.pos flow_state_pos,
			   ci.compliance_item_id, 
			   COALESCE(cid_user.title, cid_user_parent.title, cid_base.title) title,
			   COALESCE(cid_user.summary, cid_user_parent.summary, cid_base.summary) summary,
			   COALESCE(cid_user.details, cid_user_parent.details, cid_base.details) details,
			   COALESCE(cid_user.citation, cid_user_parent.citation, cid_base.citation) citation,
			   ciroc.country, ciror.region, ci.reference_code,
			   ci.user_comment, ci.external_link, ci.created_dtm, ci.updated_dtm, creg.adoption_dtm,
			   cisrc.description source, cis.description status,
			   i.closed_issues, i.total_issues, i.open_issues,
			   req.total_requirements, req.open_requirements, crrs.rollout_regions, cir.out_of_scope,
				CASE
					WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REGULATION AND creg.is_policy = 0 THEN 'Regulation'
					WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REGULATION AND creg.is_policy = 1 THEN 'Policy'
					WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REQUIREMENT THEN 'Requirement'
					WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_CONDITION THEN 'Condition'
				END type
		  FROM compliance_item_region cir 
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cir.flow_item_id
		  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid
		  JOIN compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
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
		  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id 
		  LEFT JOIN compliance_regulation creg ON ci.compliance_item_id = creg.compliance_item_id
		  LEFT JOIN (
					SELECT compliance_item_id,
						   listagg(country, ', ') WITHIN GROUP(ORDER BY compliance_item_id) country
					  FROM (
						SELECT DISTINCT cr.compliance_item_id,
							   NVL(pc.name, cg.group_name) country
						  FROM compliance_item_rollout cr
						  LEFT JOIN country_group cg ON cr.country_group = cg.country_group_id
						  LEFT JOIN postcode.country pc ON cr.country = pc.country
					)
					 GROUP BY compliance_item_id
			) ciroc ON ciroc.compliance_item_id = ci.compliance_item_id			
		  LEFT JOIN (
					SELECT compliance_item_id,
						   listagg(region, ', ') WITHIN GROUP(ORDER BY compliance_item_id) region
					  FROM (
						SELECT DISTINCT cr.compliance_item_id,
							   NVL(pr.name, rg.group_name) region
						  FROM compliance_item_rollout cr
						  LEFT JOIN region_group rg ON cr.region_group = rg.region_group_id
						  LEFT JOIN postcode.region pr ON cr.country = pr.country AND cr.region = pr.region
					)
					 GROUP BY compliance_item_id
			) ciror ON ciror.compliance_item_id = ci.compliance_item_id
		  LEFT JOIN (
					SELECT crs.compliance_item_id, listagg(r.description,', ') WITHIN GROUP(ORDER BY crs.compliance_item_id)  as rollout_regions
					  FROM compliance_rollout_regions crs
					  JOIN v$region r ON r.region_sid = crs.REGION_SID AND crs.app_sid = r.app_sid
					 GROUP BY crs.compliance_item_id 
			) crrs ON crrs.compliance_item_id = ci.compliance_item_id
		  LEFT JOIN (
			SELECT icr.app_sid, icr.flow_item_id,
				   COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
				   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
			  FROM issue_compliance_region icr
			  JOIN issue i ON icr.app_sid = i.app_sid AND icr.issue_compliance_region_id = i.issue_compliance_region_id
			 WHERE i.deleted = 0
			 GROUP BY icr.app_sid, icr.flow_item_id
			) i ON cir.flow_item_id = i.flow_item_id AND cir.app_sid = i.app_sid
		  LEFT JOIN (
			SELECT pcir.app_sid, pcir.flow_item_id,
				   COUNT(*) total_requirements,
				   COUNT(CASE WHEN NOT (
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_NA OR 
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT OR 
							fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_RETIRED
						) THEN ccir.flow_item_id END) open_requirements
			  FROM compliance_item_region pcir
			  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = pcir.flow_item_id
			  JOIN compliance_req_reg crr ON pcir.compliance_item_id = crr.regulation_id
			  JOIN compliance_item_region ccir ON crr.requirement_id = ccir.compliance_item_id AND pcir.region_sid = ccir.region_sid
			  JOIN flow_item fi ON ccir.flow_item_id = fi.flow_item_id
			  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
			 GROUP BY pcir.app_sid, pcir.flow_item_id
			) req ON cir.flow_item_id = req.flow_item_id AND cir.app_sid = req.app_sid
		 ORDER BY fil_list.pos;

	SELECT DISTINCT cir.compliance_item_id
	  BULK COLLECT INTO v_compliance_ids
	  FROM compliance_item_region cir 
	  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cir.flow_item_id;

	OPEN out_compliance_tags FOR
		SELECT cit.compliance_item_id, t.tag_id, t.tag, tgm.tag_group_id
		  FROM compliance_item_tag cit
		  JOIN TABLE (v_compliance_ids) fil_list ON fil_list.column_value = cit.compliance_item_id
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.PageFilteredComplianceItemIds');

	IF in_order_by IN ('openIssues','closedIssues','totalIssues') THEN
		SELECT security.T_ORDERED_SID_ROW(flow_item_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.flow_item_id, ROWNUM rn
				  FROM (
					SELECT cir.flow_item_id
					  FROM compliance_item_region cir
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cir.flow_item_id
					  LEFT JOIN (
						SELECT icr.app_sid, icr.flow_item_id,
							   COUNT(i.resolved_dtm) closed_issues, COUNT(*) total_issues,
							   COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
						  FROM issue_compliance_region icr
						  JOIN issue i ON icr.app_sid = i.app_sid AND icr.issue_compliance_region_id = i.issue_compliance_region_id
						 WHERE i.deleted = 0
						 GROUP BY icr.app_sid, icr.flow_item_id
						) i ON cir.flow_item_id = i.flow_item_id AND cir.app_sid = i.app_sid
					 ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (in_order_by)
									WHEN 'openIssues' THEN TO_CHAR(NVL(i.open_issues, 0), '0000000000')
									WHEN 'closedIssues' THEN TO_CHAR(NVL(i.closed_issues, 0), '0000000000')
									WHEN 'totalIssues' THEN TO_CHAR(NVL(i.total_issues, 0), '0000000000')
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (in_order_by)
									WHEN 'openIssues' THEN TO_CHAR(NVL(i.open_issues, 0), '0000000000')
									WHEN 'closedIssues' THEN TO_CHAR(NVL(i.closed_issues, 0), '0000000000')
									WHEN 'totalIssues' THEN TO_CHAR(NVL(i.total_issues, 0), '0000000000')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cir.flow_item_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN cir.flow_item_id END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSIF in_order_by IN ('totalRequirements', 'openRequirements') THEN
		SELECT security.T_ORDERED_SID_ROW(flow_item_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.flow_item_id, ROWNUM rn
				  FROM (
					SELECT cir.flow_item_id
					  FROM compliance_item_region cir
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cir.flow_item_id
					  LEFT JOIN (
						SELECT pcir.app_sid, pcir.flow_item_id,
							   COUNT(*) total_requirements,
							   COUNT(CASE WHEN NOT (
										fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_NA OR 
										fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT OR 
										fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_RETIRED
									) THEN ccir.flow_item_id END) open_requirements
						  FROM compliance_item_region pcir
						  JOIN TABLE (in_id_list) fil_list ON fil_list.object_id = pcir.flow_item_id
						  JOIN compliance_req_reg crr ON pcir.compliance_item_id = crr.regulation_id
						  JOIN compliance_item_region ccir ON crr.requirement_id = ccir.compliance_item_id AND pcir.region_sid = ccir.region_sid
						  JOIN flow_item fi ON ccir.flow_item_id = fi.flow_item_id
						  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
						 GROUP BY pcir.app_sid, pcir.flow_item_id
						) req ON cir.flow_item_id = req.flow_item_id AND cir.app_sid = req.app_sid
					 ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (in_order_by)
									WHEN 'openRequirements' THEN TO_CHAR(NVL(req.open_requirements, 0), '0000000000')
									WHEN 'totalRequirements' THEN TO_CHAR(NVL(req.total_requirements, 0), '0000000000')
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (in_order_by)
									WHEN 'openRequirements' THEN TO_CHAR(NVL(req.open_requirements, 0), '0000000000')
									WHEN 'totalRequirements' THEN TO_CHAR(NVL(req.total_requirements, 0), '0000000000')
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cir.flow_item_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN cir.flow_item_id END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(flow_item_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.flow_item_id, ROWNUM rn
				  FROM (
					SELECT fil_list.object_id flow_item_id
					  FROM compliance_item_region cir
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cir.flow_item_id
					  JOIN compliance_item ci ON cir.compliance_item_id = ci.compliance_item_id
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
					  JOIN v$region r ON cir.app_sid = r.app_sid AND cir.region_sid = r.region_sid
					  LEFT JOIN compliance_regulation cr ON ci.compliance_item_id = cr.compliance_item_id
					  JOIN flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
					  JOIN flow_state fs ON fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
					  LEFT JOIN (
						SELECT oit.compliance_item_id, oit.tag_group_id, stragg(oit.tag) tags
						  FROM (
							SELECT cit.compliance_item_id, tgm.tag_group_id, t.tag
							  FROM compliance_item_tag cit
							  JOIN compliance_item_region cir ON cit.compliance_item_id = cir.compliance_item_id
							  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) frl ON frl.object_id = cir.flow_item_id
							  JOIN tag_group_member tgm ON cit.tag_id = tgm.tag_id AND cit.app_sid = tgm.app_sid
							  JOIN v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
							 WHERE tgm.tag_group_id = v_order_by_id
							 ORDER BY tgm.tag_group_id, tgm.pos
						  ) oit
						 GROUP BY oit.compliance_item_id, oit.tag_group_id
						) cits ON ci.compliance_item_id = cits.compliance_item_id
					  LEFT JOIN (
							SELECT compliance_item_id,
								   listagg(country, ', ') WITHIN GROUP(ORDER BY compliance_item_id) country
							  FROM (
								SELECT DISTINCT cr.compliance_item_id,
									   NVL(pc.name, cg.group_name) country
								  FROM compliance_item_rollout cr
								  LEFT JOIN country_group cg ON cr.country_group = cg.country_group_id
								  LEFT JOIN postcode.country pc ON cr.country = pc.country
							)
							 GROUP BY compliance_item_id
					) ciroc ON ciroc.compliance_item_id = ci.compliance_item_id			
					  LEFT JOIN (
							SELECT compliance_item_id,
								   listagg(region, ', ') WITHIN GROUP(ORDER BY compliance_item_id) region
							  FROM (
								SELECT DISTINCT cr.compliance_item_id,
									   NVL(pr.name, rg.group_name) region
								  FROM compliance_item_rollout cr
								  LEFT JOIN region_group rg ON cr.region_group = rg.region_group_id
								  LEFT JOIN postcode.region pr ON cr.country = pr.country AND cr.region = pr.region
							)
							 GROUP BY compliance_item_id
					) ciror ON ciror.compliance_item_id = ci.compliance_item_id
					LEFT JOIN (
							SELECT crs.compliance_item_id, listagg(r.description,', ') WITHIN GROUP(ORDER BY crs.compliance_item_id)  as rollout_regions
							  FROM compliance_rollout_regions crs
							  JOIN v$region r ON r.region_sid = crs.REGION_SID AND crs.app_sid = r.app_sid
							 GROUP BY crs.compliance_item_id 
					) crrs ON crrs.compliance_item_id = ci.compliance_item_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'flowItemId' THEN TO_CHAR(cir.flow_item_id, '0000000000')
									WHEN 'flowStateLabel' THEN LOWER(fs.label)
									WHEN 'outOfScope' THEN LOWER(cir.out_of_scope)
									WHEN 'regionDescription' THEN LOWER(r.description)
									WHEN 'status' THEN TO_CHAR(ci.compliance_item_status_id, '0000000000')
									WHEN 'flowStateLabel' THEN TO_CHAR(fs.pos, '0000000000')
									WHEN 'complianceItemId' THEN TO_CHAR(ci.compliance_item_id, '0000000000')
									WHEN 'title' THEN LOWER(NVL2(cid_user.title, cid_user.title, cid_base.title))
									WHEN 'citation' THEN LOWER(NVL2(cid_user.citation, cid_user.citation, cid_base.citation))
									WHEN 'source' THEN LOWER(ci.source)
									WHEN 'country' THEN LOWER(ciroc.country)
									WHEN 'region' THEN LOWER(ciror.region)
									WHEN 'referenceCode' THEN LOWER(ci.reference_code)
									WHEN 'userComment' THEN LOWER(ci.user_comment)
									WHEN 'externalLink' THEN LOWER(ci.external_link)
									WHEN 'createdDtm' THEN TO_CHAR(ci.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'updatedDtm' THEN TO_CHAR(ci.updated_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'adoptionDtm' THEN TO_CHAR(cr.adoption_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tags' THEN LOWER(cits.tags)
									WHEN 'type' THEN 
										CASE
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REGULATION AND cr.is_policy = 0 THEN 'Regulation'
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REGULATION AND cr.is_policy = 1 THEN 'Policy'
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REQUIREMENT THEN 'Requirement'
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_CONDITION THEN 'Condition'
										END
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'flowItemId' THEN TO_CHAR(cir.flow_item_id, '0000000000')
									WHEN 'flowStateLabel' THEN LOWER(fs.label)
									WHEN 'outOfScope' THEN LOWER(cir.out_of_scope)
									WHEN 'regionDescription' THEN LOWER(r.description)
									WHEN 'status' THEN TO_CHAR(ci.compliance_item_status_id, '0000000000')
									WHEN 'flowStateLabel' THEN TO_CHAR(fs.pos, '0000000000')
									WHEN 'complianceItemId' THEN TO_CHAR(ci.compliance_item_id, '0000000000')
									WHEN 'title' THEN LOWER(NVL2(cid_user.title, cid_user.title, cid_base.title))
									WHEN 'citation' THEN LOWER(NVL2(cid_user.citation, cid_user.citation, cid_base.citation))
									WHEN 'source' THEN LOWER(ci.source)
									WHEN 'country' THEN LOWER(ciroc.country)
									WHEN 'region' THEN LOWER(ciror.region)
									WHEN 'referenceCode' THEN LOWER(ci.reference_code)
									WHEN 'userComment' THEN LOWER(ci.user_comment)
									WHEN 'externalLink' THEN LOWER(ci.external_link)
									WHEN 'createdDtm' THEN TO_CHAR(ci.created_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'updatedDtm' THEN TO_CHAR(ci.updated_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'adoptionDtm' THEN TO_CHAR(cr.adoption_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'tags' THEN LOWER(cits.tags)
									WHEN 'type' THEN
										CASE
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REGULATION AND cr.is_policy = 0 THEN 'Regulation'
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REGULATION AND cr.is_policy = 1 THEN 'Policy'
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_REQUIREMENT THEN 'Requirement'
											WHEN ci.compliance_item_type = compliance_pkg.COMPLIANCE_CONDITION THEN 'Condition'
										END
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cir.flow_item_id END ASC,
							CASE WHEN in_order_dir='DESC' THEN cir.flow_item_id END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Compliance Register -> '||v_name);

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
	v_user_sid						security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.GetList', in_compound_filter_id);

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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.GetReportData', in_compound_filter_id);

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

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.compliance_register_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG
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
			SELECT cir.region_sid
			  FROM compliance_item_region cir
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
			 GROUP BY cir.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, cir.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT cir.flow_item_id, fv.filter_value_id
			  FROM compliance_item_region cir
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
			  JOIN chain.filter_value fv ON cir.region_sid = fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) cir;
	ELSE
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM compliance_item_region cir
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON cir.region_sid = r.region_sid;				 
	END IF;	
END;

PROCEDURE FilterFlowStateLabel (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_regulation_flow_sid			security_pkg.T_SID_ID;
	v_requirement_flow_sid			security_pkg.T_SID_ID;
	v_condition_flow_sid			security_pkg.T_SID_ID;
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		SELECT MIN(regulation_flow_sid), MIN(requirement_flow_sid), MIN(condition_flow_sid)
		  INTO v_regulation_flow_sid, v_requirement_flow_sid, v_condition_flow_sid
		  FROM compliance_options;

		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description, num_value)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, fs.label, fs.label, fs.flow_state_id
		  FROM (
			SELECT fs.label, MIN(fs.flow_state_id) flow_state_id
			  FROM flow_state fs
			 WHERE fs.flow_sid IN (v_regulation_flow_sid, v_requirement_flow_sid, v_condition_flow_sid)
			   AND fs.is_deleted = 0
			   AND fs.lookup_key != 'NOT_CREATED'
			 GROUP BY fs.label
		  ) fs
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = fs.label
		 );
	END IF;
	
	chain.filter_pkg.SortFlowStateValues(in_filter_field_id);
	chain.filter_pkg.SetFlowStateColours(in_filter_field_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item_region cir
	  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id AND cir.app_sid = fi.app_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	  JOIN chain.filter_value fv ON fs.label = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterOutOfScope (
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
			SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, tmp.num_value, tmp.description
			  FROM (
				SELECT 1 num_value, 'Out of scope' description FROM DUAL
				 UNION
				SELECT 0 num_value, 'In scope' description FROM DUAL
				) tmp
			 WHERE NOT EXISTS (
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = tmp.num_value
			);
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item_region cir
	  JOIN chain.filter_value fv ON fv.num_value = cir.out_of_scope
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterOpenActions (
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.open_ncs, o.description
		  FROM (
			SELECT 1 open_ncs, 'Items with open actions' description FROM dual
			UNION ALL SELECT 0, 'Items with no open actions' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.open_ncs
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item_region cir
	  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id AND cir.app_sid = fi.app_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
	  LEFT JOIN (
		SELECT icr.flow_item_id, COUNT(CASE WHEN i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL THEN i.issue_id ELSE NULL END) open_issues
		  FROM issue_compliance_region icr
		  JOIN issue i ON icr.app_sid = i.app_sid AND icr.issue_compliance_region_id = i.issue_compliance_region_id
		 WHERE i.deleted = 0
		 GROUP BY icr.app_sid, icr.flow_item_id
		) i ON cir.flow_item_id = i.flow_item_id
	   JOIN chain.filter_value fv ON ((fv.num_value = 1 AND NVL(i.open_issues, 0) > 0) OR (fv.num_value = NVL(i.open_issues, 0)))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterOpenRequirements (
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
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.open_ncs, o.description
		  FROM (
			SELECT 1 open_ncs, 'Regulations with open requirements' description FROM dual
			UNION ALL SELECT 0, 'Regulations with no open requirements' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.open_ncs
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item_region cir
	  JOIN flow_item fi ON cir.flow_item_id = fi.flow_item_id AND cir.app_sid = fi.app_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
	  LEFT JOIN (
		SELECT pcir.app_sid, pcir.flow_item_id,
			   COUNT(CASE WHEN NOT (
						fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_NA OR 
						fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_COMPLIANT OR 
						fs.flow_state_nature_id = csr_data_pkg.NATURE_REQUIREMENT_RETIRED
					) THEN ccir.flow_item_id END) open_requirements
		  FROM compliance_item_region pcir
		  JOIN TABLE (in_ids) fil_list ON fil_list.object_id = pcir.flow_item_id
		  JOIN compliance_req_reg crr ON pcir.compliance_item_id = crr.regulation_id
		  JOIN compliance_item_region ccir ON crr.requirement_id = ccir.compliance_item_id AND pcir.region_sid = ccir.region_sid
		  JOIN flow_item fi ON ccir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		 GROUP BY pcir.app_sid, pcir.flow_item_id
		) req ON cir.flow_item_id = req.flow_item_id AND cir.app_sid = req.app_sid
	   JOIN chain.filter_value fv ON ((fv.num_value = 1 AND NVL(req.open_requirements, 0) > 0) OR (fv.num_value = NVL(req.open_requirements, 0)))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterComplianceItem (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_compliance_item_ids			chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert flow item ids to compliance item ids
		SELECT chain.T_FILTERED_OBJECT_ROW(cir.compliance_item_id, NULL, NULL)
		  BULK COLLECT INTO v_compliance_item_ids
		  FROM compliance_item_region cir
		  JOIN TABLE(in_ids) t ON cir.flow_item_id = t.object_id;
		  
		-- filter compliance items
		compliance_library_report_pkg.GetFilteredIds(
			in_compound_filter_id	=> v_compound_filter_id,
			in_parent_type 			=> compliance_library_report_pkg.PARENT_LEGAL_REGISTER,
			in_id_list				=> v_compliance_item_ids,
			out_id_list				=> v_compliance_item_ids
		);
		
		-- convert compliance item ids to flow item ids
		SELECT chain.T_FILTERED_OBJECT_ROW(flow_item_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT cir.flow_item_id
			  FROM compliance_item_region cir
			  JOIN TABLE(v_compliance_item_ids) t ON cir.compliance_item_id = t.object_id
			  JOIN TABLE(in_ids) ii ON cir.flow_item_id = ii.object_id
		  );
	END IF;
END;

PROCEDURE FilterEmbeddedComplianceItem (
	in_name							IN	chain.filter_field.name%TYPE,
	in_column_sid					IN  security_pkg.T_SID_ID,
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  chain.filter_field.filter_field_id%TYPE,
	in_group_by_index				IN  chain.filter_field.group_by_index%TYPE,
	in_show_all						IN	chain.filter_field.show_all%TYPE,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compliance_item_ids			chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	-- convert flow item ids to compliance item ids
	SELECT chain.T_FILTERED_OBJECT_ROW(cir.compliance_item_id, in_group_by_index, t.group_by_value)
	  BULK COLLECT INTO v_compliance_item_ids
	  FROM compliance_item_region cir
	  JOIN TABLE(in_ids) t ON cir.flow_item_id = t.object_id;
	  
	-- filter compliance items
	compliance_library_report_pkg.RunSingleUnit(in_name, in_column_sid, in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, v_compliance_item_ids, v_compliance_item_ids);
	
	-- convert compliance item ids to flow item ids
	SELECT chain.T_FILTERED_OBJECT_ROW(flow_item_id, in_group_by_index, group_by_value)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT DISTINCT cir.flow_item_id, t.group_by_value
		  FROM compliance_item_region cir
		  JOIN TABLE(v_compliance_item_ids) t ON cir.compliance_item_id = t.object_id
		  JOIN TABLE(in_ids) ii ON cir.flow_item_id = ii.object_id
	  );
END;

PROCEDURE FilterRegion (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_region_sids					chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert flow item ids to compliance item ids
		SELECT chain.T_FILTERED_OBJECT_ROW(cir.region_sid, NULL, NULL)
		  BULK COLLECT INTO v_region_sids
		  FROM compliance_item_region cir
		  JOIN TABLE(in_ids) t ON cir.flow_item_id = t.object_id;
		  
		-- filter compliance items
		region_report_pkg.GetFilteredIds(
			in_compound_filter_id	=> v_compound_filter_id,
			in_id_list				=> v_region_sids,
			out_id_list				=> v_region_sids
		);
		
		-- convert compliance item ids to flow item ids
		SELECT chain.T_FILTERED_OBJECT_ROW(flow_item_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT cir.flow_item_id
			  FROM compliance_item_region cir
			  JOIN TABLE(v_region_sids) t ON cir.region_sid = t.object_id
			  JOIN TABLE(in_ids) ii ON cir.flow_item_id = ii.object_id
		  );
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
		-- convert flow item ids to compliance item ids
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
		  BULK COLLECT INTO v_issue_ids
		  FROM compliance_item_region cir
		  JOIN TABLE(in_ids) t ON cir.flow_item_id = t.object_id
		  JOIN issue_compliance_region icr ON cir.flow_item_id = icr.flow_item_id
		  JOIN issue i ON icr.issue_compliance_region_id = i.issue_compliance_region_id;
		  
		-- filter compliance items
		issue_report_pkg.GetFilteredIds(
			in_compound_filter_id	=> v_compound_filter_id,
			in_id_list				=> v_issue_ids,
			out_id_list				=> v_issue_ids
		);
		
		-- convert compliance item ids to flow item ids
		SELECT chain.T_FILTERED_OBJECT_ROW(flow_item_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT icr.flow_item_id
			  FROM issue i
			  JOIN TABLE(v_issue_ids) t ON i.issue_id = t.object_id
			  JOIN issue_compliance_region icr ON i.issue_compliance_region_id = icr.issue_compliance_region_id
			  JOIN TABLE(in_ids) ii ON icr.flow_item_id = ii.object_id
		  );
	END IF;
END;

PROCEDURE FilterComplianceItemId (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTERED_OBJECT_ROW(cir.flow_item_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_item_region cir
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cir.flow_item_id = t.object_id
	  JOIN chain.filter_value fv
	    ON chain.filter_pkg.CheckNumberRange(cir.compliance_item_id, fv.num_value, fv.min_num_val, fv.max_num_val) = 1
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

END compliance_register_report_pkg;
/