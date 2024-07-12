CREATE OR REPLACE PACKAGE BODY csr.permit_report_pkg
IS

-- private field filter units
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterFlowStateLabel		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActivityStartDtm	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActivityEndDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPermitStartDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPermitEndDtm		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPermitType			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterPermitSubType		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActivityType		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterActivitySubType		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDateUpdated			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDateCreated			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedByUserSid	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSiteCommDtm			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_sids IN chain.T_FILTERED_OBJECT_TABLE, out_sids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAudits				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

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
	v_compound_filter_id			chain.compound_filter.compound_filter_id%TYPE;
BEGIN
	IF in_name LIKE 'CmsFilter.%' THEN
		v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
		cms.filter_pkg.FilterColumnIds(in_filter_id, in_filter_field_id, v_compound_filter_id, in_column_sid, in_sids, out_sids);
	ELSIF in_name = 'ActivityStartDtm' THEN
		FilterActivityStartDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'ActivityEndDtm' THEN
		FilterActivityEndDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'PermitStartDtm' THEN
		FilterPermitStartDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'PermitEndDtm' THEN
		FilterPermitEndDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'PermitType' THEN
		FilterPermitType(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'PermitSubType' THEN
		FilterPermitSubType(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'ActivityType' THEN
		FilterActivityType(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'ActivitySubType' THEN
		FilterActivitySubType(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'RegionSid' THEN
		FilterRegionSid(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'FlowStateLabel' THEN
		FilterFlowStateLabel(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'DateUpdated' THEN
		FilterDateUpdated(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'DateCreated' THEN
		FilterDateCreated(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'CreatedByUserSid' THEN
		FilterCreatedByUserSid(in_filter_id, in_filter_field_id, in_group_by_index, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'SiteCommissioningDtm' THEN
		FilterSiteCommDtm(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSIF in_name = 'AuditFilter' THEN
		FilterAudits(in_filter_id, in_filter_field_id, in_show_all, in_sids, out_sids);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || in_name);
	END IF;
END;

PROCEDURE FilterPermitIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_starting_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_sids;

	IF in_parallel = 0 THEN
		out_sids := in_sids;
	ELSE
		out_sids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.FilterIds', in_filter_id);

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, compound_filter_id, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);

		RunSingleUnit(r.name, r.column_sid, in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);

		chain.filter_pkg.EndDebugLog(v_inner_log_id);

		IF r.comparator = chain.filter_pkg.COMPARATOR_EXCLUDE THEN
			chain.filter_pkg.InvertFilterSet(v_starting_ids, v_result_ids, v_result_ids);
		END IF;

		IF in_parallel = 0 THEN
			v_starting_ids := v_result_ids;
			out_sids := v_result_ids;
		ELSE
			out_sids := out_sids MULTISET UNION v_result_ids;
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
	chain.filter_pkg.RunCompoundFilter('FilterPermitIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types			IN	security.T_SID_TABLE,
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.GetFilterObjectData');

	-- just in case
	DELETE FROM chain.tt_filter_object_data;

	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id,
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END, l.object_id
	  FROM compliance_permit cp
	  JOIN TABLE(in_id_list) l ON cp.compliance_permit_id = l.object_id
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
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_can_manage_compliances		BOOLEAN;
	v_user_sid						security_pkg.T_SID_ID := security_pkg.GetSid;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.GetFilteredIds', in_compound_filter_id);

	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	--v_can_manage_compliances := csr_data_pkg.CheckCapability('Manage compliance items');

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM compliance_permit cp
	  JOIN flow_item fi ON cp.app_sid = fi.app_sid AND cp.flow_item_id = fi.flow_item_id
	  JOIN region r ON cp.app_sid = r.app_sid AND cp.region_sid = r.region_sid AND r.active = 1
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN cp.region_sid END = tr.region_sid
	 WHERE (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_search IS NULL
		OR CONTAINS (cp.title, v_sanitised_search) > 0
		OR CONTAINS (cp.activity_details, v_sanitised_search) > 0
		OR CONTAINS (cp.permit_reference, v_sanitised_search) > 0
		)
	  AND (EXISTS (
				 SELECT 1
				   FROM region_role_member rrm
				   JOIN flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
				  WHERE rrm.app_sid = cp.app_sid
					AND rrm.region_sid = cp.region_sid
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
	 GROUP BY cp.compliance_permit_id;

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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.ApplyBreadcrumb');

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
	out_score_cur 					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.CollectSearchResults');

	OPEN out_cur FOR
		SELECT cp.compliance_permit_id, title, cp.activity_details, permit_reference,
		       permit_start_dtm, permit_end_dtm, activity_start_dtm, activity_end_dtm,
			   cp.permit_type_id, cp.permit_sub_type_id, cp.activity_type_id, cp.activity_sub_type_id,
			   cp.site_commissioning_required, cp.site_commissioning_dtm,
		       cpt.description permit_type, cpst.description permit_sub_type, cat.description activity_type, ast.description activity_sub_type,
			   (SELECT COUNT(*) FROM compliance_permit_condition WHERE compliance_permit_id = cp.compliance_permit_id) conditions,
			   (SELECT COUNT(*) FROM compliance_permit_application WHERE permit_id = cp.compliance_permit_id) applications,
			   r.description region_description, cp.region_sid, cp.date_created, cp.date_updated, cp.created_by created_by_user_sid, cu.full_name created_by,
			   fs.flow_sid, fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key,
			   fs.state_colour flow_state_colour, fs.pos flow_state_pos,
			   NVL(i.open_issues, 0) open_issues,
			   NVL(i.closed_issues, 0) closed_issues, 
			   NVL(i.total_issues, 0) total_issues
		  FROM compliance_permit cp
		  JOIN compliance_permit_type cpt ON cp.permit_type_id = cpt.permit_type_id
		  LEFT JOIN compliance_permit_sub_type cpst ON cp.permit_sub_type_id = cpst.permit_sub_type_id AND cp.permit_type_id = cpst.permit_type_id
		  JOIN compliance_activity_type cat ON cp.activity_type_id = cat.activity_type_id
		  LEFT JOIN compliance_activity_sub_type ast ON cp.activity_sub_type_id = ast.activity_sub_type_id AND cp.activity_type_id = ast.activity_type_id
		  JOIN TABLE (in_id_list) fil_list ON fil_list.sid_id = cp.compliance_permit_id
		  JOIN v$region r ON cp.region_sid = r.region_sid
		  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN csr_user cu ON cp.created_by = cu.csr_user_sid
		  LEFT JOIN (
					SELECT i.app_sid, 
						   i.permit_id,
						   COUNT(i.resolved_dtm) closed_issues, 
						   COUNT(i.issue_id) total_issues,
					       COUNT(CASE WHEN NVL(i.resolved_dtm, i.rejected_dtm) IS NULL 
								THEN i.issue_id 
								ELSE NULL 
						   END) open_issues
					  FROM issue i
					 WHERE i.deleted = 0 AND i.issue_compliance_region_id IS NULL
					 GROUP BY i.app_sid, i.permit_id
			   ) i ON i.app_sid = cp.app_sid AND i.permit_id = cp.compliance_permit_id
		 ORDER BY fil_list.pos;
	
	OPEN out_score_cur FOR
		SELECT s.compliance_permit_id, s.score, s.score_threshold_id, st.description,
				s.changed_by_user_sid,
				st.text_colour, st.background_colour, t.label score_type_label,
				t.score_type_id, t.allow_manual_set, t.format_mask, s.valid_until_dtm
		  FROM v$current_compl_perm_score s
		  JOIN TABLE (in_id_list) ON sid_id = s.compliance_permit_id
		  JOIN score_type t ON s.score_type_id = t.score_type_id
		  LEFT JOIN score_threshold st ON st.score_threshold_id = s.score_threshold_id
		 WHERE t.hidden = 0
		   AND t.applies_to_permits = 1
		 ORDER BY t.pos, t.score_type_id;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredPermitItemIds (
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.PageFilteredPermitItemIds');

	IF in_order_by = 'permitStartDtm' AND in_order_dir = 'DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.object_id, ROWNUM rn
			  FROM (
				SELECT fil_list.object_id
				  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list
				  JOIN compliance_permit cp ON fil_list.object_id = cp.compliance_permit_id
				 ORDER BY cp.permit_start_dtm DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSIF in_order_by IN ('totalIssues', 'openIssues', 'closedIssues') THEN
		SELECT security.T_ORDERED_SID_ROW(compliance_permit_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT compliance_permit_id, ROWNUM rn
			  FROM (
				SELECT cp.compliance_permit_id
				  FROM compliance_permit cp
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cp.compliance_permit_id
				  LEFT JOIN (
							SELECT i.app_sid, 
								   i.permit_id,
								   COUNT(i.resolved_dtm) closed_issues, 
								   COUNT(i.issue_id) total_issues,
								   COUNT(CASE WHEN NVL(i.resolved_dtm, i.rejected_dtm) IS NULL 
										THEN i.issue_id 
										ELSE NULL 
								   END) open_issues
							  FROM issue i
							 WHERE i.deleted = 0 AND i.issue_compliance_region_id IS NULL
							 GROUP BY i.app_sid, i.permit_id
					   ) i ON i.app_sid = cp.app_sid AND i.permit_id = cp.compliance_permit_id
				ORDER BY 
					CASE WHEN NVL(in_order_dir, 'ASC') = 'ASC' THEN
						CASE in_order_by
							WHEN 'totalIssues' THEN total_issues
							WHEN 'openIssues' THEN open_issues
							WHEN 'closedIssues' THEN closed_issues
						END 
					END ASC,
					CASE WHEN in_order_dir = 'DESC' THEN
						CASE in_order_by
							WHEN 'totalIssues' THEN total_issues
							WHEN 'openIssues' THEN open_issues
							WHEN 'closedIssues' THEN closed_issues
						END 
					END DESC,
					CASE WHEN NVL(in_order_dir, 'ASC') = 'ASC' THEN cp.permit_start_dtm END ASC,
					CASE WHEN in_order_dir = 'DESC' THEN cp.permit_start_dtm END DESC
				) 
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
		  
	ELSIF in_order_by IN ('score.%', 'scoreThreshold.%') THEN
		SELECT security.T_ORDERED_SID_ROW(compliance_permit_id, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT compliance_permit_id, ROWNUM rn
			  FROM (
				SELECT cp.compliance_permit_id
				  FROM compliance_permit cp
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cp.compliance_permit_id
				  LEFT JOIN (SELECT compliance_permit_id, score 
							   FROM v$current_compl_perm_score
							  WHERE score_type_id = CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER)			
					)cps ON cp.compliance_permit_id = cps.compliance_permit_id
				 ORDER BY 
					CASE WHEN in_order_dir='DESC' OR in_order_dir IS NULL THEN cps.score END DESC, 
					CASE WHEN in_order_dir='ASC' THEN cps.score END ASC
				) 
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);

		SELECT security.T_ORDERED_SID_ROW(compliance_permit_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.compliance_permit_id, ROWNUM rn
				  FROM (
					SELECT cp.compliance_permit_id
					  FROM compliance_permit cp
					  JOIN v$region r ON cp.app_sid = r.app_sid AND cp.region_sid = r.region_sid
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cp.compliance_permit_id
					  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id
					  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'flowItemId' THEN TO_CHAR(cp.flow_item_id, '0000000000')
									WHEN 'regionDescription' THEN LOWER(r.description)
									WHEN 'compliancePermitId' THEN TO_CHAR(cp.compliance_permit_id, '0000000000')
									WHEN 'title' THEN LOWER(cp.title)
									WHEN 'permitReference' THEN LOWER(cp.permit_reference)
									WHEN 'activityStartDtm' THEN TO_CHAR(cp.activity_start_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'activityEndDtm' THEN TO_CHAR(cp.activity_end_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'permitEndDtm' THEN TO_CHAR(cp.permit_end_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'permitType' THEN TO_CHAR(cp.permit_type_id, '0000000000')
									WHEN 'permitSubType' THEN TO_CHAR(cp.permit_sub_type_id, '0000000000')
									WHEN 'activityType' THEN TO_CHAR(cp.activity_type_id, '0000000000')
									WHEN 'activitySubType' THEN TO_CHAR(cp.activity_sub_type_id, '0000000000')
									WHEN 'dateCreated' THEN TO_CHAR(cp.date_created, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'dateUpdated' THEN TO_CHAR(cp.date_updated, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdByUserSid' THEN TO_CHAR(cp.created_by, '0000000000')
									WHEN 'siteCommissioningRequired' THEN TO_CHAR(cp.site_commissioning_required, '000')
									WHEN 'siteCommissioningDtm' THEN TO_CHAR(cp.site_commissioning_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'conditions' THEN TO_CHAR((SELECT COUNT(*) FROM compliance_permit_condition WHERE compliance_permit_id = cp.compliance_permit_id), '0000000000')
									WHEN 'applications' THEN TO_CHAR((SELECT COUNT(*) FROM compliance_permit_application WHERE permit_id = cp.compliance_permit_id), '0000000000')
									WHEN 'flowStateLabel' THEN fs.label
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'flowItemId' THEN TO_CHAR(cp.flow_item_id, '0000000000')
									WHEN 'regionDescription' THEN LOWER(r.description)
									WHEN 'compliancePermitId' THEN TO_CHAR(cp.compliance_permit_id, '0000000000')
									WHEN 'title' THEN LOWER(cp.title)
									WHEN 'permitReference' THEN LOWER(cp.permit_reference)
									WHEN 'activityStartDtm' THEN TO_CHAR(cp.activity_start_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'activityEndDtm' THEN TO_CHAR(cp.activity_end_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'permitEndDtm' THEN TO_CHAR(cp.permit_end_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'permitType' THEN TO_CHAR(cp.permit_type_id, '0000000000')
									WHEN 'permitSubType' THEN TO_CHAR(cp.permit_sub_type_id, '0000000000')
									WHEN 'activityType' THEN TO_CHAR(cp.activity_type_id, '0000000000')
									WHEN 'activitySubType' THEN TO_CHAR(cp.activity_sub_type_id, '0000000000')
									WHEN 'dateCreated' THEN TO_CHAR(cp.date_created, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'dateUpdated' THEN TO_CHAR(cp.date_updated, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'createdByUserSid' THEN TO_CHAR(cp.created_by, '0000000000')
									WHEN 'siteCommissioningRequired' THEN TO_CHAR(cp.site_commissioning_required, '000')
									WHEN 'siteCommissioningDtm' THEN TO_CHAR(cp.site_commissioning_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'conditions' THEN TO_CHAR((SELECT COUNT(*) FROM compliance_permit_condition WHERE compliance_permit_id = cp.compliance_permit_id), '0000000000')
									WHEN 'applications' THEN TO_CHAR((SELECT COUNT(*) FROM compliance_permit_application WHERE permit_id = cp.compliance_permit_id), '0000000000')
									WHEN 'flowStateLabel' THEN fs.label
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cp.permit_start_dtm END ASC,
							CASE WHEN in_order_dir='DESC' THEN cp.permit_start_dtm END DESC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_PERMITS, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Permit -> '||v_name);

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
	out_score_cur 					OUT SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.GetPermitList', in_compound_filter_id);

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

	-- Get the total number of rows (to work out number of pages)
	SELECT COUNT(DISTINCT object_id)
	  INTO out_total_rows
	  FROM TABLE(v_id_list);

	PageFilteredPermitItemIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);

	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_score_cur);

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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_PERMITS, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_PERMITS
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.GetReportData', in_compound_filter_id);

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

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_PERMITS, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);

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
	out_score_cur					OUT SYS_REFCURSOR
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

	CollectSearchResults(v_id_page, out_cur, out_score_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_score_cur					OUT SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.permit_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_PERMITS
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
		out_score_cur				=> out_score_cur
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
			SELECT cp.region_sid
			  FROM compliance_permit cp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.compliance_permit_id = t.object_id
			 GROUP BY cp.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, cp.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT cp.compliance_permit_id, fv.filter_value_id
			  FROM compliance_permit cp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.compliance_permit_id = t.object_id
			  JOIN chain.filter_value fv ON cp.region_sid = fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) cp;
	ELSE
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.compliance_permit_id = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON cp.region_sid = r.region_sid;				 
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
	v_permit_flow_sid				security_pkg.T_SID_ID;
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		SELECT MIN(permit_flow_sid)
		  INTO v_permit_flow_sid
		  FROM compliance_options;

		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description, num_value)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, fs.label, fs.label, fs.flow_state_id
		  FROM (
			SELECT fs.label, MIN(fs.flow_state_id) flow_state_id
			  FROM flow_state fs
			 WHERE fs.flow_sid = v_permit_flow_sid		 
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
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_permit cp
	  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id AND cp.app_sid = fi.app_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	  JOIN chain.filter_value fv ON fs.label = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterActivityStartDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.activity_start_dtm), MAX(cp.activity_start_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cp.activity_start_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cp.activity_start_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			cp.activity_start_dtm IS NOT NULL AND
			cp.activity_start_dtm >= NVL(dr.start_dtm, cp.activity_start_dtm) AND 
			(dr.end_dtm IS NULL OR cp.activity_start_dtm < dr.end_dtm));
END;

PROCEDURE FilterActivityEndDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.activity_end_dtm), MAX(cp.activity_end_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cp.activity_end_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cp.activity_end_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			cp.activity_end_dtm IS NOT NULL AND
			cp.activity_end_dtm >= NVL(dr.start_dtm, cp.activity_end_dtm) AND 
			(dr.end_dtm IS NULL OR cp.activity_end_dtm < dr.end_dtm));
END;

PROCEDURE FilterSiteCommDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.site_commissioning_dtm), MAX(cp.site_commissioning_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cp.site_commissioning_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cp.site_commissioning_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			cp.site_commissioning_dtm IS NOT NULL AND
			cp.site_commissioning_dtm >= NVL(dr.start_dtm, cp.site_commissioning_dtm) AND 
			(dr.end_dtm IS NULL OR cp.site_commissioning_dtm < dr.end_dtm));
END;

PROCEDURE FilterPermitStartDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.permit_start_dtm), MAX(cp.permit_start_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cp.permit_start_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cp.permit_start_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			cp.permit_start_dtm IS NOT NULL AND
			cp.permit_start_dtm >= NVL(dr.start_dtm, cp.permit_start_dtm) AND 
			(dr.end_dtm IS NULL OR cp.permit_start_dtm < dr.end_dtm));

END;

PROCEDURE FilterPermitEndDtm (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.permit_end_dtm), MAX(cp.permit_end_dtm)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON (dr.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND
			cp.permit_end_dtm IS NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL AND
			cp.permit_end_dtm IS NOT NULL)
		OR (dr.null_filter = chain.filter_pkg.NULL_FILTER_ALL AND 
			cp.permit_end_dtm IS NOT NULL AND
			cp.permit_end_dtm >= NVL(dr.start_dtm, cp.permit_end_dtm) AND 
			(dr.end_dtm IS NULL OR cp.permit_end_dtm < dr.end_dtm));

END;

PROCEDURE FilterPermitType (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id 				IN  NUMBER, 
	in_group_by_index 				IN  NUMBER, 
	in_show_all 					IN  NUMBER, 
	in_sids 						IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cpt.permit_type_id, cpt.description
		  FROM compliance_permit_type cpt
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = cpt.permit_type_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = cp.permit_type_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterPermitSubType (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id 				IN  NUMBER, 
	in_group_by_index 				IN  NUMBER, 
	in_show_all 					IN  NUMBER, 
	in_sids 						IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cpst.description, cpst.description
		  FROM compliance_permit_sub_type cpst
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = cpst.description
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  LEFT JOIN compliance_permit_sub_type cpst 
		ON cp.permit_sub_type_id = cpst.permit_sub_type_id AND cp.permit_type_id = cpst.permit_type_id
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.filter_value fv ON fv.str_value = cpst.description
		OR (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND cpst.permit_sub_type_id IS NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterActivityType (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id 				IN  NUMBER, 
	in_group_by_index 				IN  NUMBER, 
	in_show_all 					IN  NUMBER, 
	in_sids 						IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cat.activity_type_id, cat.description
		  FROM compliance_activity_type cat
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = cat.activity_type_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.filter_value fv ON fv.num_value = cp.activity_type_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;


PROCEDURE FilterActivitySubType (
	in_filter_id 					IN  chain.filter.filter_id%TYPE, 
	in_filter_field_id 				IN  NUMBER, 
	in_group_by_index 				IN  NUMBER, 
	in_show_all 					IN  NUMBER, 
	in_sids 						IN  chain.T_FILTERED_OBJECT_TABLE, 
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cat.description, cat.description
		  FROM compliance_activity_sub_type cat
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = cat.description
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  LEFT JOIN compliance_activity_sub_type cat ON cp.activity_sub_type_id = cat.activity_sub_type_id AND cp.activity_type_id = cat.activity_type_id
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.filter_value fv ON fv.str_value = cat.description 
		OR (fv.null_filter = chain.filter_pkg.NULL_FILTER_REQUIRE_NULL AND cp.activity_sub_type_id IS NULL)
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterDateUpdated (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.date_updated), MAX(cp.date_updated)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON cp.date_updated >= NVL(dr.start_dtm, cp.date_updated)
	   AND (dr.end_dtm IS NULL OR cp.date_updated < dr.end_dtm)
	 WHERE cp.date_updated IS NOT NULL;

END;

PROCEDURE FilterDateCreated (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date			DATE;
	v_max_date			DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		SELECT MIN(cp.date_created), MAX(cp.date_created)
		  INTO v_min_date, v_max_date
		  FROM compliance_permit cp
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id;

		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);

	END IF;

	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_sids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.tt_filter_date_range dr
		ON cp.date_created >= NVL(dr.start_dtm, cp.date_created)
	   AND (dr.end_dtm IS NULL OR cp.date_created < dr.end_dtm)
	 WHERE cp.date_created IS NOT NULL;

END;

PROCEDURE FilterCreatedByUserSid (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN	NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		-- ensure the filter_value rows include all assigned to users for the current filter
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cb.created_by
		  FROM (
			SELECT DISTINCT created_by
			  FROM compliance_permit cp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.compliance_permit_id = t.object_id
			  ) cb
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = cb.created_by
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(cp.compliance_permit_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM compliance_permit cp
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cp.compliance_permit_id = t.object_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = cp.created_by
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND cp.created_by = SYS_CONTEXT('SECURITY', 'SID'))
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterAudits (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;	
	v_audit_ids						chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);
	
	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO v_audit_ids
		  FROM compliance_permit p
		  JOIN internal_audit ia ON p.compliance_permit_id = ia.permit_id
		  JOIN TABLE(in_ids) t ON p.compliance_permit_id = t.object_id;
		  
		-- filter audits
		audit_report_pkg.GetFilteredIds(
			in_search						=> NULL,
			in_group_key					=> NULL,
			in_compound_filter_id			=> v_compound_filter_id,
			in_id_list						=> v_audit_ids,
			out_id_list						=> v_audit_ids
		);
		
		SELECT chain.T_FILTERED_OBJECT_ROW(p.compliance_permit_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM compliance_permit p
		  JOIN internal_audit ia ON p.compliance_permit_id = ia.permit_id
		  JOIN TABLE(v_audit_ids) t ON ia.internal_audit_sid = t.object_id;
	END IF;
END;

END permit_report_pkg;
/
