CREATE OR REPLACE PACKAGE BODY CSR.user_report_pkg
IS

-- private field filter units
PROCEDURE FilterIsActive				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCanReceiveAlerts		 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterHasEnhancedAccessibility (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterHasCoverUser			 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCoverUser				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCoverDates				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterAssocRegion				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterStartPointRegion		 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterStartPointIndicator		 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRole					 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterGroup					 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLanguage				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCulture					 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterTimeZone				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRoleRegion				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterCreatedDate				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterExpirationDate			 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLastLogonType			 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLastLogonDate			 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterLineManager				 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterUserRef					 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIsAnonymised			 (in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterUserSids (
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
	v_compound_filter_id			chain.compound_filter.compound_filter_id%TYPE;
BEGIN
	v_starting_ids := in_ids;

	IF in_parallel = 0 THEN
		out_ids := in_ids;
	ELSE
		out_ids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name LIKE 'CmsFilter.%' THEN
			v_compound_filter_id := chain.filter_pkg.GetCompoundFilterIdFromAdapter(in_filter_id, r.filter_field_id);
			cms.filter_pkg.FilterColumnIds(in_filter_id, r.filter_field_id, v_compound_filter_id, r.column_sid, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IsActive' THEN
			FilterIsActive(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CanReceiveAlerts' THEN
			FilterCanReceiveAlerts(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'HasEnhancedAccessibility' THEN
			FilterHasEnhancedAccessibility(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'HasCoverUser' THEN
			FilterHasCoverUser(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CoverUser' THEN
			FilterCoverUser(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CoverDates' THEN
			FilterCoverDates(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'RoleRegion' THEN
			FilterRoleRegion(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'AssocRegion' THEN
			FilterAssocRegion(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'StartPointRegion' THEN
			FilterStartPointRegion(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'StartPointIndicator' THEN
			FilterStartPointIndicator(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Role' THEN
			FilterRole(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Group' THEN
			FilterGroup(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Language' THEN
			FilterLanguage(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Culture' THEN
			FilterCulture(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'TimeZone' THEN
			FilterTimeZone(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'ExpirationDtm' THEN
			FilterExpirationDate(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'CreatedDtm' THEN
			FilterCreatedDate(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'LastLogonType' THEN
			FilterLastLogonType(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'LastLogon' THEN
			FilterLastLogonDate(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);		
		ELSIF r.name = 'LineManager' THEN
			FilterLineManager(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'UserRef' THEN
			FilterUserRef(in_filter_id, r.filter_field_id, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'IsAnonymised' THEN
			FilterIsAnonymised(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
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
	chain.filter_pkg.RunCompoundFilter('FilterUserSids', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types	IN	security.T_SID_TABLE,
	in_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, 
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END, l.object_id
	  FROM v$csr_user cu
	  JOIN TABLE(in_id_list) l ON cu.csr_user_sid = l.object_id
	 CROSS JOIN TABLE(in_aggregation_types) a
	  LEFT JOIN chain.customer_aggregate_type cuat ON a.column_value = cuat.customer_aggregate_type_id;
	  
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
	v_users_sid						security.security_pkg.T_SID_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.GetInitialIds');

	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_users_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading Users');
	END IF;
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM csr_user cu
	  JOIN security.securable_object so ON cu.csr_user_sid = so.sid_id
	 WHERE so.parent_sid_id = v_users_sid
	   AND cu.app_sid = v_app_sid
	   AND cu.hidden = 0
	   AND (v_sanitised_search IS NULL
			OR UPPER(cu.full_name) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(cu.user_name) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(cu.friendly_name) LIKE '%'||UPPER(in_search)||'%'
			OR UPPER(cu.email) LIKE '%'||UPPER(in_search)||'%'
			OR TO_CHAR(cu.csr_user_sid) = UPPER(in_search)
		);
	
	IF NVL(in_pre_filter_sid, 0) > 0 THEN
		FOR r IN (
			SELECT sf.compound_filter_id, sf.search_text
			  FROM chain.saved_filter sf
			 WHERE saved_filter_sid = in_pre_filter_sid
		) LOOP	
			GetFilteredIds(
				in_search						=> r.search_text,
				in_compound_filter_id			=> r.compound_filter_id,
				in_id_list						=> out_id_list,
				out_id_list						=> out_id_list
			);
		END LOOP;
	END IF;
	 
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

PROCEDURE GetFilteredIdsSimple(
	in_filter_id					IN	chain.compound_filter.compound_filter_id%TYPE,
	in_search						IN	VARCHAR2 DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	GetFilteredIds(
		in_compound_filter_id => in_filter_id, 
		in_search => in_search,
		out_id_list => v_id_list
	);
	
	OPEN out_cur FOR
		SELECT DISTINCT object_id user_sid
		  FROM TABLE(v_id_list);
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.ApplyBreadcrumb');
	
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
	out_info_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_rsp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_isp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_assreg_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_covusr_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_groups_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_period_name					reporting_period.name%TYPE;
	v_period_start_dtm				reporting_period.start_dtm%TYPE;
	v_period_end_dtm				reporting_period.end_dtm%TYPE;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','APP');
	v_groups_sid					security.security_pkg.T_ACT_ID := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.CollectSearchResults');

	reporting_period_pkg.GetCurrentPeriod(v_app_sid, v_period_name, v_period_start_dtm, v_period_end_Dtm);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ cu.csr_user_sid user_sid, cu.user_name, cu.full_name, cu.email, cu.friendly_name, cu.language,
			cu.culture, cu.timezone, cu.active, cu.enable_aria, cu.send_alerts, cu.last_logon, lt.label last_logon_type,
			cu.created_dtm, cu.expiration_dtm, cu.line_manager_sid, mu.full_name line_manager_full_name,
			NVL(mu.active,0) line_manager_active, cu.user_ref, cu.anonymised
		  FROM v$csr_user cu
		  JOIN logon_type lt ON cu.last_logon_type_id = lt.logon_type_id
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = cu.csr_user_sid
		  LEFT JOIN v$csr_user mu ON cu.line_manager_sid = mu.csr_user_sid
		 ORDER BY fil_list.pos;
		 
	OPEN out_info_cur FOR
		SELECT user_info_xml_fields 
		  FROM customer 
		 WHERE app_sid = v_app_sid;

	OPEN out_roles_cur FOR
		SELECT r.name role_name, reg.description region_description, fil_list.sid_id csr_user_sid
		  FROM TABLE(in_id_list) fil_list
		  JOIN region_role_member rrm ON rrm.app_sid = v_app_sid AND fil_list.sid_id = rrm.user_sid
		  JOIN role r ON rrm.app_sid = r.app_sid AND rrm.role_sid = r.role_sid
		  JOIN v$region reg ON rrm.app_sid = reg.app_sid AND rrm.region_sid = reg.region_sid
		 WHERE rrm.inherited_from_sid = rrm.region_sid;

	OPEN out_rsp_cur FOR
		SELECT user_sid, r.region_sid id, r.description
		  FROM region_start_point rsp
		  JOIN v$region r ON rsp.region_sid = r.region_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = rsp.user_sid;
			   
	OPEN out_isp_cur FOR
		SELECT user_sid, i.ind_sid id, i.description
		  FROM ind_start_point isp 
		  JOIN v$ind i ON isp.ind_sid = i.ind_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = isp.user_sid;
			   
	OPEN out_assreg_cur FOR
		SELECT user_sid, r.region_sid i, r.description
		  FROM region_owner ro
		  JOIN v$region r ON ro.region_sid = r.region_sid
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = ro.user_sid;
		 
	OPEN out_covusr_cur FOR
		SELECT user_being_covered_sid user_sid, uc.user_giving_cover_sid id, ccu.full_name description 
		  FROM user_cover uc 
		  JOIN v$csr_user ccu ON ccu.csr_user_sid = uc.user_giving_cover_sid AND uc.cover_terminated = 0
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = uc.user_being_covered_sid;
		
	OPEN out_groups_cur FOR
		SELECT so.sid_id group_sid, so.name, fil_list.sid_id csr_user_sid
		  FROM security.securable_object so
		  JOIN security.securable_object_class soc ON so.class_id = soc.class_id
		  JOIN security.group_members gm ON so.sid_id = gm.group_sid_id 
		  JOIN TABLE(in_id_list) fil_list ON gm.member_sid_id = fil_list.sid_id
		 WHERE so.application_sid_id = v_app_sid
		   AND so.parent_sid_id = v_groups_sid
		   AND so.name NOT IN ('Everyone', 'RegisteredUsers')
		   AND (so.class_id = security_pkg.SO_GROUP OR LOWER(soc.class_name) = 'csrusergroup');

	chain.filter_pkg.EndDebugLog(v_log_id);
END;


PROCEDURE PageFilteredUserSids (
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.PageFilteredUserSids');

	IF in_order_by = 'lastLogon' THEN
		-- default query when you hit the page, use quick version
		-- without joins
		SELECT security.T_ORDERED_SID_ROW(csr_user_sid, rn)
		  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.csr_user_sid, ROWNUM rn
			  FROM (
				SELECT cu.csr_user_sid
				  FROM csr_user cu
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cu.csr_user_sid
				  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
				 ORDER BY 
					CASE WHEN in_order_dir='ASC' THEN ut.last_logon END ASC,
					CASE WHEN in_order_dir='DESC' OR in_order_dir IS NULL THEN ut.last_logon END DESC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	ELSE
		v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
		v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
		
		SELECT security.T_ORDERED_SID_ROW(csr_user_sid, rn)
		  BULK COLLECT INTO out_id_list
			  FROM (
				SELECT x.csr_user_sid, ROWNUM rn
				  FROM (
					SELECT cu.csr_user_sid
					  FROM v$csr_user cu
					  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = cu.csr_user_sid
					  LEFT JOIN v$csr_user mu ON cu.line_manager_sid = mu.csr_user_sid
					 ORDER BY
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
								CASE (v_order_by)
									WHEN 'userSid' THEN TO_CHAR(cu.csr_user_sid, '0000000000')
									WHEN 'fullName' THEN LOWER(cu.full_name)
									WHEN 'userRef' THEN LOWER(cu.user_ref)
									WHEN 'email' THEN LOWER(cu.email)
									WHEN 'friendlyName' THEN LOWER(cu.friendly_name)
									WHEN 'language' THEN LOWER(cu.language)
									WHEN 'culture' THEN LOWER(cu.culture)
									WHEN 'timezone' THEN LOWER(cu.timezone)
									WHEN 'active' THEN TO_CHAR(cu.active)
									WHEN 'lineManagerSid' THEN TO_CHAR(cu.line_manager_sid, '0000000000')
									WHEN 'lineManagerFullName' THEN LOWER(mu.full_name)
									WHEN 'enableAria' THEN TO_CHAR(cu.enable_aria)
									WHEN 'sendAlerts' THEN TO_CHAR(cu.send_alerts)
									WHEN 'emailDomain' THEN LOWER(REGEXP_REPLACE(cu.email,'^.+@',''))
									WHEN 'userName' THEN LOWER(cu.user_name)
									WHEN 'anonymised' THEN LOWER(cu.anonymised)
								END
							END ASC,
							CASE WHEN in_order_dir='DESC' THEN
								CASE (v_order_by)
									WHEN 'userSid' THEN TO_CHAR(cu.csr_user_sid, '0000000000')
									WHEN 'fullName' THEN LOWER(cu.full_name)
									WHEN 'userRef' THEN LOWER(cu.user_ref)
									WHEN 'email' THEN LOWER(cu.email)
									WHEN 'friendlyName' THEN LOWER(cu.friendly_name)
									WHEN 'language' THEN LOWER(cu.language)
									WHEN 'culture' THEN LOWER(cu.culture)
									WHEN 'timezone' THEN LOWER(cu.timezone)
									WHEN 'active' THEN TO_CHAR(cu.active)
									WHEN 'lineManagerSid' THEN TO_CHAR(cu.line_manager_sid, '0000000000')
									WHEN 'lineManagerFullName' THEN LOWER(mu.full_name)
									WHEN 'enableAria' THEN TO_CHAR(cu.enable_aria)
									WHEN 'sendAlerts' THEN TO_CHAR(cu.send_alerts)
									WHEN 'emailDomain' THEN LOWER(REGEXP_REPLACE(cu.email,'^.+@',''))
									WHEN 'userName' THEN LOWER(cu.user_name)
									WHEN 'anonymised' THEN LOWER(cu.anonymised)
								END
							END DESC,
							CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN cu.csr_user_sid END DESC,
							CASE WHEN in_order_dir='DESC' THEN cu.csr_user_sid END ASC
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_CSR_USER, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension User -> '||v_name);

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
	out_info_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_rsp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_isp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_assreg_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_covusr_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_groups_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.GetUserList', in_compound_filter_id);
	
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
	
	PageFilteredUserSids(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur, out_info_cur, out_roles_cur, out_rsp_cur, out_isp_cur, out_assreg_cur, out_covusr_cur, out_groups_cur);
	
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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_CSR_USER, a.aggregate_type_id, a.description, a.format_mask,
		   a.filter_page_ind_interval_id, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM (
		SELECT at.aggregate_type_id, at.description, null format_mask, null filter_page_ind_interval_id, NVL(sat.pos, at.aggregate_type_id) pos
		  FROM chain.aggregate_type at
		  JOIN TABLE(in_aggregation_types) sat ON at.aggregate_type_id = sat.sid_id
		 WHERE at.card_group_id = chain.filter_pkg.FILTER_TYPE_CSR_USER
		 UNION
		SELECT cuat.customer_aggregate_type_id, i.description, NVL(i.format_mask, m.format_mask), null filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN v$ind i ON cuat.app_sid = i.app_sid AND cuat.ind_sid = i.ind_sid
		  JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_CSR_USER
		 UNION
		SELECT cuat.customer_aggregate_type_id, fi.description, NVL(fi.format_mask, fm.format_mask), fpii.filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN chain.filter_page_ind_interval fpii ON cuat.filter_page_ind_interval_id = fpii.filter_page_ind_interval_id
		  JOIN chain.filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id
		  JOIN v$ind fi ON fpi.app_sid = fi.app_sid AND fpi.ind_sid = fi.ind_sid
		  JOIN measure fm ON fi.measure_sid = fm.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_CSR_USER
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.user_report_pkg.GetReportData', in_compound_filter_id);
	
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
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_CSR_USER, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
		SELECT /*+ALL_ROWS*/ cu.csr_user_sid object_id, cu.csr_user_sid user_sid, cu.full_name, cu.email, cu.friendly_name, cu.language, cu.culture, cu.timezone, cu.active, 
			cu.enable_aria, cu.send_alerts,
			r.region_start_point, 
			i.ind_start_point, 
			ccu.cover_user, '/csr/site/users/editUser.acds?userSid='||cu.csr_user_sid user_link
		  FROM v$csr_user cu
		  JOIN TABLE(in_id_list) fil_list ON fil_list.object_id = cu.csr_user_sid
		  JOIN ( 
			  SELECT user_sid, LISTAGG(r.description, ', ') WITHIN GROUP (ORDER BY r.description) region_start_point
				FROM region_start_point rsp
				JOIN v$region r ON rsp.region_sid = r.region_sid
			   GROUP BY user_sid) r ON cu.csr_user_sid = r.user_sid
		  JOIN ( 
			  SELECT user_sid, LISTAGG(i.description, ', ') WITHIN GROUP (ORDER BY i.description) ind_start_point
				FROM ind_start_point isp 
				JOIN v$ind i ON isp.ind_sid = i.ind_sid
			   GROUP BY user_sid) i ON cu.csr_user_sid = i.user_sid
		  LEFT JOIN (
			  SELECT user_being_covered_sid, LISTAGG(ccu.full_name, ', ') WITHIN GROUP (ORDER BY ccu.full_name) cover_user 
				FROM user_cover uc 
				LEFT JOIN v$csr_user ccu ON ccu.csr_user_sid = uc.user_giving_cover_sid AND uc.cover_terminated = 0
			   GROUP BY user_being_covered_sid) ccu ON cu.csr_user_sid = ccu.user_being_covered_sid;
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
	out_info_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_rsp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_isp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_assreg_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_covusr_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_groups_cur					OUT security_pkg.T_OUTPUT_CUR
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
	
	CollectSearchResults(v_id_page, out_cur, out_info_cur, out_roles_cur, out_rsp_cur, out_isp_cur, out_assreg_cur, out_covusr_cur, out_groups_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR,
	out_info_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_roles_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_rsp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_isp_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_assreg_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_covusr_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_groups_cur					OUT security_pkg.T_OUTPUT_CUR
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
		out_cur						=> out_cur,
		out_info_cur				=> out_info_cur,
		out_roles_cur				=> out_roles_cur,
		out_rsp_cur					=> out_rsp_cur,
		out_isp_cur					=> out_isp_cur,
		out_assreg_cur				=> out_assreg_cur,
		out_covusr_cur				=> out_covusr_cur,
		out_groups_cur				=> out_groups_cur
	);
	
	chain.filter_pkg.EndDebugLog(v_log_id);
END;

PROCEDURE INTERNAL_ScheduleWelcomeAlerts(
	in_id_list						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_count						OUT NUMBER
)
AS
	v_raised_by_user_sid			security_pkg.T_SID_ID;
	
BEGIN
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_USER) THEN
		v_raised_by_user_sid := SYS_CONTEXT('SECURITY', 'SID');
		out_count := 0;
		
		FOR r IN (
			SELECT DISTINCT object_id 
			  FROM TABLE(in_id_list) fil_list
		) LOOP
			INSERT INTO user_message_alert (user_message_alert_id, raised_by_user_sid, notify_user_sid)
			VALUES (user_message_alert_id_seq.nextval, v_raised_by_user_sid, r.object_id);
			
			out_count := out_count + 1;
		END LOOP;
	ELSE
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ALERT_TEMPLATE_NOT_FOUND, 'Alert template not found or alert is inactive');
	END IF;
END;

PROCEDURE ScheduleFilterWelcomeAlerts(
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_search						IN	VARCHAR2,
	in_max							IN	NUMBER,
	out_count						OUT NUMBER
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
BEGIN
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_USER) THEN
		
		GetFilteredIds(
			in_compound_filter_id => in_filter_id, 
			in_search => in_search,
			out_id_list => v_id_list
		);
		
		IF v_id_list.COUNT > in_max THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_EXCEEDS_MAX, 'More than '||in_max||' records in filter.');
		END IF;
		INTERNAL_ScheduleWelcomeAlerts(
			in_id_list			=> v_id_list,
			out_count			=> out_count
		);
	ELSE
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ALERT_TEMPLATE_NOT_FOUND, 'Alert template not found or alert is inactive');
	END IF;
END;

PROCEDURE ScheduleFilterWelcomeAlerts(
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_search						IN	VARCHAR2,
	out_count						OUT NUMBER
)
AS
	v_raised_by_user_sid			security_pkg.T_SID_ID;
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
BEGIN
	IF alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_USER) THEN
		v_raised_by_user_sid := SYS_CONTEXT('SECURITY', 'SID');
		
		GetFilteredIds(
			in_compound_filter_id => in_filter_id, 
			in_search => in_search,
			out_id_list => v_id_list
		);
		
		INTERNAL_ScheduleWelcomeAlerts(
			in_id_list			=> v_id_list,
			out_count			=> out_count
		);
	ELSE
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ALERT_TEMPLATE_NOT_FOUND, 'Alert template not found or alert is inactive');
	END IF;
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

PROCEDURE FilterIsActive (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, b.val, b.description
		  FROM (
			SELECT 1 val, 'Active' description FROM dual
			UNION ALL SELECT 0, 'Inactive' FROM dual
		  ) b
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = b.val
		 );
	END IF; 
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.active = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

PROCEDURE FilterCanReceiveAlerts (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, b.val, b.description
		  FROM (
			SELECT 1 val, 'Can receive alerts' description FROM dual
			UNION ALL SELECT 0, 'Connot receive alerts' FROM dual
		  ) b
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = b.val
		 );
	END IF;
 	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.send_alerts = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterHasEnhancedAccessibility (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, b.val, b.description
		  FROM (
			SELECT 1 val, 'Uses enhanced accessibility' description FROM dual
			UNION ALL SELECT 0, 'Does not use enhanced accessibility' FROM dual
		  ) b
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = b.val
		 );
	END IF; 
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.enable_aria = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterHasCoverUser (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, b.val, b.description
		  FROM (
			SELECT 1 val, 'Has user cover enabled' description FROM dual
			UNION ALL SELECT 0, 'No user cover enabled' FROM dual
		  ) b
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = b.val
		 );
	END IF; 
	
	SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  LEFT JOIN user_cover cov ON cov.cover_terminated = 0 AND cov.user_being_covered_sid = cu.csr_user_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.filter_value fv ON DECODE(cov.user_being_covered_sid, NULL, 0, 1) = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCoverUser (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cu.csr_user_sid, cu.full_name
		  FROM v$csr_user cu
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = cu.csr_user_sid
		 );	
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN user_cover cov ON cov.cover_terminated = 0 AND cov.user_being_covered_sid = cu.csr_user_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.filter_value fv ON cov.user_giving_cover_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCoverDates (
	in_filter_id IN chain.filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids OUT chain.T_FILTERED_OBJECT_TABLE)
AS
	v_min_date	DATE;
	v_max_date	DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(cov.start_dtm), MAX(cov.end_dtm)
		  INTO v_min_date, v_max_date
		  FROM user_cover cov 
		 WHERE cov.cover_terminated = 0;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);	
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN user_cover cov ON cov.cover_terminated = 0 AND cov.user_being_covered_sid = cu.csr_user_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr ON (dr.end_dtm IS NULL OR cov.start_dtm < dr.end_dtm) AND (cov.end_dtm IS NULL OR dr.start_dtm IS NULL OR cov.end_dtm > dr.start_dtm)		  
	 WHERE cov.start_dtm IS NOT NULL;
END;

PROCEDURE FilterAssocRegion (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT DISTINCT ro.region_sid
			  FROM region_owner ro
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ro.user_sid = t.object_id
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(ro.user_sid, in_group_by_index, ro.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT ro.user_sid, fv.filter_value_id
			  FROM region_owner ro
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ro.user_sid = t.object_id
			  JOIN chain.filter_value fv ON ro.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) ro;
	ELSE
		SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$csr_user cu
		  JOIN region_owner ro ON cu.csr_user_sid = ro.user_sid
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON ro.region_sid = r.region_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id;
	END IF;
END;

PROCEDURE FilterStartPointRegion (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT DISTINCT rsp.region_sid
			  FROM region_start_point rsp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rsp.user_sid = t.object_id
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(rsp.user_sid, in_group_by_index, rsp.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT rsp.user_sid, fv.filter_value_id
			  FROM region_start_point rsp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rsp.user_sid = t.object_id
			  JOIN chain.filter_value fv ON rsp.region_sid= fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) rsp;
	ELSE
		SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$csr_user cu
		  JOIN region_start_point rsp ON cu.csr_user_sid = rsp.user_sid
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON rsp.region_sid = r.region_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id;
	END IF;
END;

PROCEDURE FilterStartPointIndicator (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.ind_sid
		  FROM (
			SELECT DISTINCT isp.ind_sid
			  FROM ind_start_point isp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON isp.user_sid = t.object_id
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = n.ind_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(rsp.user_sid, in_group_by_index, rsp.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT isp.user_sid, fv.filter_value_id
			  FROM ind_start_point isp
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON isp.user_sid = t.object_id
			  JOIN chain.filter_value fv ON isp.ind_sid = fv.num_value 
			 WHERE fv.filter_field_id = in_filter_field_id
		) rsp;
	ELSE
		SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, i.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$csr_user cu
		  JOIN ind_start_point isp ON cu.csr_user_sid = isp.user_sid
		  JOIN (
				SELECT i.ind_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM ind i
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH i.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND i.ind_sid = ff.num_value
			   CONNECT BY PRIOR i.app_sid = i.app_sid
				   AND PRIOR i.ind_sid = i.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) i ON isp.ind_sid = i.ind_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id;
	END IF;
END;

PROCEDURE FilterRole (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, r.role_sid, r.name
		  FROM role r
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = r.role_sid
		 );
	END IF; 
	
	WITH roleRegionFilterSids AS (
		SELECT region_sid
		  FROM chain.filter_field ff
		  JOIN chain.filter_value fv ON ff.filter_field_id = fv.filter_field_id
		 WHERE filter_id = in_filter_id
		   AND name = 'RoleRegion'
	)	
	SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN region_role_member rrm ON cu.csr_user_sid = rrm.user_sid
	  JOIN chain.filter_value fv ON rrm.role_sid = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id
	   AND (
		NOT EXISTS (SELECT NULL FROM roleRegionFilterSids) OR
			EXISTS (SELECT NULL FROM (
						SELECT region_sid 
						  FROM region  
						 START WITH region_sid IN (SELECT region_sid FROM roleRegionFilterSids)
					   CONNECT BY PRIOR parent_sid = region_sid) 
					WHERE region_sid = rrm.region_sid)
		);	
END;

PROCEDURE FilterGroup (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, gt.sid_id, so.name
		  FROM security.group_table gt
		  JOIN security.securable_object so ON gt.sid_id = so.sid_id
		 WHERE class_id = security.class_pkg.GetClassId('CSRUserGroup')
		   AND application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
		   AND so.name != 'RegisteredUsers'
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = gt.sid_id
		 );
	END IF; 	
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN security.group_members gm ON cu.csr_user_sid = gm.member_sid_id
	  JOIN chain.filter_value fv ON gm.group_sid_id = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLanguage (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, ts.lang, l.description
		  FROM aspen2.translation_set ts
		  JOIN aspen2.lang l ON ts.lang = l.lang
		 WHERE ts.application_sid = security.security_pkg.getapp 
		   AND ts.hidden = 0
		   AND NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = l.lang
		 );
	END IF;
 	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.language = fv.str_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterCulture (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, c.IETF, c.description
		  FROM aspen2.culture c
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value = c.IETF
		 );
	END IF; 
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.culture = fv.str_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterTimeZone (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, tz, tz
		  FROM (SELECT DISTINCT timezone tz
				  FROM csr.v$csr_user
				 MINUS
				SELECT str_value
				  FROM chain.filter_value
				 WHERE filter_field_id = in_filter_field_id);
	END IF;
 	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.timezone = fv.str_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterRoleRegion (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN	
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, region_sid)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, n.region_sid
		  FROM (
			SELECT DISTINCT rrm.region_sid
			  FROM region_role_member rrm
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rrm.user_sid = t.object_id
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(ro.user_sid, in_group_by_index, ro.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT rrm.user_sid, fv.filter_value_id
			  FROM region_role_member rrm
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON rrm.user_sid = t.object_id
			  JOIN chain.filter_value fv ON rrm.region_sid= fv.region_sid 
			   AND fv.filter_field_id = in_filter_field_id
		) ro;
	ELSE
		SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM v$csr_user cu
		  JOIN region_role_member rrm ON cu.csr_user_sid = rrm.user_sid
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON rrm.region_sid = r.region_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id;
	END IF;
END;

PROCEDURE FilterCreatedDate (
	in_filter_id IN chain.filter.filter_id%TYPE, 
	in_filter_field_id IN NUMBER, 
	in_show_all IN NUMBER, 
	in_ids IN chain.T_FILTERED_OBJECT_TABLE, 
	out_ids OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date	DATE;
	v_max_date	DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(cu.created_dtm), MAX(cu.created_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$csr_user cu;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);	
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr ON (dr.end_dtm IS NULL OR cu.created_dtm < dr.end_dtm) AND (dr.start_dtm IS NULL OR cu.created_dtm > dr.start_dtm)		  
	 WHERE cu.created_dtm IS NOT NULL;
END;

PROCEDURE FilterExpirationDate
(
	in_filter_id IN chain.filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date	DATE;
	v_max_date	DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(cu.expiration_dtm), MAX(cu.expiration_dtm)
		  INTO v_min_date, v_max_date
		  FROM v$csr_user cu;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);	
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr ON (dr.end_dtm IS NULL OR cu.expiration_dtm < dr.end_dtm) AND (dr.start_dtm IS NULL OR NVL(cu.expiration_dtm, sysdate) > dr.start_dtm)		  
	 WHERE cu.expiration_dtm IS NOT NULL;	
END;

PROCEDURE FilterLastLogonType (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, lt.logon_type_id, lt.label
		  FROM logon_type lt
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = lt.logon_type_id
		 );
	END IF; 
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON fv.num_value = cu.last_logon_type_id
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterLastLogonDate (
	in_filter_id IN chain.filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_min_date	DATE;
	v_max_date	DATE;
BEGIN
	IF in_show_all = 1 THEN
		-- Get date range from our data
		-- val is stored as days since 1900 (JS one day behind).
		SELECT MIN(cu.last_logon), MAX(cu.last_logon)
		  INTO v_min_date, v_max_date
		  FROM v$csr_user cu;
		
		-- fill filter_value with some sensible date ranges
		chain.filter_pkg.CreateDateRangeValues(in_filter_field_id, v_min_date, v_max_date);	
	END IF;
	
	chain.filter_pkg.PopulateDateRangeTT(
		in_filter_field_id			=> in_filter_field_id,
		in_include_time_in_filter	=> 1
	);
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, dr.group_by_index, dr.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.tt_filter_date_range dr ON (dr.end_dtm IS NULL OR cu.last_logon < dr.end_dtm) AND (dr.start_dtm IS NULL OR NVL(cu.last_logon, sysdate) > dr.start_dtm)		  
	 WHERE cu.last_logon IS NOT NULL;	
END;

PROCEDURE FilterLineManager (
	in_filter_id IN chain.filter.filter_id%TYPE,
	in_filter_field_id IN NUMBER,
	in_show_all IN NUMBER,
	in_ids IN chain.T_FILTERED_OBJECT_TABLE,
	out_ids OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cu.csr_user_sid, cu.full_name
		  FROM v$csr_user cu
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = cu.csr_user_sid
		 );	
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.v$filter_value fv ON cu.line_manager_sid = DECODE(fv.num_value, -1, SYS_CONTEXT('SECURITY', 'SID'), fv.num_value)
	 WHERE fv.filter_id = in_filter_id 
	   AND fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterUserRef (
	in_filter_id				IN	chain.filter.filter_id%TYPE,
	in_filter_field_id			IN	NUMBER,
	in_show_all					IN	NUMBER,
	in_ids						IN	chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT	chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, str_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, cu.user_ref, cu.user_ref
		  FROM v$csr_user cu
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.str_value like '%'||cu.user_ref||'%');
	END IF;
	
	SELECT chain.t_filtered_object_row(cu.csr_user_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	  JOIN chain.v$filter_value fv ON cu.user_ref like '%'||fv.str_value||'%'
	 WHERE fv.filter_id = in_filter_id 
	   AND fv.filter_field_id = in_filter_field_id;
END;

PROCEDURE FilterIsAnonymised (
	in_filter_id				IN  chain.filter.filter_id%TYPE,
	in_filter_field_id			IN  NUMBER,
	in_group_by_index			IN  NUMBER,
	in_show_all					IN  NUMBER,
	in_ids						IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids						OUT chain.T_FILTERED_OBJECT_TABLE)
AS
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, b.val, b.description
		  FROM (
			SELECT 1 val, 'Anonymised' description FROM dual
			UNION ALL SELECT 0, 'Not Anonymised' FROM dual
		  ) b
		 WHERE NOT EXISTS (
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = b.val
		 );
	END IF; 
	
	SELECT chain.T_FILTERED_OBJECT_ROW(cu.csr_user_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$csr_user cu
	  JOIN chain.filter_value fv ON cu.anonymised = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON cu.csr_user_sid = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;		
END;

END user_report_pkg;
/
