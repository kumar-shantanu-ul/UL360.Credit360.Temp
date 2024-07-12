CREATE OR REPLACE PACKAGE BODY CSR.issue_report_pkg
IS

-- This is matched Credit360.Issues.ParentType enum in 
-- /csr/web/shared/IssueFilterList.js -- these need to be kept in sync
PARENT_TYPE_PROPERTY				CONSTANT NUMBER := 1;
PARENT_TYPE_SUPPLIER				CONSTANT NUMBER := 2;
PARENT_TYPE_AUDIT					CONSTANT NUMBER := 3;
PARENT_TYPE_COMPLIANCE				CONSTANT NUMBER := 4;

-- private field filter units
PROCEDURE FilterIssueTypeId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIssuePriorityId		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAuditTypeId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterStatus				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRagStatusId			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOwnerSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAssignedToSid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRaisedBySid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterResolvedBySid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterClosedBySid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterInvolvingSid		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOverdue				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCritical			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterUnread				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegionSid			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCustomFields		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterDueDate				(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterForecastDate		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLastModifiedDate	(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRaisedDate			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterResolvedDate		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterClosedDate			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterOverdueBy			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterSavedFilter			(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_comparator IN chain.filter_field.comparator%TYPE, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterNonCompliances		(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

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
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_inner_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, NVL(show_all, 0) show_all, group_by_index, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'IssueTypeId' THEN
			FilterIssueTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IssuePriorityId' THEN
			FilterIssuePriorityId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AuditTypeId' THEN
			FilterAuditTypeId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Status' THEN
			FilterStatus(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RagStatusId' THEN
			FilterRagStatusId(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OwnerUserSid' THEN
			FilterOwnerSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AssignedToUserSid' THEN
			FilterAssignedToSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ResolvedByUserSid' THEN
			FilterResolvedBySid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ClosedByUserSid' THEN
			FilterClosedBySid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RaisedByUserSid' THEN
			FilterRaisedBySid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'InvolvingUserSid' THEN
			FilterInvolvingSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Overdue' THEN
			FilterOverdue(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Unread' THEN
			FilterUnread(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IsCritical' THEN
			FilterCritical(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RegionSid' THEN
			FilterRegionSid(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name LIKE 'CustomField.%' THEN
			FilterCustomFields(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'DueDate' THEN
			FilterDueDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ForecastDate' THEN
			FilterForecastDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'LastModifiedDate' THEN
			FilterLastModifiedDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RaisedDate' THEN
			FilterRaisedDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ClosedDate' THEN
			FilterClosedDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ResolvedDate' THEN
			FilterResolvedDate(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'OverdueBy' THEN
			FilterOverdueBy(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF LOWER(r.name) = 'savedfilter' THEN
			FilterSavedFilter(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, r.comparator, v_starting_ids, v_result_ids);
		ELSIF r.name = 'NonComplianceFilter' THEN
			FilterNonCompliances(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
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
	in_from_filter_id			IN	chain.filter.filter_id%TYPE,
	in_to_filter_id				IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	chain.filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE RunCompoundFilter(
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_parallel					IN	NUMBER,
	in_max_group_by				IN	NUMBER,
	in_id_list					IN	chain.T_FILTERED_OBJECT_TABLE,
	out_id_list					OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	chain.filter_pkg.RunCompoundFilter('FilterIds', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types	IN	security.T_SID_TABLE,
	in_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id					chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	-- assumes rejected issues were open for 0/NULL days
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT agg.column_value, l.object_id, 
			CASE agg.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				WHEN AGG_TYPE_DAYS_OPEN THEN chain.filter_pkg.AFUNC_SUM
				WHEN AGG_TYPE_DAYS_OVERDUE THEN chain.filter_pkg.AFUNC_SUM
				WHEN AGG_TYPE_AVG_DAYS_OPEN THEN chain.filter_pkg.AFUNC_AVERAGE
				WHEN AGG_TYPE_AVG_DAYS_OVRDUE THEN chain.filter_pkg.AFUNC_AVERAGE
			END,
			CASE agg.column_value
				WHEN AGG_TYPE_COUNT THEN l.object_id
				WHEN AGG_TYPE_DAYS_OPEN THEN
					CASE WHEN i.rejected_dtm IS NULL THEN
						ROUND(COALESCE(i.manual_completion_dtm, i.resolved_dtm, SYSDATE) - i.raised_dtm)
					END
				WHEN AGG_TYPE_DAYS_OVERDUE THEN
					CASE WHEN i.rejected_dtm IS NULL AND COALESCE(i.manual_completion_dtm, i.resolved_dtm, SYSDATE) > i.due_dtm THEN
						ROUND(COALESCE(i.manual_completion_dtm, i.resolved_dtm, SYSDATE) - i.due_dtm)
					END
				WHEN AGG_TYPE_AVG_DAYS_OPEN THEN
					CASE WHEN i.rejected_dtm IS NULL THEN
						ROUND(COALESCE(i.manual_completion_dtm, i.resolved_dtm, SYSDATE) - i.raised_dtm)
					END
				WHEN AGG_TYPE_AVG_DAYS_OVRDUE THEN
					CASE WHEN i.rejected_dtm IS NULL AND COALESCE(i.manual_completion_dtm, i.resolved_dtm, SYSDATE) > i.due_dtm THEN
						ROUND(COALESCE(i.manual_completion_dtm, i.resolved_dtm, SYSDATE) - i.due_dtm)
					END
			END
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) l ON i.issue_id = l.object_id
	  CROSS JOIN TABLE(in_aggregation_types) agg
	;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetPermissibleIds (
	out_id_list						OUT	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_restrict_issue_visibility		NUMBER(1) := 0;
	v_is_builtin_admin				NUMBER(1) := 0;
	v_has_capability				NUMBER(1) := 0;
	v_has_region_root_start_point	NUMBER(1) := issue_pkg.HasRegionRootStartPoint;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetPermissibleIds');
	
	SELECT restrict_issue_visibility
	  INTO v_restrict_issue_visibility
	  FROM csr.customer;

	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		v_is_builtin_admin := 1;
	END IF;
	IF csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Issue management') THEN
		v_has_capability := 1;
	END IF;

	-- Start with a list of all issue ids that the user has access to, i.e. without issues outside user's
	-- starting point unless they are involved directly as creator, assigned to or by issue_involvement.user_sid.
	-- We assume they only have roles on regions within their starting point.
	-- We treat issues without a region_sid as customer.region_root_sid.
	-- Some issues will not have a region_sid, but will refer to something at a known region_sid
	-- e.g. issues coming from CMS forms. Ideally we would build that link sometime in the future.
	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM issue i
	  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
	  LEFT JOIN (
		SELECT region_sid
		  FROM region
		 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	  ) r ON i.region_sid = r.region_sid
	  LEFT JOIN issue_involvement ii ON i.app_sid = ii.app_sid AND i.issue_id = ii.issue_id AND ii.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	  LEFT JOIN issue_involvement iic ON i.app_sid = iic.app_sid AND i.issue_id = iic.issue_id AND iic.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	 WHERE i.deleted = 0 -- exclude deleted
	   -- have permissions
	   AND (
			v_is_builtin_admin = 1
			OR (v_restrict_issue_visibility = 0 AND i.is_public = 1)
			OR v_has_capability = 1
			OR (i.is_public = 1
				AND (r.region_sid IS NOT NULL
					OR v_has_region_root_start_point = 1
					OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					OR i.raised_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					OR ii.issue_id IS NOT NULL
					OR iic.issue_id IS NOT NULL)
				)
			OR (EXISTS (
					SELECT *
					  FROM region_role_member rrm
					  JOIN issue_involvement ii
						ON rrm.app_sid = ii.app_sid
					   AND rrm.role_sid = ii.role_sid
					 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
					   AND rrm.region_sid = i.region_sid
					   AND ii.issue_id = i.issue_id
					)
					OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					OR i.raised_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					OR ii.issue_id IS NOT NULL
					OR iic.issue_id IS NOT NULL
				)
		);
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE GetInitialIds (
	in_search						IN	VARCHAR2 DEFAULT NULL,
	in_group_key					IN	chain.saved_filter.group_key%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	chain.saved_filter.saved_filter_sid%TYPE DEFAULT NULL,
	in_parent_type					IN	NUMBER DEFAULT NULL,
	in_parent_id					IN	NUMBER DEFAULT NULL,
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
	v_permissible_ids				chain.T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
	v_has_regions					NUMBER;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_searched_ids					security.T_SID_TABLE;
	v_log_id_2						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetInitialIds');
	
	chain.filter_pkg.GetFilteredObjectsFromCache(
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES,
		out_filtered_objects => v_permissible_ids
	);
	
	IF v_permissible_ids IS NULL THEN
		GetPermissibleIds(v_permissible_ids);
		
		chain.filter_pkg.SetFilteredObjectsInCache(
			in_card_group_id => chain.filter_pkg.FILTER_TYPE_ISSUES,
			in_filtered_objects => v_permissible_ids
		);
	END IF;

	IF in_id_list IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(t1.object_id, NULL, NULL)
		  BULK COLLECT INTO v_temp_ids
		  FROM TABLE(in_id_list) t1 
		  JOIN TABLE(v_permissible_ids) t2 on t1.object_id = t2.object_id;

		v_permissible_ids := v_temp_ids;
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
				in_id_list						=> v_permissible_ids,
				out_id_list						=> v_permissible_ids
			);
		END LOOP;
	END IF;
	
	IF in_search IS NULL AND
	   v_sanitised_search IS NULL AND 
	   in_parent_type IS NULL AND
	   (in_date_col_type IS NULL OR (in_start_dtm IS NULL AND in_end_dtm IS NULL)) AND
	   (in_region_col_type IS NULL OR in_region_sids IS NULL OR CARDINALITY(in_region_sids) = 0) THEN
		
		-- Nothing else to filter, return permissible IDs
		out_id_list := v_permissible_ids;
		chain.filter_pkg.EndDebugLog(v_log_id);
		RETURN;
		
	END IF;
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	
	-- Do the search separately - oracle is quick at querying a freetext index to get you some IDs
	-- but for some reason slow at doing that as part of a join
	IF v_sanitised_search IS NOT NULL OR in_search IS NOT NULL THEN
		
		v_log_id_2 := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetInitialIds.FreeTextSearch');
		SELECT issue_id
		  BULK COLLECT INTO v_searched_ids
		  FROM (
			SELECT issue_id
			  FROM issue
			 WHERE (INSTR(v_sanitised_search, '%') > 0 AND CONTAINS (label, v_sanitised_search) > 0) 
			    OR (INSTR(v_sanitised_search, '%') = 0 AND UPPER(label) LIKE '%' || UPPER(in_search) || '%' )
			 UNION -- this could have been done with an OR, but was 1000% slower
			SELECT issue_id
			  FROM issue
			 WHERE (INSTR(v_sanitised_search, '%') > 0 AND CONTAINS (description, v_sanitised_search) > 0)
			    OR (INSTR(v_sanitised_search, '%') = 0 AND UPPER(description) LIKE '%' || UPPER(in_search) || '%' )
			 UNION
			SELECT issue_id
			  FROM issue_log
			 WHERE (INSTR(v_sanitised_search, '%') > 0 AND CONTAINS (message, v_sanitised_search) > 0)
			    OR (INSTR(v_sanitised_search, '%') = 0 AND UPPER(message) LIKE '%' || UPPER(in_search) || '%' )
			);
		chain.filter_pkg.EndDebugLog(v_log_id_2);
		aspen2.request_queue_pkg.AssertRequestStillActive;
	END IF;
	
	v_log_id_2 := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetInitialIds.InitialFilter');

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM issue i
	  JOIN (SELECT object_id FROM TABLE(v_permissible_ids) ORDER BY object_id) p ON i.issue_id = p.object_id
	  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
	  LEFT JOIN temp_region_sid tr ON CASE in_region_col_type WHEN COL_TYPE_REGION_SID THEN i.region_sid END = tr.region_sid
	  LEFT JOIN (SELECT column_value FROM TABLE(v_searched_ids) ORDER BY column_value) srch ON i.issue_id = srch.column_value
	  LEFT JOIN issue_supplier isup ON in_parent_type = PARENT_TYPE_SUPPLIER AND 
			    i.issue_supplier_id = isup.issue_supplier_id AND i.app_sid = isup.app_sid AND isup.company_sid = in_parent_id
	  LEFT JOIN issue_non_compliance inc ON in_parent_type = PARENT_TYPE_AUDIT AND
				inc.app_sid = i.app_sid AND inc.issue_non_compliance_id = i.issue_non_compliance_id
	  LEFT JOIN audit_non_compliance anc ON in_parent_type = PARENT_TYPE_AUDIT AND
				inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid AND
				(anc.internal_audit_sid = in_parent_id OR in_parent_id IS NULL)
	  LEFT JOIN issue_compliance_region icr ON in_parent_type = PARENT_TYPE_COMPLIANCE AND 
	  			icr.app_sid = i.app_sid AND icr.issue_compliance_region_id = i.issue_compliance_region_id
	  LEFT JOIN v$region r ON r.region_sid = i.region_sid
	  LEFT JOIN csr.supplier s ON r.region_sid = s.region_sid
	 WHERE (in_parent_type IS NULL OR
			(in_parent_type = PARENT_TYPE_PROPERTY AND i.region_sid = in_parent_id) OR
			(in_parent_type = PARENT_TYPE_AUDIT AND anc.internal_audit_sid IS NOT NULL) OR
			(in_parent_type = PARENT_TYPE_SUPPLIER AND s.company_sid = in_parent_id ) OR 
			(in_parent_type = PARENT_TYPE_COMPLIANCE 
				AND (icr.flow_item_id = in_parent_id 
					 OR (permit_id = in_parent_id))))
	   AND (v_has_regions = 0 OR tr.region_sid IS NOT NULL)
	   AND (in_date_col_type IS NULL OR (
			(in_start_dtm IS NULL OR in_start_dtm <= 
				CASE in_date_col_type 
					WHEN COL_TYPE_RAISED_DTM THEN i.raised_dtm 
					WHEN COL_TYPE_RESOLVED_DTM THEN NVL(i.manual_completion_dtm, i.resolved_dtm)
					WHEN COL_TYPE_DUE_DTM THEN i.due_dtm 
					WHEN COL_TYPE_FORECAST_DTM THEN i.forecast_dtm 
				END
			) AND
			(in_end_dtm IS NULL OR in_end_dtm > 
				CASE in_date_col_type 
					WHEN COL_TYPE_RAISED_DTM THEN i.raised_dtm 
					WHEN COL_TYPE_RESOLVED_DTM THEN NVL(i.manual_completion_dtm, i.resolved_dtm)
					WHEN COL_TYPE_DUE_DTM THEN i.due_dtm 
					WHEN COL_TYPE_FORECAST_DTM THEN i.forecast_dtm 
				END
			) 
	   ))
	   -- matches the search
	   AND (in_search IS NULL OR (
		   srch.column_value IS NOT NULL
		OR UPPER(it.internal_issue_ref_prefix||NVL(i.issue_ref, i.issue_id)) = UPPER(in_search)
		OR UPPER(r.description) LIKE '%' || UPPER(in_search) || '%'
		OR EXISTS (SELECT *
					 FROM issue_non_compliance ict
					 JOIN audit_non_compliance anc ON ict.app_sid = anc.app_sid AND ict.non_compliance_id = anc.non_compliance_id
					 JOIN internal_audit ia ON anc.app_sid = ia.app_sid AND anc.internal_audit_sid = ia.internal_audit_sid
					 JOIN internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
					 JOIN internal_audit_type_group iatg ON iat.app_sid = iatg.app_sid AND iat.internal_audit_type_group_id = iatg.internal_audit_type_group_id
					WHERE iatg.internal_audit_ref_prefix IS NOT NULL
					  AND ict.issue_non_compliance_id = i.issue_non_compliance_id
					  -- match on [prefix][ID] on audits
					  AND UPPER(iatg.internal_audit_ref_prefix||NVL(ia.internal_audit_ref, ia.internal_audit_sid)) = UPPER(in_search)
			)
		OR EXISTS (SELECT *
					 FROM non_compliance nc
					 JOIN non_compliance_type nct ON nc.app_sid = nct.app_sid AND nc.non_compliance_type_id = nct.non_compliance_type_id
					 JOIN issue_non_compliance ict ON nc.app_sid = ict.app_sid AND nc.non_compliance_id = ict.non_compliance_id
					WHERE nct.inter_non_comp_ref_prefix IS NOT NULL
					  AND ict.issue_non_compliance_id = i.issue_non_compliance_id
					  -- match on [prefix][ID] on non-compliances
					  AND UPPER(nct.inter_non_comp_ref_prefix||NVL(nc.non_compliance_ref, nc.non_compliance_id)) = UPPER(in_search)
			)
	   ));

	chain.filter_pkg.EndDebugLog(v_log_id_2);
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
	-- Step 1, get initial set of ids
	GetInitialIds(in_search, in_group_key, in_pre_filter_sid, in_parent_type, in_parent_id, in_region_sids,
		in_start_dtm, in_end_dtm, in_region_col_type, in_date_col_type, in_id_list, out_id_list);

	-- Step 2, If there's a filter, restrict the list of issue ids
	IF NVL(in_compound_filter_id, 0) > 0 THEN -- XPJ passes round zero for some reason?
		RunCompoundFilter(in_compound_filter_id, 0, NULL, out_id_list, out_id_list);
	END IF;
END;

PROCEDURE ApplyBreadcrumb (
	in_id_list						IN  chain.T_FILTERED_OBJECT_TABLE,
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.ApplyBreadcrumb');
	
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

-- why is this taking ordering data?
PROCEDURE CollectSearchResults(
	in_id_list						IN	security.T_ORDERED_SID_TABLE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_cust_vals					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','SID');
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_permissible_cust_fields		security.T_SID_TABLE;
BEGIN
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.CollectSearchResults');
	v_permissible_cust_fields := issue_pkg.GetPermissibleCustomFields();

	-- Return a page of results
	OPEN out_cur FOR
		WITH p AS (
			SELECT /*+ MATERIALIZE */ t.root_region_sid, t.region_path, ROW_NUMBER() over (PARTITION BY t.root_region_sid ORDER BY t.lvl DESC) rn
			  FROM (
				SELECT CONNECT_BY_ROOT region_sid root_region_sid, RTRIM(REVERSE(SYS_CONNECT_BY_PATH(REVERSE(description), ' > ')), '> ') region_path, level lvl
				  FROM v$region
				 WHERE region_sid IN (
					SELECT region_sid 
					  FROM region_start_point
					 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
					)
				 START WITH region_sid IN (
					SELECT DISTINCT i.region_sid 
					  FROM issue i
					  JOIN TABLE(in_id_list) issue_ids ON issue_ids.sid_id = i.issue_id)
			   CONNECT BY PRIOR parent_sid = region_sid
			  ) t
		)
		SELECT /*+ALL_ROWS CARDINALITY(fil_list, 100)*/ i.issue_id, i.status, i.issue_type_id, i.issue_type_label, i.is_overdue, i.is_closed, i.is_resolved, i.is_rejected,
				i.label, i.description, CASE WHEN i.assigned_to_user_sid = v_user_sid THEN 1 ELSE 0 END is_involved, i.is_owner,
				i.raised_by_user_sid, i.raised_full_name, i.assigned_to_user_sid, i.assigned_to_full_name, i.assigned_to_role_sid, i.assigned_to_role_name,
				i.owner_user_sid, i.owner_full_name, i.owner_role_sid, i.owner_role_name,
				i.due_dtm, i.forecast_dtm, i.raised_dtm, source_label, i.manual_completion_dtm, i.resolved_dtm, i.last_modified_dtm, i.closed_dtm, i.rejected_dtm,
				CASE WHEN ilr.read_dtm IS NULL AND il.logged_by_user_sid != v_user_sid THEN 0 ELSE 1 END last_issue_log_is_read,
				il.message last_log_message, il.logged_dtm last_message_logged_dtm, il.logged_by_full_name last_logged_by_full_name, NVL(il.is_user, 0) last_logged_by_is_user,
				i.region_sid, r.description region_description, r.region_type, rt.class_name region_type_class_name,
				i.issue_priority_id, i.priority_description, i.issue_non_compliance_id, i.rag_status_id, i.rag_status_label, i.rag_status_colour,
				i.custom_issue_id,
				NVL(ia.internal_audit_ref, ia.internal_audit_sid) created_in_audit_sid,
				nc.non_compliance_ref, nc.non_compliance_id,
				iat.label audit_type_label, nct.label non_compliance_type,
				ia.audit_dtm, NVL(i.custom_issue_id, i.issue_id) display_id, nc.label non_compliance_label, i.closed_full_name, i.resolved_full_name,
				CASE
					WHEN i.is_overdue = 1 THEN 'Overdue'
					ELSE null
				END overdue, -- required for deprecated export to not break existing functionality
				NVL(i.assigned_to_full_name, i.assigned_to_role_name) assigned_to, -- required for deprecated export to not break existing functionality
				p.region_path, i.is_critical,
				CASE WHEN i.issue_due_source_id IS NOT NULL THEN 1 ELSE 0 END is_due_dtm_relative,
				i.parent_id parent_issue_id
		  FROM v$issue i
		  LEFT JOIN v$region r on r.region_sid = i.region_sid
		  LEFT JOIN region_type rt on r.region_type = rt.region_type
		  LEFT JOIN p ON p.root_region_sid = i.region_sid AND p.rn = 1
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = i.issue_id
		  LEFT JOIN v$issue_log il ON i.last_issue_log_id = il.issue_log_id AND i.issue_id = il.issue_id
		  LEFT JOIN issue_log_read ilr ON il.issue_log_id = ilr.issue_log_id AND ilr.csr_user_sid = v_user_sid
		  LEFT JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id  
		  LEFT JOIN non_compliance nc on inc.non_compliance_id = nc.non_compliance_id
		  LEFT JOIN non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
		  LEFT JOIN internal_audit ia ON nc.created_in_audit_sid = ia.internal_audit_sid
		  LEFT JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
		 ORDER BY fil_list.pos;

	OPEN out_cust_vals FOR
		SELECT sv.issue_id, icf.issue_custom_field_id, icf.field_type, icf.label, sv.string_value, NULL date_value
		  FROM issue_custom_field_str_val sv
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = sv.issue_id
		  JOIN issue_custom_field icf ON sv.issue_custom_field_id = icf.issue_custom_field_id AND sv.app_sid = icf.app_sid
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
		 UNION ALL
		SELECT issue_id, issue_custom_field_id, field_type, label, string_value, NULL FROM (
			SELECT os.issue_id, icf.issue_custom_field_id, icf.field_type, icf.label, stragg(fo.label) string_value
			  FROM issue_custom_field_option fo
			  JOIN issue_custom_field_opt_sel os ON fo.issue_custom_field_opt_id = os.issue_custom_field_opt_id AND fo.issue_custom_field_id = os.issue_custom_field_id AND fo.app_sid = os.app_sid
			  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = os.issue_id
			  JOIN issue_custom_field icf ON os.issue_custom_field_id = icf.issue_custom_field_id AND os.app_sid = icf.app_sid
			  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value
			 GROUP BY os.issue_id, icf.issue_custom_field_id, icf.field_type, icf.label
			)
		 UNION ALL
		SELECT dv.issue_id, icf.issue_custom_field_id, icf.field_type, icf.label, NULL, date_value
		  FROM issue_custom_field_date_val dv
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = dv.issue_id
		  JOIN issue_custom_field icf ON dv.issue_custom_field_id = icf.issue_custom_field_id AND dv.app_sid = icf.app_sid
		  JOIN TABLE(v_permissible_cust_fields) pcf ON icf.issue_custom_field_id = pcf.column_value;

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE PageFilteredIds (
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.PageFilteredIds');	

	IF in_order_by = 'issueId' AND in_order_dir='DESC' THEN
		SELECT security.T_ORDERED_SID_ROW(object_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.object_id, ROWNUM rn
				  FROM (
					SELECT object_id
					  FROM (SELECT DISTINCT object_id FROM TABLE(in_id_list))
					 ORDER BY object_id DESC
					) x 
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
		
		SELECT security.T_ORDERED_SID_ROW(issue_id, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.issue_id, ROWNUM rn
				  FROM (
					SELECT i.issue_id
					  FROM v$issue i --TODO: join to just the tables needed for sorting, v$issue is quite big
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = i.issue_id
					  LEFT JOIN issue_custom_field_str_val sv
					    ON v_order_by = 'customField'
					   AND v_order_by_id = sv.issue_custom_field_id
					   AND i.issue_id = sv.issue_id
					  LEFT JOIN issue_custom_field_date_val dv
					    ON v_order_by = 'customField'
					   AND v_order_by_id = dv.issue_custom_field_id
					   AND i.issue_id = dv.issue_id
					  LEFT JOIN (
						SELECT os.issue_id, MIN(fo.label) min_label
						  FROM issue_custom_field_option fo
						  JOIN issue_custom_field_opt_sel os
						    ON fo.issue_custom_field_opt_id = os.issue_custom_field_opt_id
						   AND fo.issue_custom_field_id = os.issue_custom_field_id
						   AND fo.app_sid = os.app_sid
						 WHERE v_order_by = 'customField'
						   AND v_order_by_id = os.issue_custom_field_id
						 GROUP BY os.issue_id
						) ov ON i.issue_id = ov.issue_id
					 ORDER BY
							-- To avoid dyanmic SQL, do many case statements
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'issueType' THEN issue_type_label
									WHEN 'issueId' THEN TO_CHAR(issue_id, '0000000000')
									WHEN 'isOverdue' THEN TO_CHAR(1-is_overdue) -- reverse overdue so default is overdue first
									WHEN 'label' THEN LOWER(label)
									WHEN 'description' THEN LOWER(DBMS_LOB.SUBSTR(description, 1000, 1))
									WHEN 'status' THEN
										CASE(status) 
											WHEN 'Ongoing' THEN '1'
											WHEN 'Rejected' THEN '2'
											WHEN 'Resolved' THEN '3'
											WHEN 'Closed' THEN '4'
										END
									WHEN 'raisedFullName' THEN LOWER(raised_full_name)
									WHEN 'resolvedFullName' THEN LOWER(resolved_full_name)
									WHEN 'closedFullName' THEN LOWER(closed_full_name)
									WHEN 'assignedToFullName' THEN LOWER(assigned_to_full_name)
									WHEN 'ownerFullName' THEN LOWER(owner_full_name)
									WHEN 'raisedDtmFormatted' THEN TO_CHAR(raised_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'dueDtmFormatted' THEN TO_CHAR(due_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'resolvedDtmFormatted' THEN TO_CHAR(NVL(manual_completion_dtm, resolved_dtm), 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'closedDtmFormatted' THEN TO_CHAR(closed_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'lastModifiedDtmFormatted' THEN TO_CHAR(last_modified_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'priorityDescription' THEN priority_description
									WHEN 'customField' THEN NVL(LOWER(ov.min_label), NVL(LOWER(sv.string_value), TO_CHAR(dv.date_value, 'YYYY-MM-DD HH24:MI:SS')))
									WHEN 'isCritical' THEN TO_CHAR(1-is_critical) -- reverse critical so default is critical first
									WHEN 'regionDescription' THEN LOWER(i.region_name)
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'issueType' THEN issue_type_label
									WHEN 'issueId' THEN TO_CHAR(issue_id, '0000000000')
									WHEN 'isOverdue' THEN TO_CHAR(1-is_overdue)
									WHEN 'label' THEN LOWER(label)
									WHEN 'description' THEN LOWER(DBMS_LOB.SUBSTR(description, 1000, 1))
									WHEN 'status' THEN
										CASE(status) 
											WHEN 'Ongoing' THEN '1'
											WHEN 'Rejected' THEN '2'
											WHEN 'Resolved' THEN '3'
											WHEN 'Closed' THEN '4'
										END
									WHEN 'raisedFullName' THEN LOWER(raised_full_name)
									WHEN 'resolvedFullName' THEN LOWER(resolved_full_name)
									WHEN 'closedFullName' THEN LOWER(closed_full_name)
									WHEN 'assignedToFullName' THEN LOWER(assigned_to_full_name)
									WHEN 'ownerFullName' THEN LOWER(owner_full_name)
									WHEN 'raisedDtmFormatted' THEN TO_CHAR(raised_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'dueDtmFormatted' THEN TO_CHAR(due_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'resolvedDtmFormatted' THEN TO_CHAR(NVL(manual_completion_dtm, resolved_dtm), 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'closedDtmFormatted' THEN TO_CHAR(closed_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'lastModifiedDtmFormatted' THEN TO_CHAR(last_modified_dtm, 'YYYY-MM-DD HH24:MI:SS')
									WHEN 'priorityDescription' THEN priority_description
									WHEN 'customField' THEN NVL(LOWER(ov.min_label), NVL(LOWER(sv.string_value), TO_CHAR(dv.date_value, 'YYYY-MM-DD HH24:MI:SS')))
									WHEN 'isCritical' THEN TO_CHAR(1-is_critical)
									WHEN 'regionDescription' THEN LOWER(i.region_name)
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN i.issue_id END DESC,
							CASE WHEN in_order_dir='DESC' THEN i.issue_id END ASC
					) x
				 WHERE ROWNUM <= in_end_row
				)
			  WHERE rn > in_start_row;
	END IF;
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_IssueIdsToNonCompSids(
	in_issue_ids					IN security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	INSERT INTO chain.temp_grid_extension_map gem (source_id, linked_type, linked_id)
	SELECT DISTINCT ids.sid_id, chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, anc.audit_non_compliance_id
	  FROM TABLE(in_issue_ids) ids
	  JOIN csr.issue i ON ids.sid_id = i.issue_id
	  JOIN csr.issue_non_compliance inc ON inc.issue_non_compliance_id = i.issue_non_compliance_id
	  JOIN csr.audit_non_compliance anc ON anc.non_compliance_id = inc.non_compliance_id;
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_ISSUES, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;
		
		IF v_extension_id = chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES THEN
			INTERNAL_IssueIdsToNonCompSids(in_id_page);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Issue -> '||v_name);
		END IF;

	END LOOP;
END;

PROCEDURE GetList(
	in_search						IN	VARCHAR2,
	in_group_key					IN	chain.saved_filter.group_key%TYPE,
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
	out_cur							OUT	SYS_REFCURSOR,
	out_cust_vals					OUT	SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetList', in_compound_filter_id);

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
	CollectSearchResults(
		in_id_list			=> v_id_page,
		out_cur				=> out_cur,
		out_cust_vals		=> out_cust_vals
	);

	chain.filter_pkg.EndDebugLog(v_log_id);
END;

-- this was missing, not sure why
/*
PROCEDURE GetAggregateDetails (
	in_aggregation_types			IN	security.T_ORDERED_SID_TABLE,
	in_id_col_sid					IN	security_pkg.T_SID_ID,
	out_agg_types					OUT	chain.T_FILTER_AGG_TYPE_TABLE,
	out_aggregate_thresholds		OUT	chain.T_FILTER_AGG_TYPE_THRES_TABLE
)
AS
BEGIN
	SELECT chain.T_FILTER_AGG_TYPE_ROW(filter_pkg.FILTER_TYPE_ISSUES, a.aggregate_type_id, a.description, null, null, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM TABLE(in_aggregation_types) sat
	  JOIN (
		SELECT at.aggregate_type_id, at.description
		  FROM chain.aggregate_type at
		 WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_ISSUES
		) a ON sat.sid_id = a.aggregate_type_id
	 ORDER BY sat.pos;
END;
*/

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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetReportData', in_compound_filter_id);
	
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

	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_ISSUES, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
		SELECT t.object_id, i.issue_id, i.label, i.description,
			   r.description region_description, it.label issue_type_label,
			   issue_pkg.GetIssueUrl(i.issue_id) issue_url
		  FROM issue i
		  JOIN TABLE(in_id_list) t ON i.issue_id = t.object_id
		  JOIN issue_type it ON i.issue_type_id = it.issue_type_id
		  LEFT JOIN v$region r ON i.region_sid = r.region_sid;
END;

PROCEDURE GetExport(
	in_search						IN	VARCHAR2,
	in_group_key					IN  chain.saved_filter.group_key%TYPE,
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
	out_cur							OUT	SYS_REFCURSOR,
	out_cust_vals					OUT	SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
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
		out_cust_vals		=> out_cust_vals
	);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_cust_vals					OUT	SYS_REFCURSOR
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	v_log_id := chain.filter_pkg.StartDebugLog('csr.issue_report_pkg.GetListAsExtension', in_compound_filter_id);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(linked_id, NULL, NULL)
	  BULK COLLECT INTO v_id_list
	  FROM (
			SELECT linked_id
			  FROM chain.temp_grid_extension_map
			 WHERE linked_type = chain.filter_pkg.FILTER_TYPE_ISSUES
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
		out_cust_vals 				=> out_cust_vals
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

PROCEDURE FilterIssueTypeId (
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
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, it.issue_type_id, it.label
		  FROM issue_type it
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = it.issue_type_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv ON i.issue_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterIssuePriorityId (
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
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, ip.issue_priority_id, ip.description
		  FROM issue_priority ip
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = ip.issue_priority_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
 	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv ON i.issue_priority_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAuditTypeId (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, iat.internal_audit_type_id, iat.label
		  FROM internal_audit_type iat
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = iat.internal_audit_type_id
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(ia.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	    FROM (
		SELECT DISTINCT i.issue_id, ia.internal_audit_type_id
		  FROM issue i
		  JOIN issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id
		  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id
		  JOIN internal_audit ia ON anc.internal_audit_sid = ia.internal_audit_sid
		) ia
	  JOIN TABLE(in_ids) t ON ia.issue_id = t.object_id
	  JOIN chain.filter_value fv ON ia.internal_audit_type_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterStatus (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, s.status_name, s.status_name
		  FROM (
			SELECT 'Ongoing' status_name FROM dual
			UNION ALL SELECT 'Rejected' FROM dual
			UNION ALL SELECT 'Resolved' FROM dual
			UNION ALL SELECT 'Closed' FROM dual
		  ) s
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = s.status_name
		 );
		
	END IF;
	
	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT s.pos new_pos, fv.pos old_pos, fv.filter_value_id
		  FROM chain.filter_value fv
		  JOIN (
			SELECT 'Ongoing' status_name, 1 pos FROM dual
			UNION ALL SELECT 'Rejected', 2 FROM dual
			UNION ALL SELECT 'Resolved', 3 FROM dual
			UNION ALL SELECT 'Closed', 4 FROM dual
		  ) s ON s.status_name = fv.str_value
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.pos, s.pos, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET pos = r.new_pos
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM V$issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv ON i.status = fv.str_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRagStatusId (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, rs.rag_status_id, rs.label
		  FROM rag_status rs
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = rs.rag_status_id
		 );
		
	END IF;
	
	FOR r IN (
		SELECT rs.colour, fv.filter_value_id
		  FROM chain.filter_value fv
		  JOIN rag_status rs ON fv.num_value = rs.rag_status_id
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.colour, rs.colour, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET colour = r.colour
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv ON i.rag_status_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterOwnerSid (
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
		-- ensure the filter_value rows include all assigned to users for the current filter
		-- we don't remove values from old filters / drilldowns so it's possible to get 0 count
		-- filter values
		-- TODO: Should we remove values from chain.filter_value that no longer match in_sids?
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.assigned_to
		  FROM (
			SELECT DISTINCT NVL(owner_user_sid, owner_role_sid) assigned_to
			  FROM issue i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			  ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = i.assigned_to
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM chain.filter_value fv
	  JOIN (
		SELECT i.issue_id, i.owner_user_sid, i.owner_role_sid, i.region_sid
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		 WHERE rownum >= 0 -- fully materialize sub-query
		) i
		ON fv.user_sid = i.owner_user_sid
		OR fv.user_sid = i.owner_role_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_ROLES AND EXISTS(SELECT 1 FROM region_role_member rrm WHERE rrm.role_sid = i.owner_role_sid AND rrm.region_sid = i.region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr_user u WHERE u.csr_user_sid = i.owner_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterAssignedToSid (
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
		-- ensure the filter_value rows include all assigned to users for the current filter
		-- we don't remove values from old filters / drilldowns so it's possible to get 0 count
		-- filter values
		-- TODO: Should we remove values from chain.filter_value that no longer match in_sids?
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.assigned_to
		  FROM (
			SELECT DISTINCT NVL(assigned_to_user_sid, assigned_to_role_sid) assigned_to
			  FROM issue i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			  ) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = i.assigned_to
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM chain.filter_value fv
	  JOIN (
		SELECT i.issue_id, i.assigned_to_user_sid, i.assigned_to_role_sid, i.region_sid
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		 WHERE rownum >= 0 -- fully materialize sub-query
		) i
		ON fv.user_sid = i.assigned_to_user_sid
		OR fv.user_sid = i.assigned_to_role_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_ROLES AND EXISTS(SELECT 1 FROM region_role_member rrm WHERE rrm.role_sid = i.assigned_to_role_sid AND rrm.region_sid = i.region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr_user u WHERE u.csr_user_sid = i.assigned_to_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterInvolvingSid (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, ii.involving
		  FROM (
			SELECT DISTINCT NVL(user_sid, role_sid) involving
			  FROM issue_involvement ii
			  JOIN TABLE(in_ids) t ON ii.issue_id = t.object_id
			 ) ii
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			    AND fv.user_sid = ii.involving
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN csr.issue_involvement ii ON i.issue_id = ii.issue_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = ii.user_sid
		OR fv.user_sid = ii.role_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND ii.user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_ROLES AND EXISTS(SELECT 1 FROM region_role_member rrm WHERE rrm.role_sid = ii.role_sid AND rrm.region_sid = i.region_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_ROLES AND ii.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr_user u WHERE u.csr_user_sid = ii.user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRaisedBySid (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.raised_by_user_sid
		  FROM (
			SELECT DISTINCT raised_by_user_sid
			  FROM issue i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = i.raised_by_user_sid
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = i.raised_by_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND i.raised_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr_user u WHERE u.csr_user_sid = i.raised_by_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterResolvedBySid (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.resolved_by_user_sid
		  FROM (
			SELECT DISTINCT resolved_by_user_sid
			  FROM issue i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = i.resolved_by_user_sid
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = i.resolved_by_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND i.resolved_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr_user u WHERE u.csr_user_sid = i.resolved_by_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterClosedBySid (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, user_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.closed_by_user_sid
		  FROM (
			SELECT DISTINCT closed_by_user_sid
			  FROM issue i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			) i
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.user_sid = i.closed_by_user_sid
		 );
		
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv
		ON fv.user_sid = i.closed_by_user_sid
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_ME AND i.closed_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		OR (in_show_all = 0 AND fv.user_sid = chain.filter_pkg.USER_MY_STAFF AND EXISTS(SELECT 1 FROM csr_user u WHERE u.csr_user_sid = i.closed_by_user_sid AND u.line_manager_sid = SYS_CONTEXT('SECURITY', 'SID')))
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterOverdue (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, o.overdue, o.description
		  FROM (
			SELECT 1 overdue, 'Overdue' description FROM dual
			UNION ALL SELECT 0, 'Not overdue' FROM dual
		  ) o
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = o.overdue
		 );
		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = num_value
	 WHERE filter_field_id = in_filter_field_id
	   AND (pos IS NULL OR pos != num_value);

	SELECT chain.T_FILTERED_OBJECT_ROW(issue_id, in_group_by_index, filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv ON i.is_overdue = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCritical (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, c.critical, c.description
		  FROM (
			SELECT 1 critical, 'Critical' description FROM dual
			UNION ALL SELECT 0, 'Not critical' FROM dual
		  ) c
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = c.critical
		 );
		
	END IF;
	
	UPDATE chain.filter_value
	   SET pos = num_value
	 WHERE filter_field_id = in_filter_field_id
	   AND (pos IS NULL OR pos != num_value);

	SELECT chain.T_FILTERED_OBJECT_ROW(issue_id, in_group_by_index, filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN chain.filter_value fv ON i.is_critical = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterUnread (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_user_sid			security_pkg.T_SID_ID := security_pkg.GetSid;
BEGIN
	
	IF in_show_all = 1 THEN
		-- not used in reports, doesn't make sense to add (unless a customer starts asking for it)
		NULL;
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  JOIN issue_log il ON i.last_issue_log_id = il.issue_log_id AND i.issue_id = il.issue_id
	  LEFT JOIN issue_log_read ilr ON il.issue_log_id = ilr.issue_log_id AND ilr.csr_user_sid = v_user_sid
	  JOIN chain.filter_value fv ON CASE WHEN ilr.read_dtm IS NULL AND il.logged_by_user_sid != v_user_sid THEN 1 ELSE 0 END = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRegionSid (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_group_by_index	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_region_root_sid	security_pkg.T_SID_ID;
BEGIN
	
	SELECT region_root_sid
	  INTO v_region_root_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, i.region_sid
		  FROM (
			SELECT DISTINCT NVL(region_sid,v_region_root_sid) region_sid
			  FROM issue i
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			 --UNION SELECT region_2_sid
			   --FROM issue i
			   --JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
			 ) i
		 WHERE i.region_sid IS NOT NULL -- TODO: should we include null region sids (excl. region_2_sid obviously)?
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = i.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.filter_value fv ON i.region_sid = fv.region_sid --OR  i.region_2_sid = fv.region_sid
		 WHERE fv.filter_field_id = in_filter_field_id;
	ELSE
		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN (
			SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root fv.filter_value_id filter_value_id
			  FROM region r
			  JOIN chain.filter_value fv ON fv.filter_field_id = in_filter_field_id AND r.app_sid = fv.app_sid
			 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = fv.region_sid
		   CONNECT BY PRIOR r.app_sid = r.app_sid
		       AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
		       AND PRIOR fv.filter_value_id = fv.filter_value_id
		 ) r ON r.region_sid = i.region_sid OR r.region_sid = i.region_2_sid
		UNION
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  FROM issue i
		  JOIN chain.filter_value fv
		    ON i.region_sid IS NULL -- issues that don't have a region can only be seen if fitlering from the root
		   AND fv.region_sid = v_region_root_sid
		 WHERE fv.filter_field_id = in_filter_field_id;
	END IF;
END;

PROCEDURE FilterCustomFields (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, icfo.issue_custom_field_opt_id, icfo.label
		  FROM issue_custom_field_option icfo
		  JOIN issue_custom_field icf ON icfo.issue_custom_field_id = icf.issue_custom_field_id
		  JOIN chain.filter_field ff ON ff.name = 'CustomField.'||icf.issue_custom_field_id
		 WHERE ff.filter_id = in_filter_id
		   AND NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = icfo.issue_custom_field_opt_id
		 );
		
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(issue_id, in_group_by_index, filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM (
		SELECT istr.issue_id, fv.filter_value_id
		  FROM issue_custom_field_str_val istr
		  JOIN TABLE(in_ids) t ON istr.issue_id = t.object_id
		  JOIN chain.filter_value fv ON LOWER(istr.string_value) LIKE '%'||LOWER(fv.str_value)||'%'
		  JOIN chain.filter_field ff ON fv.filter_field_id = ff.filter_field_id
		  JOIN issue_custom_field icf
			ON istr.issue_custom_field_id = icf.issue_custom_field_id
		   AND ff.name = 'CustomField.'||icf.issue_custom_field_id
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND icf.field_type = 'T'
		 UNION
		SELECT iopt.issue_id, fv.filter_value_id
		  FROM issue_custom_field_opt_sel iopt
		  JOIN TABLE(in_ids) t ON iopt.issue_id = t.object_id
		  JOIN chain.filter_value fv ON iopt.issue_custom_field_opt_id = fv.num_value
		  JOIN chain.filter_field ff ON fv.filter_field_id = ff.filter_field_id
		  JOIN issue_custom_field icf
			ON iopt.issue_custom_field_id = icf.issue_custom_field_id
		   AND ff.name = 'CustomField.'||icf.issue_custom_field_id
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND icf.field_type IN ('O', 'M')
		 UNION
		SELECT idte.issue_id, fv.filter_value_id
		  FROM issue_custom_field_date_val idte
		  JOIN TABLE(in_ids) t ON idte.issue_id = t.object_id
		  JOIN chain.filter_value fv ON LOWER(idte.date_value) LIKE '%'||LOWER(fv.start_dtm_value)||'%'
		  JOIN chain.filter_field ff ON fv.filter_field_id = ff.filter_field_id
		  JOIN issue_custom_field icf
			ON idte.issue_custom_field_id = icf.issue_custom_field_id
		   AND ff.name = 'CustomField.'||icf.issue_custom_field_id
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND icf.field_type = 'D'
	  )
	;
END;

PROCEDURE FilterDueDate (
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
		-- Get date range from our data
		SELECT MIN(i.due_dtm), MAX(i.due_dtm)
		  INTO v_min_date, v_max_date
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		 WHERE i.due_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
		-- the above will only create filter values of type DATE_SPECIFY_DATES, so we can
		-- speed this up by not having a call to chain.filter_pkg.CheckDateRange and checking
		-- the start/end values directly
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  CROSS JOIN chain.filter_value fv 
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND i.due_dtm >= NVL(fv.start_dtm_value, i.due_dtm)
		   AND (fv.end_dtm_value IS NULL OR i.due_dtm < fv.end_dtm_value);
	ELSE

		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id			=> in_filter_field_id,
			in_include_time_in_filter	=> 0
		);
		
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, dr.group_by_index, dr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.tt_filter_date_range dr 
			ON i.due_dtm >= NVL(dr.start_dtm, i.due_dtm)
		   AND (dr.end_dtm IS NULL OR i.due_dtm < dr.end_dtm)
		 WHERE due_dtm IS NOT NULL;
	
	END IF;
END;

PROCEDURE FilterForecastDate (
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
		-- Get date range from our data
		SELECT MIN(i.forecast_dtm), MAX(i.forecast_dtm)
		  INTO v_min_date, v_max_date
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		 WHERE i.forecast_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
		-- the above will only create filter values of type DATE_SPECIFY_DATES, so we can
		-- speed this up by not having a call to chain.filter_pkg.CheckDateRange and checking
		-- the start/end values directly
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  CROSS JOIN chain.filter_value fv 
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND i.forecast_dtm >= NVL(fv.start_dtm_value, i.forecast_dtm)
		   AND (fv.end_dtm_value IS NULL OR i.forecast_dtm < fv.end_dtm_value);
	ELSE

		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id			=> in_filter_field_id,
			in_include_time_in_filter	=> 0
		);
		
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, dr.group_by_index, dr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.tt_filter_date_range dr 
			ON i.forecast_dtm >= NVL(dr.start_dtm, i.forecast_dtm) 
		   AND (dr.end_dtm IS NULL OR i.forecast_dtm < dr.end_dtm)
		 WHERE forecast_dtm IS NOT NULL;
	
	END IF;
END;

PROCEDURE FilterLastModifiedDate (
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
		-- Get date range from our data
		SELECT MIN(i.last_modified_dtm), MAX(i.last_modified_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
		-- the above will only create filter values of type DATE_SPECIFY_DATES, so we can
		-- speed this up by not having a call to chain.filter_pkg.CheckDateRange and checking
		-- the start/end values directly
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM V$issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  CROSS JOIN chain.filter_value fv 
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND i.last_modified_dtm >= NVL(fv.start_dtm_value, i.last_modified_dtm)
		   AND (fv.end_dtm_value IS NULL OR i.last_modified_dtm < fv.end_dtm_value);
		
	ELSE
		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id			=> in_filter_field_id,
			in_include_time_in_filter	=> 1
		);

		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, dr.group_by_index, dr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.tt_filter_date_range dr 
		    ON i.last_modified_dtm >= NVL(dr.start_dtm, i.last_modified_dtm) 
		   AND (dr.end_dtm IS NULL OR i.last_modified_dtm < dr.end_dtm);
	END IF;
END;

PROCEDURE FilterRaisedDate (
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
		-- Get date range from our data
		SELECT MIN(i.raised_dtm), MAX(i.raised_dtm)
		  INTO v_min_date, v_max_date
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
		-- the above will only create filter values of type DATE_SPECIFY_DATES, so we can
		-- speed this up by not having a call to chain.filter_pkg.CheckDateRange and checking
		-- the start/end values directly
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  CROSS JOIN chain.filter_value fv 
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND i.raised_dtm >= NVL(fv.start_dtm_value, i.raised_dtm)
		   AND (fv.end_dtm_value IS NULL OR i.raised_dtm < fv.end_dtm_value);
	ELSE

		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id			=> in_filter_field_id,
			in_include_time_in_filter	=> 1
		);
		
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, dr.group_by_index, dr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.tt_filter_date_range dr
			ON i.raised_dtm >= NVL(dr.start_dtm, i.raised_dtm)
		   AND (dr.end_dtm IS NULL OR i.raised_dtm < dr.end_dtm);
	
	END IF;
END;

PROCEDURE FilterResolvedDate (
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
		-- Get date range from our data
		SELECT MIN(NVL(i.manual_completion_dtm, i.resolved_dtm)), MAX(NVL(i.manual_completion_dtm, i.resolved_dtm))
		  INTO v_min_date, v_max_date
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		 WHERE i.resolved_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
		-- the above will only create filter values of type DATE_SPECIFY_DATES, so we can
		-- speed this up by not having a call to chain.filter_pkg.CheckDateRange and checking
		-- the start/end values directly
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  CROSS JOIN chain.filter_value fv 
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND NVL(i.manual_completion_dtm, i.resolved_dtm) >= NVL(fv.start_dtm_value, i.resolved_dtm)
		   AND (fv.end_dtm_value IS NULL OR NVL(i.manual_completion_dtm, i.resolved_dtm) < fv.end_dtm_value);
	ELSE

		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id			=> in_filter_field_id,
			in_include_time_in_filter	=> 1
		);
		
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, dr.group_by_index, dr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.tt_filter_date_range dr 
			ON NVL(i.manual_completion_dtm, i.resolved_dtm) >= NVL(dr.start_dtm, i.resolved_dtm)
		   AND (dr.end_dtm IS NULL OR NVL(i.manual_completion_dtm, i.resolved_dtm) < dr.end_dtm)
		 WHERE i.resolved_dtm IS NOT NULL;
	
	END IF;
END;

PROCEDURE FilterClosedDate (
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
		-- Get date range from our data
		SELECT MIN(i.closed_dtm), MAX(i.closed_dtm)
		  INTO v_min_date, v_max_date
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		 WHERE i.closed_dtm IS NOT NULL;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);
		
		-- the above will only create filter values of type DATE_SPECIFY_DATES, so we can
		-- speed this up by not having a call to chain.filter_pkg.CheckDateRange and checking
		-- the start/end values directly
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  CROSS JOIN chain.filter_value fv 
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND i.closed_dtm >= NVL(fv.start_dtm_value, i.closed_dtm)
		   AND (fv.end_dtm_value IS NULL OR i.closed_dtm < fv.end_dtm_value);
	ELSE

		chain.filter_pkg.PopulateDateRangeTT(
			in_filter_field_id			=> in_filter_field_id,
			in_include_time_in_filter	=> 1
		);
		
		SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, dr.group_by_index, dr.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM issue i
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
		  JOIN chain.tt_filter_date_range dr
			ON i.closed_dtm >= NVL(dr.start_dtm, i.closed_dtm)
		   AND (dr.end_dtm IS NULL OR i.closed_dtm < dr.end_dtm)
		 WHERE i.closed_dtm IS NOT NULL;
	
	END IF;
END;


PROCEDURE FilterOverdueBy (
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
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, dr.date_range, dr.description
		  FROM (
			SELECT '0-30' date_range, 'up to 30 days' description FROM dual -- use lower case to match JS to give better chance of finding a translation
			UNION ALL SELECT '30-60', 'between 30 and 60 days' FROM dual
			UNION ALL SELECT '60-90', 'between 60 and 90 days' FROM dual
			UNION ALL SELECT '90+', 'over 90 days' FROM dual
			UNION ALL SELECT '180+', 'over 6 months' FROM dual
		  ) dr
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = dr.date_range
		 );
		
	END IF;
		 
	-- update pos column in a cursor, updating only rows that have changed
	-- as an update statement was causing row-locks and blockers
	FOR r IN (
		SELECT s.pos new_pos, fv.pos old_pos, fv.filter_value_id
		  FROM chain.filter_value fv
		  JOIN (
			SELECT '0-30' date_range, 1 pos FROM dual
			UNION ALL SELECT '30-60', 2 FROM dual
			UNION ALL SELECT '60-90', 3 FROM dual
			UNION ALL SELECT '90+', 4 FROM dual
			UNION ALL SELECT '180+', 5 FROM dual
		  ) s ON s.date_range = fv.str_value
		 WHERE fv.filter_field_id = in_filter_field_id
		   AND DECODE(fv.pos, s.pos, 1, 0) = 0
	) LOOP
		UPDATE chain.filter_value
		   SET pos = r.new_pos
		 WHERE filter_value_id = r.filter_value_id;
	END LOOP;

	SELECT chain.T_FILTERED_OBJECT_ROW(i.issue_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM issue i
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON i.issue_id = t.object_id
	  CROSS JOIN chain.filter_value fv 
	  WHERE due_dtm IS NOT NULL
	   AND fv.filter_field_id = in_filter_field_id
	   AND ((
		fv.str_value='0-30' AND i.due_dtm < SYSDATE AND i.due_dtm >= (SYSDATE - 30) AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
	   ) OR (
		fv.str_value='30-60' AND i.due_dtm < (SYSDATE-30) AND i.due_dtm >= (SYSDATE - 60) AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
	   ) OR (
		fv.str_value='60-90' AND i.due_dtm < (SYSDATE-60) AND i.due_dtm >= (SYSDATE - 90) AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
	   ) OR (
		fv.str_value='90+' AND i.due_dtm < (SYSDATE-90)  AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
	   ) OR (
		fv.str_value='180+' AND i.due_dtm < (SYSDATE-180)  AND i.resolved_dtm IS NULL AND i.rejected_dtm IS NULL
	   ));
END;

PROCEDURE FilterSavedFilter (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_group_by_index				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_comparator					IN	chain.filter_field.comparator%TYPE, 
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_result_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_temp_ids						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	IF in_comparator = chain.filter_pkg.COMPARATOR_INTERSECT THEN
		v_result_ids := in_ids;

		IF in_group_by_index IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot group by intersected filters');
		END IF;

		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text, fv.filter_value_id
			  FROM chain.filter_value fv
			  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
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
			  FROM chain.filter_value fv
			  JOIN chain.saved_filter sf ON fv.saved_filter_sid_value = sf.saved_filter_sid
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

PROCEDURE FilterNonCompliances (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_ids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_compound_filter_id			chain.filter.compound_filter_id%TYPE;
	v_non_compliance_ids			chain.T_FILTERED_OBJECT_TABLE;	
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, in_filter_field_id);

	IF v_compound_filter_id IS NULL THEN
		out_ids := in_ids;
	ELSE
		-- convert issue ids to audit-non-compliance ids
		SELECT chain.T_FILTERED_OBJECT_ROW(anc.audit_non_compliance_id, NULL, NULL)
		  BULK COLLECT INTO v_non_compliance_ids
		  FROM audit_non_compliance anc
		  JOIN issue_non_compliance inc ON inc.non_compliance_id = anc.non_compliance_id
		  JOIN issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id
		  JOIN TABLE(in_ids) t ON i.issue_id = t.object_id;
		  
		-- filter non-compliances
		non_compliance_report_pkg.GetFilteredIds(
			in_compound_filter_id	=> v_compound_filter_id,
			in_id_list				=> v_non_compliance_ids,
			out_id_list				=> v_non_compliance_ids
		);
		
		-- convert audit-non-compliance ids to issue ids
		SELECT chain.T_FILTERED_OBJECT_ROW(issue_id, NULL, NULL)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT i.issue_id
			  FROM TABLE(v_non_compliance_ids) t
			  JOIN audit_non_compliance anc ON t.object_id = anc.audit_non_compliance_id
			  JOIN issue_non_compliance inc ON anc.non_compliance_id = inc.non_compliance_id
			  JOIN issue i ON i.issue_non_compliance_id = inc.issue_non_compliance_id
			  JOIN TABLE(in_ids) iid ON iid.object_id = i.issue_id
		  );
	END IF;
END;

END issue_report_pkg;
/
