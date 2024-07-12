CREATE OR REPLACE PACKAGE BODY CSR.sheet_report_pkg
IS

-- private field filter units
PROCEDURE FilterRole(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterUser(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterRegion(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);
PROCEDURE FilterIndicator(in_filter_id IN chain.filter.filter_id%TYPE, in_filter_field_id IN NUMBER, in_group_by_index IN NUMBER, in_show_all IN NUMBER, in_ids IN chain.T_FILTERED_OBJECT_TABLE, out_ids OUT chain.T_FILTERED_OBJECT_TABLE);

PROCEDURE FilterSheets(
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
	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.FilterIds', in_filter_id);
	
	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index, column_sid, comparator
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
		 ORDER BY group_by_index
	) LOOP
		aspen2.request_queue_pkg.AssertRequestStillActive;
		v_inner_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.FilterIds.Filter'||r.name||' show_all: '||r.show_all||' group_by_index: '||r.group_by_index, r.filter_field_id);
		
		IF r.name = 'Role' THEN
			FilterRole(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'UserSid' THEN
			FilterUser(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Region' THEN
			FilterRegion(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
		ELSIF r.name = 'Indicator' THEN
			FilterIndicator(in_filter_id, r.filter_field_id, r.group_by_index, r.show_all, v_starting_ids, v_result_ids);
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
	chain.filter_pkg.RunCompoundFilter('FilterSheets', in_compound_filter_id, in_parallel, in_max_group_by, in_id_list, out_id_list);
END;

PROCEDURE GetFilterObjectData (
	in_aggregation_types	IN	security.T_SID_TABLE,
	in_id_list				IN	chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.GetFilterObjectData');
	
	-- just in case
	DELETE FROM chain.tt_filter_object_data;
	
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT a.column_value, l.object_id, 
		   CASE a.column_value
				WHEN AGG_TYPE_COUNT THEN chain.filter_pkg.AFUNC_COUNT
				ELSE chain.filter_pkg.AFUNC_SUM
			END, l.object_id
	  FROM sheet s
	  JOIN (
        SELECT delegation_sid
		  FROM delegation d
		 WHERE csr.delegation_pkg.SQL_CheckDelegationPermission(security.security_pkg.getact, d.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) = 1
		) d ON s.delegation_sid = d.delegation_sid
	  JOIN TABLE(in_id_list) l ON s.sheet_id = l.object_id
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
	-- Reusing in_start_dtm and in_end_dtm, no longer applies to in_date_col_type but instead filter sheet start and end date.
	-- If not passed (NULL) returns data for the current year.
	v_sanitised_search				VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_search);
	v_has_regions					NUMBER;
	v_delegations_sid				security.security_pkg.T_SID_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID;
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	aspen2.request_queue_pkg.AssertRequestStillActive;
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.GetInitialIds');

	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_delegations_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Delegations');

	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_delegations_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading Delegations');
	END IF;
	
	chain.filter_pkg.PopulateTempRegionSid(in_region_sids, in_region_col_type, v_has_regions);

	SELECT chain.T_FILTERED_OBJECT_ROW(s.sheet_id, NULL, NULL)
	  BULK COLLECT INTO out_id_list
	  FROM sheet s
	  JOIN (
        SELECT delegation_sid, description
		  FROM v$delegation d
		 WHERE csr.delegation_pkg.SQL_CheckDelegationPermission(security.security_pkg.getact, d.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) = 1
		) d ON s.delegation_sid = d.delegation_sid
	 WHERE (v_sanitised_search IS NULL
			OR UPPER(d.description) LIKE '%'||UPPER(in_search)||'%'
			OR TO_CHAR(d.delegation_sid) = UPPER(in_search)
			OR TO_CHAR(s.sheet_id) = UPPER(in_search)
		)
		AND s.start_dtm >= NVL(in_start_dtm, TRUNC(SYSDATE, 'YY'))
		AND s.end_dtm <= NVL(in_end_dtm, ADD_MONTHS(NVL(in_start_dtm, TRUNC(SYSDATE, 'YY')), 12));
	
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
		SELECT object_id user_sid
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.ApplyBreadcrumb');
	
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
	out_cur							OUT security_pkg.T_OUTPUT_CUR
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.CollectSearchResults');

	reporting_period_pkg.GetCurrentPeriod(v_app_sid, v_period_name, v_period_start_dtm, v_period_end_Dtm);

	OPEN out_cur FOR
		SELECT s.sheet_id, s.delegation_sid, s.last_action_id, s.last_action_desc, s.percent_complete,
			   s.start_dtm, s.end_dtm, s.is_visible, s.status,
			   s.reminder_dtm, s.submission_dtm, s.last_action_dtm,
			   du.users, dr.regions,
			   csr.delegation_pkg.ConcatDelegationDelegators(d.delegation_sid) delegators,
			   d.period_set_id, d.period_interval_id, d.start_dtm delegation_start_dtm, d.end_dtm delegation_end_dtm,
			   d.name, d.root_delegation_sid, d.parent_sid parent_delegation_sid, d.lvl, d.is_top_level,
			   NVL(sh.sheet_returns, 0) sheet_returns, r.name role_name
		  FROM sheet_with_last_action s
		  JOIN (
			SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.period_set_id, d.period_interval_id, d.start_dtm, d.end_dtm, DECODE(d.parent_sid, d.app_sid, 1, 0) is_top_level,
				CONNECT_BY_ROOT(d.delegation_sid) root_delegation_sid, LEVEL lvl
			  FROM (SELECT * FROM delegation d WHERE csr.delegation_pkg.SQL_CheckDelegationPermission(security.security_pkg.getact, d.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) = 1) d
			 START WITH d.parent_sid = d.app_sid
		   CONNECT BY d.parent_sid = PRIOR d.delegation_sid
			) d ON s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_role drl ON s.delegation_sid = drl.delegation_sid AND drl.delegation_sid = drl.inherited_from_sid
		  LEFT JOIN role r ON drl.role_sid = r.role_sid
		  LEFT JOIN (SELECT delegation_sid, listagg(u.email, ',' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (order by u.email) users FROM v$delegation_user d JOIN csr_user u ON d.user_sid = u.csr_user_sid GROUP BY delegation_sid) du ON d.delegation_sid = du.delegation_sid
		  LEFT JOIN (SELECT delegation_sid, listagg(d.description, ',' ON OVERFLOW TRUNCATE '...') WITHIN GROUP (order by d.description) regions FROM v$delegation_region d GROUP BY delegation_sid) dr ON d.delegation_sid = dr.delegation_sid
		  LEFT JOIN (SELECT sheet_id, COUNT(sheet_history_id) sheet_returns FROM sheet_history WHERE sheet_action_id = csr_data_pkg.ACTION_RETURNED GROUP BY sheet_id) sh ON s.sheet_id = sh.sheet_id
		  JOIN TABLE(in_id_list) fil_list ON fil_list.sid_id = s.sheet_id
		 ORDER BY fil_list.pos;

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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.PageFilteredIds');
	v_order_by := regexp_substr(in_order_by,'[A-Z,a-z]+');
	v_order_by_id := CAST(regexp_substr(in_order_by,'[0-9]+') AS NUMBER);
	
	SELECT security.T_ORDERED_SID_ROW(sheet_id, rn)
	  BULK COLLECT INTO out_id_list
		  FROM (
			SELECT x.sheet_id, ROWNUM rn
			  FROM (
				SELECT s.sheet_id
				  FROM sheet s
				  JOIN (
					SELECT delegation_sid, description
					  FROM v$delegation d
					 WHERE csr.delegation_pkg.SQL_CheckDelegationPermission(security.security_pkg.getact, d.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) = 1
					) d ON s.delegation_sid = d.delegation_sid
				  JOIN (SELECT DISTINCT object_id FROM TABLE(in_id_list)) fil_list ON fil_list.object_id = s.sheet_id
				  LEFT JOIN (SELECT sheet_id, COUNT(sheet_history_id) sheet_returns FROM sheet_history WHERE sheet_action_id = csr_data_pkg.ACTION_RETURNED GROUP BY sheet_id) sh ON s.sheet_id = sh.sheet_id
				  LEFT JOIN delegation_role dr ON dr.delegation_sid = s.delegation_sid AND dr.delegation_sid = dr.inherited_from_sid
				  LEFT JOIN role r ON dr.role_sid = r.role_sid
				 ORDER BY
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
							CASE (v_order_by)
								WHEN 'sheetId' THEN TO_CHAR(s.sheet_id, '0000000000')
								WHEN 'delegationId' THEN TO_CHAR(s.delegation_sid, '0000000000')
								WHEN 'sheetName' THEN LOWER(d.description)
								WHEN 'startDtm' THEN TO_CHAR(s.start_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'end_dtm' THEN TO_CHAR(s.end_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'reminderDtm' THEN TO_CHAR(s.reminder_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'submissionDtm' THEN TO_CHAR(s.submission_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'sheetReturns' THEN TO_CHAR(NVL(sh.sheet_returns, 0))
								WHEN 'roleName' THEN LOWER(r.name)
							END
						END ASC,
						CASE WHEN in_order_dir='DESC' THEN
							CASE (v_order_by)
								WHEN 'sheetId' THEN TO_CHAR(s.sheet_id, '0000000000')
								WHEN 'delegationId' THEN TO_CHAR(s.delegation_sid, '0000000000')
								WHEN 'sheetName' THEN LOWER(d.description)
								WHEN 'startDtm' THEN TO_CHAR(s.start_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'end_dtm' THEN TO_CHAR(s.end_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'reminderDtm' THEN TO_CHAR(s.reminder_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'submissionDtm' THEN TO_CHAR(s.submission_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'sheetReturns' THEN TO_CHAR(NVL(sh.sheet_returns, 0))
								WHEN 'roleName' THEN LOWER(r.name)
							END
						END DESC,
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN s.sheet_id END DESC,
						CASE WHEN in_order_dir='DESC' THEN s.sheet_id END ASC
				) x
				WHERE ROWNUM <= in_end_row
			)
		  WHERE rn > in_start_row;
	
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

	chain.filter_pkg.GetEnabledGridExtensions(chain.filter_pkg.FILTER_TYPE_SHEET, v_enabled_extensions);

	LOOP
		FETCH v_enabled_extensions INTO v_extension_id, v_name;
		EXIT WHEN v_enabled_extensions%NOTFOUND;

		RAISE_APPLICATION_ERROR(-20001, 'Unrecognised grid extension Sheet -> '||v_name);

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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_id_list						chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_id_page						security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_log_id						chain.debug_log.debug_log_id%TYPE;
BEGIN	
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.GetList', in_compound_filter_id);
	
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
	
	PageFilteredIds(v_id_list, in_start_row, in_end_row, in_order_by, in_order_dir, v_id_page);
	
	INTERNAL_PopGridExtTempTable(v_id_page);
	
	-- Return a page of results
	CollectSearchResults(v_id_page, out_cur);
	
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
	SELECT chain.T_FILTER_AGG_TYPE_ROW(chain.filter_pkg.FILTER_TYPE_SHEET, a.aggregate_type_id, a.description, a.format_mask,
		   a.filter_page_ind_interval_id, 0, null, null, null)
	  BULK COLLECT INTO out_agg_types
	  FROM (
		SELECT at.aggregate_type_id, at.description, null format_mask, null filter_page_ind_interval_id, NVL(sat.pos, at.aggregate_type_id) pos
		  FROM chain.aggregate_type at
		  JOIN TABLE(in_aggregation_types) sat ON at.aggregate_type_id = sat.sid_id
		 WHERE at.card_group_id = chain.filter_pkg.FILTER_TYPE_SHEET
		 UNION
		SELECT cuat.customer_aggregate_type_id, i.description, NVL(i.format_mask, m.format_mask), null filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN v$ind i ON cuat.app_sid = i.app_sid AND cuat.ind_sid = i.ind_sid
		  JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_SHEET
		 UNION
		SELECT cuat.customer_aggregate_type_id, fi.description, NVL(fi.format_mask, fm.format_mask), fpii.filter_page_ind_interval_id, sat.pos
		  FROM chain.customer_aggregate_type cuat 
		  JOIN TABLE(in_aggregation_types) sat ON cuat.customer_aggregate_type_id = sat.sid_id
		  JOIN chain.filter_page_ind_interval fpii ON cuat.filter_page_ind_interval_id = fpii.filter_page_ind_interval_id
		  JOIN chain.filter_page_ind fpi ON fpii.filter_page_ind_id = fpi.filter_page_ind_id
		  JOIN v$ind fi ON fpi.app_sid = fi.app_sid AND fpi.ind_sid = fi.ind_sid
		  JOIN measure fm ON fi.measure_sid = fm.measure_sid
		 WHERE cuat.card_group_id = chain.filter_pkg.FILTER_TYPE_SHEET
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
	v_log_id := chain.filter_pkg.StartDebugLog('csr.sheet_report_pkg.GetReportData', in_compound_filter_id);
	
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
	
	chain.filter_pkg.GetAggregateData(chain.filter_pkg.FILTER_TYPE_SHEET, in_grp_by_compound_filter_id, in_aggregation_types, in_breadcrumb, in_max_group_by, in_show_totals, v_id_list, v_top_n_values, out_field_cur, out_data_cur);
	
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
		SELECT /*+ALL_ROWS*/ cu.csr_user_sid user_sid, cu.full_name, cu.email, cu.friendly_name, cu.language, cu.culture, cu.timezone, cu.active, 
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
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
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
	
	CollectSearchResults(v_id_page, out_cur);
END;

PROCEDURE GetListAsExtension(
	in_compound_filter_id			IN chain.compound_filter.compound_filter_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
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
		out_cur						=> out_cur
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
		  FROM (
			SELECT DISTINCT r.role_sid, r.name
			  FROM role r
			  JOIN delegation_role dr ON dr.role_sid = r.role_sid
		) r
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = r.role_sid
		 );
	END IF; 
	

	SELECT DISTINCT chain.T_FILTERED_OBJECT_ROW(s.sheet_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM sheet s
	  JOIN delegation_role dr ON s.delegation_sid = dr.delegation_sid
	  JOIN chain.filter_value fv ON dr.role_sid = fv.num_value
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON s.sheet_id = t.object_id
	 WHERE fv.filter_field_id = in_filter_field_id;	
END;

PROCEDURE FilterUser(
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
		  FROM (
			SELECT DISTINCT cu.csr_user_sid, cu.full_name
			  FROM v$csr_user cu
		      JOIN v$delegation_user du ON cu.csr_user_sid = du.user_sid
		) cu
		 WHERE NOT EXISTS ( -- exclude any we may have already
			SELECT NULL
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = cu.csr_user_sid
		 );	
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(s.sheet_id, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM sheet s
	  JOIN v$delegation_user du ON s.delegation_sid = du.delegation_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON s.sheet_id = t.object_id
	  JOIN chain.v$filter_value fv ON du.user_sid = DECODE(fv.num_value, -1, SYS_CONTEXT('SECURITY', 'SID'), fv.num_value)
	 WHERE fv.filter_id = in_filter_id 
	   AND fv.filter_field_id = in_filter_field_id;	
END;

 PROCEDURE FilterRegion(
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
			SELECT dr.region_sid
			  FROM sheet s
			  JOIN delegation_region dr ON s.delegation_sid = dr.delegation_sid
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON s.sheet_id = t.object_id
			 GROUP BY dr.region_sid
			 ) n
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.region_sid = n.region_sid
		 );
		
		-- if show_all is on, we don't want to aggregate (otherwise the data is a mess)
		SELECT chain.T_FILTERED_OBJECT_ROW(s.sheet_id, in_group_by_index, s.sheet_id)
		  BULK COLLECT INTO out_ids
		  FROM (
			SELECT DISTINCT s.sheet_id, fv.filter_value_id
			  FROM sheet s
			  JOIN delegation_region dr ON s.delegation_sid = dr.delegation_sid
			  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON s.sheet_id = t.object_id
			  JOIN chain.filter_value fv ON dr.region_sid = fv.region_sid 
			 WHERE fv.filter_field_id = in_filter_field_id
		) s;
	ELSE		
		-- if show_all is off, users have specified the regions they want, they'll
		-- expect to get region aggregation
		SELECT chain.T_FILTERED_OBJECT_ROW(s.sheet_id, in_group_by_index, r.filter_value_id)
		  BULK COLLECT INTO out_ids
		  FROM sheet s
		  JOIN delegation_region dr ON s.delegation_sid = dr.delegation_sid
		  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON s.sheet_id = t.object_id
		  JOIN (
				SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, connect_by_root ff.filter_value_id filter_value_id
				  FROM region r
				  JOIN chain.filter_value ff ON ff.filter_field_id = in_filter_field_id
				 START WITH r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = ff.region_sid
			   CONNECT BY PRIOR r.app_sid = r.app_sid
				   AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   AND PRIOR ff.filter_value_id = ff.filter_value_id
			 ) r ON dr.region_sid = r.region_sid;				 
	END IF;	
END;

PROCEDURE FilterIndicator(
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
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, di.ind_sid, i.description
		  FROM sheet s
		  JOIN delegation_ind di ON s.delegation_sid = di.delegation_sid
		  JOIN v$ind i ON di.ind_sid = i.ind_sid
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = di.ind_sid
		 );
	END IF;
	
	SELECT chain.T_FILTERED_OBJECT_ROW(s.sheet_id, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM sheet s
	  JOIN delegation_ind di ON s.delegation_sid = di.delegation_sid
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON s.sheet_id = t.object_id
	  JOIN chain.filter_value fv ON di.ind_sid = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

END sheet_report_pkg;
/
